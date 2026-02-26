import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

    // Local state
    property string editSymbols:
        pluginApi?.pluginSettings?.gestureSymbols ||
        pluginApi?.manifest?.metadata?.defaultSettings?.gestureSymbols ||
        ""

    readonly property var defaultGestureSymbols: {
        "scroll": ["⮆", "⮇", "⮄", "⮅"],
        "swipe3": ["🡆", "🡇", "🡄", "🡅"],
        "swipe4": ["⭲", "⭳", "⭰", "⭱"],
        "click": "󰳽",
        "rightClick": "󰳾",
        "middleClick": "󰻃",
        "motion": "󰆽",
        "pinchIn": "󰘖",
        "pinchOut": "󰘕"
    }

    function getDefaultJson() {
        return JSON.stringify(defaultGestureSymbols, null, 2);
    }

    NLabel {
        label: pluginApi?.tr("settings.label", "Gesture Symbols") || "Gesture Symbols"
        description: pluginApi?.tr("settings.desc", "Customize gesture display symbols (JSON format)") || "Customize gesture display symbols (JSON format)"
    }

    NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.json", "JSON") || "JSON"
        placeholderText: getDefaultJson()
        text: root.editSymbols || getDefaultJson()
        onTextChanged: root.editSymbols = text
    }

    RowLayout {
        NButton {
            text: pluginApi?.tr("settings.copy", "Copy") || "Copy"
            onClicked: {
                // Copy current text to clipboard
                Qt.application.clipboard.text = root.editSymbols || getDefaultJson();
            }
        }

        NButton {
            text: pluginApi?.tr("settings.reset", "Reset") || "Reset"
            onClicked: {
                root.editSymbols = getDefaultJson();
            }
        }

        NButton {
            text: pluginApi?.tr("settings.useDefault", "Use Defaults") || "Use Defaults"
            onClicked: {
                root.editSymbols = "";
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        label: pluginApi?.tr("settings.keys", "Available Keys") || "Available Keys"
        description: "scroll, swipe3, swipe4, click, rightClick, middleClick, motion, pinchIn, pinchOut"
    }

    // Save function - called by the dialog
    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Modifier Keys", "Cannot save: pluginApi is null");
            return;
        }

        // Validate JSON if not empty
        if (root.editSymbols && root.editSymbols.trim() !== "") {
            try {
                JSON.parse(root.editSymbols);
            } catch (e) {
                Logger.e("Modifier Keys", "Invalid JSON:", e);
            }
        }

        pluginApi.pluginSettings.gestureSymbols = root.editSymbols;
        pluginApi.saveSettings();
        Logger.i("Modifier Keys", "Settings saved");
    }
}
