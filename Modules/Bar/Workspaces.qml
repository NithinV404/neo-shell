// Workspaces.qml
import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Services

Rectangle {
    id: root

    property string screenName: ""

    implicitWidth: workspaceRow.implicitWidth + 24
    implicitHeight: parent.height * 0.75
    color: Theme.secondaryContainer
    radius: 24
    Layout.alignment: Qt.AlignLeft

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutBack
        }
    }

    RowLayout {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: NiriService.allWorkspaces.filter(ws => ws.output === root.screenName)

            delegate: Rectangle {
                id: pill

                required property var modelData
                required property int index

                readonly property bool isFocused: modelData.is_focused

                Layout.alignment: Qt.AlignVCenter

                implicitWidth: isFocused ? 20 : 8
                implicitHeight: 8
                radius: height / 2

                color: isFocused ? Theme.primary : pillMouse.containsMouse ? Theme.tertiary : Theme.outline

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        NiriService.switchToWorkspace(pill.modelData.idx);
                    }
                }
            }
        }
    }
}
