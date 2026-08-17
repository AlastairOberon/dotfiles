import QtQuick
import QtQuick.Layouts
import QtQuick.Controls 
import Quickshell
import Quickshell.Services.Pipewire
import ".." // Imports your Theme and BlueprintPopup!

BlueprintPopup {
    id: mixerPopup
    
    // --- 1. CONFIGURE THE BLUEPRINT ---
    popupWidth: 335 
    popupHeight: 400 
    isTopBar: true
    //barOverlap: 0
    //timeoutDuration: 3000 // Automatically handles hover-pausing!

    // ==========================================
    // --- 2. UI CONTENT ---
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        // Margins are automatically handled by the Blueprint container!
        spacing: 15

        // --- MASTER VOLUME ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text { 
                    text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? "󰖁" : "󰕾" 
                    color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? Theme.urgent : Theme.secondary 
                    font.pixelSize: 18 
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                Text { 
                    Layout.fillWidth: true
                    text: Pipewire.defaultAudioSink ? (Pipewire.defaultAudioSink.properties["node.description"] || "Master Volume") : "Master Volume"
                    color: Theme.text; font.pixelSize: 14; font.bold: true
                    elide: Text.ElideRight 
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                Text { 
                    text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : "0%"
                    color: Theme.inactive; font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Master Mute Button
                Rectangle {
                    width: 24; height: 24; radius: 6
                    color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? Theme.urgent : Theme.secondaryBase
                    Behavior on color { ColorAnimation { duration: 150 } } // Kept fast for snappy click feedback
                    
                    Text { 
                        anchors.centerIn: parent
                        text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? "󰖁" : "󰕾"
                        color: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? Theme.base : Theme.text
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                            }
                        }
                    }
                }

                // Master Slider
                VolumeSlider {
                    value: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
                    onMoved: (val) => {
                        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                            Pipewire.defaultAudioSink.audio.volume = val;
                            if (val > 0) Pipewire.defaultAudioSink.audio.muted = false;
                        }
                    }
                }
            }
        }

        // Animated Separator
        Rectangle { 
            Layout.fillWidth: true; 
            height: 1; 
            color: Theme.secondaryBase 
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        // --- INDIVIDUAL APP STREAMS ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth 

            ColumnLayout {
                width: parent.width
                spacing: 15

                Repeater {
                    model: Pipewire.nodes

                    delegate: ColumnLayout {
                        id: appRow
                        Layout.fillWidth: true
                        
                        property bool isAppStream: modelData && modelData.properties && modelData.properties["media.class"] === "Stream/Output/Audio"
                        property string appName: isAppStream ? (modelData.properties["application.name"] || modelData.properties["node.name"] || "Unknown App") : ""
                        
                        visible: isAppStream
                        Layout.preferredHeight: visible ? implicitHeight : 0

                        PwObjectTracker { objects: [modelData] }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { 
                                Layout.fillWidth: true
                                text: appRow.appName
                                color: Theme.inactive; font.pixelSize: 13
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text { 
                                text: modelData && modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : "0%"
                                color: Theme.inactive; font.pixelSize: 12
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // App Mute Button
                            Rectangle {
                                width: 24; height: 24; radius: 6
                                color: modelData && modelData.audio && modelData.audio.muted ? Theme.urgent : Theme.secondaryBase
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text { 
                                    anchors.centerIn: parent
                                    text: modelData && modelData.audio && modelData.audio.muted ? "󰖁" : "󰕾"
                                    color: modelData && modelData.audio && modelData.audio.muted ? Theme.base : Theme.text
                                    font.pixelSize: 14
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (modelData && modelData.audio) {
                                            modelData.audio.muted = !modelData.audio.muted;
                                        }
                                    }
                                }
                            }

                            // App Slider
                            VolumeSlider {
                                value: modelData && modelData.audio ? modelData.audio.volume : 0
                                onMoved: (val) => {
                                    if (modelData && modelData.audio) {
                                        modelData.audio.volume = val;
                                        if (val > 0) modelData.audio.muted = false;
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
