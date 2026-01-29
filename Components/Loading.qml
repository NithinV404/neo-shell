import QtQuick

Item {
    id: root

    // API
    property int size: 24          // total height
    property int dotSize: 6
    property int gap: 5
    property color dotColor: "#6750A4" // primary
    property bool running: true

    // timing
    property int period: 700       // ms for a full cycle
    property int stagger: 120      // ms between dots

    implicitHeight: size
    implicitWidth: dotSize * 3 + gap * 2

    Repeater {
        model: 3

        delegate: Rectangle {
            width: root.dotSize
            height: root.dotSize
            radius: root.dotSize / 2
            color: root.dotColor

            x: index * (root.dotSize + root.gap)
            y: (root.size - root.dotSize) / 2

            // start "small and dim"
            scale: 0.7
            opacity: 0.55

            SequentialAnimation {
                running: root.running && root.visible
                loops: Animation.Infinite

                // phase offset per dot
                PauseAnimation {
                    duration: index * root.stagger
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: parent
                        property: "scale"
                        to: 1.15
                        duration: root.period * 0.25
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: parent
                        property: "opacity"
                        to: 1.0
                        duration: root.period * 0.25
                        easing.type: Easing.OutCubic
                    }
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: parent
                        property: "scale"
                        to: 0.7
                        duration: root.period * 0.35
                        easing.type: Easing.InOutCubic
                    }
                    NumberAnimation {
                        target: parent
                        property: "opacity"
                        to: 0.55
                        duration: root.period * 0.35
                        easing.type: Easing.InOutCubic
                    }
                }

                // rest of the cycle (keeps period consistent)
                PauseAnimation {
                    duration: root.period * 0.40
                }
            }
        }
    }
}
