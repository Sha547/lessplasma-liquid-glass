import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_workMinutes: workSpin.value
    property alias cfg_breakMinutes: breakSpin.value
    property string cfg_workColorHex: "#FF3B30"
    property string cfg_breakColorHex: "#34C759"
    property alias cfg_timeFontSize: fontSizeSpin.value
    property alias cfg_glassBlur: blurSlider.value
    property alias cfg_glassTintOpacity: tintSlider.value
    property alias cfg_cornerRadius: cornerSlider.value

    function toHex(c) {
        function part(v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2); }
        return "#" + part(c.r) + part(c.g) + part(c.b);
    }

    QQC2.SpinBox {
        id: workSpin
        Kirigami.FormData.label: "Focus length (min):"
        from: 1
        to: 120
    }

    QQC2.SpinBox {
        id: breakSpin
        Kirigami.FormData.label: "Break length (min):"
        from: 1
        to: 60
    }

    RowLayout {
        Kirigami.FormData.label: "Focus color:"
        Rectangle {
            width: Kirigami.Units.gridUnit * 1.5
            height: Kirigami.Units.gridUnit * 1.5
            radius: 4
            color: page.cfg_workColorHex
            border.color: Kirigami.Theme.textColor
            border.width: 1
            MouseArea { anchors.fill: parent; onClicked: workDialog.open() }
        }
        QQC2.Label { text: page.cfg_workColorHex; opacity: 0.7 }
        ColorDialog {
            id: workDialog
            selectedColor: page.cfg_workColorHex
            onAccepted: page.cfg_workColorHex = page.toHex(selectedColor)
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Break color:"
        Rectangle {
            width: Kirigami.Units.gridUnit * 1.5
            height: Kirigami.Units.gridUnit * 1.5
            radius: 4
            color: page.cfg_breakColorHex
            border.color: Kirigami.Theme.textColor
            border.width: 1
            MouseArea { anchors.fill: parent; onClicked: breakDialog.open() }
        }
        QQC2.Label { text: page.cfg_breakColorHex; opacity: 0.7 }
        ColorDialog {
            id: breakDialog
            selectedColor: page.cfg_breakColorHex
            onAccepted: page.cfg_breakColorHex = page.toHex(selectedColor)
        }
    }

    QQC2.SpinBox {
        id: fontSizeSpin
        Kirigami.FormData.label: "Time font size:"
        from: 16
        to: 48
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
