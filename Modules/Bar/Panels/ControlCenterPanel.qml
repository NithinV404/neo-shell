import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Services
import qs.Services.UI
import qs.Common
import Quickshell.Services.Pipewire

Item {
    implicitHeight: layout.implicitHeight
    implicitWidth: layout.implicitWidth
    ColumnLayout {
        id: layout
        anchors.centerIn: parent
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
                    color: powerBtnMouse.containsMouse ? Theme.primary : Theme.surfaceContainer //powerBtnMouse.containsMouse ? Theme.tertiaryContainer : Theme.surface
                    implicitWidth: 32
                    implicitHeight: 32

                    StyledText {
                        anchors.centerIn: parent
                        name: "power_settings_new"
                        size: 18
                        color: powerBtnMouse.containsMouse ? Theme.primaryFg : Theme.surfaceFg
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

            Flow {
                id: togglesGrid
                anchors.centerIn: parent
                width: 332
                spacing: 12

                QuickToggle {
                    icon: {
                        name: {
                            if (NetworkService.ethernetConnected) {
                                return "lan";
                            }
                            if (NetworkService.wifiEnabled && !NetworkService.wifiConnected) {
                                return "signal_wifi_bad";
                            }
                            if (NetworkService.wifiEnabled && NetworkService.wifiConnected) {
                                return NetworkService.getSignalInfo(NetworkService.activeWifiDetails.signal, NetworkService.connected).icon;
                            }

                            return "signal_disconnected";
                        }
                    }
                    title: {
                        var name = NetworkService.ethernetConnected && "Ethernet" || NetworkService.wifiConnected && "Wifi" || "Ethernet";
                        return name.charAt(0).toUpperCase() + name.slice(1);
                    }
                    status: {
                        var ns = NetworkService;
                        if (ns.ethernetConnected)
                            return ns.activeEthernetDetails?.connectionName ?? "Connected";
                        if (ns.wifiEnabled && !ns.wifiConnected)
                            return "WiFi on";
                        if (ns.wifiEnabled && ns.wifiConnected)
                            return ns.activeWifiDetails?.connectionName ?? "Connected";
                        return "Offline";
                    }

                    active: NetworkService.wifiEnabled || NetworkService.ethernetConnected
                    onMenuClicked: quickLayoutStack.currentIndex = 1
                }

                QuickToggle {
                    title: "Bluetooth"
                    icon: {
                        var devices = BluetoothService.connectedDevices;

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

                    status: {
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

                    active: BluetoothService.enabled
                    onMenuClicked: quickLayoutStack.currentIndex = 2
                    onClicked: {
                        BluetoothService.toggleBluetooth();
                    }
                }
                QuickToggle {
                    icon: Settings.darkMode ? "dark_mode" : "light_mode"
                    title: "Dark mode"
                    active: Settings.darkMode
                    widgetSize: QuickToggle.WidgetSize.Compact
                    hasSubMenu: false
                    onClicked: Settings.setDarkMode(!Settings.darkMode)
                }
                QuickToggle {
                    icon: AudioService.getOutputIcon() ?? AudioService.getInputIcon() ?? "devices_off"
                    active: Settings.source != "" || Settings.sink != ""
                    title: "Audio"
                    status: AudioService.source.nickname || AudioService.source.description || "Unknown Device"
                    onClicked: {
                        quickLayoutStack.currentIndex = 3;
                    }
                    onMenuClicked: {
                        quickLayoutStack.currentIndex = 3;
                    }
                }
                QuickToggle {
                    icon: PowerProfileService.getIcon(PowerProfileService.profile)
                    widgetSize: QuickToggle.WidgetSize.Compact
                    active: true
                    hasSubMenu: false
                    title: "Power Profile"
                    status: PowerProfileService.getName(PowerProfileService.profile)
                    onClicked: {
                        PowerProfileService.cycleProfile();
                    }
                }
            }
        }
        ColumnLayout {
            spacing: 6
            RevealItems {
                id: revealAudio
                implicitHeight: revealAudio.height
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
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
                    onIconPress: {
                        AudioService.setOutputMuted(!AudioService.muted);
                    }
                    showValue: true

                    onMoved: newValue => {
                        AudioService.setVolume(newValue / 100);
                    }
                }
                sub: ColumnLayout {
                    id: appStreamCol
                    Layout.fillWidth: true
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
                implicitHeight: revealBrightness.height
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
