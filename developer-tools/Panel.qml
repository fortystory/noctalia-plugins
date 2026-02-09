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
    property real contentPreferredWidth: 680
    property real contentPreferredHeight: 540

    // ==================== 当前工具组件 ====================
    property var currentTool: null

    // ==================== 设置对话框引用 ====================
    property var settingsDialog: null

    // ==================== 面板容器 ====================
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"  // 透明背景，点击关闭

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

            // ==================== 标题栏 ====================
            Rectangle {
                id: titleBar
                width: parent.width
                height: 40
                radius: parent.radius
                color: Style.color.surfaceVariant
                border.width: 1
                border.color: Style.color.outline

                // 拖拽区域
                MouseArea {
                    anchors.fill: parent
                    drag.target: panelContent
                    drag.axis: Drag.XAndYAxis
                }

                // 标题
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("开发者工具")
                    font.pixelSize: 14
                    font.bold: true
                    color: Style.color.onSurface
                }

                // 关闭按钮
                NButton {
                    id: closeButton
                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: "×"
                    onClicked: {
                        pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }
                }
            }

            // ==================== 主内容区域 ====================
            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: parent.bottom
                    margins: 10
                }
                spacing: 10

                // 侧边栏 - 简化版本
                Rectangle {
                    id: sidebar
                    width: 80
                    Layout.fillHeight: true
                    color: Style.color.surfaceVariant
                    radius: 8

                    // 工具列表
                    Column {
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        spacing: 8

                        // 时间戳工具按钮
                        Rectangle {
                            width: parent.width - 16
                            height: 50
                            radius: 8
                            color: sidebarTool1.hovered ? Style.color.primaryContainer : Style.color.surface
                            border.width: sidebarTool1.hovered ? 2 : 0
                            border.color: Style.color.primary

                            Text {
                                anchors.centerIn: parent
                                text: "🕐"
                                font.pixelSize: 20
                            }

                            MouseArea {
                                id: sidebarTool1
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: loadTimestampTool()
                            }
                        }

                        // JSON工具按钮
                        Rectangle {
                            width: parent.width - 16
                            height: 50
                            radius: 8
                            color: sidebarTool2.hovered ? Style.color.primaryContainer : Style.color.surface
                            border.width: sidebarTool2.hovered ? 2 : 0
                            border.color: Style.color.primary

                            Text {
                                anchors.centerIn: parent
                                text: "📄"
                                font.pixelSize: 20
                            }

                            MouseArea {
                                id: sidebarTool2
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: loadJsonTool()
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // 工具内容区域
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Style.color.surface
                    radius: 8

                    // 时间戳工具
                    Column {
                        id: timestampTool
                        anchors {
                            fill: parent
                            margins: 20
                        }
                        visible: true
                        spacing: 15

                        Text {
                            text: qsTr("时间戳转换")
                            font.pixelSize: 18
                            font.bold: true
                            color: Style.color.onSurface
                        }

                        Text {
                            text: qsTr("当前时间戳（秒）:")
                            color: Style.color.onSurfaceVariant
                        }

                        Text {
                            id: currentTimestamp
                            text: Math.floor(Date.now() / 1000).toString()
                            font.pixelSize: 24
                            font.bold: true
                            color: Style.color.primary
                        }

                        Text {
                            text: qsTr("当前时间戳（毫秒）:")
                            color: Style.color.onSurfaceVariant
                        }

                        Text {
                            text: Date.now().toString()
                            font.pixelSize: 24
                            font.bold: true
                            color: Style.color.primary
                        }

                        Item { Layout.fillHeight: true }
                    }

                    // JSON 工具（默认隐藏）
                    Rectangle {
                        id: jsonTool
                        anchors {
                            fill: parent
                            margins: 20
                        }
                        visible: false
                        color: Style.color.surface

                        Text {
                            text: qsTr("JSON 格式化")
                            font.pixelSize: 18
                            font.bold: true
                            color: Style.color.onSurface
                        }

                        Text {
                            anchors.topMargin: 20
                            text: qsTr("输入 JSON:")
                            color: Style.color.onSurfaceVariant
                        }
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

    // ==================== 工具加载函数 ====================
    function loadTimestampTool() {
        timestampTool.visible = true
        jsonTool.visible = false
    }

    function loadJsonTool() {
        timestampTool.visible = false
        jsonTool.visible = true
    }
}
