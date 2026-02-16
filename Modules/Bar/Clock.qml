// Clock.qml
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Services
import qs.Modules.Bar.Wallpaper
import Quickshell

Rectangle {
    id: root
    property var activePanel: null
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: timeRow.implicitWidth + 16
    implicitHeight: parent.height * 0.75
    color: clockMouse.containsMouse ? Theme.tertiaryContainer : Theme.secondaryContainer
    radius: 24
    // border.width: 1
    // border.color: Qt.darker(Theme.outline)

    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function openPanel() {
        var getLocalPos = root.mapToItem(null, 0, 0);
        if (root.activePanel === null) {
            panel.active = true;
            activePanel = panel.item;
        } else {
            closePanel();
        }
    }

    function closePanel() {
        if (root.activePanel !== null) {
            root.activePanel.close();
        }
        return;
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            root.openPanel();
        }
    }

    RowLayout {
        id: timeRow
        anchors.centerIn: parent
        spacing: 8

        // Clock icon
        StyledText {
            name: "schedule"
            size: 16
            color: clockMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.secondaryContainerFg
            Layout.alignment: Qt.AlignVCenter
        }

        // Time
        Text {
            text: Qt.formatDateTime(clock.date, "hh:mm ap")
            color: clockMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.secondaryContainerFg
            font.pixelSize: 14
            font.family: Settings.fontFamily
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Separator
        Rectangle {
            width: 1
            height: 14
            color: clockMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.outline
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        // Date
        Text {
            text: Qt.formatDateTime(clock.date, "ddd, MMM d")
            color: clockMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.secondaryContainerFg
            font.pixelSize: 12
            font.family: Settings.fontFamily
            Layout.alignment: Qt.AlignVCenter
        }
    }
    LazyLoader {
        id: panel
        active: false
        WallpaperPanel {
            onMenuClosed: {
                panel.active = false;
                root.activePanel = null;
            }
        }
        onActiveChanged: {
            if (active && panel.item) {
                var pos = root.mapToItem(null, 0, 0);
                root.activePanel = panel.item;
                panel.item.openAt(pos.x + (root.width / 2), pos.y);
            }
        }
    }
}
