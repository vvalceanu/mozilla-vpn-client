/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "serverdata.h"
#include "leakdetector.h"
#include "logger.h"
#include "mozillavpn.h"
#include "servercountrymodel.h"
#include "serveri18n.h"
#include "settingsholder.h"

namespace {
Logger logger(LOG_MODEL, "ServerData");
}

ServerData::ServerData() { MVPN_COUNT_CTOR(ServerData); }

ServerData::~ServerData() { MVPN_COUNT_DTOR(ServerData); }

bool ServerData::fromSettings() {
  SettingsHolder* settingsHolder = SettingsHolder::instance();
  Q_ASSERT(settingsHolder);

  if (!settingsHolder->hasCurrentServerCountryCode() ||
      !settingsHolder->hasCurrentServerCity()) {
    return false;
  }

  initializeInternal(settingsHolder->currentServerCountryCode(),
                     settingsHolder->currentServerCity(),
                     settingsHolder->entryServerCountryCode(),
                     settingsHolder->entryServerCity());

  logger.debug() << toString();
  return true;
}

bool ServerData::fromString(const QString& data) {
  QStringList serverList = data.split("->");

  QString exit = serverList.last();
  int index = exit.lastIndexOf(',');
  if (index < 0) {
    return false;
  }
  QString exitCountryCode = exit.mid(index + 1).trimmed();
  QString exitCityName = exit.left(index).trimmed();
  QString entryCountryCode;
  QString entryCityName;

  if (serverList.count() > 1) {
    QString entry = serverList.first();
    index = entry.lastIndexOf(',');
    if (index > 0) {
      entryCityName = entry.left(index).trimmed();
      entryCountryCode = entry.mid(index + 1).trimmed();
    }
  }

  initializeInternal(exitCountryCode, exitCityName, entryCountryCode,
                     entryCityName);

  logger.debug() << toString();
  return true;
}

void ServerData::writeSettings() {
  SettingsHolder* settingsHolder = SettingsHolder::instance();
  Q_ASSERT(settingsHolder);

  settingsHolder->setCurrentServerCountryCode(m_exitCountryCode);
  settingsHolder->setCurrentServerCity(m_exitCityName);

  if (multihop()) {
    settingsHolder->setEntryServerCountryCode(m_entryCountryCode);
    settingsHolder->setEntryServerCity(m_entryCityName);
  } else {
    settingsHolder->removeEntryServer();
  }
}

void ServerData::update(const QString& countryCode, const QString& cityName,
                        const QString& entryCountryCode,
                        const QString& entryCityName) {
  logger.debug() << "Country:" << countryCode << "City:" << cityName;
  initializeInternal(countryCode, cityName, entryCountryCode, entryCityName);
  emit changed();
}

void ServerData::initializeInternal(const QString& exitCountryCode,
                                    const QString& exitCityName,
                                    const QString& entryCountryCode,
                                    const QString& entryCityName) {
  m_initialized = true;
  m_exitCountryCode = exitCountryCode;
  m_exitCityName = exitCityName;
  m_entryCountryCode = entryCountryCode;
  m_entryCityName = entryCityName;
}

QString ServerData::localizedCityName() const {
  return ServerI18N::translateCityName(m_exitCountryCode, m_exitCityName);
}

QString ServerData::localizedEntryCity() const {
  return ServerI18N::translateCityName(m_entryCountryCode, m_entryCityName);
}

QString ServerData::toString() const {
  if (!m_initialized) {
    return QString();
  }

  QString result = "";
  if (multihop()) {
    result += m_entryCityName + ", " + m_entryCountryCode + " -> ";
  }

  result += m_exitCityName + ", " + m_exitCountryCode;
  return result;
}

double ServerData::exitLatitude() const {
  if (!m_initialized) {
    return 0;
  }

  const ServerCity* city = currentExitCity();
  if (!city) {
    return 0;
  }

  return city->latitude();
}

double ServerData::exitLongitude() const {
  if (!m_initialized) {
    return 0;
  }

  const ServerCity* city = currentExitCity();
  if (!city) {
    return 0;
  }

  return city->longitude();
}

const ServerCity* ServerData::currentExitCity() const {
  if (!m_initialized) {
    return nullptr;
  }

  ServerCountryModel* scm = MozillaVPN::instance()->serverCountryModel();
  Q_ASSERT(scm);

  for (const ServerCountry& country : scm->countries()) {
    if (country.code() == m_exitCountryCode) {
      for (const ServerCity& city : country.cities()) {
        if (city.name() == m_exitCityName) {
          return &city;
        }
      }
    }
  }

  return nullptr;
}
