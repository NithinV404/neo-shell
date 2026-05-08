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
    visible: false

    // Shorthand to the live flow object
    readonly property var flow: PolkitService.agent?.flow ?? null
    property bool opened: false

    // Open when polkit fires a request
    Connections {
        target: PolkitService.agent
        function onIsActiveChanged() {
            if (PolkitService.agent.isActive) {
                passwordInput.clear();
                root.visible = true;
                root.opened = true;
                openTimer.start();
            }
        }
    }

    // Close when the flow finishes (success or daemon cancel)
    Connections {
        target: root.flow
        function onIsCompletedChanged() {
            if (root.flow?.isCompleted)
                root.close();
        }
        function onIsCancelledChanged() {
            if (root.flow?.isCancelled)
                root.close();
        }
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
        onTriggered: root.visible = false
    }

    // Backdrop click cancels
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            const p = mapToItem(modalContainer, mouse.x, mouse.y);
            const inside = p.x >= 0 && p.x <= modalContainer.width && p.y >= 0 && p.y <= modalContainer.height;
            if (!inside) {
                root.flow?.cancelAuthenticationRequest();
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
        transitions: Transition {
            NumberAnimation {
                properties: "opacity,scale"
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

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
                    text: root.flow?.message ?? "Authentication Required"
                    font.family: Settings.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    color: Theme.surfaceFg
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: root.flow?.actionId ?? ""
                    font.pixelSize: 11
                    font.family: Settings.fontFamily
                    color: Theme.surfaceVariantFg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Error / supplementary message (e.g. "Wrong password")
            Rectangle {
                Layout.fillWidth: true
                height: errText.implicitHeight + 12
                radius: Settings.radius / 2
                color: root.flow?.supplementaryIsError ? Qt.rgba(1, 0, 0, 0.12) : Qt.rgba(0, 1, 0, 0.08)
                visible: (root.flow?.supplementaryMessage ?? "") !== ""

                Text {
                    id: errText
                    anchors {
                        fill: parent
                        margins: 6
                    }
                    text: root.flow?.supplementaryMessage ?? ""
                    color: root.flow?.supplementaryIsError ? Theme.error : "green"
                    font.pixelSize: 12
                    font.family: Settings.fontFamily
                    wrapMode: Text.WordWrap
                }
            }

            // Input (only shown when polkit asks for one)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.flow?.isResponseRequired ?? false

                Text {
                    text: root.flow?.inputPrompt ?? "Password"
                    font.pixelSize: 12
                    font.family: Settings.fontFamily
                    font.weight: Font.Medium
                    color: Theme.surfaceVariantFg
                }

                InputField {
                    id: passwordInput
                    Layout.fillWidth: true
                    placeholder: root.flow?.inputPrompt ?? "Enter password"
                    // polkit tells us whether to hide the input
                    password: !(root.flow?.responseVisible ?? false)
                    onAccepted: submitResponse()
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 12

                Button {
                    text: "Cancel"
                    onClicked: {
                        root.flow?.cancelAuthenticationRequest();
                        root.close();
                    }
                }

                Button {
                    text: "Authenticate"
                    primary: true
                    enabled: passwordInput.text.length > 0
                    visible: root.flow?.isResponseRequired ?? false
                    onClicked: submitResponse()
                }
            }
        }
    }

    function submitResponse() {
        if (root.flow?.isResponseRequired) {
            root.flow.submit(passwordInput.text);
            passwordInput.clear();
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            root.flow?.cancelAuthenticationRequest();
            root.close();
        }
    }
}
