// Panel.qml - Modifier Keys Panel with Tabs
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property int currentTab: 0  // 0: 帮助, 1: 统计

    readonly property var panelGeometry: panelContainer
    property real contentPreferredWidth: 320 * Style.uiScaleRatio
    property real contentPreferredHeight: 450 * Style.uiScaleRatio
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

            // Tab navigation
            RowLayout {
                id: tabBar
                spacing: 4
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: [
                        { text: "⌨️ " + (pluginApi?.tr("help", "帮助") || "帮助"), tab: 0 },
                        { text: "📊 " + (pluginApi?.tr("stats.title", "统计") || "统计"), tab: 1 }
                    ]

                    delegate: Rectangle {
                        width: tabText.implicitWidth + Style.marginM * 2
                        height: 32
                        color: currentTab === modelData.tab ? Color.mPrimary : "transparent"
                        radius: Style.radiusS
                        border.color: currentTab === modelData.tab ? Color.mPrimary : Color.mOutlineVariant
                        border.width: 1

                        NText {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData.text
                            pointSize: Style.fontSizeM
                            color: currentTab === modelData.tab ? Color.mOnPrimary : Color.mOnSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentTab = modelData.tab
                        }
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            // Tab content
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    sourceComponent: currentTab === 0 ? helpTabComponent : statsTabComponent
                }
            }
        }
    }

    Component {
        id: helpTabComponent
        HelpTab { pluginApi: root.pluginApi }
    }

    Component {
        id: statsTabComponent
        StatsTab { pluginApi: root.pluginApi }
    }
}
