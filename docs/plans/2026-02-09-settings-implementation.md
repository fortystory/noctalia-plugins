# Noctalia插件设置功能实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement basic settings functionality including theme preference, default startup tool, and window position memory for the Noctalia developer tools plugin.

**Architecture:** Modal dialog design with three core settings, using Noctalia plugin API for persistence, integrated with existing sidebar and main window components.

**Tech Stack:** QML 2.15, Qt Quick Controls 2.15, Noctalia Shell Plugin API, Qt Quick Dialogs

---
## 重要说明：不使用Git命令

**所有任务步骤都不包含git命令**。开发完成后，我将手动进行git操作。

## 任务结构
每个任务包含：文件操作、步骤说明、代码示例和验证命令。

### Task 1: 创建设置管理器组件

**Files:**
- Create: `plugins/developer-tools/qml/components/SettingsManager.qml`

**Step 1: 创建设置管理器QML文件**

```qml
// SettingsManager.qml - 设置管理组件
// 封装Noctalia设置API的读写操作，提供验证和默认值处理
import QtQuick 2.15

QtObject {
    id: settingsManager

    // 必需的API引用
    property var pluginApi: null

    // 默认设置值
    property string defaultTheme: "system"
    property int defaultToolIndex: 0
    property bool defaultWindowPositionMemory: true

    // 读取设置值（带验证和默认值）
    function getValue(key, defaultValue) {
        if (!pluginApi || !pluginApi.settings) {
            console.warn("Settings API not available, using default:", defaultValue)
            return defaultValue
        }

        var value = pluginApi.settings.value(key, defaultValue)
        return validateValue(key, value, defaultValue)
    }

    // 保存设置值
    function setValue(key, value) {
        if (pluginApi && pluginApi.settings) {
            pluginApi.settings.setValue(key, value)
            console.log("Setting saved:", key, "=", value)
            return true
        }
        console.error("Failed to save setting:", key, "- API unavailable")
        return false
    }

    // 验证设置值有效性
    function validateValue(key, value, defaultValue) {
        switch(key) {
            case "preferences/theme":
                if (["system", "light", "dark"].includes(value)) {
                    return value
                }
                console.warn("Invalid theme value:", value, "- using default:", defaultValue)
                return defaultValue

            case "preferences/defaultTool":
                var intValue = parseInt(value)
                if (!isNaN(intValue) && intValue >= 0) {
                    return intValue
                }
                console.warn("Invalid tool index:", value, "- using default:", defaultValue)
                return defaultValue

            case "preferences/windowPositionMemory":
                if (typeof value === "boolean") {
                    return value
                }
                if (value === "true" || value === "false") {
                    return value === "true"
                }
                if (value === 1 || value === 0) {
                    return value === 1
                }
                console.warn("Invalid boolean value:", value, "- using default:", defaultValue)
                return defaultValue

            default:
                console.warn("Unknown setting key:", key)
                return defaultValue
        }
    }

    // 批量保存所有设置
    function saveAll(themePreference, defaultToolIndex, windowPositionMemory) {
        var success = true

        success = success && setValue("preferences/theme", themePreference)
        success = success && setValue("preferences/defaultTool", defaultToolIndex)
        success = success && setValue("preferences/windowPositionMemory", windowPositionMemory)

        if (success) {
            console.log("All settings saved successfully")
        } else {
            console.error("Failed to save some settings")
        }

        return success
    }

    // 加载所有设置到对象
    function loadAll() {
        return {
            themePreference: getValue("preferences/theme", defaultTheme),
            defaultToolIndex: getValue("preferences/defaultTool", defaultToolIndex),
            windowPositionMemory: getValue("preferences/windowPositionMemory", defaultWindowPositionMemory)
        }
    }

    // 检查设置API可用性
    function isApiAvailable() {
        return pluginApi && pluginApi.settings
    }
}
```

**Step 2: 验证文件创建**

检查文件是否创建成功并包含正确内容：
- 文件路径：`plugins/developer-tools/qml/components/SettingsManager.qml`
- 确认文件包含所有必需函数
- 确认设置了正确的属性默认值

### Task 2: 创建设置内容组件

**Files:**
- Create: `plugins/developer-tools/qml/components/SettingsContent.qml`

**Step 1: 创建设置内容QML文件**

