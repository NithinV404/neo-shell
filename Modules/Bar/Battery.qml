import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Services
import Qt5Compat.GraphicalEffects

Item {
    id: root
    required property var screen
    property bool hovered: false

    // Size it properly for a panel icon
    visible: BatteryService.primaryDevice
    width: 30
    height: 18

    Rectangle {
        id: background
        height: parent.height
        width: parent.width
        radius: width / 2
        color: {
            BatteryService.batteryPercentage < 21 ? Theme.errorContainer : Theme.primaryContainer;
        }
    }

    Item {
        id: clip
        anchors.fill: parent
        visible: false

        Rectangle {
            height: parent.height
            width: parent.width * (BatteryService.batteryPercentage) / 100
            color: {
                BatteryService.batteryPercentage < 21 ? Theme.error : Theme.primary;
            }
        }
    }

    Rectangle {
        id: mask
        color: Theme.primary
        anchors.fill: parent
        radius: width / 2
        visible: false
    }

    OpacityMask {
        anchors.fill: parent
        source: clip
        maskSource: mask
    }

    Item {
        z: 2
        width: parent.width
        height: parent.height
        RowLayout {
            spacing: 0
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            StyledText {
                id: icon
                text: BatteryService.batteryCharging ? "bolt" : BatteryService.batteryPluggedIn ? "power" : ""
                size: root.height * 0.55
                weight: 600
                filled: true
                color: BatteryService.batteryPercentage < 20 ? Theme.errorContainerFg : BatteryService.batteryPercentage > 25 ? Theme.primaryFg : Theme.primaryContainerFg
            }

            Text {
                text: BatteryService.batteryPercentage
                font.pixelSize: root.height * 0.6
                font.weight: 600
                color: {
                    if (BatteryService.batteryPercentage > 55 & icon.text != "") {
                        return Theme.primaryFg;
                    }
                    if (BatteryService.batteryPercentage > 45 && icon.text == "") {
                        return Theme.primaryFg;
                    }
                    if (BatteryService.batteryPercentage < 20) {
                        return Theme.errorContainerFg;
                    }
                    return Theme.secondaryContainerFg;
                }
            }
        }
    }
}
