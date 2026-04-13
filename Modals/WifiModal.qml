import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
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
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ✅ Fixed: Use proper signal declarations (no 'on' prefix in declaration)
    signal connectRequested(string ssid, string password)
    signal cancelRequested(string ssid)
    signal menuClosed()

    property string ssid
    property string title
    property bool opened: false

    function open(title, networkSsid) {
        root.ssid = networkSsid || "Unknown Network";
        root.title = title || "Modal";
        passwordInput.clear();
        root.opened = true;
        root.visible = true;  // ✅ Ensure visibility
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
        repeat: false
        interval: 220
        onTriggered: {
            root.menuClosed();  // ✅ Emit signal properly
            root.visible = false;  // ✅ Hide window after animation
        }
    }

    // ✅ Fixed: Check if visible before processing events
    visible: false

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        propagateComposedEvents: true
        onClicked: mouse => {
            const p = mapToItem(modalContainer, mouse.x, mouse.y);
            const inside = (p.x >= 0 && p.x <= modalContainer.width && p.y >= 0 && p.y <= modalContainer.height);
            if (!inside) {
                // ✅ Fixed: Use proper signal emission syntax
                root.cancelRequested(root.ssid);
                root.close();
            }
        }
    }

    Rectangle {
        id: modalContainer
        implicitWidth: 420
        implicitHeight: contentColumn.implicitHeight + 48
        color: Theme.surface
        anchors.centerIn: parent
        radius: Settings.radius
        state: root.opened ? "open" : "closed"

        states: [
            State {
                name: "closed"
                PropertyChanges {
                    target: modalContainer
                    opacity: 0
                    scale: 0.94
                }
            },
            State {
                name: "open"
                PropertyChanges {
                    target: modalContainer
                    opacity: 1
                    scale: 1
                }
            }
        ]

        transitions: [
            Transition {
                from: "closed"
                to: "open"
                ParallelAnimation {
                    NumberAnimation {
                        properties: "opacity,scale"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            },
            Transition {
                from: "open"
                to: "closed"
                ParallelAnimation {
                    NumberAnimation {
                        properties: "opacity,scale"
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
        ]

        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: 24
            }
            spacing: 16

            // Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    id: titleText  // ✅ Renamed to avoid conflict with property
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
                        if (passwordInput.text.length >= 8) {
                            root.connectRequested(root.ssid, passwordInput.text);
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
