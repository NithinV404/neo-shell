#include "wallpaper.h"
#include "QQmlContext"
#include "QQmlEngine"
#include <QImageReader>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <QSGTexture>
#include <qhash.h>
#include <qhashfunctions.h>
#include <qlogging.h>
#include <qnumeric.h>
#include <qsharedpointer.h>
#include <qsize.h>
#include <qstringview.h>
#include <rhi/qrhi.h>
#include <bc1_compression.h>

#include <malloc.h>

#define STB_DXT_IMPLEMENTATION
#include "stb_dxt.h"


WallpaperItem::WallpaperItem(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
}

void WallpaperItem::setSource(const QUrl &source) {
    if (m_source == source)
        return;
    m_source = source;
    m_sourceDirty = true;
    emit sourceChanged();
    update();
}


void WallpaperItem::setFillMode(int mode) {
    if (m_fillMode == mode)
        return;
    m_fillMode = mode;
    emit fillModeChanged();
    update();
}

void WallpaperItem::setSize(const QSize &size) {
    if (m_size == size)
        return;
    m_size = size;
    emit sizeChanged();
    update();
}

// Runs on the render thread while the GUI thread is blocked.
QSGNode *WallpaperItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
    if (m_source.isEmpty() || !window()) {
        delete oldNode; // also deletes the owned texture
        m_sourceDirty = true;
        return nullptr;
    }

    auto *node = static_cast<QSGSimpleTextureNode *>(oldNode);
    if (!node) {
        node = new QSGSimpleTextureNode();
        node->setOwnsTexture(true); // node deletes texture on replace / destruction
        m_sourceDirty = true;       // fresh node (e.g. after scene graph invalidation)
    }

    if (m_sourceDirty) {

        QSGTexture *tex = nullptr;
        QRhi *rhi = window()->rhi();

        if (rhi && rhi->isTextureFormatSupported(QRhiTexture::BC1)) {
            tex = new neoshell::Bc1Texture(m_source, m_size); // no convertTo needed anymore
        } else {
            tex = window()->createTextureFromImage(neoshell::Bc1Texture::readImage(m_source, m_size));
        }
        if (!tex) {
            delete node;
            return nullptr;
        }

        node->setTexture(tex); // deletes the previous texture (we own it)
        malloc_trim(0);
        m_sourceDirty = false;
    }

    QSGTexture *tex = node->texture();
    const QSizeF texSize = tex->textureSize();
    const QRectF br = boundingRect();
    QRectF srcRect(QPointF(0, 0), texSize);

    if (m_fillMode == 1 && br.height() > 0 && texSize.height() > 0) { // preserveAspectCrop
        const qreal sa = br.width() / br.height();
        const qreal ia = texSize.width() / texSize.height();
        if (sa > ia) { // item is wider: crop top/bottom
            const qreal h = ia / sa;
            srcRect.setTop((1.0 - h) / 2.0 * texSize.height());
            srcRect.setHeight(h * texSize.height());
        } else { // item is taller: crop left/right
            const qreal w = sa / ia;
            srcRect.setLeft((1.0 - w) / 2.0 * texSize.width());
            srcRect.setWidth(w * texSize.width());
        }
    }

    node->setRect(br);
    node->setSourceRect(srcRect);
    node->setFiltering(QSGTexture::Linear);
    return node;
}