#include "theme_manager.h"
#include <bc1_compression.h>
#include <malloc.h>
#include <qimage.h>
#include <qimagereader.h>
#include <qsharedpointer.h>
#include <qurl.h>
#include <stb_dxt.h>

neoshell::Bc1Texture::Bc1Texture(QUrl &url, QSize &size) : m_url(url), m_size(size) {
    auto bc1 = getBc1();
    m_data = bc1->bc1;
    m_size = bc1->size;
};

QSharedPointer<const neoshell::Bc1Texture::Bc1Entry> neoshell::Bc1Texture::getBc1() {
    static QHash<QString, QWeakPointer<const neoshell::Bc1Texture::Bc1Entry>> cache;
    const QString key = m_url.toString() + '@' + QString::number(m_size.width()) + 'x' +
                        QString::number(m_size.height());

    if (auto hit = cache.value(key).toStrongRef()) {
        return hit;
    }

    QSharedPointer<QImage> image = QSharedPointer<QImage>::create(
        readImage(m_url, m_size).convertedTo(QImage::Format_RGBA8888));
    const QImage small = image->scaled(64, 64, Qt::KeepAspectRatio, Qt::SmoothTransformation)
                             .convertedTo(QImage::Format_ARGB32);
    ThemeManager *tm = ThemeManager::instance();
    QMetaObject::invokeMethod(
        tm, [tm, small]() { tm->extract_image(small); }, Qt::QueuedConnection);
    auto e = QSharedPointer<Bc1Entry>::create();
    e->bc1 = compressToBc1(*image);
    e->size = (*image).size();
    cache.insert(key, e);
    return e;
};

QImage neoshell::Bc1Texture::readImage(const QUrl &m_url, const QSize &m_size) {
    QImage img = [&]() {
        QImageReader reader(m_url.toLocalFile());
        reader.setScaledSize(m_size);
        reader.autoTransform();
        return reader.read();
    }();
    return img;
}

QByteArray neoshell::Bc1Texture::compressToBc1(QImage &image) {
    const int w = image.width();
    const int h = image.height();
    const int blockX = (w + 3) / 4; // 1080p(1083/4 = 270 blocks horizontally)
    const int blockY = (h + 3) / 4; // 1080p(1923/4 = 480 blocks vertically)

    QByteArray bc1(qsizetype(blockX) * blockY * 8,
                   Qt::Uninitialized); // Multiplied by 8 since BC1 is 4x4 pixels 8 bytes
    auto *dstBase = reinterpret_cast<unsigned char *>(
        bc1.data()); // Getting raw pointer to the QByteArray first byte of compressed image
    const uchar *srcBase = image.constBits();      // Starting pointer the image data
    const qsizetype stride = image.bytesPerLine(); // Lines to move to get next row of line of image

#pragma omp parallel for schedule(static)
    for (int by = 0; by < blockY; ++by) {

        // Create 64 size blocks 4x4*8
        alignas(16) unsigned char block[16 * 4];

        // Pointer to first block ((dstBase) + by = 0 (Initial) + blockX = 480 * 8) =  3840 +
        // memory add of dstBase Block size of uncompressed mem 3840
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

void neoshell::Bc1Texture::commitTextureOperations(QRhi *rhi, QRhiResourceUpdateBatch *rub) {
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
    rub->uploadTexture(m_tex, QRhiTextureUploadDescription({QRhiTextureUploadEntry(0, 0, sub)}));

    // The batch holds its own copy/reference of the data, so drop ours.
    m_data = QByteArray();
    malloc_trim(0);
}
