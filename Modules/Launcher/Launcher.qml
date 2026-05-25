import qs.Services
import qs.Common
import qs.Widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Services.UI

Popout {
    id: root
    visible: root.visible
    screen: root.screen
    focusable: true

    Component.onCompleted: {
        openAnimationTimer.running = true;
    }

    onIsVisibleChanged: {
        if (!root.isVisible) {
            root.enableShadow = false;
            closeAnimationTimer.running = true;
        }
    }

    Timer {
        id: openAnimationTimer
        interval: root.animationDuration
        running: false
        onTriggered: {
            root.enableShadow = true;
        }
    }

    Timer {
        id: closeAnimationTimer
        interval: root.animationDuration
        onTriggered: {
            if (!root.isVisible) {
                root.visible = false;
            }
        }
    }

    property bool enableShadow: false

    // Track selected item
    property int selectedIndex: 0

    // Search Index

    // Search query
    property string searchQuery: ""

    // Search
    onSearchQueryChanged: {
        AppService.searchApplications(searchQuery);
    }

    // Reset selection when apps list changes
    Connections {
        target: AppService
        function applicationsChanged() {
            root.selectedIndex = 0;
        }
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
        AppService.launchApp(app);
        root.close();
    }

    function launchSelected() {
        if (AppService.applications.count > 0 && selectedIndex >= 0 && selectedIndex < AppService.applications.count) {
            AppService.launchApp(AppService.applications.get(selectedIndex));
        }
        root.close();
    }

    function moveSelectionUp() {
        if (root.selectedIndex > 0) {
            root.selectedIndex--;
            appList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    function moveSelectionDown() {
        if (root.selectedIndex < AppService.applications.count - 1) {
            root.selectedIndex++;
            appList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    Item {
        id: keybinds
        Keys.onUpPressed: root.moveSelectionUp()
        Keys.onDownPressed: root.moveSelectionDown()
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
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        //anchors.topMargin: (parent.height - 600) / 2
        //anchors.horizontalCenter: parent.horizontalCenter
        width: 450
        height: root.isVisible ? appColumn.implicitHeight : 0
        scale: root.isVisible ? 1 : 0.8
        radius: Settings.radius
        color: Theme.surface
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        Behavior on height {
            SequentialAnimation {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutQuad
                }
            }
        }

        ColumnLayout {
            id: appColumn
            width: parent.width
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
                        text: `${AppService.applications.count} apps`
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
                    text: root.searchQuery

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
                Layout.preferredHeight: Math.min(appList.contentHeight, 450)
                Layout.fillWidth: true
                Layout.margins: 8
                model: AppService.applications
                clip: true
                spacing: 4
                flickDeceleration: 900
                maximumFlickVelocity: 2000
                boundsBehavior: Flickable.OvershootBounds
                currentIndex: root.selectedIndex

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 300
                        easing.type: Easing.InCubic
                    }
                }

                move: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        property: "y"
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                populate: Transition {

                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 400
                        easing.type: Easing.OutCubic
                    }
                }

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
            }
        }
    }
}
