import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 280 * Style.uiScaleRatio
    property real contentPreferredHeight: 600 * Style.uiScaleRatio
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
                    { icon: "\u2318", name: pluginApi?.tr("super", "Super (Win)") || "Super (Win)", key: "Meta" },
                    { icon: "\u2325", name: pluginApi?.tr("alt", "Alt") || "Alt", key: "Alt" },
                    { icon: "\u2303", name: pluginApi?.tr("ctrl", "Ctrl") || "Ctrl", key: "Ctrl" },
                    { icon: "\u21e7", name: pluginApi?.tr("shift", "Shift") || "Shift", key: "Shift" }
                ]

                RowLayout {
                    spacing: Style.marginM
                    Layout.fillWidth: true

                    NText {
                        text: modelData.icon
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
                    NText { text: "󰆽"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 48 }
                    NText { text: pluginApi?.tr("motion", "Motion") || "Motion"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "󰳽"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 48 }
                    NText { text: pluginApi?.tr("click", "Click") || "Click"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "⮆ ⮇,⮄ ⮅"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 48 }
                    NText { text: pluginApi?.tr("scroll", "Scroll") || "Scroll"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "🡆 🡇 🡄 🡅"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 48 }
                    NText { text: pluginApi?.tr("swipe3", "3-Finger Swipe") || "3-Finger Swipe"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "⭲ ⭳ ⭰ ⭱"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 48 }
                    NText { text: pluginApi?.tr("swipe4", "4-Finger Swipe") || "4-Finger Swipe"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
                RowLayout {
                    NText { text: "󰘖 󰘕"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 48 }
                    NText { text: pluginApi?.tr("pinch", "Pinch") || "Pinch"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Settings button
            NButton {
                text: pluginApi?.tr("settings", "Symbol Settings") || "Symbol Settings"
                Layout.fillWidth: true
                onClicked: {
                    try {
                        pluginApi.openSettings(root.screen, root);
                    } catch (e) {
                        try {
                            pluginApi.openSettings(screen);
                        } catch (err) {
                            // Fallback: try to open settings via panel
                            Logger.d("Modifier Keys", "Settings not available");
                        }
                    }
                }
            }

            // Hint
            NText {
                text: pluginApi?.tr("hint", "Right-click bar widget to open settings") || "Right-click bar widget to open settings"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
