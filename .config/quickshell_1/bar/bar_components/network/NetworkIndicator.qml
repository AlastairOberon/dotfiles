import QtQuick
import Quickshell
import Quickshell.Io 
import "../../bar_components" // Assuming you want it themed!

Item {
    id: netContainer
    width: netRow.width + 10
    height: 30
    
    property var parentWindow
    
    // Logic state variables
    property bool isAirplane: false
    property bool isDisconnected: false
    property bool isEthernet: false
    property int signal: 100
    property string downSpeed: "0 KB/s"
    property string upSpeed: "0 KB/s"
    property real lastRx: 0
    property real lastTx: 0

    // Background process to grab raw network data
    Process {
        id: netStats
        command: ["bash", "-c", "
            # 1. Check Airplane Mode
            # THE FIX: Assume Airplane mode is ON (1), but if we find even ONE radio 
            # that is 'Soft blocked: no', we immediately know it's OFF (0).
            airplane=1
            if rfkill list | grep -q 'Soft blocked: no'; then airplane=0; fi

            # 2. Get the active internet interface
            dev=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'dev \\K\\w+' | head -n1)
            
            # If totally offline, output states and exit immediately
            if [ -z \"$dev\" ]; then 
                echo \"$airplane|0|0|0|0|1\"
                exit 
            fi
            
            # 3. The foolproof Wi-Fi check
            is_wifi=0
            if [ -d \"/sys/class/net/$dev/wireless\" ]; then
                is_wifi=1
            fi
            
            # 4. Total bytes downloaded and uploaded (fallback to 0 if error)
            rx=$(cat /sys/class/net/$dev/statistics/rx_bytes 2>/dev/null || echo 0)
            tx=$(cat /sys/class/net/$dev/statistics/tx_bytes 2>/dev/null || echo 0)
            
            # 5. Get Wi-Fi signal percentage if on Wi-Fi
            sig=100
            if [ \"$is_wifi\" -eq 1 ]; then
                sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | grep '^\\*' | cut -d: -f2)
                [ -z \"$sig\" ] && sig=0
            fi
            
            # Output: airplane | is_wifi | signal | rx | tx | is_disconnected
            echo \"$airplane|$is_wifi|$sig|$rx|$tx|0\"
        "]
        
        stdout: SplitParser {
            onRead: function(data) {
                let parts = data.split('|');
                if (parts.length < 6) return;
                
                netContainer.isAirplane = (parts[0] === "1");
                netContainer.isEthernet = (parts[1] === "0");
                netContainer.signal = parseInt(parts[2]);
                let nowRx = parseInt(parts[3]);
                let nowTx = parseInt(parts[4]);
                netContainer.isDisconnected = (parts[5] === "1");

                // Safely calculate speed or lock to zero
                if (netContainer.isDisconnected) {
                    netContainer.downSpeed = "0 KB/s";
                    netContainer.upSpeed = "0 KB/s";
                    netContainer.lastRx = 0;
                    netContainer.lastTx = 0;
                } else {
                    if (netContainer.lastRx > 0) {
                        // Failsafe: if the interface restarts, rx/tx drops back to 0. 
                        // This prevents negative numbers!
                        if (nowRx >= netContainer.lastRx && nowTx >= netContainer.lastTx) {
                            netContainer.downSpeed = Math.round((nowRx - netContainer.lastRx) / 2048) + " KB/s";
                            netContainer.upSpeed = Math.round((nowTx - netContainer.lastTx) / 2048) + " KB/s";
                        } else {
                            netContainer.downSpeed = "0 KB/s";
                            netContainer.upSpeed = "0 KB/s";
                        }
                    }
                    netContainer.lastRx = nowRx;
                    netContainer.lastTx = nowTx;
                }
            }
        }
    }

    // Trigger the process every 2 seconds
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: netStats.running = true
    }

    // Run once immediately on startup
    Component.onCompleted: netStats.running = true

    MouseArea {
        anchors.fill: parent
        onClicked: netPopup.toggle()
    }

    Row {
        id: netRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            // Icon Priority: Airplane -> Disconnected -> Ethernet -> Wi-Fi signal
            text: {
                if (isAirplane) return "󰀝";
                if (isDisconnected) return "󰤮";
                if (isEthernet) return "󰈀";
                return signal > 75 ? "󰤨" : (signal > 50 ? "󰤥" : (signal > 25 ? "󰤢" : "󰤯"));
            }
            color: Theme.main 
            font.pixelSize: 16
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            Text { text: "▼ " + downSpeed; color: Theme.secondary; font.pixelSize: 9 }
            Text { text: "▲ " + upSpeed; color: Theme.secondary; font.pixelSize: 9 }
        }
    }

    NetworkPopup {
        id: netPopup
        parentWindow: netContainer.parentWindow
        anchorTarget: netContainer
    }
}
