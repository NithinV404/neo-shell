import QtQuick.Layouts
import QtQuick
import qs.Services
import qs.Components

Rectangle {
    id: root

    property var activePanel: null
    readonly property int iconSize: 16
    implicitWidth: layout.implicitWidth + 18
    implicitHeight: parent.height * 0.75
    Layout.alignment: Qt.AlignRight
    color: quickControlsPanel.containsMouse ? Theme.tertiaryContainer : Theme.secondaryContainer
    // border.width: 1
    // border.color: Qt.darker(Theme.outline)

    radius: 24
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

    function openPanel() {
        if (root.activePanel === null) {
            panel.active = true;
            activePanel = panel.item;
        } else {
            closePanel();
        }
    }

    function closePanel() {
        if (root.activePanel !== null) {
            root.activePanel.close();
        }
        return;
    }

    MouseArea {
        id: quickControlsPanel
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && root.activePanel == null) {
                root.openPanel();
            } else {
                root.closePanel();
            }
        }
    }

    RowLayout {
        id: layout
        spacing: 2
        anchors.centerIn: parent

        // --- ICON - 1: Ethernet ---
        StyledText {
            name: {
                var ns = NetworkService;
                if (ns.ethernetConnected) {
                    return "lan";
                }
                if (ns.wifiEnabled && !ns.wifiConnected) {
                    return "signal_wifi_bad";
                }
                if (ns.wifiEnabled && ns.wifiConnected) {
                    return ns.wifiSingalIcon;
                }

                return "signal_disconnected";
            }
            size: root.iconSize

            // Use "on_primary_container" so it is visible against the background
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.secondaryContainerFg
        }
        StyledText {
            visible: BluetoothService.enabled
            name: BluetoothService.connectedDevices.length > 0 ? "bluetooth_connected" : "bluetooth"
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.secondaryContainerFg
            size: root.iconSize
        }
        StyledText {
            name: AudioService.getOutputIcon()
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.secondaryContainerFg
            size: root.iconSize
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: AudioService.toggleMute()
            }
        }
        StyledText {
            name: AudioService.getInputIcon()
            color: quickControlsPanel.containsMouse ? Theme.tertiaryContainerFg : Theme.secondaryContainerFg
            size: root.iconSize
            MouseArea {
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                onClicked: AudioService.toggleMicMute()
            }
        }
    }
    Loader {
        id: panel
        active: false
        sourceComponent: QuickControlsPanel {
            onMenuClosed: {
                panel.active = false;
                root.activePanel = null;
            }
        }
        onLoaded: {
            var getLocalPos = root.mapToItem(null, 0, 0);
            item.openAt(getLocalPos.x + (root.width / 2), getLocalPos.y);
        }
    }
}
