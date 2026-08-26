#include "niri.hpp"
#include <qjsonobject.h>
#include <qjsondocument.h>
#include <qlocalsocket.h>
#include <qoverload.h>
#include <qprocess.h>
#include <qstringview.h>
#include <unistd.h>

NiriIpc::NiriIpc(QObject *parent) : QObject(parent) {
    m_socket = new QLocalSocket(this);
    connect(m_socket, &QLocalSocket::readyRead, this, &NiriIpc::onReadyRead);
    connect(m_socket, &QLocalSocket::errorOccurred, this, &NiriIpc::onError);
    connect(m_socket, &QLocalSocket::connected, this, &NiriIpc::connected);
    connect(m_socket, &QLocalSocket::disconnected, this, &NiriIpc::disconnected);
}

NiriIpc::~NiriIpc() {
    disconnectFromNiri();
}


bool NiriIpc::connectToNiri() {
    QString socketPath = QProcessEnvironment::systemEnvironment().value("NIRI_SOCKET");
    if(socketPath.isEmpty()) {
        QString runTimeDir = QProcessEnvironment::systemEnvironment().value("XDG_RUNTIME_DIR", "/run/user/" + QString::number(getuid()));
        socketPath = runTimeDir + "/niri.wayland-1." + QString::number(getpid()) + ".sock";

        emit errorOccured("NIRI_SOCKET env not set make sure niri is running");
        return false;
    }
    m_socket->connectToServer(socketPath);
    return m_socket->waitForConnected(2000);
}

void NiriIpc::disconnectFromNiri() {
    if(m_socket->state() != QLocalSocket::LocalSocketState::UnconnectedState)
    {
        m_socket->disconnectFromServer();
    }
}

void NiriIpc::sendRequest(const QJsonObject &request) {
    if(!isConnected()) {
        emit errorOccured("Niri not connected");
    }
    QJsonDocument doc(request);
    QByteArray data = doc.toJson(QJsonDocument::Compact) + "\n";
    m_socket->write(data);
    m_socket->flush();
}

void NiriIpc::startEventStream() {
    m_eventStreamMode = true;
    sendRequest(QJsonObject{{"EventStream", QJsonValue::Null}});
}
void NiriIpc::requestWindows()       { sendRequest(QJsonObject{{"Windows", QJsonValue::Null}}); }
void NiriIpc::requestWorkspaces()    { sendRequest(QJsonObject{{"Workspaces", QJsonValue::Null}}); }
void NiriIpc::requestFocusedWindow() { sendRequest(QJsonObject{{"FocusedWindow", QJsonValue::Null}}); }
void NiriIpc::requestOutputs()       { sendRequest(QJsonObject{{"Outputs", QJsonValue::Null}}); }

void NiriIpc::sendAction(const QJsonObject &action)
{
    QJsonObject req;
    req["Action"] = action;
    sendRequest(req);
}

bool NiriIpc::isConnected() const {
    return m_socket->state() == QLocalSocket::LocalSocketState::ConnectedState;
};

void NiriIpc::onReadyRead() {
    m_buffer.append(m_socket->readAll());
    int idx;
    while((idx = m_buffer.indexOf("\n")) != -1) {
        QByteArray line = m_buffer.left(idx).trimmed();
        m_buffer.remove(0, idx+1);
        if(!line.isEmpty()) {
            processLine(line);
        }
    }
}

void NiriIpc::processLine(const QByteArray &line) {
    QJsonDocument doc = QJsonDocument::fromJson(line);
    if(doc.isNull() || !doc.isObject()) {
        emit errorOccured("Invalid JSON received: " + QString(line));
        return;
    }
    QJsonObject obj = doc.object();
    if(m_eventStreamMode) {
        emit eventReceived(obj);
    }
    else {
        emit replyReceived(obj);
    }
}


void NiriIpc::onError(const QLocalSocket::LocalSocketError &socketError)
{
    Q_UNUSED(socketError)
    emit errorOccured(m_socket->errorString());
}
