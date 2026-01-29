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
            return Theme.getColor("surface_container");
        if (root.primary) {
            return buttonMouse.containsPress ? Theme.getColor("primary_container") : buttonMouse.containsMouse ? Qt.lighter(Theme.getColor("primary"), 1.1) : Theme.getColor("primary");
        }
        return buttonMouse.containsPress ? Theme.getColor("surface_container_high") : buttonMouse.containsMouse ? Theme.getColor("surface_container_highest") : Theme.getColor("surface");
    }
    border.color: root.primary ? "transparent" : Theme.getColor("outline")
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
                    return Theme.getColor("on_surface_variant");
                return root.primary ? Theme.getColor("on_primary") : Theme.getColor("primary");
            }
        }

        Text {
            text: root.text
            font.pixelSize: 14
            font.family: Settings.fontFamily
            font.weight: Font.Medium

            color: {
                if (!root.enabled)
                    return Theme.getColor("on_surface_variant");
                return root.primary ? Theme.getColor("on_primary") : Theme.getColor("primary");
            }
        }
    }
}
