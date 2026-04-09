import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Widgets
import qs.Modals
import qs.Services
import qs.Common

Item {
    id: root
    signal goBack
    implicitHeight: 400
    implicitWidth: 350

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
        // --- Header ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: Settings.radius
            color: Theme.surfaceContainerHighest

            RowLayout {
                anchors {
                    leftMargin: 4
                    rightMargin: 4
                    fill: parent
                }
                Rectangle {
                    implicitWidth: 35
                    implicitHeight: 35
                    radius: Settings.radius
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
                    Layout.alignment: Qt.AlignCenter

                    Text {
                        text: "Wifi"
                        color: Theme.surfaceFg
                        font.family: Settings.fontFamily
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }
                }

                StyledText {
                    id: refreshIcon
                    Layout.margins: 4
                    name: "refresh"
                    color: Theme.surfaceFg
                    rotation: 0

                    NumberAnimation on rotation {
                        id: rotationAnim
                        running: NetworkService.scanningActive
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite

                        // Reset rotation when animation stops
                        onRunningChanged: {
                            if (!running) {
                                refreshIcon.rotation = 0;
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NetworkService.scan();
                        }
                    }
                }

                Toggle {
                    id: wifiToggle
                    checked: NetworkService.wifiEnabled
                    onToggled: {
                        NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
                    }
                }
            }
        }

        // --- Scrollable Wifi List ---
        Flickable {
            id: wifiFlickable
            Layout.fillHeight: true
            Layout.fillWidth: true
            contentHeight: wifiListContainer.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Optional: Scrollbar
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout {
                id: wifiListContainer
                implicitHeight: 20
                width: parent.width

                property string activeInputSSID
                property string lastAttemptSSID
                property var connectedNetworks: []

                Component.onCompleted: getConnectedNetworks()

                Connections {
                    target: NetworkService

                    function onWifiConnectedChanged() {
                        Qt.callLater(() => wifiListContainer.getConnectedNetworks());
                    }

                    function onEthernetConnectedChanged() {
                        Qt.callLater(() => wifiListContainer.getConnectedNetworks());
                    }

                    function onWifiEnabledChanged() {
                        Qt.callLater(() => wifiListContainer.getConnectedNetworks());
                    }
                }

                function getConnectedNetworks() {
                    var list = [];

                    // Only add if actually connected and has data
                    if (NetworkService.ethernetConnected && NetworkService.activeEthernetDetails.connectionName) {
                        list.push({
                            type: "ethernet",
                            data: NetworkService.activeEthernetDetails
                        });
                    }

                    if (NetworkService.wifiConnected && NetworkService.activeWifiDetails.connectionName) {
                        list.push({
                            type: "wifi",
                            data: NetworkService.activeWifiDetails
                        });
                    }

                    connectedNetworks = list;
                }

                Text {
                    Layout.leftMargin: 8
                    visible: NetworkService.ethernetConnected || NetworkService.wifiConnected
                    color: Qt.darker(Theme.primary)
                    font.family: Settings.fontFamily
                    text: "Connected networks"
                    font.pixelSize: 12
                }

                Repeater {
                    id: connectedRepeated
                    model: wifiListContainer.connectedNetworks

                    delegate: Rectangle {
                        id: connectedDelegateScope
                        Layout.fillWidth: true
                        implicitHeight: connectedContentCol.implicitHeight + 20
                        color: Theme.surfaceContainerHighest

                        required property var modelData
                        required property int index
                        readonly property bool isFirst: connectedDelegateScope.index === 0
                        readonly property bool isLast: connectedDelegateScope.index === (connectedRepeated.count - 1)

                        topLeftRadius: connectedDelegateScope.isFirst ? 24 : 4
                        topRightRadius: connectedDelegateScope.isFirst ? 24 : 4
                        bottomLeftRadius: connectedDelegateScope.isLast ? 24 : 4
                        bottomRightRadius: connectedDelegateScope.isLast ? 24 : 4

                        Behavior on implicitHeight {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutQuad
                            }
                        }

                        MouseArea {
                            id: connectedContextMenuHover
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: mouse => {
                                wifiItemMenu.popup();
                            }
                        }

                        ColumnLayout {
                            id: connectedContentCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 10

                            RowLayout {
                                Layout.fillWidth: true

                                StyledText {
                                    name: connectedDelegateScope.modelData.type == "ethernet" ? "lan" : NetworkService.getSignalInfo(connectedDelegateScope.modelData.data.signal, connectedDelegateScope.modelData.data.connected).icon
                                    color: Theme.primaryFg
                                    container: true
                                    containerColor: Theme.primary
                                    size: 20
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8
                                    spacing: 2

                                    Text {
                                        text: {
                                            let name = connectedDelegateScope.modelData.type;
                                            return name.charAt(0).toUpperCase() + name.slice(1);
                                        }
                                        color: Theme.surfaceFg
                                        font.pixelSize: 14
                                    }
                                    Text {
                                        text: {
                                            var ssid = connectedDelegateScope.modelData.data.connectionName;
                                            if (ssid > 20)
                                                return ssid.slice(0, 18) + "...";
                                            else if (!ssid)
                                                return "Hidden";
                                            else
                                                return ssid;
                                        }
                                        color: Qt.rgba(Theme.primaryContainerFg.r, Theme.primaryContainerFg.g, Theme.primaryContainerFg.b, 0.7)
                                        elide: Text.ElideRight
                                        font.pixelSize: 14
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    color: connectedConnectBtnMouse.containsMouse ? Qt.darker(Theme.primary) : Theme.primary
                                    radius: 15
                                    implicitWidth: connectedConnectBtnText.text.length * 10
                                    implicitHeight: 30

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 300
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Text {
                                        id: connectedConnectBtnText
                                        anchors.centerIn: parent
                                        visible: connectedDelegateScope.modelData.type == "wifi"
                                        text: connectedDelegateScope.modelData.type == "wifi" ? "Disconnect" : "Connect"
                                        color: Theme.primaryFg
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: connectedConnectBtnMouse
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: {
                                            if (connectedDelegateScope.modelData.type == "wifi") {
                                                root.wifiService.disconnectWifi();
                                            } else {
                                                if (NetworkService.ethernetConnected) {
                                                    NetworkService.disconnectEthernet();
                                                } else {
                                                    root.wifiService.connectEthernet();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    implicitHeight: wifiColumn.height
                    Layout.fillWidth: true
                    property string activeInputSSID: ""
                    property string lastAttemptSSID: ""

                    Text {
                        Layout.leftMargin: 8
                        visible: NetworkService.wifiEnabled
                        color: Qt.darker(Theme.primary)
                        font.family: Settings.fontFamily
                        text: "Available networks"
                        font.pixelSize: 12
                    }

                    Loading {
                        visible: NetworkService.scanningActive
                        implicitSize: 40
                        Layout.topMargin: 12
                        Layout.bottomMargin: 12
                        Layout.alignment: Qt.AlignCenter
                    }
                    Column {
                        id: wifiColumn
                        Layout.fillWidth: true
                        spacing: 2
                        visible: NetworkService.wifiEnabled

                        Repeater {
                            id: wifiRepeater
                            property var availableNetworks: Object.values(NetworkService.networks || {})
                            model: availableNetworks

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

                                // Helper properties for rounded corners
                                readonly property bool isFirst: delegateScope.index === 0
                                readonly property bool isLast: delegateScope.index === (wifiRepeater.count - 1)

                                Rectangle {
                                    id: bgRect
                                    width: parent.width
                                    height: contentCol.implicitHeight + 20
                                    color: Theme.surfaceContainerHighest

                                    topLeftRadius: delegateScope.isFirst ? 24 : 4
                                    topRightRadius: delegateScope.isFirst ? 24 : 4
                                    bottomLeftRadius: delegateScope.isLast ? 24 : 4
                                    bottomRightRadius: delegateScope.isLast ? 24 : 4

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
                                                name: NetworkService.getSignalInfo(delegateScope.signal, delegateScope.connected).icon
                                                color: Theme.primaryFg
                                                container: true
                                                containerColor: Theme.primary
                                                size: 20
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
                                                    color: Theme.surfaceFg
                                                    font.pixelSize: 14
                                                }

                                                Text {
                                                    text: {
                                                        if (delegateScope.isConnecting) {
                                                            return "Connecting...";
                                                        }
                                                        if (delegateScope.connected) {
                                                            return "Connected";
                                                        } else {
                                                            return delegateScope.saved ? "Saved" : delegateScope.secured ? "Secured" : "Open";
                                                        }
                                                    }
                                                    font.pixelSize: 11
                                                    color: Qt.rgba(Theme.primaryContainerFg.r, Theme.primaryContainerFg.g, Theme.primaryContainerFg.b, 0.7)
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                            }

                                            Rectangle {
                                                color: connectBtnMouse.containsMouse ? Qt.darker(Theme.primary) : Theme.primary
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
                                                    text: delegateScope.connected ? "Disconnect" : "Connect"
                                                    color: Theme.primaryFg
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
                                                            NetworkService.disconnect(delegateScope.ssid);
                                                            wifiListContainer.activeInputSSID = "";
                                                            wifiListContainer.lastAttemptSSID = "";
                                                            return;
                                                        }

                                                        wifiListContainer.lastAttemptSSID = delegateScope.ssid;

                                                        if (delegateScope.secured && !delegateScope.saved) {
                                                            wifiModalLoader.open("Connect to Wifi", delegateScope.ssid);
                                                        } else {
                                                            NetworkService.connect(delegateScope.ssid);
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
                                            color: delegateScope.saved ? Theme.secondaryContainer : Qt.lighter(Theme.secondaryContainer)
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
                                            color: forgetItem.highlighted ? Qt.rgba(Theme.tertiary.r, Theme.tertiary.g, Theme.tertiary.b, 0.5) : "transparent"
                                        }
                                        contentItem: Text {
                                            text: forgetItem.text
                                            color: parent.enabled ? Theme.tertiaryFg : Qt.rgba(Theme.secondaryFg.r, Theme.secondaryFg.g, Theme.secondaryFg.b, 0.5)
                                            font.pixelSize: 13
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }
                                        onTriggered: {
                                            NetworkService.forget(delegateScope.ssid);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // --- Empty State ---
        HelpInfo {
            visible: !NetworkService.wifiEnabled
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            icon: if (!NetworkService.wifiEnabled) {
                return "wifi_off";
            } else {
                return "warning";
            }
            title: if (!NetworkService.wifiEnabled) {
                return "Turn on wifi";
            } else {
                return "Wifi Adapter not found";
            }
        }
    }

    // --- Global Modal Loader ---
    Loader {
        id: wifiModalLoader
        active: false
        asynchronous: true

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
