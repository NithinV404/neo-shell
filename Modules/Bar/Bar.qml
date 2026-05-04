// components/Bar.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Modules
import qs.Modules.Bar
import qs.Modules.Bar.ControlCenterPanel
import qs.Modules.Bar.WallpaperPanel
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
    // WlrLayershell.namespace: "neoshell:bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Auto

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
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
            Workspaces {
                id: workspaces
                screenName: bar.modelData?.name ?? ""
            }
            Rectangle {
                id: centerRect
                width: centerLayout.width
                height: centerLayout.height
                color: centerRectMouse.containsMouse ? Theme.tertiaryContainer : Theme.surfaceContainer
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
                        if (mouse.button === Qt.LeftButton && !wallpaperPanel.active) {
                            var pos = centerRect.mapToGlobal(0, 0);
                            wallpaperPanel.active = true;
                            wallpaperPanel.item.openAt(pos.x + (centerRect.width / 2), pos.y + centerRect.height + 8);
                        } else {
                            wallpaperPanel.item.close();
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

            Rectangle
            {
                anchors.verticalCenter: parent.verticalCenter
                width: backgroundApps.width
                height: backgroundApps.height
                color: Theme.surfaceContainer
                radius: Settings.radius
                BackgroundApps {
                    id: backgroundApps
                }

                Behavior on width
                {
                    NumberAnimation
                    {
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
                            console.info("Clicked");
                            if (!controlCenterPanel.active) {
                                var pos = quickControls.mapToGlobal(0, 0);
                                controlCenterPanel.active = true;
                                controlCenterPanel.item.openAt(pos.x + quickControls.width / 2, pos.y + quickControls.height + 8);
                            } else {
                                controlCenterPanel.item.close();
                            }
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
}
