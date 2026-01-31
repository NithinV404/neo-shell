// ~/.config/quickshell/Modules/Wallpaper/Wallpaper.qml

import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    id: root

    property string source: ""
    property color color: "#1a1a2e"
    property int fillMode: Image.PreserveAspectCrop

    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        aboveWindows: false
        focusable: false

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "wallpaper"

        Rectangle {
            anchors.fill: parent
            color: root.color
            Image {
                anchors.fill: parent
                source: root.source
                fillMode: root.fillMode
                visible: root.source !== ""
            }
        }
    }
}
