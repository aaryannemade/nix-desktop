import QtQuick
import Quickshell
import "../../theme"

Pill {
    id: root
    hoverReveal: true
    forceReveal: SessionState.vpnPopupVisible

    readonly property bool connected:    VpnState.connected
    readonly property bool connecting:   VpnState.connecting
    readonly property bool disconnecting: VpnState.disconnecting
    readonly property bool busy:         connecting || disconnecting

    label: {
        if (connected)      return "󰦝 VPN"
        if (connecting)     return "󰦝 …"
        if (disconnecting)  return "󰦞 …"
        return "󰦞 Off"
    }

    pillColor: connected ? PanelColors.vpn : PanelColors.rowBackground
    textColor: connected ? PanelColors.pillForeground : PanelColors.textMain

    // Subtle pulsing opacity when busy
    SequentialAnimation on opacity {
        running: root.busy
        loops: Animation.Infinite
        NumberAnimation { to: 0.5; duration: 600; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
        onStopped: root.opacity = 1.0
    }

    mouseArea.onClicked: function(mouse) {
        if (SessionState.vpnPopupVisible) {
            SessionState.vpnPopupVisible = false
        } else {
            SessionState.closeAllPopups()
            SessionState.vpnPopupVisible = true
        }
        mouse.accepted = false
    }
}
