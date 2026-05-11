import qs.Common
import qs.Services
import qs.Widgets
import QtQuick

Item {
    id: root
    implicitHeight: togglesGrid.height + 20
    implicitWidth: togglesGrid.width + 20

    property bool editMode: false
    property bool isReady: false

    onEditModeChanged: {
        if (!editMode) {
            Settings.setToggleOrder(togglePanel.serializeModel());
        }
    }

    Rectangle {
        id: togglePanel
        border.width: root.editMode ? 2 : 0
        anchors.fill: parent
        border.color: Theme.primary
        radius: Settings.radius
        color: Theme.surfaceContainer

        function serializeModel() {
            var order = [];
            for (let i = 0; i < quickTogglesModel.count; i++) {
                let item = quickTogglesModel.get(i);
                order.push({
                    "toggleId": item.toggleId,
                    "title": item.title,
                    "icon": item.icon,
                    "compact": item.compact,
                    "hasMenu": item.hasMenu
                });
            }
            return order;
        }

        Component.onCompleted: {
            var saved = Settings.controlCenterToggleOrder;
            if (saved && saved.length > 0) {
                quickTogglesModel.clear();
                for (let i = 0; i < saved.length; i++) {
                    let item = saved[i];
                    quickTogglesModel.append({
                        "toggleId": item.toggleId,
                        "title": item.title,
                        "icon": item.icon,
                        "compact": item.compact,
                        "hasMenu": item.hasMenu
                    });
                }
            }

            root.isReady = true;
        }

        function _getToggleStatus(toggleId) {
            switch (toggleId) {
            case "network":
                {
                    let ns = NetworkService;
                    if (ns.ethernetConnected)
                        return ns.activeEthernetDetails?.connectionName ?? "Connected";
                    if (ns.wifiEnabled && !ns.wifiConnected)
                        return "WiFi on";
                    if (ns.wifiEnabled && ns.wifiConnected)
                        return ns.activeWifiDetails?.connectionName ?? "Connected";
                    return "Offline";
                }
            case "bluetooth":
                {
                    if (!BluetoothService.adapter || !BluetoothService.adapter.devices) {
                        return null;
                    }
                    let devices = [...BluetoothService.adapter.devices.values.filter(dev => dev && (dev.paired || dev.trusted))];
                    for (let device of devices) {
                        if (device && device.connected) {
                            return device.name;
                        }
                    }
                    return null;
                }
            case "darkmode":
                return "";
            case "audio":
                return AudioService.source.nickname || AudioService.source.description || "Unknown Device";
            case "powerprofile":
                return PowerProfileService.getName(PowerProfileService.profile);
            default:
                return "";
            }
        }

        function _getToggleMenuClicked(toggleId) {
            switch (toggleId) {
            case "network":
                return quickLayoutStack.switchTo(1);
            case "bluetooth":
                return quickLayoutStack.switchTo(2);
            case "darkmode":
                return Settings.setDarkMode(!Settings.darkMode);
            case "audio":
                return quickLayoutStack.switchTo(3);
            case "powerprofile":
                return PowerProfileService.cycleProfile();
            default:
            }
        }

        function _getToggleClicked(toggleId) {
            switch (toggleId) {
            case "network":
                return NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
            case "bluetooth":
                return BluetoothService.toggleBluetooth();
            case "darkmode":
                return Settings.setDarkMode(!Settings.darkMode);
            case "audio":
                return;
            case "powerprofile":
                return PowerProfileService.cycleProfile();
            default:
            }
        }

        function _getToggleTitle(toggleId): string {
            switch (toggleId) {
            case "network":
                {
                    var name = String(NetworkService.ethernetConnected && "Ethernet" || NetworkService.wifiConnected && "Wifi" || "Ethernet");
                    return name.charAt(0).toUpperCase() + name.slice(1);
                }
            case "bluetooth":
                return "Bluetooth";
            case "darkmode":
                return "Darkmode";
            case "audio":
                return "Audio";
            case "powerprofile":
                return "Power profile";
            default:
                return "Help";
            }
        }

        function _getToggleActive(toggleId): bool {
            switch (toggleId) {
            case "network":
                return NetworkService.wifiEnabled || NetworkService.ethernetConnected;
            case "bluetooth":
                return BluetoothService.enabled;
            case "darkmode":
                return Settings.darkMode;
            case "audio":
                return Settings.source != "" || Settings.sink != "";
            case "powerprofile":
                return true;
            default:
                return false;
            }
        }

        function _getToggleIcon(toggleId): string {
            switch (toggleId) {
            case "network":
                {
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
            case "bluetooth":
                {
                    let devices = BluetoothService.connectedDevices;
                    if (devices.length > 0) {
                        var device = devices[0];
                        var deviceIcon = BluetoothService.getDeviceIcon(device);

                        if (deviceIcon !== "bluetooth") {
                            return deviceIcon;
                        } else {
                            return "bluetooth_connected";
                        }
                    } else {
                        return "bluetooth";
                    }
                }
            case "darkmode":
                return Settings.darkMode ? "dark_mode" : "light_mode";
            case "audio":
                return AudioService.getOutputIcon() ?? AudioService.getInputIcon() ?? "devices_off";
            case "powerprofile":
                return PowerProfileService.getIcon(PowerProfileService.profile);
            default:
                return "help";
            }
        }

        ListModel {
            id: quickTogglesModel
        }

        Flow {
            id: togglesGrid
            width: 330
            spacing: 10
            x: 10
            y: 10

            move: Transition {
                enabled: root.isReady
                NumberAnimation {
                    properties: "x,y"
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            onPositioningComplete: {
                for (var i = 0; i < toggleRepeater.count; i++) {
                    var item = toggleRepeater.itemAt(i);
                    if (!item)
                        continue;

                    if (item.isDragging) {
                        // Flow just moved the item's slot — compensate the translate
                        // so the visual position doesn't jump
                        var dx = item.lastSlotX - item.x;
                        var dy = item.lastSlotY - item.y;
                        item.dragOffsetX += dx;
                        item.dragOffsetY += dy;
                    }

                    // Always update the stored slot position
                    item.lastSlotX = item.x;
                    item.lastSlotY = item.y;
                }
            }

            Repeater {
                id: toggleRepeater
                model: quickTogglesModel

                delegate: Item {
                    id: toggleWrapper
                    required property int index
                    required property string toggleId
                    required property string title
                    required property string icon
                    required property bool compact
                    required property bool hasMenu

                    width: innerToggle.implicitWidth
                    height: innerToggle.implicitHeight

                    property real lastSlotX: 0
                    property real lastSlotY: 0

                    property real dragOffsetX: 0
                    property real dragOffsetY: 0
                    property bool isDragging: false

                    transform: Translate {
                        x: toggleWrapper.dragOffsetX
                        y: toggleWrapper.dragOffsetY
                    }

                    // Only animate snap-back, not during drag
                    Behavior on dragOffsetX {
                        enabled: !toggleWrapper.isDragging
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on dragOffsetY {
                        enabled: !toggleWrapper.isDragging
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }

                    DragHandler {
                        id: toggleDrag
                        enabled: root.editMode
                        target: null

                        onActiveChanged: {
                            if (active) {
                                toggleWrapper.isDragging = true;
                                toggleWrapper.z = 1;
                                // Capture slot position at drag start
                                toggleWrapper.lastSlotX = toggleWrapper.x;
                                toggleWrapper.lastSlotY = toggleWrapper.y;
                            } else {
                                toggleWrapper.isDragging = false;
                                toggleWrapper.z = 0;
                                // Snap back — Flow owns x/y, Translate resets to 0
                                toggleWrapper.dragOffsetX = 0;
                                toggleWrapper.dragOffsetY = 0;
                            }
                        }

                        onTranslationChanged: {
                            if (!active)
                                return;
                            toggleWrapper.dragOffsetX = translation.x;
                            toggleWrapper.dragOffsetY = translation.y;

                            // Hit-test for reorder
                            var scene = centroid.scenePosition;
                            var local = togglesGrid.mapFromGlobal(scene.x, scene.y);

                            for (let i = 0; i < toggleRepeater.count; i++) {
                                let item = toggleRepeater.itemAt(i);
                                if (!item)
                                    continue;
                                let hit = local.x >= item.x && local.x <= item.x + item.width && local.y >= item.y && local.y <= item.y + item.height;

                                if (hit && i !== toggleWrapper.index) {
                                    Utils.timer(200, () => {
                                        quickTogglesModel.move(toggleWrapper.index, i, 1);
                                    }, root);
                                    break;
                                }
                            }
                        }
                    }

                    QuickToggle {
                        id: innerToggle
                        widgetSize: toggleWrapper.compact ? QuickToggle.WidgetSize.Compact : QuickToggle.WidgetSize.Normal
                        hasSubMenu: toggleWrapper.hasMenu
                        editMode: root.editMode
                        active: togglePanel._getToggleActive(toggleId)
                        title: togglePanel._getToggleTitle(toggleId) ?? toggleWrapper.title
                        icon: togglePanel._getToggleIcon(toggleId)
                        status: togglePanel._getToggleStatus(toggleId)
                        onMenuClicked: togglePanel._getToggleMenuClicked(toggleId)
                        onClicked: togglePanel._getToggleClicked(toggleId)
                        onSize: {
                            quickTogglesModel.setProperty(toggleWrapper.index, "compact", innerToggle.isCompact);
                        }
                    }
                }
            }
        }
    }
}