```qml
// SettingsContent.qml - 设置内容布局组件
// 包含所有设置项的垂直布局，带标签和输入控件
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: settingsContent

    // 属性定义
    property var theme: Theme {}
    property var settingsManager: null
    property var toolModel: null

    // 设置值属性
    property string themePreference: "system"
    property int defaultToolIndex: 0
    property bool windowPositionMemory: true

    // 间距配置
    spacing: theme.spacingLarge

    // 主题设置组
    GroupBox {
        id: themeGroup
        Layout.fillWidth: true
        title: qsTr("外观")
        background: Rectangle {
            color: theme.surfaceColor
            border.color: theme.borderColor
            border.width: theme.borderWidth
            radius: theme.borderRadius
        }
        label: Label {
            text: themeGroup.title
            font.pixelSize: theme.fontSizeLarge
            font.bold: true
            color: theme.textColor
            padding: 5
        }

        ColumnLayout {
            spacing: theme.spacingMedium
            width: parent.width

            // 主题偏好设置
            RowLayout {
                spacing: theme.spacingLarge

                Label {
                    text: qsTr("主题偏好:")
                    font.pixelSize: theme.fontSizeNormal
                    color: theme.textColor
                    Layout.preferredWidth: 120
                }

                ComboBox {
                    id: themeComboBox
                    Layout.fillWidth: true
                    model: [
                        { value: "system", text: qsTr("跟随系统") },
                        { value: "light", text: qsTr("浅色主题") },
                        { value: "dark", text: qsTr("深色主题") }
                    ]

                    textRole: "text"
                    valueRole: "value"

                    currentIndex: {
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === themePreference) {
                                return i
                            }
                        }
                        return 0
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0) {
                            themePreference = model[currentIndex].value
                        }
                    }

                    background: Rectangle {
                        color: theme.backgroundColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                        radius: theme.borderRadius
                    }

                    contentItem: Text {
                        text: themeComboBox.displayText
                        font.pixelSize: theme.fontSizeNormal
                        color: theme.textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }

                    ToolTip {
                        visible: themeComboBox.hovered
                        text: qsTr("选择插件主题外观")
                        delay: 300
                    }
                }
            }

            // 主题设置提示
            Text {
                text: qsTr("主题更改将在下次启动插件时生效")
                font.pixelSize: theme.fontSizeSmall
                color: theme.secondaryColor
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // 默认工具设置组
    GroupBox {
        id: toolGroup
        Layout.fillWidth: true
        title: qsTr("启动设置")
        background: Rectangle {
            color: theme.surfaceColor
            border.color: theme.borderColor
            border.width: theme.borderWidth
            radius: theme.borderRadius
        }
        label: Label {
            text: toolGroup.title
            font.pixelSize: theme.fontSizeLarge
            font.bold: true
            color: theme.textColor
            padding: 5
        }

        ColumnLayout {
            spacing: theme.spacingMedium
            width: parent.width

            // 默认启动工具设置
            RowLayout {
                spacing: theme.spacingLarge

                Label {
                    text: qsTr("默认启动工具:")
                    font.pixelSize: theme.fontSizeNormal
                    color: theme.textColor
                    Layout.preferredWidth: 120
                }

                ComboBox {
                    id: toolComboBox
                    Layout.fillWidth: true

                    // 从工具模型动态加载
                    model: toolModel ? toolModel : []
                    textRole: "name"

                    currentIndex: defaultToolIndex

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0) {
                            defaultToolIndex = currentIndex
                        }
                    }

                    background: Rectangle {
                        color: theme.backgroundColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                        radius: theme.borderRadius
                    }

                    contentItem: Text {
                        text: toolComboBox.displayText
                        font.pixelSize: theme.fontSizeNormal
                        color: theme.textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }

                    ToolTip {
                        visible: toolComboBox.hovered
                        text: qsTr("选择插件启动时默认显示的工具")
                        delay: 300
                    }
                }
            }

            // 工具设置提示
            Text {
                text: qsTr("默认工具将在下次启动插件时生效")
                font.pixelSize: theme.fontSizeSmall
                color: theme.secondaryColor
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // 窗口设置组
    GroupBox {
        id: windowGroup
        Layout.fillWidth: true
        title: qsTr("窗口行为")
        background: Rectangle {
            color: theme.surfaceColor
            border.color: theme.borderColor
            border.width: theme.borderWidth
            radius: theme.borderRadius
        }
        label: Label {
            text: windowGroup.title
            font.pixelSize: theme.fontSizeLarge
            font.bold: true
            color: theme.textColor
            padding: 5
        }

        ColumnLayout {
            spacing: theme.spacingMedium
            width: parent.width

            // 窗口位置记忆开关
            RowLayout {
                spacing: theme.spacingLarge

                Label {
                    text: qsTr("窗口位置记忆:")
                    font.pixelSize: theme.fontSizeNormal
                    color: theme.textColor
                    Layout.preferredWidth: 120
                }

                Switch {
                    id: positionSwitch
                    checked: windowPositionMemory

                    onCheckedChanged: {
                        windowPositionMemory = checked
                    }

                    background: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 24
                        radius: 12
                        color: positionSwitch.checked ? theme.primaryColor : theme.surfaceColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                    }

                    indicator: Rectangle {
                        x: positionSwitch.checked ? parent.width - width : 0
                        y: (parent.height - height) / 2
                        width: 24
                        height: 24
                        radius: 12
                        color: theme.backgroundColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                    }

                    ToolTip {
                        visible: positionSwitch.hovered
                        text: qsTr("记住窗口关闭时的位置和大小")
                        delay: 300
                    }
                }

                Label {
                    text: positionSwitch.checked ? qsTr("启用") : qsTr("禁用")
                    font.pixelSize: theme.fontSizeNormal
                    color: positionSwitch.checked ? theme.primaryColor : theme.textColor
                }
            }

            // 窗口设置提示
            Text {
                text: qsTr("禁用位置记忆将清除现有的窗口位置存储")
                font.pixelSize: theme.fontSizeSmall
                color: theme.secondaryColor
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // API状态显示（当API不可用时）
    Rectangle {
        visible: settingsManager && !settingsManager.isApiAvailable()
        Layout.fillWidth: true
        height: 40
        radius: theme.borderRadius
        color: theme.warningColor
        opacity: 0.9

        RowLayout {
            anchors.fill: parent
            anchors.margins: theme.spacingSmall

            Text {
                text: "⚠️"
                font.pixelSize: 16
                color: "white"
                Layout.alignment: Qt.AlignCenter
            }

            Text {
                text: qsTr("设置API不可用，更改不会持久保存")
                font.pixelSize: theme.fontSizeSmall
                color: "white"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    // 初始化函数
    function initialize(manager, model) {
        settingsManager = manager
        toolModel = model

        if (settingsManager) {
            var settings = settingsManager.loadAll()
            themePreference = settings.themePreference
            defaultToolIndex = settings.defaultToolIndex
            windowPositionMemory = settings.windowPositionMemory
        }
    }

    // 保存设置函数
    function saveSettings() {
        if (settingsManager) {
            return settingsManager.saveAll(themePreference, defaultToolIndex, windowPositionMemory)
        }
        return false
    }

    // 重置为默认值
    function resetToDefaults() {
        themePreference = settingsManager ? settingsManager.defaultTheme : "system"
        defaultToolIndex = settingsManager ? settingsManager.defaultToolIndex : 0
        windowPositionMemory = settingsManager ? settingsManager.defaultWindowPositionMemory : true
    }
}
```

