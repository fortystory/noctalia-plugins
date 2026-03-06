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

    function getEditModifierSymbols() {
        if (!pluginApi) return "";
        var settings = pluginApi.pluginSettings;
        if (settings && settings.modifierSymbols) return settings.modifierSymbols;
        var defaults = pluginApi.manifest?.metadata?.defaultSettings;
        if (defaults && defaults.modifierSymbols) return defaults.modifierSymbols;
        return "";
    }

    function setEditModifierSymbols(value) {
        if (!pluginApi) return;
        if (!pluginApi.pluginSettings) pluginApi.pluginSettings = {};
        pluginApi.pluginSettings.modifierSymbols = value;
    }

    readonly property var defaultGestureSymbols: {
        "scroll": ["⥤", "⥥", "⥢", "⥣"],
        "swipe3": ["🡆", "🡇", "🡄", "🡅"],
        "swipe4": ["⭲", "⭳", "⭰", "⭱"],
        "click": "󰳽",
        "rightClick": "󰳾",
        "middleClick": "󰻃",
        "motion": "󰆽",
        "pinchIn": "󰘖",
        "pinchOut": "󰘕"
    }

    readonly property var defaultModifierSymbols: {
        "super": "⌘",
        "alt": "⌥",
        "ctrl": "⌃",
        "shift": "🡅"
    }

    function getDefaultGestureJson() {
        return JSON.stringify(defaultGestureSymbols, null, 2);
    }

    function getDefaultModifierJson() {
        return JSON.stringify(defaultModifierSymbols, null, 2);
    }

    function getCurrentGestureJson() {
        var saved = getEditSymbols();
        if (saved && saved.toString().trim() !== "") {
            return saved;
        }
        return getDefaultGestureJson();
    }

    function getCurrentModifierJson() {
        var saved = getEditModifierSymbols();
        if (saved && saved.toString().trim() !== "") {
            return saved;
        }
        return getDefaultModifierJson();
    }

    NLabel {
        label: pluginApi?.tr("settings.modifier.label", "Modifier Key Symbols") || "Modifier Key Symbols"
        description: pluginApi?.tr("settings.modifier.desc", "Customize modifier key display symbols (JSON format)") || "Customize modifier key display symbols (JSON format)"
    }

    NTextInput {
        id: modifierJsonInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.modifier.json", "JSON") || "JSON"
        placeholderText: getDefaultModifierJson()
        text: getCurrentModifierJson()
        onTextChanged: setEditModifierSymbols(text)
    }

    RowLayout {
        NButton {
            text: pluginApi?.tr("settings.modifier.copy", "Copy") || "Copy"
            onClicked: {
                var textToCopy = modifierJsonInput.text || getDefaultModifierJson();
                Quickshell.clipboardText = textToCopy;
            }
        }

        NButton {
            text: pluginApi?.tr("settings.modifier.reset", "Reset") || "Reset"
            onClicked: {
                setEditModifierSymbols(getDefaultModifierJson());
                modifierJsonInput.text = getDefaultModifierJson();
            }
        }

        NButton {
            text: pluginApi?.tr("settings.modifier.useDefault", "Use Defaults") || "Use Defaults"
            onClicked: {
                setEditModifierSymbols("");
                modifierJsonInput.text = getDefaultModifierJson();
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        label: pluginApi?.tr("settings.modifierKeys", "Modifier Keys") || "Modifier Keys"
        description: "super, alt, ctrl, shift"
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        label: pluginApi?.tr("settings.gesture.label", "Gesture Symbols") || "Gesture Symbols"
        description: pluginApi?.tr("settings.gesture.desc", "Customize gesture display symbols (JSON format)") || "Customize gesture display symbols (JSON format)"
    }

    NTextInput {
        id: jsonInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.gesture.json", "JSON") || "JSON"
        placeholderText: getDefaultGestureJson()
        text: getCurrentGestureJson()
        onTextChanged: setEditSymbols(text)
    }

    RowLayout {
        NButton {
            text: pluginApi?.tr("settings.gesture.copy", "Copy") || "Copy"
            onClicked: {
                var textToCopy = jsonInput.text || getDefaultGestureJson();
                Quickshell.clipboardText = textToCopy;
            }
        }

        NButton {
            text: pluginApi?.tr("settings.gesture.reset", "Reset") || "Reset"
            onClicked: {
                setEditSymbols(getDefaultGestureJson());
                jsonInput.text = getDefaultGestureJson();
            }
        }

        NButton {
            text: pluginApi?.tr("settings.gesture.useDefault", "Use Defaults") || "Use Defaults"
            onClicked: {
                setEditSymbols("");
                jsonInput.text = getDefaultGestureJson();
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        label: pluginApi?.tr("settings.gestureKeys", "Gesture Keys") || "Gesture Keys"
        description: "scroll, swipe3, swipe4, click, rightClick, middleClick, motion, pinchIn, pinchOut"
    }

    // Save function - called by the dialog
    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Modifier Keys", "Cannot save: pluginApi is null");
            return;
        }

        var gestureJsonStr = jsonInput.text || getDefaultGestureJson();
        var modifierJsonStr = modifierJsonInput.text || getDefaultModifierJson();

        // Validate JSON if not empty
        if (gestureJsonStr && gestureJsonStr.toString().trim() !== "") {
            try {
                JSON.parse(gestureJsonStr);
            } catch (e) {
                Logger.e("Modifier Keys", "Invalid gesture JSON:", e);
            }
        }

        if (modifierJsonStr && modifierJsonStr.toString().trim() !== "") {
            try {
                JSON.parse(modifierJsonStr);
            } catch (e) {
                Logger.e("Modifier Keys", "Invalid modifier JSON:", e);
            }
        }

        setEditSymbols(gestureJsonStr);
        setEditModifierSymbols(modifierJsonStr);
        pluginApi.saveSettings();
        Logger.i("Modifier Keys", "Settings saved");
    }
}
