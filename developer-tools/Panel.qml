// Panel.qml - 开发者工具面板 (Noctalia Panel 入口)
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import "qml/components" as Components

Item {
    id: root

    // Noctalia Panel 必需属性
    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 600
    property real contentPreferredHeight: 450
    readonly property bool allowAttach: true

    anchors.fill: parent

    // 面板容器
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        // 面板内容区域
        Rectangle {
            id: panelContent
            anchors.centerIn: parent
            width: Math.min(parent.width - Style.marginXL * 2, root.contentPreferredWidth)
            height: Math.min(parent.height - Style.marginXL * 2, root.contentPreferredHeight)
            radius: Style.radiusL
            color: Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: Style.borderS

            // 布局
            RowLayout {
                anchors {
                    fill: parent
                    margins: Style.marginS
                }
                spacing: Style.marginS

                // 左侧 Sidebar
                Components.Sidebar {
                    id: sidebar
                    Layout.fillHeight: true
                }

                // 分隔线
                Rectangle {
                    width: 1
                    Layout.fillHeight: true
                    color: Color.mOutline
                    opacity: 0.3
                }

                // 右侧内容区 - StackLayout
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Style.radiusS
                    color: Color.mSurface

                    StackLayout {
                        anchors {
                            fill: parent
                            margins: Style.marginM
                        }
                        currentIndex: sidebar.currentIndex

                        Components.TimestampTool {
                            id: timestampTool
                        }

                        Components.JSONTool {
                            id: jsonTool
                        }
                    }
                }
            }
        }
    }
}
