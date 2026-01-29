import QtQuick.Layouts
import QtQuick
import qs.Services
import qs.Components

Rectangle {
    id: root

    property var activePanel: null
    readonly property int iconSize: 16
    implicitWidth: layout.implicitWidth + 16
    implicitHeight: parent.height - 8
    color: Theme.getColor("surface_container_highest")

    radius: 12
    clip: true

    visible: layout.implicitWidth > 0

    function openPanel() {
        var getLocalPos = root.mapToItem(null, 0, 0);
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
        spacing: 1
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 8

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
            color: Theme.getColor("on_surface")
        }
        StyledText {
            visible: BluetoothService.enabled
            name: BluetoothService.connectedDevices.length > 0 ? "bluetooth_connected" : "bluetooth"
            color: Theme.getColor("on_surface")
            size: root.iconSize
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
            item.openAt(getLocalPos.x, getLocalPos.y);
        }
    }
}
