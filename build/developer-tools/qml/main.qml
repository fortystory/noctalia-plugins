// main.qml - 插件主入口
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import org.noctalia.shell 1.0

ApplicationWindow {
    id: mainWindow

    // 窗口属性
    width: _windowWidth
    height: _windowHeight

    // 窗口尺寸缓存属性
    property int _windowWidth: 600
    property int _windowHeight: 400
    title: qsTr("开发者工具")
    visible: false
    flags: Qt.Dialog | Qt.FramelessWindowHint
    color: "transparent"

    // Noctalia插件API
    property var pluginApi

    // 主题引用
    property var theme: Qt.createQmlObject('import QtQuick 2.15; QtObject {}', mainWindow, "ThemePlaceholder")

    // 当前工具组件
    property var currentTool: null

    // 设置对话框引用（新增）
    property var settingsDialog: null

    // 工具加载器
    Loader {
        id: toolLoader
        anchors {
            left: sidebar.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 10
        }

        sourceComponent: Component {
            Item {
                anchors.fill: parent

                // 默认占位符
                Text {
                    anchors.centerIn: parent
                    text: qsTr("选择左侧工具开始使用")
                    font.pixelSize: 16
                    color: theme.textColor
                    opacity: 0.5
                }
            }
        }
    }

    // 侧边栏
    Sidebar {
        id: sidebar
        width: 80
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }

        onToolSelected: function(index, toolName) {
            console.log("Loading tool:", toolName, "at index:", index)

            // 清理当前工具
            if (currentTool && typeof currentTool.cleanup === "function") {
                currentTool.cleanup()
            }

            // 释放Loader资源
            toolLoader.source = ""
            currentTool = null

            // 加载新工具
            var toolInfo = sidebar.getCurrentTool()
            if (toolInfo) {
                var componentPath = "tools/" + toolInfo.component
                // 路径安全检查
                if (componentPath.indexOf("..") === -1 && componentPath.endsWith(".qml")) {
                    toolLoader.setSource(componentPath, {
                        "toolName": toolInfo.name,
                        "toolIcon": toolInfo.icon,
                        "toolDescription": toolInfo.description
                    })

                    // 保存引用（等待Loader加载完成）
                    if (toolLoader.status === Loader.Ready) {
                        currentTool = toolLoader.item
                    } else {
                        // 异步等待加载完成
                        var connection = function() {
                            currentTool = toolLoader.item
                            initializeAndConnectTool()
                            toolLoader.loaded.disconnect(connection)
                        }
                        toolLoader.loaded.connect(connection)
                        return
                    }
                } else {
                    console.error("Invalid component path:", componentPath)
                    showMessage(qsTr("工具加载失败：无效路径"), "error")
                    return
                }
            } else {
                console.error("No tool info found for index:", index)
                return
            }

            initializeAndConnectTool()

            function initializeAndConnectTool() {
                // 初始化工具
                if (currentTool && typeof currentTool.initialize === "function") {
                    currentTool.initialize()
                }

                // 连接信号
                if (currentTool) {
                    if (typeof currentTool.copyToClipboard === "function") {
                        currentTool.copyToClipboard.connect(copyToClipboardHandler)
                    }
                    if (typeof currentTool.showMessage === "function") {
                        currentTool.showMessage.connect(showMessageHandler)
                    }
                }
            }
        }

        // 新增：设置按钮点击处理
        onSettingsButtonClicked: {
            console.log("Sidebar settings button clicked")

            if (settingsDialog) {
                // 确保对话框引用最新的API和模型
                settingsDialog.pluginApi = pluginApi
                settingsDialog.toolModel = sidebar.toolModel

                // 显示设置对话框
                settingsDialog.showDialog()
            } else {
                console.error("Settings dialog not available")
                showMessage(qsTr("Settings dialog initialization failed"), "error")
            }
        }
    }

    // 窗口背景（带阴影）
    Rectangle {
        id: windowBackground
        anchors.fill: parent
        radius: 12
        color: theme.backgroundColor
        border.width: 1
        border.color: theme.borderColor

        // 阴影效果
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 16
            samples: 17
            color: "#00000030"
        }

        // 标题栏
        Rectangle {
            id: titleBar
            width: parent.width
            height: 40
            radius: parent.radius
            color: Qt.lighter(theme.backgroundColor, 1.05)
            border.width: 1
            border.color: theme.borderColor

            // 标题
            Text {
                anchors {
                    left: parent.left
                    leftMargin: 15
                    verticalCenter: parent.verticalCenter
                }
                text: mainWindow.title
                font.pixelSize: 14
                font.bold: true
                color: theme.textColor
            }

            // 关闭按钮
            Button {
                id: closeButton
                anchors {
                    right: parent.right
                    rightMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                width: 30
                height: 30

                background: Rectangle {
                    radius: 4
                    color: closeButton.down ? Qt.lighter(theme.errorColor, 1.2) :
                           closeButton.hovered ? theme.errorColor : "transparent"
                }

                contentItem: Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 20
                    font.bold: true
                    color: closeButton.hovered ? "white" : theme.textColor
                }

                onClicked: {
                    console.log("Close button clicked")
                    mainWindow.visible = false
                }

                ToolTip {
                    visible: closeButton.hovered
                    text: qsTr("关闭")
                    delay: 300
                }
            }

            // 标题栏拖拽区域
            MouseArea {
                anchors.fill: parent
                drag.target: mainWindow
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: Screen.width - mainWindow.width
                drag.minimumY: 0
                drag.maximumY: Screen.height - mainWindow.height

                onDoubleClicked: {
                    // 双击最大化/还原
                    if (mainWindow.visibility === Window.Windowed) {
                        mainWindow.showMaximized()
                    } else {
                        mainWindow.showNormal()
                    }
                }
            }
        }
    }

    // 消息显示组件
    Rectangle {
        id: messageBox
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 50
        }
        width: 300
        height: 40
        radius: 6
        color: theme.surfaceColor
        border.width: 1
        border.color: theme.borderColor
        visible: false
        z: 100

        Text {
            id: messageText
            anchors.centerIn: parent
            font.pixelSize: 12
            color: theme.textColor
        }

        // 自动隐藏定时器
        Timer {
            id: messageTimer
            interval: 3000
            onTriggered: messageBox.visible = false
        }
    }

    // 事件处理：点击外部关闭窗口
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onPressed: mouse.accepted = false

        // 检测是否点击在窗口外部
        onClicked: {
            // 如果点击在窗口外部，关闭窗口
            if (!windowBackground.contains(Qt.point(mouse.x, mouse.y))) {
                console.log("Clicked outside window, closing")
                mainWindow.visible = false
            }
        }
    }

    // 窗口显示/隐藏动画
    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    Behavior on scale {
        NumberAnimation { duration: 200 }
    }

    // 窗口显示时
    onVisibleChanged: {
        if (visible) {
            console.log("Window shown")
            opacity = 0
            scale = 0.9
            opacity = 1
            scale = 1

            // 恢复上次的位置（第324-334行）
            var positionMemoryEnabled = pluginApi.settings.value("preferences/windowPositionMemory", true)

            if (positionMemoryEnabled) {
                var x = pluginApi.settings.value("window/x", -1)
                var y = pluginApi.settings.value("window/y", -1)
                if (x !== -1 && y !== -1) {
                    mainWindow.x = x
                    mainWindow.y = y
                    console.log("Window position restored (position memory enabled)")
                } else {
                    // 默认居中显示
                    mainWindow.x = (Screen.width - width) / 2
                    mainWindow.y = (Screen.height - height) / 2
                    console.log("Window position centered (no saved position)")
                }
            } else {
                // 位置记忆禁用时始终居中
                mainWindow.x = (Screen.width - width) / 2
                mainWindow.y = (Screen.height - height) / 2
                console.log("Window position centered (position memory disabled)")
            }

            // 恢复上次选择的工具（第336-338行）
            var lastTool = pluginApi.settings.value("sidebar/lastTool", 0)

            // 优先使用设置中的默认工具（修改后）
            var defaultToolSetting = pluginApi.settings.value("preferences/defaultTool", 0)
            var toolToSelect = defaultToolSetting

            // 但如果用户上次选择了其他工具，使用上次选择（保持向后兼容）
            if (pluginApi.settings.contains("sidebar/lastTool")) {
                toolToSelect = lastTool
            }

            sidebar.selectTool(toolToSelect)

        } else {
            console.log("Window hidden")

            // 保存窗口位置和大小（第353-357行）
            var positionMemoryEnabled = pluginApi.settings.value("preferences/windowPositionMemory", true)

            if (positionMemoryEnabled) {
                pluginApi.settings.setValue("window/x", mainWindow.x)
                pluginApi.settings.setValue("window/y", mainWindow.y)
                pluginApi.settings.setValue("window/width", mainWindow.width)
                pluginApi.settings.setValue("window/height", mainWindow.height)
                console.log("Window position saved (position memory enabled)")
            } else {
                console.log("Window position not saved (position memory disabled)")
            }

            // 更新缓存尺寸
            _windowWidth = mainWindow.width
            _windowHeight = mainWindow.height

            // 保存当前选择的工具
            pluginApi.settings.setValue("sidebar/lastTool", sidebar.currentIndex)

            // 清理当前工具
            if (currentTool && typeof currentTool.cleanup === "function") {
                currentTool.cleanup()
            }
        }
    }

    // 处理复制到剪贴板
    function copyToClipboardHandler(text) {
        console.log("Copying to clipboard:", text.substring(0, 50) + "...")

        // 使用Noctalia API复制到剪贴板
        if (pluginApi && typeof pluginApi.copyToClipboard === "function") {
            pluginApi.copyToClipboard(text)
            showMessage(qsTr("已复制到剪贴板"), "success")
        } else {
            // 备用方案
            Qt.callLater(function() {
                // 这里可以使用Qt的剪贴板API
                console.log("Using Qt clipboard")
                // 注意：需要导入QtClipboard模块
            })
            showMessage(qsTr("复制功能需要Noctalia API支持"), "warning")
        }
    }

    // 显示消息
    function showMessageHandler(message, type) {
        showMessage(message, type)
    }

    function showMessage(text, type) {
        console.log("Showing message:", text, "type:", type)

        // 设置消息颜色
        switch(type) {
            case "success":
                messageBox.color = theme.successColor
                messageText.color = "white"
                break
            case "warning":
                messageBox.color = theme.warningColor
                messageText.color = "white"
                break
            case "error":
                messageBox.color = theme.errorColor
                messageText.color = "white"
                break
            default:
                messageBox.color = theme.surfaceColor
                messageText.color = theme.textColor
        }

        messageText.text = text
        messageBox.visible = true
        messageTimer.restart()
    }

    // 创建设置对话框
    function createSettingsDialog() {
        console.log("Creating settings dialog...")

        try {
            // 动态创建SettingsDialog组件
            var dialogComponent = Qt.createComponent("../components/SettingsDialog.qml")

            if (dialogComponent.status === Component.Ready) {
                settingsDialog = dialogComponent.createObject(mainWindow, {
                    "theme": theme,
                    "pluginApi": pluginApi,
                    "toolModel": sidebar.toolModel
                })

                if (settingsDialog) {
                    console.log("Settings dialog created successfully")

                    // 连接对话框信号
                    settingsDialog.settingsSaved.connect(function() {
                        console.log("Settings saved signal received")
                        // 可以在这里添加设置保存后的额外处理
                    })

                    settingsDialog.settingsApplied.connect(function() {
                        console.log("Settings applied signal received")
                        // 可以在这里添加设置应用后的额外处理
                    })

                    settingsDialog.dialogClosed.connect(function() {
                        console.log("Settings dialog closed signal received")
                        // 可以在这里添加对话框关闭后的清理
                    })

                } else {
                    console.error("Failed to create settings dialog object")
                }
            } else {
                console.error("Failed to load settings dialog component:", dialogComponent.errorString())
            }
        } catch (error) {
            console.error("Error creating settings dialog:", error)
        }
    }

    // 公共方法：切换窗口显示/隐藏
    function toggle() {
        console.log("Toggling window, current visible:", visible)
        visible = !visible
    }

    // 公共方法：显示窗口
    function show() {
        visible = true
    }

    // 公共方法：隐藏窗口
    function hide() {
        visible = false
    }

    // 初始化
    Component.onCompleted: {
        console.log("Main window component completed")

        // 初始化窗口尺寸
        _windowWidth = pluginApi.settings.value("window/width", 600)
        _windowHeight = pluginApi.settings.value("window/height", 400)

        // 创建主题实例
        theme = Qt.createQmlObject('import QtQuick 2.15; QtObject {}', mainWindow)

        // 创建设置对话框（新增）
        createSettingsDialog()

        // 设置主题属性绑定
        if (pluginApi && pluginApi.style) {
            theme.backgroundColor = pluginApi.style.backgroundColor
            theme.textColor = pluginApi.style.textColor
            theme.borderColor = pluginApi.style.borderColor
            theme.primaryColor = pluginApi.style.primaryColor
            theme.successColor = pluginApi.style.successColor || "#10b981"
            theme.warningColor = pluginApi.style.warningColor || "#f59e0b"
            theme.errorColor = pluginApi.style.errorColor || "#ef4444"
            theme.surfaceColor = pluginApi.style.surfaceColor || "#f8fafc"
        }

        // 监听主题变化
        if (pluginApi) {
            pluginApi.styleChanged.connect(function() {
                console.log("Theme changed, updating colors")
                if (pluginApi.style) {
                    theme.backgroundColor = pluginApi.style.backgroundColor
                    theme.textColor = pluginApi.style.textColor
                    theme.borderColor = pluginApi.style.borderColor
                    theme.primaryColor = pluginApi.style.primaryColor
                    theme.successColor = pluginApi.style.successColor || "#10b981"
                    theme.warningColor = pluginApi.style.warningColor || "#f59e0b"
                    theme.errorColor = pluginApi.style.errorColor || "#ef4444"
                    theme.surfaceColor = pluginApi.style.surfaceColor || "#f8fafc"
                }
            })
        }
    }
}