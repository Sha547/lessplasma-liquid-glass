import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property string phase: "work" // work | break
    property bool running: false
    property int totalSeconds: plasmoid.configuration.workMinutes * 60
    property int remaining: totalSeconds

    function phaseSeconds() {
        return (root.phase === "work" ? plasmoid.configuration.workMinutes : plasmoid.configuration.breakMinutes) * 60;
    }

    function pad(n) { return n < 10 ? "0" + n : "" + n; }
    function timeText() {
        var m = Math.floor(root.remaining / 60);
        var s = root.remaining % 60;
        return pad(m) + ":" + pad(s);
    }

    function toggle() {
        if (root.remaining <= 0) root.remaining = root.phaseSeconds();
        root.running = !root.running;
    }

    function reset() {
        root.running = false;
        root.phase = "work";
        root.remaining = root.phaseSeconds();
    }

    function skip() {
        root.phase = (root.phase === "work") ? "break" : "work";
        root.remaining = root.phaseSeconds();
    }

    Component.onCompleted: root.remaining = phaseSeconds()

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remaining > 0) {
                root.remaining -= 1;
            } else {
                root.skip();
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 190
        Layout.preferredHeight: 190
        Layout.minimumWidth: 140
        Layout.minimumHeight: 140

        GlassCard {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: Math.min(plasmoid.configuration.cornerRadius, Math.min(width, height) / 2)
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            GlassArc {
                id: ring
                anchors.centerIn: parent
                width: Math.min(card.width, card.height) - 30
                height: width
                strokeWidth: 9
                progress: root.phaseSeconds() > 0 ? 1 - (root.remaining / root.phaseSeconds()) : 0
                progressColor: root.phase === "work" ? plasmoid.configuration.workColorHex : plasmoid.configuration.breakColorHex
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.toggle()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.phase === "work" ? "FOCUS" : "BREAK"
                    color: "white"
                    opacity: 0.55
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.timeText()
                    color: "white"
                    font.pixelSize: plasmoid.configuration.timeFontSize
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.running ? "tap to pause" : "tap to start"
                    color: "white"
                    opacity: 0.4
                    font.pixelSize: 10
                }
            }

            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                text: "↺"
                color: "white"
                opacity: 0.5
                font.pixelSize: 15
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: root.reset()
                }
            }
        }
    }
}
