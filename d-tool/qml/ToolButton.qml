// ToolButton.qml - 状态栏按钮组件
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import org.noctalia.shell 1.0

Button {
    id: toolButton

    // 公共属性
    property string buttonIcon: "🛠️"
    property string tooltip: qsTr("开发者工具")
    property bool windowVisible: false

    // 信号定义
    signal toggleWindow()

    // 按钮尺寸
    width: 40
    height: 40

    // 基础颜色（蓝色主题）
    property color baseColor: "#3b82f6"
    property color hoverColor: Qt.lighter(baseColor, 1.2)
    property color pressedColor: Qt.darker(baseColor, 1.2)
    property color activeColor: Qt.darker(baseColor, 1.4)

    // 当前显示的颜色（根据状态计算）
    property color displayColor: windowVisible ? activeColor :
        (toolButton.down ? pressedColor :
            (toolButton.hovered ? hoverColor : baseColor))

    // 文本内容（图标）
    text: buttonIcon
    font.pixelSize: 18
    font.family: "Segoe UI Emoji, Noto Color Emoji, sans-serif"

    // 背景
    background: Rectangle {
        id: buttonBackground
        radius: 4
        color: displayColor
        border.width: 1
        border.color: Qt.darker(baseColor, 1.3)

        // 内阴影效果
        layer.enabled: true
        layer.effect: InnerShadow {
            horizontalOffset: 0
            verticalOffset: 1
            radius: 3
            samples: 17
            color: "#00000040"
            spread: 0.3
        }
    }

    // 点击处理
    onClicked: {
        windowVisible = !windowVisible
        toggleWindow()
    }

    // 工具提示
    ToolTip {
        visible: toolButton.hovered && tooltip !== ""
        delay: 500
        text: tooltip
    }

    // 键盘快捷键支持（Ctrl+Shift+D）
    Shortcut {
        sequence: "Ctrl+Shift+D"
        onActivated: {
            windowVisible = !windowVisible
            toggleWindow()
        }
    }

    // 状态变化动画
    Behavior on displayColor {
        ColorAnimation {
            duration: 150
        }
    }
}