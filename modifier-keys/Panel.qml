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
    property real contentPreferredHeight: 200 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

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

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
