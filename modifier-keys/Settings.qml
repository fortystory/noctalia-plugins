import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

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

    property var cfg: pluginApi?.pluginSettings || {}

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
        text: pluginApi?.tr("settings.title", "Gesture Symbols") || "Gesture Symbols"
        font.pixelSize: Style.fontSizeL || 18
        font.bold: true
        color: Style.textColor || "#FFFFFF"
    }

    // Hint
    Text {
        text: pluginApi?.tr("settings.hint", "Paste JSON to customize symbols:") || "Paste JSON to customize symbols:"
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

        Flickable {
            id: flickable
            anchors.fill: parent
            anchors.margins: Style.marginS
            contentWidth: textEdit.contentWidth
            contentHeight: textEdit.contentHeight
            clip: true

            TextEdit {
                id: textEdit
                width: flickable.width - Style.marginS * 2
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                font.family: "monospace"
                font.pixelSize: Style.fontSizeS || 12
                color: Style.textColor || "#FFFFFF"
                text: root.jsonText
                onTextChanged: root.jsonText = text
            }
        }
    }

    // Buttons
    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
            text: pluginApi?.tr("settings.reset", "Reset") || "Reset"
            onClicked: {
                textEdit.text = JSON.stringify(defaultGestureSymbols, null, 2);
            }
        }

        Item { Layout.fillWidth: true }

        NButton {
            text: pluginApi?.tr("settings.save", "Save") || "Save"
            onClicked: {
                try {
                    const parsed = JSON.parse(textEdit.text);
                    if (!pluginApi.pluginSettings) pluginApi.pluginSettings = {};
                    pluginApi.pluginSettings.gestureSymbols = JSON.stringify(parsed);
                    pluginApi.saveSettings();
                    toastText.text = pluginApi?.tr("settings.saved", "Saved!") || "Saved!";
                    toast.visible = true;
                    toastTimer.start();
                } catch (e) {
                    toastText.text = pluginApi?.tr("settings.invalid", "Invalid JSON") || "Invalid JSON";
                    toast.visible = true;
                    toastTimer.start();
                }
            }
        }
    }

    // Toast
    Rectangle {
        id: toast
        visible: false
        color: Style.accentColor || "#4CAF50"
        radius: Style.radiusS || 4
        padding: Style.marginS || 8
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Text {
            id: toastText
            text: ""
            color: "#FFFFFF"
            font.pixelSize: Style.fontSizeS || 12
        }
    }

    Timer {
        id: toastTimer
        interval: 1500
        onTriggered: toast.visible = false
    }
}