**Step 2: 验证文件创建**

检查文件是否创建成功并包含正确内容：
- 文件路径：`plugins/developer-tools/qml/components/SettingsContent.qml`
- 确认包含所有三个设置项（主题、默认工具、窗口位置）
- 确认设置了正确的属性绑定和信号处理

### Task 3: 创建设置对话框组件

**Files:**
- Create: `plugins/developer-tools/qml/components/SettingsDialog.qml`

**Step 1: 创建设置对话框QML文件**

```qml
// SettingsDialog.qml - 设置对话框组件
// 模态对话框容器，包含设置内容和按钮区域
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: settingsDialog

    // 窗口属性
    width: 500
    height: 550
    minimumWidth: 450
    minimumHeight: 500
    title: qsTr("设置")
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
    property var settingsContent: null

    // 窗口背景
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
                text: settingsDialog.title
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
                    console.log("Settings dialog closed")
                    settingsDialog.close()
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
                drag.target: settingsDialog
                drag.axis: Drag.XAndYAxis
                drag.minimumX: 0
                drag.maximumX: Screen.width - settingsDialog.width
                drag.minimumY: 0
                drag.maximumY: Screen.height - settingsDialog.height
            }
        }

        // 主内容区域
        Rectangle {
            id: contentArea
            anchors {
                top: titleBar.bottom
                left: parent.left
                right: parent.right
                bottom: buttonArea.top
                margins: 1
            }
            color: theme.backgroundColor

            // 滚动区域（确保内容可滚动）
            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 20

                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                // 设置内容组件
                SettingsContent {
                    id: settingsContentComponent
                    width: scrollView.availableWidth
                    theme: settingsDialog.theme

                    // 通过函数初始化，避免循环依赖
                    Component.onCompleted: {
                        if (settingsDialog.settingsManager) {
                            settingsContentComponent.initialize(
                                settingsDialog.settingsManager,
                                settingsDialog.toolModel
                            )
                        }
                    }
                }
            }
        }

        // 按钮区域
        Rectangle {
            id: buttonArea
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 70
            color: Qt.lighter(theme.backgroundColor, 1.05)
            border.width: 1
            border.color: theme.borderColor

            RowLayout {
                anchors.centerIn: parent
                spacing: 20

                // 取消按钮
                Button {
                    id: cancelButton
                    text: qsTr("取消")
                    width: 100

                    background: Rectangle {
                        color: cancelButton.down ? Qt.lighter(theme.surfaceColor, 0.9) :
                               cancelButton.hovered ? theme.surfaceColor : theme.backgroundColor
                        border.color: theme.borderColor
                        border.width: 1
                        radius: 6
                    }

                    contentItem: Text {
                        text: cancelButton.text
                        font.pixelSize: theme.fontSizeNormal
                        color: theme.textColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        console.log("Settings changes cancelled")
                        settingsDialog.close()
                    }
                }

                // 应用按钮
                Button {
                    id: applyButton
                    text: qsTr("应用")
                    width: 100

                    background: Rectangle {
                        color: applyButton.down ? Qt.darker(theme.primaryColor, 1.2) :
                               applyButton.hovered ? Qt.darker(theme.primaryColor, 1.1) : theme.primaryColor
                        border.color: theme.primaryColor
                        border.width: 1
                        radius: 6
                    }

                    contentItem: Text {
                        text: applyButton.text
                        font.pixelSize: theme.fontSizeNormal
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        console.log("Applying settings...")
                        var success = settingsContentComponent.saveSettings()
                        if (success) {
                            console.log("Settings applied successfully")
                            settingsDialog.settingsApplied()
                            // 显示成功消息
                            if (settingsDialog.pluginApi && settingsDialog.pluginApi.showMessage) {
                                settingsDialog.pluginApi.showMessage(qsTr("设置已应用"), "success")
                            }
                        } else {
                            console.error("Failed to apply settings")
                            if (settingsDialog.pluginApi && settingsDialog.pluginApi.showMessage) {
                                settingsDialog.pluginApi.showMessage(qsTr("设置保存失败"), "error")
                            }
                        }
                    }
                }

                // 确定按钮
                Button {
                    id: okButton
                    text: qsTr("确定")
                    width: 100

                    background: Rectangle {
                        color: okButton.down ? Qt.darker(theme.primaryColor, 1.2) :
                               okButton.hovered ? Qt.darker(theme.primaryColor, 1.1) : theme.primaryColor
                        border.color: theme.primaryColor
                        border.width: 1
                        radius: 6
                    }

                    contentItem: Text {
                        text: okButton.text
                        font.pixelSize: theme.fontSizeNormal
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        console.log("Saving and closing settings...")
                        var success = settingsContentComponent.saveSettings()
                        if (success) {
                            console.log("Settings saved successfully")
                            settingsDialog.settingsSaved()
                            // 显示成功消息
                            if (settingsDialog.pluginApi && settingsDialog.pluginApi.showMessage) {
                                settingsDialog.pluginApi.showMessage(qsTr("设置已保存"), "success")
                            }
                        } else {
                            console.error("Failed to save settings")
                            if (settingsDialog.pluginApi && settingsDialog.pluginApi.showMessage) {
                                settingsDialog.pluginApi.showMessage(qsTr("设置保存失败"), "error")
                            }
                        }
                        settingsDialog.close()
                    }
                }
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

    // 窗口显示时初始化
    onVisibleChanged: {
        if (visible) {
            console.log("Settings dialog shown")

            // 居中显示
            settingsDialog.x = (Screen.width - width) / 2
            settingsDialog.y = (Screen.height - height) / 2

            // 动画效果
            opacity = 0
            scale = 0.9
            opacity = 1
            scale = 1

            // 初始化设置管理器
            if (!settingsManager) {
                settingsManager = Qt.createQmlObject('import QtQuick 2.15; import "../developer-tools/qml/components" 1.0; SettingsManager {}',
                                                     settingsDialog, "SettingsManagerObject")
                if (settingsManager) {
                    settingsManager.pluginApi = pluginApi
                }
            }

            // 保存引用
            settingsContent = settingsContentComponent

            console.log("Settings dialog initialized with API:", !!pluginApi)
        } else {
            console.log("Settings dialog hidden")
            settingsDialog.dialogClosed()
        }
    }

    // 公共方法：显示对话框
    function showDialog(api, model) {
        pluginApi = api
        toolModel = model
        show()
    }

    // 公共方法：关闭对话框
    function closeDialog() {
        close()
    }
}
```

