import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property string cfg_accentColorHex: "#FF9F0A"
    property alias cfg_showSecondHand: secondCheck.checked
    property alias cfg_sweepSeconds: sweepCheck.checked
    property alias cfg_glassBlur: blurSlider.value
    property alias cfg_glassTintOpacity: tintSlider.value

    function toHex(c) {
        function part(v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2); }
        return "#" + part(c.r) + part(c.g) + part(c.b);
    }

    RowLayout {
        Kirigami.FormData.label: "Second hand color:"
        Rectangle {
            width: Kirigami.Units.gridUnit * 1.5
            height: Kirigami.Units.gridUnit * 1.5
            radius: 4
            color: page.cfg_accentColorHex
            border.color: Kirigami.Theme.textColor
            border.width: 1
            MouseArea { anchors.fill: parent; onClicked: dialog.open() }
        }
        QQC2.Label { text: page.cfg_accentColorHex; opacity: 0.7 }
        ColorDialog {
            id: dialog
            selectedColor: page.cfg_accentColorHex
            onAccepted: page.cfg_accentColorHex = page.toHex(selectedColor)
        }
    }

    QQC2.CheckBox {
        id: secondCheck
        Kirigami.FormData.label: "Second hand:"
        text: "Show second hand"
    }

    QQC2.CheckBox {
        id: sweepCheck
        Kirigami.FormData.label: "Motion:"
        text: "Smooth sweep (updates 30x/sec instead of ticking once a second)"
    }

    QQC2.Slider {
        id: blurSlider
        Kirigami.FormData.label: "Glass blur:"
        from: 0.0
        to: 1.0
        stepSize: 0.05
    }

    QQC2.Slider {
        id: tintSlider
        Kirigami.FormData.label: "Glass tint:"
        from: 0.0
        to: 0.8
        stepSize: 0.02
    }
}
