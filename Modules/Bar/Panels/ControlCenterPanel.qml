import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Widgets
import qs.Services
import qs.Services.UI
import qs.Common
import Quickshell.Services.Pipewire

Item
{
    implicitHeight: togglePanel.implicitHeight
    implicitWidth: togglePanel.implicitWidth
Rectangle {
    id: togglePanel
    implicitHeight: togglesGrid.height + 10
    implicitWidth: togglesGrid.width
    color: "transparent"
    radius: Settings.radius

    GridLayout {
        id: togglesGrid
        readonly property int quickToogleHeight: 50
        readonly property int quickToogleWidth: 170
        columns: 2
        columnSpacing: 12
        rowSpacing: 12

        Rectangle {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            Layout.topMargin: 12
            Layout.bottomMargin: 4
            radius: Settings.radius
            color: Theme.surface

            RowLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                }
                Rectangle {
                    radius: Settings.radius
                    Layout.alignment: Qt.AlignRight
                    color: powerBtnMouse.containsMouse ? Theme.surfaceContainerLow : Theme.surface //powerBtnMouse.containsMouse ? Theme.tertiaryContainer : Theme.surface
                    implicitWidth: 32
                    implicitHeight: 32
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    StyledText {
                        anchors.centerIn: parent
                        name: "power_settings_new"
                        size: 18
                        color: powerBtnMouse.containsMouse ? Theme.tertiaryContainerFg : Theme.primaryContainerFg
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
                var name = NetworkService.ethernetConnected && "Ethernet" || NetworkService.wifiConnected && "Wifi";
                return name.charAt(0).toUpperCase() + name.slice(1);
            }
            status: {
                var ns = NetworkService;
                if (ns.ethernetConnected)
                    return ns.ethernetInterface;
                if (ns.wifiEnabled && !ns.wifiConnected)
                    return "Wifi available";
                if (ns.wifiEnabled && ns.wifiConnected)
                    return ns.activeWifiDetails.connectionName;
                return "No internet";
            }

            active: NetworkService.wifiEnabled || NetworkService.ethernetConnected
            onMenuClicked: quickLayoutStack.currentIndex = 1
            implicitWidth: togglesGrid.quickToogleWidth
            implicitHeight: togglesGrid.quickToogleHeight
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
            implicitWidth: togglesGrid.quickToogleWidth
            implicitHeight: togglesGrid.quickToogleHeight
            active: BluetoothService.enabled
            onMenuClicked: quickLayoutStack.currentIndex = 2
            onClicked: {
                BluetoothService.toggleBluetooth();
            }
        }
        QuickToggle {
            icon: "dark_mode"
            title: "Dark mode"
            active: Settings.darkMode
            hasSubMenu: false
            onClicked: Settings.setDarkMode(!Settings.darkMode)
            implicitWidth: togglesGrid.quickToogleWidth
            implicitHeight: togglesGrid.quickToogleHeight
        }
        QuickToggle {
            implicitWidth: togglesGrid.quickToogleWidth
            implicitHeight: togglesGrid.quickToogleHeight
        }
        ColumnLayout {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            spacing: 0
            RevealItems {
                id: revealAudio
                Layout.fillWidth: true
                Layout.columnSpan: 2
                subItems: (AudioService.appStreams?.length ?? 0) > 0
                main: RowLayout {
                    Layout.fillWidth: true
                    implicitWidth: parent.width
                    Rectangle {
                        implicitHeight: 48
                        implicitWidth: 48
                        color: Theme.surfaceContainerHighest
                        radius: Settings.radius
                        StyledText {
                            anchors.centerIn: parent
                            color: AudioService.muted ? Theme.surfaceVariantFg : Theme.primaryContainerFg
                            name: AudioService.getOutputIcon()
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.setOutputMuted(!AudioService.muted)  // ← This toggles mute
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        value: AudioService.volume * 100
                        minValue: 0
                        maxValue: Settings.audio.volumeOverdrive ? 150 : 100
                        icon: ""  // Icon is separate
                        showValue: true

                        onMoved: newValue => {
                            AudioService.setVolume(newValue / 100);
                        }
                    }
                }
                sub: ColumnLayout {
                    id: appStreamCol
                    Layout.fillWidth: true
                    width: parent.width
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

                            Rectangle {
                                implicitHeight: 48
                                implicitWidth: 48
                                color: Theme.surfaceContainerHighest
                                radius: Settings.radius

                                StyledText {
                                    anchors.centerIn: parent
                                    color: streamDelegate.appMuted ? Theme.surfaceVariantFg : Theme.primaryContainerFg
                                    name: AudioService.getApplicationVolumeIcon(streamDelegate.node)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        streamDelegate.audioNode.muted = !streamDelegate.appMuted;
                                        AudioService.setPanelAppStreamMuted(streamDelegate.audioNode, !streamDelegate.appMuted);
                                    }
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                value: ((streamDelegate.appVolume !== undefined) ? streamDelegate.appVolume : 0.0) * 100
                                minValue: 0
                                maxValue: 100
                                icon: ""
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
                subItems: BrightnessService.monitors.length > 1
                property var currentScreen: BrightnessService && BrightnessService.getMonitorForScreen(root.screen)
                property real mainBrightness: currentScreen ? currentScreen.brightness : 0.0
                main: RowLayout {
                    Layout.fillWidth: true
                    implicitWidth: parent.width
                    Rectangle {
                        implicitHeight: 48
                        implicitWidth: 48
                        color: Theme.surfaceContainerHighest
                        radius: Settings.radius
                        StyledText {
                            anchors.centerIn: parent
                            color: AudioService.muted ? Theme.surfaceVariantFg : Theme.primaryContainerFg
                            name: BrightnessService.getBrightnessIcon(revealBrightness.currentScreen.brightness)
                        }
                    }
                    Slider {
                        Layout.fillWidth: true
                        value: Math.round(revealBrightness.mainBrightness * 100)
                        minValue: 0
                        maxValue: 100
                        icon: ""  // Icon is separate
                        showValue: true
                        onMoved: newValue => {
                            BrightnessService.setBrightness(newValue / 100);
                        }
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

                            Rectangle {
                                implicitHeight: 48
                                implicitWidth: 48
                                color: Theme.surfaceContainerHighest
                                radius: Settings.radius

                                StyledText {
                                    anchors.centerIn: parent
                                    color: Theme.primaryContainerFg
                                    name: BrightnessService.getBrightnessIcon(brightnessStreamDelegate.modelData.brightness)
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                // ← Use the properly bound property
                                value: Math.round(brightnessStreamDelegate.modelData.brightness * 100)
                                minValue: 0
                                maxValue: 100
                                icon: ""
                                showValue: true

                                onMoved: newValue => {
                                    brightnessStreamDelegate.modelData.setBrightness(value / 100);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
}
