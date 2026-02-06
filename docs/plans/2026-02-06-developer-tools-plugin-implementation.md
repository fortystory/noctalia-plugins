# Noctalia开发者工具插件实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为Noctalia Shell实现开发者工具插件，包含状态栏按钮、侧边栏导航、时间戳转换和JSON格式化工具。

**Architecture:** 采用QML + Qt Quick开发，插件集合模式，侧边栏导航布局，工具组件化设计，集成Noctalia API。

**Tech Stack:** QML, Qt Quick, Noctalia插件API, Qt国际化系统

---

## 阶段1：基础设施设置

### Task 1: 创建项目目录结构

**Files:**
- Create: `plugins/developer-tools/`
- Create: `plugins/developer-tools/qml/`
- Create: `plugins/developer-tools/qml/tools/`
- Create: `plugins/developer-tools/qml/components/`
- Create: `plugins/developer-tools/translations/`
- Create: `shared/components/`
- Create: `tools/`

**Step 1: 创建目录结构**

运行命令：
```bash
mkdir -p plugins/developer-tools/{qml/{tools,components},translations}
mkdir -p shared/components
mkdir -p tools
```

**Step 2: 验证目录创建**

运行命令：
```bash
find plugins/developer-tools -type d
```
预期：显示所有创建的目录

**Step 3: 创建基础README**

在`plugins/developer-tools/README.md`添加：
```markdown
# Noctalia开发者工具插件

提供开发者常用工具的快速访问插件。

## 功能
- 时间戳转换工具
- JSON格式化工具
- 侧边栏导航
- 中英文支持
```

**Step 4: 提交更改**

---

### Task 2: 创建插件manifest.json

**Files:**
- Create: `plugins/developer-tools/manifest.json`

**Step 1: 创建manifest文件**

```json
{
  "id": "dev.fortystory.developer-tools",
  "name": "Developer Tools",
  "version": "1.0.0",
  "type": "bar-widget",
  "author": "Forty",
  "description": "Collection of developer utilities including timestamp converter and JSON formatter",
  "main": "qml/main.qml",
  "icon": "icon.svg",
  "translations": {
    "en_US": "translations/en_US.qm",
    "zh_CN": "translations/zh_CN.qm"
  },
  "settings": {
    "window": {
      "width": 600,
      "height": 400,
      "rememberPosition": true,
      "rememberSize": true
    },
    "sidebar": {
      "width": 80,
      "rememberSelection": true
    }
  },
  "permissions": [
    "clipboard",
    "system-time",
    "theme-access"
  ]
}
```

**Step 2: 创建占位图标**

创建`plugins/developer-tools/icon.svg`：
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <rect width="24" height="24" fill="#3b82f6" rx="4"/>
  <path d="M8 5v14l8-7z" fill="white"/>
  <path d="M12 8l2 2-2 2-2-2z" fill="white" opacity="0.7"/>
</svg>
```

**Step 3: 验证JSON语法**

运行命令：
```bash
python3 -m json.tool plugins/developer-tools/manifest.json
```
预期：输出格式化的JSON，无错误

**Step 4: 提交更改**

---

### Task 3: 创建工具脚本

**Files:**
- Create: `tools/build.sh`
- Create: `tools/deploy.sh`

**Step 1: 创建构建脚本**

```bash
#!/bin/bash
# build.sh - 构建开发者工具插件

set -e

PLUGIN_DIR="plugins/developer-tools"
BUILD_DIR="build"

echo "Building Developer Tools plugin..."

# 清理旧构建
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 复制文件
cp -r "$PLUGIN_DIR" "$BUILD_DIR/"

# 检查必需文件
if [ ! -f "$PLUGIN_DIR/manifest.json" ]; then
    echo "Error: manifest.json not found"
    exit 1
fi

if [ ! -f "$PLUGIN_DIR/qml/main.qml" ]; then
    echo "Warning: main.qml not found yet (first build)"
fi

echo "Build complete. Plugin in: $BUILD_DIR/developer-tools"
```

**Step 2: 创建部署脚本**

```bash
#!/bin/bash
# deploy.sh - 部署插件到Noctalia

set -e

PLUGIN_DIR="plugins/developer-tools"
NOCTALIA_PLUGINS="$HOME/.local/share/noctalia/plugins"

echo "Deploying Developer Tools plugin..."

# 检查目标目录
if [ ! -d "$NOCTALIA_PLUGINS" ]; then
    echo "Creating Noctalia plugins directory..."
    mkdir -p "$NOCTALIA_PLUGINS"
fi

# 部署插件
cp -r "$PLUGIN_DIR" "$NOCTALIA_PLUGINS/"

echo "Deployment complete. Restart Noctalia to load the plugin."
echo "Plugin installed at: $NOCTALIA_PLUGINS/developer-tools"
```

**Step 3: 设置执行权限**

运行命令：
```bash
chmod +x tools/build.sh tools/deploy.sh
```

**Step 4: 测试脚本**

运行命令：
```bash
./tools/build.sh
```
预期：显示构建成功信息

**Step 5: 提交更改**

---

## 阶段2：核心QML组件

### Task 4: 创建工具基类

**Files:**
- Create: `plugins/developer-tools/qml/tools/ToolBase.qml`

**Step 1: 创建ToolBase基类**

```qml
// ToolBase.qml - 所有工具页面的基类
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: toolBase

    // 公共属性
    property string toolName: ""
    property string toolIcon: ""
    property string toolDescription: ""
    property bool isActive: false

    // 配置属性
    property int spacing: 10
    property int margin: 15
    property int fontSize: 12
    property int titleFontSize: 14

    // 信号定义
    signal copyToClipboard(string text)
    signal showMessage(string message, string type)
    signal toolInitialized()
    signal toolDeactivated()

    // 初始化方法
    function initialize() {
        console.log("Initializing tool:", toolName)
        toolInitialized()
    }

    // 清理方法
    function cleanup() {
        console.log("Cleaning up tool:", toolName)
        toolDeactivated()
    }

    // 验证输入方法（子类可重写）
    function validateInput(input) {
        return input !== ""
    }

    // 格式化时间戳（工具方法）
    function formatTimestamp(timestamp, isMilliseconds) {
        if (isMilliseconds) {
            return new Date(timestamp).toLocaleString()
        } else {
            return new Date(timestamp * 1000).toLocaleString()
        }
    }

    // 获取当前时间戳（工具方法）
    function getCurrentTimestamp(isMilliseconds) {
        const now = Date.now()
        return isMilliseconds ? now : Math.floor(now / 1000)
    }

    // 组件加载完成
    Component.onCompleted: {
        console.log("Tool component loaded:", toolName)
    }

    // 组件销毁
    Component.onDestruction: {
        cleanup()
    }
}
```

**Step 2: 验证QML语法**

运行命令：
```bash
qmlscene --check plugins/developer-tools/qml/tools/ToolBase.qml || echo "qmlscene not available, continuing"
```
预期：无语法错误（或跳过）

**Step 3: 提交更改**

---

### Task 5: 创建主题定义

**Files:**
- Create: `plugins/developer-tools/qml/components/Theme.qml`

**Step 1: 创建Theme组件**

```qml
// Theme.qml - 主题定义和工具函数
import QtQuick 2.15

