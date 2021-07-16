/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "taskandroidproducts.h"
#include "iaphandler.h"
#include "leakdetector.h"
#include "logger.h"
#include "mozillavpn.h"
#include "networkrequest.h"

namespace {
Logger logger(LOG_IAP, "TaskAndroidProducts");
}

TaskAndroidProducts::TaskAndroidProducts() : Task("TaskAndroidProducts") {
  MVPN_COUNT_CTOR(TaskAndroidProducts);
}

TaskAndroidProducts::~TaskAndroidProducts() {
  MVPN_COUNT_DTOR(TaskAndroidProducts);
}

void TaskAndroidProducts::run(MozillaVPN* vpn) {
  NetworkRequest* request = NetworkRequest::createForAndroidProducts(this);

  connect(request, &NetworkRequest::requestFailed,
          [this, vpn](QNetworkReply::NetworkError error, const QByteArray&) {
            logger.log() << "Android product request failed" << error;
            vpn->errorHandle(ErrorHandler::toErrorType(error));
            emit completed();
          });

  connect(request, &NetworkRequest::requestCompleted,
          [this](const QByteArray& data) {
            logger.log() << "Android product request completed" << data;

            IAPHandler* ipaHandler = IAPHandler::instance();
            Q_ASSERT(ipaHandler);

            connect(ipaHandler, &IAPHandler::productsRegistered, this,
                    &TaskAndroidProducts::completed);
            ipaHandler->registerProducts(data);
          });
}
