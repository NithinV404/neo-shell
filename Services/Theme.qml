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

    // --- Material 3 Property Definitions ---
    property color primary: "#007BFF"
    property color primaryFg: "#FFFFFF"
    property color primaryContainer: darkMode ? "#004085" : "#CCE5FF"
    property color primaryContainerFg: darkMode ? "#FFFFFF" : "#004085"

    property color secondary: "#6C757D"
    property color secondaryFg: "#FFFFFF"
    property color secondaryContainer: darkMode ? "#495057" : "#E9ECEF"
    property color secondaryContainerFg: darkMode ? "#FFFFFF" : "#212529"

    property color tertiary: "#007BFF"
    property color tertiaryFg: "#FFFFFF"
    property color tertiaryContainer: darkMode ? "#004085" : "#CCE5FF"
    property color tertiaryContainerFg: darkMode ? "#FFFFFF" : "#004085"

    property color error: "#DC3545"
    property color errorFg: "#FFFFFF"
    property color errorContainer: darkMode ? "#921B27" : "#F8D7DA"
    property color errorContainerFg: darkMode ? "#FFFFFF" : "#842029"

    property color background: darkMode ? "#000000" : "#FFFFFF"
    property color backgroundFg: darkMode ? "#FFFFFF" : "#000000"

    property color surface: darkMode ? "#000000" : "#FFFFFF"
    property color surfaceFg: darkMode ? "#FFFFFF" : "#000000"
    property color surfaceVariant: darkMode ? "#1A1A1A" : "#F8F9FA"
    property color surfaceVariantFg: darkMode ? "#E0E0E0" : "#212529"

    property color surfaceContainerLowest: darkMode ? "#000000" : "#FFFFFF"
    property color surfaceContainerLow: darkMode ? "#0A0A0A" : "#F8F9FA"
    property color surfaceContainer: darkMode ? "#121212" : "#F1F3F5"
    property color surfaceContainerHigh: darkMode ? "#1A1A1A" : "#E9ECEF"
    property color surfaceContainerHighest: darkMode ? "#222222" : "#DEE2E6"

    property color outline: darkMode ? "#333333" : "#DEE2E6"
    property color outlineVariant: darkMode ? "#444444" : "#CED4DA"

    property color inverseSurface: darkMode ? "#FFFFFF" : "#362F27"
    property color inverseSurfaceFg: darkMode ? "#000000" : "#FBEFE2"
    property color inversePrimary: "#007BFF"

    property color shadow: "#000000"
    property color scrim: "#000000"

    onDarkModeChanged: updateColorProperties()

    function updateColorProperties() {
        var mode = darkMode ? "dark" : "light";
        var c = colors[mode] || {};

        function getC(key, fallback) {
            return c[key] ? Qt.color(c[key]) : Qt.color(fallback);
        }

        // --- Core Colors ---
        primary = getC("primary", "#007BFF");
        primaryFg = getC("on_primary", "#FFFFFF");
        primaryContainer = getC("primary_container", darkMode ? "#004085" : "#CCE5FF");
        primaryContainerFg = getC("on_primary_container", darkMode ? "#FFFFFF" : "#004085");

        secondary = getC("secondary", "#6C757D");
        secondaryFg = getC("on_secondary", "#FFFFFF");
        secondaryContainer = getC("secondary_container", darkMode ? "#495057" : "#E9ECEF");
        secondaryContainerFg = getC("on_secondary_container", darkMode ? "#FFFFFF" : "#212529");

        tertiary = getC("tertiary", "#007BFF");
        tertiaryFg = getC("on_tertiary", "#FFFFFF");
        tertiaryContainer = getC("tertiary_container", darkMode ? "#004085" : "#CCE5FF");
        tertiaryContainerFg = getC("on_tertiary_container", darkMode ? "#FFFFFF" : "#004085");

        // --- Error Colors ---
        error = getC("error", "#DC3545");
        errorFg = getC("on_error", "#FFFFFF");
        errorContainer = getC("error_container", darkMode ? "#921B27" : "#F8D7DA");
        errorContainerFg = getC("on_error_container", darkMode ? "#FFFFFF" : "#842029");

        // --- Surfaces & Backgrounds ---
        background = getC("background", darkMode ? "#000000" : "#FFFFFF");
        backgroundFg = getC("on_background", darkMode ? "#FFFFFF" : "#000000");
        surface = getC("surface", darkMode ? "#000000" : "#FFFFFF");
        surfaceFg = getC("on_surface", darkMode ? "#FFFFFF" : "#000000");
        surfaceVariant = getC("surface_variant", darkMode ? "#1A1A1A" : "#F8F9FA");
        surfaceVariantFg = getC("on_surface_variant", darkMode ? "#E0E0E0" : "#212529");

        surfaceContainerLowest = getC("surface_container_lowest", darkMode ? "#000000" : "#FFFFFF");
        surfaceContainerLow = getC("surface_container_low", darkMode ? "#0A0A0A" : "#F8F9FA");
        surfaceContainer = getC("surface_container", darkMode ? "#121212" : "#F1F3F5");
        surfaceContainerHigh = getC("surface_container_high", darkMode ? "#1A1A1A" : "#E9ECEF");
        surfaceContainerHighest = getC("surface_container_highest", darkMode ? "#222222" : "#DEE2E6");

        // --- Outlines & Effects ---
        outline = getC("outline", darkMode ? "#333333" : "#DEE2E6");
        outlineVariant = getC("outline_variant", darkMode ? "#444444" : "#CED4DA");
        shadow = getC("shadow", "#000000");
        scrim = getC("scrim", "#000000");

        // --- Inverse Sets ---
        inverseSurface = getC("inverse_surface", darkMode ? "#FFFFFF" : "#362F27");
        inverseSurfaceFg = getC("inverse_on_surface", darkMode ? "#000000" : "#FBEFE2");
        inversePrimary = getC("inverse_primary", "#007BFF");
    }

    function parseTheme(content) {
        if (!content)
            return;
        try {
            var json = JSON.parse(content.trim());
            root.colors = json.colors || {};
            root.updateColorProperties();
        } catch (e) {
            console.warn("[Theme] JSON error, using hardcoded fallbacks.");
            root.colors = {};
            root.updateColorProperties();
        }
    }

    FileView {
        id: themeFile
        watchChanges: true
        path: Paths.home + "/.config/quickshell/quickshell.json"
        onFileChanged: reloadTimer.restart()
        onTextChanged: parseTheme(text())
        onLoaded: parseTheme(text())
    }

    Timer {
        id: reloadTimer
        interval: 200
        onTriggered: themeFile.reload()
    }
}
