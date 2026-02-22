import QtQuick
import qs.Common
import qs.Services
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property var icon
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

        // Fuzzy search through all available desktop entries
        const searchTerm = lastPart.toLowerCase();
        let bestMatch = null;
        let bestScore = 0;

        for (const entry of DesktopEntries.applications.values) {
            const entryId = (entry.id ?? "").toLowerCase();
            const entryName = (entry.name ?? "").toLowerCase();
            const entryExec = (entry.exec ?? "").toLowerCase();

            let score = 0;

            // Exact ID match (shouldn't happen, but just in case)
            if (entryId === searchTerm) {
                return entry;
            }

            // ID starts with search term (e.g., "helium" matches "helium-browser")
            if (entryId.startsWith(searchTerm + "-") || entryId.startsWith(searchTerm + "_") || entryId.startsWith(searchTerm + ".")) {
                score = 100;
            } else
            // ID contains search term
            if (entryId.includes(searchTerm)) {
                score = 75;
            } else
            // Name exactly matches
            if (entryName === searchTerm) {
                score = 90;
            } else
            // Name starts with search term
            if (entryName.startsWith(searchTerm)) {
                score = 70;
            } else
            // Name contains search term
            if (entryName.includes(searchTerm)) {
                score = 50;
            } else
            // Exec command contains search term
            if (entryExec.includes(searchTerm)) {
                score = 40;
            }

            // Prefer shorter IDs (more specific matches)
            if (score > 0) {
                score -= entryId.length * 0.1;
            }

            if (score > bestScore) {
                bestScore = score;
                bestMatch = entry;
            }
        }

        if (bestMatch) {
            console.log(`Fuzzy matched "${appId}" → "${bestMatch.id}" (score: ${bestScore.toFixed(1)})`);
            return bestMatch;
        }

        return null;
    }

    // Use icon from desktop entry, otherwise try app_id directly
    property string iconName: desktopEntry?.icon ?? root.icon ?? ""
    property bool hasIcon: iconName !== "" && iconName !== null
    property bool iconLoaded: hasIcon && iconImage.status === Image.Ready

    // Fallback
    Rectangle {
        anchors.fill: parent
        radius: 24
        color: Theme.primaryContainer
        visible: !root.iconLoaded

        Text {
            anchors.centerIn: parent
            text: root.iconName.charAt(0)?.toUpperCase() ?? "?"
            font.pixelSize: root.size * 0.45
            font.family: Settings.fontFamily
            font.weight: Font.Medium
            color: Theme.primaryContainerFg
        }
    }

    // Icon
    IconImage {
        id: iconImage
        visible: root.iconLoaded
        source: root.hasIcon ? root.iconName.startsWith("/") ? "file://" + root.iconName : Quickshell.iconPath(root.iconName, true) : ""
        mipmap: true
        asynchronous: true
        implicitSize: root.size

        onStatusChanged: {
            if (status === Image.Error) {
                console.log("Failed to load icon:", root.iconName, "for app:", root.icon);
            }
        }
    }
}
