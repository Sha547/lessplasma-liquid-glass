import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_eventLabel: labelField.text
    property alias cfg_targetDateTime: dateField.text
    property string cfg_accentColorHex: "#FF9F0A"
    property alias cfg_numberFontSize: fontSizeSpin.value
    property alias cfg_glassBlur: blurSlider.value
    property alias cfg_glassTintOpacity: tintSlider.value
    property alias cfg_cornerRadius: cornerSlider.value

    function toHex(c) {
        function part(v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2); }
        return "#" + part(c.r) + part(c.g) + part(c.b);
    }

    QQC2.TextField {
        id: labelField
        Kirigami.FormData.label: "Event label:"
        placeholderText: "Christmas"
    }

    QQC2.TextField {
        id: dateField
        Kirigami.FormData.label: "Target date/time:"
        placeholderText: "2026-12-31T00:00"
    }

    QQC2.Label {
        Kirigami.FormData.label: " "
        text: "Format: YYYY-MM-DD or YYYY-MM-DDTHH:MM"
        opacity: 0.55
        font.pixelSize: 11
    }

    RowLayout {
        Kirigami.FormData.label: "Number color:"
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

    QQC2.SpinBox {
        id: fontSizeSpin
        Kirigami.FormData.label: "Number font size:"
        from: 28
        to: 88
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

    RowLayout {
        Kirigami.FormData.label: "Corner radius:"
        QQC2.Slider {
            id: cornerSlider
            from: 0
            to: 48
            stepSize: 1
            Layout.preferredWidth: Kirigami.Units.gridUnit * 9
        }
        QQC2.Label {
            text: cornerSlider.value === 0
                  ? "sharp"
                  : (cornerSlider.value >= 48 ? "fully blended" : Math.round(cornerSlider.value) + " px")
            opacity: 0.7
        }
    }
}
