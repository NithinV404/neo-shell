import QtQuick
import qs.Common
import qs.Services
import Quickshell

Item {
    id: root

    property var icon
    property int size: 56

    implicitWidth: size
    implicitHeight: size

    property string iconName: root.icon?.icon ?? ""
    property bool hasIcon: iconName !== "" && iconName !== null
    property bool iconLoaded: hasIcon && iconImage.status === Image.Ready

    // Fallback
    Rectangle {
        anchors.fill: parent
        radius: size * 0.22
        color: Theme.primaryContainer
        visible: !root.iconLoaded

        Text {
            anchors.centerIn: parent
            text: root.icon?.name?.charAt(0)?.toUpperCase() ?? "?"
            font.pixelSize: root.size * 0.45
            font.family: Settings.fontFamily
            font.weight: Font.Medium
            color: Theme.primaryContainerFg
        }
    }

    // Icon
    Image {
        id: iconImage
        anchors.fill: parent
        visible: root.iconLoaded
        source: Quickshell.iconPath(root.icon?.icon ?? "", true)
        sourceSize: Qt.size(root.size, root.size)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        cache: true
    }
}
