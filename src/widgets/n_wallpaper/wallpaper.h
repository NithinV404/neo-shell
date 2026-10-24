#pragma once
#include <QByteArray>
#include <QImage>
#include <QQuickItem>
#include <QUrl>
#include <qqmlintegration.h>
#include <qsharedpointer.h>

class WallpaperItem : public QQuickItem {
    QML_ELEMENT
    Q_OBJECT
    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged REQUIRED) 
    Q_PROPERTY(int fillMode READ fillMode WRITE setFillMode NOTIFY fillModeChanged)
    Q_PROPERTY(QSize size READ size WRITE setSize NOTIFY sizeChanged REQUIRED)

public:
    explicit WallpaperItem(QQuickItem *parent = nullptr);
    ~WallpaperItem() override = default;


    QUrl source() const { return m_source; }
    void setSource(const QUrl &source);

    int fillMode() const { return m_fillMode; }
    void setFillMode(int mode);

    const QSize size()  { return m_size; }
    void setSize(const QSize &size);

    static QByteArray compressToBc1(const QImage &image);

    static QImage readImage();

signals:
    void sourceChanged();
    void fillModeChanged();
    void sizeChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    QUrl m_source;
    QSize m_size;
    int m_fillMode = 1;          // 0 = stretch, 1 = preserveAspectCrop
    bool m_sourceDirty = true;   // touched on GUI thread, read in updatePaintNode (GUI blocked)
};