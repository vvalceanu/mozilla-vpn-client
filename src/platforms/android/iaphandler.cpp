/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "platforms/android/iaphandler.h"
#include "constants.h"
#include "androidutils.h"
#include "leakdetector.h"
#include "logger.h"
#include "mozillavpn.h"
#include "networkrequest.h"
#include "settingsholder.h"

#include <QCoreApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QScopeGuard>

#include <QAndroidBinder>
#include <QAndroidIntent>
#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QAndroidParcel>
#include <QAndroidServiceConnection>
#include <QHostAddress>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QTextCodec>
#include <QtAndroid>

#include "jni.h"
#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QtAndroid>

namespace {
Logger logger(LOG_IAP, "IAPHandler");
constexpr auto CLASSNAME = "org.mozilla.sarah.vpn.InAppPurchase";
IAPHandler* s_instance = nullptr;
}  // namespace

// static
IAPHandler* IAPHandler::createInstance() {
  Q_ASSERT(!s_instance);
  new IAPHandler(qApp);
  Q_ASSERT(s_instance);
  return instance();
}

// static
IAPHandler* IAPHandler::instance() {
  Q_ASSERT(s_instance);
  return s_instance;
}

IAPHandler::IAPHandler(QObject* parent) : QAbstractListModel(parent) {
  MVPN_COUNT_CTOR(IAPHandler);

  Q_ASSERT(!s_instance);
  s_instance = this;

  QtAndroid::runOnAndroidThreadSync([]() {
    // Hook together implementation for onSkuDetailsReceived into the JNI
    JNINativeMethod methods[]{
        {"onSkuDetailsReceived", "(Ljava/lang/String;)V",
         reinterpret_cast<void*>(onSkuDetailsReceived)},
    };
    QAndroidJniObject javaClass(CLASSNAME);
    QAndroidJniEnvironment env;
    jclass objectClass = env->GetObjectClass(javaClass.object<jobject>());
    env->RegisterNatives(objectClass, methods,
                         sizeof(methods) / sizeof(methods[0]));
    env->DeleteLocalRef(objectClass);
  });

  // IT IS HERE THAT WE SHOULD SET UP SOMETHING
  // THAT CREATES THE ONE TRUE BILLINGCLIENT
}

IAPHandler::~IAPHandler() {
  MVPN_COUNT_DTOR(IAPHandler);

  Q_ASSERT(s_instance == this);
  s_instance = nullptr;

  // AND HERE THAT WE SHOULD DESTROY THE THING THAT SETS
  // UP THE ONE TRUE BILLING CLIENT
}

// static
void IAPHandler::onSkuDetailsReceived(JNIEnv* env, jobject thiz, jstring sku) {
  Q_UNUSED(thiz);

  // From androidutils.cpp
  const char* buffer = env->GetStringUTFChars(sku, nullptr);
  if (!buffer) {
    // oh no
    return;
  }
  env->ReleaseStringUTFChars(sku, buffer);

  QJsonDocument json = QJsonDocument::fromJson(buffer);
  if (!json.isObject()) {
    logger.log() << "onSkuDetailsReceived - object expected";
    return;
  }

  QJsonObject obj = json.object();
  if (!obj.contains("products")) {
    logger.log() << "onSkuDetailsReceived - products entry expected";
    return;
  }

  QJsonArray products = obj["products"].toArray();
  if (products.isEmpty()) {
    logger.log() << "onSkuDetailsRecieved - no products found";
    return;
  }

  for (const QJsonValue& value : products) {
    IAPHandler::instance()->productRegistered(value);
  }

  IAPHandler::instance()->productsRegistrationCompleted();
}

