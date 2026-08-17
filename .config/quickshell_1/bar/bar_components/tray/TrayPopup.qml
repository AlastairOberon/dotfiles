import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import ".." 

BlueprintPopup {
    id: root

    // --- 1. CONFIGURE THE BLUEPRINT ---
    popupWidth: 250
    // FIX: A fixed height prevents the Wayland compositor from panicking 
    popupHeight: 450 
    isTopBar: false 
    //barOverlap: 0
    //timeoutDuration: 0

    // --- 2. LOGIC ---
    Process {
        id: killProcess
        // Command injected directly on click to avoid race condition
    }

    // --- 3. UI CONTENT ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        ListView {
            id: trayList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5
            model: SystemTray.items
            clip: true
            property string expandedId: ""

            // Forces a 100px buffer when no apps are present
            footer: Item {
                width: trayList.width
                height: trayList.count === 0 ? 100 : 0
                visible: trayList.count === 0
                
                Text {
                    anchors.centerIn: parent
                    text: "No hidden apps"
                    color: Theme.inactive
                    font.pixelSize: 13
                }
            }

            delegate: Column {
                id: delegateRect
                width: trayList.width
                property string appId: modelData.id || modelData.title || index.toString()
                property bool isExpanded: trayList.expandedId === appId

                // Prevents child elements from bleeding into the next row when shrinking
                clip: true

                // Added 5px spacing so the buttons aren't touching the top row
                spacing: 5

                // Top row (40) + Spacing (5) + Bottom row (30) = 75 perfectly
                height: isExpanded ? 75 : 40
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                // Top row (icon + name)
                Item {
                    width: parent.width; height: 40

                    // Isolated the background to animate Opacity instead of Color
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Theme.secondaryBase
                        opacity: (delegateRect.isExpanded || mouseArea.containsMouse) ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 8; spacing: 12
                        Image {
                            Layout.preferredWidth: 20; Layout.preferredHeight: 20
                            source: modelData.icon; fillMode: Image.PreserveAspectFit; smooth: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.title || modelData.id || "Unknown App"
                            color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight
                        }
                        Text {
                            text: delegateRect.isExpanded ? "󰅀" : "󰅁"
                            color: Theme.inactive; font.pixelSize: 16
                        }
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: trayList.expandedId = delegateRect.isExpanded ? "" : delegateRect.appId
                    }
                }

                // Expanded actions
                RowLayout {
                    width: parent.width; height: 30; spacing: 10
                    opacity: delegateRect.isExpanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    // --- OPEN BUTTON ---
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                        color: mouseAreaOpen.containsMouse ? Qt.lighter(Theme.secondary, 1.1) : Theme.secondary
                        Text { anchors.centerIn: parent; text: "Open"; color: Theme.base; font.bold: true; font.pixelSize: 12 }
                        
                        MouseArea { 
                            id: mouseAreaOpen
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { 
                                modelData.activate(); 
                                if (typeof root.toggle === "function") {
                                    root.toggle();
                                } else {
                                    root.visible = false;
                                }
                            } 
                        }
                    }

                    // --- KILL BUTTON ---
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                        color: mouseAreaKill.containsMouse ? Qt.lighter(Theme.urgent, 1.1) : Theme.urgent
                        Text { anchors.centerIn: parent; text: "Kill"; color: Theme.base; font.bold: true; font.pixelSize: 12 }
                        
                        MouseArea { 
                            id: mouseAreaKill
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                // 1. Grab everything we can get our hands on
                                let id = modelData.id || "";
                                let title = modelData.title || "";
                                let tooltip = modelData.tooltipTitle || "";
                                let icon = modelData.icon || "";
                                
                                // Print to console so you can see exactly what the app is calling itself!
                                console.log("KILLING APP -> ID: " + id + " | Title: " + title + " | Tooltip: " + tooltip + " | Icon: " + icon);

                                // 2. The Tooltip is our best bet for Electron apps. 
                                // If the tooltip is "Vesktop - 1 Notification", this grabs just "Vesktop"
                                let shortTooltip = tooltip.split(" ")[0].toLowerCase();
                                let shortTitle = title.split(" ")[0].toLowerCase();
                                let shortId = id.split("-")[0].toLowerCase();

                                // 3. The Ultimate Kill Chain
                                // We check the tooltip first, because if the title is "chrome_status_icon", we want to ignore it!
                                let smartKill = "";
                                
                                if (shortTooltip !== "" && shortTooltip !== "chrome_status_icon") {
                                    smartKill = 'pkill -i -f "' + shortTooltip + '"';
                                } else {
                                    smartKill = 'pkill -i -f "' + shortTitle + '" || pkill -i -f "' + shortId + '"';
                                }

                                killProcess.running = false;
                                killProcess.command = ["bash", "-c", smartKill];
                                killProcess.running = true;
                                
                                trayList.expandedId = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
