// Panel.qml - 开发者工具面板 (Noctalia Panel 入口)
import QtQuick
import Quickshell
import qs.Widgets

Item {
    id: root

    // ==================== Noctalia Panel 必需属性 ====================
    required property var pluginApi
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 500
    property real contentPreferredHeight: 400

    // ==================== 面板容器 ====================
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        // 面板内容区域
        Rectangle {
            id: panelContent
            width: Math.min(parent.width - 40, root.contentPreferredWidth)
            height: Math.min(parent.height - 40, root.contentPreferredHeight)
            anchors.centerIn: parent
            radius: 12
            color: Style.color.surface
            border.width: 1
            border.color: Style.color.outline

            // 标题栏
            Rectangle {
                id: titleBar
                width: parent.width
                height: 40
                radius: parent.radius
                color: Style.color.surfaceVariant

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("Developer Tools")
                    font.pixelSize: 14
                    font.bold: true
                    color: Style.color.onSurface
                }

                // 关闭按钮（使用 Text 代替 NButton）
                Text {
                    id: closeButton
                    anchors {
                        right: parent.right
                        rightMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    text: "×"
                    font.pixelSize: 20
                    color: Style.color.onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pluginApi.closePanel(pluginApi.panelOpenScreen)
                        }
                    }
                }
            }

            // 内容区域
            Rectangle {
                id: contentArea
                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: parent.bottom
                }
                color: Style.color.surface

                Column {
                    anchors {
                        fill: parent
                        margins: 20
                    }
                    spacing: 15

                    Text {
                        text: qsTr("时间戳工具")
                        font.pixelSize: 16
                        font.bold: true
                        color: Style.color.onSurface
                    }

                    Text {
                        text: qsTr("当前时间戳（秒）: ") + Math.floor(Date.now() / 1000)
                        color: Style.color.onSurfaceVariant
                    }

                    Text {
                        text: qsTr("当前时间戳（毫秒）: ") + Date.now()
                        color: Style.color.onSurfaceVariant
                    }

                    Text {
                        text: qsTr("JSON 工具")
                        font.pixelSize: 16
                        font.bold: true
                        color: Style.color.onSurface
                        anchors.topMargin: 30
                    }

                    Text {
                        text: qsTr("JSON 格式化功能开发中...")
                        color: Style.color.onSurfaceVariant
                    }
                }
            }
        }

        // 点击外部关闭
        MouseArea {
            anchors.fill: parent
            onClicked: {
                pluginApi.closePanel(pluginApi.panelOpenScreen)
            }
        }
    }
}
