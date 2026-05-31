// components/Bar.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Modals
import qs.Modules.Bar
import qs.Widgets
import qs.Modules.Launcher
import qs.Modules.Bar.ControlCenterPanel
import qs.Modules.Bar.WallpaperPanel
import qs.Services.UI
import qs.Services
import qs.Common
import Quickshell.Wayland

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData
    anchors {
        top: true
        left: true
        right: true
        bottom: false
    }

    margins {
        top: 2
        bottom: 0
        left: 4
        right: 4
    }

    color: "transparent"

    implicitHeight: 40
    Component.onCompleted: {
        if (this.WlrLayershell != null) {
            this.WlrLayershell.layer = WlrLayer.Top;
            this.WlrLayershell.namespace = "neoshell:bar";
            this.exclusionMode = ExclusionMode.Auto;
        }
    }

    WlrLayershell.exclusionMode: ExclusionMode.Auto

    BackgroundEffect.blurRegion: Region {
        item: barContainer
        radius: Settings.radius
    }

    function openPanel(panel, parent, alignment, verticalMargin) {
        if (panel.active && panel.item && panel.item.visible) {
            panel.item.close();
            return;
        }

        panel.active = true;
        var pos = parent.mapToGlobal(0, 0);

        panel.item.openAt(alignment === "center" ? pos.x + (parent.width / 2) : alignment === "right" ? pos.x + parent.width : pos.x // default (left)
        , pos.y + parent.height + verticalMargin);
    }

    function closePanel(panel) {
        if (panel.active) {
            panel.item.close();
            return;
        }

        return;
    }

    Rectangle {
        id: barContainer
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, Settings.blurEnabled ? Settings.blurOpacity : 1)
        radius: Settings.radius
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4
            spacing: 4

            Apps {
                id: apps
                screenName: bar.modelData?.name ?? ""
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 4
            z: 2
            Workspaces {
                id: workspaces
                screenName: bar.modelData?.name ?? ""
            }
            Rectangle {
                id: centerRect
                width: centerLayout.width
                height: centerLayout.height
                color: centerRectMouse.containsMouse ? Qt.alpha(Theme.tertiaryContainer, Settings.blurEnabled ? Settings.blurOpacity : 1) : Qt.alpha(Theme.surfaceContainer, Settings.blurEnabled ? Settings.blurOpacity : 1)
                radius: Settings.radius

                Behavior on color {
                    ColorAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutBack
                    }
                }

                RowLayout {
                    id: centerLayout
                    Clock {
                        id: clock
                        screen: bar.modelData
                        hovered: centerRectMouse.containsMouse
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                    }

                    Battery {
                        id: battery
                        screen: bar.modelData
                        hovered: centerRectMouse.containsMouse
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 4
                    }
                }
                MouseArea {
                    id: centerRectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            bar.openPanel(wallpaperPanel, centerRect, "center", 8);
                        }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 4
            spacing: 4
            height: parent.height

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: backgroundApps.visible ? backgroundApps.width : 0
                height: backgroundApps.height
                color: Qt.alpha(Theme.surfaceContainer, Settings.blurEnabled ? Settings.blurOpacity : 1)
                radius: Settings.radius
                SystemTray {
                    id: backgroundApps
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }
            }
            QuickControls {
                id: quickControls
                screen: bar.modelData
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    id: quickControlsPanel
                    anchors.fill: quickControls
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            bar.openPanel(controlCenterPanel, quickControls, "left", 8);
                        }
                    }
                }
            }
        }
    }

    LazyLoader {
        id: controlCenterPanel
        active: false
        ControlCenterPanel {
            screen: bar.modelData
            onMenuClosed: {
                controlCenterPanel.active = false;
            }
        }
    }

    LazyLoader {
        id: wallpaperPanel
        active: false
        WallpaperPanel {
            screen: bar.modelData
            onMenuClosed: {
                wallpaperPanel.active = false;
            }
        }
    }

    Connections {
        target: OSDService

        function onOpen(osdType) {
            osdLoader.active = true;
            osdLoader.item.open(osdType);
        }
    }

    LazyLoader {
        id: osdLoader
        active: false
        OSD {
            id: osdPanel
            screen: bar.modelData
            onMenuClosed: {
                osdLoader.active = false;
            }
        }
    }

    PowerMenu {}

    // App Launcher
    Scope {
        id: launcherScope
        Connections {
            target: LauncherService

            function onToggle() {
                launcherPanel.active = true;
                launcherPanel.item?.openAt((bar.modelData.width / 2) - (launcherPanel.item.panelWidth / 2), bar.modelData.height);
            }

            function onOpen() {
                launcherPanel.active = true;
                launcherPanel.item?.openAt(bar.modelData.width / 2, bar.modelData.height / 2);
            }

            function onClose() {
                launcherPanel.active = true;
                launcherPanel.item?.close();
            }
        }
    }
    LazyLoader {
        id: launcherPanel
        Launcher {
            screen: bar.modelData
            onMenuClosed: {
                launcherPanel.active = false;
            }
        }
    }

    // Polkit
    Polkit {}
}
