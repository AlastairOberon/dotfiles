import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Shapes 
import Qt5Compat.GraphicalEffects 
import Quickshell
import Quickshell.Io
import "../" 

BlueprintPopup {
    id: mediaPopup
    
    popupWidth: 1050 
    popupHeight: Math.round(Screen.height * 0.25)
    
    isTopBar: false 
    //barOverlap: -10
    timeoutDuration: 5000 

    // --- DATA RECEIVERS ---
    property string nowPlaying: "No Media Playing"
    property string playbackStatus: "Paused"
    property real trackPosition: 0
    property real trackLength: 1
    property string trackArt: "" 
    property string currentPlayer: "%any"

    Process { id: mediaCmdProcess }
    function runMediaCmd(cmd) {
        mediaCmdProcess.command = ["bash", "-c", "playerctl -p '" + mediaPopup.currentPlayer + "' " + cmd];
        mediaCmdProcess.running = true;
    }

    // ==========================================
    // --- 1. THE BLURRED BACKDROP ---
    // ==========================================
    Item {
        anchors.fill: parent
        
        Rectangle {
            id: bgMask
            anchors.fill: parent
            radius: 8
            color: "black"
            visible: false
        }

        Image {
            id: blurredBgSource
            anchors.fill: parent
            source: mediaPopup.trackArt
            fillMode: Image.PreserveAspectCrop
            visible: false
            asynchronous: true
            
            // THE FIX: Dynamically measure the dimensions!
            property real aspectRatio: sourceSize.height > 0 ? (sourceSize.width / sourceSize.height) : 1.0
            // If it's a 4:3 image (~1.33 ratio), zoom to 1.6 to hide bars. Otherwise, standard 1.2 zoom.
            scale: (aspectRatio > 1.3 && aspectRatio < 1.4) ? 1.6 : 1.2 
        }

        FastBlur {
            anchors.fill: parent
            source: blurredBgSource
            radius: 64 
            visible: mediaPopup.trackArt !== "" && blurredBgSource.status === Image.Ready
            
            // THE FIX: Lowers the opacity so the blurred art blends with the Hyprglass base!
            // Tweak this between 0.1 and 1.0 to find the perfect balance.
            opacity: 0.45 
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: bgMask
            }

            Rectangle {
                anchors.fill: parent
                // THE FIX: Lowered the black tint slightly so it doesn't crush the colors
                color: Qt.rgba(0, 0, 0, 0.4) 
            }
        }
    }

    // ==========================================
    // --- 2. MAIN CONTENT LAYOUT ---
    // ==========================================
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20 
        spacing: 35 

        // --- LEFT: CIRCULAR ART & PROGRESS RING ---
        Item {
            id: ringContainer
            
            Layout.preferredWidth: mediaPopup.popupHeight - 70
            Layout.preferredHeight: mediaPopup.popupHeight - 70
            Layout.alignment: Qt.AlignVCenter

            property real progressAngle: mediaPopup.trackLength > 0 ? (mediaPopup.trackPosition / mediaPopup.trackLength) * 360 : 0
            Behavior on progressAngle { NumberAnimation { duration: 1000; easing.type: Easing.Linear } }

            // Background Ring 
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: Theme.secondaryBase
                border.width: 6
            }

            // Active Progress Ring 
            Shape {
                anchors.fill: parent
                // THE FIX: Removed the heavy 4x multisampled layer here!
                visible: ringContainer.progressAngle > 0 
                
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Theme.main
                    strokeWidth: 6
                    capStyle: ShapePath.RoundCap
                    
                    startX: ringContainer.width / 2
                    startY: 3
                    
                    PathAngleArc {
                        centerX: ringContainer.width / 2
                        centerY: ringContainer.height / 2
                        radiusX: (ringContainer.width / 2) - 3
                        radiusY: (ringContainer.height / 2) - 3
                        startAngle: -90
                        sweepAngle: ringContainer.progressAngle
                    }
                }
            }

            // Circular Mask Definition 
            Rectangle {
                id: artMask
                anchors.centerIn: parent
                width: parent.width - 24 
                height: width
                radius: width / 2
                visible: false 
            }

            // Fallback Background 
            Rectangle {
                anchors.fill: artMask
                radius: artMask.radius
                color: Theme.secondaryBase
                visible: mediaPopup.trackArt === "" || albumArtImage.status === Image.Error
                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    font.pixelSize: 48
                    color: Theme.inactive
                }
            }

            // The Custom Turntable Spin Engine
            Item {
                id: artContainer
                anchors.fill: artMask
                visible: mediaPopup.trackArt !== "" && albumArtImage.status !== Image.Error
                
                property real targetSpinSpeed: mediaPopup.playbackStatus === "Playing" ? 1.0 : 0.0
                property real currentSpinSpeed: targetSpinSpeed
                
                Behavior on currentSpinSpeed {
                    NumberAnimation { 
                        duration: 1500 
                        easing.type: Easing.InOutQuad 
                    }
                }
                
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: artMask
                }

                Image {
                    id: albumArtImage
                    anchors.fill: parent
                    source: mediaPopup.trackArt
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    
                    // THE FIX: Dynamically measure dimensions here too!
                    property real aspectRatio: sourceSize.height > 0 ? (sourceSize.width / sourceSize.height) : 1.0
                    
                    // Automatically applies the mathematical scale (1.35) ONLY if the image dimensions are 4:3
                    scale: (aspectRatio > 1.3 && aspectRatio < 1.4) ? 1.35 : 1.0
                }
                
                Timer {
                    interval: 16 
                    repeat: true
                    running: artContainer.currentSpinSpeed > 0
                    onTriggered: {
                        albumArtImage.rotation = (albumArtImage.rotation + (0.72 * artContainer.currentSpinSpeed)) % 360
                    }
                }
            }
        }

        // --- RIGHT: INFO & CONTROLS ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            Item { Layout.fillHeight: true } 

            // Track Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                
                // --- SCROLLING & FADING TITLE CONTAINER ---
                Item {
                    id: titleContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 35
                    clip: true

                    property bool needsScroll: titleText.contentWidth > titleContainer.width
                    property string trackTitle: mediaPopup.nowPlaying.split(" - ")[0] || "Unknown Title"

                    layer.enabled: titleContainer.needsScroll
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: titleContainer.width
                            height: titleContainer.height
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.1; color: "black" }
                                GradientStop { position: 0.9; color: "black" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }

                    Row {
                        id: titleRow
                        x: titleContainer.needsScroll ? 0 : (titleContainer.width - titleText.width) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 80

                        Text {
                            id: titleText
                            text: titleContainer.trackTitle
                            color: "#FFFFFF" 
                            font.bold: true
                            font.pixelSize: 26 
                            
                            onTextChanged: {
                                if (titleContainer.needsScroll) titleScrollAnim.restart();
                                else { titleScrollAnim.stop(); titleRow.x = (titleContainer.width - titleText.width) / 2; }
                            }
                        }

                        Text {
                            text: titleContainer.trackTitle
                            color: "#FFFFFF" 
                            font.bold: true
                            font.pixelSize: 26 
                            visible: titleContainer.needsScroll
                        }

                        NumberAnimation on x {
                            id: titleScrollAnim
                            loops: Animation.Infinite
                            running: titleContainer.needsScroll
                            from: 0
                            to: -(titleText.width + titleRow.spacing)
                            duration: (titleText.width + titleRow.spacing) * 25
                        }
                    }
                }

                // Artist
                Text {
                    text: mediaPopup.nowPlaying.split(" - ")[1] || "Unknown Artist"
                    color: "#DDDDDD" 
                    font.pixelSize: 18 
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter 
                }
            }

            Item { Layout.preferredHeight: 10 } 

            // Jump Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter 
                spacing: 20 

                Repeater {
                    model: [
                        { label: "-60s", cmd: "position 60-" },
                        { label: "-30s", cmd: "position 30-" },
                        { label: "-10s", cmd: "position 10-" },
                        { label: "|", cmd: "" },
                        { label: "+10s", cmd: "position 10+" },
                        { label: "+30s", cmd: "position 30+" },
                        { label: "+60s", cmd: "position 60+" }
                    ]
                    
                    delegate: Text {
                        text: modelData.label
                        font.pixelSize: 15
                        font.bold: true
                        
                        color: {
                            if (modelData.label === "|") return "#555555";
                            return jumpMouse.containsMouse ? Theme.main : "#BBBBBB";
                        }
                        
                        MouseArea {
                            id: jumpMouse
                            anchors.fill: parent
                            hoverEnabled: modelData.label !== "|"
                            enabled: modelData.label !== "|"
                            onClicked: mediaPopup.runMediaCmd(modelData.cmd)
                        }
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            Item { Layout.preferredHeight: 10 } 

            // Main Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter 
                spacing: 50 

                Text {
                    text: "󰒮" 
                    font.pixelSize: 42 
                    color: prevMouse.containsMouse ? Theme.main : "#FFFFFF"
                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: mediaPopup.runMediaCmd("previous") 
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    text: mediaPopup.playbackStatus === "Playing" ? "󰏤" : "󰐊"
                    font.pixelSize: 56 
                    color: playMouse.containsMouse ? Theme.main : "#FFFFFF"
                    MouseArea {
                        id: playMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: mediaPopup.runMediaCmd("play-pause") 
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    text: "󰒭" 
                    font.pixelSize: 42 
                    color: nextMouse.containsMouse ? Theme.main : "#FFFFFF"
                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: mediaPopup.runMediaCmd("next") 
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
