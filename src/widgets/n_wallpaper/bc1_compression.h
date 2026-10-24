#include <QImageReader>
#include <QSGTexture>
#include <qsize.h>
#include <qstringview.h>
#include <rhi/qrhi.h>

namespace neoshell {

// A QSGTexture backed by a BC1-compressed QRhiTexture.
// The RHI texture is created and uploaded lazily in commitTextureOperations(),
// which the scene graph calls on the render thread with a resource update
// batch that it submits for you.

class Bc1Texture : public QSGTexture {

  public:
    Bc1Texture(QUrl &url, QSize &size);
    ~Bc1Texture() override { delete m_tex; }

    qint64 comparisonKey() const override {
        return qint64(reinterpret_cast<quintptr>(m_tex ? static_cast<const void *>(m_tex)
                                                       : static_cast<const void *>(this)));
    }
    QRhiTexture *rhiTexture() const override { return m_tex; }
    QSize textureSize() const override { return m_size; }
    bool hasAlphaChannel() const override { return false; }
    bool hasMipmaps() const override { return false; }

    struct Bc1Entry {
        QByteArray bc1;
        QSize size;
    };

    void commitTextureOperations(QRhi *rhi, QRhiResourceUpdateBatch *rub) override;
    QSharedPointer<const neoshell::Bc1Texture::Bc1Entry> getBc1();

    [[nodiscard]] static QImage readImage(const QUrl &m_url, const QSize &m_size);
    [[nodiscard]] static QByteArray compressToBc1(QImage &image);

  private:
    QByteArray m_data;
    QUrl m_url;
    QSize m_size;
    QRhiTexture *m_tex = nullptr;
};
}; // namespace neoshell