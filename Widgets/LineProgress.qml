import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Item {
    id: root
    property real progress: 0.5
    property real maxProgress: 1.5
    property color bgColor: Theme.surface
    property color progressColor: Theme.primary
    property color inactiveColor: Theme.surfaceContainerHighest
    height: 4
    width: 100
    clip: true

    readonly property real _normalized: Math.max(0, Math.min(1, progress / maxProgress))

    RowLayout {
        anchors.fill: parent
        spacing: 5
        Rectangle {
            id: leftLine
            Layout.alignment: Qt.AlignLeft
            height: parent.height
            width: Math.max(parent.height, root.width * root._normalized)
            color: root.progressColor
            radius: height / 2

            Behavior on width {
                NumberAnimation {
                    easing.type: Easing.OutCubic
                    duration: 200
                }
            }
        }
        Rectangle {
            id: rightLine
            Layout.alignment: Qt.AlignLeft
            x: leftLine.width + 5
            width: root.width - leftLine.width - 5
            radius: Settings.radius
            height: parent.height
            color: root.inactiveColor
        }
    }
    Rectangle {
        height: root.height
        width: root.height
        color: root.progressColor
        z: 1
        radius: height / 2
        anchors.right: parent.right
    }
}
