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
    property string iconTheme: "Papirus"
    property string defaultIconTheme: ""
    property bool hasTriedDefaultSettings: false
    property var availableIconThemes: []
    property bool audioVolumeOverdrive: true
    property int audioVolumeStep: 2
    property string wallpaperImage: ""
    property var wallpaperFolderImages: []
    readonly property string _homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    readonly property string _configUrl: StandardPaths.writableLocation(StandardPaths.ConfigLocation)
    readonly property string _configDir: Utils.strip(_configUrl)

    Component.onCompleted: {
        loadSettings();
        detectDefault();
        if (defaultIconTheme != iconTheme) {
            setIconTheme();
        }
        console.log(defaultIconTheme);
    }

    onDarkModeChanged: {
        saveSettings();
        updateAppsColorScheme();
    }
    onWallpaperFolderImagesChanged: saveSettings()
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
            "audioVolumeStep": audioVolumeStep,
            "audioVolumeOverdrive": audioVolumeOverdrive,
            "wallpaperImage": wallpaperImage
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
                audioVolumeOverdrive = settings.audioVolumeOverdrive !== undefined ? settings.audioVolumeOverdrive : false;
                audioVolumeStep = settings.audioVolumeStep !== undefined ? settings.audioVolumeStep : 1;
                wallpaperFolderImages = settings.wallpaperFolderImages !== undefined ? settings.wallpaperFolderImages : [];
                wallpaperImage = settings.wallpaperImage !== undefined ? settings.wallpaperImage : "";
                loadAvailableIcons();
                detectDefault();
            }
        } catch (e) {
            console.error(e);
        } finally {
            _loading = false;
        }
    }

    function loadSettings() {
        _loading = true;
        parseSettings(settingsFile.text());
        _loading = false;
    }

    function loadAvailableIcons() {
        iconThemeDetectionProcess.running = true;
    }

    function setFont() {
    }

    function setIconTheme(theme) {
        setGtkIconTheme();
    }

    function setGtkIconTheme() {
        Proc.runCommand("gtkIconTheme", ["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", iconTheme == "System Default" ? defaultIconTheme : iconTheme], null, 500, 3000);
    }

    function detectDefault() {
        systemDefaultDetectionProcess.running = true;
    }

    function setDarkMode(value) {
        darkMode = value;
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

        const imagePath = Utils.strip(wallpaperImage);
        Quickshell.execDetached(["matugen", "image", "-c", Utils.strip(Utils.config) + "/quickshell/matugen/config/neoshell.toml"  // Your config path
            , imagePath]);
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
                root.saveSettings();
            }
        }
    }

    Process {
        id: systemDefaultDetectionProcess

        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | sed \"s/'//g\" || echo ''"]
        running: false
        onExited: exitCode => {
            if (exitCode === 0 && stdout && stdout.length > 0)
                root.defaultIconTheme = stdout.trim();
            else
                root.defaultIconTheme = "";
            iconThemeDetectionProcess.running = true;
        }
    }
}
