import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Widgets
import qs.Services
import qs.Common

Item {
    id: root
    property var bs
    property alias bluetooth: root.bs
    implicitHeight: 400
    implicitWidth: 350

    signal goBack

    function startDiscovering() {
        if (!bs.enabled) {
            return;
        }
        bs.adapter.discovering = true;
        autoScanTimer.start();
    }
    function stopDiscovering() {
        autoScanTimer.stop();
        if (bs.adapter && bs.adapter.discovering) {
            bs.adapter.discovering = false;
        }
    }

    Timer {
        id: autoScanTimer
        repeat: false
        interval: 10000
        onTriggered: {
            if (!root.bs.adapter.discovering) {
                return;
            } else {
                root.bs.adapter.discovering = false;
            }
        }
    }

    Component.onCompleted: {
        root.startDiscovering();
    }

    Component.onDestruction: {
        root.stopDiscovering();
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 12
    }

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: 12
            bottomMargin: 12
        }

        // --- Header (Fixed, doesn't scroll) ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: 28
            color: Theme.surfaceContainerHighest

            Text {
                anchors.centerIn: parent
                text: "Bluetooth"
                font.family: Settings.fontFamily
                color: Theme.surfaceFg
                font.pixelSize: 16
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 8

                Rectangle {
                    implicitWidth: 35
                    implicitHeight: 35
                    radius: 20
                    color: !backButtonHover.containsMouse ? Theme.primary : Qt.darker(Theme.primary)

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    StyledText {
                        name: "chevron_backward"
                        anchors.centerIn: parent
                        color: Theme.primaryFg
                    }

                    MouseArea {
                        id: backButtonHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.goBack()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    id: refresh
                    Layout.margins: 4
                    name: "refresh"
                    color: Theme.surfaceFg
                    rotation: 0

                    RotationAnimation on rotation {
                        id: rotationAnim
                        running: root.bs.discovering
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite

                        // Reset rotation when animation stops
                        onRunningChanged: {
                            if (!running) {
                                refresh.rotation = 0;
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.startDiscovering();
                        }
                    }
                }

                Toggle {
                    checked: root.bs.enabled
                    onToggled: {
                        root.bs.adapter.enabled = !root.bs.adapter.enabled;
                    }
                }
            }
        }

        // --- Empty State ---

        HelpInfo {
            visible: !root.bs.enabled
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            icon: "bluetooth_disabled"
            title: "Turn on Bluetooth"
        }

        // --- Scrollable Content ---
        Flickable {
            id: contentFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: width
            contentHeight: scrollableContent.implicitHeight

            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Enable scrolling only when content is taller than view
            interactive: contentHeight > height

            // Optional: Scroll indicator
            ScrollBar.vertical: ScrollBar {
                policy: contentFlickable.contentHeight > contentFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: scrollableContent
                width: parent.width
                spacing: 16

                // --- Paired Devices Section ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.bs.enabled && root.bs?.pairedDevices.length > 0

                    Text {
                        visible: root.bs.enabled
                        Layout.leftMargin: 8
                        color: Qt.darker(Theme.primary)
                        font.family: Settings.fontFamily
                        text: "Paired Devices"
                        font.pixelSize: 12
                    }

                    // Use Column + Repeater instead of ListView for proper height
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        visible: root.bs.enabled

                        Repeater {
                            id: pairedDevicesRepeater
                            model: root.bs?.pairedDevices ?? []

                            delegate: Rectangle {
                                id: pairedDeviceDelegate

                                required property int index
                                required property var modelData

                                property bool isStart: index === 0
                                property bool isLast: index === pairedDevicesRepeater.count - 1

                                width: parent.width
                                height: 48

                                topLeftRadius: isStart ? Settings.radius : 4
                                topRightRadius: isStart ? Settings.radius : 4
                                bottomLeftRadius: isLast ? Settings.radius : 4
                                bottomRightRadius: isLast ? Settings.radius : 4

                                color: pairedDeviceHover.containsMouse ? Qt.lighter(Theme.surfaceContainerHighest, 1.1) : pairedDeviceDelegate.modelData.connected ? Qt.alpha(Theme.primary, 0.13) : Theme.surfaceContainerHighest

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    StyledText {
                                        name: root.bs.getDeviceIcon(pairedDeviceDelegate.modelData)
                                        color: Theme.primaryFg
                                        container: true
                                        containerColor: Theme.primary
                                        size: 20
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: pairedDeviceDelegate.modelData.name || "Unknown Device"
                                            color: Theme.surfaceFg
                                            font.pixelSize: 14
                                            font.family: Settings.fontFamily
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            visible: pairedDeviceDelegate.modelData.state
                                            text: {
                                                switch (pairedDeviceDelegate.modelData.state) {
                                                case BluetoothDeviceState.Disconnected:
                                                    return "Disconnected";
                                                case BluetoothDeviceState.Connecting:
                                                    return "Connecting...";
                                                case BluetoothDeviceState.Connected:
                                                    return "Connected";
                                                case BluetoothDeviceState.Disconnecting:
                                                    return "Disconnecting...";
                                                default:
                                                    return "";
                                                }
                                            }
                                            color: text == "Connected" ? "green" : text.includes("failed") ? "red" : Qt.lighter(Theme.surfaceFg)
                                            font.pixelSize: 11
                                        }
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignRight
                                        name: {
                                            var b = pairedDeviceDelegate.modelData.battery * 100;
                                            if (b >= 95)
                                                return "battery_android_full";
                                            if (b >= 85)
                                                return "battery_android_6";
                                            if (b >= 70)
                                                return "battery_android_5";
                                            if (b >= 50)
                                                return "battery_android_4";
                                            if (b >= 35)
                                                return "battery_android_3";
                                            if (b >= 20)
                                                return "battery_android_2";
                                            if (b >= 10)
                                                return "battery_android_1";
                                            return "battery_android_0";
                                        }
                                        size: 24
                                        color: Theme.primary
                                    }
                                }

                                MouseArea {
                                    id: pairedDeviceHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (pairedDeviceDelegate.modelData.connected) {
                                            pairedDeviceDelegate.modelData.disconnect();
                                        } else {
                                            root.bs.connectDeviceWithTrust(pairedDeviceDelegate.modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- Available Devices Section ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.leftMargin: 8
                        color: Qt.darker(Theme.primary)
                        font.family: Settings.fontFamily
                        text: "Available Devices"
                        font.pixelSize: 12
                        visible: availableDevicesRepeater.count > 0
                    }
                    Loading {
                        visible: root.bs.discovering
                        implicitSize: 40
                        Layout.topMargin: 12
                        Layout.bottomMargin: 12
                        Layout.alignment: Qt.AlignCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Repeater {
                            id: availableDevicesRepeater
                            model: {
                                if (!root.bs?.devices)
                                    return [];

                                return root.bs.devices.values.filter(dev => {
                                    return dev && root.bs.canConnect(dev);
                                });
                            }

                            delegate: Rectangle {
                                id: availableDeviceDelegate

                                required property int index
                                required property var modelData

                                property bool isStart: index === 0
                                property bool isLast: index === availableDevicesRepeater.count - 1

                                width: parent.width
                                height: 48

                                topLeftRadius: isStart ? Settings.radius : 4
                                topRightRadius: isStart ? Settings.radius : 4
                                bottomLeftRadius: isLast ? Settings.radius : 4
                                bottomRightRadius: isLast ? Settings.radius : 4

                                color: availableDeviceHover.containsMouse ? Qt.lighter(Theme.surfaceContainerHighest, 1.1) : Theme.surfaceContainerHighest

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    StyledText {
                                        name: root.bs.getDeviceIcon(availableDeviceDelegate.modelData)
                                        color: Theme.primaryFg
                                        container: true
                                        containerColor: Theme.primary
                                        size: 20
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: availableDeviceDelegate.modelData.name || "Unknown Device"
                                        color: Theme.surfaceFg
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        name: root.bs.getSignalIcon(root.bs.getSignalStrength(availableDeviceDelegate.modelData))
                                        color: Theme.surfaceFg
                                        size: 16
                                    }
                                }

                                MouseArea {
                                    id: availableDeviceHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.bs.connectDeviceWithTrust(availableDeviceDelegate.modelData);
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