**Step 2: 验证文件创建**

检查文件是否创建成功并包含正确内容：
- 文件路径：`plugins/developer-tools/qml/components/SettingsDialog.qml`
- 确认包含完整的对话框结构（标题栏、内容区、按钮区）
- 确认设置了正确的模态行为和动画效果

### Task 4: 修改侧边栏组件

**Files:**
- Modify: `plugins/developer-tools/qml/components/Sidebar.qml:262-275`

**Step 1: 修改侧边栏设置按钮点击处理**

找到Sidebar.qml文件的第262-275行，将TODO注释替换为实际的设置功能实现：

```qml
// 设置按钮（第262-275行）
ToolButton {
    id: settingsButton
    anchors {
        centerIn: parent
        verticalCenterOffset: theme.spacingSmall
    }
    buttonIcon: "⚙️"
    tooltip: qsTr("设置")
    onClicked: {
        console.log("设置按钮点击，打开设置对话框")

        // 触发设置对话框显示信号
        if (typeof settingsButtonClicked === "function") {
            settingsButtonClicked()
        } else {
            console.warn("settingsButtonClicked信号未定义，请确保父组件已连接")
        }
    }
}
```

**Step 2: 添加设置按钮点击信号**

在Sidebar.qml文件的信号定义区域（约第47-48行）添加新信号：

