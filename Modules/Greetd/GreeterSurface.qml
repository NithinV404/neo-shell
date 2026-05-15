import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property var source: Settings.wallpaperImage
    property string sessionCommand: "niri"

    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // ── Greetd Events ─────────────────────────────────────────
    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (error) {
                errorText.text = "Authentication error: " + message;
                errorText.color = "#ff4444";
                Greetd.cancelSession();
                return;
            }

            if (responseRequired) {
                errorText.text = "Responding to: " + message;
                errorText.color = Theme.tertiary;
                Greetd.respond(passwordField.text);
            } else {
                errorText.text = message;
                errorText.color = Theme.secondary;
                Greetd.respond("");
            }
        }

        function onStateChanged() {
            if (Greetd.state === GreetdState.ReadyToLaunch) {
                errorText.text = "Launching session...";
                errorText.color = "#44ff44";
                Greetd.launch([root.sessionCommand]);
            } else if (Greetd.state === GreetdState.Error) {
                errorText.text = "Session error. Please try again.";
                errorText.color = "#ff4444";
                Greetd.cancelSession();
            } else if (Greetd.state === GreetdState.Inactive) {
                errorText.color = Theme.secondary;
                passwordField.text = "";
                passwordField.forceActiveFocus();
            } else if (Greetd.state === GreetdState.Authenticating) {
                errorText.text = "Authenticating...";
                errorText.color = Theme.tertiary;
            }
        }

        function onError(errorType, description) {
            errorText.text = description || "Authentication failed. Please try again.";
            errorText.color = "#ff4444";
            passwordField.text = "";
            Greetd.cancelSession();
        }
    }

    // ── Background ────────────────────────────────────────────
    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            color: "#000000"

            Image {
                anchors.fill: parent
                source: root.source
                fillMode: Image.PreserveAspectCrop
                visible: root.source !== ""
            }
        }

        // ── Clock ─────────────────────────────────────────────
        SystemClock {
            id: clock
            precision: SystemClock.Seconds
        }

        Item {
            id: clockItem
            width: clockLayout.implicitWidth
            height: 200
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 100

            RowLayout {
                id: clockLayout
                anchors.centerIn: parent
                spacing: 1

                Text {
                    text: String(clock.date.getHours() % 12 || 12).padStart(2, '0')
                    font.family: Settings.fontFamily
                    font.pixelSize: 80
                    font.weight: 800
                    renderType: Text.NativeRendering
                    font.hintingPreference: Font.PreferNoHinting
                    color: Theme.primary
                    Layout.alignment: Qt.AlignTop
                }

                Item {
                    width: 20
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 20

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 3
                            color: Theme.secondary
                        }

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 3
                            color: Theme.secondary
                        }
                    }
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "mm")
                    font.family: Settings.fontFamily
                    font.pixelSize: 80
                    font.weight: 800
                    renderType: Text.NativeRendering
                    font.hintingPreference: Font.PreferNoHinting
                    color: Theme.tertiary
                    Layout.alignment: Qt.AlignTop
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "AP")
                    font.family: Settings.fontFamily
                    font.pixelSize: 20
                    font.weight: 500
                    renderType: Text.NativeRendering
                    color: Theme.tertiary
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 16
                }

                Rectangle {
                    width: 4
                    radius: 2
                    color: Theme.secondary
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    Layout.topMargin: 16
                    Layout.bottomMargin: 14
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 16
                    Layout.bottomMargin: 14

                    Text {
                        text: Qt.formatDateTime(clock.date, "MMM").toUpperCase()
                        font.family: Settings.fontFamily
                        font.pixelSize: 20
                        font.weight: 650
                        renderType: Text.NativeRendering
                        color: Theme.primary
                        verticalAlignment: Text.AlignTop
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "dd")
                        font.family: Settings.fontFamily
                        font.pixelSize: 20
                        font.weight: 650
                        renderType: Text.NativeRendering
                        color: Theme.tertiary
                        verticalAlignment: Text.AlignVCenter
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: Qt.formatDateTime(clock.date, "dddd")
                        font.family: Settings.fontFamily
                        font.pixelSize: 20
                        font.weight: 500
                        renderType: Text.NativeRendering
                        color: Theme.secondary
                        verticalAlignment: Text.AlignBottom
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // ── Login Box ─────────────────────────────────────────
        Rectangle {
            id: loginBox
            width: 360
            height: loginLayout.implicitHeight + 40
            radius: 15
            color: Qt.rgba(0, 0, 0, 0.4)
            border.color: Theme.secondary
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: clockItem.bottom
            anchors.topMargin: 40

            ColumnLayout {
                id: loginLayout
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                AppIcon {
                    id: userIcon
                    Layout.fillWidth: true
                    name: "Nithin"
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    color: Theme.primary
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    enabled: Greetd.state !== GreetdState.Authenticating

                    background: Rectangle {
                        color: Qt.rgba(255, 255, 255, 0.1)
                        radius: 8
                        border.color: passwordField.activeFocus ? Theme.primary : Theme.secondary
                    }

                    Keys.onReturnPressed: doLogin()
                }

                Button {
                    Layout.fillWidth: true
                    text: Greetd.state === GreetdState.Authenticating ? "Authenticating…" : "Login"
                    enabled: Greetd.state !== GreetdState.Authenticating
                    onClicked: doLogin()
                }

                Text {
                    id: errorText
                    Layout.fillWidth: true
                    text: ""
                    color: Theme.secondary
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: text !== ""
                }
            }
        }
    }

    // ── Login Flow ────────────────────────────────────────────
    function doLogin() {
        if (passwordField.text === "") {
            errorText.text = "Please enter a password.";
            errorText.color = "#ff4444";
            return;
        }

        if (Greetd.state === GreetdState.Authenticating) {
            return;
        }

        if (Greetd.state === GreetdState.ReadyToLaunch) {
            Greetd.launch([root.sessionCommand]);
            return;
        }

        if (Greetd.state === GreetdState.Error) {
            Greetd.cancelSession();
            return;
        }

        errorText.text = "";
        Greetd.createSession("nithin");
    }

    Component.onCompleted: {
        passwordField.forceActiveFocus();
    }
}
