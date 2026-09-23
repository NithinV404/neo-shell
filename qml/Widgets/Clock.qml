// Clock.qml
import QtQuick
import QtQuick.Layouts
import Shell.Services

Rectangle {
    id: root
    property bool hovered: false
    property date time_date: new Date();
    width: timeRow.implicitWidth + 30
    height: 28

    // I updated this so the color actually changes when hovered
    color: hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
    radius: 12

    Behavior on color {
        ColorAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    // 1. Add a MouseArea to handle clicks and hover
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            // Toggle the panel visibility when clicked
            clockPanel.visible = !clockPanel.visible;
        }
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }

    RowLayout {
        id: timeRow
        anchors.centerIn: parent
        spacing: 4

        // Time
        Text {
            id: textTime
            text: ClockService.time
            color: Theme.onSurface
            font.pixelSize: Math.round(root.height * 0.4)
            font.weight: 500
            font.family: "Adwaita Sans"
            Layout.alignment: Qt.AlignCenter
            renderType: Text.QtRendering
        }

        // Separator
        Rectangle {
            Layout.preferredWidth: 4
            Layout.preferredHeight: 4
            radius: 12
            color: Theme.onSurface
            opacity: 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        // Date
        Text {
            text: ClockService.date
            color: Theme.onSurface
            font.pixelSize: 12
            font.weight: 500
            font.family: "Adwaita Sans"
            Layout.alignment: Qt.AlignCenter
            renderType: Text.QtRendering
            font.hintingPreference: Font.PreferFullHinting
        }
    }
}
