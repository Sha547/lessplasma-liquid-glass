import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_cityLabel: cityField.text
    property alias cfg_utcOffsetHours: offsetSlider.value
    property alias cfg_use24Hour: use24Check.checked
    property alias cfg_clockFontSize: clockFontSpin.value
    property alias cfg_labelFontSize: labelFontSpin.value
    property alias cfg_offsetFontSize: offsetFontSpin.value
    property alias cfg_glassBlur: blurSlider.value
    property alias cfg_glassTintOpacity: tintSlider.value
    property alias cfg_cornerRadius: cornerSlider.value

    QQC2.TextField {
        id: cityField
        Kirigami.FormData.label: "City label:"
        placeholderText: "TYO"
        maximumLength: 6
    }

    RowLayout {
        Kirigami.FormData.label: "UTC offset:"

        QQC2.Slider {
            id: offsetSlider
            from: -12
            to: 14
            stepSize: 0.5
            Layout.preferredWidth: Kirigami.Units.gridUnit * 9
        }

        QQC2.Label {
            text: (offsetSlider.value >= 0 ? "+" : "") + offsetSlider.value + "h"
            opacity: 0.7
        }
    }

    QQC2.CheckBox {
        id: use24Check
        Kirigami.FormData.label: "24-hour clock:"
        text: "Use 24-hour time"
    }

    QQC2.SpinBox {
        id: clockFontSpin
        Kirigami.FormData.label: "Clock font size:"
        from: 20
        to: 72
    }

    QQC2.SpinBox {
        id: labelFontSpin
        Kirigami.FormData.label: "City label font size:"
        from: 8
        to: 24
    }

    QQC2.SpinBox {
        id: offsetFontSpin
        Kirigami.FormData.label: "Offset font size:"
        from: 8
        to: 24
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
