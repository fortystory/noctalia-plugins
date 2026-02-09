// BarWidget.qml - 状态栏按钮组件 (Noctalia bar-widget 入口)
import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

BarPill {
    id: root

    // Noctalia bar-widget 必需属性
    required property var pluginApi
    required property ShellScreen screen

    // 图标和文本
    icon: "code"
    text: ""

    // 提示文本
    tooltipText: qsTr("Developer Tools")

    // 点击打开面板
    onClicked: {
        TooltipService.hide()
        pluginApi.togglePanel(root.screen, root)
    }
}
