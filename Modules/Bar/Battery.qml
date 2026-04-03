import QtQuick
import qs.Widgets
import qs.Services
import qs.Common

Rectangle {
    id: root
    required property var screen

    // Size it properly for a panel icon
    visible: BatteryService
    implicitWidth: 30
    implicitHeight: 30
    color: Theme.surfaceContainerHighest
    radius: 100

    WavyCircle {
        id: batteryWave
        anchors.fill: parent
        lineWidth: 1.5
        waveHeight: 1
        frequency: 10
        animate: BatteryService.batteryPluggedIn || BatteryService.batteryCharging
        degree: BatteryService.batteryPercentage * 3.6
        color: BatteryService.batteryPercentage < 30 ? Theme.error : Theme.primary

        // The Icon inside the WavyCircle
        StyledText {
            anchors.centerIn: parent
            text: BatteryService.batteryIcon
            size: 16
            color: batteryWave.color // Matches the ring color
        }
    }
}
