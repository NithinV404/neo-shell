#include "wallpaper.h"

#include <QImageReader>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <QSGTexture>
#include <qlogging.h>
#include <qnumeric.h>
#include <rhi/qrhi.h>

#include <algorithm>
#include <cstring>
#include <malloc.h>

#define STB_DXT_IMPLEMENTATION
#include "stb_dxt.h"

namespace {

// A QSGTexture backed by a BC1-compressed QRhiTexture.
// The RHI texture is created and uploaded lazily in commitTextureOperations(),
// which the scene graph calls on the render thread with a resource update
// batch that it submits for you.
class Bc1Texture : public QSGTexture {
public:
    Bc1Texture(QByteArray data, QSize size) : m_data(std::move(data)), m_size(size) {}
    ~Bc1Texture() override { delete m_tex; }

    qint64 comparisonKey() const override {
        return qint64(reinterpret_cast<quintptr>(m_tex ? static_cast<const void *>(m_tex)
                                                       : static_cast<const void *>(this)));
    }
    QRhiTexture *rhiTexture() const override { return m_tex; }
    QSize textureSize() const override { return m_size; }
    bool hasAlphaChannel() const override { return false; }
    bool hasMipmaps() const override { return false; }

    void commitTextureOperations(QRhi *rhi, QRhiResourceUpdateBatch *rub) override {
        if (m_tex || m_data.isEmpty())
            return;

        m_tex = rhi->newTexture(QRhiTexture::BC1, m_size, 1);
        
        if (!m_tex->create()) {
            delete m_tex;
            m_tex = nullptr;
            return;
        }

        QRhiTextureSubresourceUploadDescription sub(m_data);
        sub.setSourceSize(m_size);
        rub->uploadTexture(m_tex,
                           QRhiTextureUploadDescription({ QRhiTextureUploadEntry(0, 0, sub) }));

        // The batch holds its own copy/reference of the data, so drop ours.
        m_data = QByteArray();
        malloc_trim(0);
    }

private:
    QByteArray m_data;
    QSize m_size;
    QRhiTexture *m_tex = nullptr;
};

} // namespace

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

// Input must be RGBA8888 (byte order R,G,B,A), which is what stb_dxt expects.
QByteArray WallpaperItem::compressToBc1(const QImage &image) {
    const int w = image.width();
    const int h = image.height();
    const int blockX = (w + 3) / 4;  // 1080p(1083/4 = 270 blocks horizontally) 
    const int blockY = (h + 3) / 4;  // 1080p(1923/4 = 480 blocks vertically)

    QByteArray bc1(qsizetype(blockX) * blockY * 8, Qt::Uninitialized);  //Multiplied by 8 since BC1 is 4x4 pixels 8 bytes
    auto *dstBase = reinterpret_cast<unsigned char *>(bc1.data()); // Getting raw pointer to the QByteArray first byte of compressed image 
    const uchar *srcBase = image.constBits(); // Starting pointer the image data
    const qsizetype stride = image.bytesPerLine(); // Lines to move to get next row of line of image 

#pragma omp parallel for schedule(static)
    for (int by = 0; by < blockY; ++by) {

        // Create 64 size blocks 4x4*8
        alignas(16) unsigned char block[16 * 4]; 
        
        // Pointer to first block ((dstBase) + by = 0 (Initial) + blockX = 480 * 8) =  3840 + memory add of dstBase
        // Block size of uncompressed mem 3840 
        unsigned char *dst = dstBase + qsizetype(by) * blockX * 8; 

        
        const int y0 = by * 4; 
 
        for (int bx = 0; bx < blockX; ++bx) {
            const int x0 = bx * 4;
            if (x0 + 4 <= w && y0 + 4 <= h) {
                const uchar *row = srcBase + y0 * stride + x0 * 4;
                std::memcpy(block + 0, row, 16);
                std::memcpy(block + 16, row + stride, 16);
                std::memcpy(block + 32, row + stride * 2, 16);
                std::memcpy(block + 48, row + stride * 3, 16);
            } else {
                // Edge clamp for dimensions not divisible by 4
                for (int py = 0; py < 4; ++py) {
                    const int sy = std::min(y0 + py, h - 1);
                    const uchar *row = srcBase + sy * stride;
                    for (int px = 0; px < 4; ++px) {
                        const int sx = std::min(x0 + px, w - 1);
                        std::memcpy(block + (py * 4 + px) * 4, row + sx * 4, 4);
                    }
                }
            }
            stb_compress_dxt_block(dst, block, /*alpha=*/0, STB_DXT_NORMAL);
            dst += 8;
        }
    }
    return bc1;
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

        QImage img = [&]() {
            QImageReader reader(m_source.toLocalFile());
            reader.setAutoTransform(true);
            reader.setScaledSize(QSize(1920, 1080));
            return reader.read();
        }();

        if (img.isNull()) {
            delete node;
            return nullptr;
        }

        QSGTexture *tex = nullptr;
        QRhi *rhi = window()->rhi();

        if (rhi && rhi->isTextureFormatSupported(QRhiTexture::BC1)) {
            if(img.format() != QImage::Format_RGBA8888) {
                img.convertTo(QImage::Format_RGBA8888);
            }
            QByteArray bc1 = compressToBc1(img);
            tex = new Bc1Texture(std::move(bc1), img.size());
            img = QImage();
            // Use the real image size rather than reader.scaledSize() if you
            // ever stop forcing a fixed scaled size.
        } else {
            // Fallback: plain uncompressed texture (also covers non-RHI backends)
            tex = window()->createTextureFromImage(img);
        }

        if (!tex) {
            delete node;
            return nullptr;
        }

        node->setTexture(tex); // deletes the previous texture (we own it)
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
        } else {       // item is taller: crop left/right
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