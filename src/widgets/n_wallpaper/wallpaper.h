#pragma once

#include <QByteArray>
#include <QImage>
#include <QQuickItem>
#include <QUrl>
#include <qqmlintegration.h>

class WallpaperItem : public QQuickItem {
    QML_ELEMENT
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int fillMode READ fillMode WRITE setFillMode NOTIFY fillModeChanged)

public:
    explicit WallpaperItem(QQuickItem *parent = nullptr);
    ~WallpaperItem() override = default;

    QUrl source() const { return m_source; }
    void setSource(const QUrl &source);

    int fillMode() const { return m_fillMode; }
    void setFillMode(int mode);

signals:
    void sourceChanged();
    void fillModeChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    static QByteArray compressToBc1(const QImage &image);

    QUrl m_source;
    int m_fillMode = 1;          // 0 = stretch, 1 = preserveAspectCrop
    bool m_sourceDirty = true;   // touched on GUI thread, read in updatePaintNode (GUI blocked)
};