void IAPHandler::registerProducts(const QByteArray& data) {
  logger.log() << "Maybe register products" << data;

  Q_ASSERT(m_productsRegistrationState == eRegistered ||
           m_productsRegistrationState == eNotRegistered);

  auto guard = qScopeGuard([&] { emit productsRegistered(); });

  if (m_productsRegistrationState == eRegistered) {
    return;
  }

  Q_ASSERT(m_products.isEmpty());

  QJsonDocument json = QJsonDocument::fromJson(data);
  if (!json.isObject()) {
    logger.log() << "Object expected";
    return;
  }

  QJsonObject obj = json.object();
  if (!obj.contains("products")) {
    logger.log() << "products entry expected";
    return;
  }

  QJsonArray products = obj["products"].toArray();
  if (products.isEmpty()) {
    logger.log() << "No products found";
    return;
  }

  m_productsRegistrationState = eRegistering;

  for (const QJsonValue& value : products) {
    addProduct(value);
  }

  if (m_products.isEmpty()) {
    logger.log() << "No pending products (nothing has been registered). Unable "
                    "to recover from "
                    "this scenario.";
    return;
  }

  logger.log() << "We are about to register" << m_products.size() << "products";

  // This goes to native code, and then comes back via onSkuDetailsReceived
  // where we then emit the productsRegistered() signal.
  auto appContext = QtAndroid::androidActivity().callObjectMethod(
      "getApplicationContext", "()Landroid/content/Context;");
  auto jniString = QAndroidJniObject::fromString(data);

  QAndroidJniObject::callStaticMethod<void>(
      "org/mozilla/sarah/vpn/InAppPurchase", "lookupProductsInPlayStore",
      "(Landroid/content/Context;Ljava/lang/String;)V", appContext.object(),
      jniString.object());

  logger.log() << "Waiting for the products registration";

  guard.dismiss();
}

void IAPHandler::addProduct(const QJsonValue& value) {
  if (!value.isObject()) {
    logger.log() << "Object expected for the single product";
    return;
  }

  QJsonObject obj = value.toObject();

  Product product;
  product.m_name = obj["id"].toString();
  product.m_type = productTypeToEnum(obj["type"].toString());
  product.m_featuredProduct = obj["featured_product"].toBool();

  if (product.m_type == ProductUnknown) {
    logger.log() << "Unknown product type:" << obj["type"].toString();
    return;
  }

  m_products.append(product);
}

IAPHandler::Product* IAPHandler::findProduct(const QString& productIdentifier) {
  for (Product& p : m_products) {
    if (p.m_name == productIdentifier) {
      return &p;
    }
  }
  return nullptr;
}


void IAPHandler::unknownProductRegistered(const QString& identifier) {
  logger.log() << "Product registration failed:" << identifier;
}

void IAPHandler::productRegistered(const QJsonValue& product) {
  logger.log() << "Product registered - " << product.toString();

  Q_ASSERT(m_productsRegistrationState == eRegistering);

  QString productIdentifier = product["sku"].toString();
  Product* productData = findProduct(productIdentifier);
  Q_ASSERT(productData);

  logger.log() << "Id:" << productIdentifier;
  logger.log() << "Title:" << product["title"].toString();
  logger.log() << "Description:" << product["description"].toString();

  QString priceValue = product["price"].toString();
  logger.log() << "Price:" << priceValue;

  /*
    QString monthlyPriceValue;
    int32_t mounthCount = productTypeToMonthCount(productData->m_type);
    Q_ASSERT(mounthCount >= 1);

    if (mounthCount == 1) {
      monthlyPriceNS = priceValue;
    } else {
      monthlyPriceNS = priceValue / monthCount;
    }
    QString monthlyPriceValue = QString(monthlyPriceNS);

    logger.log() << "Monthly Price:" << monthlyPriceValue; */

  productData->m_price = priceValue;
  productData->m_monthlyPrice = "13";
  productData->m_nonLocalizedMonthlyPrice = 12.222;
}

void IAPHandler::productsRegistrationCompleted() {
  logger.log() << "All the products has been registered";

  beginResetModel();

  computeSavings();

  m_productsRegistrationState = eRegistered;

  endResetModel();

  emit productsRegistered();
}

/* SUBSCRIBE */

void IAPHandler::subscribe(const QString& productIdentifier) {
  logger.log() << "Subscription required" << productIdentifier;
  emit subscriptionStarted(productIdentifier);
}

