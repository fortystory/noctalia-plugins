// TimestampTool.qml - 时间戳转换工具
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.System

Item {
    id: root

    // 时间戳转换函数
    function parseDateString(dateStr) {
        // 处理 YYYYMMDDHHiiss 格式（无分隔符）
        var compactRegex = /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/
        var match = dateStr.match(compactRegex)
        if (match) {
            var date = new Date(
                parseInt(match[1]),
                parseInt(match[2]) - 1,
                parseInt(match[3]),
                parseInt(match[4]),
                parseInt(match[5]),
                parseInt(match[6])
            )
            if (!isNaN(date.getTime())) {
                return date
            }
        }

        // 尝试 ISO 格式（YYYY-MM-DDTHH:mm:ss）
        var isoStr = dateStr.replace(/[-:]/g, 'T')
        var date = new Date(isoStr)
        if (!isNaN(date.getTime())) {
            return date
        }

        // 尝试标准日期解析
        date = new Date(dateStr)
        if (!isNaN(date.getTime())) {
            return date
        }

        return null
    }

    function updateFromSeconds(seconds) {
        var ts = parseInt(seconds)
        if (!isNaN(ts)) {
            var date = new Date(ts * 1000)
            // 使用本地时区格式
            var dateStr = date.toLocaleString(Qt.locale(), "yyyy-MM-dd HH:mm:ss")
            var msStr = (ts * 1000).toString()
            // 直接设置输入框的 text 属性
            dateInput.text = dateStr
            millisecondsInput.text = msStr
            Logger.i("Timestamp", "转换成功: " + seconds + " -> " + dateStr)
        } else {
            Logger.w("Timestamp", "无效的秒时间戳: " + seconds)
        }
    }

    function updateFromMilliseconds(ms) {
        var ts = parseInt(ms)
        if (!isNaN(ts)) {
            var date = new Date(ts)
            // 使用本地时区格式
            var dateStr = date.toLocaleString(Qt.locale(), "yyyy-MM-dd HH:mm:ss")
            var secStr = Math.floor(ts / 1000).toString()
            // 直接设置输入框的 text 属性
            dateInput.text = dateStr
            secondsInput.text = secStr
            Logger.i("Timestamp", "转换成功: " + ms + " -> " + dateStr)
        } else {
            Logger.w("Timestamp", "无效的毫秒时间戳: " + ms)
        }
    }

    function updateFromDate(dateStr) {
        var date = parseDateString(dateStr)
        if (date) {
            var ts = date.getTime()
            var secStr = Math.floor(ts / 1000).toString()
            var msStr = ts.toString()
            // 直接设置输入框的 text 属性
            secondsInput.text = secStr
            millisecondsInput.text = msStr
            Logger.i("Timestamp", "转换成功: " + dateStr + " -> " + secStr)
        } else {
            Logger.w("Timestamp", "无效的日期格式: " + dateStr)
        }
    }

    function copyToClipboard(text) {
        var escaped = text.replace(/'/g, "'\\''")
        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s' '" + escaped + "' | wl-copy"
        ])
        Logger.i("Timestamp", "已复制到剪贴板")
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Style.marginM
        }
        spacing: Style.marginM

        // 标题
        NText {
            text: qsTr("时间戳转换")
            font.pointSize: Style.fontSizeL
            font.weight: Font.Medium
            color: Color.mOnSurface
        }

        // 秒时间戳
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NTextInput {
                id: secondsInput
                Layout.fillWidth: true
                placeholderText: qsTr("秒时间戳")
            }

            NIconButton {
                icon: "copy"
                onClicked: {
                    root.copyToClipboard(secondsInput.text)
                }
            }
        }

        // 毫秒时间戳
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NTextInput {
                id: millisecondsInput
                Layout.fillWidth: true
                placeholderText: qsTr("毫秒时间戳")
            }

            NIconButton {
                icon: "copy"
                onClicked: {
                    root.copyToClipboard(millisecondsInput.text)
                }
            }
        }

        // 日期字符串
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NTextInput {
                id: dateInput
                Layout.fillWidth: true
                placeholderText: qsTr("YYYY-MM-DD HH:mm:ss")
            }

            NIconButton {
                icon: "copy"
                onClicked: {
                    root.copyToClipboard(dateInput.text)
                }
            }
        }

        // 转换按钮
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
                text: qsTr("转换")
                icon: "refresh"
                onClicked: {
                    // 尝试所有三个输入框，优先使用秒时间戳
                    if (secondsInput.text.trim() !== "") {
                        root.updateFromSeconds(secondsInput.text)
                    } else if (millisecondsInput.text.trim() !== "") {
                        root.updateFromMilliseconds(millisecondsInput.text)
                    } else if (dateInput.text.trim() !== "") {
                        root.updateFromDate(dateInput.text)
                    } else {
                        Logger.w("Timestamp", "请输入时间戳或日期")
                    }
                }
            }

            NButton {
                text: qsTr("当前时间")
                icon: "clock"
                onClicked: {
                    var now = Date.now()
                    secondsInput.text = Math.floor(now / 1000).toString()
                    millisecondsInput.text = now.toString()
                    dateInput.text = new Date(now).toLocaleString(Qt.locale(), "yyyy-MM-dd HH:mm:ss")
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // 提示
        NText {
            text: qsTr("支持格式: YYYY-MM-DD HH:mm:ss, YYYYMMDDHHiiss")
            font.pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
