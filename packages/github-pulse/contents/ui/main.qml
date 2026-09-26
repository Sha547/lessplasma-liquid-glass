import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property int prCount: -1
    property int assignedCount: -1
    property bool ghAvailable: true

    P5Support.DataSource {
        id: ds
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) => {
            if (data && data["exit code"] === 0) {
                var raw = (data.stdout || "").trim();
                if (raw === "NOGH") {
                    root.ghAvailable = false;
                } else {
                    root.ghAvailable = true;
                    var parts = raw.split("|");
                    if (parts.length >= 2) {
                        root.prCount = parseInt(parts[0]);
                        root.assignedCount = parseInt(parts[1]);
                        if (isNaN(root.prCount)) root.prCount = -1;
                        if (isNaN(root.assignedCount)) root.assignedCount = -1;
                    }
                }
            }
            disconnectSource(sourceName);
        }

        function refresh() {
            connectSource(
                "if ! command -v gh >/dev/null 2>&1; then echo NOGH; exit 0; fi; " +
                "pr=$(gh api search/issues -f q='is:open is:pr author:@me' --jq '.total_count' 2>/dev/null); " +
                "asg=$(gh api search/issues -f q='is:open assignee:@me' --jq '.total_count' 2>/dev/null); " +
                "echo \"${pr:--1}|${asg:--1}\""
            );
        }
    }

    Timer {
        interval: Math.max(60, plasmoid.configuration.refreshSeconds) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: ds.refresh()
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 220
        Layout.preferredHeight: 130
        Layout.minimumWidth: 180
        Layout.minimumHeight: 100

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
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                visible: root.ghAvailable

                Text {
                    text: "GitHub"
                    color: "white"
                    opacity: 0.55
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.prCount >= 0 ? root.prCount : "–"
                            color: "white"
                            font.pixelSize: plasmoid.configuration.countFontSize
                            font.bold: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "open PRs"
                            color: "white"
                            opacity: 0.6
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Qt.rgba(1, 1, 1, 0.15)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.assignedCount >= 0 ? root.assignedCount : "–"
                            color: "white"
                            font.pixelSize: plasmoid.configuration.countFontSize
                            font.bold: true
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "assigned"
                            color: "white"
                            opacity: 0.6
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !root.ghAvailable
                text: "gh CLI not found or\nnot logged in"
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
