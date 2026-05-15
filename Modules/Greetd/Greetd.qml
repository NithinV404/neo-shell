import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ShellRoot {
    id: root

    // ---------------------------------------------------------
    // Material You Integration
    // We map your Theme service to Qt's global Material properties.
    // This automatically themes all Buttons, TextFields, and ComboBoxes!
    // ---------------------------------------------------------
    Material.theme: Material.Dark // Keep this Dark, or use Theme.isDark if you have it
    Material.accent: Theme.primary
    Material.background: Theme.surface
    Material.foreground: Theme.surfaceFg
    Material.primary: Theme.primary

    PanelWindow {
        id: win
        color: Material.background // Now uses Theme.surface
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24
                width: 360

                // User Avatar Circle
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 96
                    height: 96
                    radius: width / 2

                    // Use a container color for the avatar background
                    color: Theme.primaryContainer

                    Label {
                        anchors.centerIn: parent
                        text: userField.text ? userField.text.charAt(0).toUpperCase() : "?"
                        font.pixelSize: 42
                        font.bold: true
                        // Use the text color that goes on top of a primaryContainer
                        color: Theme.onPrimaryContainer
                    }
                }

                Label {
                    text: "Welcome Back"
                    font.pixelSize: 28
                    font.bold: true
                    color: Theme.surfaceFg
                    Layout.alignment: Qt.AlignHCenter
                }

                TextField {
                    id: userField
                    Layout.fillWidth: true
                    placeholderText: "Username"
                    color: Theme.surfaceFg

                    onAccepted: passField.forceActiveFocus()
                    enabled: Greetd.state !== GreetdState.Authenticating
                }

                TextField {
                    id: passField
                    Layout.fillWidth: true
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    color: Theme.surfaceFg

                    onAccepted: root.attemptLogin()
                    enabled: Greetd.state !== GreetdState.Authenticating
                }

                ComboBox {
                    id: sessionCombo
                    Layout.fillWidth: true
                    model: sessionModel
                    textRole: "name"
                    property string selectedExec: currentIndex >= 0 ? model.get(currentIndex).exec : ""
                    enabled: Greetd.state !== GreetdState.Authenticating

                    // ComboBoxes automatically pick up Material.accent and Material.background
                    Material.foreground: Theme.surfaceFg
                }

                Button {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: {
                        if (Greetd.state === GreetdState.Authenticating)
                            return "Authenticating...";
                        if (Greetd.state === GreetdState.Error)
                            return "Retry";
                        return "Sign In";
                    }
                    onClicked: root.attemptLogin()
                    highlighted: true // Makes the button solid instead of outlined
                    enabled: Greetd.state !== GreetdState.Authenticating

                    // Button will automatically use Theme.primary for background
                    // and Theme.onPrimary for text color when highlighted=true
                }

                Label {
                    id: statusText
                    text: ""

                    // Matugen provides an error color, use it here!
                    color: Theme.error

                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: text.length > 0
                }
            }
        }
    }

    // --- Dynamic Session Detection (Embedded Script) ---
    ListModel {
        id: sessionModel
    }

    Process {
        id: sessionDetector
        command: ["bash", "-c", "for d in /usr/share/wayland-sessions /usr/share/xsessions; do [ -d \"$d\" ] && for f in \"$d\"/*.desktop; do [ -f \"$f\" ] && ( n=$(grep '^Name=' \"$f\" | head -1 | sed 's/^Name=//'); e=$(grep '^Exec=' \"$f\" | head -1 | sed 's/^Exec=//' | cut -d' ' -f1); [ -n \"$n\" ] && [ -n \"$e\" ] && printf '%s|%s\\n' \"$n\" \"$e\" ); done; done"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                var parts = data.split("|");
                console.info(data);
                if (parts.length === 2) {
                    sessionModel.append({
                        "name": parts[0],
                        "exec": parts[1]
                    });
                }
            }
        }
    }

    // --- Greetd State Machine Logic ---
    function attemptLogin() {
        if (Greetd.state === GreetdState.Idle || Greetd.state === GreetdState.Error) {
            statusText.text = "";
            Greetd.createSession(userField.text);
        } else if (Greetd.state === GreetdState.AuthMessage) {
            Greetd.postAuthMessageResponse(passField.text);
        }
    }

    Connections {
        target: Greetd

        function onStateChanged() {
            switch (Greetd.state) {
            case GreetdState.Idle:
                break;
            case GreetdState.AuthMessage:
                if (Greetd.authMessage?.authType === GreetdAuthType.Secret) {
                    passField.forceActiveFocus();
                } else if (Greetd.authMessage?.authType === GreetdAuthType.Error) {
                    statusText.text = Greetd.authMessage.text;
                    passField.text = "";
                } else if (Greetd.authMessage?.authType === GreetdAuthType.Visible) {
                    statusText.text = Greetd.authMessage.text;
                }
                break;
            case GreetdState.Authenticating:
                break;
            case GreetdState.ReadyToStart:
                Greetd.startSession([sessionCombo.selectedExec]);
                break;
            case GreetdState.Error:
                statusText.text = Greetd.authMessage?.text || "Authentication failed";
                passField.text = "";
                Greetd.cancelSession();
                userField.forceActiveFocus();
                break;
            }
        }
    }
}
