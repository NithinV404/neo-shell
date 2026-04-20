import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.Services
import qs.Common

Item {
    id: root
    implicitWidth: buttonContent.width + 24
    implicitHeight: 40
    property string text: "Button"
    property string icon: ""
    property bool primary: false
    property bool enabled: true
    property color bgColor: Theme.primary
    property color textColor: Theme.primaryFg

    property color normalColor: bgColor
    property color hoverColor: Qt.lighter(bgColor, 0.9)
    property color pressedColor: Qt.darker(bgColor, 1.0)
    property color disabledColor: Qt.darker(bgColor, 1.8)

    signal clicked

    DropShadow {
        anchors.fill: button
        source: button
        horizontalOffset: 0
        verticalOffset: 6
        radius: 16
        samples: 41
        color: Qt.rgba(0, 0, 0, 0.25)
        transparentBorder: true
    }

    Rectangle {
        id: button
        anchors.fill: parent
        radius: Settings.radius
        clip: true

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

        RowLayout {
            id: buttonContent
            anchors.centerIn: parent
            spacing: 8

            StyledText {
                visible: root.icon !== ""
                text: root.icon
                size: root.height * 0.45
                color: !root.enabled ? Qt.darker(root.textColor) : root.textColor
            }

            Text {
                text: root.text
                font.pixelSize: root.height * 0.30
                font.family: Settings.fontFamily
                font.weight: Font.Medium
                color: !root.enabled ? Qt.darker(root.textColor, 1.4) : root.textColor
            }
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            if (root.enabled) {
                Effects.animation.ripple(button, button.x, button.y);
                root.clicked();
            }
        }
    }
}
