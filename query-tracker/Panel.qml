import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 600 * Style.uiScaleRatio
    property real contentPreferredHeight: 500 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property var commands: cfg.commands || defaults.commands || []
    readonly property int updateInterval: cfg.updateInterval ?? defaults.updateInterval ?? 30

    // Results from settings (persisted)
    property var results: []

    // Timer to reload settings
    Timer {
        id: settingsReloadTimer
        interval: 200
        running: false
        repeat: false
        onTriggered: {
            if (pluginApi && pluginApi.pluginSettings) {
                cfg = pluginApi.pluginSettings;
                results = cfg.results || defaults.results || [];
                Logger.d("Query Tracker", "Settings reloaded, results:", results.length);
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            settingsReloadTimer.restart();
        });
    }

    onVisibleChanged: {
        if (visible) {
            settingsReloadTimer.restart();
        }
    }

    function refresh() {
        if (pluginApi && pluginApi.refresh) {
            pluginApi.refresh();
        }
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NText {
                    text: pluginApi?.tr("widget.title", "Query Tracker") || "Query Tracker"
                    pointSize: Style.fontSizeL
                    font.bold: true
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }

                NButton {
                    text: pluginApi?.tr("widget.refresh", "Refresh") || "Refresh"
                    onClicked: refresh()
                }

                // Settings button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 6
                    color: "transparent"
                    Layout.alignment: Qt.AlignVCenter

                    NIcon {
                        anchors.centerIn: parent
                        icon: "settings"
                        pointSize: 14
                        color: Color.mOnSurface
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!pluginApi) return;

                            // Close panel first
                            var currentScreen = pluginApi.panelOpenScreen;
                            if (currentScreen) {
                                pluginApi.closePanel(currentScreen);
                                Qt.callLater(function() {
                                    try {
                                        pluginApi.openSettings();
                                    } catch (e) {
                                        Logger.w("Query Tracker", "openSettings failed:", e);
                                    }
                                });
                            } else {
                                try {
                                    pluginApi.openSettings();
                                } catch (e) {
                                    Logger.w("Query Tracker", "openSettings failed:", e);
                                }
                            }
                        }
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            // Content - Results list
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: resultsList
                    model: results
                    spacing: Style.marginS

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: 50
                        color: Color.mSurfaceVariant
                        radius: Style.radiusS

                        // Status indicator
                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: modelData.success ? Color.mPrimary : Color.mError
                            anchors {
                                left: parent.left
                                leftMargin: Style.marginM
                                top: parent.top
                                topMargin: Style.marginS + 4
                            }
                        }

                        // Command name
                        Text {
                            text: modelData.name || "Unknown"
                            font.pixelSize: (Style.fontSizeM || 14) + 4
                            color: Color.mOnSurface
                            elide: Text.ElideRight
                            anchors {
                                left: parent.left
                                leftMargin: 28
                                top: parent.top
                                topMargin: Style.marginS + 2
                                right: outputText.left
                                rightMargin: Style.marginM
                            }
                        }

                        // Output (right side)
                        Text {
                            id: outputText
                            text: modelData.stdout ? modelData.stdout :
                                  (modelData.stderr ? modelData.stderr :
                                  (modelData.success ? "(no output)" : "Exit: " + modelData.exitCode))
                            font.pixelSize: (Style.fontSizeM || 14) + 4
                            color: modelData.success ? Color.mSecondary : Color.mError
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            anchors {
                                right: parent.right
                                rightMargin: Style.marginM
                                top: parent.top
                                topMargin: Style.marginS + 2
                            }
                        }

                        // Time (below output, right aligned)
                        Text {
                            text: formatTime(modelData.timestamp)
                            font.pixelSize: (Style.fontSizeXS || 10) + 2
                            color: Color.mSecondary
                            anchors {
                                right: parent.right
                                rightMargin: Style.marginM
                                bottom: parent.bottom
                                bottomMargin: Style.marginS
                            }
                        }
                    }

                    Text {
                        visible: results.length === 0
                        anchors.centerIn: parent
                        text: pluginApi?.tr("widget.noResults", "No results") || "No results"
                        font.pixelSize: Style.fontSizeM || 14
                        color: Color.mSecondary
                    }
                }
            }

            // Footer
            NDivider {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                NText {
                    text: (pluginApi?.tr("widget.totalCommands", "Total: %1") || "Total: %1").replace("%1", commands.length)
                    pointSize: Style.fontSizeS
                    color: Color.mSecondary
                    Layout.fillWidth: true
                }

                NText {
                    text: (pluginApi?.tr("widget.success", "Success: %1") || "Success: %1").replace("%1", results.filter(function(r) { return r.success; }).length)
                    pointSize: Style.fontSizeS
                    color: Color.mPrimary
                }

                NText {
                    text: (pluginApi?.tr("widget.failed", "Failed: %1") || "Failed: %1").replace("%1", results.filter(function(r) { return !r.success; }).length)
                    pointSize: Style.fontSizeS
                    color: Color.mError
                }
            }
        }
    }

    function formatTime(timestamp) {
        if (!timestamp) return "";
        const date = new Date(timestamp);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);

        if (diffMins < 1) return "now";
        if (diffMins < 60) return diffMins + "m ago";
        if (diffHours < 24) return diffHours + "h ago";
        return date.toLocaleDateString();
    }
}
