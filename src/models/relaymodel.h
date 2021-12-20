/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef RELAYMODEL_H
#define RELAYMODEL_H

#include <QAbstractListModel>

class RelayModel final : public QAbstractListModel {
  Q_OBJECT
  Q_DISABLE_COPY_MOVE(RelayModel)

 public:
  RelayModel();
  ~RelayModel();

  enum ModelRoles {
    AddressRole = Qt::UserRole + 1,
    DescriptionRole,
    IdRole,
    NumBlockedRole,
    NumSpamRole,
    NumForwardedRole,
  };

  // We don't want to load the licenses if not needed.
  Q_INVOKABLE void initialize();

  Q_INVOKABLE void copyAddress(int id);
  Q_INVOKABLE void deleteAddress(int id);

  void update(const QByteArray& data);

  // QAbstractListModel methods

  QHash<int, QByteArray> roleNames() const override;

  int rowCount(const QModelIndex&) const override;

  QVariant data(const QModelIndex& index, int role) const override;

 private:
  struct RelayAddress {
    QString m_address;
    QString m_description;
    int m_id;
    int m_numBlocked;
    int m_numSpam;
    int m_numForwarded;
  };

  QList<RelayAddress> m_addresses;
};

#endif  // RELAYMODEL_H
