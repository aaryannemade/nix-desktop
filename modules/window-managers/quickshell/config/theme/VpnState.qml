pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Public state ──────────────────────────────────────────────────────
    property bool connected:    false
    property bool connecting:   false
    property bool disconnecting: false
    property string statusText: "Disconnected"

    // ── Connect ───────────────────────────────────────────────────────────
    function connect() {
        if (connected || connecting) return
        root.connecting   = true
        root.statusText   = "Connecting…"
        connectProc.running = false
        connectProc.running = true
    }

    // ── Disconnect ────────────────────────────────────────────────────────
    function disconnect() {
        if (!connected || disconnecting) return
        root.disconnecting = true
        root.statusText    = "Disconnecting…"
        disconnectProc.running = false
        disconnectProc.running = true
    }

    // ── Toggle ────────────────────────────────────────────────────────────
    function toggle() {
        if (connected)   disconnect()
        else             connect()
    }

    // ── Check current state by probing the process list ──────────────────
    function checkState() {
        checkProc.running = false
        checkProc.running = true
    }

    // ── Processes ─────────────────────────────────────────────────────────

    Process {
        id: connectProc
        command: ["protonvpn", "connect", "--country", "DE"]
        running: false
        onExited: function(code) {
            root.connecting = false
            if (code === 0) {
                root.connected  = true
                root.statusText = "Connected"
            } else {
                root.connected  = false
                root.statusText = "Failed to connect"
                // Reset error text after 4 s
                errorResetTimer.restart()
            }
        }
    }

    Process {
        id: disconnectProc
        command: ["protonvpn", "disconnect"]
        running: false
        onExited: function(code) {
            root.disconnecting = false
            root.connected     = false
            root.statusText    = "Disconnected"
        }
    }

    // Probe VPN state via `protonvpn status`
    Process {
        id: checkProc
        command: ["protonvpn", "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.connecting && !root.disconnecting) {
                    root.connected = text.indexOf("Connected") !== -1
                    root.statusText = root.connected ? "Connected" : "Disconnected"
                }
            }
        }
    }

    // Poll state every 10 s to stay in sync with external changes
    Timer {
        id: pollTimer
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.checkState()
    }

    // Reset error text after 4 s
    Timer {
        id: errorResetTimer
        interval: 4000
        onTriggered: root.statusText = "Disconnected"
    }

    Component.onCompleted: root.checkState()
}
