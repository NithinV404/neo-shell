#include "matugen.hpp"
#include "logger.hpp"
#include <QColor>
#include <QImage>
#include <algorithm>
#include <cmath>

auto &logger = Logger::getInstance();

std::ostream& operator<<(std::ostream& os, const RGB& color){
    os << "RGB(" << static_cast<int>(color.r) << "," << static_cast<int>(color.g) << "," << static_cast<int>(color.b) << ") \n";
    return os;
};

std::ostream& operator<<(std::ostream& os, const Matugen_colors& c) {
    os << "Matugen_colors {\n"
       << "  mode: " << c.mode << "\n"
       << "  Primary: " << c.primary << "  on_primary: " << c.on_primary
       << "  primary_container: " << c.primary_container
       << "  on_primary_container: " << c.on_primary_container << "\n"
       << "  Secondary: " << c.secondary << "  on_secondary: " << c.on_secondary
       << "  secondary_container: " << c.secondary_container
       << "  on_secondary_container: " << c.on_secondary_container << "\n"
       << "  Tertiary: " << c.teritiary << "  on_teritiary: " << c.on_teritiary
       << "  tertiary_container: " << c.teritiary_container
       << "  on_tertiary_container: " << c.on_teritiary_container << "\n"
       << "  Surface: " << c.surface << "  on_surface: " << c.on_surface
       << "  surface_variant: " << c.surface_variant
       << "  on_surface_variant: " << c.on_surface_variant << "\n"
       << "}\n";
    return os;
}

// ---------------------------------------------------------------------
// HSL helpers
// ---------------------------------------------------------------------
HSL Matugen::rgb_to_hsl(const RGB& c) const {
    float r = c.r / 255.0f, g = c.g / 255.0f, b = c.b / 255.0f;
    float mx = std::max({r, g, b});
    float mn = std::min({r, g, b});
    float l = (mx + mn) / 2.0f;
    float d = mx - mn;

    HSL out{0.0f, 0.0f, l};
    if (d < 0.0001f) return out;

    out.s = d / (1.0f - std::abs(2.0f * l - 1.0f));

    if (mx == r) {
        out.h = 60.0f * std::fmod(((g - b) / d), 6.0f);
    } else if (mx == g) {
        out.h = 60.0f * (((b - r) / d) + 2.0f);
    } else {
        out.h = 60.0f * (((r - g) / d) + 4.0f);
    }
    if (out.h < 0.0f) out.h += 360.0f;

    return out;
}

RGB Matugen::hsl_to_rgb(const HSL& c) const {
    float h = c.h, s = c.s, l = c.l;
    float C = (1.0f - std::abs(2.0f * l - 1.0f)) * s;
    float X = C * (1.0f - std::abs(std::fmod(h / 60.0f, 2.0f) - 1.0f));
    float m = l - C / 2.0f;

    float r1 = 0, g1 = 0, b1 = 0;
    if (h < 60.0f)       { r1 = C; g1 = X; b1 = 0; }
    else if (h < 120.0f) { r1 = X; g1 = C; b1 = 0; }
    else if (h < 180.0f) { r1 = 0; g1 = C; b1 = X; }
    else if (h < 240.0f) { r1 = 0; g1 = X; b1 = C; }
    else if (h < 300.0f) { r1 = X; g1 = 0; b1 = C; }
    else                 { r1 = C; g1 = 0; b1 = X; }

    auto clamp8 = [](float v) -> uint8_t {
        v = std::round(v);
        if (v < 0.0f) v = 0.0f;
        if (v > 255.0f) v = 255.0f;
        return static_cast<uint8_t>(v);
    };

    return RGB{
        clamp8((r1 + m) * 255.0f),
        clamp8((g1 + m) * 255.0f),
        clamp8((b1 + m) * 255.0f)
    };
}

