import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

    // Use function to safely get settings
    function getEditSymbols() {
        if (!pluginApi) return "";
        var settings = pluginApi.pluginSettings;
        if (settings && settings.gestureSymbols) return settings.gestureSymbols;
        var defaults = pluginApi.manifest?.metadata?.defaultSettings;
        if (defaults && defaults.gestureSymbols) return defaults.gestureSymbols;
        return "";
    }

    function setEditSymbols(value) {
        if (!pluginApi) return;
        if (!pluginApi.pluginSettings) pluginApi.pluginSettings = {};
        pluginApi.pluginSettings.gestureSymbols = value;
    }

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

    function getCurrentJson() {
        var saved = getEditSymbols();
        if (saved && saved.toString().trim() !== "") {
            return saved;
        }
        return getDefaultJson();
    }

    NLabel {
        label: pluginApi?.tr("settings.label", "Gesture Symbols") || "Gesture Symbols"
        description: pluginApi?.tr("settings.desc", "Customize gesture display symbols (JSON format)") || "Customize gesture display symbols (JSON format)"
    }

    NTextInput {
        id: jsonInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.json", "JSON") || "JSON"
        placeholderText: getDefaultJson()
        text: getCurrentJson()
        onTextChanged: setEditSymbols(text)
    }

    RowLayout {
        NButton {
            text: pluginApi?.tr("settings.copy", "Copy") || "Copy"
            onClicked: {
                var textToCopy = jsonInput.text || getDefaultJson();
                Quickshell.clipboardText = textToCopy;
            }
        }

        NButton {
            text: pluginApi?.tr("settings.reset", "Reset") || "Reset"
            onClicked: {
                setEditSymbols(getDefaultJson());
                jsonInput.text = getDefaultJson();
            }
        }

        NButton {
            text: pluginApi?.tr("settings.useDefault", "Use Defaults") || "Use Defaults"
            onClicked: {
                setEditSymbols("");
                jsonInput.text = getDefaultJson();
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        label: qsTr("Available Keys")
        description: "scroll, swipe3, swipe4, click, rightClick, middleClick, motion, pinchIn, pinchOut"
    }

    // Save function - called by the dialog
    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Modifier Keys", "Cannot save: pluginApi is null");
            return;
        }

        var jsonStr = jsonInput.text || getDefaultJson();
        // Validate JSON if not empty
        if (jsonStr && jsonStr.toString().trim() !== "") {
            try {
                JSON.parse(jsonStr);
            } catch (e) {
                Logger.e("Modifier Keys", "Invalid JSON:", e);
            }
        }

        setEditSymbols(jsonStr);
        pluginApi.saveSettings();
        Logger.i("Modifier Keys", "Settings saved");
    }
}
