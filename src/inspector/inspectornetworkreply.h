#ifndef INSPECTORNETWORKREPLY_H
#define INSPECTORNETWORKREPLY_H

#include <QNetworkReply>
#include <QObject>
#include <QBuffer>

class InspectorNetworkReply : public QNetworkReply
{
public:
    InspectorNetworkReply(QObject* parent, int responseCode, QByteArray responseBody, QByteArray responseHeaders);

    void abort() override{};

    qint64 readData(char *data, qint64 maxSize) override;

    QByteArray m_responseBody;
    QByteArray m_responseHeaders;
    QBuffer m_buffer;
};


#endif // INSPECTORNETWORKREPLY_H
