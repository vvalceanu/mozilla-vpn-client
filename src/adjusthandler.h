/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef ADJUSTHELPER_H
#define ADJUSTHELPER_H

#include <QString>

class AdjustHandler {
 public:
  enum AdjustEvent {
    SubscriptionCompleted,
  };

  AdjustHandler() = default;

  static void initialize();
  static void trackEvent(AdjustEvent event);

 private:
  static const QString eventToToken(AdjustEvent event);
};

#endif  // ADJUSTHELPER_H
