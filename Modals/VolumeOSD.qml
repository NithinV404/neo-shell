import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.Components
import qs.Services
import qs.Common

Scope {
    id: root

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio

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
            exclusiveZone: 0
            implicitWidth: 260
            implicitHeight: 90
            color: "transparent"
            mask: Region {}

            Rectangle {
                id: osdContent
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: volumeOSDLayout.height + 20
                implicitWidth: volumeOSDLayout.width + 20
                color: Theme.getColor("surface")
                radius: 12
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
                    spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitHeight: 48
                        implicitWidth: 48
                        color: Theme.getColor("surface_container_highest")
                        radius: 24

                        StyledText {
                            anchors.centerIn: parent
                            color: AudioService.muted ? Theme.getColor("on_surface_variant") : Theme.getColor("on_primary_container")
                            name: AudioService.getOutputIcon()
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.toggleMute()
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 160
                        Layout.alignment: Qt.AlignVCenter
                        value: (Pipewire.defaultAudioSink?.audio.volume ?? 0) * 100
                        minValue: 0
                        maxValue: Settings.audioVolumeOverdrive ? 150 : 100
                        showValue: true
                    }
                }
            }
        }
    }
}
