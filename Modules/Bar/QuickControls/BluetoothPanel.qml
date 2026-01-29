import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Components
import qs.Services
import qs.Common

Item {
    id: root
    property var bs
    property alias bluetooth: root.bs

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

    Component.onDestruction: {
        root.stopDiscovering();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.getColor("surface_container")
        radius: 12
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // --- Header (Fixed, doesn't scroll) ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: 28
            color: Theme.getColor("surface_container_highest")

            Text {
                anchors.centerIn: parent
                text: "Bluetooth"
                font.family: Settings.fontFamily
                color: Theme.getColor("on_surface")
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
                    color: !backButtonHover.containsMouse ? Theme.getColor("primary") : Qt.darker(Theme.getColor("primary"))

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    StyledText {
                        name: "chevron_backward"
                        anchors.centerIn: parent
                        color: Theme.getColor("on_primary")
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
                    id: syncIcon
                    Layout.margins: 4
                    name: "sync"
                    color: Theme.getColor("on_surface")
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
                                syncIcon.rotation = 0;
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
                    visible: pairedDevicesRepeater.count > 0

                    Text {
                        Layout.leftMargin: 8
                        color: Qt.darker(Theme.getColor("primary"))
                        font.family: Settings.fontFamily
                        text: "Paired Devices"
                        font.pixelSize: 12
                    }

                    // Use Column + Repeater instead of ListView for proper height
                    Column {
                        Layout.fillWidth: true
                        spacing: 2

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

                                topLeftRadius: isStart ? 12 : 4
                                topRightRadius: isStart ? 12 : 4
                                bottomLeftRadius: isLast ? 12 : 4
                                bottomRightRadius: isLast ? 12 : 4

                                color: pairedDeviceHover.containsMouse ? Qt.lighter(Theme.getColor("surface_container_highest"), 1.1) : Theme.getColor("surface_container_highest")

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    StyledText {
                                        name: root.bs.getDeviceIcon(pairedDeviceDelegate.modelData)
                                        color: Theme.getColor("on_surface")
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: pairedDeviceDelegate.modelData.name || "Unknown Device"
                                            color: Theme.getColor("on_surface")
                                            font.pixelSize: 14
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
                                            color: text == "Connected" ? "green" : text.includes("failed") ? "red" : Qt.lighter(Theme.getColor("on_surface"))
                                            font.pixelSize: 11
                                        }
                                    }

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: pairedDeviceDelegate.modelData.connected ? "green" : Theme.getColor("on_surface_variant")
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
                    visible: availableDevicesRepeater.count > 0

                    Text {
                        Layout.leftMargin: 8
                        color: Qt.darker(Theme.getColor("primary"))
                        font.family: Settings.fontFamily
                        text: "Available Devices"
                        font.pixelSize: 12
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

                                topLeftRadius: isStart ? 12 : 4
                                topRightRadius: isStart ? 12 : 4
                                bottomLeftRadius: isLast ? 12 : 4
                                bottomRightRadius: isLast ? 12 : 4

                                color: availableDeviceHover.containsMouse ? Qt.lighter(Theme.getColor("surface_container_highest"), 1.1) : Theme.getColor("surface_container_highest")

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    StyledText {
                                        name: root.bs.getDeviceIcon(availableDeviceDelegate.modelData)
                                        color: Theme.getColor("on_surface")
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: availableDeviceDelegate.modelData.name || "Unknown Device"
                                        color: Theme.getColor("on_surface")
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        name: root.bs.getSignalIcon(availableDeviceDelegate.modelData)
                                        color: Theme.getColor("on_surface_variant")
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

                // --- Empty State ---
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    visible: pairedDevicesRepeater.count === 0 && availableDevicesRepeater.count === 0

                    Text {
                        anchors.centerIn: parent
                        text: root.bs.enabled ? "No devices found" : "Bluetooth is disabled"
                        font.family: Settings.fontFamily
                        color: Theme.getColor("on_surface_variant")
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}
