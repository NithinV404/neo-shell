import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Widgets
import qs.Services
import qs.Common
import Quickshell.Wayland

Scope {
    id: root

    enum OSDType {
        InputVolume,
        OutputVolume,
        Brightness
    }

    property int type: OSD.OSDType.OutputVolume
    property var monitor: null
    property real currentBrightness: 0
    property real maxValue: type === OSD.OSDType.OutputVolume && Settings.audio.volumeOverdrive ? 1.5 : 1.0

    Connections {
        target: AudioService

        function onVolumeChanged() {
            // ONLY show if we aren't dragging the panel slider
            if (!AudioService.consumeOutputOSDSuppression()) {
                root.open(OSD.OSDType.OutputVolume);
            }
        }

        function onMutedChanged() {
            if (!AudioService.consumeOutputOSDSuppression()) {
                root.open(OSD.OSDType.OutputVolume);
            }
        }

        function onInputVolumeChanged() {
            if (!AudioService.consumeInputOSDSuppression()) {
                root.open(OSD.OSDType.InputVolume);
            }
        }

        function onInputMutedChanged() {
            if (!AudioService.consumeInputOSDSuppression()) {
                root.open(OSD.OSDType.InputVolume);
            }
        }
    }

    Connections {
        target: BrightnessService
        function onMonitorBrightnessChanged(monitor, newBrightness) {
            root.monitor = monitor;
            root.currentBrightness = newBrightness;
            root.open(OSD.OSDType.Brightness);
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

    function open(type) {
        root.type = type;

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

    function getIcon() {
        switch (root.type) {
        case OSD.OSDType.OutputVolume:
            return AudioService.getOutputIcon(AudioService.volume);
        case OSD.OSDType.InputVolume:
            return AudioService.getInputIcon(AudioService.inputVolume);
        case OSD.OSDType.Brightness:
            return BrightnessService.getBrightnessIcon(root.currentBrightness);
        default:
            return "help";
        }
    }

    function getText() {
        switch (root.type) {
        case OSD.OSDType.OutputVolume:
            return "Volume";
        case OSD.OSDType.InputVolume:
            return "Input";
        case OSD.OSDType.Brightness:
            return "Brightness";
        default:
            return "OSD";
        }
    }

    function getValue() {
        switch (root.type) {
        case OSD.OSDType.OutputVolume:
            return AudioService.volume;
        case OSD.OSDType.InputVolume:
            return AudioService.inputVolume;
        case OSD.OSDType.Brightness:
            return root.currentBrightness;
        default:
            return 0;
        }
    }

    LazyLoader {
        id: osdLoader
        active: root.keepAlive

        PanelWindow {
            id: osdPanel
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusiveZone: 0
            implicitWidth: 260
            implicitHeight: 60
            color: "transparent"
            mask: Region {}

            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                id: osdContent
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: osdLayout.height + 20
                implicitWidth: osdLayout.width + 20
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
                            opacity: 0
                            scale: 0.8
                        }
                    },
                    State {
                        name: "opened"
                        PropertyChanges {
                            target: osdContent
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
                    id: osdLayout
                    anchors.centerIn: parent
                    spacing: 4

                    StyledText {
                        id: osdIcon
                        Layout.alignment: Qt.AlignVCenter
                        color: AudioService.muted ? Theme.surfaceVariantFg : Theme.primaryContainerFg
                        name: root.getIcon()
                        size: 28
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            // onClicked: AudioService.setOutputMuted(!AudioService.muted)
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
                                id: osdText
                                text: root.getText()
                                font.family: Settings.fontFamily
                                font.pixelSize: 16
                                color: Theme.surfaceFg
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                id: osdValue
                                text: Math.round(root.getValue() * 100)
                                font.family: Settings.fontFamily
                                font.pixelSize: 16
                                color: Theme.surfaceFg
                            }
                        }

                        LineProgress {
                            Layout.fillWidth: true
                            implicitWidth: 120
                            progress: root.getValue()
                            maxProgress: root.maxValue
                        }
                    }
                }
            }
        }
    }
}
