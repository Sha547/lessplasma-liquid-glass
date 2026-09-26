import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_refreshMinutes: refreshSpin.value
    property alias cfg_warnThreshold: warnSpin.value
    property alias cfg_countFontSize: fontSizeSpin.value
    property alias cfg_glassBlur: blurSlider.value
    property alias cfg_glassTintOpacity: tintSlider.value
    property alias cfg_cornerRadius: cornerSlider.value

    QQC2.SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Check every (minutes):"
        from: 1
        to: 720
    }

    QQC2.SpinBox {
        id: warnSpin
        Kirigami.FormData.label: "Warn above:"
        from: 1
        to: 200
    }

    QQC2.SpinBox {
        id: fontSizeSpin
        Kirigami.FormData.label: "Count font size:"
        from: 20
        to: 64
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
