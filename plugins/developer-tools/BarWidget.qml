// BarWidget.qml - 状态栏按钮组件 (Noctalia bar-widget 入口)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import org.noctalia.shell 1.0

Item {
    id: barWidget

    // Noctalia bar-widget 必需属性
    required property var pluginApi
    required property var screen
    property string widgetId: "dev.fortystory.developer-tools"
    property string section: "center"  // left, center, right

    // 尺寸属性
    implicitWidth: 40
    implicitHeight: 40

    // 公共属性
    property string buttonIcon: "🛠️"
    property string tooltip: qsTr("Developer Tools")
    property bool windowVisible: false

    // 基础颜色（蓝色主题）
    property color baseColor: "#3b82f6"
    property color hoverColor: Qt.lighter(baseColor, 1.2)
    property color pressedColor: Qt.darker(baseColor, 1.2)
    property color activeColor: Qt.darker(baseColor, 1.4)

    // 当前显示的颜色
    property color displayColor: windowVisible ? activeColor :
        (mouseArea.pressed ? pressedColor :
            (mouseArea.containsMouse ? hoverColor : baseColor))

    // 主按钮
    Rectangle {
        id: buttonBackground
        anchors.fill: parent
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

        // 图标文本
        Text {
            anchors.centerIn: parent
            text: buttonIcon
            font.pixelSize: 18
            font.family: "Segoe UI Emoji, Noto Color Emoji, sans-serif"
        }
    }

    // 鼠标交互区域
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            windowVisible = !windowVisible
            toggleWindow()
        }
    }

    // 工具提示
    ToolTip {
        visible: mouseArea.containsMouse && tooltip !== ""
        delay: 500
        text: tooltip
    }

    // 键盘快捷键（Ctrl+Shift+D）
    Shortcut {
        sequence: "Ctrl+Shift+D"
        onActivated: {
            windowVisible = !windowVisible
            toggleWindow()
        }
    }

    // 颜色动画
    Behavior on displayColor {
        ColorAnimation { duration: 150 }
    }

    // ==================== 公开方法 ====================
    function toggleWindow() {
        if (!pluginApi) {
            console.warn("BarWidget: pluginApi not available")
            return
        }
        pluginApi.togglePanel(root.screen, root)
    }

    function openPopup() {
        if (!pluginApi) {
            console.warn("BarWidget: pluginApi not available")
            return
        }
        pluginApi.openPanel(root.screen, root)
    }

    function closePopup() {
        windowVisible = false
    }

    // ==================== 样式 ====================
    // 根据 Noctalia 主题调整颜色
    Component.onCompleted: {
        if (pluginApi && pluginApi.style) {
            baseColor = pluginApi.style.primaryColor || "#3b82f6"
        }

        // 监听主题变化
        if (pluginApi) {
            pluginApi.styleChanged.connect(function() {
                if (pluginApi.style) {
                    baseColor = pluginApi.style.primaryColor || "#3b82f6"
                }
            })
        }
    }
}
