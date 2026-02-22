import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Services
import qs.Common
import qs.Widgets
import qs.Modals

PanelWindow {
    id: root

    // Use real for coords (they're numbers, not "var")
    property real menuX: 0
    property real menuY: 0
    property alias posX: root.menuX
    property alias posY: root.menuY
    property bool visible: false
    property bool isVisible: false

    signal menuClosed

    function openAt(x, y) {
        root.menuX = x - root.width / 2;
        root.menuY = y;
        root.visible = true;
        root.isVisible = true;
    }

    function close() {
        root.visible = false;
    }

    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Click-outside-to-close
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: mouse => {
            const p = mapToItem(quickLayoutStack, mouse.x, mouse.y);
            const inside = (p.x >= 0 && p.x <= quickLayoutStack.width && p.y >= 0 && p.y <= quickLayoutStack.height);
            if (!inside) {
                root.close();
            }
        }
    }

    Item {
        id: panelContainer
        x: Utils.clampScreenX(root.menuX, width, 5)
        y: Utils.clampScreenY(root.menuY, height, 0)
        implicitWidth: 400
        implicitHeight: quickLayoutStack.height
        clip: true

        state: root.visible ? "open" : "closed"
        transformOrigin: Item.Top

        states: [
            State {
                name: "closed"
                PropertyChanges {
                    target: panelContainer
                    opacity: 0
                    scale: 0.9
                }
            },
            State {
                name: "open"
                PropertyChanges {
                    target: panelContainer
                    opacity: 1
                    scale: 1
                }
            }
        ]

        transitions: [
            Transition {
                id: openAnim
                from: "closed"
                to: "open"
                reversible: true
                SequentialAnimation {
                    ScriptAction {
                        script: {
                            if (!root.visible) {
                                root.isVisible = false;
                                root.menuClosed();
                            }
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            properties: "opacity,scale"
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        ]

        StackLayout {
            id: quickLayoutStack
            currentIndex: 0
            clip: true
            implicitWidth: 800
            height: children[currentIndex].implicitHeight

            Behavior on height {
                enabled: root.isVisible
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                active: (root.visible || root.isVisible) && quickLayoutStack.currentIndex === 0
                asynchronous: false
                sourceComponent: Rectangle {
                    id: togglePanel
                    implicitHeight: togglesGrid.implicitHeight + 20
                    implicitWidth: togglesGrid.implicitWidth + 20
                    color: Theme.surfaceContainer
                    radius: 24

                    GridLayout {
                        id: togglesGrid
                        readonly property int quickToogleHeight: 50
                        readonly property int quickToogleWidth: 180
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        anchors.centerIn: parent
                        anchors.margins: 20

                        Rectangle {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            Layout.bottomMargin: 8
                            radius: 24
                            color: Theme.surfaceContainerHighest
                            border.width: 1
                            border.color: Qt.darker(Theme.outline)

                            RowLayout {
                                anchors.fill: parent
                                Rectangle {
                                    radius: 12
                                    Layout.rightMargin: 12
                                    Layout.alignment: Qt.AlignRight
                                    color: powerBtnMouse.containsMouse ? Theme.tertiaryContainer : Theme.surface
                                    border.width: 1
                                    border.color: Qt.darker(Theme.outline)
                                    implicitWidth: 30
                                    implicitHeight: 30
                                    StyledText {
                                        anchors.centerIn: parent
                                        name: "power_settings_new"
                                        font.pixelSize: 15
                                        color: Theme.primaryContainerFg
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
                                }
                            }
                        }

                        QuickToggle {
                            icon: {
                                name: {
                                    var ns = NetworkService;
                                    if (ns.ethernetConnected)
                                        return "lan";
                                    if (ns.wifiEnabled && !ns.wifiConnected)
                                        return "signal_wifi_bad";
                                    if (ns.wifiEnabled && ns.wifiConnected)
                                        return ns.wifiSingalIcon;
                                    return "signal_disconnected";
                                }
                            }
                            title: {
                                var name = NetworkService.networkStatus;
                                return name.charAt(0).toUpperCase() + name.slice(1);
                            }
                            status: {
                                var ns = NetworkService;
                                if (ns.ethernetConnected)
                                    return ns.ethernetInterface;
                                if (ns.wifiEnabled && !ns.wifiConnected)
                                    return "Wifi available";
                                if (ns.wifiEnabled && ns.wifiConnected)
                                    return ns.currentWifiSSID;
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
                            onClicked: Settings.setDarkMode(!Settings.darkMode)
                            implicitWidth: togglesGrid.quickToogleWidth
                            implicitHeight: togglesGrid.quickToogleHeight
                        }
                        QuickToggle {
                            implicitWidth: togglesGrid.quickToogleWidth
                            implicitHeight: togglesGrid.quickToogleHeight
                        }
                        RevealItems {
                            id: reveal
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            Layout.topMargin: 4
                            subItems: (AppAudioService.applicationStreams?.length ?? 0) > 0
                            main: RowLayout {
                                Layout.fillWidth: true
                                implicitWidth: parent.width
                                Rectangle {
                                    implicitHeight: 48
                                    implicitWidth: 48
                                    color: Theme.surfaceContainerHighest
                                    radius: 24
                                    StyledText {
                                        anchors.centerIn: parent
                                        color: AudioService.muted ? Theme.surfaceVariantFg : Theme.primaryContainerFg
                                        name: AudioService.getOutputIcon()
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: AudioService.toggleMute()  // ← This toggles mute
                                    }
                                }

                                Slider {
                                    Layout.fillWidth: true
                                    value: AudioService.volume * 100
                                    minValue: 0
                                    maxValue: Settings.audioVolumeOverdrive ? 150 : 100
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
                                    model: AppAudioService.applicationStreams
                                    delegate: RowLayout {
                                        id: streamDelegate
                                        required property var modelData
                                        readonly property PwNode node: modelData && modelData.ready ? modelData : null
                                        readonly property real appVolume: node?.audio.volume ?? 0
                                        readonly property bool appMuted: node?.audio.muted ?? true

                                        property string resolvedIcon: ""

                                        Component.onCompleted: resolveIcon()

                                        onNodeChanged: resolveIcon()

                                        function resolveIcon() {
                                            let appName = AppAudioService.getApplicationName(node).toLowerCase();

                                            if (appName.includes("electron") || appName.includes("chromium")) {
                                                // Async resolve
                                                AppAudioService.resolveAppName(node, function (name) {
                                                    streamDelegate.resolvedIcon = name;
                                                });
                                                if (!appName.includes("electron") || !appName.includes("chromium")) {
                                                    return;
                                                }
                                                resolvedIcon = appName;
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
                                            radius: 24

                                            StyledText {
                                                anchors.centerIn: parent
                                                color: streamDelegate.appMuted ? Theme.surfaceVariantFg : Theme.primaryContainerFg
                                                name: streamDelegate.node && AppAudioService.getApplicationVolumeIcon(streamDelegate.node)
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: streamDelegate.node && AppAudioService.toggleApplicationMute(streamDelegate.node)
                                            }
                                        }

                                        Slider {
                                            Layout.fillWidth: true
                                            implicitHeight: 30
                                            // ← Use the properly bound property
                                            value: Math.round(streamDelegate.appVolume * 100)
                                            minValue: 0
                                            maxValue: 100
                                            icon: ""
                                            showValue: true

                                            onMoved: newValue => {
                                                streamDelegate.node ? AppAudioService.setApplicationVolume(streamDelegate.node, newValue) : "";
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
                    }
                }
            }

            Loader {
                id: wifiPanelPage
                asynchronous: false
                active: (root.visible || root.isVisible) && quickLayoutStack.currentIndex === 1
                sourceComponent: NetworkListPanel {
                    wifi: NetworkService
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }

            Loader {
                id: bluetoothPanelPage
                asynchronous: false
                active: (root.visible || root.isVisible) && quickLayoutStack.currentIndex === 2
                sourceComponent: BluetoothPanel {
                    bluetooth: BluetoothService
                    onGoBack: quickLayoutStack.currentIndex = 0
                }
            }
        }
    }
}
