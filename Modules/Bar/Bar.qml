// components/Bar.qml
import Quickshell.Widgets
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Modules.Bar.BackgroundApps
import qs.Modules.Bar.QuickControls
import qs.Modules.Bar
import qs.Services
import Quickshell.Wayland
import qs.Widgets

PanelWindow {
    id: bar

    property var modelData
    property var barPanelsManager: null

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
    exclusionMode: ExclusionMode.Auto

    Rectangle {
        anchors.fill: parent
        anchors.centerIn: parent
        color: Theme.surface
        radius: 24
        border.width: 1
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)

        // Clock absolutely centered, independent of layout
        Clock {
            id: clock
            anchors.centerIn: parent
            z: 1
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 4

            Workspaces {
                id: workspaces
                Layout.alignment: Qt.AlignVCenter
                screenName: bar.modelData?.name ?? ""
            }

            Rectangle {
                width: 1
                radius: 12
                height: 18
                color: Theme.surfaceFg
                opacity: 0.5
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 2
                Layout.rightMargin: 2
            }

            Apps {
                id: apps
                Layout.alignment: Qt.AlignVCenter
                screenName: bar.modelData?.name ?? ""
            }

            Item {
                Layout.fillWidth: true
            }

            // No clock here anymore

            Item {
                Layout.fillWidth: true
            }

            BackgroundApps {
                id: backgroundApps
                Layout.alignment: Qt.AlignVCenter
            }

            QuickControls {
                id: quickControls
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
