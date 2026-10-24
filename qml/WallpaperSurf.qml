import QtQuick
import QtQuick.Effects
import Shell
import Shell.Services

PanelWindow {
    id: root
    visible: true
    layer: PanelWindow.Background
    scope:  "neoshell-wallpaper"
    anchors: PanelWindow.AnchorTop | PanelWindow.AnchorRight | PanelWindow.AnchorBottom | PanelWindow.AnchorLeft
    keyboardInteractivity: PanelWindow.None
    exclusionZone: -1
    color: "transparent"


    WallpaperItem {
        id: wallpaper
        anchors.fill: parent
        source: "file:///mnt/vault/Pictures/Wallpapers/wallhaven-ly8l7p_3840x2160.png"
        size: Qt.size(1920,1080)
    }

    PanelWindow {
        id: backdrop
        visible: true
        layer: PanelWindow.Background
        scope:  "neoshell-backdrop"
        anchors: PanelWindow.AnchorTop | PanelWindow.AnchorRight | PanelWindow.AnchorBottom | PanelWindow.AnchorLeft
        keyboardInteractivity: PanelWindow.None
        exclusionZone: -1
        color: "transparent"

        WallpaperItem {
            id: backdropSource
            anchors.fill: parent
            source: "file:///mnt/vault/Pictures/Wallpapers/wallhaven-ly8l7p_3840x2160.png"
            size: Qt.size(1920,1080)
        }
    }
}
