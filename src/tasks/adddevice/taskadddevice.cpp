/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "taskadddevice.h"
#include "curve25519.h"
#include "errorhandler.h"
#include "leakdetector.h"
#include "logger.h"
#include "mozillavpn.h"
#include "networkrequest.h"

#include <QRandomGenerator>

namespace {
Logger logger(LOG_MAIN, "TaskAddDevice");
}

TaskAddDevice::TaskAddDevice(const QString& deviceName, const QString& pubkey)
    : Task("TaskAddDevice"), m_deviceName(deviceName), m_publicKey(pubkey) {
  MVPN_COUNT_CTOR(TaskAddDevice);
}

TaskAddDevice::~TaskAddDevice() { MVPN_COUNT_DTOR(TaskAddDevice); }

void TaskAddDevice::run(MozillaVPN* vpn) {
  NetworkRequest* request =
      NetworkRequest::createForDeviceCreation(this, m_deviceName, m_publicKey);

  connect(request, &NetworkRequest::requestFailed,
          [this, vpn](QNetworkReply::NetworkError error, const QByteArray&) {
            logger.log() << "Failed to add the device" << error;
            vpn->errorHandle(ErrorHandler::toErrorType(error));
            emit completed();
          });

  connect(request, &NetworkRequest::requestCompleted,
          [this](const QByteArray&) {
            logger.log() << "Added device:" << m_deviceName;
            emit completed();
          });
}

// static
QPair<QByteArray, QByteArray> TaskAddDevice::generateKeypair() {
  QByteArray keyBytes;

  QRandomGenerator* generator = QRandomGenerator::system();
  Q_ASSERT(generator);

  for (uint8_t i = 0; i < CURVE25519_KEY_SIZE; ++i) {
    quint32 v = generator->generate();
    keyBytes.append(v & 0xFF);
  }

  QByteArray privateKey = keyBytes.toBase64();
  QByteArray publicKey = Curve25519::generatePublicKey(privateKey);
  return QPair<QByteArray, QByteArray>(privateKey, publicKey);
}
