import QtQuick
import QtQuick.Layouts
import ".." // <-- Make sure this points to wherever Theme.qml lives!

Item {
    id: indicatorRoot
    
    // !!! THE FIX: Proper Layout sizing so the hitbox isn't 0x0 pixels !!!
    Layout.preferredWidth: 35
    Layout.fillHeight: true

    property var parentWindow

    Text {
        anchors.centerIn: parent
        text: "󰇙" // The new Vertical Dots icon!
        
        // THE FIX: Dynamic theme color with a hover effect!
        color: trayMouse.containsMouse ? Theme.main : Theme.text
        font.pixelSize: 22
        font.bold: true
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        id: trayMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            // === DIAGNOSTIC TRACKERS ===
            console.log("\n=== TRAY CLICK TEST ===");
            console.log("1. Does the indicator have the window?:", indicatorRoot.parentWindow);
            console.log("2. Is the anchor target set?:", indicatorRoot);
            
            trayPopup.toggle();
        }
    }

    TrayPopup {
        id: trayPopup
        parentWindow: indicatorRoot.parentWindow
        anchorTarget: indicatorRoot
    }
}
