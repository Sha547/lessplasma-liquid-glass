import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property string scriptPath: Qt.resolvedUrl("../code/sun.py").toString().replace(/^file:\/\//, "")

    property date now: new Date()
    property date sunrise
    property date sunset
    property bool loaded: false
    property bool polar: false
    property string city: ""

    function pad(n) { return n < 10 ? "0" + n : "" + n; }
    function fmt(d) { return pad(d.getHours()) + ":" + pad(d.getMinutes()); }

    function dayProgress() {
        if (!loaded) return 0;
        var total = sunset.getTime() - sunrise.getTime();
        if (total <= 0) return 0;
        var elapsed = now.getTime() - sunrise.getTime();
        return Math.max(0, Math.min(1, elapsed / total));
    }

    function isDaytime() {
        return loaded && now.getTime() >= sunrise.getTime() && now.getTime() < sunset.getTime();
    }

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var raw = (data.stdout || "").trim();
                if (raw.length > 0) {
                    var info = {};
                    raw.split("\n").forEach(function (line) {
                        var i = line.indexOf("=");
                        if (i > 0) info[line.substr(0, i)] = line.substr(i + 1);
                    });
                    if (info["polar"] === "1") {
                        root.polar = true;
                        root.loaded = false;
                    } else if (info["sunrise"] && info["sunset"]) {
                        root.sunrise = new Date(info["sunrise"]);
                        root.sunset = new Date(info["sunset"]);
                        root.polar = false;
                        root.loaded = true;
                    }
                    if (info["city"] !== undefined) root.city = info["city"];
                }
            }
            disconnectSource(sourceName);
        }

        function refresh() {
            var cfg = plasmoid.configuration;
            connectSource("python3 \"" + root.scriptPath + "\" \"" + cfg.latitude + "\" \"" + cfg.longitude + "\"");
        }
    }

    Timer {
        id: clockTimer
        interval: 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: Math.max(300, plasmoid.configuration.refreshMinutes * 60) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.refresh()
    }

    Connections {
        target: plasmoid.configuration
        function onLatitudeChanged() { ds.refresh(); }
        function onLongitudeChanged() { ds.refresh(); }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 220
        Layout.minimumWidth: 160
        Layout.minimumHeight: 160

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
                width: Math.min(card.width, card.height) - 36
                height: width
                strokeWidth: 8
                startAngleDeg: -90
                progress: root.dayProgress()
                trackColor: Qt.rgba(1, 1, 1, 0.10)
                progressColor: root.isDaytime() ? plasmoid.configuration.dayColorHex : plasmoid.configuration.nightColorHex
                visible: root.loaded
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 3
                visible: root.loaded

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.city.length > 0 ? root.city.toUpperCase() : "SUN"
                    color: "white"
                    opacity: 0.55
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    ColumnLayout {
                        spacing: 0
                        Text { Layout.alignment: Qt.AlignHCenter; text: "↑"; color: "white"; opacity: 0.5; font.pixelSize: 11 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: root.loaded ? root.fmt(root.sunrise) : "--:--"; color: "white"; font.pixelSize: plasmoid.configuration.timeFontSize; font.bold: true }
                    }
                    ColumnLayout {
                        spacing: 0
                        Text { Layout.alignment: Qt.AlignHCenter; text: "↓"; color: "white"; opacity: 0.5; font.pixelSize: 11 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: root.loaded ? root.fmt(root.sunset) : "--:--"; color: "white"; font.pixelSize: plasmoid.configuration.timeFontSize; font.bold: true }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 2
                    text: root.isDaytime() ? "Daylight" : "Night"
                    color: "white"
                    opacity: 0.5
                    font.pixelSize: 11
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.margins: 16
                width: parent.width - 32
                visible: !root.loaded
                text: root.polar ? "No sunrise/sunset today\nat this latitude" : "Locating…"
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
