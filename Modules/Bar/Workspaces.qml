import QtQuick
import QtQuick.Layouts
import qs.Services

Rectangle {
    id: root

    property string screenName: ""

    // Store the sorted list
    property var currentWsList: NiriService.allWorkspaces.filter(ws => ws.output === root.screenName).sort((a, b) => a.idx - b.idx)

    // Track the currently active delegate item for the slider
    property Item activeItem: null

    implicitWidth: workspaceRow.width + 10
    implicitHeight: 40
    color: "transparent"
    radius: 24

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutBack
        }
    }

    Rectangle {
        id: slidingIndicator
        z: 2
        x: root.activeItem ? (workspaceRow.x + root.activeItem.x) : 0
        y: workspaceRow.y

        width: root.activeItem ? root.activeItem.width : 0
        height: 24
        radius: 24
        color: Theme.primary

        Rectangle {
            width: 4
            height: 4
            radius: 2
            anchors.centerIn: parent

            color: Theme.primaryFg

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
            }
        }
    }

    RowLayout {
        id: workspaceRow
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: root.currentWsList

            delegate: Item {
                id: delegateItem

                required property var modelData
                required property int index

                readonly property bool isFocused: modelData.is_focused

                // Update the parent's tracker when this item becomes focused
                onIsFocusedChanged: if (isFocused)
                    root.activeItem = delegateItem
                Component.onCompleted: if (isFocused)
                    root.activeItem = delegateItem

                implicitWidth: 24
                implicitHeight: 24

                Layout.leftMargin: isFocused ? 2 : 0
                Layout.rightMargin: isFocused ? 2 : 0

                Behavior on Layout.leftMargin {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on Layout.rightMargin {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }

                readonly property bool prevIsInactive: index > 0 && !root.currentWsList[index - 1].is_focused
                readonly property bool nextIsInactive: index < root.currentWsList.length - 1 && !root.currentWsList[index + 1].is_focused

                readonly property int rLeft: (!isFocused && prevIsInactive) ? 0 : 12
                readonly property int rRight: (!isFocused && nextIsInactive) ? 0 : 12

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surfaceContainerHighest

                    opacity: delegateItem.isFocused ? 0 : 1

                    topLeftRadius: delegateItem.rLeft
                    bottomLeftRadius: delegateItem.rLeft
                    topRightRadius: delegateItem.rRight
                    bottomRightRadius: delegateItem.rRight

                    Behavior on topLeftRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on topRightRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on bottomLeftRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on bottomRightRadius {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    anchors.centerIn: parent

                    color: Theme.surfaceVariantFg

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NiriService.switchToWorkspace(delegateItem.modelData.idx)
                }
            }
        }
    }
}
