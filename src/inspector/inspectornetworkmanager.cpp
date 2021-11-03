#include "inspectornetworkmanager.h"

#include "mozillavpn.h"
#include "networkmanager.h"
#include "inspectornetworkreply.h"



namespace {
InspectorNetworkManager* s_instance = nullptr;
}

// static
InspectorNetworkManager* InspectorNetworkManager::instance(){
    if(!s_instance){
        s_instance = new InspectorNetworkManager(MozillaVPN::instance());
    }
    return s_instance;
}

InspectorNetworkManager::InspectorNetworkManager(QObject *parent) : QObject(parent){}


QNetworkReply* InspectorNetworkManager::post(QNetworkRequest& req, const QByteArray& body){
    auto key = getMockKey("POST",req.url());
    if(m_mocks.contains(key)){
        return synthetizeResponse(key);
    }
    return NetworkManager::instance()->networkAccessManager()->post(req,body);
}

QNetworkReply* InspectorNetworkManager::get(QNetworkRequest& req){
    auto key = getMockKey("GET",req.url());
    if(m_mocks.contains(key)){
        return synthetizeResponse(key);
    }
    return NetworkManager::instance()->networkAccessManager()->get(req);
}

QNetworkReply* InspectorNetworkManager::del(QNetworkRequest& req){
    auto key = getMockKey("DELETE",req.url());
    if(m_mocks.contains(key)){
        return synthetizeResponse(key);
    }
    return NetworkManager::instance()->networkAccessManager()->sendCustomRequest(req, "DELETE");
}


// Returns a key for the Request to use in m_mocks
QString InspectorNetworkManager::getMockKey(const QString& method, const QUrl& url){
    return QString("%0;%1;%2").arg(method).arg(url.host()).arg(url.path());
}

void InspectorNetworkManager::addMockPath(QUrl path, QString method, int responseCode, QByteArray responseBody, QByteArray responseHeaders ){
    auto reply = new InspectorNetworkReply(this,responseCode,responseBody,responseHeaders);

    m_mocks.insert(getMockKey(method,path),reply);
}

void InspectorNetworkManager::clearMockPath(QUrl path, QString method){
    m_mocks.value(getMockKey(method,path))->deleteLater();
    m_mocks.remove(getMockKey(method,path));
}
void InspectorNetworkManager::clearMocks(){
    for(InspectorNetworkReply* m : m_mocks){
        m->deleteLater();
    }
    m_mocks.clear();
}
QNetworkReply* InspectorNetworkManager::synthetizeResponse(const QString& key){
    return m_mocks.value(key);
}

