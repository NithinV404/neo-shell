import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Shell.Services
import Shell.Widgets

PanelWindow {
    id: root
    visible: true
    layer: PanelWindow.Top
    anchors: PanelWindow.AnchorTop | PanelWindow.AnchorLeft | PanelWindow.AnchorRight
    exclusionZone: 32
    keyboardInteractivity: PanelWindow.None
    color: "transparent"
    height: 32

    Rectangle {
        id: bar
        anchors.fill: parent
        radius: 12
        color: Theme.surface
        border.width: 1
        border.color: Theme.primary

        RowLayout {
            id: workspaceRow
            spacing: 10
            anchors.fill: parent
            Layout.margins: 4

            ListView {
                id: workspaceListView
                Layout.leftMargin: 8
                Layout.preferredWidth: contentItem.childrenRect.width
                Layout.preferredHeight: parent.height - 8
                orientation: ListView.Horizontal
                spacing: 4

                model: NiriWorkspaces

                delegate: Rectangle {
                    width: 20
                    height: 22
                    radius: 4
                    color: model.isActive ? Theme.tertiary : Theme.surfaceContainerHighest

                    Text {
                        anchors.centerIn: parent
                        text: model.wsIndex
                        color: model.isActive ? Theme.onTertiary : Theme.onSurface
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                Layout.preferredHeight: 20
                Layout.rightMargin: 8
                color: Theme.surface

                Text {
                    width: 400
                    text: NiriWorkspaces.focusedWindowTitle || " "
                    font.family: "Adwaita Sans"
                    font.pixelSize: 12
                    color: Theme.onSurface
                    elide: Text.ElideRight
                    renderType: Text.QtRendering
                }
            }

            Clock {
                id: clock
                height: 30
            }
        }
    }
}
