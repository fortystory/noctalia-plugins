// TimestampTool.qml - 时间戳与时间字符串转换工具
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ToolBase {
    id: timestampTool

    // 时间戳格式枚举
    enum TimestampFormat {
        UnixSeconds = 0,
        UnixMilliseconds = 1,
        ISO8601 = 2,
        RFC3339 = 3
    }

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
    property int timestampFormat: TimestampFormat.UnixSeconds // 使用枚举值

    // 时间格式选项
    property var timeFormats: [
        qsTr("Unix时间戳（秒）"),
        qsTr("Unix时间戳（毫秒）"),
        qsTr("ISO 8601"),
        qsTr("RFC 3339")
    ]

    // 定时器用于更新当前时间
    Timer {
        interval: 5000
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
                        onClicked: {
                            useUTC = !useUTC
                            updateCurrentTime()
                            convertTimestamp()
                            convertDateTime()
                        }
                    }

                    CheckBox {
                        text: qsTr("毫秒精度")
                        checked: useMilliseconds
                        onClicked: {
                            useMilliseconds = !useMilliseconds
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

    // 辅助函数：解析时间戳字符串
    function parseTimestampString(input) {
        var timestamp = parseInt(input)
        if (isNaN(timestamp)) {
            throw new Error(qsTr("时间戳必须是数字"))
        }
        return timestamp
    }

    // 辅助函数：根据格式将时间戳转换为Date对象
    function timestampToDate(timestamp, format) {
        switch(format) {
            case TimestampFormat.UnixSeconds: // Unix秒
                return new Date(timestamp * 1000)
            case TimestampFormat.UnixMilliseconds: // Unix毫秒
            case TimestampFormat.ISO8601: // ISO 8601 (直接使用)
            case TimestampFormat.RFC3339: // RFC 3339 (直接使用)
                return new Date(timestamp)
            default:
                return new Date(timestamp * 1000)
        }
    }

    // 辅助函数：格式化日期输出
    function formatDateOutput(date, timestamp, useUTC) {
        var result
        if (useUTC) {
            result = date.toUTCString()
        } else {
            result = date.toLocaleString()
        }
        result += "\n" + qsTr("原始值：") + timestamp
        return result
    }

    // 工具方法：转换时间戳
    function convertTimestamp() {
        if (!inputTimestamp || inputTimestamp.trim() === "") {
            outputResult = ""
            return
        }

        // 验证输入
        if (!validateInput(inputTimestamp)) {
            outputResult = qsTr("错误：无效的输入")
            showMessage(qsTr("输入格式无效"), "error")
            return
        }

        try {
            // 使用辅助函数解析和转换时间戳
            var timestamp = parseTimestampString(inputTimestamp)
            var date = timestampToDate(timestamp, timestampFormat)

            if (isNaN(date.getTime())) {
                outputResult = qsTr("错误：无效的日期")
                showMessage(qsTr("无法解析时间戳"), "error")
                return
            }

            // 使用辅助函数格式化输出
            outputResult = formatDateOutput(date, timestamp, useUTC)

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

        // 验证输入
        if (!validateInput(inputDateTime)) {
            timestampResultText.text = qsTr("错误：无效的输入")
            showMessage(qsTr("输入格式无效"), "error")
            return
        }

        try {
            // 使用增强的日期解析函数
            var date = parseDateTime(inputDateTime, useUTC)

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

    // 通用复制函数
    function copyText(text, successMessage) {
        if (text && text.trim() !== "") {
            copyToClipboard(text)
            showMessage(successMessage, "success")
        }
    }

    // 工具方法：复制当前时间
    function copyCurrentTime() {
        var text = currentTime.split(" (")[0] // 移除时间戳部分
        copyText(text, qsTr("当前时间已复制"))
    }

    // 工具方法：复制时间戳转换结果
    function copyTimestampResult() {
        if (outputResult) {
            var lines = outputResult.split("\n")
            copyText(lines[0], qsTr("转换结果已复制")) // 只复制日期时间部分
        }
    }

    // 工具方法：复制日期时间转换结果
    function copyDateTimeResult() {
        if (timestampResultText.text && timestampResultText.text !== qsTr("等待输入...")) {
            var text = timestampResultText.text.split(" ")[0] // 只取数字部分
            copyText(text, qsTr("时间戳已复制"))
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

    // 日期时间解析函数（支持UTC）
    function parseDateTime(input, useUTC) {
        if (!input || input.trim() === "") {
            return new Date(NaN)
        }

        var date
        var parsed = false

        // 尝试直接解析
        date = new Date(input)
        if (!isNaN(date.getTime())) {
            parsed = true
        }

        // 如果使用UTC但解析失败，尝试添加UTC后缀
        if (useUTC && !parsed) {
            date = new Date(input + " UTC")
            if (!isNaN(date.getTime())) {
                parsed = true
            }
        }

        // 如果仍然失败，尝试ISO格式解析（包含Z时区）
        if (!parsed) {
            // 检查是否已经是ISO格式（包含Z）
            if (input.indexOf('Z') === -1 && useUTC) {
                // 尝试添加Z后缀表示UTC
                date = new Date(input + 'Z')
                if (!isNaN(date.getTime())) {
                    parsed = true
                }
            }
        }

        // 如果仍然失败，尝试Date.parse
        if (!parsed) {
            var timestamp = Date.parse(input)
            if (!isNaN(timestamp)) {
                date = new Date(timestamp)
                parsed = true
            }
        }

        // 如果解析成功但需要UTC，确保日期对象是UTC时间
        if (parsed && useUTC) {
            // 创建UTC时间表示
            date = new Date(Date.UTC(
                date.getUTCFullYear(),
                date.getUTCMonth(),
                date.getUTCDate(),
                date.getUTCHours(),
                date.getUTCMinutes(),
                date.getUTCSeconds(),
                date.getUTCMilliseconds()
            ))
        }

        return parsed ? date : new Date(NaN)
    }

    // 组件加载完成
    Component.onCompleted: {
        console.log("Timestamp tool component loaded")
    }
}