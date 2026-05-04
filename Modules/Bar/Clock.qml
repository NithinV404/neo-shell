// Clock.qml
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import Quickshell

Rectangle {
    id: root
    required property var screen
    property var activePanel: null
    property bool hovered: false
    implicitWidth: timeRow.implicitWidth + 30
    implicitHeight: 28
    color: "transparent"
    radius: Settings.radius

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

    
    RowLayout {
        id: timeRow
        anchors.centerIn: parent
        spacing: 4

        // Time
        Text {
            id: textTime
            text: Qt.formatDateTime(clock.date, "hh:mm ap")
            color: root.hovered ? Theme.tertiaryContainerFg : Theme.surfaceFg
            font.pixelSize: root.height * 0.45
            font.family: Settings.fontFamily
            Layout.alignment: Qt.AlignCenter
        }

        // Separator
        Rectangle {
            implicitWidth: 4
            implicitHeight: 4
            radius: Settings.radius
            color: root.hovered  ? Theme.tertiaryContainerFg : Theme.outline
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        // Date
        Text {
            text: Qt.formatDateTime(clock.date, "ddd MM/dd")
            color: root.hovered ? Theme.tertiaryContainerFg : Theme.surfaceFg
            font.pixelSize: root.height * 0.42
            font.family: Settings.fontFamily
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 1
        }
    }
   
}
