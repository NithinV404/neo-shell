import QtQuick
import Quickshell.Io

import Qt5Compat.GraphicalEffects
import qs.Services
import qs.Widgets
import qs.Common

Item {
    id: root
    property int cellWidth: 180
    property int cellHeight: 120
    property int padding: 2
    property int spacing: 8
    property int cellSize: 100
    property int noOfCols: 4
    property int noOfRows: 3
    // GridView cellWidth includes spacing
    readonly property int gridCellWidth: cellWidth + spacing
    readonly property int gridCellHeight: cellHeight + spacing

    width: (gridCellWidth * noOfCols) - spacing
    height: (gridCellHeight * noOfRows) - spacing

    property string folderPath: Utils.resolvePath(Settings.wallpapersFolder)
    property var imageFiles: []

    Component.onCompleted: {
        root.imageFiles = Settings.wallpaperFolderImages;
    }

    Timer {
        id: wallpaperRefreshTimer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            listProcess.running = true;
        }
    }

    Process {
        id: listProcess
        command: ["sh", "-c", "ls -1 \"" + root.folderPath + "\" | grep -iE '\\.(jpg|jpeg|png|webp|gif|bmp)$'"]
        running: false

        property var tempFiles: []

        onRunningChanged: {
            if (running) {
                tempFiles = [];
            }
        }

        stdout: SplitParser {
            onRead: line => {
                const trimmed = line.trim();
                if (trimmed !== "") {
                    listProcess.tempFiles.push(root.folderPath + "/" + trimmed);
                }
            }
        }

        onExited: {
            const oldFiles = root.imageFiles ?? [];
            const newFiles = listProcess.tempFiles ?? [];
            const oldSorted = JSON.stringify([...oldFiles].sort());
            const newSorted = JSON.stringify([...newFiles].sort());

            if (oldSorted !== newSorted) {
                Settings.updateWallpaperFolderImages(tempFiles);
                root.imageFiles = Settings.wallpaperFolderImages;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: Settings.radius
    }

    GridView {
        id: gridView
        width: root.gridCellWidth * root.noOfCols
        height: root.gridCellHeight * root.noOfRows
        cellWidth: root.gridCellWidth
        cellHeight: root.gridCellHeight
        model: root.imageFiles
        cacheBuffer: 300
        clip: true
        flickDeceleration: 900        // default 1500, lower = longer glide
        maximumFlickVelocity: 2000    // default ~2500, higher = faster fling


        delegate: Rectangle {
            id: imageCell
            width: root.cellWidth
            height: root.cellHeight
            color: Theme.surfaceContainer
            radius: Settings.radius
            clip: true
            readonly property bool isSelected: decodeURIComponent(Utils.strip(Settings.wallpaperImage)) === modelData
            required property string modelData
            required property int index
            readonly property bool loading: img.status !== Image.Ready

            CacheImage {
                id: img
                maxCacheSize: 256
                anchors.fill: parent
                imagePath: imageCell.modelData
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: 0
                visible: true
            }

            Rectangle {
                id: loadingOverlay
                anchors.fill: parent
                radius: Settings.radius
                color: Theme.secondaryContainer
                opacity: imageCell.loading ? 1 : 0
                z: 2

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                StyledText {
                    id: refreshIcon
                    name: "settings"
                    color: Theme.secondaryContainerFg
                    rotation: 0
                    size: parent.height * 0.5
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                    }

                    NumberAnimation on rotation {
                        id: rotationAnim
                        running: imageCell.loading
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite

                        onRunningChanged: {
                            if (!running) {
                                refreshIcon.rotation = 0;
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: mask
                anchors.fill: img
                border.width: imageCell.isSelected ? 2 : 0
                border.color: Theme.primary
                radius: Settings.radius
                clip: true
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: img
                maskSource: mask
            }

            Rectangle {
                anchors.fill: parent
                radius: Settings.radius
                color: "transparent"
                border.width: imageCell.isSelected ? 2 : 0
                border.color: Theme.tertiary
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                propagateComposedEvents: true
                onClicked: mouse => {
                    console.log("Selected:", imageCell.modelData);
                    Settings.updateWallpaperImage("file://" + imageCell.modelData);
                    mouse.accepted = false;
                }
            }
        }
    }

    Process {
        id: wallpaperProcess
        running: false
    }
}
