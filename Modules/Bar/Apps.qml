import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Services
import qs.Common

Rectangle {
    id: root

    property string screenName: ""

    implicitWidth: windowsRow.implicitWidth + 10
    implicitHeight: 28
    color: Theme.surfaceContainer
    radius: Settings.radius
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
        spacing: 2

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

                // Fixed: Make delegate a perfect square with room for indicator
                implicitWidth: 20
                implicitHeight: 20
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter


                // Container for icon + indicator to keep them centered together
                Item {
                    anchors.centerIn: parent
                    width: icon.size
                    height: icon.size

                    AppIcon {
                        id: icon
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        size: 16
                        icon: appDelegate.appId

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -1
                        visible: appDelegate.isAnyFocused
                        width: appDelegate.hasMultiple ? 12 : 4
                        height: 4
                        z: 1
                        radius: Settings.radius
                        color: appDelegate.isAnyFocused ? Theme.primary : Theme.surfaceVariant

                        Behavior on width {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 220
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
                        const wins = appDelegate.windows;

                        if (wins.length === 1) {
                            NiriService.focusWindow(wins[0].id);
                            return;
                        }

                        let focusedIdx = -1;
                        for (let i = 0; i < wins.length; i++) {
                            if (wins[i].is_focused) {
                                focusedIdx = i;
                                break;
                            }
                        }

                        const nextIdx = (focusedIdx + 1) % wins.length;
                        NiriService.focusWindow(wins[nextIdx].id);
                    }
                }
            }
        }
    }
}
