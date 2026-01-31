pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Common

Singleton {
    id: root

    // Devices
    readonly property PwNode sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property PwNode source: validatedSource
    readonly property bool hasInput: !!source
    readonly property list<PwNode> sinks: deviceNodes.sinks
    readonly property list<PwNode> sources: deviceNodes.sources

    readonly property real epsilon: 0.005

    // Output Volume - read directly from device
    readonly property real volume: {
        if (!sink?.audio)
            return 0;
        const vol = sink.audio.volume;
        if (vol === undefined || isNaN(vol))
            return 0;
        const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;
        return Math.max(0, Math.min(maxVolume, vol));
    }
    readonly property bool muted: sink?.audio?.muted ?? true

    // Input Volume - read directly from device
    readonly property real inputVolume: {
        if (!source?.audio)
            return 0;
        const vol = source.audio.volume;
        if (vol === undefined || isNaN(vol))
            return 0;
        const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;
        return Math.max(0, Math.min(maxVolume, vol));
    }
    readonly property bool inputMuted: source?.audio?.muted ?? true

    signal micMuteChanged

    // Allow callers to skip the next OSD notification when they are already
    // presenting volume state (e.g. the Audio Panel UI). We track this as a short
    // time window so suppression applies to every monitor, not just the first one
    // that receives the signal.
    property double outputOSDSuppressedUntilMs: 0
    property double inputOSDSuppressedUntilMs: 0

    function suppressOutputOSD(durationMs = 400) {
        const target = Date.now() + durationMs;
        outputOSDSuppressedUntilMs = Math.max(outputOSDSuppressedUntilMs, target);
    }

    function suppressInputOSD(durationMs = 400) {
        const target = Date.now() + durationMs;
        inputOSDSuppressedUntilMs = Math.max(inputOSDSuppressedUntilMs, target);
    }

    function consumeOutputOSDSuppression(): bool {
        return Date.now() < outputOSDSuppressedUntilMs;
    }

    function consumeInputOSDSuppression(): bool {
        return Date.now() < inputOSDSuppressedUntilMs;
    }

    readonly property real stepVolume: Settings.audioVolumeStep / 100.0

    // Filtered device nodes (non-stream sinks and sources)
    readonly property var deviceNodes: Pipewire.ready ? Pipewire.nodes.values.reduce((acc, node) => {
        if (!node.isStream) {
            if (node.isSink) {
                acc.sinks.push(node);
            } else if (node.audio) {
                acc.sources.push(node);
            }
        }
        return acc;
    }, {
        "sources": [],
        "sinks": []
    }) : {
        "sources": [],
        "sinks": []
    }

    // Validated source (ensures it's a proper audio source, not a sink)
    readonly property PwNode validatedSource: {
        if (!Pipewire.ready) {
            return null;
        }
        const raw = Pipewire.defaultAudioSource;
        if (!raw || raw.isSink || !raw.audio) {
            return null;
        }
        // Optional: check type if available (type reflects media.class per docs)
        if (raw.type && typeof raw.type === "string" && !raw.type.startsWith("Audio/Source")) {
            return null;
        }
        return raw;
    }

    // Internal state for feedback loop prevention
    property bool isSettingOutputVolume: false
    property bool isSettingInputVolume: false

    // Bind default sink and source to ensure their properties are available
    PwObjectTracker {
        id: sinkTracker
        objects: root.sink ? [root.sink] : []
    }

    PwObjectTracker {
        id: sourceTracker
        objects: root.source ? [root.source] : []
    }

    // Bind all devices to ensure their properties are available
    PwObjectTracker {
        objects: [...root.sinks, ...root.sources]
    }

    // Watch output device changes for clamping
    Connections {
        target: sink?.audio ?? null

        function onVolumeChanged() {
            // Ignore volume changes if we're the one setting it (to prevent feedback loop)
            if (root.isSettingOutputVolume) {
                return;
            }

            if (!root.sink?.audio) {
                return;
            }

            const vol = root.sink.audio.volume;
            if (vol === undefined || isNaN(vol)) {
                return;
            }

            const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;

            // If volume exceeds max, clamp it (but only if we didn't just set it)
            if (vol > maxVolume) {
                root.isSettingOutputVolume = true;
                Qt.callLater(() => {
                    if (root.sink?.audio && root.sink.audio.volume > maxVolume) {
                        root.sink.audio.volume = maxVolume;
                    }
                    root.isSettingOutputVolume = false;
                });
            }
        }
    }

    // Watch input device changes for clamping
    Connections {
        target: source?.audio ?? null

        function onMutedChanged() {
            root.micMuteChanged();
        }

        function onVolumeChanged() {
            // Ignore volume changes if we're the one setting it (to prevent feedback loop)
            if (root.isSettingInputVolume) {
                return;
            }

            if (!root.source?.audio) {
                return;
            }

            const vol = root.source.audio.volume;
            if (vol === undefined || isNaN(vol)) {
                return;
            }

            const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;

            // If volume exceeds max, clamp it (but only if we didn't just set it)
            if (vol > maxVolume) {
                root.isSettingInputVolume = true;
                Qt.callLater(() => {
                    if (root.source?.audio && root.source.audio.volume > maxVolume) {
                        root.source.audio.volume = maxVolume;
                    }
                    root.isSettingInputVolume = false;
                });
            }
        }
    }

    // Output Control
    function increaseVolume() {
        if (!Pipewire.ready || !sink?.audio) {
            return;
        }
        const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;
        if (volume >= maxVolume) {
            return;
        }
        setVolume(Math.min(maxVolume, volume + stepVolume));
    }

    function decreaseVolume() {
        if (!Pipewire.ready || !sink?.audio) {
            return;
        }
        if (volume <= 0) {
            return;
        }
        setVolume(Math.max(0, volume - stepVolume));
    }

    function setVolume(newVolume: real) {
        if (!Pipewire.ready || !sink?.ready || !sink?.audio) {
            return;
        }

        const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;
        const clampedVolume = Math.max(0, Math.min(maxVolume, newVolume));
        const delta = Math.abs(clampedVolume - sink.audio.volume);
        if (delta < root.epsilon) {
            return;
        }

        // Set flag to prevent feedback loop, then set the actual volume
        isSettingOutputVolume = true;
        sink.audio.muted = false;
        sink.audio.volume = clampedVolume;

        // Clear flag after a short delay to allow external changes to be detected
        Qt.callLater(() => {
            isSettingOutputVolume = false;
        });

        root.volumeChanged();
    }

    function setOutputMuted(muted: bool) {
        if (!Pipewire.ready || !sink?.audio) {
            return "No sink available or Pipewire not ready";
        }

        sink.audio.muted = muted;
        return muted ? "Audio muted" : "Audio unmuted";
    }

    function getOutputIcon() {
        if (muted)
            return "volume_off";

        const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;
        const clampedVolume = Math.max(0, Math.min(volume, maxVolume));

        // Show volume_off icon when volume is effectively 0% (within rounding threshold)
        if (clampedVolume < root.epsilon) {
            return "volume_off";
        }
        if (clampedVolume <= 0.5) {
            return "volume_down";
        }
        return "volume_up";
    }

    // Input Control
    function increaseInputVolume() {
        if (!Pipewire.ready || !source?.audio) {
            return;
        }
        const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;
        if (inputVolume >= maxVolume) {
            return;
        }
        setInputVolume(Math.min(maxVolume, inputVolume + stepVolume));
    }

    function decreaseInputVolume() {
        if (!Pipewire.ready || !source?.audio) {
            return;
        }
        setInputVolume(Math.max(0, inputVolume - stepVolume));
    }

    function setInputVolume(newVolume: real) {
        if (!Pipewire.ready || !source?.ready || !source?.audio) {
            return;
        }

        const maxVolume = Settings.audioVolumeOverdrive ? 1.5 : 1.0;
        const clampedVolume = Math.max(0, Math.min(maxVolume, newVolume));
        const delta = Math.abs(clampedVolume - source.audio.volume);
        if (delta < root.epsilon) {
            return;
        }

        // Set flag to prevent feedback loop, then set the actual volume
        isSettingInputVolume = true;
        source.audio.muted = false;
        source.audio.volume = clampedVolume;

        // Clear flag after a short delay to allow external changes to be detected
        Qt.callLater(() => {
            isSettingInputVolume = false;
        });
    }

    function setInputMuted(muted: bool) {
        if (!Pipewire.ready || !source?.audio) {
            return "No source available or Pipewire not ready";
        }

        source.audio.muted = muted;
        return muted ? "Microphone muted" : "Microphone unmuted";
    }

    function getInputIcon() {
        if (inputMuted || inputVolume <= Number.EPSILON) {
            return "mic";
        }
        return "mic_off";
    }

    // Device Selection
    function setAudioSink(newSink: PwNode): void {
        if (!Pipewire.ready) {
            return;
        }
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        if (!Pipewire.ready) {
            return;
        }
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function displayName(node) {
        if (!node) {
            return "";
        }

        if (node.properties && node.properties["device.description"]) {
            return node.properties["device.description"];
        }

        if (node.description && node.description !== node.name) {
            return node.description;
        }

        if (node.nickname && node.nickname !== node.name) {
            return node.nickname;
        }

        if (node.name.includes("analog-stereo")) {
            return "Built-in Speakers";
        }
        if (node.name.includes("bluez")) {
            return "Bluetooth Audio";
        }
        if (node.name.includes("usb")) {
            return "USB Audio";
        }
        if (node.name.includes("hdmi")) {
            return "HDMI Audio";
        }

        return node.name;
    }

    // Legacy function names for backwards compatibility
    function toggleMute() {
        if (!root.sink?.audio) {
            return "No audio sink available";
        }

        root.sink.audio.muted = !root.sink.audio.muted;
        return root.sink.audio.muted ? "Audio muted" : "Audio unmuted";
    }

    function setMicVolume(percentage) {
        return setInputVolume(percentage / 100.0);
    }

    function toggleMicMute() {
        if (!root.source?.audio) {
            return "No audio source available";
        }

        root.source.audio.muted = !root.source.audio.muted;
        return root.source.audio.muted ? "Microphone muted" : "Microphone unmuted";
    }

    IpcHandler {
        target: "audio"

        function setvolume(percentage: string): string {
            return root.setVolume(parseInt(percentage));
        }

        function increment(step: string): string {
            if (!root.sink?.audio) {
                return "No audio sink available";
            }

            if (root.sink.audio.muted) {
                root.sink.audio.muted = false;
            }

            const currentVolume = Math.round(root.sink.audio.volume * 100);
            const stepValue = parseInt(step || "5");
            const newVolume = Math.max(0, Math.min(100, currentVolume + stepValue));

            root.sink.audio.volume = newVolume / 100;
            root.volumeChanged();
            return `Volume increased to ${newVolume}%`;
        }

        function decrement(step: string): string {
            if (!root.sink?.audio) {
                return "No audio sink available";
            }

            if (root.sink.audio.muted) {
                root.sink.audio.muted = false;
            }

            const currentVolume = Math.round(root.sink.audio.volume * 100);
            const stepValue = parseInt(step || "5");
            const newVolume = Math.max(0, Math.min(100, currentVolume - stepValue));

            root.sink.audio.volume = newVolume / 100;
            root.volumeChanged();
            return `Volume decreased to ${newVolume}%`;
        }

        function mute(): string {
            const result = root.toggleMute();
            root.volumeChanged();
            return result;
        }

        function setmic(percentage: string): string {
            return root.setMicVolume(parseInt(percentage));
        }

        function micmute(): string {
            const result = root.toggleMicMute();
            root.micMuteChanged();
            return result;
        }

        function status(): string {
            let result = "Audio Status:\n";

            if (root.sink?.audio) {
                const volume = Math.round(root.sink.audio.volume * 100);
                const muteStatus = root.sink.audio.muted ? " (muted)" : "";
                result += `Output: ${volume}%${muteStatus}\n`;
            } else {
                result += "Output: No sink available\n";
            }

            if (root.source?.audio) {
                const micVolume = Math.round(root.source.audio.volume * 100);
                const muteStatus = root.source.audio.muted ? " (muted)" : "";
                result += `Input: ${micVolume}%${muteStatus}`;
            } else {
                result += "Input: No source available";
            }

            return result;
        }
    }
}
