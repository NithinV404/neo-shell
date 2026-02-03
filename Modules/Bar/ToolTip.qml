import Quickshell
import QtQuick
import qs.Services

PanelWindow {
    id: root
    property alias x: root.x
    property alias y: root.y
    property alias text: root.text

    WlrLayershell.layer: WlrLayer.Overlay

    Component.onCompleted: {}

    Rectangle {
        implicitWidth: root.text.length * 2
        implicitHeight: root.text
        color: Theme.primaryContainer
        border: Theme.primaryContainerFg
    }
}
