import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    // Load modifier symbols from settings
    function loadModifierSymbols() {
        if (!pluginApi) return defaultModifierSymbols;
        const cfg = pluginApi.pluginSettings || {};
        const saved = cfg.modifierSymbols || "";
        if (!saved || saved.trim() === "") return defaultModifierSymbols;
        try {
            const parsed = JSON.parse(saved);
            var result = {};
            for (var k in defaultModifierSymbols) result[k] = defaultModifierSymbols[k];
            for (var k in parsed) result[k] = parsed[k];
            return result;
        } catch (e) {
            return defaultModifierSymbols;
        }
    }

    readonly property var defaultModifierSymbols: ({
        "super": "⌘",
        "alt": "⌥",
        "ctrl": "⌃",
        "shift": "🡅"
    })

    property var modifierSymbols: loadModifierSymbols()

    readonly property var panelGeometry: panelContainer
    property real contentPreferredWidth: 280 * Style.uiScaleRatio
    property real contentPreferredHeight: 350 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            // Title
            NText {
                text: pluginApi?.tr("title", "Modifier Keys") || "Modifier Keys"
                pointSize: Style.fontSizeL
                font.bold: true
                color: Color.mOnSurface
                Layout.alignment: Qt.AlignHCenter
            }

            NDivider {
                Layout.fillWidth: true
            }

            // Key list
            Repeater {
                model: [
                    { key: "Meta", name: pluginApi?.tr("super", "Super (Win)") || "Super (Win)" },
                    { key: "Alt", name: pluginApi?.tr("alt", "Alt") || "Alt" },
                    { key: "Ctrl", name: pluginApi?.tr("ctrl", "Ctrl") || "Ctrl" },
                    { key: "Shift", name: pluginApi?.tr("shift", "Shift") || "Shift" }
                ]

                RowLayout {
                    spacing: Style.marginM
                    Layout.fillWidth: true

                    NText {
                        text: root.modifierSymbols[modelData.key.toLowerCase()] || "?"
                        pointSize: Style.fontSizeL
                        color: Color.mPrimary
                        Layout.preferredWidth: 30
                        Layout.alignment: Qt.AlignHCenter
                    }

                    NText {
                        text: modelData.name
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NText {
                        text: modelData.key
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            // Gesture legend
            NText {
                text: pluginApi?.tr("gestures", "Gestures") || "Gestures"
                pointSize: Style.fontSizeM
                font.bold: true
                color: Color.mOnSurface
            }

            ColumnLayout {
                spacing: 4

                RowLayout {
                    NText { text: "󰆽"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                    NText { text: pluginApi?.tr("motion", "Motion") || "Motion"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "󰳽"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                    NText { text: pluginApi?.tr("click", "Click") || "Click"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "⥤ ⥥ ⥢ ⥣"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                    NText { text: pluginApi?.tr("scroll", "Scroll") || "Scroll"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "🡆 🡇 🡄 🡅"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                    NText { text: pluginApi?.tr("swipe3", "3-Finger Swipe") || "3-Finger Swipe"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "⭲ ⭳ ⭰ ⭱"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                    NText { text: pluginApi?.tr("swipe4", "4-Finger Swipe") || "4-Finger Swipe"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "󰘖  󰘕"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                    NText { text: pluginApi?.tr("pinch", "Pinch") || "Pinch"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
