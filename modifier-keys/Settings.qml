import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    anchors.fill: parent
    spacing: Style.marginM

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})

    readonly property var defaultGestureSymbols: {
        "scroll": ["⮆", "⮇", "⮄", "⮅"],
        "swipe3": ["🡆", "🡇", "🡄", "🡅"],
        "swipe4": ["⭲", "⭳", "⭰", "⭱"],
        "click": "󰳽",
        "rightClick": "󰳾",
        "middleClick": "󰻃",
        "motion": "󰆽",
        "pinchIn": "󰩯",
        "pinchOut": "󰩮"
    }

    function getGestureSymbols() {
        const saved = cfg.gestureSymbols || "";
        if (!saved || saved.trim() === "") return defaultGestureSymbols;
        try {
            const parsed = JSON.parse(saved);
            var result = {};
            for (var k in defaultGestureSymbols) result[k] = defaultGestureSymbols[k];
            for (var k in parsed) result[k] = parsed[k];
            return result;
        } catch (e) {
            return defaultGestureSymbols;
        }
    }

    property string jsonText: JSON.stringify(getGestureSymbols(), null, 2)

    // Title
    Text {
        text: "Gesture Symbols"
        font.pixelSize: Style.fontSizeL || 18
        font.bold: true
        color: Style.textColor || "#FFFFFF"
    }

    // Hint
    Text {
        text: "Paste JSON to customize symbols:"
        font.pixelSize: Style.fontSizeS || 12
        color: Style.textColorSecondary || "#AAAAAA"
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
    }

    // JSON Editor
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Style.fillColorSecondary || "#2A2A2A"
        radius: Style.radiusS || 4

        TextEdit {
            id: textEdit
            anchors.fill: parent
            anchors.margins: Style.marginS
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            font.family: "monospace"
            font.pixelSize: Style.fontSizeS || 12
            color: Style.textColor || "#FFFFFF"
            text: root.jsonText
            onTextChanged: root.jsonText = text
        }
    }

    // Buttons
    RowLayout {
        Layout.fillWidth: true

        NButton {
            text: "Reset"
            onClicked: {
                textEdit.text = JSON.stringify(defaultGestureSymbols, null, 2);
            }
        }

        Item { Layout.fillWidth: true }

        NButton {
            text: "Save"
            onClicked: {
                try {
                    const parsed = JSON.parse(textEdit.text);
                    if (!pluginApi.pluginSettings) pluginApi.pluginSettings = {};
                    pluginApi.pluginSettings.gestureSymbols = JSON.stringify(parsed);
                    pluginApi.saveSettings();
                    saveLabel.text = "Saved!";
                    saveLabel.color = "#4CAF50";
                } catch (e) {
                    saveLabel.text = "Invalid JSON";
                    saveLabel.color = "#F44336";
                }
            }
        }
    }

    Text {
        id: saveLabel
        text: ""
        font.pixelSize: Style.fontSizeS || 12
        color: "#4CAF50"
    }
}
