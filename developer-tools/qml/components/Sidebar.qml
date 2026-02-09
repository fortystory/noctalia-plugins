// Sidebar.qml - 侧边栏导航组件 (Noctalia 风格)
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    // 属性
    property int currentIndex: 0

    implicitWidth: 80

    // 视觉胶囊 - 居中显示
    Rectangle {
        id: visualCapsule
        anchors.centerIn: parent
        width: parent.width
        height: 2 * Style.baseWidgetSize + Style.marginS
        color: "transparent"

        Column {
            anchors.centerIn: parent
            spacing: Style.marginS

            // Timestamp 按钮
            Item {
                width: 64
                height: Style.baseWidgetSize

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radiusM
                    color: root.currentIndex === 0 ? Color.mPrimary : Color.mHover
                    opacity: root.currentIndex === 0 ? 0.3 : 0.15
                }

                NIcon {
                    anchors.centerIn: parent
                    icon: "clock"
                    color: root.currentIndex === 0 ? Color.mPrimary : Color.mOnSurfaceVariant
                    scale: 0.7
                }

                MouseArea {
                    id: mouseAreaTimestamp
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.currentIndex = 0
                    }
                }
            }

            // JSON 按钮
            Item {
                width: 64
                height: Style.baseWidgetSize

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radiusM
                    color: root.currentIndex === 1 ? Color.mPrimary : Color.mHover
                    opacity: root.currentIndex === 1 ? 0.3 : 0.15
                }

                NIcon {
                    anchors.centerIn: parent
                    icon: "braces"
                    color: root.currentIndex === 1 ? Color.mPrimary : Color.mOnSurfaceVariant
                    scale: 0.7
                }

                MouseArea {
                    id: mouseAreaJSON
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.currentIndex = 1
                    }
                }
            }
        }
    }
}
