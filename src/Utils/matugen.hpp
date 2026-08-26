#pragma once
#include <cstdint>
#include <ostream>
#include <string>
#include <vector>
#include <optional>

struct HSL {
    float h, s, l;
};

struct RGB {
    std::uint8_t r, g, b;
};

enum System_Mode {
    Auto,
    Light,
    Dark
};

struct Matugen_colors {
    System_Mode mode = System_Mode::Auto;

    // Primary
    RGB primary                = {103, 80, 164};
    RGB on_primary             = {255, 255, 255};
    RGB primary_container      = {234, 221, 255};
    RGB on_primary_container   = {33, 0, 93};

    // Secondary
    RGB secondary              = {98, 91, 113};
    RGB on_secondary           = {255, 255, 255};
    RGB secondary_container    = {232, 222, 248};
    RGB on_secondary_container = {29, 25, 43};

    // Tertiary
    RGB teritiary              = {125, 82, 96};
    RGB on_teritiary           = {255, 255, 255};
    RGB teritiary_container    = {255, 216, 228};
    RGB on_teritiary_container = {49, 17, 29};

    // Error
    RGB error                  = {179, 38, 30};
    RGB on_error              = {255, 255, 255};

    // Surfaces & Backgrounds
    RGB surface                = {254, 247, 255};
    RGB surface_variant        = {231, 224, 236};
    RGB on_surface             = {29, 27, 32};
    RGB on_surface_variant     = {73, 69, 79};
    RGB surface_dim               = {222, 216, 225};
    RGB surface_bright            = {255, 251, 254};
    RGB surface_container_lowest  = {255, 255, 255};
    RGB surface_container_low     = {247, 242, 250};
    RGB surface_container         = {243, 237, 247};
    RGB surface_container_high    = {236, 230, 240};
    RGB surface_container_highest = {230, 224, 233};
    RGB background             = {254, 247, 255};
    RGB on_background          = {29, 27, 32};

    // Outline / Inverse
    RGB outline             = {121, 116, 126};
    RGB outline_variant     = {202, 196, 208};
    RGB inverse_surface     = {50, 47, 53};
    RGB inverse_on_surface  = {245, 239, 244};
    RGB inverse_primary     = {208, 188, 255};
    RGB surface_tint        = {103, 80, 164};
    RGB scrim               = {0, 0, 0};

    // Decorative
    RGB shadow                 = {0, 0, 0};
};

std::ostream& operator<<(std::ostream& os, const RGB& color);
std::ostream& operator<<(std::ostream& os, const Matugen_colors& colors);

class Matugen {
    public:
        Matugen_colors extract_colors(const std::string* path, bool is_darkmode=false);
        std::string to_hex(RGB rgb);
    private:
        HSL rgb_to_hsl(const RGB& c) const;
        RGB hsl_to_rgb(const HSL& c) const;
        std::optional<std::vector<RGB>> extract_pixels(const std::string* path);
};
