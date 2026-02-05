// Workspaces.qml
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Components
import qs.Services
import Quickshell

Rectangle {
    id: root
    implicitWidth: workspaceRow.implicitWidth + 16
    implicitHeight: parent.height * 0.75
    color: Theme.surfaceContainerHighest
    radius: 12
    border.width: 1
    border.color: Qt.darker(Theme.outline)

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
                implicitWidth: workspacePill.workspaceWindows.length > 0 ? pillContent.implicitWidth + 10 : pillContent.implicitWidth + 20
                implicitHeight: 20
                radius: 8

                color: {
                    if (isFocused) {
                        return pillMouse.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary;
                    } else if (isActive) {
                        return pillMouse.containsMouse ? Theme.tertiary : Theme.secondaryContainer;
                    } else {
                        return pillMouse.containsMouse ? Theme.tertiary : Theme.secondary;
                    }
                }

                border.width: isFocused ? 0 : 1
                border.color: isActive ? Theme.outline : Qt.darker(Theme.outline)

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 150
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
                                icon: ({
                                        icon: modelData.app_id || "",
                                        name: modelData.title || modelData.app_id || "App"
                                    })
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