void IAPHandler::startSubscription(const QString& productIdentifier) {
  Q_ASSERT(m_productsRegistrationState == eRegistered);

  Product* product = findProduct(productIdentifier);
  Q_ASSERT(product);
  Q_ASSERT(product->m_productNS);

  if (m_subscriptionState != eInactive) {
    logger.log() << "No multiple IAP!";
    return;
  }

  m_subscriptionState = eActive;

  logger.log() << "Starting the subscription" << productIdentifier;

  // This goes to native code, and then comes back via onSkuDetailsReceived
  // where we then emit the productsRegistered() signal.
  auto appActivity = QtAndroid::androidActivity();
  auto appContext = activity.callObjectMethod("getApplicationContext",
                                              "()Landroid/content/Context;");
  auto jniString = QAndroidJniObject::fromString(data);

  QAndroidJniObject::callStaticMethod<void>(
      "org/mozilla/sarah/vpn/InAppPurchase", "purchaseProduct",
      "(Landroid/content/Context;Ljava/lang/String;Landroid/app/Activity)V",
      appContext.object(), jniString.object(), appActivity.object());
}

void IAPHandler::stopSubscription() {
  logger.log() << "Stop subscription";
  m_subscriptionState = eInactive;
}

void IAPHandler::processCompletedTransactions(const QStringList& ids) {
  logger.log() << "process completed transactions" << ids[0];
  // TO DO
}

/* UTILS */

void IAPHandler::computeSavings() {
  double monthlyPrice = 0;
  // Let's find the price for the monthly payment.
  for (const Product& product : m_products) {
    if (product.m_type == ProductMonthly) {
      monthlyPrice = product.m_nonLocalizedMonthlyPrice;
      break;
    }
  }

  if (monthlyPrice == 0) {
    logger.log() << "No monthly payment found";
    return;
  }

  // Compute the savings for all the other types.
  for (Product& product : m_products) {
    if (product.m_type == ProductMonthly) continue;

    int savings =
        qRound(100.00 -
               ((product.m_nonLocalizedMonthlyPrice * 100.00) / monthlyPrice));
    if (savings < 0 || savings > 100) continue;

    product.m_savings = (int)savings;

    logger.log() << "Saving" << product.m_savings << "for" << product.m_name;
  }
}

QHash<int, QByteArray> IAPHandler::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[ProductIdentifierRole] = "productIdentifier";
  roles[ProductPriceRole] = "productPrice";
  roles[ProductMonthlyPriceRole] = "productMonthlyPrice";
  roles[ProductTypeRole] = "productType";
  roles[ProductFeaturedRole] = "productFeatured";
  roles[ProductSavingsRole] = "productSavings";
  return roles;
}

int IAPHandler::rowCount(const QModelIndex&) const {
  if (m_productsRegistrationState != eRegistered) {
    return 0;
  }

  return m_products.count();
}

QVariant IAPHandler::data(const QModelIndex& index, int role) const {
  if (m_productsRegistrationState != eRegistered || !index.isValid()) {
    return QVariant();
  }

  switch (role) {
    case ProductIdentifierRole:
      return QVariant(m_products.at(index.row()).m_name);

    case ProductPriceRole:
      return QVariant(m_products.at(index.row()).m_price);

    case ProductMonthlyPriceRole:
      return QVariant(m_products.at(index.row()).m_monthlyPrice);

    case ProductTypeRole:
      return QVariant(m_products.at(index.row()).m_type);

    case ProductFeaturedRole:
      return QVariant(m_products.at(index.row()).m_featuredProduct);

    case ProductSavingsRole:
      return QVariant(m_products.at(index.row()).m_savings);

    default:
      return QVariant();
  }
}

// static
IAPHandler::ProductType IAPHandler::productTypeToEnum(const QString& type) {
  if (type == "yearly") return ProductYearly;
  if (type == "half-yearly") return ProductHalfYearly;
  if (type == "monthly") return ProductMonthly;
  return ProductUnknown;
}

// static
uint32_t IAPHandler::productTypeToMonthCount(ProductType type) {
  switch (type) {
    case ProductYearly:
      return 12;
    case ProductHalfYearly:
      return 6;
    case ProductMonthly:
      return 1;
    default:
      Q_ASSERT(false);
      return 1;
  }
}
