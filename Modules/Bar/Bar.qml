// components/Bar.qml
import Quickshell.Widgets
import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Modules.Bar.BackgroundApps
import qs.Modules.Bar.QuickControls
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
        left: 4
        right: 4
        top: 4
        bottom: 0
    }

    color: "transparent"

    implicitHeight: 30
    WlrLayershell.namespace: "quickshell:quickmenu"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        implicitWidth: parent.width
        implicitHeight: parent.height
        color: Theme.getColor("surface_container")

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        anchors {
            leftMargin: 4
            rightMargin: 4
        }
        radius: 24
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Item {
                Layout.fillWidth: parent
            }
            // 3. The System Tray
            // Icon {
            //     name: "signal_wifi_bad"
            //     size: 18
            //     color: Theme.getColor("inverse_primary")
            // }
            BackgroundApps {}
            QuickControls {}
        }
    }
}
