import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Services
import qs.Services.UI
import qs.Common
import Quickshell.Services.Pipewire

Item {
    required property var screen
    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth
    ColumnLayout {
        id: layout
        Rectangle {
            Layout.columnSpan: 2
            Layout.alignment: Qt.AlignRight
            Layout.margins: 4
            implicitHeight: 32
            implicitWidth: 32
            radius: Settings.radius
            color: Theme.surfaceContainer

            RowLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                }
                Rectangle {
                    radius: Settings.radius
                    Layout.alignment: Qt.AlignCenter
                    color: !togglePanel.editMode ? editButtonMouse.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer : Theme.primary //powerBtnMouse.containsMouse ? Theme.tertiaryContainer : Theme.surface
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledText {
                        anchors.centerIn: parent
                        name: !togglePanel.editMode ? "dashboard_2_edit" : "check"
                        size: 18
                        color: togglePanel.editMode ? Theme.primaryFg : Theme.surfaceFg
                    }
                    MouseArea {
                        id: editButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            togglePanel.editMode = !togglePanel.editMode;
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    radius: Settings.radius
                    Layout.alignment: Qt.AlignCenter
                    color: powerBtnMouse.containsMouse ? Theme.primary : Theme.surfaceContainer //powerBtnMouse.containsMouse ? Theme.tertiaryContainer : Theme.surface
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledText {
                        anchors.centerIn: parent
                        name: "power_settings_new"
                        size: 18
                        color: powerBtnMouse.containsMouse ? Theme.surfaceContainer : Theme.surfaceFg
                    }
                    MouseArea {
                        id: powerBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            PowerMenuService.toggle();
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Rectangle {
            id: togglePanel
            implicitHeight: togglesGrid.height + 20
            implicitWidth: togglesGrid.width + 20
            radius: Settings.radius
            color: Theme.surfaceContainer
            property bool editMode: false

            onEditModeChanged: {
                if (!editMode) {
                    Settings.setToggleOrder(serializeModel());
                }
            }

            function serializeModel() {
                var order = [];
                for (let i = 0; i < quickTogglesModel.count; i++) {
                    order.push(quickTogglesModel.get(i).toggleId);
                }
                return order;
            }

            Component.onCompleted: {
                var saved = Settings.controlCenterToggleOrder;
                if (!saved || saved.length === 0)
                    return;
                for (let i = 0; i < saved.length; i++) {
                    for (let j = i; j < quickTogglesModel.count; j++) {
                        if (quickTogglesModel.get(j).toggleId === saved[i]) {
                            if (j !== i)
                                quickTogglesModel.move(j, i, 1);
                            break;
                        }
                    }
                }
            }

            function _getToggleStatus(toggleId) {
                switch (toggleId) {
                case "network":
                    {
                        var ns = NetworkService;
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
                ListElement {
                    toggleId: "network"
                    title: "Network"
                    icon: "signal_disconnected"
                    compact: false
                    hasMenu: true
                }
                ListElement {
                    toggleId: "bluetooth"
                    title: "Bluetooth"
                    icon: "bluetooth"
                    compact: false
                    hasMenu: true
                }
                ListElement {
                    toggleId: "darkmode"
                    title: "Dark mode"
                    icon: "dark_mode"
                    compact: true
                    hasMenu: false
                }
                ListElement {
                    toggleId: "audio"
                    title: "Audio"
                    icon: "devices_off"
                    compact: false
                    hasMenu: true
                }
                ListElement {
                    toggleId: "powerprofile"
                    title: "Power Profile"
                    icon: "bolt"
                    compact: true
                    hasMenu: false
                }
            }

            Flow {
                id: togglesGrid
                width: 330
                spacing: 10
                x: 10
                y: 10

                move: Transition {
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
                            enabled: togglePanel.editMode
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

                                for (var i = 0; i < toggleRepeater.count; i++) {
                                    var item = toggleRepeater.itemAt(i);
                                    if (!item)
                                        continue;
                                    var hit = local.x >= item.x && local.x <= item.x + item.width && local.y >= item.y && local.y <= item.y + item.height;

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
                            editMode: togglePanel.editMode
                            active: togglePanel._getToggleActive(toggleId)
                            title: togglePanel._getToggleTitle(toggleId) ?? toggleWrapper.title
                            icon: togglePanel._getToggleIcon(toggleId)
                            status: togglePanel._getToggleStatus(toggleId)
                            onMenuClicked: togglePanel._getToggleMenuClicked(toggleId)
                            onClicked: togglePanel._getToggleClicked(toggleId)
                        }
                    }
                }
            }
        }
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true
            Layout.columnSpan: 2
            RevealItems {
                id: revealAudio
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                subItems: (AudioService.appStreams?.length ?? 0) > 0
                color: Theme.surfaceContainer
                main: Slider {
                    Layout.margins: 12
                    Layout.fillWidth: true
                    containerBackground: Theme.surfaceContainer
                    value: AudioService.volume * 100
                    minValue: 0
                    maxValue: Settings.audio.volumeOverdrive ? 150 : 100
                    icon: AudioService.getOutputIcon(AudioService.source)  // Icon is separate
                    showValue: true

                    onMoved: newValue => {
                        AudioService.setVolume(newValue / 100);
                    }
                }
                sub: ColumnLayout {
                    id: appStreamCol
                    implicitWidth: parent.width
                    Repeater {
                        model: AudioService.appStreams
                        delegate: RowLayout {
                            id: streamDelegate
                            required property var modelData
                            property PwNode node: (modelData && modelData.ready) ? modelData : null
                            property PwNodeAudio audioNode: (modelData && modelData.audio) ? modelData.audio : null
                            property real appVolume: (audioNode && audioNode.volume !== undefined) ? audioNode.volume : 0.0
                            property bool appMuted: (audioNode && audioNode.muted !== undefined) ? audioNode.muted : false

                            property string resolvedIcon: ""

                            Component.onCompleted: {
                                resolveIcon();
                            }

                            onNodeChanged: {
                                resolveIcon();
                            }

                            function resolveIcon() {
                                let appName = "";
                                AudioService.getApplicationName(node, function (name) {
                                    appName = name;
                                });

                                if (appName.includes("electron") || appName.includes("Chromium")) {
                                    // Set a generic fallback icon immediately while we wait for resolution
                                    resolvedIcon = "chromium";

                                    AudioService.resolveAppName(node, function (name) {
                                        streamDelegate.resolvedIcon = name;
                                    });
                                } else {
                                    resolvedIcon = appName;
                                }
                            }

                            Layout.fillWidth: true
                            implicitWidth: parent.width

                            Slider {
                                containerBackground: Theme.surfaceContainer
                                Layout.fillWidth: true
                                value: ((streamDelegate.appVolume !== undefined) ? streamDelegate.appVolume : 0.0) * 100
                                minValue: 0
                                maxValue: 100
                                icon: AudioService.getApplicationVolumeIcon(streamDelegate.node)
                                showValue: true
                                enabled: !!(streamDelegate.node && streamDelegate.audioNode)
                                onMoved: function (value) {
                                    streamDelegate.audioNode.volume = value / 100;
                                    AudioService.setPanelAppStreamVolume(streamDelegate.audioNode, value / 100);
                                }
                            }

                            AppIcon {
                                icon: streamDelegate.resolvedIcon
                                size: 30
                            }
                        }
                    }
                }
            }

            RevealItems {
                id: revealBrightness
                Layout.fillWidth: true
                Layout.columnSpan: 2
                color: Theme.surfaceContainer
                subItems: BrightnessService.monitors.length > 1
                property var currentScreen: BrightnessService && BrightnessService.getMonitorForScreen(root.screen)
                property real mainBrightness: currentScreen ? currentScreen.brightness : 0.0
                main: Slider {
                    containerBackground: Theme.surfaceContainer
                    Layout.fillWidth: true
                    value: Math.round(revealBrightness.mainBrightness * 100)
                    minValue: 0
                    maxValue: 100
                    icon: BrightnessService.getBrightnessIcon(revealBrightness.mainBrightness)  // Icon is separate
                    showValue: true
                    onMoved: newValue => {
                        BrightnessService.setBrightness(newValue / 100);
                    }
                }
                sub: ColumnLayout {
                    id: monitorStreamCol
                    Layout.fillWidth: true
                    width: parent.width
                    Repeater {
                        model: BrightnessService.monitors.filter(m => m !== revealBrightness.currentScreen)
                        delegate: RowLayout {
                            id: brightnessStreamDelegate
                            required property var modelData
                            Layout.fillWidth: true
                            implicitWidth: parent.width

                            Slider {
                                containerBackground: Theme.surfaceContainer
                                Layout.fillWidth: true
                                // ← Use the properly bound property
                                value: Math.round(brightnessStreamDelegate.modelData.brightness * 100)
                                minValue: 0
                                maxValue: 100
                                icon: BrightnessService.getBrightnessIcon(brightnessStreamDelegate.modelData.brightness)
                                showValue: true

                                onMoved: newValue => {
                                    brightnessStreamDelegate.modelData.setBrightness(value / 100);
                                }
                            }
                            Rectangle {
                                implicitHeight: 48
                                implicitWidth: 48
                                color: Theme.surfaceContainerHigh
                                radius: Settings.radius

                                StyledText {
                                    anchors.centerIn: parent
                                    color: Theme.primaryContainerFg
                                    name: `monitor`
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