std::optional<std::vector<RGB>> Matugen::extract_pixels(const std::string* path) {
    QImage image(QString::fromStdString(*path));
    if(image.isNull()) {
        logger.warning("Failed to load the image");
        return std::nullopt;
    }
    // 128x128 provides an excellent sample size for hue detection
    QImage scaled = image.scaled(128, 128, Qt::IgnoreAspectRatio, Qt::SmoothTransformation)
                        .convertToFormat(QImage::Format_RGB32);

    if(scaled.isNull()) {
        logger.warning("Failed to scale the image");
        return std::nullopt;
    }

    std::vector<RGB> pixels;
    pixels.reserve(scaled.width() * scaled.height());

    for (int y = 0; y < scaled.height(); ++y) {
        const QRgb* scan = reinterpret_cast<const QRgb*>(scaled.scanLine(y));
        for (int x = 0; x < scaled.width(); ++x) {
            QRgb px = scan[x];
            if (qAlpha(px) < 16) continue; // skip transparent
            pixels.push_back(RGB{
                static_cast<uint8_t>(qRed(px)),
                static_cast<uint8_t>(qGreen(px)),
                static_cast<uint8_t>(qBlue(px))
            });
        }
    }
    logger.info("Extracted pixels successfully");
    return pixels;
}

Matugen_colors Matugen::extract_colors(const std::string* path, bool is_darkmode) {
    logger.debug("Loaded image path:" + *path);
    auto pixels_opt = extract_pixels(path);
    if(!pixels_opt.has_value()) return Matugen_colors{};
    auto& all_pixels = *pixels_opt;

    // ------------------------------------------------------------------
    // 1. Hue Histograms
    // We use two histograms:
    // - One for VIBRANT pixels (to pick Primary/Tertiary accents)
    // - One for ALL pixels (to find the prominent background hue for Surfaces)
    // ------------------------------------------------------------------
    struct HueBucket {
        int count = 0;
        float sum_s = 0.0f;
    };
    std::array<HueBucket, 12> vibrant_buckets;
    std::array<HueBucket, 12> all_buckets;

    int total_vibrant = 0;
    int total_colorful = 0; // includes softer background colors

    for (const auto& px : all_pixels) {
        HSL hsl = rgb_to_hsl(px);
        if (hsl.l < 0.10f || hsl.l > 0.90f) continue; // skip extreme black/white

        int idx = static_cast<int>(hsl.h / 30.0f) % 12;

        // Track all non-gray pixels for the prominent background hue
        if (hsl.s > 0.08f) {
            all_buckets[idx].count++;
            all_buckets[idx].sum_s += hsl.s;
            total_colorful++;
        }

        // Track only highly saturated pixels for accents
        if (hsl.s > 0.25f) {
            vibrant_buckets[idx].count++;
            vibrant_buckets[idx].sum_s += hsl.s;
            total_vibrant++;
        }
    }

    // Fallbacks if image is monochrome
    float primary_hue = 265.0f, primary_s = 0.5f;
    float tertiary_hue = 45.0f, tertiary_s = 0.5f;
    float prominent_hue = 265.0f, prominent_s = 0.1f;

    // --- Find Prominent Background Hue ---
    if (total_colorful > 50) {
        std::vector<int> sorted_all(12);
        for (int i = 0; i < 12; ++i) sorted_all[i] = i;
        std::sort(sorted_all.begin(), sorted_all.end(), [&](int a, int b) {
            return all_buckets[a].count > all_buckets[b].count;
        });
        int b_prom = sorted_all[0];
        prominent_hue = (b_prom * 30.0f) + 15.0f;
        prominent_s = all_buckets[b_prom].sum_s / all_buckets[b_prom].count;
    }

    // --- Find Vibrant Accent Hues ---
    if (total_vibrant > 50) {
        std::vector<int> sorted_vib(12);
        for (int i = 0; i < 12; ++i) sorted_vib[i] = i;
        std::sort(sorted_vib.begin(), sorted_vib.end(), [&](int a, int b) {
            return vibrant_buckets[a].count > vibrant_buckets[b].count;
        });

        int b0 = sorted_vib[0];
        primary_hue = (b0 * 30.0f) + 15.0f;
        primary_s = vibrant_buckets[b0].sum_s / vibrant_buckets[b0].count;

        int b1 = -1;
        for (int i = 1; i < 12; ++i) {
            int idx = sorted_vib[i];
            if (vibrant_buckets[idx].count == 0) break;
            float hue = (idx * 30.0f) + 15.0f;
            float diff = std::abs(primary_hue - hue);
            if (diff > 180.0f) diff = 360.0f - diff;
            if (diff > 40.0f) { b1 = idx; break; }
        }

        if (b1 == -1) {
            tertiary_hue = std::fmod(primary_hue + 60.0f, 360.0f);
            tertiary_s = primary_s * 0.8f;
        } else {
            tertiary_hue = (b1 * 30.0f) + 15.0f;
            tertiary_s = vibrant_buckets[b1].sum_s / vibrant_buckets[b1].count;
        }
    }

    // ------------------------------------------------------------------
    // 2. Chroma (Saturation) Scaling
    // ------------------------------------------------------------------
    // Accents get boosted so they pop
    float s_primary   = std::clamp(primary_s, 0.50f, 0.85f);
    float s_secondary = std::clamp(primary_s * 0.40f, 0.10f, 0.30f);
    float s_tertiary  = std::clamp(tertiary_s * 0.70f, 0.25f, 0.50f);

    // Surfaces use the PROMINENT background hue and its ACTUAL saturation!
    // This is what makes the surface feel like the wallpaper's background.
    float s_neutral   = std::clamp(prominent_s * 0.40f, 0.02f, 0.15f);
    float s_outline   = std::clamp(prominent_s * 0.15f, 0.01f, 0.06f);
    float s_variant   = std::clamp(prominent_s * 0.60f, 0.03f, 0.12f);

    auto make_color = [&](float h, float s, float l) {
        return hsl_to_rgb({h, std::clamp(s, 0.0f, 1.0f), std::clamp(l, 0.0f, 1.0f)});
    };

    Matugen_colors colors;
    colors.mode = is_darkmode ? System_Mode::Dark : System_Mode::Light;

    // We use prominent_hue for all surfaces to match the background
    float neutral_hue = prominent_hue;

    if (!is_darkmode) {
        // ==========================================
        // LIGHT MODE
        // ==========================================
        colors.primary   = make_color(primary_hue, s_primary, 0.45);
        colors.on_primary = make_color(primary_hue, 0.0f, 1.00);
        colors.primary_container = make_color(primary_hue, s_primary * 0.5f, 0.92);
        colors.on_primary_container = make_color(primary_hue, s_primary, 0.15);

        colors.secondary = make_color(primary_hue, s_secondary, 0.45);
        colors.on_secondary = make_color(primary_hue, 0.0f, 1.00);
        colors.secondary_container = make_color(primary_hue, s_secondary * 0.5f, 0.92);
        colors.on_secondary_container = make_color(primary_hue, s_secondary, 0.15);

        colors.teritiary = make_color(tertiary_hue, s_tertiary, 0.45);
        colors.on_teritiary = make_color(tertiary_hue, 0.0f, 1.00);
        colors.teritiary_container = make_color(tertiary_hue, s_tertiary * 0.5f, 0.92);
        colors.on_teritiary_container = make_color(tertiary_hue, s_tertiary, 0.15);

        // Surfaces now derive from the prominent background hue!
        colors.surface = make_color(neutral_hue, s_neutral, 0.97);
        colors.on_surface = make_color(neutral_hue, s_neutral, 0.12);
        colors.surface_variant = make_color(neutral_hue, s_variant, 0.90);
        colors.on_surface_variant = make_color(neutral_hue, s_variant, 0.30);
        colors.background = colors.surface;
        colors.on_background = colors.on_surface;

        colors.error = make_color(25.0f, 0.70f, 0.45);
        colors.on_error = make_color(25.0f, 0.0f, 1.00);

        colors.surface_dim               = make_color(neutral_hue, s_neutral, 0.87);
        colors.surface_bright            = make_color(neutral_hue, s_neutral, 0.98);
        colors.surface_container_lowest  = make_color(neutral_hue, s_neutral, 1.00);
        colors.surface_container_low     = make_color(neutral_hue, s_neutral, 0.96);
        colors.surface_container         = make_color(neutral_hue, s_neutral, 0.94);
        colors.surface_container_high    = make_color(neutral_hue, s_neutral, 0.92);
        colors.surface_container_highest = make_color(neutral_hue, s_neutral, 0.90);

        colors.outline         = make_color(neutral_hue, s_outline, 0.50);
        colors.outline_variant = make_color(neutral_hue, s_outline, 0.80);
        colors.inverse_surface = make_color(neutral_hue, s_neutral, 0.20);
        colors.inverse_on_surface = make_color(neutral_hue, s_neutral, 0.95);
        colors.inverse_primary = make_color(primary_hue, s_primary, 0.80);
        colors.surface_tint    = colors.primary;
        colors.scrim           = RGB{0, 0, 0};
    } else {
        // ==========================================
        // DARK MODE
        // ==========================================
        colors.primary   = make_color(primary_hue, s_primary, 0.80);
        colors.on_primary = make_color(primary_hue, 0.0f, 0.15);
        colors.primary_container = make_color(primary_hue, s_primary * 0.5f, 0.30);
        colors.on_primary_container = make_color(primary_hue, s_primary, 0.92);

        colors.secondary = make_color(primary_hue, s_secondary, 0.80);
        colors.on_secondary = make_color(primary_hue, 0.0f, 0.15);
        colors.secondary_container = make_color(primary_hue, s_secondary * 0.5f, 0.30);
        colors.on_secondary_container = make_color(primary_hue, s_secondary, 0.92);

        colors.teritiary = make_color(tertiary_hue, s_tertiary, 0.80);
        colors.on_teritiary = make_color(tertiary_hue, 0.0f, 0.15);
        colors.teritiary_container = make_color(tertiary_hue, s_tertiary * 0.5f, 0.30);
        colors.on_teritiary_container = make_color(tertiary_hue, s_tertiary, 0.92);

        colors.surface = make_color(neutral_hue, s_neutral, 0.10);
        colors.on_surface = make_color(neutral_hue, s_neutral, 0.92);
        colors.surface_variant = make_color(neutral_hue, s_variant, 0.30);
        colors.on_surface_variant = make_color(neutral_hue, s_variant, 0.80);
        colors.background = colors.surface;
        colors.on_background = colors.on_surface;

        colors.error = make_color(25.0f, 0.50f, 0.80);
        colors.on_error = make_color(25.0f, 0.0f, 0.15);

        colors.surface_dim               = make_color(neutral_hue, s_neutral, 0.06);
        colors.surface_bright            = make_color(neutral_hue, s_neutral, 0.24);
        colors.surface_container_lowest  = make_color(neutral_hue, s_neutral, 0.04);
        colors.surface_container_low     = make_color(neutral_hue, s_neutral, 0.10);
        colors.surface_container         = make_color(neutral_hue, s_neutral, 0.12);
        colors.surface_container_high    = make_color(neutral_hue, s_neutral, 0.17);
        colors.surface_container_highest = make_color(neutral_hue, s_neutral, 0.22);

        colors.outline         = make_color(neutral_hue, s_outline, 0.60);
        colors.outline_variant = make_color(neutral_hue, s_outline, 0.30);
        colors.inverse_surface = make_color(neutral_hue, s_neutral, 0.90);
        colors.inverse_on_surface = make_color(neutral_hue, s_neutral, 0.20);
        colors.inverse_primary = make_color(primary_hue, s_primary, 0.40);
        colors.surface_tint    = colors.primary;
        colors.scrim           = RGB{0, 0, 0};
    }

    colors.shadow = RGB{0, 0, 0};

    logger.info("Successfully extracted matugen colors");
    logger.debug(colors);
    return colors;
}

std::string Matugen::to_hex(RGB rgb) {
    char buf[8];
    std::snprintf(buf, sizeof(buf), "#%02X%02X%02X", rgb.r, rgb.g, rgb.b);
    return std::string(buf);
}
