/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "captiveportalmonitor.h"
#include "captiveportalrequesttask.h"
#include "leakdetector.h"
#include "logger.h"
#include "taskscheduler.h"

constexpr uint32_t CAPTIVE_PORTAL_MONITOR_MSEC = 10000;

namespace {
Logger logger(LOG_NETWORKING, "CaptivePortalMonitor");
}

CaptivePortalMonitor::CaptivePortalMonitor(QObject* parent) : QObject(parent) {
  MVPN_COUNT_CTOR(CaptivePortalMonitor);

  connect(&m_timer, &QTimer::timeout, this, &CaptivePortalMonitor::check);
}

CaptivePortalMonitor::~CaptivePortalMonitor() {
  MVPN_COUNT_DTOR(CaptivePortalMonitor);
}

void CaptivePortalMonitor::start() {
  logger.debug() << "Captive portal monitor start";
  m_timer.start(CAPTIVE_PORTAL_MONITOR_MSEC);
}

void CaptivePortalMonitor::stop() {
  logger.debug() << "Captive portal monitor stop";
  m_timer.stop();
}

void CaptivePortalMonitor::check() {
  logger.debug() << "Checking the internet connectivity";

  CaptivePortalRequestTask* task = new CaptivePortalRequestTask(false);
  connect(task, &CaptivePortalRequestTask::operationCompleted, this,
          [this](CaptivePortalRequest::CaptivePortalResult result) {
            logger.debug() << "Captive portal detection:" << result;

            if (result != CaptivePortalRequest::CaptivePortalResult::NoPortal ||
                !m_timer.isActive()) {
              return;
            }

            // It seems that the captive-portal is gone. We can reactivate the
            // VPN.
            emit online();
          });

  TaskScheduler::scheduleTask(task);
}
