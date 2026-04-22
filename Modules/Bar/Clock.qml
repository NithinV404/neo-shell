// Clock.qml
import QtQuick
import QtQuick.Layouts
import qs.Common

import qs.Services
import qs.Modules.Bar.Wallpaper
import Quickshell

Rectangle {
    id: root
    required property var screen
    property var activePanel: null
    implicitWidth: timeRow.implicitWidth + 30
    implicitHeight: 28
    color: "transparent" //clockMouse.containsMouse ? Theme.tertiaryContainer : Theme.surfaceContainer
    radius: Settings.radius
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
        spacing: 4

        // Time
        Text {
            id: textTime
            text: Qt.formatDateTime(clock.date, "hh:mm ap")
            color: clockMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.surfaceFg
            font.pixelSize: root.height * 0.5
            font.family: Settings.fontFamily
            Layout.alignment: Qt.AlignCenter
        }

        // Separator
        Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            radius: Settings.radius
            color: clockMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.outline
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        // Date
        Text {
            text: Qt.formatDateTime(clock.date, "ddd MM/dd")
            color: clockMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.surfaceFg
            font.pixelSize: root.height * 0.45
            font.family: Settings.fontFamily
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 1
        }
    }
    LazyLoader {
        id: panel
        active: false
        WallpaperPanel {
            screen: root.screen
            onMenuClosed: {
                panel.active = false;
                root.activePanel = null;
            }
        }
        onActiveChanged: {
            if (active && panel.item) {
                var pos = root.mapToGlobal(0, 0);
                console.info(pos);
                root.activePanel = panel.item;
                panel.item.openAt(pos.x + (root.width / 2), pos.y + root.height + 8);
            }
        }
    }
}
