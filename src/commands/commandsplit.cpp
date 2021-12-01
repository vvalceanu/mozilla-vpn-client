/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "commandsplit.h"
#include "commandlineparser.h"
#include "leakdetector.h"
#include "mozillavpn.h"
#include "settingsholder.h"
#include "simplenetworkmanager.h"

#include <QEventLoop>
#include <QTextStream>

#ifdef MVPN_LINUX 
 #include <unistd.h>
#endif

CommandSplit::CommandSplit(QObject* parent)
    : Command(parent, "split", "<app> starts an app and excludes it from the VPN") {
  MVPN_COUNT_CTOR(CommandSplit);
}

CommandSplit::~CommandSplit() { MVPN_COUNT_DTOR(CommandSplit); }

int CommandSplit::run(QStringList& tokens) {
  Q_ASSERT(!tokens.isEmpty());
  return runCommandLineApp([&]() {
    QString appName = tokens[0];
    Q_ASSERT(tokens[1] == "split");
    QString targetApp= tokens[2];

    if(targetApp.isEmpty()){
      QTextStream stream(stdout);
      stream << "Please pass an appname ";
      return 0;
    }

    MozillaVPN vpn;
    QEventLoop loop;
    QObject::connect(vpn.controller(), &Controller::stateChanged, [&] {
      if (vpn.controller()->state() == Controller::StateOff ||
          vpn.controller()->state() == Controller::StateOn) {
        loop.exit();
      }
    });
    vpn.controller()->initialize();
    loop.exec(); 

    if (vpn.controller()->state() != Controller::StateOn) {
      QTextStream stream(stdout);
      stream << "The VPN tunnel is not active" << Qt::endl;
      return 0;
    }
    #ifdef MVPN_LINUX
    int pid = getpid();

    bool ok = vpn.controller()->excludeRunningApp(targetApp, pid);

    if(!ok){
      QTextStream stream(stdout);
      stream << "Not supported" << Qt::endl;
      return 0;
    }
    return execl(targetApp.constData(), nullptr, nullptr);
    #else 
      QTextStream stream(stdout);
      stream << "Not supported" << Qt::endl;
      return 0;
    #endif
  });
}

static Command::RegistrationProxy<CommandSplit> s_commandSplit;
