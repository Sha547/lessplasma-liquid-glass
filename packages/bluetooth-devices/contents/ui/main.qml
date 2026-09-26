import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property var devices: [] // [{name, battery}]
    property string status: "checking" // checking | nobt | none | ok

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var raw = (data.stdout || "").trim();
                if (raw === "NOBT") {
                    root.status = "nobt";
                    root.devices = [];
                } else if (raw === "NONE" || raw.length === 0) {
                    root.status = "none";
                    root.devices = [];
                } else {
                    var out = [];
                    raw.split("\n").forEach(function(line) {
                        var parts = line.split("~");
                        var name = (parts[0] || "").trim();
                        var batt = (parts[1] || "").trim();
                        if (name.length > 0) out.push({ name: name, battery: batt });
                    });
                    root.devices = out;
                    root.status = "ok";
                }
            }
            disconnectSource(sourceName);
        }

        function refresh() {
            connectSource(
                "if ! command -v bluetoothctl >/dev/null 2>&1; then echo NOBT; exit 0; fi; " +
                "out=$(bluetoothctl devices Connected 2>/dev/null); " +
                "if [ -z \"$out\" ]; then echo NONE; exit 0; fi; " +
                "echo \"$out\" | while IFS= read -r line; do " +
                "  name=$(echo \"$line\" | cut -d' ' -f3-); " +
                "  batt=''; " +
                "  if command -v upower >/dev/null 2>&1; then " +
                "    for p in $(upower -e 2>/dev/null); do " +
                "      info=$(upower -i \"$p\" 2>/dev/null); " +
                "      key=$(echo \"$name\" | cut -c1-6); " +
                "      if [ -n \"$key\" ] && echo \"$info\" | grep -qi \"$key\"; then " +
                "        batt=$(echo \"$info\" | grep -m1 'percentage:' | grep -oE '[0-9]+'); break; " +
                "      fi; " +
                "    done; " +
                "  fi; " +
                "  echo \"${name}~${batt}\"; " +
                "done"
            );
        }
    }

    Timer {
        interval: Math.max(10, plasmoid.configuration.refreshSeconds) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.refresh()
    }

    fullRepresentation: Item {
        id: view
        Layout.preferredWidth: 260
        Layout.preferredHeight: Math.max(110, 56 + root.devices.length * 34)
        Layout.minimumWidth: 200
        Layout.minimumHeight: 90

        GlassCard {
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: Math.min(plasmoid.configuration.cornerRadius, height / 2)
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Text {
                    text: "Bluetooth"
                    color: "white"
                    opacity: 0.55
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    visible: root.status === "ok"

                    Repeater {
                        model: root.devices

                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: modelData.name
                                color: "white"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: modelData.battery.length > 0
                                text: modelData.battery + "%"
                                color: Qt.rgba(1, 1, 1, 0.6)
                                font.pixelSize: 12
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.status !== "ok"
                    text: root.status === "nobt" ? "bluetoothctl not found"
                          : root.status === "none" ? "No devices connected"
                          : "Checking…"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
