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
import qs.Components

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
    WlrLayershell.namespace: "quickshell:quickmenu"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        anchors.centerIn: parent
        color: Theme.surface
        radius: 24

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // Use a single RowLayout for everything
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 4

            Workspaces {
                Layout.alignment: Qt.AlignVCenter
                screenName: bar.modelData?.name ?? ""
            }

            Apps {
                Layout.alignment: Qt.AlignVCenter
                screenName: bar.modelData?.name ?? ""
            }

            Item {
                Layout.fillWidth: true
            }

            Clock {
                anchors.centerIn: parent
            }

            Item {
                Layout.fillWidth: true
            }

            BackgroundApps {
                Layout.alignment: Qt.AlignVCenter
            }

            QuickControls {
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
