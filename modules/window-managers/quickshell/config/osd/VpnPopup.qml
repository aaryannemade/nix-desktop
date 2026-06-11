import QtQuick
import Quickshell
import "../theme"

PopupBase {
    id: root
    implicitWidth:  220
    borderColor:    VpnState.connected ? PanelColors.vpn : PanelColors.border
    clipContent:    true
    contentHeight:  column.implicitHeight
    autoDismiss:    false

    Connections {
        target: SessionState
        function onVpnPopupVisibleChanged() {
            root.animState = SessionState.vpnPopupVisible ? "open" : "closing"
        }
    }

    readonly property bool connected:    VpnState.connected
    readonly property bool connecting:   VpnState.connecting
    readonly property bool disconnecting: VpnState.disconnecting
    readonly property bool busy:         connecting || disconnecting

    Column {
        id: column
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: root.padding }
        spacing: 4

        // ── Toggle row ────────────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 34; radius: 6
            color: {
                let base = root.connected ? PanelColors.vpn : PanelColors.rowBackground
                return toggleMouse.containsMouse ? Qt.lighter(base, 1.15) : base
            }
            Behavior on color { ColorAnimation { duration: 150 } }

            // Left accent stripe when off
            Rectangle {
                visible: !root.connected && !root.busy
                width: 3; height: parent.height - 10; radius: 2
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                color: PanelColors.vpn
            }

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                spacing: 8

                Text {
                    text: root.connected ? "󰦝" : "󰦞"
                    font.pixelSize: 15; font.family: "JetBrainsMono Nerd Font"
                    color: root.connected ? PanelColors.pillForeground : PanelColors.textMain
                    anchors.verticalCenter: parent.verticalCenter

                    // Pulse icon when busy
                    SequentialAnimation on opacity {
                        running: root.busy
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.4; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                        onStopped: opacity = 1.0
                    }
                }

                Text {
                    text: {
                        if (root.connecting)    return "Connecting…"
                        if (root.disconnecting) return "Disconnecting…"
                        return root.connected ? "VPN On" : "VPN Off"
                    }
                    font.pixelSize: 13; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                    color: root.connected ? PanelColors.pillForeground : PanelColors.textMain
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.busy
                cursorShape: Qt.PointingHandCursor
                onClicked: VpnState.toggle()
            }
        }

        // ── Status row ────────────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 30; radius: 6
            color: "transparent"
            visible: VpnState.statusText !== ""

            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 14 }
                spacing: 6
                Text {
                    text: "󰋼"
                    font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: VpnState.statusText
                    font.pixelSize: 12; font.bold: false; font.family: "JetBrainsMono Nerd Font"
                    color: PanelColors.textDim
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
