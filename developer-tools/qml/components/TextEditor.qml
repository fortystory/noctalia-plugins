// TextEditor.qml - 可重用的代码和文本编辑器组件
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

FocusScope {
    id: textEditorRoot

    // 公共属性
    property alias text: textArea.text
    property string placeholderText: ""
    property bool readOnly: false
    property bool showLineNumbers: true
    property string language: "text"  // "text", "json", "javascript", "xml", "html", "css"
    property int fontSize: theme.fontSizeNormal
    property color textColor: theme.textColor
    property color backgroundColor: theme.backgroundColor
    property color borderColor: theme.borderColor
    property color lineNumberColor: Qt.darker(backgroundColor, 1.2)
    property color lineNumberTextColor: Qt.darker(textColor, 1.5)

    // 主题引用
    property var theme: Theme {}

    // 信号定义
    signal textChanged()
    signal focusChanged(bool hasFocus)
    signal copyRequested()
    signal pasteRequested()

    // 内部属性
    property int _lineCount: 1
    property int _currentLine: 1
    property int _currentColumn: 1
    property real _lineHeight: fontSize * _lineHeightMultiplier  // 估计的行高，随字体大小变化

    // 常量定义
    readonly property int _digitWidth: 8                     // 行号中每个数字的宽度（像素）
    readonly property int _lineNumberMinDigits: 3           // 行号最小位数
    readonly property int _lineNumberMargin: 20             // 行号区域右边距
    readonly property real _lineHeightMultiplier: 1.5       // 行高相对于字体大小的倍数
    readonly property int _scrollBarSize: 8                 // 滚动条宽度/高度
    readonly property int _statusBarHeight: 20              // 状态栏高度
    readonly property int _statusBarMargin: 5               // 状态栏内边距
    readonly property int _lineNumberRightMargin: 5         // 行号文本右边距
    readonly property int _cursorWidth: 2                   // 光标宽度
    readonly property int _cursorAnimationDuration: 800     // 光标闪烁动画时长（毫秒）

    // 滚动条常量
    readonly property int _scrollBarThumbLength: 100        // 滚动条滑块长度
    readonly property real _scrollBarPressedOpacity: 0.9    // 滚动条按下时的不透明度
    readonly property real _scrollBarHoveredOpacity: 0.7    // 滚动条悬停时的不透明度
    readonly property real _scrollBarNormalOpacity: 0.5     // 滚动条正常状态的不透明度
    readonly property real _scrollBarBackgroundDarkenFactor: 1.1  // 滚动条背景变暗因子

    // 阴影效果常量
    readonly property int _shadowHorizontalOffset: 0
    readonly property int _shadowVerticalOffset: 2
    readonly property int _shadowSamples: 17
    readonly property real _shadowSpread: 0.3

    // 尺寸计算
    property int lineNumberWidth: showLineNumbers ? (Math.max(_lineNumberMinDigits, _lineCount.toString().length) * _digitWidth + _lineNumberMargin) : 0
    property int padding: 10

    // 计算文本行数的高效函数（避免创建字符串数组）
    function calculateLineCount(text) {
        if (!text || text.length === 0) return 1
        var count = 1
        for (var i = 0; i < text.length; i++) {
            if (text.charAt(i) === '\n') {
                count++
            }
        }
        return count
    }

    // 文本区域内容宽度
    property real contentWidth: textArea.contentWidth
    property real contentHeight: textArea.contentHeight


    // 主布局
    Rectangle {
        id: editorContainer
        anchors.fill: parent
        color: backgroundColor
        border.width: theme.borderWidth
        border.color: borderColor
        radius: theme.borderRadius

        // 内部阴影效果
        layer.enabled: true
        layer.effect: InnerShadow {
            horizontalOffset: _shadowHorizontalOffset
            verticalOffset: _shadowVerticalOffset
            radius: theme.shadowRadius
            samples: _shadowSamples
            color: theme.shadowColorTransparent
            spread: _shadowSpread
        }

        // 行号区域
        // 使用ListView实现行号显示，相比Rectangle+Flickable+Text方案有以下优点：
        // 1. 更好的性能（虚拟化、重用）
        // 2. 自动处理滚动同步
        // 3. 简化代码结构
        Rectangle {
            id: lineNumberArea
            visible: showLineNumbers
            width: lineNumberWidth
            height: parent.height
            color: lineNumberColor
            border.width: 0

            // 行号列表 - 使用ListView实现高效的行号渲染
            ListView {
                id: lineNumberView
                anchors.fill: parent
                model: _lineCount
                interactive: false
                clip: true

                delegate: Rectangle {
                    width: lineNumberWidth
                    height: _lineHeight
                    color: lineNumberColor

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: _lineNumberRightMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: index + 1
                        font.pointSize: fontSize
                        font.family: theme.fontFamily
                        color: lineNumberTextColor
                        opacity: (index + 1 === _currentLine) ? 1.0 : 0.7
                    }
                }

            }
        }

        // 滚动区域
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

            boundsBehavior: Flickable.StopAtBounds

            // 同步行号区域滚动
            onContentYChanged: {
                if (lineNumberView.contentY !== contentY) {
                    lineNumberView.contentY = contentY
                }
            }

            // 文本编辑区域
            TextArea {
                id: textArea
                width: Math.max(flickable.width, contentWidth + 2 * padding)
                height: Math.max(flickable.height, contentHeight + 2 * padding)
                anchors.top: parent.top
                anchors.left: parent.left

                // 文本编辑属性
                font.pointSize: fontSize
                font.family: theme.fontFamily
                color: textColor
                selectionColor: Qt.rgba(theme.primaryColor.r, theme.primaryColor.g, theme.primaryColor.b, 0.3)
                selectedTextColor: textColor
                wrapMode: TextArea.Wrap
                readOnly: textEditorRoot.readOnly
                placeholderText: textEditorRoot.placeholderText
                placeholderTextColor: Qt.darker(textColor, 1.8)

                // 填充
                leftPadding: padding
                rightPadding: padding
                topPadding: padding
                bottomPadding: padding

                // 背景透明（由外部容器提供）
                background: null

                // 光标颜色
                cursorDelegate: Rectangle {
                    width: _cursorWidth
                    color: theme.primaryColor
                    visible: parent.activeFocus

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.0; duration: _cursorAnimationDuration }
                        NumberAnimation { from: 0.0; to: 1.0; duration: _cursorAnimationDuration }
                    }
                }

                // 文本变化处理
                onTextChanged: {
                    // 更新行数
                    var lines = calculateLineCount(text)
                    if (lines !== _lineCount) {
                        _lineCount = lines
                    }

                    // 触发信号
                    textEditorRoot.textChanged()

                    // 自动滚动到底部（如果光标在最后）
                    if (cursorPosition === text.length) {
                        flickable.contentY = contentHeight - flickable.height + 2 * padding
                    }
                }

                // 光标位置变化
                onCursorPositionChanged: {
                    // 计算当前行和列
                    var textBeforeCursor = text.substring(0, cursorPosition)
                    var lines = textBeforeCursor.split("\n")
                    _currentLine = lines.length
                    _currentColumn = lines[lines.length - 1].length + 1

                    // 确保当前行可见
                    ensureVisible(_currentLine)
                }

                // 焦点变化
                onActiveFocusChanged: {
                    textEditorRoot.focusChanged(activeFocus)
                }

                // 右键菜单
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.popup()
                        }
                    }
                }

                // 确保指定行可见
                function ensureVisible(lineNumber) {
                    var lineY = (lineNumber - 1) * _lineHeight
                    if (lineY < flickable.contentY) {
                        flickable.contentY = lineY
                    } else if (lineY + _lineHeight > flickable.contentY + flickable.height) {
                        flickable.contentY = lineY + _lineHeight - flickable.height
                    }
                }
            }

            // 滚动条
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                width: _scrollBarSize
                active: true

                background: Rectangle {
                    color: Qt.darker(editorContainer.color, _scrollBarBackgroundDarkenFactor)
                    radius: width / 2
                }

                contentItem: Rectangle {
                    implicitWidth: _scrollBarSize
                    implicitHeight: _scrollBarThumbLength
                    radius: width / 2
                    color: theme.primaryColor
                    opacity: parent.pressed ? _scrollBarPressedOpacity : (parent.hovered ? _scrollBarHoveredOpacity : _scrollBarNormalOpacity)
                }
            }

            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
                height: _scrollBarSize
                active: true

                background: Rectangle {
                    color: Qt.darker(editorContainer.color, _scrollBarBackgroundDarkenFactor)
                    radius: height / 2
                }

                contentItem: Rectangle {
                    implicitWidth: _scrollBarThumbLength
                    implicitHeight: _scrollBarSize
                    radius: height / 2
                    color: theme.primaryColor
                    opacity: parent.pressed ? _scrollBarPressedOpacity : (parent.hovered ? _scrollBarHoveredOpacity : _scrollBarNormalOpacity)
                }
            }
        }

        // 占位文本（当内容为空且没有焦点时显示）
        Text {
            id: placeholder
            anchors.left: lineNumberArea.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: padding + 1
            anchors.rightMargin: padding
            anchors.topMargin: padding
            text: placeholderText
            font: textArea.font
            color: textArea.placeholderTextColor
            visible: textArea.text === "" && !textArea.activeFocus && placeholderText !== ""
            wrapMode: Text.Wrap
        }

        // 状态指示器（显示当前行/列）
        Rectangle {
            id: statusBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: _statusBarHeight
            color: Qt.darker(backgroundColor, 1.05)
            border.width: 0
            visible: textArea.activeFocus

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: _statusBarMargin
                anchors.rightMargin: _statusBarMargin
                spacing: 10

                Text {
                    text: qsTr("行: %1, 列: %2").arg(_currentLine).arg(_currentColumn)
                    font.pointSize: fontSize - 2
                    color: Qt.darker(textColor, 1.5)
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("字数: %1").arg(textArea.text.length)
                    font.pointSize: fontSize - 2
                    color: Qt.darker(textColor, 1.5)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    // 右键菜单
    Menu {
        id: contextMenu

        MenuItem {
            text: qsTr("复制")
            icon.source: "qrc:/icons/copy.svg"
            enabled: textArea.selectedText !== ""
            onTriggered: {
                copyRequested()
                textArea.copy()
            }
        }

        MenuItem {
            text: qsTr("粘贴")
            icon.source: "qrc:/icons/paste.svg"
            enabled: !readOnly
            onTriggered: {
                pasteRequested()
                textArea.paste()
            }
        }

        MenuItem {
            text: qsTr("剪切")
            icon.source: "qrc:/icons/cut.svg"
            enabled: textArea.selectedText !== "" && !readOnly
            onTriggered: {
                textArea.cut()
            }
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("全选")
            icon.source: "qrc:/icons/select-all.svg"
            onTriggered: {
                selectAll()
            }
        }

        MenuItem {
            text: qsTr("清空")
            icon.source: "qrc:/icons/clear.svg"
            enabled: !readOnly
            onTriggered: {
                clear()
            }
        }

        MenuSeparator {}

        MenuItem {
            text: qsTr("查找")
            icon.source: "qrc:/icons/search.svg"
            onTriggered: {
                // 查找功能占位
                console.log("Find functionality not implemented yet")
            }
        }
    }

    // 公共方法实现
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

    function cut() {
        if (!readOnly) {
            textArea.cut()
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

    function insertText(newText) {
        if (!readOnly) {
            textArea.insert(textArea.cursorPosition, newText)
        }
    }

    function getSelectedText() {
        return textArea.selectedText
    }

    function hasSelection() {
        return textArea.selectedText !== ""
    }

    // 语法高亮设置（占位实现）
    // 注意：这是一个简化版本，实际需要更复杂的实现
    // 完整的语法高亮通常需要：
    // 1. 自定义TextArea的textDocument属性
    // 2. 使用QSyntaxHighlighter或自定义高亮器
    // 3. 为不同语言定义高亮规则（关键字、字符串、注释等）
    // 4. 处理多行注释和嵌套语法
    function setupSyntaxHighlighting() {
        // 根据语言设置不同的高亮规则
        switch(language) {
            case "json":
                textArea.textFormat = TextEdit.PlainText
                // JSON语法高亮占位：实际应使用高亮器解析大括号、引号、关键字等
                console.log("JSON syntax highlighting placeholder - needs proper implementation")
                break
            case "javascript":
                textArea.textFormat = TextEdit.PlainText
                // JavaScript语法高亮占位：实际应处理函数、变量、关键字等
                console.log("JavaScript syntax highlighting placeholder - needs proper implementation")
                break
            case "xml":
            case "html":
                textArea.textFormat = TextEdit.PlainText
                // XML/HTML语法高亮占位：实际应处理标签、属性等
                console.log("XML/HTML syntax highlighting placeholder - needs proper implementation")
                break
            case "css":
                textArea.textFormat = TextEdit.PlainText
                // CSS语法高亮占位：实际应处理选择器、属性、值等
                console.log("CSS syntax highlighting placeholder - needs proper implementation")
                break
            default:
                textArea.textFormat = TextEdit.PlainText
                // 纯文本模式，无语法高亮
        }

        // 标记需要后续实现
        // TODO: 实现完整的语法高亮功能
        // TODO: 集成QSyntaxHighlighter或类似方案
    }

    // 初始化
    Component.onCompleted: {
        // 初始化行数
        _lineCount = calculateLineCount(textArea.text)

        // 设置语法高亮
        setupSyntaxHighlighting()
    }

    // 语言变化时更新语法高亮
    onLanguageChanged: {
        setupSyntaxHighlighting()
    }
}