// Panel.qml - Command Output Panel
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.System
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property var screen

    readonly property var cfg: pluginApi?.pluginSettings || ({})

    anchors.fill: parent

    readonly property int updateInterval: cfg.updateInterval ?? 60
    property bool isUpdating: false
    property int currentCommandIndex: -1
    property var commandResults: []

    // 共享的 Process 组件
    Process {
        id: process
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function(exitCode) {
            var cmd = root.cfg.commands[root.currentCommandIndex];
            var result = {
                name: cmd?.name || "Unknown",
                command: cmd?.command || "",
                output: stdout.text,
                success: exitCode === 0
            };
            root.updateResult(root.currentCommandIndex, result);
            root.executeNextCommand(root.currentCommandIndex + 1);
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Style.marginM
        }
        spacing: Style.marginM

        // 标题栏
        RowLayout {
            Layout.fillWidth: true

            NText {
                text: qsTr("命令输出")
                font.pointSize: Style.fontSizeL
                font.weight: Font.Medium
                color: Color.mOnSurface
            }

            Item {
                Layout.fillWidth: true
            }

            // 刷新按钮
            NButton {
                text: qsTr("刷新")
                icon: "refresh"
                enabled: !root.isUpdating
                onClicked: {
                    root.executeAllCommands();
                }
            }

            // 设置按钮
            NButton {
                text: qsTr("设置")
                icon: "settings"
                onClicked: {
                    root.openSettings();
                }
            }
        }

        // 命令列表
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Style.radiusS
            color: Color.mSurface
            border.color: Color.mOutline
            border.width: Style.borderS

            ScrollView {
                anchors.fill: parent
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: Style.marginS

                    Repeater {
                        model: root.commandResults
                        delegate: commandDelegate
                    }

                    // 空状态
                    NText {
                        width: parent.width
                        visible: root.commandResults.length === 0
                        text: qsTr("暂无命令输出\n点击设置添加命令")
                        horizontalAlignment: Text.AlignHCenter
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }

        // 底部信息
        RowLayout {
            Layout.fillWidth: true

            NText {
                text: qsTr("更新时间: %1 秒").arg(updateInterval)
                font.pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
            }

            Item {
                Layout.fillWidth: true
            }

            NText {
                text: root.isUpdating ? qsTr("更新中...") : qsTr("已更新")
                font.pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
            }
        }
    }

    // 命令结果委托
    Component {
        id: commandDelegate

        Rectangle {
            required property var modelData

            Layout.fillWidth: true
            height: Math.max(resultColumn.height, 60) + Style.marginS * 2
            radius: Style.radiusS
            color: modelData?.success ? Color.mSurfaceVariant : Color.mErrorContainer
            border.color: modelData?.success ? Color.mOutline : Color.mError
            border.width: Style.borderS

            ColumnLayout {
                id: resultColumn
                width: parent.width - Style.marginS * 2
                x: Style.marginS
                y: Style.marginS
                spacing: Style.marginS

                // 命令标题
                RowLayout {
                    Layout.fillWidth: true

                    NIcon {
                        icon: modelData?.success ? "check" : "x"
                        color: modelData?.success ? Color.mPrimary : Color.mError
                        scale: 0.6
                    }

                    NText {
                        text: modelData?.name || qsTr("未知命令")
                        font.pointSize: Style.fontSizeS
                        font.weight: Font.Medium
                        color: modelData?.success ? Color.mOnSurface : Color.mOnError
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // 复制按钮
                    NIconButton {
                        icon: "copy"
                        onClicked: {
                            if (modelData?.output) {
                                root.copyToClipboard(modelData.output);
                            }
                        }
                    }
                }

                // 命令字符串
                NText {
                    text: modelData?.command || ""
                    font.family: "monospace"
                    font.pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                    elide: Text.ElideRight
                }

                // 输出内容
                TextArea {
                    Layout.fillWidth: true
                    readOnly: true
                    text: modelData?.output || qsTr("无输出")
                    font.family: "monospace"
                    font.pointSize: Style.fontSizeS
                    color: modelData?.success ? Color.mOnSurface : Color.mOnError
                    wrapMode: TextArea.Wrap
                    background: Rectangle {
                        color: "transparent"
                    }
                    selectByMouse: true
                }
            }
        }
    }

    // 打开设置
    function openSettings() {
        if (!pluginApi) return;

        var scr = pluginApi?.panelOpenScreen || root.screen;
        if (scr) {
            pluginApi.closePanel(scr);
            Qt.callLater(function() {
                BarService.openPluginSettings(scr, pluginApi.manifest);
            });
        } else if (pluginApi.withCurrentScreen) {
            pluginApi.withCurrentScreen(function(s) {
                pluginApi.closePanel(s);
                Qt.callLater(function() {
                    BarService.openPluginSettings(s, pluginApi.manifest);
                });
            });
        } else {
            try {
                pluginApi.openSettings(root.screen, root);
            } catch (e) {
                try {
                    pluginApi.openSettings();
                } catch (err) {
                    Logger.w("CommandOutput", "openSettings failed:", err);
                }
            }
        }
    }

    // 复制到剪贴板
    function copyToClipboard(text) {
        var escaped = text.replace(/'/g, "'\\''")
        Quickshell.execDetached([
            "sh", "-c",
            "printf '%s' '" + escaped + "' | wl-copy"
        ])
        Logger.i("CommandOutput", "已复制到剪贴板")
    }

    // 执行所有命令
    function executeAllCommands() {
        if (!root.cfg.commands || root.cfg.commands.length === 0) return

        root.isUpdating = true;
        root.commandResults = [];
        root.commandResults = new Array(root.cfg.commands.length).fill(null);
        root.executeNextCommand(0);
    }

    // 依次执行命令
    function executeNextCommand(index) {
        if (index >= root.cfg.commands.length) {
            root.isUpdating = false;
            return;
        }

        var cmd = root.cfg.commands[index];
        if (!cmd || !cmd.command) {
            root.executeNextCommand(index + 1);
            return;
        }

        root.currentCommandIndex = index;
        process.command = ["sh", "-c", cmd.command];
        process.running = true;
    }

    // 更新结果
    function updateResult(index, result) {
        var newResults = root.commandResults.slice();
        newResults[index] = result;
        root.commandResults = newResults;
    }

    Component.onCompleted: {
        root.executeAllCommands();
    }
}
