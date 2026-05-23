import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Widgets
import qs.Services
import qs.Common
import Quickshell.Wayland

PanelWindow {
    id: root
    signal menuClosed

    onKeepAliveChanged: {
        if (!keepAlive && isOpen) {
            isOpen = false;
            root.menuClosed();
        }
    }

    required property var screen

    enum OSDType {
        InputVolume,
        OutputVolume,
        Brightness
    }

    property int type: OSD.OSDType.OutputVolume
    property var monitor: null
    property real currentBrightness: 0
    property real maxValue: type === OSD.OSDType.OutputVolume && Settings.audio.volumeOverdrive ? 1.5 : 1.0
    property bool isOpen: false
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
        root.isOpen = true;

        shouldShowOsd = true;
        animating = true;

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
            return BrightnessService.getBrightnessIcon(BrightnessService.getMonitorForScreen(root.screen).brightness);
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
            return BrightnessService.getMonitorForScreen(root.screen).brightness;
        default:
            return 0;
        }
    }

    anchors.bottom: true
    anchors.right: true
    exclusiveZone: 0
    implicitWidth: 150
    implicitHeight: 150
    color: "transparent"
    mask: Region {}

    WlrLayershell.layer: WlrLayer.Overlay

    Item {
        anchors.centerIn: parent
        width: 100
        height: 100

        Rectangle {
            id: osdContent
            anchors.fill: parent
            color: Theme.surface
            scale: root.shouldShowOsd ? 1 : 0
            opacity: root.shouldShowOsd ? 1 : 0
            radius: height / 2

            WavyCircle {
                anchors.fill: parent
                value: root.getValue()
                maxValue: Settings.audio.volumeOverdrive ? 1.5 : 1
                color: root.getValue() < 1 ? Theme.primary : "red"
                lineWidth: 4
                waveHeight: 2
                animate: false
                frequency: 0
                startDegree: 180
                degree: 270

                Text {
                    text: Math.floor(root.getValue() * 100)
                    color: Theme.tertiary
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    font.pixelSize: 18
                    font.weight: 800
                    font.family: Settings.fontFamily
                    anchors.leftMargin: 1
                    anchors.bottomMargin: 8
                }
            }

            StyledText {
                anchors.centerIn: parent
                size: parent.height * 0.6
                text: root.getIcon()
                color: Theme.secondary
            }

            Behavior on opacity {
                NumberAnimation {
                    easing.type: Easing.OutBack
                    duration: 300
                }
            }

            Behavior on scale {
                NumberAnimation {
                    easing.type: Easing.OutBack
                    duration: 300
                }
            }
        }
    }
}
