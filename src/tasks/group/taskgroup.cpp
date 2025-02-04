/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "taskgroup.h"
#include "leakdetector.h"
#include "logger.h"

namespace {
Logger logger(LOG_MAIN, "TaskGroup");
}

TaskGroup::TaskGroup(std::initializer_list<Task*> list)
    : Task("TaskGroup"), m_tasks(list) {
  MVPN_COUNT_CTOR(TaskGroup);
}

TaskGroup::~TaskGroup() {
  MVPN_COUNT_DTOR(TaskGroup);

  for (Task* task : m_tasks) {
    task->deleteLater();
  }
}

void TaskGroup::run() {
  for (Task* task : m_tasks) {
    connect(task, &Task::completed, this, [this, task]() {
      m_tasks.removeOne(task);
      task->deleteLater();
      maybeComplete();
    });

    logger.debug() << "Running subtask:" << task->name();
    task->run();
  }

  maybeComplete();
}

void TaskGroup::maybeComplete() {
  if (m_tasks.isEmpty()) {
    emit completed();
  }
}

void TaskGroup::cancel() {
  Task::cancel();
  for (Task* task : m_tasks) {
    task->cancel();
  }
}

bool TaskGroup::deletable() const {
  for (Task* task : m_tasks) {
    if (!task->deletable()) return false;
  }
  return true;
}
