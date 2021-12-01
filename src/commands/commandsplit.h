/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef COMMANDSPLIT_H
#define COMMANDSPLIT_H

#include "command.h"

class CommandSplit final : public Command {
 public:
  explicit CommandSplit(QObject* parent);
  ~CommandSplit();

  int run(QStringList& tokens) override;
};

#endif  // COMMANDSPLIT_H
