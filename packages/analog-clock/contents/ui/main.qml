import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property date now: new Date()
    readonly property real hourAngle: ((now.getHours() % 12) + now.getMinutes() / 60 + now.getSeconds() / 3600) * 30
    readonly property real minuteAngle: (now.getMinutes() + now.getSeconds() / 60) * 6
    readonly property real secondAngle: now.getSeconds() * 6 + now.getMilliseconds() * 0.006

    Timer {
        interval: plasmoid.configuration.sweepSeconds ? 33 : 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 200
        Layout.preferredHeight: 200
        Layout.minimumWidth: 140
        Layout.minimumHeight: 140

        GlassCard {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            // A perfect circle: TickBezel's rounded-rect perimeter degenerates
            // to four quarter-arcs (zero-length straight edges) when the
            // corner radius equals half the side, since the card is square.
            // The glass shader also needs roundness=2 here -- its default
            // (~4.5, a squircle) stays a rounded square even at radius=w/2.
            cornerRadius: Math.min(width, height) / 2
            roundness: 2.0
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            TickBezel {
                anchors.fill: parent
                cornerRadius: card.cornerRadius
                inset: 12
                tickCount: 60
                majorEvery: 5
                tickLength: 7
                tickWidthMajor: 2.5
                tickWidthMinor: 1
                tickOpacity: 0.55
            }

            Item {
                id: face
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) - 40
                height: width

                Item {
                    rotation: root.hourAngle
                    anchors.centerIn: parent
                    width: 1; height: 1
                    Rectangle {
                        width: 7
                        radius: 3.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -face.height * 0.32
                        height: face.height * 0.32
                        color: "white"
                    }
                }

                Item {
                    rotation: root.minuteAngle
                    anchors.centerIn: parent
                    width: 1; height: 1
                    Rectangle {
                        width: 3.5
                        radius: 1.75
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -face.height * 0.40
                        height: face.height * 0.40
                        color: "white"
                    }
                }

                Item {
                    visible: plasmoid.configuration.showSecondHand
                    rotation: root.secondAngle
                    anchors.centerIn: parent
                    width: 1; height: 1
                    Rectangle {
                        width: 1.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -face.height * 0.44
                        height: face.height * 0.44
                        color: plasmoid.configuration.accentColorHex
                    }
                    Rectangle {
                        width: 1.5
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        height: face.height * 0.12
                        color: plasmoid.configuration.accentColorHex
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 9; height: 9
                    radius: 4.5
                    color: plasmoid.configuration.accentColorHex
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 4; height: 4
                    radius: 2
                    color: "white"
                }
            }
        }
    }
}
