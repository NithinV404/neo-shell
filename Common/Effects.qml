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
                    height = Math.max(parent.width, parent.height)
                    opacity = 0
                    destroy(400)
                }

                Behavior on width { NumberAnimation { duration: 400 } }
                Behavior on height { NumberAnimation { duration: 400 } }
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }`, parent);
        }
    }
    property QtObject blur: QtObject {
        function createBlurRegion(targetWindow) {
            if (!targetWindow)
                return null;

            try {
                const region = Qt.createQmlObject(`
                import Quickshell
                Region {}
            `, targetWindow, "BlurRegion");
                targetWindow.BackgroundEffect.blurRegion = region;
                return region;
            } catch (e) {
                console.warn("Failed to create blur region:", e);
                return null;
            }
        }

        function reapplyBlurRegion()
        {
             if (!region || !available)
                return;
            try {
                targetWindow.BackgroundEffect.blurRegion = region;
                region.changed();
            } catch (e) {}
        }

        function destroyBlurRegion(targetWindow, region)
        {
            if(!region)
                return 
            try 
            {
                targetWindow.BackgroundEffect.blurRegion = null 
            }
            catch(e){}
            region.destroy();
        }
    }
}
