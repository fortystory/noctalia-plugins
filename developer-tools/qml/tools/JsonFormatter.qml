// JsonFormatter.qml - JSON格式化与压缩工具
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components" as Components

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

    // 防抖定时器，用于延迟验证以避免频繁调用
    property Timer debounceTimer: Timer {
        interval: 300 // 300毫秒延迟
        running: false
        repeat: false
        onTriggered: validateJson()
    }

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
                Components.TextEditor {
                    id: inputEditor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: qsTr('输入JSON，例如：{"name": "value", "array": [1, 2, 3]}')
                    language: "json"
                    fontSize: theme.fontSizeNormal
                    text: inputJson  // 绑定到inputJson属性

                    onTextChanged: {
                        // 只有当文本实际变化时才更新inputJson（避免循环）
                        if (text !== inputJson) {
                            inputJson = text
                        }
                        // 重置防抖定时器，延迟验证
                        debounceTimer.restart()
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
                Components.TextEditor {
                    id: outputEditor
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readOnly: true
                    language: "json"
                    fontSize: theme.fontSizeNormal
                    text: outputJson

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
                                // 不再自动格式化，用户需要手动点击"格式化"按钮
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
                var location = getLineAndColumn(inputJson, position)
                errorMessage += "\n" + qsTr("位置：第") + location.line + qsTr("行，第") + location.column + qsTr("列")
            }
        }
    }

    // 辅助函数：计算文本中指定位置的行和列（优化版本，避免创建子字符串）
    function getLineAndColumn(text, position) {
        if (!text || position < 0 || position > text.length) {
            return { line: 1, column: 1 }
        }

        var line = 1
        var column = 1
        for (var i = 0; i < position; i++) {
            if (text.charAt(i) === '\n') {
                line++
                column = 1
            } else {
                column++
            }
        }
        return { line: line, column: column }
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
        // 停止任何待处理的防抖定时器并立即验证
        debounceTimer.stop()
        validateJson()

        if (isValidJson) {
            formatJson()
            showMessage(qsTr("示例JSON已加载"), "success")
        }
    }




    // 组件加载完成
    Component.onCompleted: {
        console.log("JSON formatter component loaded")
    }
}