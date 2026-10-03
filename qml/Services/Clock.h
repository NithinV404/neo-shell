#pragma once
#include <QObject>
#include <QDateTime>
#include <QTimer>

class ClockService : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString time READ time NOTIFY timeChanged)
    Q_PROPERTY(QString date READ date NOTIFY timeChanged)
    Q_PROPERTY(QDateTime dateTime READ dateTime NOTIFY timeChanged)

public:
    explicit ClockService(QObject *parent = nullptr);

    QString time() const;
    QString date() const;
    QDateTime dateTime() const { return m_dateTime; }

signals:
    void timeChanged();

private slots:
    void tick();

private:
    QDateTime m_dateTime;
    QTimer m_timer;
};
