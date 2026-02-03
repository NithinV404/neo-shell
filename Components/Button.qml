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

    signal clicked

    implicitWidth: buttonContent.implicitWidth + 30
    implicitHeight: 34
    radius: 22
    color: {
        if (!root.enabled)
            return Theme.surfaceContainer;
        if (root.primary) {
            return buttonMouse.containsPress ? Theme.primaryContainer : buttonMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary;
        }
        return buttonMouse.containsPress ? Theme.surfaceContainerHigh : buttonMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surface;
    }
    border.color: root.primary ? "transparent" : Theme.outline
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
            if (root.enabled) {
                root.clicked();
            }
        }
    }

    RowLayout {
        id: buttonContent
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Settings.fontFamily
            font.pixelSize: 18
            color: {
                if (!root.enabled)
                    return Theme.surfaceVariantFg;
                return root.primary ? Theme.primaryFg : Theme.primary;
            }
        }

        Text {
            text: root.text
            font.pixelSize: 14
            font.family: Settings.fontFamily
            font.weight: Font.Medium

            color: {
                if (!root.enabled)
                    return Theme.surfaceVariantFg;
                return root.primary ? Theme.primaryFg : Theme.primary;
            }
        }
    }
}
