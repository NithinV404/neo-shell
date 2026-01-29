import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Components
import qs.Common

Item {
    id: root

    implicitWidth: 200
    implicitHeight: 40

    property real value: 0.5
    property real minValue: 0.0
    property real maxValue: 1.0
    property string icon: ""
    property bool showValue: true
    property color accentColor: Theme.getColor("primary")

    signal moved(real newValue)

    readonly property real normalizedValue: {
        if (maxValue === minValue)
            return 0;
        return (value - minValue) / (maxValue - minValue);
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: height / 4
        color: Theme.getColor("surface_container_highest")

        // Clipping container - this is the key!
        Item {
            id: fillClipper
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.normalizedValue
            clip: true

            Behavior on width {
                enabled: !mouseArea.pressed
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            // Fill is always full parent width with proper radius
            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: background.width
                radius: background.radius
                color: root.accentColor
            }
        }
        Rectangle {
            id: handle
            width: 12
            height: parent.height + 18
            radius: 5
            color: Theme.getColor("surface")
            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - 10) * root.normalizedValue
            Behavior on x {
                enabled: !mouseArea.pressed
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                id: handleFill
                color: Theme.getColor("primary")
                height: parent.height - 1
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 8
                radius: 24
            }
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 8

            StyledText {
                visible: root.icon !== ""
                name: root.icon
                size: 18
                color: root.normalizedValue > 0.15 ? Theme.getColor("on_primary") : Theme.getColor("on_surface_variant")

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                visible: root.showValue
                text: Math.round(root.value)
                font.family: Settings.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                color: root.normalizedValue > 0.85 ? Theme.getColor("on_primary") : Theme.getColor("on_surface")

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            Rectangle {
                visible: !root.showValue && root.normalizedValue < 0.9
                height: 4
                width: 4
                color: Theme.getColor("primary")
                radius: background.height / 2
                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: mouse => updateValue(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    updateValue(mouse.x);
            }

            function updateValue(mouseX) {
                let norm = Math.max(0, Math.min(1, mouseX / width));
                root.value = root.minValue + norm * (root.maxValue - root.minValue);
                root.moved(root.value);
            }
        }
    }
}
