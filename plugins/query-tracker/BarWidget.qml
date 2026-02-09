// BarWidget.qml - Query Tracker Status Bar Widget
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Item {
    id: root

    property var pluginApi: null
    property var screen

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property int updateInterval: cfg.updateInterval ?? 60

    implicitWidth: layout.implicitWidth + Style.marginM * 2
    implicitHeight: Style.baseWidgetSize

    // 状态颜色
    readonly property bool hasError: errorCount > 0
    readonly property int errorCount: 0

    // 数据缓存
    property var commandResults: []
    property bool isUpdating: false

    // 当前执行的命令索引
    property int currentCommandIndex: -1

    RowLayout {
        id: layout
        anchors {
            fill: parent
            leftMargin: Style.marginS
            rightMargin: Style.marginS
        }
        spacing: Style.marginS

        // 状态图标
        NIcon {
            icon: "terminal"
            color: root.hasError ? Color.mError : Color.mPrimary
            scale: 0.7
        }

        // 查询数量/状态文本
        NText {
            text: root.isUpdating ? qsTr("更新中...") : qsTr("%1 个查询").arg(root.commandResults.length)
            color: root.hasError ? Color.mError : Color.mOnSurfaceVariant
            font.pointSize: Style.fontSizeS
        }

        // 刷新指示器（更新时显示）
        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: root.isUpdating ? Color.mPrimary : Color.mSurfaceVariant
            visible: root.isUpdating
        }
    }

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

    // 更新结果
    function updateResult(index, result) {
        var newResults = root.commandResults.slice();
        newResults[index] = result;
        root.commandResults = newResults;

        // 检查是否所有命令都执行完成
        var allDone = true;
        for (var i = 0; i < root.cfg.commands.length; i++) {
            if (!newResults[i]) {
                allDone = false;
                break;
            }
        }
        if (allDone) {
            root.isUpdating = false;
        }
    }

    // 执行所有命令
    function executeAllCommands() {
        if (!root.cfg.commands || root.cfg.commands.length === 0) return

        root.isUpdating = true;
        root.commandResults = [];
        root.commandResults = new Array(root.cfg.commands.length).fill(null);

        // 从第一个命令开始
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

    // 定时器
    Timer {
        id: updateTimer
        interval: root.updateInterval * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.executeAllCommands();
        }
    }

    // 点击打开面板
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(root.screen, root);
            }
        }
    }

    Component.onCompleted: {
        root.executeAllCommands();
    }
}
