import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"
import "widgets"

Pill {
    id: root

    readonly property bool isHyprland: Hyprland.requestSocketPath !== ""
    property string layoutSymbol: ""
    readonly property string layoutLabel: layoutName(layoutSymbol)

    visible: !isHyprland && layoutLabel !== ""
    pillColor: PanelColors.hashColor(layoutLabel)
    textColor: PanelColors.pillForeground
    label: layoutLabel
    minWidth: 28
    widestLabel: "horizon scroll"

    function layoutName(symbol) {
        var normalized = symbol.trim().toLowerCase()
        if (normalized === "") return ""

        var names = {
            "t": "tile",
            "tile": "tile",
            "[]=": "tile",
            "g": "grid",
            "grid": "grid",
            "###": "grid",
            "s": "horizon scroll",
            "scroller": "horizon scroll",
            "hscroll": "horizon scroll",
            "hs": "horizon scroll",
            "vs": "vertical scroll",
            "vscroller": "vertical scroll",
            "vertical_scroller": "vertical scroll",
            "d": "deck",
            "deck": "deck",
            "m": "monocle",
            "monocle": "monocle",
            "ct": "center tile",
            "center_tile": "center tile",
            "vt": "vertical tile",
            "vertical_tile": "vertical tile",
            "dw": "dwindle",
            "dwindle": "dwindle",
            "f": "floating",
            "float": "floating",
            "floating": "floating"
        }

        if (names[normalized]) return names[normalized]
        return normalized.replace(/_/g, " ")
    }

    function parseLine(line) {
        var trimmed = line.trim()
        if (trimmed.length === 0) return

        try {
            var json = JSON.parse(trimmed)
            var monitors = json["all_tags"]
            if (!monitors || monitors.length === 0) return

            var tags = monitors[0]["tags"]
            if (!tags) return

            for (var i = 0; i < tags.length; i++) {
                var tag = tags[i]
                if (tag["is_active"] === true) {
                    root.layoutSymbol = tag["layout"] || ""
                    return
                }
            }

            root.layoutSymbol = ""
        } catch (e) {
            console.warn("LayoutIndicator parse error:", e, trimmed)
        }
    }

    Process {
        id: initProc
        command: ["mmsg", "get", "all-tags"]
        running: !root.isHyprland
        stdout: SplitParser { onRead: (line) => root.parseLine(line) }
    }

    Process {
        id: watchProc
        command: ["mmsg", "watch", "all-tags"]
        running: !root.isHyprland
        onRunningChanged: if (!running && !root.isHyprland) watchRestartTimer.start()
        stdout: SplitParser { onRead: (line) => root.parseLine(line) }
    }

    Timer {
        id: watchRestartTimer
        interval: 1000
        onTriggered: if (!root.isHyprland) watchProc.running = true
    }
}
