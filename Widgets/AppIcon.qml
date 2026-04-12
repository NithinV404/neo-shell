import QtQuick
import qs.Common
import qs.Services
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property string icon
    property string name: ""
    property int size: 56

    implicitWidth: size
    implicitHeight: size

    // Look up the desktop entry to get the correct icon
    readonly property var desktopEntry: {
        const appId = root.icon ?? "";

        if (appId.startsWith("/")) {
            return appId;
        }

        if (!appId)
            return null;

        const lastPart = appId.toLowerCase().split(".").slice(-1)[0];

        // Base variations for exact matching
        const exactLookups = [appId, appId.toLowerCase(), lastPart, lastPart.replace(/_/g, "-"), lastPart.replace(/-/g, "_")];

        // Try exact matches first
        for (const id of exactLookups) {
            const entry = DesktopEntries.byId(id);
            if (entry)
                return entry;
        }

        const searchResult = Utils.heuristicSearch(DesktopEntries.applications.values, lastPart);
        if (searchResult.length > 0) {
            return searchResult[0];
        }

        return null;
    }

    // Use icon from desktop entry, otherwise try app_id directly
    property string iconName: desktopEntry?.icon ?? root.icon ?? ""
    property bool hasIcon: iconName && iconName !== null
    property bool iconLoaded: hasIcon && iconImage.status === Image.Ready

    // Fallback
    Rectangle {
        anchors.fill: parent
        radius: Settings.radius
        color: Theme.primary
        visible: !root.iconLoaded

        Text {
            anchors.centerIn: parent
            text: root.name ? root.name.charAt(0).toUpperCase() : root.iconName ? root.iconName.charAt(0).toUpperCase() : "?"
            font.pixelSize: root.size * 0.45
            font.family: Settings.fontFamily
            font.weight: Font.Medium
            color: Theme.primaryFg
        }
    }

    // Icon
    IconImage {
        id: iconImage
        visible: root.iconLoaded

        source: {
            if (root.hasIcon) {
                if (root.iconName.startsWith("/")) {
                    return "file://" + root.iconName;
                } else if (root.iconName.startsWith("image:")) {
                    return root.iconName;
                } else {
                    Quickshell.iconPath(root.iconName, true);
                }
            } else {
                return "?";
            }
        }
        asynchronous: true
        implicitSize: root.size
        onStatusChanged: {
            if (status === Image.Error || status === Image.Null) {
                console.info(`Failed to Load icon for ${root.iconName}`);
            }
        }
    }
}
