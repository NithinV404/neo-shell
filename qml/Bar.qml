import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Shell.Services
import Shell.Widgets

PanelWindow {
    id: root
    visible: true // Changed to true so the layer shell surface actually maps/shows

    // --- LayerShell Configuration ---
    layer: PanelWindow.Top
    // Stretch across the top of the screen
    anchors: PanelWindow.AnchorTop | PanelWindow.AnchorLeft | PanelWindow.AnchorRight
    // Reserve space at the top so windows don't hide behind it
    exclusionZone: 32
    // Only take keyboard focus when interacted with (or PanelWindow.None if you don't want focus at all)
    keyboardInteractivity: PanelWindow.OnDemand

    color: "transparent" // Window background transparent so Rectangle handles the drawing

    // Width is ignored because anchors Left and Right stretch it automatically.
    width: 400
    height: 32   // Must have a height! LayerShell Top/Left/Right anchors don't set height.

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
