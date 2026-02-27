import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Item {
    id: root
    property real progress: 0.5
    property color bgColor: Theme.surface
    property color progressColor: Theme.primary
    property color inactiveColor: Theme.surfaceContainerHighest
    implicitHeight: 4
    implicitWidth: 100

    RowLayout {
        anchors.fill: parent
        spacing: 5
        Rectangle {
            implicitHeight: parent.height
            implicitWidth: Math.max(parent.height, root.width * Math.min(1, root.progress))
            color: root.progressColor
            radius: height / 2

            Behavior on implicitWidth {
                NumberAnimation {
                    easing.type: Easing.OutCubic
                    duration: 200
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            radius: Settings.radius
            implicitHeight: parent.height
            color: root.inactiveColor

            Behavior on implicitWidth {
                NumberAnimation {
                    easing.type: Easing.OutCubic
                    duration: 200
                }
            }
        }
    }
    Rectangle {
        implicitHeight: root.height
        implicitWidth: root.height
        color: root.progressColor
        z: 1
        radius: height / 2
        anchors.right: parent.right
    }
}
