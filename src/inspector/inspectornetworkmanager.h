#ifndef INSPECTORNETWORKMANAGER_H
#define INSPECTORNETWORKMANAGER_H

#include "inspectornetworkreply.h"

#include <QObject>
#include <QNetworkRequest>

#include <QByteArray>
#include <QNetworkReply>
#include <QUrl>


class InspectorNetworkManager : public QObject
{
    Q_OBJECT
public:
    static InspectorNetworkManager* instance();

    QNetworkReply* post(QNetworkRequest& req, const QByteArray& body);
    QNetworkReply* get(QNetworkRequest& req);
    QNetworkReply* del(QNetworkRequest& req);

    QNetworkReply* synthetizeResponse(const QString& key);

    void addMockPath(QUrl path, QString method, int responseCode, QByteArray responseBody, QByteArray responseHeaders);
    void clearMockPath(QUrl path, QString method);
    void clearMocks();

private:
    QMap<QString, InspectorNetworkReply*> m_mocks;
    QString getMockKey(const QString& method, const QUrl& url);
    explicit InspectorNetworkManager(QObject *parent = nullptr);


signals:

};

#endif // INSPECTORNETWORKMANAGER_H
