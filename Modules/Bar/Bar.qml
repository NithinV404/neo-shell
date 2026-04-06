// components/Bar.qml

import Quickshell
import QtQuick
import qs.Modules.Bar.BackgroundApps
import qs.Modules.Bar.QuickControls
import qs.Modules.Bar
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
    }

    margins {
        top: 2
        bottom: 0
        left: 4
        right: 4
    }

    color: "transparent"

    implicitHeight: 40
    WlrLayershell.namespace: "neoshell:bar"
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
            Clock {
                id: clock
                screen: bar.modelData
                anchors.verticalCenter: parent.verticalCenter
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
            Battery {
                id: battery
                screen: bar.modelData
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
