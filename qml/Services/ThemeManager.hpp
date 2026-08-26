#pragma once

#include <QObject>
#include <QtGui/QColor>
#include <QQmlEngine>
#include <qqmlregistration.h>
#include <qtmetamacros.h>
#include "../../src/Utils/matugen.hpp"

class ThemeManager : public QObject {
      Q_OBJECT
      QML_ELEMENT
      QML_SINGLETON


      Q_PROPERTY(QColor primary READ primary NOTIFY themeChanged)
      Q_PROPERTY(QColor onPrimary READ onPrimary NOTIFY themeChanged)
      Q_PROPERTY(QColor primaryContainer READ primaryContainer NOTIFY themeChanged)
      Q_PROPERTY(QColor onPrimaryContainer READ onPrimaryContainer NOTIFY themeChanged)

      Q_PROPERTY(QColor secondary READ secondary NOTIFY themeChanged)
      Q_PROPERTY(QColor onSecondary READ onSecondary NOTIFY themeChanged)
      Q_PROPERTY(QColor secondaryContainer READ secondaryContainer NOTIFY themeChanged)
      Q_PROPERTY(QColor onSecondaryContainer READ onSecondaryContainer NOTIFY themeChanged)

      Q_PROPERTY(QColor tertiary READ tertiary NOTIFY themeChanged)
      Q_PROPERTY(QColor onTertiary READ onTertiary NOTIFY themeChanged)
      Q_PROPERTY(QColor tertiaryContainer READ tertiaryContainer NOTIFY themeChanged)
      Q_PROPERTY(QColor onTertiaryContainer READ onTertiaryContainer NOTIFY themeChanged)

      Q_PROPERTY(QColor error READ error NOTIFY themeChanged)
      Q_PROPERTY(QColor onError READ onError NOTIFY themeChanged)

      Q_PROPERTY(QColor surface READ surface NOTIFY themeChanged)
      Q_PROPERTY(QColor onSurface READ onSurface NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceVariant READ surfaceVariant NOTIFY themeChanged)
      Q_PROPERTY(QColor onSurfaceVariant READ onSurfaceVariant NOTIFY themeChanged)
      Q_PROPERTY(QColor background READ background NOTIFY themeChanged)
      Q_PROPERTY(QColor onBackground READ onBackground NOTIFY themeChanged)

      Q_PROPERTY(QColor surfaceDim READ surfaceDim NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceBright READ surfaceBright NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceContainerLowest READ surfaceContainerLowest NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceContainerLow READ surfaceContainerLow NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceContainer READ surfaceContainer NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceContainerHigh READ surfaceContainerHigh NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceContainerHighest READ surfaceContainerHighest NOTIFY themeChanged)

      Q_PROPERTY(QColor outline READ outline NOTIFY themeChanged)
      Q_PROPERTY(QColor outlineVariant READ outlineVariant NOTIFY themeChanged)
      Q_PROPERTY(QColor inverseSurface READ inverseSurface NOTIFY themeChanged)
      Q_PROPERTY(QColor inverseOnSurface READ inverseOnSurface NOTIFY themeChanged)
      Q_PROPERTY(QColor inversePrimary READ inversePrimary NOTIFY themeChanged)
      Q_PROPERTY(QColor surfaceTint READ surfaceTint NOTIFY themeChanged)
      Q_PROPERTY(QColor scrim READ scrim NOTIFY themeChanged)

      Q_PROPERTY(QColor shadow READ shadow NOTIFY themeChanged)

      public: explicit ThemeManager(QObject *parent = nullptr) : QObject(parent) {}

      static ThemeManager* instance() {
          static ThemeManager inst;
          return &inst;
      }

      static ThemeManager* create(QQmlEngine *qmlEngine, QJSEngine *jsEngine) {
          Q_UNUSED(qmlEngine);
          Q_UNUSED(jsEngine);
          return instance();
      }

      // --- Primary ---
        QColor primary()              const { return toQColor(m_colors.primary); }
        QColor onPrimary()            const { return toQColor(m_colors.on_primary); }
        QColor primaryContainer()     const { return toQColor(m_colors.primary_container); }
        QColor onPrimaryContainer()   const { return toQColor(m_colors.on_primary_container); }

        // --- Secondary ---
        QColor secondary()            const { return toQColor(m_colors.secondary); }
        QColor onSecondary()          const { return toQColor(m_colors.on_secondary); }
        QColor secondaryContainer()   const { return toQColor(m_colors.secondary_container); }
        QColor onSecondaryContainer() const { return toQColor(m_colors.on_secondary_container); }

        // --- Tertiary ---
        QColor tertiary()             const { return toQColor(m_colors.teritiary); }
        QColor onTertiary()           const { return toQColor(m_colors.on_teritiary); }
        QColor tertiaryContainer()    const { return toQColor(m_colors.teritiary_container); }
        QColor onTertiaryContainer()  const { return toQColor(m_colors.on_teritiary_container); }

        // --- Error ---
        QColor error()                const { return toQColor(m_colors.error); }
        QColor onError()              const { return toQColor(m_colors.on_error); }

        // --- Surfaces & Backgrounds ---
        QColor surface()              const { return toQColor(m_colors.surface); }
        QColor onSurface()            const { return toQColor(m_colors.on_surface); }
        QColor surfaceVariant()       const { return toQColor(m_colors.surface_variant); }
        QColor onSurfaceVariant()     const { return toQColor(m_colors.on_surface_variant); }
        QColor background()           const { return toQColor(m_colors.background); }
        QColor onBackground()         const { return toQColor(m_colors.on_background); }

        // --- Surface tones ---
        QColor surfaceDim()               const { return toQColor(m_colors.surface_dim); }
        QColor surfaceBright()            const { return toQColor(m_colors.surface_bright); }
        QColor surfaceContainerLowest()   const { return toQColor(m_colors.surface_container_lowest); }
        QColor surfaceContainerLow()      const { return toQColor(m_colors.surface_container_low); }
        QColor surfaceContainer()         const { return toQColor(m_colors.surface_container); }
        QColor surfaceContainerHigh()     const { return toQColor(m_colors.surface_container_high); }
        QColor surfaceContainerHighest()  const { return toQColor(m_colors.surface_container_highest); }

        // --- Outline / Inverse / Misc ---
        QColor outline()          const { return toQColor(m_colors.outline); }
        QColor outlineVariant()   const { return toQColor(m_colors.outline_variant); }
        QColor inverseSurface()   const { return toQColor(m_colors.inverse_surface); }
        QColor inverseOnSurface() const { return toQColor(m_colors.inverse_on_surface); }
        QColor inversePrimary()   const { return toQColor(m_colors.inverse_primary); }
        QColor surfaceTint()      const { return toQColor(m_colors.surface_tint); }
        QColor scrim()            const { return toQColor(m_colors.scrim); }

        // --- Decorative ---
        QColor shadow()           const { return toQColor(m_colors.shadow); }


      Q_INVOKABLE void loadWallpaperColors(QString path, bool is_dark_mode) {
          Matugen matugen;
          std::string qmlpath = path.toStdString();
          m_colors = matugen.extract_colors(&qmlpath, is_dark_mode);

          emit themeChanged();
      }

      signals: void themeChanged();

      private:
          static QColor toQColor(const RGB& c) {
                  return QColor(c.r, c.g, c.b);
          }
          Matugen_colors m_colors;
  };
