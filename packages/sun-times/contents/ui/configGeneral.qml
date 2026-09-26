import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_refreshMinutes: refreshSpin.value
    property alias cfg_latitude: latField.text
    property alias cfg_longitude: lonField.text
    property string cfg_dayColorHex: "#FF9F0A"
    property string cfg_nightColorHex: "#5AC8FA"
    property alias cfg_timeFontSize: fontSizeSpin.value
    property alias cfg_glassBlur: blurSlider.value
    property alias cfg_glassTintOpacity: tintSlider.value
    property alias cfg_cornerRadius: cornerSlider.value

    function toHex(c) {
        function part(v) { return ("0" + Math.round(v * 255).toString(16)).slice(-2); }
        return "#" + part(c.r) + part(c.g) + part(c.b);
    }

    QQC2.Label {
        Kirigami.FormData.label: "Location:"
        text: "Leave blank to detect from your IP address."
        opacity: 0.7
        wrapMode: Text.WordWrap
        Layout.preferredWidth: Kirigami.Units.gridUnit * 16
    }

    QQC2.TextField {
        id: latField
        Kirigami.FormData.label: "Latitude:"
        placeholderText: "auto"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }

    QQC2.TextField {
        id: lonField
        Kirigami.FormData.label: "Longitude:"
        placeholderText: "auto"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 10
    }

    RowLayout {
        Kirigami.FormData.label: "Daylight ring color:"
        Rectangle {
            width: Kirigami.Units.gridUnit * 1.5
            height: Kirigami.Units.gridUnit * 1.5
            radius: 4
            color: page.cfg_dayColorHex
            border.color: Kirigami.Theme.textColor
            border.width: 1
            MouseArea { anchors.fill: parent; onClicked: dayDialog.open() }
        }
        QQC2.Label { text: page.cfg_dayColorHex; opacity: 0.7 }
        ColorDialog {
            id: dayDialog
            selectedColor: page.cfg_dayColorHex
            onAccepted: page.cfg_dayColorHex = page.toHex(selectedColor)
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Night ring color:"
        Rectangle {
            width: Kirigami.Units.gridUnit * 1.5
            height: Kirigami.Units.gridUnit * 1.5
            radius: 4
            color: page.cfg_nightColorHex
            border.color: Kirigami.Theme.textColor
            border.width: 1
            MouseArea { anchors.fill: parent; onClicked: nightDialog.open() }
        }
        QQC2.Label { text: page.cfg_nightColorHex; opacity: 0.7 }
        ColorDialog {
            id: nightDialog
            selectedColor: page.cfg_nightColorHex
            onAccepted: page.cfg_nightColorHex = page.toHex(selectedColor)
        }
    }

    QQC2.SpinBox {
        id: refreshSpin
        Kirigami.FormData.label: "Refresh every (minutes):"
        from: 5
        to: 180
    }

    QQC2.SpinBox {
        id: fontSizeSpin
        Kirigami.FormData.label: "Time font size:"
        from: 12
        to: 32
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
