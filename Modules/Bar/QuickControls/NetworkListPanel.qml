import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Components
import qs.Modals
import qs.Services
import qs.Common

Item {
    id: root
    property var wifiService
    property alias wifi: root.wifiService
    property var wifiModalInstace: null

    signal goBack

    Component.onCompleted: {
        NetworkService.addRef();
        if (NetworkService.wifiEnabled) {
            NetworkService.scanWifi();
        }
    }

    Component.onDestruction: {
        NetworkService.removeRef();
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.getColor("surface_container")
        radius: 12
    }

    Connections {
        target: root.wifiService
        function onPasswordDialogShouldReopenChanged() {
            wifiModalLoader.open("Invalid Password", wifiListContainer.lastAttemptSSID);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12

        // --- Header ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: 28
            color: Theme.getColor("surface_container_highest")

            RowLayout {
                Layout.alignment: Qt.AlignTop
                implicitWidth: parent.width - 10
                Layout.margins: 2

                Rectangle {
                    implicitWidth: 35
                    implicitHeight: 35
                    radius: 20
                    color: !backButtonHover.containsMouse ? Theme.getColor("primary") : Qt.darker(Theme.getColor("primary"))
                    Layout.topMargin: 3.5
                    Layout.leftMargin: 4
                    Layout.rightMargin: 8

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
                    Layout.alignment: Qt.AlignCenter

                    Text {
                        text: "Wifi"
                        color: Theme.getColor("on_surface")
                        font.family: Settings.fontFamily
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }
                }

                Toggle {
                    checked: root.wifiService.wifiEnabled
                    onToggled: {
                        root.wifiService.toggleWifiRadio();
                        delayedWifiScanToggle.start();
                    }
                }

                Timer {
                    id: delayedWifiScanToggle
                    repeat: false
                    interval: 3000
                    onTriggered: {
                        root.wifiService.startAutoScan();
                    }
                }
            }
        }

        // --- Scrollable Wifi List ---
        Flickable {
            id: wifiFlickable
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: 4
            contentHeight: wifiListContainer.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Optional: Scrollbar
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Rectangle {
                id: wifiListContainer
                width: parent.width
                height: wifiColumn.height
                color: "transparent"
                radius: 12

                property string activeInputSSID: ""
                property string lastAttemptSSID: ""

                // Sorted network list
                readonly property var sortedNetworks: {
                    let networks = [...root.wifiService.wifiNetworks];
                    networks.sort((a, b) => {
                        if (a.ssid === root.wifiService.currentWifiSSID)
                            return -1;
                        if (b.ssid === root.wifiService.currentWifiSSID)
                            return 1;
                        return b.signal - a.signal;
                    });
                    return networks;
                }

                Column {
                    id: wifiColumn
                    width: parent.width
                    spacing: 2

                    Repeater {
                        id: wifiRepeater
                        model: wifiListContainer.sortedNetworks

                        delegate: FocusScope {
                            id: delegateScope
                            width: wifiColumn.width
                            height: bgRect.height

                            activeFocusOnTab: true

                            required property int index
                            required property var modelData

                            // Extract properties from modelData
                            readonly property string ssid: modelData.ssid ?? ""
                            readonly property int signal: modelData.signal ?? 0
                            readonly property bool secured: modelData.secured ?? false
                            readonly property string bssid: modelData.bssid ?? ""
                            readonly property bool connected: modelData.connected ?? false
                            readonly property bool saved: modelData.saved ?? false

                            property bool isExpanded: wifiListContainer.activeInputSSID === delegateScope.ssid
                            readonly property bool isCurrent: delegateScope.ssid === root.wifiService.currentWifiSSID
                            readonly property bool isConnecting: root.wifiService.isConnecting && root.wifiService.connectingSSID === delegateScope.ssid
                            readonly property bool isLastAttempt: wifiListContainer.lastAttemptSSID === delegateScope.ssid
                            readonly property bool isErrorForThisRow: isLastAttempt && (root.wifiService.connectionStatus === "invalid_password" || root.wifiService.connectionStatus === "failed")

                            // Helper properties for rounded corners
                            readonly property bool isFirst: delegateScope.index === 0
                            readonly property bool isLast: delegateScope.index === (wifiRepeater.count - 1)

                            Rectangle {
                                id: bgRect
                                width: parent.width
                                height: contentCol.implicitHeight + 20
                                color: Theme.getColor("surface_container_highest")

                                topLeftRadius: delegateScope.isFirst ? 12 : 4
                                topRightRadius: delegateScope.isFirst ? 12 : 4
                                bottomLeftRadius: delegateScope.isLast ? 12 : 4
                                bottomRightRadius: delegateScope.isLast ? 12 : 4

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                MouseArea {
                                    id: contextMenuHover
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: mouse => {
                                        wifiItemMenu.popup();
                                    }
                                }

                                ColumnLayout {
                                    id: contentCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 10

                                    RowLayout {
                                        Layout.fillWidth: true

                                        StyledText {
                                            name: delegateScope.signal >= 50 ? "wifi" : "wifi_1_bar"
                                            color: Theme.getColor("on_surface")
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: 8
                                            spacing: 2

                                            Text {
                                                text: {
                                                    var ssid = delegateScope.ssid;
                                                    if (ssid.length > 20)
                                                        return ssid.slice(0, 18) + "...";
                                                    else if (!ssid)
                                                        return "Hidden";
                                                    else
                                                        return ssid;
                                                }
                                                elide: Text.ElideRight
                                                color: Theme.getColor("on_surface")
                                                font.pixelSize: 14
                                            }

                                            Text {
                                                text: {
                                                    if (delegateScope.isConnecting) {
                                                        return root.wifiService.connectionStatus;
                                                    }
                                                    if (delegateScope.connected) {
                                                        return "Connected";
                                                    } else {
                                                        return delegateScope.saved ? "Saved" : delegateScope.secured ? "Secured" : "Open";
                                                    }
                                                }
                                                font.pixelSize: 11
                                                color: Qt.rgba(Theme.getColor("on_surface").r, Theme.getColor("on_surface").g, Theme.getColor("on_surface").b, 0.7)
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Loading {
                                            visible: delegateScope.isConnecting
                                            dotColor: Theme.getColor("on_secondary")
                                            size: 18
                                            running: root.wifiService.isConnecting
                                            Layout.rightMargin: 8
                                        }

                                        Rectangle {
                                            color: connectBtnMouse.containsMouse ? Qt.darker(Theme.getColor("primary")) : Theme.getColor("primary")
                                            radius: 15
                                            implicitWidth: connectBtnText.text.length * 10
                                            implicitHeight: 30

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 300
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Text {
                                                id: connectBtnText
                                                anchors.centerIn: parent
                                                text: delegateScope.isCurrent ? "Disconnect" : "Connect"
                                                color: Theme.getColor("on_primary")
                                                font.pixelSize: 12
                                            }

                                            MouseArea {
                                                id: connectBtnMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: {
                                                    if (delegateScope.isCurrent) {
                                                        wifiModalLoader.close();
                                                        root.wifiService.disconnectWifi();
                                                        wifiListContainer.activeInputSSID = "";
                                                        wifiListContainer.lastAttemptSSID = "";
                                                        return;
                                                    }

                                                    wifiListContainer.lastAttemptSSID = delegateScope.ssid;

                                                    if (delegateScope.secured && !delegateScope.saved) {
                                                        wifiModalLoader.open("Connect to Wifi", delegateScope.ssid);
                                                    } else {
                                                        root.wifiService.connectToWifi(delegateScope.ssid);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Menu {
                                id: wifiItemMenu
                                popupType: Popup.Window
                                padding: 6
                                background: Item {
                                    implicitWidth: 180
                                    implicitHeight: 44
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: delegateScope.saved ? Theme.getColor("secondary") : Qt.lighter(Theme.getColor("secondary"))
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.08)
                                    }
                                }

                                MenuItem {
                                    id: forgetItem
                                    text: "Forget network"
                                    enabled: delegateScope.saved
                                    implicitHeight: 34
                                    leftPadding: 8
                                    rightPadding: 8
                                    background: Rectangle {
                                        radius: 10
                                        color: forgetItem.highlighted ? Qt.rgba(Theme.getColor("tertiary").r, Theme.getColor("tertiary").g, Theme.getColor("tertiary").b, 0.5) : "transparent"
                                    }
                                    contentItem: Text {
                                        text: forgetItem.text
                                        color: parent.enabled ? Theme.getColor("on_tertiary") : Qt.lighter(Theme.getColor("on_secondary"))
                                        font.pixelSize: 13
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }
                                    onTriggered: {
                                        root.wifiService.forgetWifiNetwork(delegateScope.ssid);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- Global Modal Loader ---
    Loader {
        id: wifiModalLoader
        active: false

        function open(title, ssid) {
            active = true;
            Qt.callLater(() => {
                if (item) {
                    item.open(title, ssid);
                }
            });
        }

        function close() {
            active = false;
        }

        sourceComponent: WifiModal {
            onConnect: function (ssid, password) {
                root.wifiService.connectToWifi(ssid, password);
            }
            onCancel: function (ssid) {
                if (root.wifiService.connectionError) {
                    root.wifiService.forgetWifiNetwork(ssid);
                    root.wifiService.isConnecting = false;
                    wifiListContainer.lastAttemptSSID = "";
                    wifiListContainer.activeInputSSID = "";
                }
            }
            onMenuClosed: {
                wifiModalLoader.active = false;
            }
        }
    }
}
