// Panel.qml - 开发者工具面板 (Noctalia Panel 入口)
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.noctalia.shell 1.0

Item {
    id: root

    // ==================== Noctalia Panel 必需属性 ====================
    required property var pluginApi
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 680 * 1.0  // 可调整的宽度
    property real contentPreferredHeight: 540 * 1.0  // 可调整的高度

    // ==================== 主题引用 ====================
    property var theme: Qt.createQmlObject('import QtQuick 2.15; QtObject {}', root, "ThemePlaceholder")

    // ==================== 当前工具组件 ====================
    property var currentTool: null

    // ==================== 设置对话框引用 ====================
    property var settingsDialog: null

    // ==================== 面板容器 ====================
    Rectangle {
        id: panelContainer
        anchors.fill: parent

        // 面板内容区域
        Rectangle {
            id: panelContent
            width: Math.min(parent.width - 40, root.contentPreferredWidth)
            height: Math.min(parent.height - 40, root.contentPreferredHeight)
            anchors.centerIn: parent
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

            // ==================== 标题栏 ====================
            Rectangle {
                id: titleBar
                width: parent.width
                height: 40
                radius: parent.radius
                color: Qt.lighter(theme.backgroundColor, 1.05)
                border.width: 1
                border.color: theme.borderColor

                // 拖拽区域
                MouseArea {
                    anchors.fill: parent
                    drag.target: panelContent
                    drag.axis: Drag.XAndYAxis
                    drag.minimumX: 0
                    drag.maximumX: panelContainer.width - panelContent.width
                    drag.minimumY: 0
                    drag.maximumY: panelContainer.height - panelContent.height
                }

                // 标题
                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 15
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("开发者工具")
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
                        pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }

                    ToolTip {
                        visible: closeButton.hovered
                        text: qsTr("关闭")
                        delay: 300
                    }
                }
            }

            // ==================== 主内容区域 ====================
            RowLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: titleBar.bottom
                    bottom: parent.bottom
                    margins: 10
                }
                spacing: 10

                // 侧边栏
                Sidebar {
                    id: sidebar
                    width: 80
                    Layout.fillHeight: true

                    onToolSelected: function(index, toolName) {
                        console.log("Loading tool:", toolName, "at index:", index)
                        loadTool(index)
                    }

                    onSettingsButtonClicked: {
                        if (settingsDialog) {
                            settingsDialog.pluginApi = pluginApi
                            settingsDialog.toolModel = sidebar.toolModel
                            settingsDialog.showDialog()
                        }
                    }
                }

                // 工具加载器
                Loader {
                    id: toolLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    sourceComponent: Component {
                        Item {
                            anchors.fill: parent

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
            }
        }

        // 点击外部关闭
        MouseArea {
            anchors.fill: parent
            onClicked: {
                pluginApi.closePanel(pluginApi.panelOpenScreen)
            }
        }
    }

    // ==================== 消息显示组件 ====================
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

        Timer {
            id: messageTimer
            interval: 3000
            onTriggered: messageBox.visible = false
        }
    }

    // ==================== 工具加载逻辑 ====================
    function loadTool(index) {
        // 清理当前工具
        if (currentTool && typeof currentTool.cleanup === "function") {
            currentTool.cleanup()
        }

        toolLoader.source = ""
        currentTool = null

        // 加载新工具
        var toolInfo = sidebar.getCurrentTool()
        if (toolInfo) {
            var componentPath = "qml/tools/" + toolInfo.component
            if (componentPath.indexOf("..") === -1 && componentPath.endsWith(".qml")) {
                toolLoader.setSource(componentPath, {
                    "toolName": toolInfo.name,
                    "toolIcon": toolInfo.icon,
                    "toolDescription": toolInfo.description
                })

                if (toolLoader.status === Loader.Ready) {
                    currentTool = toolLoader.item
                } else {
                    var connection = function() {
                        currentTool = toolLoader.item
                        initializeAndConnectTool()
                        toolLoader.loaded.disconnect(connection)
                    }
                    toolLoader.loaded.connect(connection)
                    return
                }
            }
        }

        initializeAndConnectTool()
    }

    function initializeAndConnectTool() {
        if (currentTool && typeof currentTool.initialize === "function") {
            currentTool.initialize()
        }

        if (currentTool) {
            if (typeof currentTool.copyToClipboard === "function") {
                currentTool.copyToClipboard.connect(copyToClipboardHandler)
            }
            if (typeof currentTool.showMessage === "function") {
                currentTool.showMessage.connect(showMessageHandler)
            }
        }
    }

    // ==================== 消息处理 ====================
    function copyToClipboardHandler(text) {
        if (pluginApi && typeof pluginApi.copyToClipboard === "function") {
            pluginApi.copyToClipboard(text)
            showMessage(qsTr("已复制到剪贴板"), "success")
        } else {
            showMessage(qsTr("复制功能需要Noctalia API支持"), "warning")
        }
    }

    function showMessageHandler(message, type) {
        showMessage(message, type)
    }

    function showMessage(text, type) {
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

    // ==================== 设置对话框 ====================
    function createSettingsDialog() {
        try {
            var dialogComponent = Qt.createComponent("qml/components/SettingsDialog.qml")

            if (dialogComponent.status === Component.Ready) {
                settingsDialog = dialogComponent.createObject(root, {
                    "theme": theme,
                    "pluginApi": pluginApi,
                    "toolModel": sidebar.toolModel
                })

                if (settingsDialog) {
                    console.log("Settings dialog created successfully")
                }
            }
        } catch (error) {
            console.error("Error creating settings dialog:", error)
        }
    }

    // ==================== 主题初始化 ====================
    function initTheme() {
        theme = Qt.createQmlObject('import QtQuick 2.15; QtObject {}', root)

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

    // ==================== 初始化 ====================
    Component.onCompleted: {
        console.log("Developer Tools Panel initialized")
        initTheme()
        createSettingsDialog()
    }
}
