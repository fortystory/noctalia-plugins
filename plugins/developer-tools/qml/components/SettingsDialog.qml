// SettingsDialog.qml - 设置对话框组件
// 模态对话框容器，包含设置内容和按钮区域
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

ApplicationWindow {
    id: settingsDialog

    // 窗口属性
    width: 500
    height: 550
    minimumWidth: 450
    minimumHeight: 500
    title: qsTr("Settings")
    flags: Qt.Dialog | Qt.WindowCloseButtonHint
    modality: Qt.ApplicationModal

    // 属性定义
    property var theme: Theme {}
    property var pluginApi: null
    property var toolModel: null

    // 信号定义
    signal settingsSaved()
    signal settingsApplied()
    signal dialogClosed()

    // 内部组件
    property var settingsManager: null

    // 显示/隐藏状态
    property bool isShowing: false

    // 窗口背景（带阴影效果、圆角）
    Rectangle {
        id: background
        anchors.fill: parent
        color: theme.backgroundColor
        radius: theme.borderRadius

        // 阴影效果
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: theme.shadowRadius * 2
            samples: 25
            color: theme.shadowColorTransparent
        }
    }

    // 标题栏（带拖拽功能、关闭按钮）
    Rectangle {
        id: titleBar
        height: 40
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: theme.spacingMedium
        }
        color: "transparent"

        // 标题
        Text {
            id: titleText
            text: settingsDialog.title
            font.pixelSize: theme.fontSizeTitle
            font.bold: true
            color: theme.textColor
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
        }

        // 关闭按钮
        Button {
            id: closeButton
            width: 32
            height: 32
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }

            background: Rectangle {
                color: "transparent"
                radius: theme.borderRadius

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 2
                    color: theme.secondaryColor
                    rotation: 45
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 2
                    color: theme.secondaryColor
                    rotation: -45
                }
            }

            onClicked: {
                closeDialog()
            }

            ToolTip {
                visible: closeButton.hovered
                text: qsTr("Close")
                delay: 300
            }
        }

        // 拖拽区域（整个标题栏可拖拽）
        MouseArea {
            anchors.fill: parent
            property point clickPos: "0,0"

            onPressed: {
                clickPos = Qt.point(mouse.x, mouse.y)
            }

            onPositionChanged: {
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                settingsDialog.x += delta.x
                settingsDialog.y += delta.y
            }
        }
    }

    // 内容区域（包含SettingsContent组件，支持滚动）
    ScrollView {
        id: scrollView
        anchors {
            top: titleBar.bottom
            left: parent.left
            right: parent.right
            bottom: buttonBar.top
            margins: theme.spacingMedium
            topMargin: theme.spacingLarge
            bottomMargin: theme.spacingLarge
        }

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        contentWidth: availableWidth
        clip: true

        // 设置内容组件
        SettingsContent {
            id: settingsContentComponent
            width: scrollView.availableWidth
            theme: settingsDialog.theme
            // settingsManager and toolModel will be set in initialize()
        }
    }

    // 按钮区域（取消、应用、确定三个按钮）
    Rectangle {
        id: buttonBar
        height: 60
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: theme.spacingMedium
        }
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: theme.spacingMedium

            // 取消按钮
            Button {
                id: cancelButton
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36
                text: qsTr("Cancel")

                background: Rectangle {
                    color: theme.surfaceColor
                    border.color: theme.borderColor
                    border.width: theme.borderWidth
                    radius: theme.borderRadius
                }

                contentItem: Text {
                    text: cancelButton.text
                    font.pixelSize: theme.fontSizeNormal
                    color: theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    closeDialog()
                }

                ToolTip {
                    visible: cancelButton.hovered
                    text: qsTr("放弃更改并关闭")
                    delay: 300
                }
            }

            // 占位符
            Item {
                Layout.fillWidth: true
            }

            // 应用按钮
            Button {
                id: applyButton
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36
                text: qsTr("Apply")

                background: Rectangle {
                    color: theme.primaryColor
                    border.color: theme.primaryColor
                    border.width: theme.borderWidth
                    radius: theme.borderRadius
                }

                contentItem: Text {
                    text: applyButton.text
                    font.pixelSize: theme.fontSizeNormal
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    applySettings()
                }

                ToolTip {
                    visible: applyButton.hovered
                    text: qsTr("应用更改但不关闭")
                    delay: 300
                }
            }

            // 确定按钮
            Button {
                id: okButton
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36
                text: qsTr("OK")

                background: Rectangle {
                    color: theme.primaryColor
                    border.color: theme.primaryColor
                    border.width: theme.borderWidth
                    radius: theme.borderRadius
                }

                contentItem: Text {
                    text: okButton.text
                    font.pixelSize: theme.fontSizeNormal
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    saveAndClose()
                }

                ToolTip {
                    visible: okButton.hovered
                    text: qsTr("保存更改并关闭")
                    delay: 300
                }
            }
        }
    }

    // 动画效果
    opacity: isShowing ? 1 : 0
    scale: isShowing ? 1 : 0.9
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    Behavior on scale {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // 初始化函数
    function initialize() {
        console.log("SettingsDialog: Initializing...")

        // 创建设置管理器
        if (pluginApi) {
            var component = Qt.createComponent("SettingsManager.qml")
            if (component.status === Component.Ready) {
                settingsManager = component.createObject(settingsDialog, {
                    pluginApi: pluginApi
                })

                if (settingsManager) {
                    console.log("SettingsDialog: SettingsManager created successfully")

                    // 设置内容组件的属性
                    settingsContentComponent.settingsManager = settingsManager
                    settingsContentComponent.toolModel = toolModel

                    // 初始化设置内容组件
                    settingsContentComponent.initialize(settingsManager, toolModel)
                } else {
                    console.error("SettingsDialog: Failed to create SettingsManager")
                }
            } else {
                console.error("SettingsDialog: Failed to load SettingsManager component:", component.errorString())
            }
        } else {
            console.warn("SettingsDialog: Plugin API not available")
        }
    }

    // 显示对话框
    function showDialog() {
        console.log("SettingsDialog: Showing dialog")

        if (!settingsManager) {
            initialize()
        }

        isShowing = true
        show()
        raise()
        requestActivate()
    }

    // 关闭对话框
    function closeDialog() {
        console.log("SettingsDialog: Closing dialog")

        isShowing = false
        close()
        dialogClosed()
    }

    // 应用设置（保存但不关闭）
    function applySettings() {
        console.log("SettingsDialog: Applying settings")

        if (settingsContentComponent.saveSettings()) {
            console.log("SettingsDialog: Settings applied successfully")
            settingsApplied()
        } else {
            console.error("SettingsDialog: Failed to apply settings")
        }
    }

    // 保存并关闭
    function saveAndClose() {
        console.log("SettingsDialog: Saving and closing")

        if (settingsContentComponent.saveSettings()) {
            console.log("SettingsDialog: Settings saved successfully")
            settingsSaved()
            closeDialog()
        } else {
            console.error("SettingsDialog: Failed to save settings")
        }
    }

    // 显示消息提示（暂未实现UI，仅输出到控制台）
    function showMessage(text, isError) {
        if (isError) {
            console.error("SettingsDialog:", text)
        } else {
            console.log("SettingsDialog:", text)
        }
    }

    // 窗口关闭事件处理
    onClosing: {
        console.log("SettingsDialog: Window closing")
        closeDialog()
    }

    // 组件加载完成
    Component.onCompleted: {
        console.log("SettingsDialog: Component loaded")
    }
}