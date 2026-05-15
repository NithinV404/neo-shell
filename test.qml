import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: root
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    Item {
        anchors.centerIn: parent
        width: 400
        height: 200

        Rectangle {
            anchors.fill: parent
            color: "green"
        }

        Item {
            anchors.centerIn: parent
            width: 80
            height: 40

            Rectangle {
                anchors.fill: parent
                color: "red"
                radius: 24
            }

            Rectangle {
                id: mask
                color: "red"
                visible: false
                anchors.fill: parent
                radius: 24
                clip: true
            }

            Item {
                id: batteryFill
                anchors.fill: parent
                visible: false

                Rectangle {
                    width: parent.width * 0.8
                    height: parent.height
                    color: "blue"
                    radius: 24
                }
            }

            OpacityMask {
                source: batteryFill
                maskSource: mask
                anchors.fill: parent
            }
        }
    }
}
