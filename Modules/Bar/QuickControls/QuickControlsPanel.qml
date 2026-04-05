import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.Services
import qs.Common
import qs.Widgets
import Quickshell.Wayland

PanelWindow {
    id: root

    // Use real for coords (they're numbers, not "var")
    required property var screen
    property real menuX: 0
    property real menuY: 0
    property alias posX: root.menuX
    property alias posY: root.menuY
    property bool visible: false
    property bool isVisible: false

    signal menuClosed

    function openAt(x, y) {
        root.menuX = x;
        root.menuY = y;
        root.visible = true;
        root.isVisible = true;
    }

    function close() {
        root.visible = false;
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

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
        x: Utils.clampScreenX(root.menuX, width, 5, root.screen)
        y: Utils.clampScreenY(root.menuY, height, 0, root.screen)
        implicitWidth: quickLayoutStack.width + 40
        implicitHeight: quickLayoutStack.height
        clip: false
        state: root.visible ? "open" : "closed"
        transformOrigin: Item.Top

        DropShadow {
            anchors.fill: panelRect
            source: panelRect
            horizontalOffset: 0
            verticalOffset: 8
            radius: 18
            samples: 49
            color: Qt.rgba(0, 0, 0, 0.35)
            transparentBorder: true
        }

        states: [
            State {
                name: "closed"
                PropertyChanges {
                    target: panelContainer
                    opacity: 0
                    scale: 0.9
                    height: 0
                }
            },
            State {
                name: "open"
                PropertyChanges {
                    target: panelContainer
                    opacity: 1
                    scale: 1
                    height: quickLayoutStack.height
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
                            properties: "opacity,scale,height"
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        ]

        Rectangle {
            id: panelRect
            anchors.fill: parent
            radius: Settings.radius
            color: Theme.surface
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        }

        StackLayout {
            id: quickLayoutStack
            currentIndex: 0
            clip: true
            implicitWidth: children[currentIndex].implicitWidth
            height: children[currentIndex].implicitHeight
            anchors.centerIn: parent

            Behavior on height {
                enabled: root.isVisible
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }

            Loader {
                active: (root.visible || root.isVisible) && quickLayoutStack.currentIndex === 0
                asynchronous: false
                sourceComponent: Rectangle {
                    id: togglePanel
                    implicitHeight: togglesGrid.implicitHeight + 30
                    implicitWidth: togglesGrid.implicitWidth
                    color: "transparent"
                    radius: Settings.radius

                    GridLayout {
                        id: togglesGrid
                        readonly property int quickToogleHeight: 50
                        readonly property int quickToogleWidth: 170
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12
                        anchors.centerIn: parent

                        Rectangle {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            Layout.preferredHeight: 26
                            Layout.bottomMargin: 4
                            radius: Settings.radius
                            color: "transparent" //Theme.surfaceContainerHighest
                            // border.width: 1
                            // border.color: Qt.darker(Theme.outline)

                            RowLayout {
                                anchors.fill: parent
                                Rectangle {
                                    radius: Settings.radius
                                    Layout.alignment: Qt.AlignRight
                                    color: powerBtnMouse.containsMouse ? Theme.surfaceContainerLow : Theme.surface //powerBtnMouse.containsMouse ? Theme.tertiaryContainer : Theme.surface
                                    //border.width: 1
                                    //border.color: Qt.darker(Theme.outline)
                                    implicitWidth: 32
                                    implicitHeight: 32
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
                                    var ns = NetworkService;
                                    if (ns.ethernetConnected) {
                                        return "lan";
                                    }
                                    if (ns.wifiEnabled && !ns.wifiConnected) {
                                        return "signal_wifi_bad";
                                    }
                                    if (ns.wifiEnabled && ns.wifiConnected) {
                                        return ns.getWifiSignalIcon(ns.wifiSignalStrength);
                                    }

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
                                subItems: (AppAudioService.applicationStreams?.length ?? 0) > 0
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
                                            readonly property var node: AppAudioService.isValidNode(modelData) && modelData
                                            readonly property real appVolume: node.audio.volume ?? 0
                                            readonly property bool appMuted: node.audio.muted ?? true

                                            property string resolvedIcon: ""

                                            Component.onCompleted: resolveIcon()
                                            onNodeChanged: resolveIcon()

                                            function resolveIcon() {
                                                let appName = "";
                                                AppAudioService.getApplicationName(node, function (name) {
                                                    appName = name;
                                                });

                                                if (appName.includes("electron") || appName.includes("Chromium")) {
                                                    // Set a generic fallback icon immediately while we wait for resolution
                                                    resolvedIcon = "chromium";

                                                    AppAudioService.resolveAppName(node, function (name) {
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
                                                    name: AppAudioService.getApplicationVolumeIcon(streamDelegate.node)
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: AppAudioService.toggleApplicationMute(streamDelegate.node)
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
                                                    AppAudioService.setApplicationVolume(streamDelegate.node, newValue);
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
                                                implicitHeight: 30
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

            Loader {
                id: wifiPanelPage
                asynchronous: false
                active: (root.visible || root.isVisible) && quickLayoutStack.currentIndex === 1
                sourceComponent: NetworkListPanel {
                    wifi: NetworkService
                    onGoBack: quickLayoutStack.currentIndex = 0
                    anchors.fill: parent
                }
            }

            Loader {
                id: bluetoothPanelPage
                asynchronous: false
                active: (root.visible || root.isVisible) && quickLayoutStack.currentIndex === 2
                sourceComponent: BluetoothPanel {
                    bluetooth: BluetoothService
                    onGoBack: quickLayoutStack.currentIndex = 0
                    anchors.fill: parent
                }
            }
        }
    }
}
