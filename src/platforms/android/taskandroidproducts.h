/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TASKANDROIDPRODUCTS_H
#define TASKANDROIDPRODUCTS_H

#include "task.h"

#include <QObject>

class TaskAndroidProducts final : public Task {
  Q_DISABLE_COPY_MOVE(TaskAndroidProducts)

 public:
  TaskAndroidProducts();
  ~TaskAndroidProducts();

  void run(MozillaVPN* vpn) override;
};

#endif  // TASKANDROIDPRODUCTS_H
