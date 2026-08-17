import QtQuick
import QtQuick.Layouts
import ".." // <-- Crucial: Tells QML to look one folder up for Theme.qml

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: 24

    // The real system volume
    property real value: 0.0
    
    // Internal state to hold the visual position while dragging
    property real internalValue: 0.0
    
    // Decouples the visual bar from the system state while the mouse is held down
    property real displayValue: mouseArea.pressed ? internalValue : value

    // Fires continuously while dragging (for internal ALSA mics)
    signal moved(real newValue) 
    
    // Fires only once when the mouse is released (for heavy terminal commands)
    signal applied(real finalValue) 

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8 
        radius: 4
        
        // THE FIX: Dynamic background track color
        color: Theme.secondaryBase 
        Behavior on color { ColorAnimation { duration: 300 } }

        Rectangle {
            // Now uses displayValue so it doesn't fight the system lock while dragging
            width: Math.max(0, Math.min(track.width, track.width * root.displayValue))
            height: parent.height
            radius: 4
            
            // THE FIX: Dynamic active fill color
            color: Theme.main 
            Behavior on color { ColorAnimation { duration: 300 } }

            Rectangle {
                width: 14; height: 14; radius: 7
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width - (width / 2) 
                
                // Inherits Theme.main from the parent rectangle
                color: parent.color 
                
                // THE FIX: Matches the background of the popup to create a clean cutout look
                border.color: Theme.base; 
                border.width: 2
                Behavior on border.color { ColorAnimation { duration: 300 } }
                
                scale: mouseArea.pressed ? 1.3 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent 
        hoverEnabled: true 

        onPositionChanged: (mouse) => {
            if (pressed) {
                root.internalValue = Math.max(0, Math.min(1, mouse.x / root.width));
                root.moved(root.internalValue);
            }
        }
        
        onPressed: (mouse) => {
            root.internalValue = Math.max(0, Math.min(1, mouse.x / root.width));
            root.moved(root.internalValue);
        }

        // Triggers the heavy lifting only when you let go
        onReleased: {
            root.applied(root.internalValue);
        }
    }
}
