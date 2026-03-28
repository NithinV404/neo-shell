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

    // --- Hardcoded Simple Palette (Defaults) ---
    // Blue for Active/Primary
    property color primary: "#007BFF"
    property color primaryFg: "#FFFFFF"
    property color primaryContainer: darkMode ? "#004085" : "#CCE5FF"
    property color primaryContainerFg: darkMode ? "#FFFFFF" : "#004085"

    // Secondary & Tertiary (Mapped to Blue/Gray for simplicity)
    property color secondary: "#6C757D"
    property color secondaryFg: "#FFFFFF"
    property color secondaryContainer: darkMode ? "#495057" : "#E9ECEF"
    property color secondaryContainerFg: darkMode ? "#FFFFFF" : "#212529"

    property color tertiary: "#007BFF"
    property color tertiaryFg: "#FFFFFF"
    property color tertiaryContainer: darkMode ? "#004085" : "#CCE5FF"
    property color tertiaryContainerFg: darkMode ? "#FFFFFF" : "#004085"

    // Error (Standard Red)
    property color error: "#DC3545"
    property color errorFg: "#FFFFFF"
    property color errorContainer: darkMode ? "#921B27" : "#F8D7DA"
    property color errorContainerFg: darkMode ? "#FFFFFF" : "#842029"

    // Background (Black/White)
    property color background: darkMode ? "#000000" : "#FFFFFF"
    property color backgroundFg: darkMode ? "#FFFFFF" : "#000000"

    // Surface
    property color surface: darkMode ? "#000000" : "#FFFFFF"
    property color surfaceFg: darkMode ? "#FFFFFF" : "#000000"
    property color surfaceVariant: darkMode ? "#1A1A1A" : "#F8F9FA"
    property color surfaceVariantFg: darkMode ? "#E0E0E0" : "#212529"
    property color surfaceDim: darkMode ? "#000000" : "#DEE2E6"
    property color surfaceBright: darkMode ? "#1A1A1A" : "#FFFFFF"

    // Detailed Surface Containers
    property color surfaceContainerLowest: darkMode ? "#000000" : "#FFFFFF"
    property color surfaceContainerLow: darkMode ? "#0A0A0A" : "#F8F9FA"
    property color surfaceContainer: darkMode ? "#121212" : "#F1F3F5"
    property color surfaceContainerHigh: darkMode ? "#1A1A1A" : "#E9ECEF"
    property color surfaceContainerHighest: darkMode ? "#222222" : "#DEE2E6"
    property color surfaceTint: "#007BFF"

    // Outline
    property color outline: darkMode ? "#333333" : "#DEE2E6"
    property color outlineVariant: darkMode ? "#444444" : "#CED4DA"

    // Other
    property color shadow: "#000000"
    property color scrim: "#000000"

    // Inverse
    property color inverseSurface: darkMode ? "#FFFFFF" : "#000000"
    property color inverseSurfaceFg: darkMode ? "#000000" : "#FFFFFF"
    property color inversePrimary: "#007BFF"

    onDarkModeChanged: updateColorProperties()

    function updateColorProperties() {
        var mode = darkMode ? "dark" : "light";
        var c = colors[mode] || {};

        // Helper to grab JSON color OR use our new hardcoded simple fallback
        function getC(key, fallback) {
            return c[key] ? Qt.color(c[key]) : Qt.color(fallback);
        }

        primary = getC("primary", "#007BFF");
        primaryFg = getC("on_primary", "#FFFFFF");
        primaryContainer = getC("primary_container", darkMode ? "#004085" : "#CCE5FF");
        primaryContainerFg = getC("on_primary_container", darkMode ? "#FFFFFF" : "#004085");

        secondary = getC("secondary", "#6C757D");
        secondaryFg = getC("on_secondary", "#FFFFFF");

        background = getC("background", darkMode ? "#000000" : "#FFFFFF");
        backgroundFg = getC("on_background", darkMode ? "#FFFFFF" : "#000000");

        surface = getC("surface", darkMode ? "#000000" : "#FFFFFF");
        surfaceFg = getC("on_surface", darkMode ? "#FFFFFF" : "#000000");
        surfaceVariant = getC("surface_variant", darkMode ? "#1A1A1A" : "#F8F9FA");
        surfaceVariantFg = getC("on_surface_variant", darkMode ? "#E0E0E0" : "#212529");

        outline = getC("outline", darkMode ? "#333333" : "#DEE2E6");
        error = getC("error", "#DC3545");

        // Sync inverse colors
        inverseSurface = getC("inverse_surface", darkMode ? "#FFFFFF" : "#000000");
        inverseSurfaceFg = getC("inverse_on_surface", darkMode ? "#000000" : "#FFFFFF");
    }

    // --- File Handling remains the same ---
    function parseTheme(content) {
        if (!content) return;
        try {
            var json = JSON.parse(content.trim());
            root.colors = json.colors || {};
            root.updateColorProperties();
        } catch (e) {
            console.warn("[Theme] JSON error, keeping simple Black/White/Blue.");
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
