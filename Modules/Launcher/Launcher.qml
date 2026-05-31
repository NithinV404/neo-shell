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
    focusable: true

    property ListModel apps: AppService.applications

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
        repeat: false
        onTriggered: {
            if (!root.isVisible) {
                root.visible = false;
            }
        }
    }

    vAlign: "bottom"
    hAlign: "center"

    property bool enableShadow: false

    // Track selected item
    property int selectedIndex: 0

    // View mode: "list" or "grid"
    property string viewMode: Settings.launcherViewMode

    // Grid columns
    readonly property int gridColumns: 4
    readonly property int gridCellSize: 96
    readonly property int gridCellPadding: 8

    // Search query
    property string searchQuery: ""

    onSearchQueryChanged: {
        AppService.searchApplications(searchQuery);
    }

    content: Rectangle {
        id: launcherContainer
        property real targetHeight: appColumn.implicitHeight
        property real targetWidth: appColumn.implicitWidth
        clip: true
        anchors.bottom: parent.bottom

        width: appColumn.implicitWidth
        height: root.isVisible ? appColumn.implicitHeight : 0
        scale: root.isVisible ? 1 : 0.8
        radius: Settings.radius
        color: Theme.surface
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

        // Reset selection when apps list changes
        Connections {
            target: AppService
            function onApplicationsUpdated() {
                root.selectedIndex = 0;
            }
        }

        function launchApp(app) {
            AppService.launchApp(app);
            root.close();
        }

        function launchSelected() {
            if (root.apps.count > 0 && selectedIndex >= 0 && selectedIndex < root.apps.count) {
                AppService.launchApp(root.apps.get(selectedIndex));
            }
            root.close();
        }

        function moveSelectionUp() {
            if (viewMode === "list") {
                if (root.selectedIndex > 0) {
                    root.selectedIndex--;
                    appList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                }
            } else {
                if (root.selectedIndex >= root.gridColumns) {
                    root.selectedIndex -= root.gridColumns;
                    appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                }
            }
        }

        function moveSelectionDown() {
            if (viewMode === "list") {
                if (root.selectedIndex < root.apps.count - 1) {
                    root.selectedIndex++;
                    appList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                }
            } else {
                if (root.selectedIndex + root.gridColumns < root.apps.count) {
                    root.selectedIndex += root.gridColumns;
                    appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
                }
            }
        }

        function moveSelectionLeft() {
            if (viewMode === "grid" && root.selectedIndex > 0) {
                root.selectedIndex--;
                appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
            }
        }

        function moveSelectionRight() {
            if (viewMode === "grid" && root.selectedIndex < root.apps.count - 1) {
                root.selectedIndex++;
                appGrid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
            }
        }

        Item {
            id: keybinds
            Keys.onUpPressed: moveSelectionUp()
            Keys.onDownPressed: moveSelectionDown()
            Keys.onLeftPressed: moveSelectionLeft()
            Keys.onRightPressed: moveSelectionRight()
            Keys.onReturnPressed: launchSelected()
            Keys.onEnterPressed: launchSelected()
            Keys.onEscapePressed: root.close()
            Keys.forwardTo: [searchContainer]
        }

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

        Behavior on width {
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
                        text: `${root.apps.count} apps`
                        font.pixelSize: 12
                        font.family: Settings.fontFamily
                        color: Theme.surfaceVariantFg
                    }

                    // View mode toggle
                    Rectangle {
                        width: 64
                        height: 28
                        radius: 8
                        color: Theme.surfaceContainer

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 3
                            spacing: 2

                            // List button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: root.viewMode === "list" ? Theme.surfaceContainerHighest : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    name: "list"
                                    size: 14
                                    color: root.viewMode === "list" ? Theme.primary : Theme.surfaceVariantFg
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.setLauncherView("list");
                                        root.selectedIndex = 0;
                                    }
                                }
                            }

                            // Grid button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 6
                                color: root.viewMode === "grid" ? Theme.surfaceContainerHighest : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    name: "grid_view"
                                    size: 14
                                    color: root.viewMode === "grid" ? Theme.primary : Theme.surfaceVariantFg
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.setLauncherView("grid");
                                        root.selectedIndex = 0;
                                    }
                                }
                            }
                        }
                    }
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

            // ── LIST VIEW ──────────────────────────────────────────────
            ListView {
                id: appList
                visible: root.viewMode === "list"
                implicitHeight: root.viewMode === "list" ? Math.min(appList.contentHeight, 450) : 0
                implicitWidth: 450
                Layout.fillWidth: true
                Layout.margins: 8
                model: root.apps
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
                        alwaysRunToEnd: true
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 300
                        easing.type: Easing.InCubic
                        alwaysRunToEnd: true
                    }
                }
                move: Transition {
                    NumberAnimation {
                        property: "opacity"
                        duration: 250
                        easing.type: Easing.OutCubic
                        alwaysRunToEnd: true
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        property: "opacity"
                        duration: 250
                        easing.type: Easing.OutCubic
                        alwaysRunToEnd: true
                    }
                }
                populate: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 400
                        easing.type: Easing.OutCubic
                        alwaysRunToEnd: true
                    }
                }

                delegate: Rectangle {
                    id: listDelegateWrapper
                    required property var modelData
                    required property int index
                    property bool isSelected: index === root.selectedIndex
                    property bool isHovered: listDelegateMouse.containsMouse
                    property bool isFirst: index === 0
                    property bool isLast: index === root.apps.count - 1

                    opacity: 1
                    width: appList.width
                    height: 56
                    topLeftRadius: isSelected || isFirst ? Settings.radius : 8
                    topRightRadius: isSelected || isFirst ? Settings.radius : 8
                    bottomLeftRadius: isSelected || isLast ? Settings.radius : 8
                    bottomRightRadius: isSelected || isLast ? Settings.radius : 8

                    Component.onCompleted: {
                        if (opacity < 1)
                            console.info(opacity);
                        fadeInAnimList.start();
                    }

                    NumberAnimation {
                        id: fadeInAnimList
                        target: listDelegateWrapper
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 350
                        easing.type: Easing.OutCubic
                    }

                    Behavior on topLeftRadius {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on topRightRadius {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on bottomLeftRadius {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on bottomRightRadius {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }

                    color: isSelected ? Theme.surfaceContainerHighest : isHovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer

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
                            icon: modelData.icon
                            name: modelData.name
                            size: 40
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: modelData.name ?? ""
                                font.pixelSize: 14
                                font.family: Settings.fontFamily
                                font.weight: isSelected ? Font.Medium : Font.Normal
                                color: Theme.surfaceFg
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                visible: modelData.comment
                                text: modelData.comment ?? ""
                                font.pixelSize: 11
                                font.family: Settings.fontFamily
                                color: Theme.surfaceVariantFg
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        id: listDelegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launchApp(modelData)
                        onEntered: root.selectedIndex = index
                    }
                }
            }

            // ── GRID VIEW ──────────────────────────────────────────────
            GridView {
                id: appGrid
                visible: root.viewMode === "grid"
                implicitWidth: 550
                implicitHeight: root.viewMode === "grid" ? Math.min(appGrid.contentHeight, 450) : 0
                Layout.fillWidth: true
                Layout.margins: 8
                clip: true
                model: root.apps
                opacity: 1
                cellWidth: (appGrid.width) / root.gridColumns
                cellHeight: root.gridCellSize + root.gridCellPadding
                flickDeceleration: 900
                maximumFlickVelocity: 2000
                boundsBehavior: Flickable.OvershootBounds
                currentIndex: root.selectedIndex

                add: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 200
                        easing.type: Easing.InCubic
                    }
                }
                move: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                populate: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                delegate: Item {
                    id: gridDelegateWrapper
                    required property var modelData
                    required property int index
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    Component.onCompleted: {
                        fadeInAnimGrid.start();
                    }

                    NumberAnimation {
                        id: fadeInAnimGrid
                        target: gridDelegateWrapper
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 350
                        easing.type: Easing.OutCubic
                    }

                    Rectangle {
                        id: gridDelegate
                        property bool isSelected: gridDelegateWrapper.index === root.selectedIndex
                        property bool isHovered: gridDelegateMouse.containsMouse

                        anchors.fill: parent
                        anchors.margins: root.gridCellPadding / 2
                        radius: (isSelected || isHovered) ? Settings.radius : 8

                        color: isSelected ? Theme.surfaceContainerHighest : isHovered ? Theme.surfaceContainerHigh : Theme.surfaceContainer

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                                easing.type: Easing.OutQuad
                            }
                        }

                        Behavior on radius {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutCubic
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            AppIcon {
                                icon: gridDelegateWrapper.modelData.icon
                                name: gridDelegateWrapper.modelData.name
                                size: 52
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: gridDelegateWrapper.modelData.name ?? ""
                                font.pixelSize: 12
                                font.family: Settings.fontFamily
                                font.weight: 500
                                color: Theme.surfaceFg
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                width: appGrid.cellWidth - root.gridCellPadding * 2 - 8
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: gridDelegateMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launchApp(gridDelegateWrapper.modelData)
                            onEntered: root.selectedIndex = gridDelegateWrapper.index
                        }
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
                Layout.bottomMargin: 8

                InputField {
                    id: searchField
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: 48
                    password: false
                    text: root.searchQuery

                    onTextChanged: {
                        root.searchQuery = text;
                        root.selectedIndex = 0;
                    }

                    Keys.forwardTo: [keybinds]
                }

                Timer {
                    running: root.visible
                    interval: 50
                    onTriggered: searchField.setFocus()
                }
            }
        }
    }
}
