// BarWidget.qml - 状态栏按钮组件 (Noctalia bar-widget 入口)
import QtQuick
import Quickshell
import qs.Widgets

Item {
    id: barWidget

    // Noctalia bar-widget 必需属性
    required property var pluginApi
    required property var screen
    property string widgetId: "developer-tools"
    property string section: "center"  // left, center, right

    // 尺寸属性
    implicitWidth: 40
    implicitHeight: 40

    // 公共属性
    property string buttonIcon: "🛠️"
    property string tooltip: qsTr("Developer Tools")
    property bool windowVisible: false

    // 当前显示的颜色
    property color displayColor: windowVisible ? Style.color.primary :
        (mouseArea.pressed ? Qt.darker(Style.color.primary, 1.2) :
            (mouseArea.containsMouse ? Qt.lighter(Style.color.primary, 1.2) : Style.color.primary))

    // 主按钮
    Rectangle {
        id: buttonBackground
        anchors.fill: parent
        radius: 4
        color: displayColor
    }

    // 图标文本
    Text {
        anchors.centerIn: parent
        text: buttonIcon
        font.pixelSize: 18
    }

    // 鼠标交互区域
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            windowVisible = !windowVisible
            togglePanel()
        }
    }

    // 颜色动画
    Behavior on displayColor {
        ColorAnimation { duration: 150 }
    }

    // ==================== 面板控制 ====================
    function togglePanel() {
        if (!pluginApi) {
            console.warn("BarWidget: pluginApi not available")
            return
        }
        pluginApi.togglePanel(barWidget.screen, barWidget)
    }

    function openPanel() {
        if (!pluginApi) {
            console.warn("BarWidget: pluginApi not available")
            return
        }
        pluginApi.openPanel(barWidget.screen, barWidget)
    }

    function closePanel() {
        windowVisible = false
    }
}
