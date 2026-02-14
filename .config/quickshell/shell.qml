import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Layouts


PanelWindow{
    id:root 

    anchors.top:true
    anchors.left:true
    anchors.right:true
    implicitHeight: 40

    color: "#1e1e2e"

    RowLayout{
        anchors.fill: parent
        //anchors.margins: 0
        anchors.leftMargin: 10

        Repeater{
            model:10

            Text{
                property var worksp: Hyprland.workspaces.values.find(w =>w.id === index + 1)
                property bool act_worksp: Hyprland.focusedWorkspace?.id === ( index + 1 )
                text: act_worksp? "¤ " : (worksp ? "• " : "◦ ")
                color: act_worksp? "#cba6f7" : (worksp ? "#cdd6f4" : "#6c7086")
                font{ 
                    pixelSize: 30 
                    bold: true
                }

                MouseArea{
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }
        Item { Layout.fillWidth: true}

        //Clock and PopUp
        MouseArea {
            id: clockContainer
            hoverEnabled: true
            Layout.rightMargin: 15
            Layout.preferredWidth: contentLayout.implicitWidth
            Layout.fillHeight: true
            
            // This is the key: it hides the date as it shrinks
            clip: true 

            RowLayout {
                id: contentLayout
                anchors.right: parent.right // Anchor to right so it "grows" to the left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // The Date (Slides out to the left)
                Text {
                    id: dateText
                    text: new Date().toLocaleString(Qt.locale(), "d ddd MMM")
                    color: "#cdd6f4"
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    
                    // Logic: If hovered, use natural width (-1). If not, width is 0.
                    Layout.preferredWidth: clockContainer.containsMouse ? implicitWidth : 0
                    opacity: clockContainer.containsMouse ? 1 : 0
                    
                    // The animation that creates the "slide" effect
                    Behavior on Layout.preferredWidth {
                        NumberAnimation { 
                            duration: 200
                            easing.type: Easing.OutCubic 
                        }
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }

                // The Time (Always visible on the far right)
                Text {
                    id: timeDisplay
                    color: "#a6e3a1"
                    font.pixelSize: 16
                    font.bold: true
                    
                    function updateTime() {
                        text = new Date().toLocaleString(Qt.locale(), "HH:mm:ss");
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: timeDisplay.updateTime()
                    }
                    Component.onCompleted: updateTime()
                }
            }
        }
    }



}
