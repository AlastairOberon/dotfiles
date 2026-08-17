import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire 
import ".." // <-- Crucial: Tells QML to look one folder up for Theme.qml

MouseArea {
    id: audioContainer
    Layout.preferredWidth: audioItem.implicitWidth
    Layout.fillHeight: true

    property var parentWindow 

    // 1. Move all Pipewire tracking to the root so it's always safely available
    property var activeSink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [ audioContainer.activeSink ] }

    property bool isMuted: activeSink?.audio?.muted ?? false
    property int volume: Math.round((activeSink?.audio?.volume ?? 0) * 100)
    property bool isHeadphones: activeSink ? (activeSink.name.toLowerCase().match(/bluez|headphone|headset|ear/)) : false

    property string currentIcon: {
        if (isMuted) return "󰖁";          
        if (isHeadphones) return "󰋋";     
        if (volume === 0) return "󰝟";
        if (volume < 30) return "󰕿";
        if (volume < 70) return "󰖀";
        return "󰕾";                        
    }

    // 2. Both Click and Scroll controls are now handled safely at the root level!
    onClicked: volumeMixer.toggle()

    onWheel: (wheel) => {
        if (!activeSink?.audio) return;
        let newVol = volume;
        if (wheel.angleDelta.y > 0) newVol = Math.min(100, volume + 5); 
        else if (wheel.angleDelta.y < 0) newVol = Math.max(0, volume - 5);   
        
        activeSink.audio.volume = newVol / 100.0;
        if (activeSink.audio.muted && newVol > 0) activeSink.audio.muted = false;
    }

    // 3. The Layout is now clean and only handles visuals
    RowLayout {
        id: audioItem
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Icon
        Text { 
            text: audioContainer.currentIcon; 
            // THE FIX: Dynamic theme colors for the icon
            color: audioContainer.isMuted ? Theme.urgent : Theme.main; 
            font.pixelSize: 18 
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        
        // Volume Percentage (Width locked to prevent layout jitter)
        Text { 
            text: audioContainer.volume + "%"; 
            // THE FIX: Dynamic theme colors for the text
            color: audioContainer.isMuted ? Theme.inactive : Theme.text; 
            font.pixelSize: 14; 
            font.bold: true
            
            Layout.preferredWidth: 35 
            horizontalAlignment: Text.AlignRight 
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    VolumeMixer {
        id: volumeMixer
        parentWindow: audioContainer.parentWindow 
        anchorTarget: audioContainer 
    }
}
