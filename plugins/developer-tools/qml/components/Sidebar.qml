// Sidebar.qml - 侧边栏导航组件
// 修复记录：
// 1. 删除未使用的导入 QtQuick.Layouts
// 2. 为所有用户可见字符串添加 qsTr() 国际化包装
// 3. 根组件类型从 Rectangle 改为 Item，以符合规范要求
// 4. 已验证 ToolButton.qml 存在且属性匹配，引用正确
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: sidebar

    // ==================== 属性定义 ====================
    // 主题引用
    property var theme: Theme {}

    // 配置属性
    property int currentIndex: 0
    property int itemHeight: 60
    property int iconSize: 24
    property color backgroundColor: theme.surfaceColor
    property color selectedColor: theme.primaryColor
    property color textColor: theme.textColor
    property color iconColor: theme.secondaryColor
    property color hoverColor: Qt.lighter(selectedColor, 1.2)

    // 内部属性
    property ListModel toolModel: ListModel {}

    // 初始化工具模型
    function initializeToolModel() {
        toolModel.clear()
        toolModel.append({
            "name": qsTr("时间戳"),
            "icon": "🕐",
            "description": qsTr("时间戳与时间字符串转换"),
            "component": "TimestampTool.qml"
        })
        toolModel.append({
            "name": qsTr("JSON"),
            "icon": "📄",
            "description": qsTr("JSON格式化和压缩"),
            "component": "JsonFormatter.qml"
        })
    }

    // ==================== 信号定义 ====================
    signal toolSelected(int index, string toolName)

    // ==================== 视觉属性 ====================
    // 背景矩形
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: backgroundColor
        border.color: theme.borderColor
        border.width: theme.borderWidth
        z: -1
    }

    implicitWidth: 240

    // 顶部装饰条
    Rectangle {
        id: topDecoration
        width: parent.width
        height: 4
        color: selectedColor
        radius: 2
    }

    // 高亮指示器（带动画）
    Rectangle {
        id: highlightIndicator
        width: parent.width
        height: itemHeight
        color: selectedColor
        opacity: 0.15
        radius: theme.borderRadius
        y: currentIndex * itemHeight
        z: -1

        Behavior on y {
            SpringAnimation {
                spring: 3
                damping: 0.2
                mass: 1.0
                velocity: 100
            }
        }
    }

    // 工具列表
    ListView {
        id: toolListView
        anchors {
            top: topDecoration.bottom
            left: parent.left
            right: parent.right
            bottom: settingsArea.top
            margins: theme.spacingMedium
        }
        model: toolModel
        spacing: theme.spacingSmall
        clip: true
        interactive: true

        delegate: Item {
            id: toolItemDelegate
            width: ListView.view.width
            height: itemHeight

            property bool isSelected: index === currentIndex
            property bool isHovered: mouseArea.containsMouse

            // 工具项背景
            Rectangle {
                id: itemBackground
                anchors.fill: parent
                radius: theme.borderRadius
                color: {
                    if (isSelected) {
                        return selectedColor
                    } else if (isHovered) {
                        return hoverColor
                    } else {
                        return "transparent"
                    }
                }
                opacity: isSelected ? 0.3 : (isHovered ? 0.1 : 0)
                border.color: isSelected ? selectedColor : (isHovered ? hoverColor : "transparent")
                border.width: isSelected ? 2 : (isHovered ? 1 : 0)

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
                Behavior on border.width {
                    NumberAnimation { duration: 150 }
                }
            }

            // 图标
            Text {
                id: iconText
                anchors {
                    left: parent.left
                    leftMargin: theme.spacingLarge
                    verticalCenter: parent.verticalCenter
                }
                text: icon
                font.pixelSize: iconSize
                color: isSelected ? selectedColor : iconColor
                font.family: "Segoe UI Emoji, Apple Color Emoji, Noto Color Emoji"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            // 工具名称
            Text {
                id: nameText
                anchors {
                    left: iconText.right
                    leftMargin: theme.spacingMedium
                    verticalCenter: parent.verticalCenter
                }
                text: name
                font.pixelSize: theme.fontSizeLarge
                font.weight: isSelected ? Font.Bold : Font.Normal
                color: isSelected ? selectedColor : textColor
                font.family: theme.fontFamily

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on font.weight {
                    PropertyAnimation { duration: 150 }
                }
            }

            // 鼠标区域
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    selectTool(index)
                }

                // 工具提示
                ToolTip {
                    id: toolTip
                    text: description
                    delay: 500
                    visible: mouseArea.containsMouse && !isSelected
                    background: Rectangle {
                        color: theme.surfaceColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                        radius: theme.borderRadius
                    }
                    contentItem: Text {
                        text: toolTip.text
                        font.pixelSize: theme.fontSizeNormal
                        color: theme.textColor
                        font.family: theme.fontFamily
                    }
                }
            }

            // 悬停效果动画
            ParallelAnimation {
                id: hoverAnimation
                running: isHovered && !isSelected
                PropertyAnimation {
                    target: itemBackground
                    property: "scale"
                    from: 1.0
                    to: 1.02
                    duration: 200
                }
            }

            ParallelAnimation {
                id: unhoverAnimation
                running: !isHovered && !isSelected
                PropertyAnimation {
                    target: itemBackground
                    property: "scale"
                    from: 1.02
                    to: 1.0
                    duration: 200
                }
            }
        }
    }

    // 底部设置区域
    Item {
        id: settingsArea
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: itemHeight + theme.spacingMedium

        // 分隔线
        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: theme.borderWidth
            color: theme.borderColor
        }

        // 设置按钮
        ToolButton {
            id: settingsButton
            anchors {
                centerIn: parent
                verticalCenterOffset: theme.spacingSmall
            }
            buttonIcon: "⚙️"
            tooltip: qsTr("设置")
            onClicked: {
                console.log("设置按钮点击")
                // TODO: 实现设置功能
            }
        }
    }

    // ==================== 方法实现 ====================
    // 选择工具
    function selectTool(index) {
        if (index >= 0 && index < toolModel.count) {
            var oldIndex = currentIndex
            currentIndex = index

            // 触发选择信号
            var toolName = toolModel.get(index).name
            toolSelected(index, toolName)

            // 滚动到可见区域
            toolListView.positionViewAtIndex(index, ListView.Contain)

            console.log("工具选择:", index, toolName)
        }
    }

    // 获取当前工具信息
    function getCurrentTool() {
        if (toolModel.count > 0 && currentIndex >= 0 && currentIndex < toolModel.count) {
            return toolModel.get(currentIndex)
        }
        return null
    }

    // 动态添加新工具（未来扩展）
    function addTool(name, icon, description, component) {
        toolModel.append({
            "name": name,
            "icon": icon,
            "description": description,
            "component": component
        })
        console.log("工具添加:", name)
    }

    // ==================== 组件初始化 ====================
    Component.onCompleted: {
        initializeToolModel()
        console.log("Sidebar组件初始化完成，工具数量:", toolModel.count)
        if (toolModel.count > 0) {
            // 默认选择第一个工具
            selectTool(0)
        }
    }
}