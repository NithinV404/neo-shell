import qs.Services
import qs.Common
import qs.Components
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    IpcHandler {
        target: "launcher"

        function toggleLauncher() {
            root.toggle();
        }

        function showLauncher() {
            root.open();
        }

        function hideLauncher() {
            root.close();
        }
    }

    property bool showLauncher: false
    property bool showContainer: false
    property int selectedIndex: 0  // Track selected item

    // All apps from service
    readonly property var allApps: AppService.applications

    // Search query
    property string searchQuery: ""

    // Filtered apps - computed locally
    readonly property var apps: {
        if (!searchQuery || searchQuery.trim().length === 0) {
            return allApps;
        }
        return AppService.searchApplications(searchQuery);
    }

    // Reset selection when apps list changes
    onAppsChanged: {
        selectedIndex = 0;
    }

    function open() {
        searchQuery = "";
        selectedIndex = 0;  // Reset selection
        root.showLauncher = true;
        openTimer.start();
    }

    function close() {
        root.showContainer = false;
        closeTimer.start();
    }

    function toggle() {
        root.showLauncher ? root.close() : root.open();
    }

    function launchApp(app) {
        app.execute();
        close();
    }

    function launchSelected() {
        if (root.apps.length > 0 && selectedIndex >= 0 && selectedIndex < root.apps.length) {
            launchApp(root.apps[selectedIndex]);
        }
    }

    Timer {
        id: openTimer
        interval: 10
        onTriggered: root.showContainer = true
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: {
            root.showLauncher = false;
            searchQuery = "";
            selectedIndex = 0;
        }
    }

    LazyLoader {
        id: appLauncherLoader
        active: root.showLauncher

        PanelWindow {
            id: launcherWindow
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            anchors.top: true
            color: "transparent"

            function moveSelectionUp() {
                if (root.selectedIndex > 0) {
                    root.selectedIndex--;
                    appList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                }
            }

            function moveSelectionDown() {
                if (root.selectedIndex < root.apps.length - 1) {
                    root.selectedIndex++;
                    appList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                }
            }

            // Keyboard navigation
            Keys.onUpPressed: moveSelectionUp()
            Keys.onDownPressed: moveSelectionDown()
            Keys.onReturnPressed: root.launchSelected()
            Keys.onEnterPressed: root.launchSelected()
            Keys.onEscapePressed: root.close()

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    const p = mapToItem(launcherContainer, mouse.x, mouse.y);
                    const inside = p.x >= 0 && p.x <= launcherContainer.width && p.y >= 0 && p.y <= launcherContainer.height;
                    if (!inside)
                        root.close();
                }
            }

            Rectangle {
                id: launcherContainer
                anchors.centerIn: parent
                width: 450
                height: root.showContainer ? 600 : 0
                radius: 16
                color: Theme.surface
                clip: true

                opacity: root.showContainer ? 1 : 0
                scale: root.showContainer ? 1 : 0.94

                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
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

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Header
                    Rectangle {
                        id: header
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            StyledText {
                                name: "apps"
                                font.pixelSize: 20
                                color: Theme.primary
                            }

                            Text {
                                text: "Applications"
                                font.pixelSize: 16
                                font.family: Settings.fontFamily
                                font.weight: Font.Medium
                                color: Theme.surfaceFg
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: `${root.apps.length} apps`
                                font.pixelSize: 12
                                font.family: Settings.fontFamily
                                color: Theme.surfaceVariantFg
                            }
                        }
                    }

                    // Search field
                    Item {
                        id: searchContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: searchField.implicitHeight
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8

                        TextField {
                            id: searchField
                            anchors.left: parent.left
                            anchors.right: parent.right
                            password: false
                            onTextChanged: {
                                root.searchQuery = text;
                                root.selectedIndex = 0;  // Reset to first on search
                            }

                            // Forward navigation keys to window
                            Keys.onUpPressed: moveSelectionUp()
                            Keys.onDownPressed: moveSelectionDown()
                            Keys.onReturnPressed: root.launchSelected()
                            Keys.onEnterPressed: root.launchSelected()
                            Keys.onEscapePressed: root.close()
                        }

                        Timer {
                            running: root.showContainer
                            interval: 50
                            onTriggered: searchField.setFocus()
                        }
                    }

                    // Divider
                    Rectangle {
                        id: divider
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 8
                        color: Theme.outlineVariant
                    }

                    // App list
                    ListView {
                        id: appList
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.margins: 8

                        model: root.apps
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        currentIndex: root.selectedIndex  // Sync with selection

                        delegate: Rectangle {
                            id: appDelegate
                            required property var modelData
                            required property int index

                            width: appList.width
                            height: 56
                            radius: 12

                            // Highlight if selected OR hovered
                            readonly property bool isSelected: index === root.selectedIndex
                            readonly property bool isHovered: delegateMouse.containsMouse

                            color: isSelected ? Theme.surfaceContainerHighest : isHovered ? Theme.surfaceContainerHigh : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                AppIcon {
                                    icon: appDelegate.modelData
                                    size: 40
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 40
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: appDelegate.modelData.name ?? ""
                                        font.pixelSize: 14
                                        font.family: Settings.fontFamily
                                        font.weight: appDelegate.isSelected ? Font.Medium : Font.Normal
                                        color: Theme.surfaceFg
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Text {
                                        visible: appDelegate.modelData.comment
                                        text: appDelegate.modelData.comment ?? ""
                                        font.pixelSize: 11
                                        font.family: Settings.fontFamily
                                        color: Theme.surfaceVariantFg
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }

                            MouseArea {
                                id: delegateMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launchApp(appDelegate.modelData)
                                onEntered: root.selectedIndex = appDelegate.index  // Update selection on hover
                            }
                        }

                        // Empty state
                        Text {
                            anchors.centerIn: parent
                            visible: root.apps.length === 0
                            text: root.searchQuery ? "No matching applications" : "No applications found"
                            font.pixelSize: 14
                            font.family: Settings.fontFamily
                            color: Theme.surfaceVariantFg
                        }
                    }
                }
            }
        }
    }
}