```qml
// ==================== 信号定义 ====================
signal toolSelected(int index, string toolName)
signal settingsButtonClicked()  // 新增：设置按钮点击信号
```

**Step 3: 验证修改**

检查修改是否正确：
- 侧边栏设置按钮现在触发`settingsButtonClicked`信号
- 信号定义已添加到信号区域
- 原有的工具选择信号保持不变

### Task 5: 修改主窗口组件

**Files:**
- Modify: `plugins/developer-tools/qml/main.qml`

**Step 1: 在main.qml中添加设置对话框引用**

在main.qml的组件定义区域（约第30行）添加设置对话框属性：

```qml
// 当前工具组件
property var currentTool: null

// 设置对话框引用（新增）
property var settingsDialog: null
```

**Step 2: 在Component.onCompleted中创建设置对话框**

在main.qml的Component.onCompleted函数中（约第411-449行）添加设置对话框初始化：

```qml
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

    // 设置主题属性绑定（原有代码保持不变）
    if (pluginApi && pluginApi.style) {
        // ... 原有主题设置代码
    }

    // 监听主题变化（原有代码保持不变）
    if (pluginApi) {
        // ... 原有主题变化监听代码
    }
}
```

**Step 3: 添加创建设置对话框的函数**

在main.qml的函数定义区域添加新函数（可以在showMessage函数之后添加）：

```qml
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
```

**Step 4: 连接侧边栏设置按钮信号**

在main.qml的侧边栏定义区域（约第60-68行）添加信号连接：

