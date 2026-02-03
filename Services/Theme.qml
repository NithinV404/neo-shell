pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property var colors: ({})
    property bool darkMode: Settings.darkMode

    // Primary
    property color primary: "#6750A4"
    property color primaryFg: "#FFFFFF"
    property color primaryContainer: "#EADDFF"
    property color primaryContainerFg: "#21005D"

    // Secondary
    property color secondary: "#625B71"
    property color secondaryFg: "#FFFFFF"
    property color secondaryContainer: "#E8DEF8"
    property color secondaryContainerFg: "#1D192B"

    // Tertiary
    property color tertiary: "#7D5260"
    property color tertiaryFg: "#FFFFFF"
    property color tertiaryContainer: "#FFD8E4"
    property color tertiaryContainerFg: "#31111D"

    // Error
    property color error: "#B3261E"
    property color errorFg: "#FFFFFF"
    property color errorContainer: "#F9DEDC"
    property color errorContainerFg: "#410E0B"

    // Background
    property color background: "#1C1B1F"
    property color backgroundFg: "#E6E1E5"

    // Surface
    property color surface: "#1C1B1F"
    property color surfaceFg: "#E6E1E5"
    property color surfaceVariant: "#49454F"
    property color surfaceVariantFg: "#CAC4D0"
    property color surfaceDim: "#141218"
    property color surfaceBright: "#3B383E"
    property color surfaceContainerLowest: "#0F0D13"
    property color surfaceContainerLow: "#1D1B20"
    property color surfaceContainer: "#211F26"
    property color surfaceContainerHigh: "#2B2930"
    property color surfaceContainerHighest: "#36343B"
    property color surfaceTint: "#96ccf8"

    // Outline
    property color outline: "#938F99"
    property color outlineVariant: "#49454F"

    // Other
    property color shadow: "#000000"
    property color scrim: "#000000"

    // Inverse
    property color inverseSurface: "#E6E1E5"
    property color inverseSurfaceFg: "#313033"
    property color inversePrimary: "#6750A4"

    onDarkModeChanged: updateColorProperties()

    function updateColorProperties() {
        var mode = darkMode ? "dark" : "light";
        var c = colors[mode] || {};

        primary = Qt.color(c["primary"] || "#6750A4");
        primaryFg = Qt.color(c["on_primary"] || "#FFFFFF");
        primaryContainer = Qt.color(c["primary_container"] || "#EADDFF");
        primaryContainerFg = Qt.color(c["on_primary_container"] || "#21005D");

        secondary = Qt.color(c["secondary"] || "#625B71");
        secondaryFg = Qt.color(c["on_secondary"] || "#FFFFFF");
        secondaryContainer = Qt.color(c["secondary_container"] || "#E8DEF8");
        secondaryContainerFg = Qt.color(c["on_secondary_container"] || "#1D192B");

        tertiary = Qt.color(c["tertiary"] || "#7D5260");
        tertiaryFg = Qt.color(c["on_tertiary"] || "#FFFFFF");
        tertiaryContainer = Qt.color(c["tertiary_container"] || "#FFD8E4");
        tertiaryContainerFg = Qt.color(c["on_tertiary_container"] || "#31111D");

        error = Qt.color(c["error"] || "#B3261E");
        errorFg = Qt.color(c["on_error"] || "#FFFFFF");
        errorContainer = Qt.color(c["error_container"] || "#F9DEDC");
        errorContainerFg = Qt.color(c["on_error_container"] || "#410E0B");

        background = Qt.color(c["background"] || "#1C1B1F");
        backgroundFg = Qt.color(c["on_background"] || "#E6E1E5");

        surface = Qt.color(c["surface"] || "#1C1B1F");
        surfaceFg = Qt.color(c["on_surface"] || "#E6E1E5");
        surfaceVariant = Qt.color(c["surface_variant"] || "#49454F");
        surfaceVariantFg = Qt.color(c["on_surface_variant"] || "#CAC4D0");
        surfaceDim = Qt.color(c["surface_dim"] || "#141218");
        surfaceBright = Qt.color(c["surface_bright"] || "#3B383E");
        surfaceContainerLowest = Qt.color(c["surface_container_lowest"] || "#0F0D13");
        surfaceContainerLow = Qt.color(c["surface_container_low"] || "#1D1B20");
        surfaceContainer = Qt.color(c["surface_container"] || "#211F26");
        surfaceContainerHigh = Qt.color(c["surface_container_high"] || "#2B2930");
        surfaceContainerHighest = Qt.color(c["surface_container_highest"] || "#36343B");
        surfaceTint = Qt.color(c["surface_tint"] || "#96ccf8");

        outline = Qt.color(c["outline"] || "#938F99");
        outlineVariant = Qt.color(c["outline_variant"] || "#49454F");

        shadow = Qt.color(c["shadow"] || "#000000");
        scrim = Qt.color(c["scrim"] || "#000000");

        inverseSurface = Qt.color(c["inverse_surface"] || "#E6E1E5");
        inverseSurfaceFg = Qt.color(c["inverse_on_surface"] || "#313033");
        inversePrimary = Qt.color(c["inverse_primary"] || "#6750A4");

        console.log("[Theme] Colors updated");
    }

    function getColor(key, fallback) {
        var safeFallback = fallback || "#00000000";
        var mode = darkMode ? "dark" : "light";
        var modeData = colors[mode];

        if (!modeData)
            return Qt.color(safeFallback);

        var val = modeData[key];
        return val ? Qt.color(val) : Qt.color(safeFallback);
    }

    FileView {
        id: themeFile
        watchChanges: true
        path: Paths.home + "/.config/quickshell/quickshell.json"

        onFileChanged: {
            reloadTimer.restart();
        }

        onTextChanged: {
            var content = text();
            if (!content)
                return;

            try {
                var json = JSON.parse(content.trim());
                root.colors = json.colors || {};
                root.wallpaperPath = json.image || "";
                root.updateColorProperties();
            } catch (e) {
                console.warn("[Theme] Parse error:", e);
            }
        }

        onLoaded: {
            var content = text();
            if (!content)
                return;

            try {
                var json = JSON.parse(content.trim());
                root.colors = json.colors || {};
                root.updateColorProperties();
            } catch (e) {
                console.warn("[Theme] Parse error:", e);
            }
        }
    }

    Timer {
        id: reloadTimer
        interval: 200
        onTriggered: themeFile.reload()
    }
}
