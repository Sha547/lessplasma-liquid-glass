import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property real synodicDays: 29.530588853
    // A known new moon (2000-01-06 18:14 UTC), the usual reference epoch for
    // this calculation. Everything else is just "how many synodic months
    // have elapsed since then", no network or ephemeris library needed.
    readonly property double refMs: Date.UTC(2000, 0, 6, 18, 14, 0)

    property date now: new Date()
    readonly property real daysSinceRef: (now.getTime() - refMs) / 86400000
    readonly property real phase: daysSinceRef / synodicDays
    readonly property real frac: phase - Math.floor(phase) // 0..1, 0=new, 0.5=full
    readonly property int illumination: Math.round(((1 - Math.cos(2 * Math.PI * frac)) / 2) * 100)

    readonly property var names: ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
                                   "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"]
    readonly property var glyphs: ["🌑", "🌒", "🌓", "🌔",
                                    "🌕", "🌖", "🌗", "🌘"]
    readonly property int nameIndex: Math.round(frac * 8) % 8

    function daysUntilFull() {
        var d = 0.5 - frac;
        if (d <= 0) d += 1;
        return Math.round(d * synodicDays);
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 200
        Layout.preferredHeight: 180
        Layout.minimumWidth: 150
        Layout.minimumHeight: 140

        GlassCard {
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: Math.min(plasmoid.configuration.cornerRadius, height / 2)
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.glyphs[root.nameIndex]
                    font.pixelSize: plasmoid.configuration.glyphFontSize
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.names[root.nameIndex]
                    color: "white"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.illumination + "% lit"
                    color: "white"
                    opacity: 0.6
                    font.pixelSize: 12
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    text: root.nameIndex === 4 ? "Full moon today"
                          : "Full moon in " + root.daysUntilFull() + "d"
                    color: "white"
                    opacity: 0.45
                    font.pixelSize: 11
                }
            }
        }
    }
}
