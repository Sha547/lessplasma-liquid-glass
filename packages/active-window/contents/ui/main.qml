import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property string appClass: ""
    property string windowTitle: ""
    property string status: "checking" // checking | ok | none | unsupported

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var raw = (data.stdout || "").trim();
                if (raw === "UNSUPPORTED") {
                    root.status = "unsupported";
                } else if (raw.length === 0) {
                    root.status = "none";
                } else {
                    var i = raw.indexOf("~");
                    root.appClass = i >= 0 ? raw.substr(0, i) : raw;
                    root.windowTitle = i >= 0 ? raw.substr(i + 1) : "";
                    root.status = "ok";
                }
            }
            disconnectSource(sourceName);
        }

        // xdotool covers X11 (and XWayland apps under some Wayland setups).
        // kdotool is the closest KWin/Wayland-native equivalent, when installed.
        // Neither is bundled by default, so this is deliberately best-effort.
        function refresh() {
            connectSource(
                "if command -v xdotool >/dev/null 2>&1; then " +
                "  wid=$(xdotool getactivewindow 2>/dev/null); " +
                "  if [ -n \"$wid\" ]; then " +
                "    cls=$(xdotool getwindowclassname \"$wid\" 2>/dev/null); " +
                "    title=$(xdotool getwindowname \"$wid\" 2>/dev/null); " +
                "    echo \"${cls}~${title}\"; exit 0; " +
                "  fi; " +
                "fi; " +
                "if command -v kdotool >/dev/null 2>&1; then " +
                "  wid=$(kdotool getactivewindow 2>/dev/null); " +
                "  if [ -n \"$wid\" ]; then " +
                "    title=$(kdotool getwindowname \"$wid\" 2>/dev/null); " +
                "    echo \"~${title}\"; exit 0; " +
                "  fi; " +
                "fi; " +
                "echo UNSUPPORTED"
            );
        }
    }

    Timer {
        interval: Math.max(1, plasmoid.configuration.refreshSeconds) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.refresh()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 260
        Layout.preferredHeight: 110
        Layout.minimumWidth: 180
        Layout.minimumHeight: 80

        GlassCard {
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: Math.min(plasmoid.configuration.cornerRadius, height / 2)
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 4
                visible: root.status === "ok"

                Text {
                    text: root.appClass.length > 0 ? root.appClass : "Desktop"
                    color: "white"
                    font.pixelSize: plasmoid.configuration.appFontSize
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.windowTitle
                    color: "white"
                    opacity: 0.6
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.margins: 16
                width: parent.width - 32
                visible: root.status !== "ok"
                text: root.status === "unsupported"
                      ? "Needs xdotool (X11) or\nkdotool (Wayland), neither found"
                      : root.status === "none" ? "No active window"
                      : "Checking…"
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}
