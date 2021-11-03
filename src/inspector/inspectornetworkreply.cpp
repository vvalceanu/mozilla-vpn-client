#include "inspectornetworkreply.h"

InspectorNetworkReply::InspectorNetworkReply(QObject* parent, int responseCode, QByteArray responseBody, QByteArray responseHeaders): QNetworkReply(parent),
    m_responseBody(responseBody),
    m_responseHeaders(responseHeaders),
    m_buffer(&m_responseBody,this)
{
    setAttribute(QNetworkRequest::HttpStatusCodeAttribute,responseCode);
    // TODO: set headers one by one.
}
qint64 InspectorNetworkReply::readData(char *data, qint64 maxSize){
    return m_buffer.read(data,maxSize);
}