```qml
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
        // ... 原有工具选择代码保持不变
    }

    // 新增：设置按钮点击处理
    onSettingsButtonClicked: {
        console.log("Sidebar settings button clicked")

        if (settingsDialog) {
            // 确保对话框引用最新的API和模型
            settingsDialog.pluginApi = pluginApi
            settingsDialog.toolModel = sidebar.toolModel

            // 显示设置对话框
            settingsDialog.show()
        } else {
            console.error("Settings dialog not available")
            showMessage(qsTr("设置对话框初始化失败"), "error")
        }
    }
}
```

**Step 5: 验证修改**

检查所有修改是否正确：
- 设置对话框属性已添加
- createSettingsDialog函数已实现
- 侧边栏设置按钮信号已连接
- 原有功能保持不变

### Task 6: 添加默认工具设置读取

**Files:**
- Modify: `plugins/developer-tools/qml/main.qml:316-318`

**Step 1: 修改窗口显示时的默认工具读取**

找到main.qml中窗口显示时的代码（约第316-318行），修改默认工具读取逻辑：

```qml
// 恢复上次选择的工具（第316-318行）
var lastTool = pluginApi.settings.value("sidebar/lastTool", 0)

// 优先使用设置中的默认工具（修改后）
var defaultToolSetting = pluginApi.settings.value("preferences/defaultTool", 0)
var toolToSelect = defaultToolSetting

// 但如果用户上次选择了其他工具，使用上次选择（保持向后兼容）
if (pluginApi.settings.contains("sidebar/lastTool")) {
    toolToSelect = lastTool
}

sidebar.selectTool(toolToSelect)
```

**Step 2: 验证修改**

检查修改是否正确：
- 现在优先读取`preferences/defaultTool`设置
- 保持对`sidebar/lastTool`的向后兼容
- 确保工具选择逻辑正确

### Task 7: 更新窗口位置记忆逻辑

**Files:**
- Modify: `plugins/developer-tools/qml/main.qml:323-335`

**Step 1: 修改窗口隐藏时的位置记忆逻辑**

找到main.qml中窗口隐藏时的代码（约第323-335行），添加位置记忆开关检查：

```qml
// 保存窗口位置和大小（第323-335行）
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
```

**Step 2: 修改窗口显示时的位置恢复逻辑**

找到main.qml中窗口显示时的代码（约第304-314行），添加位置记忆开关检查：

```qml
// 恢复上次的位置（第304-314行）
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
```

**Step 3: 验证修改**

检查修改是否正确：
- 位置记忆开关正确影响位置保存和恢复
- 禁用位置记忆时窗口始终居中显示
- 保持向后兼容性

### Task 8: 测试设置功能

**Files:**
- Test: 所有新创建和修改的文件

**Step 1: 构建插件验证语法**

运行构建脚本检查QML语法：

```bash
cd /home/forty/code/fortystory/noctalia-plugins
./tools/build.sh
```

预期输出：构建成功，没有语法错误。

**Step 2: 手动测试设置对话框**

1. **打开设置对话框**：
   - 启动插件（通过Noctalia Shell或测试工具）
   - 点击状态栏按钮打开插件窗口
   - 点击侧边栏底部的设置按钮（⚙️）
   - 预期：设置对话框正确显示，包含三个设置组

2. **测试设置修改**：
   - 修改主题偏好为"浅色主题"
   - 修改默认启动工具为"JSON"
   - 关闭窗口位置记忆开关
   - 点击"应用"按钮
   - 预期：控制台显示"Settings applied successfully"

3. **测试设置保存**：
   - 重新打开设置对话框
   - 验证设置值保持修改后的状态
   - 点击"确定"按钮
   - 预期：对话框关闭，控制台显示"Settings saved successfully"

**Step 3: 测试设置持久化**

1. **重启插件测试**：
   - 关闭插件窗口
   - 重新打开插件
   - 预期：插件启动时使用设置中指定的默认工具

2. **测试窗口位置记忆**：
   - 启用位置记忆，移动窗口位置后关闭
   - 重新打开插件，预期窗口在相同位置
   - 禁用位置记忆，移动窗口位置后关闭
   - 重新打开插件，预期窗口居中显示

**Step 4: 错误场景测试**

