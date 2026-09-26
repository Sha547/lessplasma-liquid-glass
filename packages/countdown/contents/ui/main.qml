import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property date now: new Date()
    property date target: new Date(plasmoid.configuration.targetDateTime)
    property real diffMs: target.getTime() - now.getTime()
    property bool valid: !isNaN(target.getTime())
    property bool past: diffMs <= 0

    function pad(n) { return n < 10 ? "0" + n : "" + n; }

    function bigNumber() {
        var abs = Math.abs(diffMs);
        var days = Math.floor(abs / 86400000);
        if (days >= 1) return "" + days;
        var hours = Math.floor(abs / 3600000);
        if (hours >= 1) return "" + hours;
        var mins = Math.floor(abs / 60000);
        return "" + mins;
    }

    function unitLabel() {
        var abs = Math.abs(diffMs);
        var days = Math.floor(abs / 86400000);
        if (days >= 1) return days === 1 ? "DAY" : "DAYS";
        var hours = Math.floor(abs / 3600000);
        if (hours >= 1) return hours === 1 ? "HOUR" : "HOURS";
        return "MIN";
    }

    function subLabel() {
        var abs = Math.abs(diffMs);
        var h = Math.floor((abs % 86400000) / 3600000);
        var m = Math.floor((abs % 3600000) / 60000);
        var s = Math.floor((abs % 60000) / 1000);
        return pad(h) + ":" + pad(m) + ":" + pad(s);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 160
        Layout.minimumWidth: 160
        Layout.minimumHeight: 120

        GlassCard {
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: Math.min(plasmoid.configuration.cornerRadius, height / 2)
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                visible: root.valid

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (root.past ? "SINCE " : "UNTIL ") + plasmoid.configuration.eventLabel.toUpperCase()
                    color: "white"
                    opacity: 0.55
                    font.pixelSize: 11
                    font.letterSpacing: 1
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    Layout.maximumWidth: parent.parent.width - 20
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6
                    Text {
                        text: root.bigNumber()
                        color: plasmoid.configuration.accentColorHex
                        font.pixelSize: plasmoid.configuration.numberFontSize
                        font.bold: true
                    }
                    Text {
                        text: root.unitLabel()
                        color: "white"
                        opacity: 0.7
                        font.pixelSize: plasmoid.configuration.numberFontSize * 0.32
                        font.bold: true
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: plasmoid.configuration.numberFontSize * 0.12
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.subLabel() + (root.past ? " ago" : "")
                    color: "white"
                    opacity: 0.45
                    font.pixelSize: 11
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.valid
                text: "Set a target date\nin Configure"
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
