#include "theme_manager.h"
#include "matugen.h"
#include <qlogging.h>

ThemeManager *ThemeManager::s_instance = nullptr;

ThemeManager::ThemeManager(QObject *parent) : QObject(parent) {
   s_instance = this;
}

ThemeManager *ThemeManager::instance() {
    if (!s_instance) new ThemeManager; 
    return s_instance;
}

ThemeManager *ThemeManager::create(QQmlEngine *, QJSEngine *)
{
    auto *i = instance();
    QJSEngine::setObjectOwnership(i, QJSEngine::CppOwnership);
    return i;
}

void ThemeManager::extract_image(
    const QImage &image)
{
    if(image.isNull())
    {
        qWarning() << "Reader is empty";
    }

    m_colors = Matugen().extract_colors(image, true);
    emit themeChanged();
}

QColor ThemeManager::toQColor(const RGB& c) {
        return QColor(c.r, c.g, c.b);
}

