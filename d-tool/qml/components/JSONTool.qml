// JSONTool.qml - JSON 格式化/压缩工具
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQml.Models
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.System

Item {
    id: root

    // 使用 QML 内置 JSON 处理
    function formatJSON() {
        try {
            var obj = JSON.parse(jsonTextArea.text)
            return JSON.stringify(obj, null, 2)
        } catch (e) {
            return ""
        }
    }

    function minifyJSON() {
        try {
            var obj = JSON.parse(jsonTextArea.text)
            return JSON.stringify(obj)
        } catch (e) {
            return ""
        }
    }

    function copyToClipboard(text) {
        var escaped = text.replace(/'/g, "'\\''")
        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s' '" + escaped + "' | wl-copy"
        ])
        Logger.i("JSON", "已复制到剪贴板")
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Style.marginM
        }
        spacing: Style.marginM

        // 标题
        NText {
            text: qsTr("JSON 工具")
            font.pointSize: Style.fontSizeL
            font.weight: Font.Medium
            color: Color.mOnSurface
        }

        // JSON 编辑区
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Style.radiusS
            color: Color.mSurface
            border.color: Color.mOutline
            border.width: Style.borderS

            Flickable {
                id: flickable
                anchors.fill: parent
                contentWidth: jsonTextArea.contentWidth
                contentHeight: jsonTextArea.contentHeight
                clip: true
                interactive: true

                TextArea {
                    id: jsonTextArea
                    width: flickable.width
                    height: Math.max(flickable.height, implicitHeight)
                    color: Color.mOnSurface
                    font.family: "monospace"
                    font.pointSize: Style.fontSizeS
                    wrapMode: TextArea.Wrap
                    background: Rectangle {
                        color: "transparent"
                    }
                    padding: Style.marginS
                }
            }

            // 滚动条
            ScrollBar {
                orientation: Qt.Vertical
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 12
            }
        }

        // 功能按钮行
        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NButton {
                text: qsTr("格式化")
                icon: "align-left"
                onClicked: {
                    var formatted = root.formatJSON()
                    if (formatted) {
                        jsonTextArea.text = formatted
                        Logger.i("JSON", "格式化成功")
                    } else {
                        Logger.e("JSON", "JSON 格式错误")
                    }
                }
            }

            NButton {
                text: qsTr("压缩")
                icon: "minus"
                onClicked: {
                    var minified = root.minifyJSON()
                    if (minified) {
                        jsonTextArea.text = minified
                        Logger.i("JSON", "压缩成功")
                    } else {
                        Logger.e("JSON", "JSON 格式错误")
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            NButton {
                text: qsTr("复制结果")
                icon: "copy"
                onClicked: {
                    root.copyToClipboard(jsonTextArea.text)
                }
            }
        }

        // 验证状态
        RowLayout {
            NText {
                text: qsTr("状态: ")
                font.pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
            }

            NText {
                id: validationMessage
                text: ""
                font.pointSize: Style.fontSizeS
            }
        }
    }
}
