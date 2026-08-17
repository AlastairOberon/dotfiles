import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".." // Imports Theme and BlueprintPopup from the bar_components folder!

BlueprintPopup {
    id: netPopup
    
    // --- 1. CONFIGURE THE BLUEPRINT ---
    popupWidth: 280
    popupHeight: 350
    isTopBar: true
    //barOverlap: 0
    
    property var networkList: []
    
    // Active UI States
    property bool wifiEnabled: true
    property bool airplaneMode: false

    // --- 2. HOOK INTO BLUEPRINT SIGNALS ---
    onAboutToOpen: {
        checkRadioProcess.running = true;
        scanProcess.running = true;
        wifiList.expandedSsid = ""; 
    }

    Timer {
        id: refreshTimer
        interval: 2000 
        repeat: true
        running: netPopup.visible && wifiList.expandedSsid === ""
        onTriggered: {
            checkRadioProcess.running = true;
            scanProcess.running = true;
        }
    }

    // --- LOGIC: Check Radio States ---
    Process {
        id: checkRadioProcess
        command: [
            "bash", 
            "-c", 
            "echo $(nmcli radio wifi); rfkill list | grep -q 'Soft blocked: no' && echo 'disabled' || echo 'enabled'"
        ]
        stdout: SplitParser {
            onRead: function(data) {
                let lines = data.trim().split('\n');
                if (lines.length >= 2) {
                    netPopup.wifiEnabled = (lines[0] === "enabled");
                    netPopup.airplaneMode = (lines[1] === "enabled");
                }
            }
        }
    }

    // --- LOGIC: Toggle Wi-Fi ---
    Process {
        id: toggleWifiProcess
        onExited: checkRadioProcess.running = true 
    }

    // --- LOGIC: Toggle Airplane Mode (ISOLATION & MEMORY) ---
    Process {
        id: toggleAirplaneProcess
        onExited: checkRadioProcess.running = true
    }

    // --- LOGIC: Disconnect Active Wi-Fi ---
    Process {
        id: disconnectProcess
        property string targetSsid: ""
        // Tries to disconnect by name. If that fails, aggressively disconnects the active Wi-Fi device directly!
        command: [
            "bash", 
            "-c", 
            "nmcli connection down id \"" + targetSsid + "\" || nmcli device disconnect $(nmcli -t -f DEVICE,TYPE dev | grep wifi | cut -d: -f1 | head -n1)"
        ]
        onExited: {
            checkRadioProcess.running = true;
            scanProcess.running = true;
        }
    }

    // --- LOGIC: Scan Wi-Fi ---
    Process {
        id: scanProcess
        command: ["bash", "-c", "nmcli -t -f IN-USE,SIGNAL,FREQ,SECURITY,SSID dev wifi list | tr '\n' '|'"]
        stdout: SplitParser {
            onRead: function(data) {
                let lines = data.split('|');
                let tempMap = {};

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.length === 0) continue;

                    let parts = line.split(':');
                    if (parts.length >= 5) {
                        let activeFlag = parts.shift();
                        let sig = parseInt(parts.shift());
                        let freq = parts.shift();
                        let sec = parts.shift();
                        
                        let ssid = parts.join(':').trim();
                        ssid = ssid.replace(/\\:/g, ':'); 
                        let active = (activeFlag === '*');

                        if (ssid.length > 0) {
                            if (!tempMap[ssid]) {
                                tempMap[ssid] = { "ssid": ssid, "signal": sig, "active": active, "freq": freq, "sec": sec };
                            } else {
                                if (sig > tempMap[ssid].signal) {
                                    tempMap[ssid].signal = sig;
                                    tempMap[ssid].freq = freq;
                                    tempMap[ssid].sec = sec;
                                }
                                if (active) tempMap[ssid].active = true;
                            }
                        }
                    }
                }

                let finalArray = [];
                for (let key in tempMap) { finalArray.push(tempMap[key]); }
                finalArray.sort(function(a, b) { return b.signal - a.signal; });
                netPopup.networkList = finalArray;
            }
        }
    }

    Process {
        id: termConnectProcess
        property string targetSsid: ""
        
        command: [
            "ghostty", 
            "-e", 
            "bash", 
            "-c", 
            "echo 'Connecting to: " + targetSsid + "'; nmcli --ask dev wifi connect \"" + targetSsid + "\"; echo; read -p 'Press Enter to close...'"
        ]
    }

    // ==========================================
    // --- 3. UI CONTENT ---
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // --- TOP TOGGLE BAR ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            Layout.minimumHeight: 40 
            Layout.maximumHeight: 40
            spacing: 10

            // --- WI-FI TOGGLE ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 5

                    Text {
                        text: "󰤨 Wi-Fi"
                        color: Theme.text
                        font.bold: true
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 36; height: 20; radius: 10
                        color: netPopup.wifiEnabled ? Theme.main : Theme.secondaryBase
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: Theme.base
                            y: 2
                            x: netPopup.wifiEnabled ? 18 : 2
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                MouseArea {
                    id: wifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let targetState = !netPopup.wifiEnabled;
                        netPopup.wifiEnabled = targetState;
                        
                        toggleWifiProcess.running = false;
                        toggleWifiProcess.command = ["nmcli", "radio", "wifi", targetState ? "on" : "off"];
                        toggleWifiProcess.running = true;
                    }
                }
                
                Rectangle { anchors.fill: parent; radius: 6; color: Theme.secondaryBase; opacity: wifiMouse.containsMouse ? 0.3 : 0 }
            }

            // --- AIRPLANE MODE TOGGLE ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 5

                    Text {
                        text: "󰀝 Airplane"
                        color: Theme.text
                        font.bold: true
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 36; height: 20; radius: 10
                        color: netPopup.airplaneMode ? Theme.urgent : Theme.secondaryBase
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: Theme.base
                            y: 2
                            x: netPopup.airplaneMode ? 18 : 2
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                MouseArea {
                    id: airplaneMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let targetState = !netPopup.airplaneMode;
                        netPopup.airplaneMode = targetState;
                        
                        let cmd = "";
                        if (targetState) {
                            cmd = "nmcli radio wifi > /tmp/.qs_wifi_state; (bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off) > /tmp/.qs_bt_state; rfkill block all";
                        } else {
                            cmd = "rfkill unblock all; sleep 0.5; nmcli radio wifi $(cat /tmp/.qs_wifi_state 2>/dev/null || echo on); bluetoothctl power $(cat /tmp/.qs_bt_state 2>/dev/null || echo on)";
                        }

                        toggleAirplaneProcess.running = false;
                        toggleAirplaneProcess.command = ["bash", "-c", cmd];
                        toggleAirplaneProcess.running = true;
                    }
                }
                
                Rectangle { anchors.fill: parent; radius: 6; color: Theme.secondaryBase; opacity: airplaneMouse.containsMouse ? 0.3 : 0 }
            }
        }

        // Horizontal Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.secondaryBase
        }

        // --- NETWORK LIST ---
        Text { 
            text: netPopup.wifiEnabled ? "Available Networks" : "Wi-Fi is Disabled"
            color: Theme.text
            font.bold: true 
        }

        ListView {
            id: wifiList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: netPopup.networkList
            clip: true
            spacing: 5
            
            property string expandedSsid: ""
            
            delegate: Rectangle {
                id: delegateRect
                width: wifiList.width
                
                property bool isExpanded: wifiList.expandedSsid === modelData.ssid
                
                height: isExpanded ? 90 : 35
                
                color: modelData.active ? Theme.main : "transparent"
                radius: 4
                clip: true
                Behavior on height { NumberAnimation { duration: 150 } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 5
                    
                    // 1. HEADER ROW
                    Item {
                        width: parent.width
                        height: 25
                        
                        Text { 
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 35
                            text: modelData.ssid
                            color: modelData.active ? Theme.base : Theme.text
                            font.pixelSize: 12
                            font.bold: modelData.active
                            elide: Text.ElideRight
                        }
                        
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.signal + "%"
                            color: modelData.active ? Theme.base : Theme.inactive
                            font.pixelSize: 10
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (wifiList.expandedSsid === modelData.ssid) {
                                    wifiList.expandedSsid = ""; 
                                } else {
                                    wifiList.expandedSsid = modelData.ssid; 
                                }
                            }
                        }
                    }
                    
                    // 2. EXPANDED DETAILS
                    Item {
                        width: parent.width
                        height: 50
                        visible: delegateRect.isExpanded
                        opacity: delegateRect.isExpanded ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        
                        Column {
                            anchors.fill: parent
                            spacing: 8
                            
                            Text {
                                text: "Sec: " + modelData.sec + "  |  Freq: " + modelData.freq
                                color: modelData.active ? Theme.secondaryBase : Theme.inactive
                                font.pixelSize: 10
                            }
                            
                            // --- THE CONNECT / DISCONNECT BUTTON ---
                            Rectangle {
                                width: parent.width
                                height: 25
                                radius: 4
                                // Color logic: Turns Theme.urgent (Red) if active, Theme.secondary (Blue/Base) if inactive. Also lights up on hover!
                                color: mouseAreaConnect.containsMouse 
                                    ? (modelData.active ? Qt.lighter(Theme.urgent, 1.1) : Qt.lighter(Theme.secondary, 1.1)) 
                                    : (modelData.active ? Theme.urgent : Theme.secondary)
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.active ? "Disconnect" : "Connect"
                                    color: Theme.base
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                                
                                MouseArea {
                                    id: mouseAreaConnect
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.active) {
                                            // Trigger the new Disconnect Process
                                            disconnectProcess.targetSsid = modelData.ssid;
                                            disconnectProcess.running = true;
                                            wifiList.expandedSsid = "";
                                        } else {
                                            // Trigger the existing Terminal Connect Process
                                            termConnectProcess.targetSsid = modelData.ssid;
                                            termConnectProcess.running = true;
                                            netPopup.toggle(); 
                                            wifiList.expandedSsid = "";
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
