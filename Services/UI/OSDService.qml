pragma Singleton

import qs.Modals
import Quickshell
import QtQuick
import qs.Services

QtObject {
    id: root
    signal open(var osdType)
    signal close
    signal toggle

    property Connections audioConnections: Connections {
        target: AudioService

        function onVolumeChanged() {
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

    // 2. Do the same for the BrightnessService Connections
    property Connections brightnessConnections: Connections {
        target: BrightnessService

        function onMonitorBrightnessChanged() {
            root.open(OSD.OSDType.Brightness);
        }
    }
}
