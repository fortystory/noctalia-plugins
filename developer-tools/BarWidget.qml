// BarWidget.qml - 状态栏按钮组件 (Noctalia bar-widget 入口)
import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    // Noctalia bar-widget 必需属性
    required property var pluginApi
    required property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    // 尺寸属性
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen ? screen.name : "")

    implicitWidth: capsuleHeight
    implicitHeight: capsuleHeight

    // 视觉胶囊 - 居中显示
    Rectangle {
        id: visualCapsule
        anchors.centerIn: parent
        width: root.capsuleHeight
        height: root.capsuleHeight
        radius: Math.min(Style.radiusL, width / 2)
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        // 图标
        NIcon {
            anchors.centerIn: parent
            icon: "code"
            applyUiScale: false
            color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
        }
    }

    // 鼠标交互区域
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (pluginApi) {
                pluginApi.togglePanel(root.screen, root)
            }
        }
    }
}
