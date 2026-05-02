pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtCore
import QtQuick
import qs.Common

Singleton {
    id: root

    property bool _loading: true
    property bool darkMode: true
    property string fontFamily: "Adwaita Sans"
    property string iconTheme: "System Default"
    property string defaultIconTheme: ""
    property bool hasTriedDefaultSettings: false
    property var availableIconThemes: []
    property int duration: 300
    property string wallpaperImage: ""
    property string wallpapersFolder: "~/Pictures/Wallpapers"
    property var wallpaperFolderImages: []
    property int radius: 24
    readonly property string _homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    readonly property string _configUrl: StandardPaths.writableLocation(StandardPaths.ConfigLocation)
    readonly property string _configDir: Utils.strip(_configUrl)

    property QtObject brightness: QtObject {
        property bool enableDdcSupport: true
        property var backlightDeviceMappings: []
        property real enforceMinimum: 0.01
    }

    property QtObject audio: QtObject {
        property int volumeStep: 1
        property bool volumeOverdrive: true
        property bool volumeFeedback: false
    }

    Component.onCompleted: {
        loadSettings();
        detectDefault();
        setIconTheme();
    }

    onBrightnessChanged: {
        saveSettings()
    }

    onDarkModeChanged: {
        saveSettings();
        updateAppsColorScheme();
    }
    onIconThemeChanged: {
        setIconTheme();
    }
    onWallpaperFolderImagesChanged: saveSettings()
    onDefaultIconThemeChanged: {
        saveSettings();
    }
    onWallpaperImageChanged: {
        saveSettings();
        updateMatugenColors();
    }

    // Function for different Settings
    function saveSettings() {
        if (_loading) {
            return;
        }
        settingsFile.setText(JSON.stringify({
            "darkMode": darkMode,
            "fontFamily": fontFamily,
            "iconTheme": iconTheme,
            "wallpaperFolderImages": wallpaperFolderImages,
            "brightness": {
                "enableDdcSupport": brightness.enableDdcSupport, 
                "backlightDeviceMappings": brightness.backlightDeviceMappings, 
                "enforceMinimum": brightness.enforceMinimum
            },
            "audio": {
                "volumeStep": audio.volumeStep,
                "volumeOverdrive": audio.volumeOverdrive,
                "volumeFeedback": audio.volumeFeedback
            },
            "wallpapersFolder": wallpapersFolder,
            "wallpaperImage": wallpaperImage,
            "defaultIconTheme": defaultIconTheme,
            "radius": radius
        }, null, 2));
    }

    function parseSettings(content) {
        _loading = true;
        try {
            _loading = true;

            if (content && content.trim()) {
                var settings = JSON.parse(content);
                darkMode = settings.darkMode !== undefined ? settings.darkMode : "light";
                fontFamily = settings.fontFamily !== undefined ? settings.fontFamily : "Adwaita Sans";
                iconTheme = settings.iconTheme !== undefined ? settings.iconTheme : "System Default";
                brightness.enableDdcSupport = settings.brightness.enableDdcSupport !== undefined ? settings.brightness.enableDdcSupport : true
                brightness.backlightDeviceMappings = settings.brightness.backlightDeviceMappings !== undefined ? settings.brightness.backlightDeviceMappings : []
                brightness.enforceMinimum = settings.brightness.enforceMinimum !== undefined ? settings.brightness.enforceMinimum : 1.0   
                audio.volumeOverdrive = settings.audio.volumeOverdrive !== undefined ? settings.audio.volumeOverdrive : false;
                audio.volumeStep = settings.audio.volumeStep !== undefined ? settings.audio.volumeStep : 1;
                audio.volumeFeedback = settings.audio.volumeFeedback !== undefined ? settings.audio.volumeFeedback : false;
                wallpaperFolderImages = settings.wallpaperFolderImages !== undefined ? settings.wallpaperFolderImages : [];
                wallpapersFolder = settings.wallpapersFolder !== undefined ? settings.wallpapersFolder : "~/Pictures/Wallpapers";
                wallpaperImage = settings.wallpaperImage !== undefined ? settings.wallpaperImage : "";
                defaultIconTheme = settings.defaultIconTheme !== undefined ? settings.defaultIconTheme : "";
                radius = settings.radius !== undefined ? settings.radius : 24;
                loadAvailableIcons();
                detectDefault();
            }
        } catch (e) {
            console.error(e);
        } finally {
            _loading = false;
        }
    }

    function saveWallpapersFolderPath(path) {
        wallpapersFolder = path;
        saveSettings();
    }

    function loadSettings() {
        _loading = true;
        parseSettings(settingsFile.text());
        _loading = false;
    }

    function loadAvailableIcons() {
        if (availableIconThemes.length === 0) {
            iconThemeDetectionProcess.running = true;
        }
    }

    function setFont() {
    }

    function setIconTheme() {
        setGtkIconTheme();
    }

    function setGtkIconTheme() {
        let themeToSet = (iconTheme === "System Default") ? defaultIconTheme : iconTheme;
        if (themeToSet && themeToSet.trim() !== "") {
            Proc.runCommand("gtkIconTheme", ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", themeToSet], null, 500, 3000);
        } else {
            console.warn("Attempted to set icon theme to an empty string; ignoring.");
        }
    }

    function detectDefault() {
        detectDefaultIconThemeGtk();
    }

    function detectDefaultIconThemeGtk() {
        Proc.runCommand("detectDefaultIconThemeGtk", ["sh", "-c", "gsettings get org.gnome.desktop.interface icon-theme"], function (safeOutput) {
            var detected = safeOutput.trim().replace(/'/g, "");
            if (detected && detected !== "") {
                defaultIconTheme = detected;
            }
        }, 500, 3000);
    }

    function setDarkMode(value) {
        darkMode = value;
        saveSettings();
    }

    function setVolumeOverdrive(value) {
        audio.volumeOverdrive = value;
        saveSettings();
    }

    function updateAppsColorScheme() {
        setGtkColorScheme();
        setQtColorScheme();
    }

    function setQtColorScheme() {
        const scheme = root.darkMode ? "BreezeDark" : "BreezeLight";
        const kvTheme = root.darkMode ? "KvArcDark" : "KvArc";

        Proc.runCommand("setQtTheme", ["sh", "-c", `
        kwriteconfig6 --file kdeglobals --group General   --key ColorScheme '${scheme}' && \
        kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme '${scheme}' && \
        kvantummanager --set '${kvTheme}' && \
        dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 && \
        dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:2 int32:0
      `], null, 500, 5000);
    }

    function setGtkColorScheme() {
        Proc.runCommand("setGtk4Theme", ["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", root.darkMode ? "prefer-dark" : "prefer-light"], null, 300, 5000);
        Proc.runCommand("setGtk3Theme", ["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", root.darkMode ? "adw-gtk3-dark" : "adw-gtk3"], null, 300, 5000);
    }

    function updateWallpaperFolderImages(images) {
        if (images) {
            wallpaperFolderImages = images;
        }
        saveSettings();
    }

    function updateWallpaperImage(image) {
        if (image) {
            wallpaperImage = image;
        }
        saveSettings();
    }

    function updateMatugenColors() {
        if (_loading || !wallpaperImage)
            return;

        const imagePath = Utils.stringify(wallpaperImage);
        const configPath = Utils.stringify(Utils.config) + "/quickshell/Matugen/config/neoshell.toml";
        const command = `matugen image "${imagePath}" -c "${configPath}" --source-color-index 1 `;
        Quickshell.execDetached(["sh", "-c", command]);
    }

    // FileView for Storing and parsing the settings File
    FileView {
        id: settingsFile
        path: `${StandardPaths.writableLocation(StandardPaths.ConfigLocation)}/quickshell/settings.json`
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        watchChanges: true
        onLoaded: {
            root.parseSettings(settingsFile.text());
        }
        onLoadFailed: error => {
            return;
        }
    }

    // Process for different operations
    Process {
        id: iconThemeDetectionProcess

        command: ["sh", "-c", "find /usr/share/icons ~/.local/share/icons ~/.icons -maxdepth 1 -type d 2>/dev/null | sed 's|.*/||' | grep -v '^icons$' | sort -u"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var detectedThemes = ["System Default"];
                if (text && text.trim()) {
                    var themes = text.trim().split('\n');
                    for (var i = 0; i < themes.length; i++) {
                        var theme = themes[i].trim();
                        if (theme && theme !== "" && theme !== "default" && theme !== "hicolor" && theme !== "locolor")
                            detectedThemes.push(theme);
                    }
                }
                root.availableIconThemes = detectedThemes;
            }
        }
    }
}
