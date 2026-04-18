import qs.Services
import qs.Common
import qs.Widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Services.UI

Scope {
    id: root

    Connections {
        target: LauncherService

        function onToggle() {
            root.toggle();
        }

        function onOpen() {
            root.open();
        }

        function onClose() {
            root.close();
        }
    }

    property bool visible: false

    // Track selected item
    property int selectedIndex: 0

    // All apps from service
    property var apps: AppService.applications

    // Search Index
    property bool isVisible: false

    // Search query
    property string searchQuery: ""

    // Search
    onSearchQueryChanged: {
        root.apps = searchQuery.trim().length > 0 ? AppService.searchApplications(searchQuery) : AppService.applications;
    }

    // Reset selection when apps list changes
    onAppsChanged: {
        selectedIndex = 0;
    }

    function open() {
        searchQuery = "";
        selectedIndex = 0;  // Reset selection
        root.visible = true;
        Utils.timer(30, () => root.isVisible = true, root);
    }

    function close() {
        root.isVisible = false;
    }

    function toggle() {
        root.visible ? root.close() : root.open();
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

    LazyLoader {
        id: appLauncherLoader
        active: root.visible

        PanelWindow {
            id: launcherWindow
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            anchors.bottom: true
            anchors.right: true
            anchors.left: true
            anchors.top: true
            visible: root.visible
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

            Item {
                id: keybinds
                Keys.onUpPressed: launcherWindow.moveSelectionUp()
                Keys.onDownPressed: launcherWindow.moveSelectionDown()
                Keys.onReturnPressed: root.launchSelected()
                Keys.onEnterPressed: root.launchSelected()
                Keys.onEscapePressed: root.close()
                Keys.forwardTo: [searchContainer]
            }

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
                anchors.top: parent.top
                anchors.left: parent.left
                //anchors.topMargin: (parent.height - 600) / 2
                //anchors.horizontalCenter: parent.horizontalCenter
                width: 450
                height: root.isVisible ? 600 : 0
                opacity: root.isVisible ? 1 : 0
                radius: Settings.radius
                color: Theme.surface
                border.width: 1
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 8
                    radius: 18
                    samples: 49
                    color: Qt.rgba(0, 0, 0, 0.35)
                    transparentBorder: true
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on height {
                    SequentialAnimation {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                        ScriptAction {
                            script: {
                                if (!root.isVisible) {
                                    root.visible = false;
                                }
                            }
                        }
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
                                size: 20
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

                        InputField {
                            id: searchField
                            anchors.left: parent.left
                            anchors.right: parent.right
                            implicitHeight: 48
                            password: false

                            onTextChanged: {
                                root.searchQuery = text;
                                root.selectedIndex = 0;  // Reset to first on search
                            }

                            Keys.forwardTo: [keybinds]
                        }

                        Timer {
                            running: root.visible
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

                            color: isSelected ? Theme.surfaceContainerHighest : isHovered ? Theme.surfaceContainerHigh : Theme.surface

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                AppIcon {
                                    icon: appDelegate.modelData.icon
                                    name: appDelegate.modelData.name
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
