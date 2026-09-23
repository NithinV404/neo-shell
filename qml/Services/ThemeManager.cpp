#include "ThemeManager.hpp"

void ThemeManager::loadWallpaperColors(QString path, bool is_dark_mode) {
    Matugen matugen;
    std::string qmlpath = path.toStdString();
    m_colors = matugen.extract_colors(&qmlpath, is_dark_mode);

    emit themeChanged();
}

QColor ThemeManager::toQColor(const RGB& c) {
        return QColor(c.r, c.g, c.b);
}