1. **API不可用测试**：
   - 模拟pluginApi.settings不可用
   - 打开设置对话框，预期显示API不可用警告
   - 修改设置并保存，预期控制台显示警告日志

2. **无效设置值测试**：
   - 手动修改存储的设置值为无效值
   - 打开设置对话框，预期使用默认值

### Task 9: 更新翻译文件

**Files:**
- Modify: `plugins/developer-tools/translations/zh_CN.ts`
- Modify: `plugins/developer-tools/translations/en_US.ts`

**Step 1: 更新中文翻译文件**

在zh_CN.ts中添加新的翻译字符串：

```xml
<!-- 在<context>部分添加新消息 -->
<context>
    <name>SettingsDialog</name>
    <message>
        <source>Settings</source>
        <translation>设置</translation>
    </message>
    <message>
        <source>Appearance</source>
        <translation>外观</translation>
    </message>
    <message>
        <source>Theme preference:</source>
        <translation>主题偏好：</translation>
    </message>
    <message>
        <source>Follow system</source>
        <translation>跟随系统</translation>
    </message>
    <message>
        <source>Light theme</source>
        <translation>浅色主题</translation>
    </message>
    <message>
        <source>Dark theme</source>
        <translation>深色主题</translation>
    </message>
    <message>
        <source>Theme changes will take effect after restarting the plugin</source>
        <translation>主题更改将在下次启动插件时生效</translation>
    </message>
    <message>
        <source>Select plugin theme appearance</source>
        <translation>选择插件主题外观</translation>
    </message>
    <message>
        <source>Startup settings</source>
        <translation>启动设置</translation>
    </message>
    <message>
        <source>Default startup tool:</source>
        <translation>默认启动工具：</translation>
    </message>
    <message>
        <source>Default tool will take effect after restarting the plugin</source>
        <translation>默认工具将在下次启动插件时生效</translation>
    </message>
    <message>
        <source>Select default tool when plugin starts</source>
        <translation>选择插件启动时默认显示的工具</translation>
    </message>
    <message>
        <source>Window behavior</source>
        <translation>窗口行为</translation>
    </message>
    <message>
        <source>Window position memory:</source>
        <translation>窗口位置记忆：</translation>
    </message>
    <message>
        <source>Enabled</source>
        <translation>启用</translation>
    </message>
    <message>
        <source>Disabled</source>
        <translation>禁用</translation>
    </message>
    <message>
        <source>Remember window position and size when closed</source>
        <translation>记住窗口关闭时的位置和大小</translation>
    </message>
    <message>
        <source>Disabling position memory will clear existing window position storage</source>
        <translation>禁用位置记忆将清除现有的窗口位置存储</translation>
    </message>
    <message>
        <source>Settings API unavailable, changes will not persist</source>
        <translation>设置API不可用，更改不会持久保存</translation>
    </message>
    <message>
        <source>Cancel</source>
        <translation>取消</translation>
    </message>
    <message>
        <source>Apply</source>
        <translation>应用</translation>
    </message>
    <message>
        <source>OK</source>
        <translation>确定</translation>
    </message>
    <message>
        <source>Settings saved</source>
        <translation>设置已保存</translation>
    </message>
    <message>
        <source>Settings applied</source>
        <translation>设置已应用</translation>
    </message>
    <message>
        <source>Settings save failed</source>
        <translation>设置保存失败</translation>
    </message>
    <message>
        <source>Settings dialog initialization failed</source>
        <translation>设置对话框初始化失败</translation>
    </message>
    <message>
        <source>Close</source>
        <translation>关闭</translation>
    </message>
</context>
```

**Step 2: 更新英文翻译文件**

在en_US.ts中添加相同的消息（英文原文）：

