// Workspaces.qml
import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Services

Rectangle {
    id: root
    implicitWidth: workspaceRow.implicitWidth + 10
    implicitHeight: parent.height * 0.75
    color: Theme.secondaryContainer
    radius: 24
    Layout.alignment: Qt.AlignLeft
    // border.width: 1
    // border.color: Qt.darker(Theme.outline)

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutBack
        }
    }

    RowLayout {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: NiriService.currentOutputWorkspaces

            delegate: Rectangle {
                id: workspacePill

                required property var modelData
                required property int index

                readonly property bool isFocused: modelData.is_focused
                readonly property bool isActive: modelData.is_active
                readonly property var workspaceWindows: getWorkspaceWindows(modelData.id)

                Layout.alignment: Qt.AlignVCenter
                implicitWidth: workspacePill.workspaceWindows.length > 0 ? pillContent.implicitWidth + 13 : 25
                implicitHeight: workspacePill.workspaceWindows.length > 0 ? pillContent.implicitHeight + 6 : 20
                radius: workspacePill.workspaceWindows.length > 0 ? 24 : 10

                color: {
                    if (isFocused) {
                        return pillMouse.containsMouse ? Qt.darker(Theme.primary) : Theme.primary;
                    } else if (isActive) {
                        return pillMouse.containsMouse ? Theme.tertiary : Theme.surface;
                    } else {
                        return pillMouse.containsMouse ? Theme.tertiary : Theme.surface;
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                function getWorkspaceWindows(workspaceId) {
                    return NiriService.windows.filter(w => w.workspace_id === workspaceId);
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        NiriService.switchToWorkspace(workspacePill.modelData.idx);
                    }
                }

                RowLayout {
                    id: pillContent
                    anchors.centerIn: parent
                    spacing: 2

                    // Window icons (only show if workspace has windows)
                    RowLayout {
                        spacing: 2
                        visible: workspacePill.workspaceWindows.length > 0
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            model: workspacePill.workspaceWindows.slice(0, 4)

                            delegate: AppIcon {
                                required property var modelData
                                required property int index
                                size: 14
                                icon: modelData.app_id || modelData.title || modelData.app_id || "App"

                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
