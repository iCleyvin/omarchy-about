import QtQuick
import QtQuick.Layouts

// One "label  ······  value" line inside a spec section.
RowLayout {
    id: row
    property string label: ""
    property string value: ""
    property color labelColor: "#888"
    property color valueColor: "#fff"
    property bool visibleWhenEmpty: false

    Layout.fillWidth: true
    spacing: 18
    visible: visibleWhenEmpty || value.length > 0

    Text {
        text: row.label
        color: row.labelColor
        font.pixelSize: 13
        Layout.preferredWidth: 156
        Layout.alignment: Qt.AlignTop
        wrapMode: Text.NoWrap
        elide: Text.ElideRight
    }
    Text {
        text: row.value
        color: row.valueColor
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
    }
}
