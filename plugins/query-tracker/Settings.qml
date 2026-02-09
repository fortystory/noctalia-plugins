// Settings.qml - Query Tracker Settings
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

    // 本地状态，用于强制刷新
    property var localCommands: []
    property int localUpdateInterval: 60
    property bool initialized: false
    // 使用计数器强制 Repeater 刷新
    property int commandCount: 0

    // 初始化
    Component.onCompleted: {
        syncFromSettings();
        initialized = true;
    }

    function syncFromSettings() {
        if (!pluginApi) return;
        var cfg = pluginApi.pluginSettings || {};
        var def = pluginApi.manifest?.metadata?.defaultSettings || {};

        localCommands = cfg.commands || def.commands || [];
        commandCount = localCommands.length;
        localUpdateInterval = cfg.updateInterval ?? def.updateInterval ?? 60;
    }

    function syncToSettings() {
        if (!pluginApi) return;
        pluginApi.pluginSettings.commands = localCommands;
        pluginApi.pluginSettings.updateInterval = localUpdateInterval;
        pluginApi.saveSettings();
    }

    // 添加新命令
    function addNewCommand() {
        console.log("addNewCommand 被调用, 当前 count:", commandCount);
        var newCmds = localCommands.slice();
        console.log("当前命令数:", newCmds.length);
        newCmds.push({ name: "", command: "" });
        localCommands = newCmds;
        commandCount = newCmds.length;
        console.log("更新后 count:", commandCount);
        syncToSettings();
    }

    // 更新命令
    function updateCommand(index, newData) {
        if (index < 0 || index >= localCommands.length) return;
        var newCmds = localCommands.slice();
        newCmds[index] = newData;
        localCommands = newCmds;
        commandCount = newCmds.length;  // 强制刷新
        syncToSettings();
    }

    // 删除命令
    function deleteCommand(index) {
        if (index < 0 || index >= localCommands.length) return;
        var newCmds = localCommands.slice();
        newCmds.splice(index, 1);
        localCommands = newCmds;
        commandCount = newCmds.length;  // 强制刷新
        syncToSettings();
    }

    // 标题
    NText {
        text: qsTr("查询追踪设置")
        font.pointSize: Style.fontSizeL
        font.weight: Font.Medium
        color: Color.mOnSurface
    }

    // 更新间隔设置
    RowLayout {
        Layout.fillWidth: true

        NText {
            text: qsTr("更新间隔:")
            color: Color.mOnSurface
        }

        NSlider {
            id: intervalSlider
            Layout.fillWidth: true
            from: 10
            to: 3600
            stepSize: 10
            value: localUpdateInterval
            onValueChanged: {
                localUpdateInterval = value;
                syncToSettings();
            }
        }

        NText {
            text: qsTr("%1 秒").arg(localUpdateInterval)
            color: Color.mOnSurfaceVariant
            Layout.preferredWidth: 60
        }
    }

    // 查询列表标题和添加按钮
    RowLayout {
        Layout.fillWidth: true

        NText {
            text: qsTr("查询列表")
            font.pointSize: Style.fontSizeM
            font.weight: Font.Medium
            color: Color.mOnSurface
        }

        Item { Layout.fillWidth: true }

        NButton {
            text: qsTr("添加查询")
            onClicked: {
                console.log("添加按钮点击");
                addNewCommand();
            }
        }
    }

    // 命令列表容器
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
                    id: repeater
                    // 使用数组和计数器组合触发刷新
                    model: root.commandCount
                    delegate: commandDelegate
                }

                // 空状态提示
                NText {
                    visible: root.localCommands.length === 0
                    text: qsTr("暂无查询，点击上方按钮添加")
                    horizontalAlignment: Text.AlignHCenter
                    color: Color.mOnSurfaceVariant
                }
            }
        }
    }

    // 底部提示
    NText {
        text: qsTr("提示: 修改将自动保存")
        font.pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
    }

    // 命令编辑委托
    Component {
        id: commandDelegate

        Rectangle {
            required property int index

            Layout.fillWidth: true
            height: col.height + Style.marginS
            radius: Style.radiusS
            color: Color.mSurfaceVariant
            border.color: Color.mOutline
            border.width: Style.borderS

            // 通过索引从 localCommands 获取数据
            readonly property var cmdData: root.localCommands[index] || {}

            ColumnLayout {
                id: col
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Style.marginS
                }
                spacing: Style.marginS

                // 名称
                RowLayout {
                    Layout.fillWidth: true
                    NText { text: qsTr("名称:"); color: Color.mOnSurface; Layout.preferredWidth: 50 }
                    NTextInput {
                        Layout.fillWidth: true
                        text: cmdData.name || ""
                        onEditingFinished: {
                            updateCommand(index, { name: text, command: cmdData.command });
                        }
                    }
                }

                // 查询
                RowLayout {
                    Layout.fillWidth: true
                    NText { text: qsTr("查询:"); color: Color.mOnSurface; Layout.preferredWidth: 50 }
                    NTextInput {
                        Layout.fillWidth: true
                        text: cmdData.command || ""
                        onEditingFinished: {
                            updateCommand(index, { name: cmdData.name, command: text });
                        }
                    }
                }

                // 删除按钮
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    NButton {
                        text: qsTr("删除")
                        onClicked: {
                            deleteCommand(index);
                        }
                    }
                }
            }
        }
    }

}
