#pragma once

#include <qjsonobject.h>
#include <qobject.h>
#include <qlocalsocket.h>
#include <qstringview.h>

class NiriIpc : public QObject {
    Q_OBJECT

    public:
        explicit NiriIpc(QObject *parent = nullptr);
        ~NiriIpc() override;
        QByteArray m_buffer;

        bool connectToNiri();
        void disconnectFromNiri();


        void sendRequest(const QJsonObject &request);

        void startEventStream();
        void requestWindows();
        void requestWorkspaces();
        void requestFocusedWindow();
        void requestOutputs();
        void sendAction(const QJsonObject &action);

        bool isConnected() const;

    signals:
        void connected();
        void disconnected();
        void replyReceived(const QJsonObject &reply);
        void eventReceived(const QJsonObject &event);
        void errorOccured(const QString &error);

    private slots:
        void onReadyRead();
        void onError(const QLocalSocket::LocalSocketError &error);

    private:
        QLocalSocket *m_socket = nullptr;
        bool m_eventStreamMode = false;

        void processLine(const QByteArray &line);

};
