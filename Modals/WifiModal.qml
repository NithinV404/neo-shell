import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Services
import qs.Widgets
import qs.Common

PanelWindow {
    id: root

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    color: "transparent"
    focusable: true
    visible: false
    exclusionMode: ExclusionMode.Ignore

    Component.onCompleted: {
        if (this.WlrLayershell != null) {
            this.WlrLayershell.layer = WlrLayer.Overlay;
            this.WlrLayershell.namespace = "neoshell:panel";
        }
    }

    BackgroundEffect.blurRegion: Region {
        item: modalContainer
        radius: Settings.radius
    }

    // Signals
    signal connectRequested(string ssid, string password)
    signal cancelRequested(string ssid)
    signal menuClosed

    // Properties
    property string ssid
    property string title
    property bool opened: false

    function open(modalTitle, networkSsid) {
        root.title = modalTitle || "Modal";
        root.ssid = networkSsid || "Unknown Network";
        passwordInput.clear();
        root.visible = true;
        root.opened = true;
        openTimer.start();
    }

    function close() {
        root.opened = false;
        closeTimer.restart();
    }

    Timer {
        id: openTimer
        interval: 100
        onTriggered: passwordInput.setFocus()
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: {
            root.menuClosed();
            root.visible = false;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        onClicked: mouse => {
            const p = mapToItem(modalContainer, mouse.x, mouse.y);
            const inside = (p.x >= 0 && p.x <= modalContainer.width && p.y >= 0 && p.y <= modalContainer.height);
            if (!inside) {
                root.cancelRequested(root.ssid);
                root.close();
            }
        }
    }

    Rectangle {
        id: modalContainer
        width: 420
        height: contentColumn.implicitHeight + 48 // 24 top margin + 24 bottom margin

        anchors.centerIn: parent
        color: Qt.alpha(Theme.surface, Settings.blurEnabled ? Settings.blurOpacity : 1)
        radius: Settings.radius

        // Clean animation using Behavior instead of States/Transitions
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.94

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: contentColumn

            // Anchor to top and sides to allow implicitHeight to calculate properly
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 24
            }
            spacing: 16

            // Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.title
                    font.family: Settings.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.Medium
                    color: Theme.surfaceFg
                }

                Text {
                    text: root.ssid
                    font.pixelSize: 14
                    font.family: Settings.fontFamily
                    color: Theme.surfaceVariantFg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Password input
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Password"
                    font.pixelSize: 12
                    font.family: Settings.fontFamily
                    font.weight: Font.Medium
                    color: Theme.surfaceVariantFg
                }

                InputField {
                    id: passwordInput
                    Layout.fillWidth: true
                    placeholder: "Enter network password"
                    password: true
                    onAccepted: {
                        if (text.length >= 8) {
                            root.connectRequested(root.ssid, text);
                            root.close();
                        }
                    }
                }
            }

            // Spacer
            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 8
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 12

                Button {
                    text: "Cancel"
                    onClicked: {
                        root.cancelRequested(root.ssid);
                        root.close();
                    }
                }

                Button {
                    text: "Connect"
                    primary: true
                    enabled: passwordInput.text.length >= 8
                    onClicked: {
                        root.connectRequested(root.ssid, passwordInput.text);
                        root.close();
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            root.cancelRequested(root.ssid);
            root.close();
        }
    }
}
