pragma Singleton

import QtQuick

QtObject {
    property QtObject animation: QtObject {
        function ripple(parent, x, y) {
            var qml = Qt.createQmlObject(`import QtQuick
            Rectangle {
                anchors.centerIn: parent
                width: 0; height: 0; radius: width/2
                color: Qt.lighter(parent.color);
                opacity: 0.3

                Component.onCompleted: {
                    width = parent.width
                    height = parent.width
                    opacity = 0
                    destroy(400)
                }

                Behavior on width { NumberAnimation { duration: 400 } }
                Behavior on height { NumberAnimation { duration: 400 } }
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }`, parent);
        }
    }
}
