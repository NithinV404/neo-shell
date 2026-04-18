import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Widgets
import qs.Services
import qs.Common

Item {
    id: root
    signal goBack
    implicitHeight: 400
    implicitWidth: 350

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 12
    }

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: 12
            bottomMargin: 12
        }

        // --- Header ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: Settings.radius
            color: Theme.surfaceContainerHighest

            RowLayout {
                anchors {
                    leftMargin: 4
                    rightMargin: 4
                    fill: parent
                }

                Rectangle {
                    id: backButton
                    implicitWidth: 35
                    implicitHeight: 35
                    radius: Settings.radius
                    color: !backButtonHover.containsMouse ? Theme.primary : Qt.darker(Theme.primary)

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    StyledText {
                        name: "chevron_backward"
                        anchors.centerIn: parent
                        color: Theme.primaryFg
                    }

                    MouseArea {
                        id: backButtonHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.goBack()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "Audio"
                    color: Theme.surfaceFg
                    font.family: Settings.fontFamily
                    font.pixelSize: 16
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }

        // --- Volume Overdrive Card ---
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            Layout.topMargin: 8
            implicitHeight: overdriveRow.implicitHeight + 20
            radius: Settings.radius

            color: Settings.audio.volumeOverdrive ? Qt.alpha(Theme.primary, 0.13) : Theme.surfaceContainerHighest

            border.width: Settings.audio.volumeOverdrive ? 1 : 0
            border.color: Qt.alpha(Theme.primary, 0.5)

            Behavior on color {
                ColorAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            HoverHandler {
                id: overdriveHover
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: overdriveHover.hovered ? Qt.alpha(Theme.primary, 0.06) : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            RowLayout {
                id: overdriveRow
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 10
                    bottomMargin: 10
                }

                Rectangle {
                    implicitWidth: 42
                    implicitHeight: 42
                    radius: Settings.radius
                    color: Settings.audio.volumeOverdrive ? Theme.primary : Theme.surfaceContainerHighest

                    Behavior on color {
                        ColorAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        name: Settings.audio.volumeOverdrive ? "volume_up" : "volume_down"
                        color: Settings.audio.volumeOverdrive ? Theme.primaryFg : Qt.darker(Theme.primary)
                        size: 20

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Volume Overdrive"
                        color: Theme.surfaceFg
                        font.family: Settings.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }

                    Text {
                        text: Settings.audio.volumeOverdrive ? "Allows volume above 100%" : "Volume limited to 100%"
                        color: Qt.alpha(Theme.surfaceFg, 0.6)
                        font.family: Settings.fontFamily
                        font.pixelSize: 11
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Toggle {
                    checked: Settings.audio.volumeOverdrive
                    onToggled: Settings.setVolumeOverdrive(!Settings.audio.volumeOverdrive)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.setVolumeOverdrive(!Settings.audio.volumeOverdrive)
            }
        }

        // --- Divider ---
        Rectangle {
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: parent.width - 40
            implicitHeight: 1
            color: Qt.alpha(Theme.primary, 0.25)
            radius: 100
        }

        // --- Empty State ---
        HelpInfo {
            visible: !AudioService.sinks.length === 0 || !AudioService.sources.length === 0
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            icon: "devices_off"
            title: "No Devices Found"
        }

        // --- Scrollable Content ---
        Flickable {
            id: contentFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: width
            contentHeight: scrollableContent.implicitHeight

            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ScrollBar.vertical: ScrollBar {
                policy: contentFlickable.contentHeight > contentFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: scrollableContent
                width: parent.width
                spacing: 8

                // --- OUTPUT DEVICES SECTION (SINKS) ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: AudioService.sinks.length > 0

                    Text {
                        visible: AudioService.sinks.length > 0
                        Layout.leftMargin: 8
                        color: Qt.darker(Theme.primary)
                        font.family: Settings.fontFamily
                        text: "Audio Output Devices"
                        font.pixelSize: 12
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        visible: AudioService.sinks.length > 0
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2

                        Repeater {
                            id: audioSinksRepeater
                            model: AudioService.sinks

                            delegate: Rectangle {
                                id: audioDevicesSinkDelegate

                                required property int index
                                required property var modelData

                                property bool isStart: index === 0
                                property bool isLast: index === audioSinksRepeater.count - 1
                                property bool isActive: modelData.id == AudioService.sink.id

                                width: parent.width
                                clip: true

                                implicitHeight: devicesLayout.implicitHeight + 20

                                Behavior on implicitHeight {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                topLeftRadius: isStart ? 24 : 4
                                topRightRadius: isStart ? 24 : 4
                                bottomLeftRadius: isLast ? 24 : 4
                                bottomRightRadius: isLast ? 24 : 4

                                // Selected background color like Volume Overdrive
                                color: {
                                    if (isActive) {
                                        return Qt.alpha(Theme.primary, 0.13);  // Same as Volume Overdrive active
                                    }
                                    return sinksHoverHandler.hovered ? Qt.lighter(Theme.surfaceContainerHighest, 1.1) : Theme.surfaceContainerHighest;
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                // Hover overlay for non-selected state
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: sinksHoverHandler.hovered && !audioDevicesSinkDelegate.isActive ? Qt.alpha(Theme.primary, 0.06) : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: devicesLayout
                                    anchors.fill: parent
                                    anchors.margins: 12

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 4
                                        Layout.rightMargin: 12
                                        spacing: 12

                                        HoverHandler {
                                            id: sinksHoverHandler
                                            onHoveredChanged: {
                                                // Only update hover color if not active
                                                if (!isActive) {
                                                    audioDevicesSinkDelegate.color = hovered ? Qt.lighter(Theme.surfaceContainerHighest, 1.1) : Theme.surfaceContainerHighest;
                                                }
                                            }
                                        }

                                        TapHandler {
                                            onTapped: AudioService.setAudioSink(audioDevicesSinkDelegate.modelData)
                                        }

                                        // Icon container with dynamic color
                                        Rectangle {
                                            implicitWidth: 42
                                            implicitHeight: 42
                                            radius: Settings.radius
                                            color: isActive ? Theme.primary : Theme.surfaceContainerHighest

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }
                                            }

                                            StyledText {
                                                name: "speaker"
                                                anchors.centerIn: parent
                                                color: isActive ? Theme.primaryFg : Theme.primary
                                                size: 20

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 200
                                                    }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                Layout.fillWidth: true
                                                text: audioDevicesSinkDelegate.modelData.nickname || "Unknown Device"
                                                color: isActive ? Theme.primary : Theme.surfaceFg
                                                font.pixelSize: 14
                                                font.family: Settings.fontFamily
                                                font.weight: isActive ? Font.Medium : Font.Normal
                                                elide: Text.ElideRight

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: audioDevicesSinkDelegate.modelData.name
                                                color: isActive ? Qt.alpha(Theme.primary, 0.7) : Qt.lighter(Theme.surfaceFg)
                                                font.pixelSize: 11

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: audioDevicesSinkDelegate.modelData.description
                                                color: isActive ? Qt.alpha(Theme.primary, 0.7) : Qt.lighter(Theme.surfaceFg)
                                                font.pixelSize: 11

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        id: sinkSliderRow
                                        clip: true
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 4
                                        Layout.rightMargin: 12
                                        Layout.preferredHeight: isActive ? implicitHeight : 0
                                        opacity: isActive ? 1.0 : 0.0

                                        Behavior on Layout.preferredHeight {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 40
                                            Layout.preferredWidth: 40
                                            color: isActive ? Qt.alpha(Theme.primary, 0.2) : Theme.secondaryContainer
                                            radius: Settings.radius

                                            StyledText {
                                                anchors.centerIn: parent
                                                color: AudioService.muted ? Theme.surfaceVariantFg : (isActive ? Theme.primary : Theme.primaryContainerFg)
                                                name: AudioService.getOutputIcon()
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: AudioService.setOutputMuted(!AudioService.muted)
                                            }
                                        }

                                        Slider {
                                            containerBackground: Theme.secondaryFg
                                            Layout.fillWidth: true
                                            value: AudioService.volume * 100
                                            textColorFilled: Theme.primaryFg
                                            textColorUnfilled: isActive ? Qt.alpha(Theme.primary, 0.7) : Theme.secondaryContainerFg
                                            implicitHeight: 52
                                            minValue: 0
                                            maxValue: Settings.audio.volumeOverdrive ? 150 : 100
                                            icon: ""
                                            showValue: true
                                            onMoved: newValue => AudioService.setVolume(newValue / 100)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --- INPUT DEVICES SECTION (SOURCES) ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: AudioService.sources.length > 0

                    Text {
                        visible: AudioService.sources.length > 0
                        Layout.leftMargin: 8
                        color: Qt.darker(Theme.primary)
                        font.family: Settings.fontFamily
                        text: "Audio Input Devices"
                        font.pixelSize: 12
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2
                        visible: AudioService.sources.length > 0

                        Repeater {
                            id: audioSourcesRepeater
                            model: AudioService.sources

                            delegate: Rectangle {
                                id: audioDevicesDelegate

                                required property int index
                                required property var modelData

                                property bool isStart: index === 0
                                property bool isLast: index === audioSourcesRepeater.count - 1
                                property bool isActive: modelData.id == AudioService.source.id

                                width: parent.width
                                clip: true

                                implicitHeight: inputdevicesLayout.implicitHeight + 20

                                Behavior on implicitHeight {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                topLeftRadius: isStart ? 24 : 4
                                topRightRadius: isStart ? 24 : 4
                                bottomLeftRadius: isLast ? 24 : 4
                                bottomRightRadius: isLast ? 24 : 4

                                // Selected background color like Volume Overdrive
                                color: {
                                    if (isActive) {
                                        return Qt.alpha(Theme.primary, 0.13);
                                    }
                                    return sourcesHoverHandler.containsMouse ? Qt.lighter(Theme.surfaceContainerHighest, 1.1) : Theme.surfaceContainerHighest;
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                // Hover overlay for non-selected state
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: sourcesHoverHandler.containsMouse && !isActive ? Qt.alpha(Theme.primary, 0.06) : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }

                                ColumnLayout {
                                    id: inputdevicesLayout
                                    anchors.fill: parent
                                    anchors.margins: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12

                                        HoverHandler {
                                            id: sourcesHoverHandler
                                            onHoveredChanged: {
                                                if (!isActive) {
                                                    audioDevicesDelegate.color = hovered ? Qt.lighter(Theme.surfaceContainerHighest, 1.1) : Theme.surfaceContainerHighest;
                                                }
                                            }
                                        }

                                        TapHandler {
                                            onTapped: AudioService.setAudioSource(modelData)
                                        }

                                        // Icon container with dynamic color
                                        Rectangle {
                                            implicitWidth: 42
                                            implicitHeight: 42
                                            radius: Settings.radius
                                            color: isActive ? Theme.primary : Theme.surfaceContainerHighest

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 200
                                                }
                                            }

                                            StyledText {
                                                name: "mic"
                                                anchors.centerIn: parent
                                                color: isActive ? Theme.primaryFg : Theme.primary
                                                size: 20

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 200
                                                    }
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                Layout.fillWidth: true
                                                text: audioDevicesDelegate.modelData.nickname || "Unknown Device"
                                                color: isActive ? Theme.primary : Theme.surfaceFg
                                                font.pixelSize: 14
                                                font.family: Settings.fontFamily
                                                font.weight: isActive ? Font.Medium : Font.Normal
                                                elide: Text.ElideRight

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: audioDevicesDelegate.modelData.name
                                                color: isActive ? Qt.alpha(Theme.primary, 0.7) : Qt.lighter(Theme.surfaceFg)
                                                font.pixelSize: 11

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: audioDevicesDelegate.modelData.description
                                                color: isActive ? Qt.alpha(Theme.primary, 0.7) : Qt.lighter(Theme.surfaceFg)
                                                font.pixelSize: 11

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        id: sourceSliderRow
                                        clip: true
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 4
                                        Layout.rightMargin: 12
                                        Layout.preferredHeight: isActive ? implicitHeight : 0
                                        opacity: isActive ? 1.0 : 0.0

                                        Behavior on Layout.preferredHeight {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 150
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 40
                                            Layout.preferredWidth: 40
                                            color: isActive ? Qt.alpha(Theme.primary, 0.2) : Theme.secondaryContainer
                                            radius: Settings.radius

                                            StyledText {
                                                anchors.centerIn: parent
                                                color: AudioService.inputMuted ? Theme.surfaceVariantFg : (isActive ? Theme.primary : Theme.primaryContainerFg)
                                                name: AudioService.getInputIcon()
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: AudioService.setInputMuted(!AudioService.inputMuted)
                                            }
                                        }

                                        Slider {
                                            containerBackground: Theme.secondaryFg
                                            Layout.fillWidth: true
                                            value: AudioService.inputVolume * 100
                                            textColorFilled: Theme.primaryFg
                                            textColorUnfilled: isActive ? Qt.alpha(Theme.primary, 0.7) : Theme.secondaryContainerFg
                                            implicitHeight: 52
                                            minValue: 0
                                            maxValue: Settings.audio.volumeOverdrive ? 150 : 100
                                            icon: ""
                                            showValue: true
                                            onMoved: newValue => AudioService.setInputVolume(newValue / 100)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
