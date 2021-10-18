/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef SERVERCOUNTRYMAPMODEL_H
#define SERVERCOUNTRYMAPMODEL_H

#include "servercountry.h"
#include "servercountrymapmodel.h"

#include <QAbstractListModel>
#include <QByteArray>
#include <QHash>
#include <QObject>

class ServerData;
class ServerExtra;

class ServerCountryMapModel final : public QAbstractListModel {
  Q_OBJECT
  Q_DISABLE_COPY_MOVE(ServerCountryMapModel)

 public:
  enum ServerCountryRoles {
    NameRole = Qt::UserRole + 1,
    CountryCodeRole,
    LatitudeRole,
    LongitudeRole,
  };

  ServerCountryMapModel();
  ~ServerCountryMapModel();

  // QAbstractListModel methods

  QHash<int, QByteArray> roleNames() const override;

  int rowCount(const QModelIndex&) const override;

  QVariant data(const QModelIndex& index, int role) const override;
};

#endif  // SERVERCOUNTRYMAPMODEL_H
