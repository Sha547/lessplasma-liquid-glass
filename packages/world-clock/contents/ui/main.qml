import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property date now: new Date()

    // JS Date has no IANA timezone support here, so the "other city" is just
    // a fixed UTC offset the user dials in, same as a watch's world-time bezel.
    property real localOffsetHours: -now.getTimezoneOffset() / 60
    property real targetOffsetHours: plasmoid.configuration.utcOffsetHours
    // now.getHours() already folds in localOffsetHours, so shifting the epoch
    // by (target - local) and reading getHours() again lands on the target's
    // wall-clock time without touching getTimezoneOffset() a second time.
    property date targetTime: new Date(now.getTime() + (targetOffsetHours - localOffsetHours) * 3600000)

    function pad(n) { return n < 10 ? "0" + n : "" + n; }

    function displayTime() {
        var h = targetTime.getHours();
        var m = targetTime.getMinutes();
        if (plasmoid.configuration.use24Hour) return pad(h) + ":" + pad(m);
        var h12 = h % 12;
        if (h12 === 0) h12 = 12;
        return h12 + ":" + pad(m);
    }

    function diffLabel() {
        var d = targetOffsetHours - localOffsetHours;
        if (Math.abs(d) < 0.01) return "SAME TIME";
        var sign = d > 0 ? "+" : "−";
        var abs = Math.abs(d);
        var whole = Math.floor(abs + 0.001);
        var frac = abs - whole;
        var str = frac >= 0.25 ? (whole + ".5") : "" + whole;
        return sign + str + "HRS";
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 180
        Layout.preferredHeight: 180
        Layout.minimumWidth: 140
        Layout.minimumHeight: 140

        GlassCard {
            id: card
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: Math.min(plasmoid.configuration.cornerRadius, Math.min(width, height) / 2)
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            TickBezel {
                anchors.fill: parent
                cornerRadius: card.cornerRadius
                inset: 9
                tickCount: 48
                majorEvery: 4
                tickLength: 6
                tickWidthMajor: 2
                tickWidthMinor: 1
                tickOpacity: 0.5
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: plasmoid.configuration.cityLabel
                    color: "white"
                    opacity: 0.75
                    font.pixelSize: plasmoid.configuration.labelFontSize
                    font.letterSpacing: 2
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.displayTime()
                    color: "white"
                    font.pixelSize: plasmoid.configuration.clockFontSize
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.diffLabel()
                    color: "white"
                    opacity: 0.65
                    font.pixelSize: plasmoid.configuration.offsetFontSize
                    font.letterSpacing: 1
                }
            }
        }
    }
}
