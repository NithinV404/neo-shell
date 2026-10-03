#include "Clock.h"

ClockService::ClockService(QObject *parent) : QObject(parent) {
    m_dateTime = QDateTime::currentDateTime();

    // fire once now, then align to the next minute boundary
    connect(&m_timer, &QTimer::timeout, this, &ClockService::tick);
    m_timer.start(1000);
}

void ClockService::tick() {
    auto now = QDateTime::currentDateTime();
    if (now.time().minute() != m_dateTime.time().minute() ||
        now.date() != m_dateTime.date()) {
        m_dateTime = now;
        emit timeChanged();
    }
}

QString ClockService::time() const {
    return m_dateTime.toString("hh:mm AP");
}

QString ClockService::date() const {
    return m_dateTime.toString("ddd MM/dd");
}
