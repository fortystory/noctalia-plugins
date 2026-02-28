import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property bool isVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"

    // Configuration
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property var commands: cfg.commands || defaults.commands || []
    readonly property int updateInterval: cfg.updateInterval ?? defaults.updateInterval ?? 30

    // Watch for config changes
    onCfgChanged: {
        Logger.d("Query Tracker", "Query Tracker BarWidget: Config changed");
    }

    // Local state
    property var commandResults: []
    property int successCount: 0
    property int failCount: 0

    // Sync from settings
    function syncFromSettings() {
        if (pluginApi && pluginApi.pluginSettings) {
            const newCfg = pluginApi.pluginSettings;
            const newCommands = newCfg.commands || defaults.commands || [];
            const newInterval = newCfg.updateInterval ?? defaults.updateInterval ?? 30;

            if (JSON.stringify(commands) !== JSON.stringify(newCommands)) {
                Logger.d("Query Tracker", "Commands updated, count:", newCommands.length);
            }
        }
    }

    // Timer to periodically sync settings
    Timer {
        id: settingsSyncTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            syncFromSettings();
        }
    }

    Component.onCompleted: {
        Logger.d("Query Tracker", "BarWidget loaded");
        syncFromSettings();
    }

    onPluginApiChanged: {
        if (pluginApi) {
            // Share results with Panel
            try {
                if (pluginApi.sharedData !== undefined) {
                    pluginApi.sharedData.commandResults = commandResults;
                }
            } catch (e) {
                Logger.w("Query Tracker", "Error sharing data:", e);
            }
        }
    }

    onCommandResultsChanged: {
        if (pluginApi) {
            try {
                if (pluginApi.sharedData !== undefined) {
                    pluginApi.sharedData.commandResults = commandResults;
                }
            } catch (e) {
                Logger.w("Query Tracker", "Error sharing data:", e);
            }
        }
    }

    readonly property real visualContentWidth: rowLayout.implicitWidth + Style.marginS
    readonly property real visualContentHeight: rowLayout.implicitHeight + Style.marginS

    // readonly property real contentWidth: Math.max(48, isVertical ? Style.capsuleHeight : visualContentWidth)
    // readonly property real contentHeight: Math.max(28, isVertical ? visualContentHeight : Style.capsuleHeight)

    readonly property real contentWidth: row.implicitWidth + Style.marginM
    readonly property real contentHeight: capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    // Timer for periodic command execution
    Timer {
        id: executeTimer
        interval: updateInterval * 1000
        running: commands.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            Logger.d("Query Tracker", "Timer triggered, executing commands");
            executeAllCommands();
        }
    }

    // Process for executing commands
    Process {
        id: execProcess
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        property bool isExecuting: false
        property int currentCommandIndex: 0
        property var tempResults: []

        onExited: exitCode => {
            if (!isExecuting) return;

            const cmd = commands[execProcess.currentCommandIndex];
            const outText = stdout.text || "";
            const errText = stderr.text || "";
            const result = {
                name: cmd ? cmd.name : "Unknown",
                command: cmd ? cmd.command : "",
                exitCode: exitCode,
                stdout: outText,
                stderr: errText,
                timestamp: new Date().toISOString(),
                success: exitCode === 0
            };

            Logger.d("Query Tracker", "Command result:", result.name, "exit:", exitCode, "stdout:", outText.substring(0, 50));

            tempResults.push(result);
            execProcess.currentCommandIndex++;

            // Continue to next command
            if (execProcess.currentCommandIndex < commands.length) {
                executeNextCommand();
            } else {
                // All commands executed
                finishExecution();
            }
        }
    }

    function executeAllCommands() {
        if (commands.length === 0) {
            Logger.d("Query Tracker", "No commands configured");
            return;
        }

        if (execProcess.isExecuting) {
            Logger.d("Query Tracker", "Already executing");
            return;
        }

        Logger.d("Query Tracker", "Starting execution of", commands.length, "commands");
        execProcess.isExecuting = true;
        execProcess.currentCommandIndex = 0;
        execProcess.tempResults = [];
        executeNextCommand();
    }

    function executeNextCommand() {
        if (execProcess.currentCommandIndex >= commands.length) {
            finishExecution();
            return;
        }

        const cmd = commands[execProcess.currentCommandIndex];
        if (!cmd || !cmd.command) {
            execProcess.currentCommandIndex++;
            executeNextCommand();
            return;
        }

        Logger.d("Query Tracker", "Executing command:", cmd.name);

        execProcess.command = ["sh", "-c", cmd.command];
        execProcess.running = true;
    }

    function finishExecution() {
        execProcess.isExecuting = false;

        // Update results
        commandResults = execProcess.tempResults.slice();

        // Count successes and failures
        successCount = commandResults.filter(r => r.success).length;
        failCount = commandResults.filter(r => !r.success).length;

        Logger.d("Query Tracker", "Execution complete. Success:", successCount, "Fail:", failCount);

        // Save results to settings for persistence
        saveResultsToSettings();
    }

    function saveResultsToSettings() {
        if (!pluginApi) return;
        if (!pluginApi.pluginSettings) {
            pluginApi.pluginSettings = {};
        }
        pluginApi.pluginSettings.results = commandResults;
        pluginApi.saveSettings();
        Logger.d("Query Tracker", "Results saved to settings");
    }

    // Expose refresh function
    function refresh() {
        executeAllCommands();
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusM
        color: Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: "terminal"
                pointSize: Style.barFontSize
                color: failCount > 0 ? Color.mOnError : Color.mOnSurface
            }

            Rectangle {
                visible: failCount > 0
                width: badgeText.implicitWidth + 8
                height: badgeText.implicitHeight + 6
                radius: height * 0.5
                color: Color.mError
                Layout.preferredWidth: width
                Layout.preferredHeight: height

                NText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: failCount.toString()
                    pointSize: Style.barFontSize
                    color: Color.mOnError
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!pluginApi) return;
            try {
                pluginApi.openPanel(root.screen, root);
            } catch (e) {
                try {
                    pluginApi.openPanel(screen);
                } catch (err) {
                    Logger.w("Query Tracker", "openPanel failed:", err);
                }
            }
        }
    }
}
