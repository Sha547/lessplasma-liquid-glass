import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property int count: 0
    property string manager: "..."
    property bool checking: false

    function statusColor() {
        if (root.count <= 0) return "#34C759";
        if (root.count < plasmoid.configuration.warnThreshold) return "#5AC8FA";
        return "#FF9F0A";
    }

    // Each branch tries the next package manager down the line and prints
    // "<count>|<manager>". None of this needs sudo: it reads the last
    // locally-synced package index, it never triggers a sync itself.
    readonly property string checkScript:
        "if command -v apt >/dev/null 2>&1; then " +
        "  n=$(apt list --upgradable 2>/dev/null | grep -v '^Listing' | wc -l); mgr=apt; " +
        "elif command -v dnf >/dev/null 2>&1; then " +
        "  n=$(dnf check-update -q 2>/dev/null | grep -cE '^[A-Za-z0-9]'); mgr=dnf; " +
        "elif command -v pacman >/dev/null 2>&1; then " +
        "  if command -v checkupdates >/dev/null 2>&1; then n=$(checkupdates 2>/dev/null | wc -l); " +
        "  else n=$(pacman -Qu 2>/dev/null | wc -l); fi; mgr=pacman; " +
        "elif command -v zypper >/dev/null 2>&1; then " +
        "  n=$(zypper lu 2>/dev/null | grep -cE '^v '); mgr=zypper; " +
        "else n=0; mgr=none; fi; " +
        "echo \"$n|$mgr\""

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            root.checking = false;
            if (data && data["exit code"] === 0) {
                var raw = (data.stdout || "").trim();
                var parts = raw.split("|");
                if (parts.length >= 2) {
                    root.count = parseInt(parts[0]) || 0;
                    root.manager = parts[1];
                }
            }
            disconnectSource(sourceName);
        }

        function refresh() {
            root.checking = true;
            connectSource(root.checkScript);
        }
    }

    Timer {
        interval: Math.max(60, plasmoid.configuration.refreshMinutes * 60) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.refresh()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 180
        Layout.preferredHeight: 150
        Layout.minimumWidth: 140
        Layout.minimumHeight: 110

        GlassCard {
            anchors.fill: parent
            anchors.margins: 10
            cornerRadius: Math.min(plasmoid.configuration.cornerRadius, height / 2)
            blurAmount: plasmoid.configuration.glassBlur
            tintOpacity: plasmoid.configuration.glassTintOpacity

            MouseArea {
                anchors.fill: parent
                onClicked: ds.refresh()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.checking ? "…" : "" + root.count
                    color: root.statusColor()
                    font.pixelSize: plasmoid.configuration.countFontSize
                    font.bold: true
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.count === 0 ? "up to date" : (root.count === 1 ? "update" : "updates")
                    color: "white"
                    opacity: 0.65
                    font.pixelSize: 12
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.manager
                    color: "white"
                    opacity: 0.4
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }
        }
    }
}
