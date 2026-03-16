// StatsTab.qml - Modifier Keys Statistics Tab
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "KeyStats.js" as KeyStats

Item {
    id: root

    property var pluginApi: null
    property string currentDateRange: "today"

    property var topKeys: []
    property var topShortcuts: []
    property int totalCount: 0

    function loadStats() {
        totalCount = KeyStats.getTotalCount(currentDateRange)
        topKeys = KeyStats.getTopKeys(currentDateRange, 20)
        topShortcuts = KeyStats.getTopShortcuts(currentDateRange, 20)
    }

    function getMostUsedKey() {
        if (topKeys.length === 0) return "-"
        return topKeys[0].stat_key + " (" + topKeys[0].total + ")"
    }

    function getMostUsedShortcut() {
        if (topShortcuts.length === 0) return "-"
        return topShortcuts[0].stat_key + " (" + topShortcuts[0].total + ")"
    }

    function getMaxCount(items) {
        if (items.length === 0) return 1
        return items[0].total
    }

    Component.onCompleted: loadStats()

    onCurrentDateRangeChanged: loadStats()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        // Time range selector
        RowLayout {
            spacing: 4
            Layout.fillWidth: true

            Repeater {
                model: [
                    { key: "today", label: pluginApi?.tr("stats.today", "Today") || "Today" },
                    { key: "yesterday", label: pluginApi?.tr("stats.yesterday", "Yesterday") || "Yesterday" },
                    { key: "week", label: pluginApi?.tr("stats.thisWeek", "This Week") || "This Week" },
                    { key: "month", label: pluginApi?.tr("stats.thisMonth", "This Month") || "This Month" },
                    { key: "all", label: pluginApi?.tr("stats.allTime", "All Time") || "All Time" }
                ]

                delegate: Rectangle {
                    width: rangeText.implicitWidth + Style.marginS * 2
                    height: 28
                    radius: Style.radiusS
                    color: currentDateRange === modelData.key ? Color.mPrimary : "transparent"
                    border.color: currentDateRange === modelData.key ? Color.mPrimary : Color.mOutlineVariant
                    border.width: 1

                    NText {
                        id: rangeText
                        anchors.centerIn: parent
                        text: modelData.label
                        pointSize: Style.fontSizeS
                        color: currentDateRange === modelData.key ? Color.mOnPrimary : Color.mOnSurfaceVariant
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: currentDateRange = modelData.key
                    }
                }
            }
        }

        // Summary card
        Rectangle {
            Layout.fillWidth: true
            height: summaryLayout.implicitHeight + Style.marginM * 2
            color: Color.mSurfaceVariant
            radius: Style.radiusM

            ColumnLayout {
                id: summaryLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.marginM
                spacing: 4

                NText {
                    text: (pluginApi?.tr("stats.totalKeypresses", "Total Keypresses") || "Total Keypresses") + ": " + totalCount.toLocaleString()
                    pointSize: Style.fontSizeM
                    color: Color.mOnSurface
                }

                NText {
                    text: (pluginApi?.tr("stats.mostUsedKey", "Most Used Key") || "Most Used Key") + ": " + getMostUsedKey()
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                }

                NText {
                    text: (pluginApi?.tr("stats.mostUsedShortcut", "Most Used Shortcut") || "Most Used Shortcut") + ": " + getMostUsedShortcut()
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                }
            }
        }

        // Top Keys Section
        NText {
            text: pluginApi?.tr("stats.topKeys", "Top 20 Keys") || "Top 20 Keys"
            pointSize: Style.fontSizeM
            font.bold: true
            color: Color.mOnSurface
        }

        ListView {
            id: keysList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 200)
            clip: true
            model: topKeys
            spacing: 2

            delegate: Rectangle {
                width: keysList.width
                height: 24
                color: Style.capsuleColor
                radius: Style.radiusS

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.marginS
                    anchors.rightMargin: Style.marginS
                    spacing: Style.marginS

                    NText {
                        text: (index + 1) + "."
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                        Layout.preferredWidth: 20
                    }

                    NText {
                        text: modelData.stat_key
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        Layout.preferredWidth: 80
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Color.mSurfaceVariant

                        Rectangle {
                            width: parent.width * (modelData.total / getMaxCount(topKeys))
                            height: parent.height
                            radius: parent.radius
                            color: Color.mPrimary
                        }
                    }

                    NText {
                        text: modelData.total.toLocaleString()
                        pointSize: Style.fontSizeS
                        color: Color.mPrimary
                        Layout.preferredWidth: 50
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }

        // Top Shortcuts Section
        NText {
            text: pluginApi?.tr("stats.topShortcuts", "Top 20 Shortcuts") || "Top 20 Shortcuts"
            pointSize: Style.fontSizeM
            font.bold: true
            color: Color.mOnSurface
        }

        ListView {
            id: shortcutsList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 200)
            clip: true
            model: topShortcuts
            spacing: 2

            delegate: Rectangle {
                width: shortcutsList.width
                height: 24
                color: Style.capsuleColor
                radius: Style.radiusS

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.marginS
                    anchors.rightMargin: Style.marginS
                    spacing: Style.marginS

                    NText {
                        text: (index + 1) + "."
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                        Layout.preferredWidth: 20
                    }

                    NText {
                        text: modelData.stat_key
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurface
                        Layout.preferredWidth: 120
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Color.mSurfaceVariant

                        Rectangle {
                            width: parent.width * (modelData.total / getMaxCount(topShortcuts))
                            height: parent.height
                            radius: parent.radius
                            color: Color.mSecondary
                        }
                    }

                    NText {
                        text: modelData.total.toLocaleString()
                        pointSize: Style.fontSizeS
                        color: Color.mSecondary
                        Layout.preferredWidth: 50
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // Clear button
        NButton {
            text: pluginApi?.tr("stats.clearStats", "Clear Statistics") || "Clear Statistics"
            Layout.alignment: Qt.AlignHCenter
            onClicked: clearDialog.open()
        }
    }

    // Clear confirmation dialog
    Dialog {
        id: clearDialog
        modal: true
        anchors.centerIn: parent
        width: 300
        height: 120

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusM
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM

            NText {
                text: pluginApi?.tr("stats.clearConfirm", "Are you sure you want to clear all statistics? This cannot be undone.") || "Are you sure you want to clear all statistics? This cannot be undone."
                pointSize: Style.fontSizeM
                color: Color.mOnSurface
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Style.marginS

                NButton {
                    text: pluginApi?.tr("cancel", "Cancel") || "Cancel"
                    onClicked: clearDialog.close()
                }

                NButton {
                    text: pluginApi?.tr("confirm", "Confirm") || "Confirm"
                    onClicked: {
                        KeyStats.clearAllStats()
                        loadStats()
                        clearDialog.close()
                    }
                }
            }
        }
    }
}
