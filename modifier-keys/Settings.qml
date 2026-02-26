import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: settingsContainer
    property real contentPreferredWidth: 400 * Style.uiScaleRatio
    property real contentPreferredHeight: 300 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    // Default gesture symbols
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
        if (!pluginApi) return defaultGestureSymbols;
        const saved = pluginApi.getSetting("gestureSymbols", "");
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

    Rectangle {
        id: settingsContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
                text: pluginApi?.tr("settings.title", "Gesture Symbols Settings") || "Gesture Symbols Settings"
                pointSize: Style.fontSizeL
                font.bold: true
                color: Color.mOnSurface
            }

            NText {
                text: pluginApi?.tr("settings.hint", "Paste JSON to customize gesture symbols:") || "Paste JSON to customize gesture symbols:"
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceContainer
                radius: Style.radiusS
                border.color: Color.mOutlineVariant
                border.width: 1

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    contentWidth: textEdit.width
                    contentHeight: textEdit.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: textEdit
                        width: flickable.width - Style.marginS * 2
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        font.family: "monospace"
                        font.pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        text: JSON.stringify(getGestureSymbols(), null, 2)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginS

                NButton {
                    text: pluginApi?.tr("settings.reset", "Reset") || "Reset"
                    onClicked: {
                        textEdit.text = JSON.stringify(defaultGestureSymbols, null, 2);
                    }
                }

                Item { Layout.fillWidth: true }

                NButton {
                    text: pluginApi?.tr("settings.save", "Save") || "Save"
                    primary: true
                    onClicked: {
                        try {
                            const parsed = JSON.parse(textEdit.text);
                            pluginApi.setSetting("gestureSymbols", JSON.stringify(parsed));
                            toast.show(pluginApi?.tr("settings.saved", "Saved!") || "Saved!");
                        } catch (e) {
                            toast.show(pluginApi?.tr("settings.invalid", "Invalid JSON") || "Invalid JSON");
                        }
                    }
                }
            }
        }

        NToast {
            id: toast
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
