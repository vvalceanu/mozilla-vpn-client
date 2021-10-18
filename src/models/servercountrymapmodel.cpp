/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "servercountrymapmodel.h"
#include "servercountrymodel.h"
#include "leakdetector.h"
#include "logger.h"
#include "mozillavpn.h"

namespace {
Logger logger(LOG_MODEL, "ServerCountryMapModel");
}

ServerCountryMapModel::ServerCountryMapModel() {
  MVPN_COUNT_CTOR(ServerCountryMapModel);
}

ServerCountryMapModel::~ServerCountryMapModel() {
  MVPN_COUNT_DTOR(ServerCountryMapModel);
}

QHash<int, QByteArray> ServerCountryMapModel::roleNames() const {
  QHash<int, QByteArray> roles;
  roles[NameRole] = "name";
  roles[CountryCodeRole] = "countryCode";
  roles[LatitudeRole] = "latitude";
  roles[LongitudeRole] = "longitude";
  return roles;
}

int ServerCountryMapModel::rowCount(const QModelIndex&) const {
  ServerCountryModel* scm = MozillaVPN::instance()->serverCountryModel();
  Q_ASSERT(scm);

  int count = 0;
  for (const ServerCountry& country : scm->countries()) {
    count += country.cities().length();
  }

  return count;
}

QVariant ServerCountryMapModel::data(const QModelIndex& index, int role) const {
  if (!index.isValid()) {
    return QVariant();
  }

  ServerCountryModel* scm = MozillaVPN::instance()->serverCountryModel();
  Q_ASSERT(scm);

  int pos = index.row();
  for (const ServerCountry& country : scm->countries()) {
    if (pos >= country.cities().length()) {
      pos -= country.cities().length();
      continue;
    }

    const ServerCity& city = country.cities().at(pos);
    switch (role) {
      case NameRole:
        return QVariant(city.name());

      case CountryCodeRole:
        return QVariant(country.code());

      case LatitudeRole:
        return QVariant(city.latitude());

      case LongitudeRole:
        return QVariant(city.longitude());

      default:
        return QVariant();
    }
  }

  return QVariant();
}
