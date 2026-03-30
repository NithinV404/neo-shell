import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Rectangle {
    id: root

    property string text: "Button"
    property string icon: ""
    property bool primary: false
    property bool enabled: true
    property color bgColor: Theme.primary
    property color textColor: Theme.primaryFg

    property color normalColor: bgColor
    property color hoverColor: Qt.lighter(bgColor)
    property color pressedColor: Qt.darker(bgColor, 1.0)
    property color disabledColor: Qt.darker(bgColor, 1.8)

    signal clicked

    implicitWidth: buttonContent.implicitWidth + 30
    implicitHeight: 34
    radius: Settings.radius

    color: {
        if (!root.enabled)
            return root.disabledColor;
        if (buttonMouse.containsPress)
            return root.pressedColor;
        if (buttonMouse.containsMouse)
            return root.hoverColor;
        return root.normalColor;
    }

    border.color: root.primary ? "transparent" : Qt.darker(root.bgColor, 1.4)
    border.width: root.primary ? 0 : 1

    Behavior on color {
        ColorAnimation {
            duration: 150
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            if (root.enabled)
                root.clicked();
        }
    }

    RowLayout {
        id: buttonContent
        anchors.centerIn: parent
        spacing: 8

        StyledText {
            visible: root.icon !== ""
            text: root.icon
            size: 20
            color: !root.enabled ? Qt.darker(root.textColor) : root.textColor
        }

        Text {
            text: root.text
            font.pixelSize: root.height * 0.25
            font.family: Settings.fontFamily
            font.weight: Font.Medium
            color: !root.enabled ? Qt.darker(root.textColor, 1.4) : root.textColor
        }
    }
}
