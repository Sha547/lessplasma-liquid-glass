import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property int percent: 0
    property string state: "Unknown" // Charging | Discharging | Full | Not charging | Unknown
    property bool found: false

    function ringColor() {
        if (root.percent <= plasmoid.configuration.criticalThreshold) return plasmoid.configuration.criticalColorHex;
        if (root.percent <= plasmoid.configuration.warnThreshold) return plasmoid.configuration.warnColorHex;
        return plasmoid.configuration.normalColorHex;
    }

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var raw = (data.stdout || "").trim();
                if (raw.length > 0) {
                    var parts = raw.split("|");
                    root.percent = parseInt(parts[0]) || 0;
                    root.state = parts.length > 1 ? parts[1] : "Unknown";
                    root.found = true;
                } else {
                    root.found = false;
                }
            }
            disconnectSource(sourceName);
        }

        function refresh() {
            connectSource(
                "bat=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); " +
                "if [ -n \"$bat\" ]; then echo \"$(cat $bat/capacity 2>/dev/null)|$(cat $bat/status 2>/dev/null)\"; fi"
            );
        }
    }

    Timer {
        interval: Math.max(5, plasmoid.configuration.refreshSeconds) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.refresh()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 180
        Layout.preferredHeight: 180
        Layout.minimumWidth: 130
        Layout.minimumHeight: 130

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
                strokeWidth: 10
                progress: root.percent / 100
                progressColor: root.ringColor()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                visible: root.found

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Text {
                        text: root.percent + "%"
                        color: "white"
                        font.pixelSize: plasmoid.configuration.percentFontSize
                        font.bold: true
                    }
                    Text {
                        text: "⚡"
                        visible: root.state === "Charging"
                        color: "#FF9F0A"
                        font.pixelSize: plasmoid.configuration.percentFontSize * 0.55
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.state
                    color: "white"
                    opacity: 0.6
                    font.pixelSize: 11
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.found
                text: "No battery found"
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 11
                width: parent.width - 30
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
