import Quickshell
import Quickshell.Wayland
import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import qs.Services
import qs.Components
import qs.Common

Scope {
    id: root
    property bool visible: false
    property bool isVisible: false
    property var items: [
        {
            name: "Shutdown",
            icon: "power_settings_new"
        },
        {
            name: "Restart",
            icon: "restart_alt"
        },
        {
            name: "Sleep",
            icon: "bedtime"
        },
        {
            name: "Suspend",
            icon: "pause"
        },
        {
            name: "Log Out",
            icon: "logout"
        }
    ]

    function doAction(name) {
        switch (name) {
        case "Shutdown":
            SessionService.poweroff();
            break;
        case "Restart":
            SessionService.reboot();
            break;
        case "Log out":
            SessionService.logout();
            break;
        case "Suspend":
            SessionService.suspend();
            break;
        case "Hibernate":
            SessionService.hibernate();
            break;
        }
    }

    Component.onCompleted: {
        if (SessionService.hibernateSupported) {
            root.items.push({
                name: "Hibernate",
                icon: "timelapse"
            });
        }
    }

    function toggle() {
        if (root.visible) {
            close();
        } else {
            open();
        }
    }

    function open() {
        root.isVisible = true;
    }

    function close() {
        root.visible = false;
    }

    IpcHandler {
        target: "wlogout"

        function toggleWlogoutMenu() {
            root.toggle();
        }

        function showWLogout() {
            root.open();
        }

        function hideWLogout() {
            root.close();
        }
    }

    LazyLoader {
        id: osdLoader
        active: root.isVisible

        PanelWindow {
            id: wLogoutMenu

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: {
                root.visible = true;
            }

            color: Qt.rgba(0, 0, 0, root.visible ? 0.5 : 0.0)

            Behavior on color {
                ColorAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            // Main focusable container
            Item {
                id: keyHandler
                anchors.fill: parent
                focus: true

                Component.onCompleted: {
                    forceActiveFocus();
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.close();
                        event.accepted = true;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => {
                        keyHandler.forceActiveFocus();
                        const p = mapToItem(logoutMenuContainer, mouse.x, mouse.y);
                        const inside = p.x >= 0 && p.x <= logoutMenuContainer.width && p.y >= 0 && p.y <= logoutMenuContainer.height;
                        if (!inside)
                            root.close();
                    }
                }

                Rectangle {
                    id: logoutMenuContainer
                    anchors.centerIn: parent
                    implicitHeight: root.visible ? (root.items.length * 50) + 40 : 0
                    implicitWidth: 300
                    color: Theme.getColor("surface")
                    radius: 12
                    clip: true

                    Behavior on implicitHeight {
                        SequentialAnimation {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                            ScriptAction {
                                script: {
                                    if (!root.visible) {
                                        root.isVisible = false;
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: itemColumn
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4
                        Repeater {
                            model: root.items
                            delegate: Rectangle {
                                id: buttonDelegate
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                color: Theme.getColor("surface_container_highest")
                                radius: 12

                                property real progress: 0.0

                                Item {
                                    id: progressContainer
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * buttonDelegate.progress
                                    clip: true

                                    Rectangle {
                                        id: progressBar
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: buttonDelegate.width
                                        color: Theme.getColor("primary")
                                        opacity: 0.8
                                        radius: 12
                                    }
                                }

                                NumberAnimation {
                                    id: progressAnimation
                                    target: buttonDelegate
                                    property: "progress"
                                    easing.type: Easing.Linear
                                }

                                function startFilling() {
                                    progressAnimation.stop();
                                    progressAnimation.from = buttonDelegate.progress;
                                    progressAnimation.to = 1.0;
                                    progressAnimation.duration = (1.0 - buttonDelegate.progress) * 1500;
                                    progressAnimation.easing.type = Easing.Linear;
                                    progressAnimation.start();
                                }

                                function startEmptying() {
                                    progressAnimation.stop();
                                    progressAnimation.from = buttonDelegate.progress;
                                    progressAnimation.to = 0.0;
                                    progressAnimation.duration = buttonDelegate.progress * 600;
                                    progressAnimation.easing.type = Easing.OutCubic;
                                    progressAnimation.start();
                                }

                                Connections {
                                    target: progressAnimation
                                    function onFinished() {
                                        if (buttonDelegate.progress >= 1.0) {
                                            root.doAction(buttonDelegate.modelData.name);
                                            root.close();
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12
                                    width: parent.width

                                    StyledText {
                                        name: modelData.icon
                                        font.pixelSize: 24
                                        color: Theme.getColor("on_surface")
                                        Layout.leftMargin: 12
                                    }

                                    Text {
                                        text: modelData.name
                                        color: Theme.getColor("on_surface")
                                        font.pixelSize: 14
                                        font.family: Settings.fontFamily
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: "Hold"
                                        color: Theme.getColor("on_surface")
                                        font.pixelSize: 10
                                        opacity: 0.6
                                        font.family: Settings.fontFamily
                                        Layout.rightMargin: 12
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onDoubleClicked: {
                                        root.doAction(buttonDelegate.modelData.name);
                                    }

                                    onPressed: {
                                        buttonDelegate.startFilling();
                                    }

                                    onReleased: {
                                        buttonDelegate.startEmptying();
                                    }

                                    onCanceled: {
                                        buttonDelegate.startEmptying();
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
