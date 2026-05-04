import Quickshell
import QtQuick.Layouts
import QtQuick
import qs.Services
import qs.Widgets
import qs.Common
import qs.Modules
import qs.Modules.Bar

Rectangle {
    id: root

    required property var screen
    readonly property int iconSize: height * 0.6
    implicitWidth: layout.implicitWidth + 18
    implicitHeight: 28
    color: quickControlsPanel.containsMouse ? Theme.tertiaryContainer : Theme.surfaceContainer
    // border.width: 1
    // border.color: Qt.darker(Theme.outline)

    radius: Settings.radius
    clip: true

    visible: layout.implicitWidth > 0

    Behavior on implicitWidth {
        NumberAnimation {
            easing.type: Easing.OutBack
            duration: 220
        }
    }

    Behavior on color {
        ColorAnimation {
            easing.type: Easing.OutCubic
            duration: 220
        }
    }

 

    RowLayout {
        id: layout
        spacing: 2
        anchors.centerIn: parent

        // --- ICON - 1: Ethernet ---
        StyledText {
            name: {
                if (NetworkService.ethernetConnected) {
                    return "lan";
                }
                if (NetworkService.wifiEnabled && !NetworkService.wifiConnected) {
                    return "signal_wifi_bad";
                }
                if (NetworkService.wifiEnabled && NetworkService.wifiConnected) {
                    return NetworkService.getSignalInfo(NetworkService.activeWifiDetails.signal, NetworkService.activeWifiDetails.connected).icon;
                }

                return "signal_disconnected";
            }
            size: root.iconSize

            // Use "on_primary_container" so it is visible against the background
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.surfaceFg
        }
        StyledText {
            visible: BluetoothService.enabled
            name: BluetoothService.connectedDevices.length > 0 ? "bluetooth_connected" : "bluetooth"
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.surfaceFg
            size: root.iconSize
        }
        StyledText {
            name: AudioService.getOutputIcon()
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.surfaceFg
            size: root.iconSize
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: AudioService.setOutputMuted(!AudioService.muted)
            }
        }
        StyledText {
            name: AudioService.getInputIcon()
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.surfaceFg
            size: root.iconSize
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: AudioService.setInputMuted(!AudioService.inputMuted)
            }
        }
    }
    
}
