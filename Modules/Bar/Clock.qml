// Clock.qml
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Services

Rectangle {
    id: root

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: timeRow.implicitWidth + 24
    implicitHeight: 28
    color: clockMouse.containsMouse ? Theme.getColor("tertiary_container") : Theme.getColor("surface_container_highest")
    radius: 12
    border.width: 1
    border.color: Qt.darker(Theme.getColor("outline"))

    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    property date currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            // TODO: Show calendar panel
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
            color: clockMouse.containsMouse ? Theme.getColor("on_tertiary_container") : Theme.getColor("on_surface")
            Layout.alignment: Qt.AlignVCenter
        }

        // Time
        Text {
            text: Qt.formatDateTime(root.currentTime, "hh:mm")
            color: clockMouse.containsMouse ? Theme.getColor("on_tertiary_container") : Theme.getColor("on_surface")
            font.pixelSize: 14
            font.family: Settings.fontFamily
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        // Separator
        Rectangle {
            width: 1
            height: 14
            color: clockMouse.containsMouse ? Theme.getColor("on_tertiary_container") : Theme.getColor("outline")
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        // Date
        Text {
            text: Qt.formatDateTime(root.currentTime, "ddd, MMM d")
            color: clockMouse.containsMouse ? Theme.getColor("on_tertiary_container") : Theme.getColor("on_surface_variant")
            font.pixelSize: 12
            font.family: Settings.fontFamily
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
