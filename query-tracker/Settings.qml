import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    // Local commands array with sync pattern
    property var localCommands: cfg.commands || defaults.commands || []
    property int commandCount: localCommands.length

    property int updateInterval: (cfg.updateInterval ?? defaults.updateInterval ?? 30)

    // Temporary fields for adding new command
    property string newCmdName: ""
    property string newCmdCommand: ""

    function syncFromSettings() {
        if (!pluginApi) return;
        const newCfg = pluginApi.pluginSettings || {};
        const newCommands = newCfg.commands || defaults.commands || [];
        const newInterval = newCfg.updateInterval ?? defaults.updateInterval ?? 30;

        localCommands = newCommands;
        commandCount = newCommands.length;
        updateInterval = newInterval;

        Logger.d("Query Tracker", "Sync from settings:", commandCount, "commands");
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Query Tracker: Cannot save settings - pluginApi is null");
            return;
        }

        if (!pluginApi.pluginSettings) {
            pluginApi.pluginSettings = {};
        }

        pluginApi.pluginSettings.commands = localCommands;
        pluginApi.pluginSettings.updateInterval = updateInterval;

        Logger.d("Query Tracker", "Saving - commands:", commandCount, "interval:", updateInterval);

        pluginApi.saveSettings();
        Logger.d("Query Tracker", "Settings saved successfully");
    }

    function addCommand() {
        if (newCmdName.trim() === "" || newCmdCommand.trim() === "") {
            Logger.e("Query Tracker: Name and command are required");
            return;
        }

        const newCmds = localCommands.slice();
        newCmds.push({
            name: newCmdName.trim(),
            command: newCmdCommand.trim()
        });
        localCommands = newCmds;
        commandCount = newCmds.length;

        newCmdName = "";
        newCmdCommand = "";

        saveSettings();
    }

    function removeCommand(index) {
        const newCmds = localCommands.slice();
        newCmds.splice(index, 1);
        localCommands = newCmds;
        commandCount = newCmds.length;
        saveSettings();
    }

    function updateCommand(index, name, command) {
        if (index < 0 || index >= localCommands.length) return;

        const newCmds = localCommands.slice();
        newCmds[index] = {
            name: name,
            command: command
        };
        localCommands = newCmds;
        saveSettings();
    }

    function clearResults() {
        if (!pluginApi) return;
        if (!pluginApi.pluginSettings) {
            pluginApi.pluginSettings = {};
        }
        pluginApi.pluginSettings.results = [];
        pluginApi.saveSettings();
        Logger.d("Query Tracker", "Results cleared");
    }

    // Watch for external setting changes
    Timer {
        id: settingsWatchTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            syncFromSettings();
        }
    }

    // Update Interval
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.updateInterval", "Update Interval") || "Update Interval"
            description: pluginApi?.tr("settings.updateIntervalDesc", "How often to execute commands (seconds)") || "How often to execute commands (seconds)"
        }

        RowLayout {
            spacing: Style.marginM

            NSpinBox {
                from: 5
                to: 3600
                value: updateInterval
                onValueChanged: {
                    updateInterval = value;
                    saveSettings();
                }
            }

            Text {
                text: pluginApi?.tr("settings.seconds", "seconds") || "seconds"
                color: Style.textColorSecondary || "#FFFFFF"
                font.pixelSize: Style.fontSizeM || 14
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Style.borderColor || "#333333"
    }

    // Clear Results Button
    RowLayout {
        Layout.fillWidth: true

        NButton {
            text: pluginApi?.tr("settings.clearResults", "Clear Results") || "Clear Results"
            onClicked: clearResults()
        }

        Text {
            text: pluginApi?.tr("settings.clearResultsDesc", "Clear all saved command results") || "Clear all saved command results"
            font.pixelSize: Style.fontSizeS || 12
            color: Style.textColorSecondary || "#AAAAAA"
            Layout.fillWidth: true
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Style.borderColor || "#333333"
    }

    // Commands Management
    Text {
        text: pluginApi?.tr("settings.commands", "Commands") || "Commands"
        font.pixelSize: Style.fontSizeL || 18
        font.bold: true
        color: Style.textColor || "#FFFFFF"
    }

    // Add New Command
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        Text {
            text: pluginApi?.tr("settings.addCommand", "Add New Command") || "Add New Command"
            font.bold: true
            color: Style.textColor || "#FFFFFF"
            font.pixelSize: Style.fontSizeM || 14
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: pluginApi?.tr("settings.commandName", "Name") || "Name"
                    font.pixelSize: Style.fontSizeS || 12
                    color: Style.textColorSecondary || "#FFFFFF"
                }

                NTextInput {
                    Layout.fillWidth: true
                    placeholderText: "Disk Usage"
                    text: newCmdName
                    onTextChanged: newCmdName = text
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: pluginApi?.tr("settings.command", "Command") || "Command"
                    font.pixelSize: Style.fontSizeS || 12
                    color: Style.textColorSecondary || "#AAAAAA"
                }

                NTextInput {
                    Layout.fillWidth: true
                    placeholderText: "df -h / | tail -1"
                    text: newCmdCommand
                    onTextChanged: newCmdCommand = text
                }
            }

            NButton {
                text: pluginApi?.tr("settings.add", "Add") || "Add"
                enabled: newCmdName.trim() !== "" && newCmdCommand.trim() !== ""
                onClicked: addCommand()
            }
        }
    }

    // Command List
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 300
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: Style.marginS

            Repeater {
                model: commandCount

                delegate: Rectangle {
                    required property int index

                    width: ListView.view ? ListView.view.width : parent.width
                    height: cmdItemLayout.implicitHeight + 16
                    color: Style.fillColorSecondary || "#2A2A2A"
                    radius: Style.radiusM || 8

                    readonly property var cmdData: root.localCommands[index]

                    function editCommand() {
                        editDialog.index = index;
                        editDialog.name = cmdData.name;
                        editDialog.command = cmdData.command;
                        editDialog.open();
                    }

                    RowLayout {
                        id: cmdItemLayout
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: Style.marginM

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: cmdData ? cmdData.name : ""
                                font.pixelSize: Style.fontSizeM || 14
                                font.bold: true
                                color: Style.textColor || "#FFFFFF"
                                Layout.fillWidth: true
                            }

                            Text {
                                text: cmdData ? cmdData.command : ""
                                font.pixelSize: Style.fontSizeS || 12
                                color: Style.textColorSecondary || "#AAAAAA"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Edit button (icon only)
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: "transparent"

                            NIcon {
                                anchors.centerIn: parent
                                icon: "edit"
                                pointSize: 14
                                color: Color.mPrimary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: editCommand()
                            }
                        }

                        // Remove button (icon only)
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 6
                            color: "transparent"

                            NIcon {
                                anchors.centerIn: parent
                                icon: "minus"
                                pointSize: 14
                                color: Color.mError
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    confirmDialog.index = index;
                                    confirmDialog.commandName = cmdData.name;
                                    confirmDialog.open();
                                }
                            }
                        }
                    }
                }
            }

            Text {
                visible: commandCount === 0
                text: pluginApi?.tr("settings.noCommands", "No commands configured. Add one above!") || "No commands configured. Add one above!"
                font.pixelSize: Style.fontSizeM || 14
                color: Style.textColorSecondary || "#888888"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.marginM
            }
        }
    }

    // Edit Dialog
    Dialog {
        id: editDialog
        property int index: -1
        property string name: ""
        property string command: ""

        modal: true
        width: 500 * Style.uiScaleRatio
        height: 250 * Style.uiScaleRatio

        background: Rectangle {
            color: Style.surfaceColor || "#1E1E1E"
            radius: Style.radiusM
        }

        // Custom header
        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 40
            color: Style.surfaceColor || "#2A2A2A"
            radius: Style.radiusM

            Text {
                text: pluginApi?.tr("settings.editCommand", "Edit Command") || "Edit Command"
                font.pixelSize: Style.fontSizeM || 14
                font.bold: true
                color: Style.textColor || "#FFFFFF"
                anchors.centerIn: parent
            }

            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: "transparent"
                anchors.right: parent.right
                anchors.rightMargin: Style.marginS
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "x"
                    font.pixelSize: 16
                    color: Style.textColor || "#FFFFFF"
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: editDialog.reject()
                }
            }
        }

        ColumnLayout {
            anchors.top: parent.top
            anchors.topMargin: 50
            spacing: Style.marginM
            width: parent.width

            Text {
                text: pluginApi?.tr("settings.commandName", "Name") || "Name"
                font.pixelSize: Style.fontSizeM || 14
                color: Style.textColorSecondary || "#AAAAAA"
            }

            NTextInput {
                Layout.fillWidth: true
                text: editDialog.name
                onTextChanged: editDialog.name = text
            }

            Text {
                text: pluginApi?.tr("settings.command", "Command") || "Command"
                font.pixelSize: Style.fontSizeM || 14
                color: Style.textColorSecondary || "#AAAAAA"
            }

            NTextInput {
                Layout.fillWidth: true
                text: editDialog.command
                onTextChanged: editDialog.command = text
            }
        }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.marginM
            anchors.right: parent.right
            anchors.rightMargin: Style.marginM
            spacing: Style.marginS

            NButton {
                text: pluginApi?.tr("settings.cancel", "Cancel") || "Cancel"
                onClicked: editDialog.reject()
            }

            NButton {
                text: pluginApi?.tr("settings.save", "Save") || "Save"
                onClicked: editDialog.accept()
            }
        }
    }

    // Delete Confirmation Dialog
    Dialog {
        id: confirmDialog
        property int index: -1
        property string commandName: ""

        modal: true
        width: 400 * Style.uiScaleRatio
        height: 180 * Style.uiScaleRatio

        background: Rectangle {
            color: Style.surfaceColor || "#1E1E1E"
            radius: Style.radiusM
        }

        Text {
            text: pluginApi?.tr("settings.deleteConfirm", "Delete this command?") || "Delete this command?"
            font.pixelSize: Style.fontSizeM || 14
            color: Style.textColor || "#FFFFFF"
            anchors.centerIn: parent
        }

        RowLayout {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.marginM
            anchors.right: parent.right
            anchors.rightMargin: Style.marginM
            spacing: Style.marginS

            NButton {
                text: pluginApi?.tr("settings.cancel", "Cancel") || "Cancel"
                onClicked: confirmDialog.reject()
            }

            NButton {
                text: pluginApi?.tr("settings.delete", "Delete") || "Delete"
                onClicked: {
                    if (confirmDialog.index >= 0) {
                        removeCommand(confirmDialog.index);
                    }
                    confirmDialog.reject();
                }
            }
        }
    }
}