QtObject {
    id: theme

    // 颜色定义
    property color primaryColor: "#3b82f6"
    property color secondaryColor: "#64748b"
    property color successColor: "#10b981"
    property color warningColor: "#f59e0b"
    property color errorColor: "#ef4444"
    property color backgroundColor: "#ffffff"
    property color surfaceColor: "#f8fafc"
    property color textColor: "#1e293b"
    property color borderColor: "#e2e8f0"

    // 暗色主题颜色
    property color darkBackgroundColor: "#1e293b"
    property color darkSurfaceColor: "#334155"
    property color darkTextColor: "#f1f5f9"
    property color darkBorderColor: "#475569"

    // 尺寸定义
    property int spacingSmall: 5
    property int spacingMedium: 10
    property int spacingLarge: 15
    property int borderRadius: 6
    property int borderWidth: 1
    property int shadowRadius: 4

    // 字体定义
    property string fontFamily: "Inter, system-ui, sans-serif"
    property int fontSizeSmall: 11
    property int fontSizeNormal: 13
    property int fontSizeLarge: 15
    property int fontSizeTitle: 17

    // 工具函数：获取合适的颜色
    function getColor(type, isDark) {
        if (isDark) {
            switch(type) {
                case "background": return darkBackgroundColor
                case "surface": return darkSurfaceColor
                case "text": return darkTextColor
                case "border": return darkBorderColor
                default: return type
            }
        }
        return type
    }

    // 工具函数：应用阴影
    function applyShadow(item) {
        item.layer.enabled = true
        item.layer.effect = DropShadow {
            horizontalOffset: 0
            verticalOffset: 2
            radius: shadowRadius
            samples: 17
            color: "#1f2937" + "20" // 带透明度
        }
    }

    // 工具函数：创建圆角矩形
    function createRoundedRect(parent, color) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            Rectangle {
                radius: ${borderRadius}
                color: "${color}"
                border.width: ${borderWidth}
                border.color: "${borderColor}"
            }
        `, parent)
    }
}
```

**Step 2: 创建主题测试组件**

创建临时测试文件：
```bash
echo 'import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    width: 400
    height: 300
    visible: true
    title: "Theme Test"

    Theme { id: theme }

    Rectangle {
        anchors.centerIn: parent
        width: 200
        height: 100
        radius: theme.borderRadius
        color: theme.primaryColor
        border.width: theme.borderWidth
        border.color: theme.borderColor
    }
}' > test_theme.qml
```

**Step 3: 清理测试文件**

```bash
rm -f test_theme.qml
```

**Step 4: 提交更改**

---

### Task 6: 创建文本编辑器组件

**Files:**
- Create: `plugins/developer-tools/qml/components/TextEditor.qml`

**Step 1: 创建TextEditor组件**

```qml
// TextEditor.qml - 代码和文本编辑组件
import QtQuick 2.15
import QtQuick.Controls 2.15

FocusScope {
    id: textEditor

    // 公共属性
    property alias text: textArea.text
    property alias placeholderText: placeholder.text
    property bool readOnly: false
    property bool showLineNumbers: true
    property string language: "text" // text, json, javascript, etc.
    property int fontSize: 12
    property color textColor: theme.textColor
    property color backgroundColor: theme.surfaceColor
    property color borderColor: theme.borderColor

    // 信号
    signal textChanged()
    signal focusChanged(bool hasFocus)
    signal copyRequested()
    signal pasteRequested()

    // 尺寸
    property int lineNumberWidth: 40
    property int padding: 10

    // 引用主题
    property var theme: Theme {}

    // 实际宽度和高度
    width: 300
    height: 200

    // 背景
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: theme.borderRadius
        border.width: theme.borderWidth
        border.color: borderColor

        // 内阴影效果
        layer.enabled: true
        layer.effect: InnerShadow {
            horizontalOffset: 0
            verticalOffset: 1
            radius: 2
            samples: 9
            color: "#00000010"
        }
    }

    // 行号区域
    Rectangle {
        id: lineNumberArea
        visible: showLineNumbers
        width: lineNumberWidth
        height: parent.height
        color: Qt.lighter(backgroundColor, 1.1)
        border.width: theme.borderWidth
        border.color: borderColor
        radius: theme.borderRadius

        Flickable {
            id: lineNumberFlick
            anchors.fill: parent
            contentHeight: textArea.contentHeight
            clip: true

            // 行号文本
            Text {
                id: lineNumbers
                width: parent.width - 5
                y: textArea.flickableItem.contentY
                font.family: "Monospace, Consolas, 'Courier New', monospace"
                font.pixelSize: fontSize
                color: Qt.darker(textColor, 1.5)
                wrapMode: Text.NoWrap

                // 计算行号
                function updateLineNumbers() {
                    var lineCount = textArea.lineCount
                    var numbers = ""
                    for (var i = 1; i <= lineCount; i++) {
                        numbers += i + "\n"
                    }
                    lineNumbers.text = numbers
                }

                Component.onCompleted: updateLineNumbers()
            }
        }
    }

    // 文本编辑区域
    Flickable {
        id: flickable
        anchors.left: lineNumberArea.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 1
        contentWidth: textArea.width
        contentHeight: textArea.height
        clip: true

        TextArea.flickable: TextArea {
            id: textArea
            width: flickable.width - padding * 2
            height: Math.max(flickable.height, implicitHeight)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: padding

            font.family: "Monospace, Consolas, 'Courier New', monospace"
            font.pixelSize: fontSize
            color: textColor
            wrapMode: TextArea.Wrap
            selectByMouse: true
            readOnly: textEditor.readOnly

            background: Rectangle {
                color: "transparent"
            }

            // 占位符文本
            Text {
                id: placeholder
                anchors.fill: parent
                anchors.margins: 5
                font: textArea.font
                color: Qt.darker(textColor, 2.0)
                opacity: 0.6
                visible: textArea.text.length === 0
                text: placeholderText
                wrapMode: Text.Wrap
            }

            // 文本变化处理
            onTextChanged: {
                lineNumbers.updateLineNumbers()
                textEditor.textChanged()

                // 自动滚动到底部
                if (flickable.contentHeight > flickable.height) {
                    flickable.contentY = textArea.height - flickable.height
                }
            }

            // 焦点变化
            onFocusChanged: {
                textEditor.focusChanged(focus)
            }
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
            width: 8
        }
    }

    // 右键菜单
    Menu {
        id: contextMenu

        MenuItem {
            text: qsTr("复制")
            enabled: textArea.selectedText.length > 0
            onTriggered: {
                textArea.copy()
                textEditor.copyRequested()
            }
        }

        MenuItem {
            text: qsTr("粘贴")
            enabled: !readOnly
            onTriggered: {
                textArea.paste()
                textEditor.pasteRequested()
            }
        }

        MenuItem {
            text: qsTr("全选")
            onTriggered: textArea.selectAll()
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("清空")
            enabled: !readOnly
            onTriggered: textArea.text = ""
        }
    }

    // 鼠标右键处理
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: contextMenu.popup()
    }

    // 公共方法
    function copy() {
        textArea.copy()
        copyRequested()
    }

    function paste() {
        if (!readOnly) {
            textArea.paste()
            pasteRequested()
        }
    }

    function selectAll() {
        textArea.selectAll()
    }

    function clear() {
        if (!readOnly) {
            textArea.text = ""
        }
    }

    // 计算行数
    property int lineCount: {
        if (text.length === 0) return 1
        return text.split('\n').length
    }
}
```

**Step 2: 创建简单测试**

创建测试文件：
```bash
echo 'import QtQuick 2.15
import QtQuick.Window 2.15

Window {
    width: 500
    height: 400
    visible: true
    title: "TextEditor Test"

    TextEditor {
        anchors.centerIn: parent
        width: 400
        height: 300
        placeholderText: "Enter JSON here..."
        language: "json"
        fontSize: 14
        text: "{\n  \"test\": \"value\"\n}"
    }
}' > test_editor.qml
```

**Step 3: 清理测试文件**

```bash
rm -f test_editor.qml
```

**Step 4: 提交更改**

---

## 阶段3：主界面组件

### Task 7: 创建状态栏按钮组件

**Files:**
- Create: `plugins/developer-tools/qml/ToolButton.qml`

**Step 1: 创建ToolButton组件**

```qml
// ToolButton.qml - 状态栏按钮组件
import QtQuick 2.15
import QtQuick.Controls 2.15
import org.noctalia.shell 1.0

Button {
    id: toolButton

    // 公共属性
    property string buttonIcon: "🛠️"
    property string tooltip: qsTr("开发者工具")
    property bool windowVisible: false

    // 信号
    signal toggleWindow()

    // 尺寸
    width: 40
    height: 40

    // 样式
    background: Rectangle {
        radius: 4
        color: toolButton.down ? Qt.darker("#3b82f6", 1.2) :
               toolButton.hovered ? Qt.lighter("#3b82f6", 1.1) : "#3b82f6"
        border.width: 1
        border.color: Qt.darker("#3b82f6", 1.3)

        // 内阴影
        layer.enabled: true
        layer.effect: InnerShadow {
            horizontalOffset: 0
            verticalOffset: 1
            radius: 2
            samples: 9
            color: "#00000020"
        }
    }

    // 图标
    Text {
        anchors.centerIn: parent
        text: buttonIcon
        font.pixelSize: 18
        color: "white"
    }

    // 工具提示
    ToolTip {
        visible: toolButton.hovered
        text: tooltip
        delay: 500
    }

    // 点击事件
    onClicked: {
        console.log("Tool button clicked, window visible:", !windowVisible)
        windowVisible = !windowVisible
        toggleWindow()
    }

    // 键盘快捷键支持 (Ctrl+Shift+D)
    Shortcut {
        sequence: "Ctrl+Shift+D"
        onActivated: {
            console.log("Keyboard shortcut activated")
            windowVisible = !windowVisible
            toggleWindow()
        }
    }

    // 状态变化
    onWindowVisibleChanged: {
        console.log("Window visibility changed to:", windowVisible)
        if (windowVisible) {
            background.color = Qt.darker("#3b82f6", 1.1)
        } else {
            background.color = "#3b82f6"
        }
    }
}
```

**Step 2: 验证QML语法**

运行命令：
```bash
qmlscene --check plugins/developer-tools/qml/ToolButton.qml || echo "qmlscene not available, continuing"
```

**Step 3: 提交更改**

---

### Task 8: 创建侧边栏导航组件

**Files:**
- Create: `plugins/developer-tools/qml/components/Sidebar.qml`

**Step 1: 创建Sidebar组件**

```qml
// Sidebar.qml - 侧边栏导航组件
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: sidebar

    // 公共属性
    property int currentIndex: 0
    property int itemHeight: 60
    property int iconSize: 24
    property color backgroundColor: theme.surfaceColor
    property color selectedColor: theme.primaryColor
    property color textColor: theme.textColor
    property color iconColor: theme.secondaryColor

    // 信号
    signal toolSelected(int index, string toolName)

    // 工具模型
    ListModel {
        id: toolModel

        ListElement {
            name: qsTr("时间戳")
            icon: "🕐"
            description: qsTr("时间戳与时间字符串转换")
            component: "TimestampTool.qml"
        }

        ListElement {
            name: qsTr("JSON")
            icon: "📄"
            description: qsTr("JSON格式化和压缩")
            component: "JsonFormatter.qml"
        }

        // 未来可以动态添加更多工具
        // ListElement { name: "Base64"; icon: "🔐"; description: "Base64编解码"; component: "Base64Tool.qml" }
        // ListElement { name: "正则"; icon: ".*"; description: "正则表达式测试"; component: "RegexTool.qml" }
    }

    // 背景
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        border.width: 1
        border.color: Qt.darker(backgroundColor, 1.1)

        // 顶部装饰
        Rectangle {
            width: parent.width
            height: 2
            color: selectedColor
            opacity: 0.7
        }
    }

    // 工具列表
    ListView {
        id: toolList
        anchors.fill: parent
        anchors.topMargin: 10
        model: toolModel
        spacing: 5
        clip: true

        delegate: Item {
            width: toolList.width
            height: itemHeight

            // 背景
            Rectangle {
                id: itemBackground
                anchors.fill: parent
                anchors.margins: 5
                radius: 6
                color: ListView.isCurrentItem ?
                       Qt.lighter(selectedColor, 1.3) :
                       "transparent"
                border.width: ListView.isCurrentItem ? 1 : 0
                border.color: selectedColor

                // 悬停效果
                states: State {
                    name: "hovered"
                    when: mouseArea.containsMouse && !ListView.isCurrentItem
                    PropertyChanges {
                        target: itemBackground
                        color: Qt.lighter(backgroundColor, 1.1)
                        border.width: 1
                        border.color: Qt.darker(backgroundColor, 1.2)
                    }
                }

                transitions: Transition {
                    ColorAnimation { duration: 200 }
                    PropertyAnimation { property: "border.width"; duration: 200 }
                }
            }

            // 图标
            Text {
                id: iconText
                anchors {
                    top: parent.top
                    topMargin: 10
                    horizontalCenter: parent.horizontalCenter
                }
                text: icon
                font.pixelSize: iconSize
                color: ListView.isCurrentItem ? selectedColor : iconColor
            }

            // 工具名称
            Text {
                anchors {
                    top: iconText.bottom
                    topMargin: 5
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 5
                }
                text: name
                font.pixelSize: 11
                font.bold: ListView.isCurrentItem
                color: ListView.isCurrentItem ? selectedColor : textColor
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width - 10
            }

            // 鼠标区域
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    console.log("Tool selected:", index, name)
                    toolList.currentIndex = index
                    sidebar.currentIndex = index
                    sidebar.toolSelected(index, name)
                }
            }

            // 工具提示
            ToolTip {
                visible: mouseArea.containsMouse
                text: description
                delay: 300
            }
        }

        // 高亮移动动画
        highlight: Rectangle {
            width: toolList.width
            height: itemHeight
            color: "transparent"
            border.width: 2
            border.color: selectedColor
            radius: 8
            y: toolList.currentItem ? toolList.currentItem.y : 0

            Behavior on y {
                SpringAnimation {
                    spring: 3
                    damping: 0.2
                }
            }
        }

        highlightFollowsCurrentItem: false
    }

    // 底部区域（未来可添加设置按钮）
    Item {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 50

        // 分隔线
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.darker(backgroundColor, 1.2)
        }

        // 设置按钮（占位）
        /*
        Button {
            anchors.centerIn: parent
            text: qsTr("设置")
            icon.source: "qrc:/icons/settings.svg"
            flat: true

            onClicked: {
                console.log("Settings clicked")
                // 未来实现设置对话框
            }
        }
        */
    }

    // 公共方法：选择特定工具
    function selectTool(index) {
        if (index >= 0 && index < toolModel.count) {
            toolList.currentIndex = index
            currentIndex = index
            toolSelected(index, toolModel.get(index).name)
        }
    }

    // 公共方法：获取当前工具信息
    function getCurrentTool() {
        if (currentIndex >= 0 && currentIndex < toolModel.count) {
            return toolModel.get(currentIndex)
        }
        return null
    }

    // 公共方法：添加新工具（未来扩展）
    function addTool(name, icon, description, component) {
        toolModel.append({
            "name": name,
            "icon": icon,
            "description": description,
            "component": component
        })
    }

    // 初始化
    Component.onCompleted: {
        console.log("Sidebar initialized with", toolModel.count, "tools")
        // 默认选择第一个工具
        if (toolModel.count > 0) {
            selectTool(0)
        }
    }
}
```

**Step 2: 验证QML语法**

运行命令：
```bash
qmlscene --check plugins/developer-tools/qml/components/Sidebar.qml || echo "qmlscene not available, continuing"
```

**Step 3: 提交更改**

---

### Task 9: 创建主界面

**Files:**
- Create: `plugins/developer-tools/qml/main.qml`

**Step 1: 创建主界面**

```qml
// main.qml - 插件主入口
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import org.noctalia.shell 1.0

ApplicationWindow {
    id: mainWindow

    // 窗口属性
    width: pluginApi.settings.value("window/width", 600)
    height: pluginApi.settings.value("window/height", 400)
    title: qsTr("开发者工具")
    visible: false
    flags: Qt.Dialog | Qt.FramelessWindowHint
    color: "transparent"

    // Noctalia插件API
    property var pluginApi

    // 主题引用
    property var theme: Theme {}

    // 当前工具组件
    property var currentTool: null

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

            // 加载新工具
            var toolInfo = sidebar.getCurrentTool()
            if (toolInfo) {
                toolLoader.setSource("tools/" + toolInfo.component, {
                    "toolName": toolInfo.name,
                    "toolIcon": toolInfo.icon,
                    "toolDescription": toolInfo.description
                })

                // 保存引用
                currentTool = toolLoader.item

                // 初始化工具
                if (currentTool && typeof currentTool.initialize === "function") {
                    currentTool.initialize()
                }

                // 连接信号
                if (currentTool) {
                    currentTool.copyToClipboard.connect(copyToClipboardHandler)
                    currentTool.showMessage.connect(showMessageHandler)
                }
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

            // 恢复上次的位置
            var x = pluginApi.settings.value("window/x", -1)
            var y = pluginApi.settings.value("window/y", -1)
            if (x !== -1 && y !== -1) {
                mainWindow.x = x
                mainWindow.y = y
            } else {
                // 默认居中显示
                mainWindow.x = (Screen.width - width) / 2
                mainWindow.y = (Screen.height - height) / 2
            }

            // 恢复上次选择的工具
            var lastTool = pluginApi.settings.value("sidebar/lastTool", 0)
            sidebar.selectTool(lastTool)

        } else {
            console.log("Window hidden")

            // 保存窗口位置和大小
            pluginApi.settings.setValue("window/x", mainWindow.x)
            pluginApi.settings.setValue("window/y", mainWindow.y)
            pluginApi.settings.setValue("window/width", mainWindow.width)
            pluginApi.settings.setValue("window/height", mainWindow.height)

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

        // 设置主题
        theme.backgroundColor = pluginApi.style.backgroundColor
        theme.textColor = pluginApi.style.textColor
        theme.borderColor = pluginApi.style.borderColor
        theme.primaryColor = pluginApi.style.primaryColor

        // 监听主题变化
        pluginApi.styleChanged.connect(function() {
            console.log("Theme changed, updating colors")
            theme.backgroundColor = pluginApi.style.backgroundColor
            theme.textColor = pluginApi.style.textColor
            theme.borderColor = pluginApi.style.borderColor
            theme.primaryColor = pluginApi.style.primaryColor
        })
    }
}
```

**Step 2: 验证QML语法**

运行命令：
```bash
qmlscene --check plugins/developer-tools/qml/main.qml || echo "qmlscene not available, continuing"
```

**Step 3: 提交更改**

---

## 阶段4：工具实现

### Task 10: 实现时间戳转换工具

**Files:**
- Create: `plugins/developer-tools/qml/tools/TimestampTool.qml`

**Step 1: 创建时间戳转换工具**

```qml
// TimestampTool.qml - 时间戳与时间字符串转换工具
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ToolBase {
    id: timestampTool

    // 工具属性
    toolName: qsTr("时间戳转换")
    toolIcon: "🕐"
    toolDescription: qsTr("时间戳与时间字符串相互转换")

    // 状态属性
    property string currentTime: ""
    property string inputTimestamp: ""
    property string inputDateTime: ""
    property string outputResult: ""
    property bool useMilliseconds: false
    property bool useUTC: false
    property int timestampFormat: 0 // 0: Unix秒, 1: Unix毫秒

    // 时间格式选项
    property var timeFormats: [
        qsTr("Unix时间戳（秒）"),
        qsTr("Unix时间戳（毫秒）"),
        qsTr("ISO 8601"),
        qsTr("RFC 3339")
    ]

    // 定时器用于更新当前时间
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: updateCurrentTime()
    }

    // 组件布局
    ColumnLayout {
        anchors.fill: parent
        spacing: theme.spacingMedium

        // 当前时间显示
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("当前时间")

            ColumnLayout {
                width: parent.width
                spacing: theme.spacingSmall

                Text {
                    text: currentTime
                    font.pixelSize: theme.fontSizeLarge
                    font.bold: true
                    color: theme.primaryColor
                }

                RowLayout {
                    CheckBox {
                        text: qsTr("使用UTC")
                        checked: useUTC
                        onCheckedChanged: {
                            useUTC = checked
                            updateCurrentTime()
                            convertTimestamp()
                            convertDateTime()
                        }
                    }

                    CheckBox {
                        text: qsTr("毫秒精度")
                        checked: useMilliseconds
                        onCheckedChanged: {
                            useMilliseconds = checked
                            updateCurrentTime()
                            convertTimestamp()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: qsTr("复制当前时间")
                        onClicked: copyCurrentTime()
                    }
                }
            }
        }

        // 时间戳转日期时间
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("时间戳 → 日期时间")

            ColumnLayout {
                width: parent.width
                spacing: theme.spacingSmall

                RowLayout {
                    Label {
                        text: qsTr("时间戳：")
                        Layout.minimumWidth: 80
                    }

                    TextField {
                        id: timestampInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("输入时间戳")
                        text: inputTimestamp

                        onTextChanged: {
                            inputTimestamp = text
                            convertTimestamp()
                        }
                    }

                    Button {
                        text: qsTr("现在")
                        onClicked: {
                            timestampInput.text = getCurrentTimestamp(useMilliseconds)
                            convertTimestamp()
                        }
                    }
                }

                RowLayout {
                    Label {
                        text: qsTr("格式：")
                        Layout.minimumWidth: 80
                    }

                    ComboBox {
                        id: timestampFormatCombo
                        Layout.fillWidth: true
                        model: timeFormats
                        currentIndex: timestampFormat

                        onCurrentIndexChanged: {
                            timestampFormat = currentIndex
                            convertTimestamp()
                        }
                    }
                }

                // 转换结果
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("转换结果")
                    background: Rectangle {
                        color: theme.surfaceColor
                        radius: theme.borderRadius
                    }

                    ColumnLayout {
                        width: parent.width

                        Text {
                            text: outputResult || qsTr("等待输入...")
                            font.pixelSize: theme.fontSizeNormal
                            color: outputResult ? theme.textColor : Qt.darker(theme.textColor, 2.0)
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Button {
                            text: qsTr("复制结果")
                            enabled: outputResult.length > 0
                            onClicked: copyTimestampResult()
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }
        }

        // 日期时间转时间戳
        GroupBox {
            Layout.fillWidth: true
            title: qsTr("日期时间 → 时间戳")

            ColumnLayout {
                width: parent.width
                spacing: theme.spacingSmall

                RowLayout {
                    Label {
                        text: qsTr("日期时间：")
                        Layout.minimumWidth: 80
                    }

                    TextField {
                        id: datetimeInput
                        Layout.fillWidth: true
                        placeholderText: qsTr("例如：2026-02-06 14:30:00")
                        text: inputDateTime

                        onTextChanged: {
                            inputDateTime = text
                            convertDateTime()
                        }
                    }

                    Button {
                        text: qsTr("现在")
                        onClicked: {
                            datetimeInput.text = formatCurrentDateTime()
                            convertDateTime()
                        }
                    }
                }

                // 日期时间转时间戳结果
                GroupBox {
                    Layout.fillWidth: true
                    title: qsTr("时间戳结果")
                    background: Rectangle {
                        color: theme.surfaceColor
                        radius: theme.borderRadius
                    }

                    ColumnLayout {
                        width: parent.width

                        Text {
                            id: timestampResultText
                            text: qsTr("等待输入...")
                            font.pixelSize: theme.fontSizeNormal
                            color: theme.textColor
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Button {
                            text: qsTr("复制时间戳")
                            enabled: timestampResultText.text !== qsTr("等待输入...")
                            onClicked: copyDateTimeResult()
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    // 工具方法：更新当前时间
    function updateCurrentTime() {
        var now = new Date()
        if (useUTC) {
            currentTime = now.toUTCString()
        } else {
            currentTime = now.toLocaleString()
        }

        if (useMilliseconds) {
            currentTime += " (" + now.getTime() + "ms)"
        } else {
            currentTime += " (" + Math.floor(now.getTime() / 1000) + "s)"
        }
    }

    // 工具方法：转换时间戳
    function convertTimestamp() {
        if (!inputTimestamp || inputTimestamp.trim() === "") {
            outputResult = ""
            return
        }

        try {
            var timestamp = parseInt(inputTimestamp)
            if (isNaN(timestamp)) {
                outputResult = qsTr("错误：无效的时间戳")
                showMessage(qsTr("时间戳必须是数字"), "error")
                return
            }

            // 根据格式调整时间戳
            var date
            switch(timestampFormat) {
                case 0: // Unix秒
                    date = new Date(timestamp * 1000)
                    break
                case 1: // Unix毫秒
                    date = new Date(timestamp)
                    break
                case 2: // ISO 8601 (直接使用)
                    date = new Date(timestamp)
                    break
                case 3: // RFC 3339 (直接使用)
                    date = new Date(timestamp)
                    break
                default:
                    date = new Date(timestamp * 1000)
            }

            if (isNaN(date.getTime())) {
                outputResult = qsTr("错误：无效的日期")
                showMessage(qsTr("无法解析时间戳"), "error")
                return
            }

            // 格式化输出
            if (useUTC) {
                outputResult = date.toUTCString()
            } else {
                outputResult = date.toLocaleString()
            }

            // 添加原始时间戳信息
            outputResult += "\n" + qsTr("原始值：") + timestamp

        } catch (error) {
            outputResult = qsTr("转换错误：") + error.message
            showMessage(qsTr("转换失败：") + error.message, "error")
        }
    }

    // 工具方法：转换日期时间
    function convertDateTime() {
        if (!inputDateTime || inputDateTime.trim() === "") {
            timestampResultText.text = qsTr("等待输入...")
            return
        }

        try {
            var date
            if (useUTC) {
                // 解析为UTC时间
                date = new Date(inputDateTime + " UTC")
                if (isNaN(date.getTime())) {
                    date = new Date(inputDateTime)
                }
            } else {
                date = new Date(inputDateTime)
            }

            if (isNaN(date.getTime())) {
                timestampResultText.text = qsTr("错误：无法解析日期时间")
                showMessage(qsTr("日期时间格式无效"), "error")
                return
            }

            // 根据格式输出时间戳
            var result
            if (useMilliseconds) {
                result = date.getTime() + " " + qsTr("毫秒")
            } else {
                result = Math.floor(date.getTime() / 1000) + " " + qsTr("秒")
            }

            timestampResultText.text = result

        } catch (error) {
            timestampResultText.text = qsTr("转换错误：") + error.message
            showMessage(qsTr("转换失败：") + error.message, "error")
        }
    }

    // 工具方法：获取当前时间戳
    function getCurrentTimestamp(isMs) {
        var now = Date.now()
        return isMs ? now : Math.floor(now / 1000)
    }

    // 工具方法：格式化当前日期时间
    function formatCurrentDateTime() {
        var now = new Date()
        var year = now.getFullYear()
        var month = String(now.getMonth() + 1).padStart(2, '0')
        var day = String(now.getDate()).padStart(2, '0')
        var hours = String(now.getHours()).padStart(2, '0')
        var minutes = String(now.getMinutes()).padStart(2, '0')
        var seconds = String(now.getSeconds()).padStart(2, '0')

        return year + "-" + month + "-" + day + " " + hours + ":" + minutes + ":" + seconds
    }

    // 工具方法：复制当前时间
    function copyCurrentTime() {
        var text = currentTime.split(" (")[0] // 移除时间戳部分
        copyToClipboard(text)
        showMessage(qsTr("当前时间已复制"), "success")
    }

    // 工具方法：复制时间戳转换结果
    function copyTimestampResult() {
        if (outputResult) {
            var lines = outputResult.split("\n")
            copyToClipboard(lines[0]) // 只复制日期时间部分
            showMessage(qsTr("转换结果已复制"), "success")
        }
    }

    // 工具方法：复制日期时间转换结果
    function copyDateTimeResult() {
        if (timestampResultText.text && timestampResultText.text !== qsTr("等待输入...")) {
            var text = timestampResultText.text.split(" ")[0] // 只取数字部分
            copyToClipboard(text)
            showMessage(qsTr("时间戳已复制"), "success")
        }
    }

    // 工具初始化
    function initialize() {
        console.log("Timestamp tool initialized")
        updateCurrentTime()
    }

    // 输入验证
    function validateInput(input) {
        if (!input || input.trim() === "") {
            return false
        }

        // 检查是否是数字（时间戳）或有效日期
        if (!isNaN(parseInt(input))) {
            return true
        }

        var date = new Date(input)
        return !isNaN(date.getTime())
    }

    // 组件加载完成
    Component.onCompleted: {
        console.log("Timestamp tool component loaded")
    }
}
```

**Step 2: 验证QML语法**

运行命令：
```bash
qmlscene --check plugins/developer-tools/qml/tools/TimestampTool.qml || echo "qmlscene not available, continuing"
```

**Step 3: 提交更改**

---

### Task 11: 实现JSON格式化工具

**Files:**
- Create: `plugins/developer-tools/qml/tools/JsonFormatter.qml`

**Step 1: 创建JSON格式化工具**

```qml
// JsonFormatter.qml - JSON格式化与压缩工具
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ToolBase {
    id: jsonFormatter

    // 工具属性
    toolName: qsTr("JSON格式化")
    toolIcon: "📄"
    toolDescription: qsTr("JSON格式化和压缩，支持语法高亮")

    // 状态属性
    property string inputJson: ""
    property string outputJson: ""
    property bool isValidJson: false
    property string errorMessage: ""
    property int indentSize: 2
    property bool compactMode: false

    // 组件布局
    ColumnLayout {
        anchors.fill: parent
        spacing: theme.spacingMedium

        // 输入区域
        GroupBox {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            title: qsTr("输入JSON")

            ColumnLayout {
                width: parent.width
                spacing: theme.spacingSmall

                // 输入编辑器
                TextEditor {
                    id: inputEditor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: qsTr('输入JSON，例如：{"name": "value", "array": [1, 2, 3]}')
                    language: "json"
                    fontSize: theme.fontSizeNormal

                    onTextChanged: {
                        inputJson = text
                        validateJson()
                    }
                }

                // 操作按钮
                RowLayout {
                    spacing: theme.spacingSmall

                    Button {
                        text: qsTr("格式化")
                        onClicked: formatJson()
                    }

                    Button {
                        text: qsTr("压缩")
                        onClicked: compressJson()
                    }

                    Button {
                        text: qsTr("清空")
                        onClicked: clearInput()
                    }

                    Item { Layout.fillWidth: true }

                    // 语法状态指示器
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: isValidJson ? theme.successColor : theme.errorColor

                        ToolTip {
                            visible: parentMouseArea.containsMouse
                            text: isValidJson ? qsTr("JSON语法正确") : qsTr("JSON语法错误")
                        }
                    }

                    MouseArea {
                        id: parentMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }

                    Text {
                        text: isValidJson ? qsTr("✓ 有效") : qsTr("✗ 无效")
                        color: isValidJson ? theme.successColor : theme.errorColor
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // 错误消息
                Text {
                    visible: errorMessage.length > 0
                    text: errorMessage
                    color: theme.errorColor
                    font.pixelSize: theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }

        // 输出区域
        GroupBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: qsTr("格式化结果")

            ColumnLayout {
                width: parent.width
                spacing: theme.spacingSmall

                // 输出编辑器
                TextEditor {
                    id: outputEditor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readOnly: true
                    language: "json"
                    fontSize: theme.fontSizeNormal
                    text: outputJson

                    // 语法高亮状态
                    property bool outputValid: true
                }

                // 操作按钮
                RowLayout {
                    spacing: theme.spacingSmall

                    Button {
                        text: qsTr("复制结果")
                        enabled: outputJson.length > 0
                        onClicked: copyOutput()
                    }

                    Button {
                        text: qsTr("交换")
                        onClicked: swapInputOutput()
                    }

                    Button {
                        text: qsTr("示例")
                        onClicked: loadExample()
                    }

                    Item { Layout.fillWidth: true }

                    // 缩进设置
                    RowLayout {
                        spacing: theme.spacingSmall

                        Label {
                            text: qsTr("缩进：")
                            font.pixelSize: theme.fontSizeSmall
                        }

                        ComboBox {
                            id: indentCombo
                            model: [2, 4, 8]
                            currentIndex: 0
                            width: 60

                            onCurrentIndexChanged: {
                                indentSize = model[currentIndex]
                                if (isValidJson && !compactMode) {
                                    formatJson()
                                }
                            }
                        }

                        Text {
                            text: qsTr("空格")
                            font.pixelSize: theme.fontSizeSmall
                        }
                    }
                }
            }
        }
    }

    // 工具方法：验证JSON
    function validateJson() {
        if (!inputJson || inputJson.trim() === "") {
            isValidJson = false
            errorMessage = ""
            return
        }

        try {
            // 尝试解析JSON
            JSON.parse(inputJson)
            isValidJson = true
            errorMessage = ""
        } catch (error) {
            isValidJson = false
            errorMessage = qsTr("JSON错误：") + error.message

            // 提取更友好的错误信息
            var match = error.message.match(/position (\d+)/)
            if (match) {
                var position = parseInt(match[1])
                var lines = inputJson.substring(0, position).split('\n')
                var line = lines.length
                var column = lines[lines.length - 1].length
                errorMessage += "\n" + qsTr("位置：第") + line + qsTr("行，第") + column + qsTr("列")
            }
        }
    }

    // 工具方法：格式化JSON
    function formatJson() {
        if (!isValidJson) {
            showMessage(qsTr("请先输入有效的JSON"), "warning")
            return
        }

        try {
            var parsed = JSON.parse(inputJson)
            outputJson = JSON.stringify(parsed, null, indentSize)
            compactMode = false
            showMessage(qsTr("JSON格式化完成"), "success")
        } catch (error) {
            outputJson = qsTr("格式化错误：") + error.message
            showMessage(qsTr("格式化失败：") + error.message, "error")
        }
    }

    // 工具方法：压缩JSON
    function compressJson() {
        if (!isValidJson) {
            showMessage(qsTr("请先输入有效的JSON"), "warning")
            return
        }

        try {
            var parsed = JSON.parse(inputJson)
            outputJson = JSON.stringify(parsed)
            compactMode = true
            showMessage(qsTr("JSON压缩完成"), "success")
        } catch (error) {
            outputJson = qsTr("压缩错误：") + error.message
            showMessage(qsTr("压缩失败：") + error.message, "error")
        }
    }

    // 工具方法：复制输出
    function copyOutput() {
        if (outputJson && outputJson.length > 0) {
            copyToClipboard(outputJson)
            showMessage(qsTr("JSON已复制到剪贴板"), "success")
        }
    }

    // 工具方法：交换输入输出
    function swapInputOutput() {
        if (outputJson && outputJson.length > 0) {
            var temp = inputJson
            inputJson = outputJson
            outputJson = temp

            inputEditor.text = inputJson
            outputEditor.text = outputJson

            validateJson()
            showMessage(qsTr("输入输出已交换"), "success")
        }
    }

    // 工具方法：清空输入
    function clearInput() {
        inputJson = ""
        outputJson = ""
        errorMessage = ""
        isValidJson = false

        inputEditor.text = ""
        outputEditor.text = ""

        showMessage(qsTr("已清空"), "info")
    }

    // 工具方法：加载示例
    function loadExample() {
        var example = {
            "app": "Noctalia Developer Tools",
            "version": "1.0.0",
            "features": [
                "Timestamp Converter",
                "JSON Formatter"
            ],
            "author": {
                "name": "Forty",
                "email": "dev@example.com"
            },
            "settings": {
                "windowSize": {
                    "width": 600,
                    "height": 400
                },
                "theme": "auto",
                "language": "zh_CN"
            },
            "metadata": {
                "created": "2026-02-06T10:30:00Z",
                "updated": "2026-02-06T14:45:00Z"
            }
        }

        inputJson = JSON.stringify(example, null, 2)
        inputEditor.text = inputJson
        validateJson()

        if (isValidJson) {
            formatJson()
            showMessage(qsTr("示例JSON已加载"), "success")
        }
    }

    // 工具方法：语法高亮（简化版）
    function syntaxHighlight(json) {
        if (!json) return ""

        // 简单的高亮替换
        var highlighted = json
            .replace(/(".*?"):/g, '<span style="color: #0366d6;">$1</span>:')
            .replace(/: ("[^"]*")/g, ': <span style="color: #22863a;">$1</span>')
            .replace(/: (true|false|null)/g, ': <span style="color: #d73a49;">$1</span>')
            .replace(/: (\d+)/g, ': <span style="color: #005cc5;">$1</span>')

        return highlighted
    }

    // 工具初始化
    function initialize() {
        console.log("JSON formatter initialized")
        loadExample() // 默认加载示例
    }

    // 输入验证
    function validateInput(input) {
        if (!input || input.trim() === "") {
            return false
        }

        try {
            JSON.parse(input)
            return true
        } catch (error) {
            return false
        }
    }

    // 组件加载完成
    Component.onCompleted: {
        console.log("JSON formatter component loaded")
    }
}
```

**Step 2: 验证QML语法**

运行命令：
```bash
qmlscene --check plugins/developer-tools/qml/tools/JsonFormatter.qml || echo "qmlscene not available, continuing"
```

**Step 3: 提交更改**

---

## 阶段5：国际化支持

### Task 12: 创建翻译文件

**Files:**
- Create: `plugins/developer-tools/translations/en_US.ts`
- Create: `plugins/developer-tools/translations/zh_CN.ts`

**Step 1: 创建英文翻译文件**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.1" language="en_US">
<context>
    <name>ToolButton</name>
    <message>
        <location filename="../qml/ToolButton.qml" line="12"/>
        <source>开发者工具</source>
        <translation>Developer Tools</translation>
    </message>
</context>
<context>
    <name>Sidebar</name>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="25"/>
        <source>时间戳</source>
        <translation>Timestamp</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="26"/>
        <source>时间戳与时间字符串转换</source>
        <translation>Timestamp and datetime conversion</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="31"/>
        <source>JSON</source>
        <translation>JSON</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="32"/>
        <source>JSON格式化和压缩</source>
        <translation>JSON formatting and compression</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="144"/>
        <source>设置</source>
        <translation>Settings</translation>
    </message>
</context>
<context>
    <name>main</name>
    <message>
        <location filename="../qml/main.qml" line="15"/>
        <source>开发者工具</source>
        <translation>Developer Tools</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="119"/>
        <source>选择左侧工具开始使用</source>
        <translation>Select a tool from the left to begin</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="184"/>
        <source>关闭</source>
        <translation>Close</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="341"/>
        <source>已复制到剪贴板</source>
        <translation>Copied to clipboard</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="346"/>
        <source>复制功能需要Noctalia API支持</source>
        <translation>Copy function requires Noctalia API support</translation>
    </message>
</context>
<context>
    <name>TimestampTool</name>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="12"/>
        <source>时间戳转换</source>
        <translation>Timestamp Converter</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="13"/>
        <source>时间戳与时间字符串转换</source>
        <translation>Timestamp and datetime conversion</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="65"/>
        <source>当前时间</source>
        <translation>Current Time</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="76"/>
        <source>使用UTC</source>
        <translation>Use UTC</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="82"/>
        <source>毫秒精度</source>
        <translation>Milliseconds</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="91"/>
        <source>复制当前时间</source>
        <translation>Copy Current Time</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="97"/>
        <source>时间戳 → 日期时间</source>
        <translation>Timestamp → Datetime</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="103"/>
        <source>时间戳：</source>
        <translation>Timestamp:</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="115"/>
        <source>输入时间戳</source>
        <translation>Enter timestamp</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="120"/>
        <source>现在</source>
        <translation>Now</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="126"/>
        <source>格式：</source>
        <translation>Format:</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="132"/>
        <source>Unix时间戳（秒）</source>
        <translation>Unix timestamp (seconds)</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="133"/>
        <source>Unix时间戳（毫秒）</source>
        <translation>Unix timestamp (milliseconds)</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="134"/>
        <source>ISO 8601</source>
        <translation>ISO 8601</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="135"/>
        <source>RFC 3339</source>
        <translation>RFC 3339</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="144"/>
        <source>转换结果</source>
        <translation>Conversion Result</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="151"/>
        <source>等待输入...</source>
        <translation>Waiting for input...</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="157"/>
        <source>复制结果</source>
        <translation>Copy Result</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="164"/>
        <source>日期时间 → 时间戳</source>
        <translation>Datetime → Timestamp</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="170"/>
        <source>日期时间：</source>
        <translation>Datetime:</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="176"/>
        <source>例如：2026-02-06 14:30:00</source>
        <translation>e.g., 2026-02-06 14:30:00</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="182"/>
        <source>时间戳结果</source>
        <translation>Timestamp Result</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="196"/>
        <source>复制时间戳</source>
        <translation>Copy Timestamp</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="258"/>
        <source>错误：无效的时间戳</source>
        <translation>Error: Invalid timestamp</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="262"/>
        <source>时间戳必须是数字</source>
        <translation>Timestamp must be a number</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="281"/>
        <source>错误：无效的日期</source>
        <translation>Error: Invalid date</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="285"/>
        <source>无法解析时间戳</source>
        <translation>Cannot parse timestamp</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="290"/>
        <source>原始值：</source>
        <translation>Original value:</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="297"/>
        <source>转换错误：</source>
        <translation>Conversion error:</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="301"/>
        <source>转换失败：</source>
        <translation>Conversion failed:</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="324"/>
        <source>错误：无法解析日期时间</source>
        <translation>Error: Cannot parse datetime</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="328"/>
        <source>日期时间格式无效</source>
        <translation>Datetime format is invalid</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="339"/>
        <source>毫秒</source>
        <translation>milliseconds</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="341"/>
        <source>秒</source>
        <translation>seconds</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="365"/>
        <source>当前时间已复制</source>
        <translation>Current time copied</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="376"/>
        <source>转换结果已复制</source>
        <translation>Conversion result copied</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="388"/>
        <source>时间戳已复制</source>
        <translation>Timestamp copied</translation>
    </message>
</context>
<context>
    <name>JsonFormatter</name>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="12"/>
        <source>JSON格式化</source>
        <translation>JSON Formatter</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="13"/>
        <source>JSON格式化和压缩，支持语法高亮</source>
        <translation>JSON formatting and compression with syntax highlighting</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="52"/>
        <source>输入JSON</source>
        <translation>Input JSON</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="60"/>
        <source>输入JSON，例如：{"name": "value", "array": [1, 2, 3]}</source>
        <translation>Enter JSON, e.g., {"name": "value", "array": [1, 2, 3]}</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="70"/>
        <source>格式化</source>
        <translation>Format</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="75"/>
        <source>压缩</source>
        <translation>Compress</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="80"/>
        <source>清空</source>
        <translation>Clear</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="94"/>
        <source>JSON语法正确</source>
        <translation>JSON syntax is correct</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="97"/>
        <source>JSON语法错误</source>
        <translation>JSON syntax error</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="101"/>
        <source>✓ 有效</source>
        <translation>✓ Valid</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="103"/>
        <source>✗ 无效</source>
        <translation>✗ Invalid</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="117"/>
        <source>格式化结果</source>
        <translation>Formatted Result</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="136"/>
        <source>复制结果</source>
        <translation>Copy Result</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="141"/>
        <source>交换</source>
        <translation>Swap</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="146"/>
        <source>示例</source>
        <translation>Example</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="154"/>
        <source>缩进：</source>
        <translation>Indent:</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="164"/>
        <source>空格</source>
        <translation>spaces</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="185"/>
        <source>JSON错误：</source>
        <translation>JSON error:</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="192"/>
        <source>位置：第</source>
        <translation>Position: line</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="192"/>
        <source>行，第</source>
        <translation>, column</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="192"/>
        <source>列</source>
        <translation></translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="203"/>
        <source>请先输入有效的JSON</source>
        <translation>Please enter valid JSON first</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="212"/>
        <source>JSON格式化完成</source>
        <translation>JSON formatting completed</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="216"/>
        <source>格式化错误：</source>
        <translation>Formatting error:</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="220"/>
        <source>格式化失败：</source>
        <translation>Formatting failed:</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="232"/>
        <source>JSON压缩完成</source>
        <translation>JSON compression completed</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="236"/>
        <source>压缩错误：</source>
        <translation>Compression error:</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="240"/>
        <source>压缩失败：</source>
        <translation>Compression failed:</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="248"/>
        <source>JSON已复制到剪贴板</source>
        <translation>JSON copied to clipboard</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="258"/>
        <source>输入输出已交换</source>
        <translation>Input and output swapped</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="269"/>
        <source>已清空</source>
        <translation>Cleared</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="313"/>
        <source>示例JSON已加载</source>
        <translation>Example JSON loaded</translation>
    </message>
</context>
</TS>
```

**Step 2: 创建中文翻译文件**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE TS>
<TS version="2.1" language="zh_CN">
<context>
    <name>ToolButton</name>
    <message>
        <location filename="../qml/ToolButton.qml" line="12"/>
        <source>开发者工具</source>
        <translation>开发者工具</translation>
    </message>
</context>
<context>
    <name>Sidebar</name>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="25"/>
        <source>时间戳</source>
        <translation>时间戳</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="26"/>
        <source>时间戳与时间字符串转换</source>
        <translation>时间戳与时间字符串转换</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="31"/>
        <source>JSON</source>
        <translation>JSON</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="32"/>
        <source>JSON格式化和压缩</source>
        <translation>JSON格式化和压缩</translation>
    </message>
    <message>
        <location filename="../qml/components/Sidebar.qml" line="144"/>
        <source>设置</source>
        <translation>设置</translation>
    </message>
</context>
<context>
    <name>main</name>
    <message>
        <location filename="../qml/main.qml" line="15"/>
        <source>开发者工具</source>
        <translation>开发者工具</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="119"/>
        <source>选择左侧工具开始使用</source>
        <translation>选择左侧工具开始使用</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="184"/>
        <source>关闭</source>
        <translation>关闭</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="341"/>
        <source>已复制到剪贴板</source>
        <translation>已复制到剪贴板</translation>
    </message>
    <message>
        <location filename="../qml/main.qml" line="346"/>
        <source>复制功能需要Noctalia API支持</source>
        <translation>复制功能需要Noctalia API支持</translation>
    </message>
</context>
<context>
    <name>TimestampTool</name>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="12"/>
        <source>时间戳转换</source>
        <translation>时间戳转换</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="13"/>
        <source>时间戳与时间字符串转换</source>
        <translation>时间戳与时间字符串转换</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="65"/>
        <source>当前时间</source>
        <translation>当前时间</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="76"/>
        <source>使用UTC</source>
        <translation>使用UTC</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="82"/>
        <source>毫秒精度</source>
        <translation>毫秒精度</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="91"/>
        <source>复制当前时间</source>
        <translation>复制当前时间</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="97"/>
        <source>时间戳 → 日期时间</source>
        <translation>时间戳 → 日期时间</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="103"/>
        <source>时间戳：</source>
        <translation>时间戳：</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="115"/>
        <source>输入时间戳</source>
        <translation>输入时间戳</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="120"/>
        <source>现在</source>
        <translation>现在</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="126"/>
        <source>格式：</source>
        <translation>格式：</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="132"/>
        <source>Unix时间戳（秒）</source>
        <translation>Unix时间戳（秒）</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="133"/>
        <source>Unix时间戳（毫秒）</source>
        <translation>Unix时间戳（毫秒）</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="134"/>
        <source>ISO 8601</source>
        <translation>ISO 8601</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="135"/>
        <source>RFC 3339</source>
        <translation>RFC 3339</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="144"/>
        <source>转换结果</source>
        <translation>转换结果</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="151"/>
        <source>等待输入...</source>
        <translation>等待输入...</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="157"/>
        <source>复制结果</source>
        <translation>复制结果</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="164"/>
        <source>日期时间 → 时间戳</source>
        <translation>日期时间 → 时间戳</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="170"/>
        <source>日期时间：</source>
        <translation>日期时间：</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="176"/>
        <source>例如：2026-02-06 14:30:00</source>
        <translation>例如：2026-02-06 14:30:00</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="182"/>
        <source>时间戳结果</source>
        <translation>时间戳结果</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="196"/>
        <source>复制时间戳</source>
        <translation>复制时间戳</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="258"/>
        <source>错误：无效的时间戳</source>
        <translation>错误：无效的时间戳</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="262"/>
        <source>时间戳必须是数字</source>
        <translation>时间戳必须是数字</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="281"/>
        <source>错误：无效的日期</source>
        <translation>错误：无效的日期</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="285"/>
        <source>无法解析时间戳</source>
        <translation>无法解析时间戳</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="290"/>
        <source>原始值：</source>
        <translation>原始值：</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="297"/>
        <source>转换错误：</source>
        <translation>转换错误：</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="301"/>
        <source>转换失败：</source>
        <translation>转换失败：</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="324"/>
        <source>错误：无法解析日期时间</source>
        <translation>错误：无法解析日期时间</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="328"/>
        <source>日期时间格式无效</source>
        <translation>日期时间格式无效</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="339"/>
        <source>毫秒</source>
        <translation>毫秒</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="341"/>
        <source>秒</source>
        <translation>秒</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="365"/>
        <source>当前时间已复制</source>
        <translation>当前时间已复制</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="376"/>
        <source>转换结果已复制</source>
        <translation>转换结果已复制</translation>
    </message>
    <message>
        <location filename="../qml/tools/TimestampTool.qml" line="388"/>
        <source>时间戳已复制</source>
        <translation>时间戳已复制</translation>
    </message>
</context>
<context>
    <name>JsonFormatter</name>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="12"/>
        <source>JSON格式化</source>
        <translation>JSON格式化</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="13"/>
        <source>JSON格式化和压缩，支持语法高亮</source>
        <translation>JSON格式化和压缩，支持语法高亮</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="52"/>
        <source>输入JSON</source>
        <translation>输入JSON</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="60"/>
        <source>输入JSON，例如：{"name": "value", "array": [1, 2, 3]}</source>
        <translation>输入JSON，例如：{"name": "value", "array": [1, 2, 3]}</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="70"/>
        <source>格式化</source>
        <translation>格式化</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="75"/>
        <source>压缩</source>
        <translation>压缩</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="80"/>
        <source>清空</source>
        <translation>清空</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="94"/>
        <source>JSON语法正确</source>
        <translation>JSON语法正确</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="97"/>
        <source>JSON语法错误</source>
        <translation>JSON语法错误</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="101"/>
        <source>✓ 有效</source>
        <translation>✓ 有效</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="103"/>
        <source>✗ 无效</source>
        <translation>✗ 无效</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="117"/>
        <source>格式化结果</source>
        <translation>格式化结果</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="136"/>
        <source>复制结果</source>
        <translation>复制结果</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="141"/>
        <source>交换</source>
        <translation>交换</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="146"/>
        <source>示例</source>
        <translation>示例</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="154"/>
        <source>缩进：</source>
        <translation>缩进：</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="164"/>
        <source>空格</source>
        <translation>空格</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="185"/>
        <source>JSON错误：</source>
        <translation>JSON错误：</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="192"/>
        <source>位置：第</source>
        <translation>位置：第</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="192"/>
        <source>行，第</source>
        <translation>行，第</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="192"/>
        <source>列</source>
        <translation>列</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="203"/>
        <source>请先输入有效的JSON</source>
        <translation>请先输入有效的JSON</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="212"/>
        <source>JSON格式化完成</source>
        <translation>JSON格式化完成</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="216"/>
        <source>格式化错误：</source>
        <translation>格式化错误：</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="220"/>
        <source>格式化失败：</source>
        <translation>格式化失败：</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="232"/>
        <source>JSON压缩完成</source>
        <translation>JSON压缩完成</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="236"/>
        <source>压缩错误：</source>
        <translation>压缩错误：</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="240"/>
        <source>压缩失败：</source>
        <translation>压缩失败：</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="248"/>
        <source>JSON已复制到剪贴板</source>
        <translation>JSON已复制到剪贴板</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="258"/>
        <source>输入输出已交换</source>
        <translation>输入输出已交换</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="269"/>
        <source>已清空</source>
        <translation>已清空</translation>
    </message>
    <message>
        <location filename="../qml/tools/JsonFormatter.qml" line="313"/>
        <source>示例JSON已加载</source>
        <translation>示例JSON已加载</translation>
    </message>
</context>
</TS>
```

**Step 3: 创建翻译编译脚本**

创建`tools/translate.sh`：
```bash
#!/bin/bash
# translate.sh - 编译翻译文件

set -e

PLUGIN_DIR="plugins/developer-tools"
TRANSLATIONS_DIR="$PLUGIN_DIR/translations"

echo "Compiling translations..."

# 检查lrelease命令
if ! command -v lrelease &> /dev/null; then
    echo "Error: lrelease command not found. Install Qt Linguist tools."
    exit 1
fi

# 编译所有.ts文件
for ts_file in "$TRANSLATIONS_DIR"/*.ts; do
    if [ -f "$ts_file" ]; then
        qm_file="${ts_file%.ts}.qm"
        echo "Compiling $(basename "$ts_file")..."
        lrelease "$ts_file" -qm "$qm_file"

        if [ $? -eq 0 ]; then
            echo "  -> $(basename "$qm_file")"
        else
            echo "  Error compiling $(basename "$ts_file")"
            exit 1
        fi
    fi
done

echo "Translation compilation complete."
```

**Step 4: 设置执行权限并测试**

```bash
chmod +x tools/translate.sh
./tools/translate.sh
```
预期：显示编译成功信息（或提示需要安装Qt Linguist）

**Step 5: 提交更改**

---

## 阶段6：构建和测试

### Task 13: 创建构建和部署脚本

**Files:**
- Modify: `tools/build.sh` (添加翻译编译)
- Modify: `tools/deploy.sh` (添加验证)

**Step 1: 更新构建脚本**

编辑`tools/build.sh`，在文件末尾添加：
```bash
# 编译翻译文件
if [ -f "tools/translate.sh" ]; then
    echo "Compiling translations..."
    ./tools/translate.sh || echo "Warning: Translation compilation failed"
fi

echo "Build complete. Plugin in: $BUILD_DIR/developer-tools"
```

**Step 2: 更新部署脚本**

编辑`tools/deploy.sh`，在开头添加验证：
```bash
#!/bin/bash
# deploy.sh - 部署插件到Noctalia

set -e

PLUGIN_DIR="plugins/developer-tools"
NOCTALIA_PLUGINS="$HOME/.local/share/noctalia/plugins"

echo "Deploying Developer Tools plugin..."

# 验证必需文件
echo "Verifying required files..."
REQUIRED_FILES=(
    "$PLUGIN_DIR/manifest.json"
    "$PLUGIN_DIR/qml/main.qml"
    "$PLUGIN_DIR/qml/ToolButton.qml"
    "$PLUGIN_DIR/qml/components/Sidebar.qml"
    "$PLUGIN_DIR/qml/tools/TimestampTool.qml"
    "$PLUGIN_DIR/qml/tools/JsonFormatter.qml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: Missing required file: $file"
        exit 1
    fi
done

echo "All required files present."
```

**Step 3: 创建验证脚本**

创建`tools/verify.sh`：
```bash
#!/bin/bash
# verify.sh - 验证插件完整性

set -e

PLUGIN_DIR="plugins/developer-tools"

echo "Verifying Developer Tools plugin..."

# 检查目录结构
echo "1. Checking directory structure..."
REQUIRED_DIRS=(
    "$PLUGIN_DIR"
    "$PLUGIN_DIR/qml"
    "$PLUGIN_DIR/qml/tools"
    "$PLUGIN_DIR/qml/components"
    "$PLUGIN_DIR/translations"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "  ✗ Missing directory: $dir"
        exit 1
    else
        echo "  ✓ Found: $dir"
    fi
done

# 检查必需文件
echo "2. Checking required files..."
REQUIRED_FILES=(
    "$PLUGIN_DIR/manifest.json"
    "$PLUGIN_DIR/icon.svg"
    "$PLUGIN_DIR/qml/main.qml"
    "$PLUGIN_DIR/qml/ToolButton.qml"
    "$PLUGIN_DIR/qml/components/Theme.qml"
    "$PLUGIN_DIR/qml/components/Sidebar.qml"
    "$PLUGIN_DIR/qml/components/TextEditor.qml"
    "$PLUGIN_DIR/qml/tools/ToolBase.qml"
    "$PLUGIN_DIR/qml/tools/TimestampTool.qml"
    "$PLUGIN_DIR/qml/tools/JsonFormatter.qml"
    "$PLUGIN_DIR/translations/en_US.ts"
    "$PLUGIN_DIR/translations/zh_CN.ts"
)

missing_files=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ✗ Missing file: $file"
        missing_files=$((missing_files + 1))
    else
        echo "  ✓ Found: $(basename "$file")"
    fi
done

if [ $missing_files -gt 0 ]; then
    echo "  ⚠  Missing $missing_files required file(s)"
fi

# 检查manifest.json语法
echo "3. Checking manifest.json..."
if python3 -m json.tool "$PLUGIN_DIR/manifest.json" > /dev/null 2>&1; then
    echo "  ✓ manifest.json syntax is valid"
else
    echo "  ✗ manifest.json has syntax errors"
    exit 1
fi

# 检查文件大小（粗略验证）
echo "4. Checking file sizes..."
MIN_SIZE=10  # 最小文件大小（字节）

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        if [ $size -lt $MIN_SIZE ]; then
            echo "  ⚠  File is very small: $file ($size bytes)"
        fi
    fi
done

echo ""
echo "Verification complete."
if [ $missing_files -eq 0 ]; then
    echo "✅ Plugin structure looks good!"
else
    echo "⚠️  Plugin has $missing_files missing file(s)"
fi
```

**Step 4: 设置执行权限**

```bash
chmod +x tools/verify.sh tools/build.sh tools/deploy.sh tools/translate.sh
```

**Step 5: 运行验证**

```bash
./tools/verify.sh
```
预期：显示所有文件检查通过

**Step 6: 提交更改**

---

### Task 14: 创建README和文档

**Files:**
- Modify: `plugins/developer-tools/README.md`
- Create: `plugins/developer-tools/USAGE.md`

**Step 1: 完善README.md**

```markdown
# Noctalia开发者工具插件

为Noctalia Shell提供的开发者工具集合插件。

## 功能特性

### 🛠️ 核心工具
1. **时间戳转换工具**
   - 时间戳 ↔ 日期时间双向转换
   - 支持Unix秒/毫秒格式
   - 系统时区/UTC切换
   - 实时当前时间显示
   - 一键复制功能

2. **JSON格式化工具**
   - JSON格式化与压缩
   - 语法高亮显示
   - 实时语法检查
   - 错误定位提示
   - 示例JSON快速加载

### 🎨 用户界面
- 侧边栏导航设计
- 响应式布局
- 亮色/暗色主题支持
- 窗口位置记忆
- 工具选择记忆

### 🌐 国际化
- 中文（简体）支持
- 英文支持
- 系统语言自动检测

## 安装与使用

### 安装方法
1. **构建插件**：
   ```bash
   ./tools/build.sh
   ```

2. **部署到Noctalia**：
   ```bash
   ./tools/deploy.sh
   ```

3. **重启Noctalia Shell**加载插件

### 使用方法
1. 在状态栏找到🛠️图标
2. 点击图标打开开发者工具窗口
3. 使用侧边栏切换不同工具
4. 开始使用时间戳转换或JSON格式化功能

## 开发与构建

### 项目结构
```
developer-tools/
├── qml/                    # QML源代码
│   ├── main.qml           # 主界面
│   ├── ToolButton.qml     # 状态栏按钮
│   ├── components/        # 通用组件
│   └── tools/            # 工具实现
├── translations/          # 国际化文件
├── manifest.json          # 插件配置
└── icon.svg              # 插件图标
```

### 构建命令
```bash
# 验证插件结构
./tools/verify.sh

# 编译翻译文件
./tools/translate.sh

# 完整构建
./tools/build.sh

# 部署到Noctalia
./tools/deploy.sh
```

### 添加新工具
1. 在`qml/tools/`目录创建新的QML工具文件
2. 继承`ToolBase.qml`基类
3. 在`Sidebar.qml`的`toolModel`中添加工具信息
4. 更新翻译文件

## 技术要求
- Noctalia Shell v0.2+
- Qt 5.15+ / Qt 6.0+
- Qt Quick Controls 2

## 许可证
MIT License

## 作者
Forty - [fortystory](https://github.com/fortystory)
```

**Step 2: 创建使用指南**

创建`plugins/developer-tools/USAGE.md`：
```markdown
# 开发者工具插件使用指南

## 快速开始

### 1. 打开开发者工具
- 在Noctalia状态栏找到**🛠️工具图标**
- 点击图标打开开发者工具窗口
- 或使用快捷键 **Ctrl+Shift+D**

### 2. 切换工具
- 左侧侧边栏显示可用工具列表
- 点击工具图标切换到相应工具
- 当前选中工具会高亮显示

## 时间戳转换工具

### 功能说明
将时间戳（Unix时间）转换为人类可读的日期时间，或反向转换。

### 使用方法
1. **时间戳 → 日期时间**：
   - 在上方输入框中输入时间戳（秒或毫秒）
   - 选择时间戳格式（Unix秒、Unix毫秒等）
   - 结果自动显示在下方

2. **日期时间 → 时间戳**：
   - 在下方输入框中输入日期时间
   - 格式示例：`2026-02-06 14:30:00`
   - 对应的时间戳自动计算显示

3. **常用操作**：
   - **现在**按钮：填充当前时间戳/日期时间
   - **使用UTC**：切换时区显示
   - **毫秒精度**：切换时间戳精度
   - **复制**按钮：复制转换结果

### 示例
- 输入 `1700000000` → 转换为 `2023-11-14 22:13:20`
- 输入 `2026-02-06 10:30:00` → 转换为 `1760000000`

## JSON格式化工具

### 功能说明
格式化JSON字符串，使其更易读，或压缩JSON以减少体积。

### 使用方法
1. **输入JSON**：
   - 在上方编辑器中输入或粘贴JSON
   - 实时语法检查，错误会高亮显示
   - 右侧状态指示器显示JSON有效性

2. **格式化操作**：
   - **格式化**按钮：使用2空格缩进美化JSON
   - **压缩**按钮：移除所有空格和换行
   - **清空**按钮：清空输入和输出

3. **结果处理**：
   - 格式化结果显示在下方编辑器
   - **复制结果**：复制格式化后的JSON
   - **交换**：将输出交换到输入区
   - **示例**：加载示例JSON

### 缩进设置
- 可在底部调整缩进空格数（2/4/8）
- 更改后自动重新格式化

### 示例JSON
插件内置示例JSON展示完整功能：
```json
{
  "app": "Noctalia Developer Tools",
  "version": "1.0.0",
  "features": ["Timestamp Converter", "JSON Formatter"],
  "author": {
    "name": "Forty",
    "email": "dev@example.com"
  }
}
```

## 通用功能

### 复制功能
- 所有工具都提供**复制按钮**
- 点击复制当前结果到剪贴板
- 成功复制会有提示信息

### 主题适配
- 自动适配系统亮色/暗色主题
- 使用Noctalia系统颜色
- 统一的视觉风格

### 窗口控制
- 拖拽标题栏移动窗口
- 点击❌关闭窗口
- 点击外部区域关闭窗口
- 窗口位置和大小自动记忆

## 快捷键
- **Ctrl+Shift+D**：打开/关闭开发者工具
- **Ctrl+C**：在编辑器中复制选中文本
- **Ctrl+V**：在编辑器中粘贴文本
- **Ctrl+A**：全选编辑器内容

## 故障排除

### 常见问题
1. **插件不显示**：
   - 检查是否已部署到正确目录
   - 重启Noctalia Shell
   - 查看Noctalia日志

2. **复制功能失效**：
   - 需要Noctalia API支持
   - 检查插件权限配置

3. **JSON解析错误**：
   - 检查JSON语法是否正确
   - 使用示例JSON测试功能

### 获取帮助
如遇问题，请检查：
1. Noctalia Shell版本是否支持
2. 插件文件是否完整
3. 系统日志中的错误信息

---

*最后更新：2026-02-06*
```

**Step 3: 运行最终验证**

```bash
./tools/verify.sh
```
预期：所有检查通过

**Step 4: 提交所有更改**

---

## 总结

实施计划完成。计划包含12个主要任务，分为6个阶段：

### 阶段1：基础设施设置（任务1-3）
- 项目目录结构创建
- 插件manifest配置
- 构建和部署工具

### 阶段2：核心QML组件（任务4-6）
- 工具基类和主题定义
- 文本编辑器组件
- 通用工具函数

### 阶段3：主界面组件（任务7-9）
- 状态栏按钮组件
- 侧边栏导航组件
- 主窗口界面

### 阶段4：工具实现（任务10-11）
- 时间戳转换工具
- JSON格式化工具

### 阶段5：国际化支持（任务12）
- 中英文翻译文件
- 翻译编译脚本

### 阶段6：构建和测试（任务13-14）
- 构建和部署脚本完善
- 验证脚本创建
- 文档编写

---

**计划完成并保存到 `docs/plans/2026-02-06-developer-tools-plugin-implementation.md`**

现在有两个执行选项：

**1. 子代理驱动开发（当前会话）** - 我派遣新子代理执行每个任务，任务间进行代码审查，快速迭代

**2. 并行会话（独立）** - 在新的工作树中打开新会话，使用executing-plans技能，批量执行并设置检查点

**你希望使用哪种方法？**