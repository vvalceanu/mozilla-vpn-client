/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "commanddevice.h"
#include "leakdetector.h"
#include "mozillavpn.h"
#include "tasks/accountandservers/taskaccountandservers.h"
#include "tasks/adddevice/taskadddevice.h"
#include "tasks/removedevice/taskremovedevice.h"

#include <QTextStream>
#include <QEventLoop>

CommandDevice::CommandDevice(QObject* parent)
    : Command(parent, "device", "View and edit the device list") {
  MVPN_COUNT_CTOR(CommandDevice);
}

CommandDevice::~CommandDevice() { MVPN_COUNT_DTOR(CommandDevice); }

int CommandDevice::run(QStringList& tokens) {
  Q_ASSERT(!tokens.isEmpty());
  QString appName = tokens[0];
  QString action = "list";
  if (tokens.count() > 1) {
    action = tokens[1];
  }

  return runCommandLineApp([&]() {
    if (!userAuthenticated()) {
      return 1;
    }

    MozillaVPN vpn;
    Task* task = nullptr;
    if (!loadModels()) {
      return 1;
    }

    if (action == "remove") {
      if (tokens.length() != 3) {
        QTextStream stream(stdout);
        stream << "usage: " << tokens[0] << action << "<device_id>" << Qt::endl;
        stream << Qt::endl;
        stream << "The list of <device_id> can be obtained using: 'status'"
               << Qt::endl;
        return 1;
      }

      QString deviceId = tokens[2];
      bool ok;
      int id = deviceId.toUInt(&ok);
      if (!ok) {
        QTextStream stream(stdout);
        stream << deviceId << " is not a valid number." << Qt::endl;
        return 1;
      }

      DeviceModel* dm = vpn.deviceModel();
      Q_ASSERT(dm);

      const QList<Device>& devices = dm->devices();
      if (id == 0 || id > devices.length()) {
        QTextStream stream(stdout);
        stream << deviceId << " is not a valid ID." << Qt::endl;
        return 1;
      }

      const Device& device = devices.at(id - 1);
      if (device.isCurrentDevice(vpn.keys())) {
        QTextStream stream(stdout);
        stream << "Removing the current device is not allowed. Use 'logout' "
                  "instead."
               << Qt::endl;
        return 1;
      }

      // Schedule the device removal.
      task = new TaskRemoveDevice(device.publicKey());
    } else if (action == "create") {
      if (tokens.length() != 4) {
        QTextStream stream(stdout);
        stream << "usage: " << tokens[0] << action << "<name> <pubkey>"
               << Qt::endl;
        stream << Qt::endl;
        return 1;
      }
      task = new TaskAddDevice(tokens[2], tokens[3]);
    } else if (action == "list") {
      task = new TaskAccountAndServers();
    } else {
      QTextStream stream(stdout);
      stream << "Unknown device action" << Qt::endl;
      stream << "usage: " << tokens[0] << "<action> [ARGUMENTS]" << Qt::endl;
      stream << Qt::endl;
      stream << "Supported actions: list, create, remove" << Qt::endl;
      return 1;
    }

    QEventLoop loop;
    QObject::connect(task, &Task::completed, [&] { loop.exit(); });

    task->run(&vpn);
    loop.exec();
    delete task;

    DeviceModel* dm = vpn.deviceModel();
    Q_ASSERT(dm);

    QTextStream stream(stdout);
    stream << "Active devices: " << dm->activeDevices() << Qt::endl;

    const Device* cd = dm->currentDevice(vpn.keys());
    if (cd) {
      stream << "Current devices:" << cd->name() << Qt::endl;
    }

    const QList<Device>& devices = dm->devices();
    for (int i = 0; i < devices.length(); ++i) {
      const Device& device = devices.at(i);
      stream << "Device " << (i + 1) << Qt::endl;
      stream << " - name: " << device.name() << Qt::endl;
      stream << " - creation time: " << device.createdAt().toString()
             << Qt::endl;
      stream << " - public key: " << device.publicKey() << Qt::endl;
      stream << " - ipv4 address: " << device.ipv4Address() << Qt::endl;
      stream << " - ipv6 address: " << device.ipv6Address() << Qt::endl;
    }

    return 0;
  });
}

static Command::RegistrationProxy<CommandDevice> s_commandDevice;
