// components/Bar.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Modules
import qs.Modules.Bar
import qs.Modules.Bar.Panels
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
                width: centerLayout.width
                height: centerLayout.height
                color: hoverHandler.hovered ? Theme.tertiaryContainer : Theme.surfaceContainer
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

                HoverHandler {
                    id: hoverHandler
                }
                RowLayout {
                    id: centerLayout
                    Clock {
                        id: clock
                        screen: bar.modelData
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                    }

                    Battery {
                        id: battery
                        screen: bar.modelData
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: 4
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

            BackgroundApps {
                id: backgroundApps
                anchors.verticalCenter: parent.verticalCenter
            }
            QuickControls {
                id: quickControls
                screen: bar.modelData
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