```xml
<!-- 在<context>部分添加新消息 -->
<context>
    <name>SettingsDialog</name>
    <message>
        <source>Settings</source>
        <translation>Settings</translation>
    </message>
    <message>
        <source>Appearance</source>
        <translation>Appearance</translation>
    </message>
    <message>
        <source>Theme preference:</source>
        <translation>Theme preference:</translation>
    </message>
    <message>
        <source>Follow system</source>
        <translation>Follow system</translation>
    </message>
    <message>
        <source>Light theme</source>
        <translation>Light theme</translation>
    </message>
    <message>
        <source>Dark theme</source>
        <translation>Dark theme</translation>
    </message>
    <message>
        <source>Theme changes will take effect after restarting the plugin</source>
        <translation>Theme changes will take effect after restarting the plugin</translation>
    </message>
    <message>
        <source>Select plugin theme appearance</source>
        <translation>Select plugin theme appearance</translation>
    </message>
    <message>
        <source>Startup settings</source>
        <translation>Startup settings</translation>
    </message>
    <message>
        <source>Default startup tool:</source>
        <translation>Default startup tool:</translation>
    </message>
    <message>
        <source>Default tool will take effect after restarting the plugin</source>
        <translation>Default tool will take effect after restarting the plugin</translation>
    </message>
    <message>
        <source>Select default tool when plugin starts</source>
        <translation>Select default tool when plugin starts</translation>
    </message>
    <message>
        <source>Window behavior</source>
        <translation>Window behavior</translation>
    </message>
    <message>
        <source>Window position memory:</source>
        <translation>Window position memory:</translation>
    </message>
    <message>
        <source>Enabled</source>
        <translation>Enabled</translation>
    </message>
    <message>
        <source>Disabled</source>
        <translation>Disabled</translation>
    </message>
    <message>
        <source>Remember window position and size when closed</source>
        <translation>Remember window position and size when closed</translation>
    </message>
    <message>
        <source>Disabling position memory will clear existing window position storage</source>
        <translation>Disabling position memory will clear existing window position storage</translation>
    </message>
    <message>
        <source>Settings API unavailable, changes will not persist</source>
        <translation>Settings API unavailable, changes will not persist</translation>
    </message>
    <message>
        <source>Cancel</source>
        <translation>Cancel</translation>
    </message>
    <message>
        <source>Apply</source>
        <translation>Apply</translation>
    </message>
    <message>
        <source>OK</source>
        <translation>OK</translation>
    </message>
    <message>
        <source>Settings saved</source>
        <translation>Settings saved</translation>
    </message>
    <message>
        <source>Settings applied</source>
        <translation>Settings applied</translation>
    </message>
    <message>
        <source>Settings save failed</source>
        <translation>Settings save failed</translation>
    </message>
    <message>
        <source>Settings dialog initialization failed</source>
        <translation>Settings dialog initialization failed</translation>
    </message>
    <message>
        <source>Close</source>
        <translation>Close</translation>
    </message>
</context>
```

**Step 3: 编译翻译文件**

运行翻译编译脚本（如果存在）：

```bash
cd /home/forty/code/fortystory/noctalia-plugins
./tools/translate.sh
```

或者手动使用lrelease命令：

```bash
cd /home/forty/code/fortystory/noctalia-plugins/plugins/developer-tools
lrelease translations/zh_CN.ts -qm translations/zh_CN.qm
lrelease translations/en_US.ts -qm translations/en_US.qm
```

**Step 4: 验证翻译**

1. 检查.qm文件是否生成
2. 启动插件，切换语言，验证设置对话框中的文本正确翻译

### Task 10: 最终验证和清理

**Step 1: 完整构建测试**

运行完整的构建和验证流程：

```bash
cd /home/forty/code/fortystory/noctalia-plugins
./tools/build.sh
./tools/verify.sh  # 如果存在验证脚本
```

预期：所有构建步骤成功，没有错误。

**Step 2: 功能完整性检查**

验证以下功能正常工作：

1. ✅ 侧边栏设置按钮可点击
2. ✅ 设置对话框正确显示
3. ✅ 三个设置项均可修改
4. ✅ 应用和确定按钮功能正常
5. ✅ 设置值正确持久化
6. ✅ 默认工具设置影响插件启动
7. ✅ 窗口位置记忆开关功能正常
8. ✅ 错误场景有适当反馈
9. ✅ 翻译文本正确显示

**Step 3: 代码清理和优化**

检查并清理任何调试日志或临时代码：

1. 移除不必要的console.log语句
2. 确保错误处理完整
3. 验证代码格式一致性
4. 检查QML组件导入顺序

**Step 4: 文档更新**

更新相关文档（如果存在）：
- 插件README.md中的设置功能介绍
- 用户指南中的设置说明
- 开发文档中的组件说明

---
## 执行选项

**Plan complete and saved to `docs/plans/2026-02-09-settings-implementation.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**