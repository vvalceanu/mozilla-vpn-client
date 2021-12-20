/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "relaymodel.h"
#include "leakdetector.h"
#include "logger.h"
#include "mozillavpn.h"
#include "networkrequest.h"
#include "task.h"
#include "taskscheduler.h"

#include <QClipboard>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QScopeGuard>

namespace {
Logger logger(LOG_MODEL, "RelayModel");

class TaskRelayModelAddresses final : public Task {
 public:
  TaskRelayModelAddresses() : Task("TaskRelayModelAddresses") {}

  void run() override {
    NetworkRequest* request = NetworkRequest::createForRelayAddresses(this);
    connect(request, &NetworkRequest::requestFailed,
            [this](QNetworkReply::NetworkError error, const QByteArray&) {
              logger.error() << "Request failed" << error;
              emit completed();
            });

    connect(request, &NetworkRequest::requestCompleted, this,
            [this](const QByteArray& data) {
              logger.debug() << "Request completed";

              MozillaVPN::instance()->relayModel()->update(data);
              emit completed();
            });
  }
};

class TaskRelayModelDeleteAddress final : public Task {
 public:
  TaskRelayModelDeleteAddress(int id)
      : Task("TaskRelayModelDeleteAddress"), m_id(id) {}

  void run() override {
    NetworkRequest* request =
        NetworkRequest::createForRelayDeleteAddress(this, m_id);
    connect(request, &NetworkRequest::requestFailed,
            [this](QNetworkReply::NetworkError error, const QByteArray&) {
              logger.error() << "Request failed" << error;
              emit completed();
            });

    connect(request, &NetworkRequest::requestCompleted, this,
            [this](const QByteArray&) {
              logger.debug() << "Request completed";

              MozillaVPN::instance()->relayModel()->initialize();
              emit completed();
            });
  }

 private:
  int m_id;
};

}  // namespace

RelayModel::RelayModel() { MVPN_COUNT_CTOR(RelayModel); }

RelayModel::~RelayModel() { MVPN_COUNT_DTOR(RelayModel); }

QHash<int, QByteArray> RelayModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[AddressRole] = "address";
  roles[DescriptionRole] = "description";
  roles[IdRole] = "idAddress";
  roles[NumBlockedRole] = "numBlocked";
  roles[NumSpamRole] = "numSpam";
  roles[NumForwardedRole] = "numForwarded";
  return roles;
}

int RelayModel::rowCount(const QModelIndex&) const {
  return m_addresses.count();
}

QVariant RelayModel::data(const QModelIndex& index, int role) const {
  if (!index.isValid()) {
    return QVariant();
  }

  switch (role) {
    case AddressRole:
      return QVariant(m_addresses.at(index.row()).m_address);

    case DescriptionRole:
      return QVariant(m_addresses.at(index.row()).m_description);

    case IdRole:
      return QVariant(m_addresses.at(index.row()).m_id);

    case NumBlockedRole:
      return QVariant(m_addresses.at(index.row()).m_numBlocked);

    case NumSpamRole:
      return QVariant(m_addresses.at(index.row()).m_numSpam);

    case NumForwardedRole:
      return QVariant(m_addresses.at(index.row()).m_numForwarded);

    default:
      return QVariant();
  }
}

void RelayModel::initialize() {
  TaskScheduler::scheduleTask(new TaskRelayModelAddresses());
}

void RelayModel::update(const QByteArray& data) {
  logger.debug() << data;

  beginResetModel();
  auto guard = qScopeGuard([&] { endResetModel(); });

  m_addresses.clear();

  QJsonDocument doc = QJsonDocument::fromJson(data);
  if (!doc.isArray()) {
    return;
  }

  QJsonArray array = doc.array();
  for (const QJsonValue entry : array) {
    if (!entry.isObject()) continue;

    QJsonObject obj = entry.toObject();
    if (!obj["enabled"].toBool()) continue;

    int id = obj["id"].toInt();
    QString address = obj["full_address"].toString();
    QString description = obj["description"].toString();
    int numBlocked = obj["num_blocked"].toInt();
    int numSpam = obj["num_spam"].toInt();
    int numForwarded = obj["num_forwarded"].toInt();

    m_addresses.append(RelayAddress{address, description, id, numBlocked,
                                    numSpam, numForwarded});
  }
}

void RelayModel::deleteAddress(int id) {
  TaskScheduler::scheduleTask(new TaskRelayModelDeleteAddress(id));
}

void RelayModel::copyAddress(int id) {
  for (const RelayAddress& address : m_addresses) {
    if (address.m_id == id) {
      QGuiApplication::clipboard()->setText(address.m_address);
      break;
    }
  }
}
