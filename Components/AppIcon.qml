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

    // Look up the desktop entry to get the correct icon
    readonly property var desktopEntry: {
        const appId = root.icon?.icon ?? "";
        if (!appId)
            return null;

        return DesktopEntries.byId(appId) ?? DesktopEntries.byId(appId.toLowerCase()) ?? DesktopEntries.byId(appId + ".desktop") ?? DesktopEntries.byId(appId.toLowerCase() + ".desktop") ?? null;
    }

    // Use icon from desktop entry, otherwise try app_id directly
    property string iconName: desktopEntry?.icon ?? root.icon?.icon ?? ""
    property bool hasIcon: iconName !== "" && iconName !== null
    property bool iconLoaded: hasIcon && iconImage.status === Image.Ready

    Component.onCompleted: {
        console.log("app_id:", root.icon?.icon, "→ iconName:", iconName, "→ desktopEntry:", desktopEntry);
    }

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
        source: root.hasIcon ? Quickshell.iconPath(root.iconName, true) : ""
        sourceSize: Qt.size(root.size, root.size)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
        cache: true

        onStatusChanged: {
            if (status === Image.Error) {
                console.log("Failed to load icon:", root.iconName, "for app:", root.icon?.icon);
            }
        }
    }
}
