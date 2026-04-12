import QtQuick
import qs.Widgets
import qs.Services

Rectangle {
    id: root
    required property var screen

    // Size it properly for a panel icon
    visible: BatteryService
    implicitWidth: 30
    implicitHeight: 28
    color: Theme.surfaceContainer
    radius: 100

    WavyCircle {
        id: batteryWave
        anchors.fill: parent
        lineWidth: 1.5
        waveHeight: 1
        frequency: 10
        animate: false
        degree: BatteryService.batteryPercentage * 3.6
        color: BatteryService.batteryPercentage < 30 ? Theme.error : Theme.primary

        Connections {
            target: BatteryService
            function onBatteryPluggedInChanged() {
                batteryWave.animate = true;
                waveAnimateTimer.restart();  // Use start() instead of restart()
            }

            function onBatteryChargingChanged() {
                batteryWave.animate = true;
                waveAnimateTimer.restart();
            }
        }

        Timer {
            id: waveAnimateTimer
            interval: 5000
            running: false
            onTriggered: {
                batteryWave.animate = false;
            }
        }

        // The Icon inside the WavyCircle
        StyledText {
            anchors.centerIn: parent
            text: BatteryService.batteryIcon
            size: 16
            color: batteryWave.color // Matches the ring color
        }
    }
}
