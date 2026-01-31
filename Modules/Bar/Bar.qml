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
import qs.Common

PanelWindow {
    id: bar

    property var modelData
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

    implicitHeight: 38
    WlrLayershell.namespace: "quickshell:quickmenu"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: Theme.getColor("surface")
        radius: 24

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // Clock - Absolutely centered
        Clock {
            anchors.centerIn: parent
        }

        // Right side items
        RowLayout {
            id: layoutItems
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // Spacer - pushes items to right
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
