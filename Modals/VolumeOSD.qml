import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Widgets
import qs.Services
import qs.Common
import Quickshell.Wayland

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio ?? null

        function onVolumeChanged() {
            root.open();
        }
        function onMutedChanged() {
            root.open();
        }
    }

    property bool shouldShowOsd: false
    property bool animating: false
    property bool keepAlive: shouldShowOsd || animating

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.close()
    }

    function open() {
        if (!osdLoader.active) {
            animating = true;
            shouldShowOsd = false;
            Qt.callLater(() => {
                shouldShowOsd = true;
            });
        } else {
            shouldShowOsd = true;
        }

        hideTimer.restart();
    }

    function close() {
        root.animating = true;
        root.shouldShowOsd = false;
    }

    LazyLoader {
        id: osdLoader
        active: root.keepAlive

        PanelWindow {
            id: volumeOSDPanel
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusiveZone: 0
            implicitWidth: 260
            implicitHeight: 90
            color: "transparent"
            mask: Region {}

            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                id: osdContent
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: volumeOSDLayout.height + 20
                implicitWidth: volumeOSDLayout.width + 20
                color: Theme.surface
                radius: Settings.radius
                layer.enabled: true

                // Use panel's isOpen for state
                state: root.shouldShowOsd ? "opened" : "closed"

                states: [
                    State {
                        name: "closed"
                        PropertyChanges {
                            target: osdContent
                            y: 0
                            opacity: 0
                            scale: 0.9
                        }
                    },
                    State {
                        name: "opened"
                        PropertyChanges {
                            target: osdContent
                            y: 10
                            opacity: 1
                            scale: 1
                        }
                    }
                ]

                transitions: [
                    Transition {
                        id: openAnim
                        from: "closed"
                        to: "opened"
                        NumberAnimation {
                            properties: "y,opacity,scale"
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                        onRunningChanged: root.animating = openAnim.running || closeAnim.running
                    },
                    Transition {
                        id: closeAnim
                        from: "opened"
                        to: "closed"
                        NumberAnimation {
                            properties: "y,opacity,scale"
                            duration: 200
                            easing.type: Easing.InCubic
                        }
                        onRunningChanged: root.animating = openAnim.running || closeAnim.running
                    }
                ]

                RowLayout {
                    id: volumeOSDLayout
                    anchors.centerIn: parent
                    spacing: 4
                    property real volume: (Pipewire.defaultAudioSink?.audio.volume ?? 0)

                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        color: AudioService.muted ? Theme.surfaceVariantFg : Theme.primaryContainerFg
                        name: AudioService.getOutputIcon()
                        size: 28
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.toggleMute()
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 4
                        RowLayout {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter

                            Text {
                                text: "Volume"
                                font.family: Settings.fontFamily
                                font.pixelSize: 16
                                color: Theme.surfaceFg
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Math.floor(volumeOSDLayout.volume * 100)
                                font.family: Settings.fontFamily
                                font.pixelSize: 16
                                color: Theme.surfaceFg
                            }
                        }

                        LineProgress {
                            Layout.fillWidth: true
                            implicitWidth: 120
                            progress: volumeOSDLayout.volume
                        }
                    }
                }
            }
        }
    }
}
