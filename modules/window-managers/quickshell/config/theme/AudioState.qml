pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ── AudioState ────────────────────────────────────────────────────────────────
// Single source of truth for PipeWire audio state.
// All mutations go through wpctl and periodic refreshes keep properties in sync.
Singleton {
    id: root

    // ── Public State ──────────────────────────────────────────────────────────
    property bool   popupVisible:  false
    property var    sinks:         []
    property var    sources:       []
    property int    defaultSink:   -1
    property int    defaultSource: -1
    property int    volume:        0
    property bool   muted:         false
    property int    micVolume:     0
    property bool   micMuted:      false

    function parseNodeId(text) {
        const match = text.match(/id\s+(\d+),/)
        return match ? parseInt(match[1], 10) : -1
    }

    function parseVolume(text) {
        const match = text.match(/Volume:\s+([0-9]*\.?[0-9]+)/)
        if (!match) return null
        return Math.max(0, Math.min(100, Math.round(parseFloat(match[1]) * 100)))
    }

    function parseMute(text) {
        return text.includes("[MUTED]")
    }

    function refreshSoon() {
        mutationRefreshTimer.restart()
    }

    // ── Popup Control ─────────────────────────────────────────────────────────
    function show() {
        SessionState.closeAllPopups()
        refreshAll()
        popupVisible = true
    }

    function hide() {
        popupVisible = false
    }

    // ── Refresh Helpers ───────────────────────────────────────────────────────
    // Each helper restarts the process regardless of whether it is already
    // running, so that callers always get a fresh read.

    function refreshSinks() {
        devicesProc.running = false
        devicesProc.running = true
    }

    function refreshSinkState() {
        defaultSinkProc.running = false
        defaultSinkProc.running = true
        volProc.running = false
        volProc.running = true
        muteProc.running = false
        muteProc.running = true
    }

    function refreshSources() {
        devicesProc.running = false
        devicesProc.running = true
    }

    function refreshSourceState() {
        defaultSourceProc.running = false
        defaultSourceProc.running = true
        micVolProc.running = false
        micVolProc.running = true
        micMuteProc.running = false
        micMuteProc.running = true
    }

    function refreshAll() {
        refreshSinks()
        refreshSinkState()
        refreshSourceState()
    }

    // ── Mutations ─────────────────────────────────────────────────────────────
    // Keep reads authoritative, but schedule a short refresh after each write so
    // the UI responds quickly without depending on a subscription process.

    function setDefaultSink(id) {
        Quickshell.execDetached(["wpctl", "set-default", id.toString()])
        refreshSoon()
    }

    function setDefaultSource(id) {
        Quickshell.execDetached(["wpctl", "set-default", id.toString()])
        refreshSoon()
    }

    function setVolume(newVol) {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", newVol + "%"])
        refreshSoon()
    }

    function setMicVolume(newVol) {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", newVol + "%"])
        refreshSoon()
    }

    function setMute(mute) {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", mute ? "1" : "0"])
        refreshSoon()
    }

    function setMicMute(mute) {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", mute ? "1" : "0"])
        refreshSoon()
    }

    Timer {
        id: mutationRefreshTimer
        interval: 120
        repeat: false
        onTriggered: root.refreshAll()
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.refreshAll()
    }

    // ── Device lists ──────────────────────────────────────────────────────────
    Process {
        id: devicesProc
        command: ["pw-dump"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const entries = JSON.parse(text)
                    const sinks = []
                    const sources = []

                    for (const entry of entries) {
                        if (entry.type !== "PipeWire:Interface:Node") continue

                        const props = entry.info && entry.info.props ? entry.info.props : null
                        if (!props) continue

                        const mediaClass = props["media.class"]
                        const name = props["node.name"] || ""
                        if (name.includes(".monitor")) continue

                        const device = {
                            id: entry.id,
                            name: name,
                            description: props["node.description"] || props["node.nick"] || name
                        }

                        if (mediaClass === "Audio/Sink") sinks.push(device)
                        if (mediaClass === "Audio/Source") sources.push(device)
                    }

                    root.sinks = sinks
                    root.sources = sources
                } catch (error) {
                    root.sinks = []
                    root.sources = []
                }
            }
        }
    }

    // ── Default sink / source ─────────────────────────────────────────────────
    Process {
        id: defaultSinkProc
        command: ["wpctl", "inspect", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.defaultSink = root.parseNodeId(text)
        }
    }

    Process {
        id: defaultSourceProc
        command: ["wpctl", "inspect", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.defaultSource = root.parseNodeId(text)
        }
    }

    // ── Volume ────────────────────────────────────────────────────────────────
    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const value = root.parseVolume(text)
                if (value !== null) root.volume = value
            }
        }
    }

    // ── Mute ──────────────────────────────────────────────────────────────────
    Process {
        id: muteProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.muted = root.parseMute(text)
        }
    }

    // ── Mic volume ────────────────────────────────────────────────────────────
    Process {
        id: micVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const value = root.parseVolume(text)
                if (value !== null) root.micVolume = value
            }
        }
    }

    // ── Mic mute ──────────────────────────────────────────────────────────────
    Process {
        id: micMuteProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.micMuted = root.parseMute(text)
        }
    }
}
