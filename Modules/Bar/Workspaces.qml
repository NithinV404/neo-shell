// components/Workspaces.qml
import QtQuick
import QtQuick.Layouts
import qs.Services
import qs.Common

Rectangle {
    id: root

    property string screenName: ""

    // Store the sorted list of workspaces for this screen
    property var currentWsList: NiriService.allWorkspaces.filter(ws => ws.output === root.screenName).sort((a, b) => a.idx - b.idx)

    // Track the currently active delegate item for the slider indicator
    property Item activeItem: null

    // Pre-compute which workspaces have windows (for performance)
    readonly property var workspacesWithApps: {
        const map = {};
        for (const w of NiriService.windows) {
            map[w.workspace_id] = true;
        }
        return map;
    }

    width: workspaceRow.implicitWidth + 8
    height: 28
    color: Theme.surfaceContainer
    radius: Settings.radius

    Behavior on width {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutBack
        }
    }

    // Sliding indicator (moves to active workspace)
    Rectangle {
        id: slidingIndicator
        z: 2
        x: root.activeItem ? (workspaceRow.x + root.activeItem.x + (root.activeItem.width - width) / 2) : 0
        y: (root.height - height) / 2  // Center vertically in root

        width: root.height * 0.6 
        height: root.height * 0.6 
        radius: Settings.radius
        color: Theme.primary

        Rectangle {
            width: 4
            height: 4
            radius: 2
            anchors.centerIn: parent
            color: Theme.primaryFg

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
            }
        }
    }

    // Workspace dots row
    RowLayout {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.currentWsList

            delegate: Item {
                id: delegateItem

                required property var modelData
                required property int index

                readonly property bool isFocused: modelData.is_focused
                readonly property int wsId: modelData.id

                // ✅ Does this workspace have any windows?
                readonly property bool hasApps: root.workspacesWithApps[wsId] === true

                // Track active item for slider positioning
                onIsFocusedChanged: if (isFocused)
                    root.activeItem = delegateItem
                Component.onCompleted: if (isFocused)
                    root.activeItem = delegateItem

                implicitWidth: root.height * 0.6 
                implicitHeight: root.height * 0.6 

                Layout.leftMargin: isFocused ? 2 : 0
                Layout.rightMargin: isFocused ? 2 : 0

                Behavior on Layout.leftMargin {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on Layout.rightMargin {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                // ✅ Check if neighbors have apps (for connector logic)
                readonly property bool prevHasApps: index > 0 ? root.workspacesWithApps[root.currentWsList[index - 1].id] === true : false
                readonly property bool nextHasApps: index < root.currentWsList.length - 1 ? root.workspacesWithApps[root.currentWsList[index + 1].id] === true : false

                // ✅ Only connect if: not focused + neighbor not focused + neighbor HAS apps
                readonly property bool prevIsInactive: index > 0 && !root.currentWsList[index - 1].is_focused && prevHasApps
                readonly property bool nextIsInactive: index < root.currentWsList.length - 1 && !root.currentWsList[index + 1].is_focused && nextHasApps

                // Radius logic: 0 = flat edge (connects), 12 = rounded edge (gap)
                readonly property int rLeft: (!isFocused && prevIsInactive) ? 0 : 12
                readonly property int rRight: (!isFocused && nextIsInactive) ? 0 : 12

                // ✅ Connecting background: only visible if this workspace has apps OR is focused
                Rectangle {
                    anchors.fill: parent
                    color: Theme.surfaceContainerHigh
                    visible: delegateItem.hasApps || delegateItem.isFocused
                    opacity: visible ? (delegateItem.isFocused ? 0 : 1) : 0

                    topLeftRadius: delegateItem.rLeft
                    bottomLeftRadius: delegateItem.rLeft
                    topRightRadius: delegateItem.rRight
                    bottomRightRadius: delegateItem.rRight

                    Behavior on topLeftRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on topRightRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on bottomLeftRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on bottomRightRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                // ✅ Small dot: ALWAYS visible (even for empty workspaces)
                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    anchors.centerIn: parent

                    // Dim the dot if workspace has no apps and isn't focused
                    color: (delegateItem.isFocused || delegateItem.hasApps) ? Theme.surfaceVariantFg : Theme.outline

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                // Click to switch workspace
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriService.switchToWorkspace(delegateItem.modelData.idx)
                }
            }
        }
    }
}
