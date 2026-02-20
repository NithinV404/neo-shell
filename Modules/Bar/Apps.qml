import QtQuick
import QtQuick.Layouts
import qs.Components
import qs.Services

Rectangle {
    id: root

    property string screenName: ""

    implicitWidth: windowsRow.implicitWidth + 12
    implicitHeight: parent.height * 0.75
    color: Theme.surfaceContainer
    radius: 24
    Layout.alignment: Qt.AlignVCenter

    visible: groupedApps.length > 0

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutBack
        }
    }

    readonly property int activeWorkspaceId: {
        const workspaces = NiriService.allWorkspaces;
        for (let i = 0; i < workspaces.length; i++) {
            const ws = workspaces[i];
            if (ws.output === root.screenName && ws.is_active)
                return ws.id;
        }
        return -1;
    }

    // Group windows by app_id
    readonly property var groupedApps: {
        const allWindows = NiriService.windows;
        const wsId = root.activeWorkspaceId;

        if (wsId === -1 || allWindows.length === 0)
            return [];

        const groups = {};
        const order = [];

        for (let i = 0; i < allWindows.length; i++) {
            const w = allWindows[i];
            if (w.workspace_id !== wsId)
                continue;

            const appId = w.app_id || w.title || "unknown";

            if (!groups[appId]) {
                groups[appId] = {
                    appId: appId,
                    windows: [],
                    hasAnyFocused: false
                };
                order.push(appId);
            }

            groups[appId].windows.push(w);

            if (w.is_focused)
                groups[appId].hasAnyFocused = true;
        }

        return order.map(id => groups[id]);
    }

    RowLayout {
        id: windowsRow
        anchors.centerIn: parent

        Repeater {
            model: root.groupedApps

            delegate: Item {
                id: appDelegate

                required property var modelData
                required property int index

                readonly property string appId: modelData.appId
                readonly property var windows: modelData.windows
                readonly property int windowCount: windows.length
                readonly property bool hasMultiple: windowCount > 1
                readonly property bool isAnyFocused: modelData.hasAnyFocused

                implicitWidth: 20
                implicitHeight: 20
                Layout.alignment: Qt.AlignVCenter

                // Hover highlight
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Theme.surfaceContainerHighest
                    opacity: iconMouse.containsMouse ? 0.8 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                AppIcon {
                    anchors.centerIn: parent
                    size: 18
                    icon: appDelegate.appId
                    // Always highlighted if any instance is focused
                    opacity: appDelegate.isAnyFocused ? 1.0 : 0.6

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // Indicator: dot for single, line for multiple
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -2
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: appDelegate.isAnyFocused
                    width: appDelegate.hasMultiple ? 12 : 5
                    height: appDelegate.hasMultiple ? 3 : 5
                    radius: height / 2

                    color: appDelegate.isAnyFocused ? Theme.primary : Theme.onSurfaceVariant

                    Behavior on width {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        // Cycle through windows of this app
                        const wins = appDelegate.windows;

                        if (wins.length === 1) {
                            NiriService.focusWindow(wins[0].id);
                            return;
                        }

                        // Find currently focused window index
                        let focusedIdx = -1;
                        for (let i = 0; i < wins.length; i++) {
                            if (wins[i].is_focused) {
                                focusedIdx = i;
                                break;
                            }
                        }

                        // Focus next window in cycle
                        const nextIdx = (focusedIdx + 1) % wins.length;
                        NiriService.focusWindow(wins[nextIdx].id);
                    }
                }
            }
        }
    }
}
