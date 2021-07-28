/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "androidvpnactivity.h"

#include "mozillavpn.h"
#include "logger.h"

#include "jni.h"
#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QtAndroid>

namespace {
AndroidVPNActivity* instance = nullptr;
constexpr auto CLASSNAME = "org.mozilla.sarah.vpn.qt.VPNActivity";
Logger logger(LOG_ANDROID, "AndroidVPNActivity");
}  // namespace

AndroidVPNActivity::AndroidVPNActivity() {
  instance = this;
  QtAndroid::runOnAndroidThreadSync([]() {
    // Hook in the native implementation for startActivityForResult into the JNI
    JNINativeMethod methods[]{
        {"handleBackButton", "()Z", reinterpret_cast<bool*>(handleBackButton)},
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
}

void AndroidVPNActivity::init() {
  if (instance == nullptr) {
    instance = new AndroidVPNActivity();
  }
}

// static
bool AndroidVPNActivity::handleBackButton(JNIEnv* env, jobject thiz) {
  Q_UNUSED(env);
  Q_UNUSED(thiz);
  return MozillaVPN::instance()->closeEventHandler()->eventHandled();
}

// static
void AndroidVPNActivity::onSkuDetailsReceived(JNIEnv* env, jobject thiz,
                                              jstring sku) {
  Q_UNUSED(thiz);

  // From androidutils.cpp
  const char* buffer = env->GetStringUTFChars(sku, nullptr);
  if (!buffer) {
    // oh no
    return;
  }
  QString res = QString(buffer);
  env->ReleaseStringUTFChars(sku, buffer);

  logger.log() << "The string" << res;
}
