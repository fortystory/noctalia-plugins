// BarWidget.qml - 状态栏按钮组件 (Noctalia bar-widget 入口)
import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    // Noctalia bar-widget 必需属性
    required property var pluginApi
    required property ShellScreen screen

    // 尺寸属性
    property real baseSize: Style.capsuleHeight
    property bool applyUiScale: false

    // 颜色属性
    property color colorBg: Color.mSurfaceVariant
    property color colorFg: Color.mPrimary
    property color colorBgHover: Color.mHover
    property color colorFgHover: Color.mOnHover
    property bool hovering: false

    // 尺寸计算
    implicitWidth: applyUiScale ? Math.round(baseSize * Style.uiScaleRatio) : Math.round(baseSize)
    implicitHeight: applyUiScale ? Math.round(baseSize * Style.uiScaleRatio) : Math.round(baseSize)

    // 样式
    color: hovering ? colorBgHover : colorBg
    radius: Math.min(Style.radiusL, width / 2)
    border.color: Color.mOutline
    border.width: Style.borderS

    // 图标 - 使用 NIcon
    NIcon {
        anchors.centerIn: parent
        icon: "code"  // 使用内置图标
        color: hovering ? colorFgHover : colorFg
        scale: 0.6
    }

    // 鼠标交互区域
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: root.hovering = true
        onExited: root.hovering = false

        onClicked: {
            if (pluginApi) {
                pluginApi.togglePanel(root.screen, root)
            }
        }
    }

    // 颜色动画
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
}
