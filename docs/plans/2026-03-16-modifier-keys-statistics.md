# Modifier Keys 按键统计功能实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为 modifier-keys 插件添加按键统计功能，使用 SQLite 持久化存储，在 Panel 中展示统计数据。

**Architecture:** 使用 Qt Quick LocalStorage (SQLite) 存储统计数据，内存缓冲区批量写入优化性能，Tab 面板展示帮助和统计两个视图。

**Tech Stack:** Qt Quick 2.15, QtQuick.LocalStorage, SQLite, QML

**Design Spec:** `docs/superpowers/specs/2026-03-16-modifier-keys-statistics-design.md`

---

## Task 1: 创建 KeyStats.js 数据库模块

**Files:**
- Create: `modifier-keys/KeyStats.js`

**Step 1: 创建 KeyStats.js 文件骨架**

```javascript
// KeyStats.js - Modifier Keys Statistics Database Module
.pragma library

.import QtQuick.LocalStorage 2.15 as LocalStorage

// ==================== 常量定义 ====================

const DB_NAME = "modifier-keys-stats";
const DB_VERSION = "1.0";
const DB_DESCRIPTION = "Modifier Keys Statistics Database";
const DB_SIZE = 5 * 1024 * 1024;  // 5 MB

const MODIFIER_ORDER = ["Super", "Ctrl", "Alt", "Shift"];

const BUFFER_SIZE = 50;
const FLUSH_INTERVAL = 30000;

// ==================== 模块状态 ====================

let _db = null;
let _buffer = [];

// ==================== 导出函数 ====================

function openDatabase() { /* 待实现 */ }
function initDatabase(db) { /* 待实现 */ }
function normalizeShortcut(modifiers, keyName) { /* 待实现 */ }
function normalizeKeyName(rawKeyName) { /* 待实现 */ }
function formatDate(date) { /* 待实现 */ }
function getWeekStart(date) { /* 待实现 */ }
function getDateRangeCondition(range) { /* 待实现 */ }
function recordKeyEvent(keyName, modifiers) { /* 待实现 */ }
function flushBuffer() { /* 待实现 */ }
function getTotalCount(dateRange) { /* 待实现 */ }
function getTopKeys(dateRange, limit) { /* 待实现 */ }
function getTopShortcuts(dateRange, limit) { /* 待实现 */ }
function cleanupOldData() { /* 待实现 */ }
function clearAllStats() { /* 待实现 */ }
```

**Step 2: 实现数据库初始化函数**

```javascript
function openDatabase() {
    if (_db) return _db;
    
    try {
        _db = LocalStorage.LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
        initDatabase(_db);
        return _db;
    } catch (e) {
        console.error("KeyStats: Failed to open database:", e);
        return null;
    }
}

function initDatabase(db) {
    db.transaction(function(tx) {
        // 原始事件表（仅保留当天）
        tx.executeSql('CREATE TABLE IF NOT EXISTS key_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key_name TEXT NOT NULL,
            modifiers TEXT,
            shortcut TEXT,
            timestamp INTEGER NOT NULL
        )');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_events_timestamp ON key_events(timestamp)');
        
        // 每日统计表（永久存储）
        tx.executeSql('CREATE TABLE IF NOT EXISTS key_stats_daily (
            date TEXT NOT NULL,
            stat_type TEXT NOT NULL,
            stat_key TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (date, stat_type, stat_key)
        )');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_daily_stat ON key_stats_daily(stat_type, stat_key)');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_daily_date ON key_stats_daily(date)');
        
        // 每日总计数
        tx.executeSql('CREATE TABLE IF NOT EXISTS daily_totals (
            date TEXT PRIMARY KEY,
            total_keypresses INTEGER NOT NULL DEFAULT 0
        )');
    });
}
```

**Step 3: 实现标准化函数**

```javascript
function normalizeShortcut(modifiers, keyName) {
    if (!modifiers || modifiers.length === 0) return null;
    
    const sorted = modifiers.slice().sort((a, b) => {
        return MODIFIER_ORDER.indexOf(a) - MODIFIER_ORDER.indexOf(b);
    });
    
    return sorted.join("+") + "+" + keyName;
}

function normalizeKeyName(rawKeyName) {
    let name = rawKeyName.replace(/^KEY_/, "");
    
    const keyMap = {
        "LEFTMETA": "Super", "RIGHTMETA": "Super",
        "LEFTALT": "Alt", "RIGHTALT": "Alt",
        "LEFTCTRL": "Ctrl", "RIGHTCTRL": "Ctrl",
        "LEFTSHIFT": "Shift", "RIGHTSHIFT": "Shift"
    };
    
    return keyMap[name.toUpperCase()] || name.toUpperCase();
}

function formatDate(date) {
    return date.toISOString().split('T')[0];
}

function getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);
    return new Date(d.setDate(diff));
}

function getDateRangeCondition(range) {
    const now = new Date();
    const today = formatDate(now);
    
    switch(range) {
        case "today":
            return `date = '${today}'`;
        case "yesterday":
            const yesterday = formatDate(new Date(now.getTime() - 86400000));
            return `date = '${yesterday}'`;
        case "week":
            const weekStart = getWeekStart(now);
            return `date >= '${formatDate(weekStart)}'`;
        case "month":
            const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
            return `date >= '${formatDate(monthStart)}'`;
        case "all":
            return "1=1";
        default:
            return `date = '${today}'`;
    }
}
```

**Step 4: 实现写入操作**

```javascript
function recordKeyEvent(keyName, modifiers) {
    const normalizedKey = normalizeKeyName(keyName);
    const normalizedShortcut = normalizeShortcut(modifiers, normalizedKey);
    
    _buffer.push({
        keyName: normalizedKey,
        modifiers: modifiers ? modifiers.join("+") : null,
        shortcut: normalizedShortcut,
        timestamp: Date.now()
    });
    
    if (_buffer.length >= BUFFER_SIZE) {
        flushBuffer();
    }
}

function flushBuffer() {
    if (_buffer.length === 0) return;
    
    const db = openDatabase();
    if (!db) return;
    
    const today = formatDate(new Date());
    const eventsToFlush = _buffer.slice();
    _buffer = [];
    
    try {
        db.transaction(function(tx) {
            for (const event of eventsToFlush) {
                tx.executeSql(
                    'INSERT INTO key_events (key_name, modifiers, shortcut, timestamp) VALUES (?, ?, ?, ?)',
                    [event.keyName, event.modifiers, event.shortcut, event.timestamp]
                );
                
                tx.executeSql(
                    'INSERT OR REPLACE INTO key_stats_daily (date, stat_type, stat_key, count) VALUES (?, ?, ?, COALESCE((SELECT count FROM key_stats_daily WHERE date=? AND stat_type=? AND stat_key=?), 0) + 1)',
                    [today, 'key', event.keyName, today, 'key', event.keyName]
                );
                
                if (event.shortcut) {
                    tx.executeSql(
                        'INSERT OR REPLACE INTO key_stats_daily (date, stat_type, stat_key, count) VALUES (?, ?, ?, COALESCE((SELECT count FROM key_stats_daily WHERE date=? AND stat_type=? AND stat_key=?), 0) + 1)',
                        [today, 'shortcut', event.shortcut, today, 'shortcut', event.shortcut]
                    );
                }
                
                tx.executeSql(
                    'INSERT OR REPLACE INTO daily_totals (date, total_keypresses) VALUES (?, COALESCE((SELECT total_keypresses FROM daily_totals WHERE date=?), 0) + 1)',
                    [today, today]
                );
            }
        });
    } catch (e) {
        console.error("KeyStats: Failed to flush buffer:", e);
    }
}
```

**Step 5: 实现查询操作**

```javascript
function getTotalCount(dateRange) {
    const db = openDatabase();
    if (!db) return 0;
    
    const condition = getDateRangeCondition(dateRange);
    let result = 0;
    
    try {
        db.readTransaction(function(tx) {
            const rs = tx.executeSql(`SELECT SUM(total_keypresses) as total FROM daily_totals WHERE ${condition}`);
            if (rs.rows.length > 0) {
                result = rs.rows.item(0).total || 0;
            }
        });
    } catch (e) {
        console.error("KeyStats: Failed to get total count:", e);
    }
    
    return result;
}

function getTopKeys(dateRange, limit) {
    const db = openDatabase();
    if (!db) return [];
    
    const condition = getDateRangeCondition(dateRange);
    const results = [];
    
    try {
        db.readTransaction(function(tx) {
            const rs = tx.executeSql(
                `SELECT stat_key, SUM(count) as total FROM key_stats_daily WHERE stat_type='key' AND ${condition} GROUP BY stat_key ORDER BY total DESC LIMIT ?`,
                [limit]
            );
            for (let i = 0; i < rs.rows.length; i++) {
                results.push(rs.rows.item(i));
            }
        });
    } catch (e) {
        console.error("KeyStats: Failed to get top keys:", e);
    }
    
    return results;
}

function getTopShortcuts(dateRange, limit) {
    const db = openDatabase();
    if (!db) return [];
    
    const condition = getDateRangeCondition(dateRange);
    const results = [];
    
    try {
        db.readTransaction(function(tx) {
            const rs = tx.executeSql(
                `SELECT stat_key, SUM(count) as total FROM key_stats_daily WHERE stat_type='shortcut' AND ${condition} GROUP BY stat_key ORDER BY total DESC LIMIT ?`,
                [limit]
            );
            for (let i = 0; i < rs.rows.length; i++) {
                results.push(rs.rows.item(i));
            }
        });
    } catch (e) {
        console.error("KeyStats: Failed to get top shortcuts:", e);
    }
    
    return results;
}
```

**Step 6: 实现清理操作**

```javascript
function cleanupOldData() {
    const db = openDatabase();
    if (!db) return;
    
    const yesterday = formatDate(new Date(Date.now() - 86400000));
    
    try {
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM key_events WHERE date(timestamp/1000, "unixepoch") < ?', [yesterday]);
        });
    } catch (e) {
        console.error("KeyStats: Failed to cleanup old data:", e);
    }
}

function clearAllStats() {
    const db = openDatabase();
    if (!db) return;
    
    _buffer = [];
    
    try {
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM key_events');
            tx.executeSql('DELETE FROM key_stats_daily');
            tx.executeSql('DELETE FROM daily_totals');
        });
    } catch (e) {
        console.error("KeyStats: Failed to clear all stats:", e);
    }
}
```

**Step 7: 提交**

```bash
git add modifier-keys/KeyStats.js
git commit -m "feat(modifier-keys): add KeyStats.js database module for statistics"
```

---

## Task 2: 创建 HelpTab.qml 组件

**Files:**
- Create: `modifier-keys/HelpTab.qml`
- Reference: `modifier-keys/Panel.qml` (existing content)

**Step 1: 从 Panel.qml 提取帮助内容到独立组件**

```qml
// HelpTab.qml - Modifier Keys Help Tab
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    function loadModifierSymbols() {
        if (!pluginApi) return defaultModifierSymbols;
        const cfg = pluginApi.pluginSettings || {};
        const saved = cfg.modifierSymbols || "";
        if (!saved || saved.trim() === "") return defaultModifierSymbols;
        try {
            const parsed = JSON.parse(saved);
            var result = {};
            for (var k in defaultModifierSymbols) result[k] = defaultModifierSymbols[k];
            for (var k in parsed) result[k] = parsed[k];
            return result;
        } catch (e) {
            return defaultModifierSymbols;
        }
    }

    readonly property var defaultModifierSymbols: ({
        "super": "⌘",
        "alt": "⌥",
        "ctrl": "⌃",
        "shift": "🡅"
    })

    property var modifierSymbols: loadModifierSymbols()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginS

        // Title
        NText {
            text: pluginApi?.tr("title", "Modifier Keys") || "Modifier Keys"
            pointSize: Style.fontSizeL
            font.bold: true
            color: Color.mOnSurface
            Layout.alignment: Qt.AlignHCenter
        }

        NDivider {
            Layout.fillWidth: true
        }

        // Key list
        Repeater {
            model: [
                { key: "Meta", name: pluginApi?.tr("super", "Super (Win)") || "Super (Win)" },
                { key: "Alt", name: pluginApi?.tr("alt", "Alt") || "Alt" },
                { key: "Ctrl", name: pluginApi?.tr("ctrl", "Ctrl") || "Ctrl" },
                { key: "Shift", name: pluginApi?.tr("shift", "Shift") || "Shift" }
            ]

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                NText {
                    text: root.modifierSymbols[modelData.key.toLowerCase()] || "?"
                    pointSize: Style.fontSizeL
                    color: Color.mPrimary
                    Layout.preferredWidth: 30
                    Layout.alignment: Qt.AlignHCenter
                }

                NText {
                    text: modelData.name
                    pointSize: Style.fontSizeM
                    color: Color.mOnSurface
                    Layout.fillWidth: true
                }

                NText {
                    text: modelData.key
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                }
            }
        }

        NDivider {
            Layout.fillWidth: true
        }

        // Gesture legend
        NText {
            text: pluginApi?.tr("gestures", "Gestures") || "Gestures"
            pointSize: Style.fontSizeM
            font.bold: true
            color: Color.mOnSurface
        }

        ColumnLayout {
            spacing: 4

            RowLayout {
                NText { text: "󰆽"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                NText { text: pluginApi?.tr("motion", "Motion") || "Motion"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
            }
            RowLayout {
                NText { text: "󰳽"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                NText { text: pluginApi?.tr("click", "Click") || "Click"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
            }
            RowLayout {
                NText { text: "⥤ ⥥ ⥢ ⥣"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                NText { text: pluginApi?.tr("scroll", "Scroll") || "Scroll"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
            }
            RowLayout {
                NText { text: "🡆 🡇 🡄 🡅"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                NText { text: pluginApi?.tr("swipe3", "3-Finger Swipe") || "3-Finger Swipe"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
            }
            RowLayout {
                NText { text: "⭲ ⭳ ⭰ ⭱"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                NText { text: pluginApi?.tr("swipe4", "4-Finger Swipe") || "4-Finger Swipe"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
            }
            RowLayout {
                NText { text: "󰘖  󰘕"; pointSize: Style.fontSizeS; color: Color.mPrimary; Layout.preferredWidth: 90 }
                NText { text: pluginApi?.tr("pinch", "Pinch") || "Pinch"; pointSize: Style.fontSizeS; color: Color.mOnSurfaceVariant }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
```

**Step 2: 提交**

```bash
git add modifier-keys/HelpTab.qml
git commit -m "feat(modifier-keys): extract help content to HelpTab.qml component"
```

---

## Task 3: 创建 StatsTab.qml 组件

**Files:**
- Create: `modifier-keys/StatsTab.qml`

**Step 1: 创建 StatsTab.qml 统计面板**

```qml
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
        totalCount = KeyStats.getTotalCount(currentDateRange);
        topKeys = KeyStats.getTopKeys(currentDateRange, 20);
        topShortcuts = KeyStats.getTopShortcuts(currentDateRange, 20);
    }

    function getMostUsedKey() {
        if (topKeys.length === 0) return "-";
        return topKeys[0].stat_key + " (" + topKeys[0].total + ")";
    }

    function getMostUsedShortcut() {
        if (topShortcuts.length === 0) return "-";
        return topShortcuts[0].stat_key + " (" + topShortcuts[0].total + ")";
    }

    function getMaxCount(items) {
        if (items.length === 0) return 1;
        return items[0].total;
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
                    { key: "today", label: pluginApi?.tr("stats.today", "今天") || "今天" },
                    { key: "yesterday", label: pluginApi?.tr("stats.yesterday", "昨天") || "昨天" },
                    { key: "week", label: pluginApi?.tr("stats.thisWeek", "本周") || "本周" },
                    { key: "month", label: pluginApi?.tr("stats.thisMonth", "本月") || "本月" },
                    { key: "all", label: pluginApi?.tr("stats.allTime", "全部") || "全部" }
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
                    text: (pluginApi?.tr("stats.totalKeypresses", "总按键次数") || "总按键次数") + ": " + totalCount.toLocaleString()
                    pointSize: Style.fontSizeM
                    color: Color.mOnSurface
                }

                NText {
                    text: (pluginApi?.tr("stats.mostUsedKey", "最常用按键") || "最常用按键") + ": " + getMostUsedKey()
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                }

                NText {
                    text: (pluginApi?.tr("stats.mostUsedShortcut", "最常用组合") || "最常用组合") + ": " + getMostUsedShortcut()
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                }
            }
        }

        // Top Keys Section
        NText {
            text: pluginApi?.tr("stats.topKeys", "最常用按键 TOP 20") || "最常用按键 TOP 20"
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
            text: pluginApi?.tr("stats.topShortcuts", "快捷键组合 TOP 20") || "快捷键组合 TOP 20"
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
            text: pluginApi?.tr("stats.clearStats", "清空统计数据") || "清空统计数据"
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
                text: pluginApi?.tr("stats.clearConfirm", "确定要清空所有统计数据吗？此操作不可恢复。") || "确定要清空所有统计数据吗？此操作不可恢复。"
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
                    text: pluginApi?.tr("cancel", "取消") || "取消"
                    onClicked: clearDialog.close()
                }

                NButton {
                    text: pluginApi?.tr("confirm", "确认") || "确认"
                    onClicked: {
                        KeyStats.clearAllStats();
                        loadStats();
                        clearDialog.close();
                    }
                }
            }
        }
    }
}
```

**Step 2: 提交**

```bash
git add modifier-keys/StatsTab.qml
git commit -m "feat(modifier-keys): add StatsTab.qml statistics panel component"
```

---

## Task 4: 重构 Panel.qml 为 Tab 容器

**Files:**
- Modify: `modifier-keys/Panel.qml`

**Step 1: 替换 Panel.qml 内容为 Tab 容器**

```qml
// Panel.qml - Modifier Keys Panel with Tabs
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    property int currentTab: 0  // 0: 帮助, 1: 统计

    readonly property var panelGeometry: panelContainer
    property real contentPreferredWidth: 320 * Style.uiScaleRatio
    property real contentPreferredHeight: 450 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            // Tab navigation
            RowLayout {
                id: tabBar
                spacing: 4
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: [
                        { text: "⌨️ " + (pluginApi?.tr("help", "帮助") || "帮助"), tab: 0 },
                        { text: "📊 " + (pluginApi?.tr("stats.title", "统计") || "统计"), tab: 1 }
                    ]

                    delegate: Rectangle {
                        width: tabText.implicitWidth + Style.marginM * 2
                        height: 32
                        color: currentTab === modelData.tab ? Color.mPrimary : "transparent"
                        radius: Style.radiusS
                        border.color: currentTab === modelData.tab ? Color.mPrimary : Color.mOutlineVariant
                        border.width: 1

                        NText {
                            id: tabText
                            anchors.centerIn: parent
                            text: modelData.text
                            pointSize: Style.fontSizeM
                            color: currentTab === modelData.tab ? Color.mOnPrimary : Color.mOnSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: currentTab = modelData.tab
                        }
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            // Tab content
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    sourceComponent: currentTab === 0 ? helpTabComponent : statsTabComponent
                }
            }
        }
    }

    Component {
        id: helpTabComponent
        HelpTab { pluginApi: root.pluginApi }
    }

    Component {
        id: statsTabComponent
        StatsTab { pluginApi: root.pluginApi }
    }
}
```

**Step 2: 提交**

```bash
git add modifier-keys/Panel.qml
git commit -m "feat(modifier-keys): refactor Panel.qml to tabbed container with Help and Stats tabs"
```

---

## Task 5: 修改 BarWidget.qml 添加统计采集

**Files:**
- Modify: `modifier-keys/BarWidget.qml`

**Step 1: 添加 KeyStats 导入**

在文件顶部添加：
```qml
import QtQuick.LocalStorage
import "KeyStats.js" as KeyStats
```

**Step 2: 添加属性和定时器**

在现有属性后添加：
```qml
// Statistics tracking
property string lastDate: ""

// Date change detection timer
Timer {
    id: dateCheckTimer
    interval: 60000
    running: true
    repeat: true
    onTriggered: {
        const today = Qt.formatDate(new Date(), "yyyy-MM-dd");
        if (today !== lastDate) {
            KeyStats.cleanupOldData();
            lastDate = today;
        }
    }
}

// Buffer flush timer
Timer {
    id: flushTimer
    interval: 30000
    running: true
    repeat: true
    onTriggered: KeyStats.flushBuffer()
}
```

**Step 3: 修改 Component.onCompleted**

```qml
Component.onCompleted: {
    Logger.d("Modifier Keys", "BarWidget loaded");
    KeyStats.openDatabase();
    lastDate = Qt.formatDate(new Date(), "yyyy-MM-dd");
}
```

**Step 4: 添加 Component.onDestruction**

```qml
Component.onDestruction: {
    KeyStats.flushBuffer();
}
```

**Step 5: 修改 parseKeyboardEvent 函数**

在 `parseKeyboardEvent` 函数末尾（处理普通按键的 `if (state)` 块内）添加统计记录：

```qml
function parseKeyboardEvent(line) {
    // ... 现有代码 ...

    // Normal key
    if (state) {
        addKey(keyName);
        
        // 记录统计
        const activeModifiers = [];
        if (superPressed) activeModifiers.push("Super");
        if (ctrlPressed) activeModifiers.push("Ctrl");
        if (altPressed) activeModifiers.push("Alt");
        if (shiftPressed) activeModifiers.push("Shift");
        
        KeyStats.recordKeyEvent(keyName, activeModifiers);
    } else {
        removeKey(keyName);
    }
}
```

**Step 6: 提交**

```bash
git add modifier-keys/BarWidget.qml
git commit -m "feat(modifier-keys): integrate KeyStats tracking in BarWidget"
```

---

## Task 6: 添加国际化翻译

**Files:**
- Modify: `modifier-keys/i18n/zh-CN.json`
- Modify: `modifier-keys/i18n/en.json`

**Step 1: 更新 zh-CN.json**

```json
{
  "title": "修饰键",
  "super": "Super (Win 键)",
  "alt": "Alt",
  "ctrl": "Ctrl",
  "shift": "Shift",
  "gestures": "手势",
  "motion": "移动",
  "click": "点击",
  "scroll": "滚动",
  "swipe3": "三指滑动",
  "swipe4": "四指滑动",
  "pinch": "缩放",
  "help": "帮助",
  "cancel": "取消",
  "confirm": "确认",
  "settings": {
    "modifier": {
      "label": "修饰键符号",
      "desc": "自定义修饰键显示符号（JSON 格式）",
      "json": "JSON",
      "reset": "重置",
      "copy": "复制",
      "useDefault": "使用默认"
    },
    "gesture": {
      "label": "手势符号",
      "desc": "自定义手势显示符号（JSON 格式）",
      "json": "JSON",
      "reset": "重置",
      "copy": "复制",
      "useDefault": "使用默认"
    },
    "modifierKeys": "修饰键",
    "gestureKeys": "手势键"
  },
  "stats": {
    "title": "统计",
    "today": "今天",
    "yesterday": "昨天",
    "thisWeek": "本周",
    "thisMonth": "本月",
    "allTime": "全部",
    "totalKeypresses": "总按键次数",
    "mostUsedKey": "最常用按键",
    "mostUsedShortcut": "最常用组合",
    "topKeys": "最常用按键 TOP 20",
    "topShortcuts": "快捷键组合 TOP 20",
    "clearStats": "清空统计数据",
    "clearConfirm": "确定要清空所有统计数据吗？此操作不可恢复。",
    "noData": "暂无数据"
  }
}
```

**Step 2: 更新 en.json**

```json
{
  "title": "Modifier Keys",
  "super": "Super (Win)",
  "alt": "Alt",
  "ctrl": "Ctrl",
  "shift": "Shift",
  "gestures": "Gestures",
  "motion": "Motion",
  "click": "Click",
  "scroll": "Scroll",
  "swipe3": "3-Finger Swipe",
  "swipe4": "4-Finger Swipe",
  "pinch": "Pinch",
  "help": "Help",
  "cancel": "Cancel",
  "confirm": "Confirm",
  "settings": {
    "modifier": {
      "label": "Modifier Key Symbols",
      "desc": "Customize modifier key display symbols (JSON format)",
      "json": "JSON",
      "reset": "Reset",
      "copy": "Copy",
      "useDefault": "Use Defaults"
    },
    "gesture": {
      "label": "Gesture Symbols",
      "desc": "Customize gesture display symbols (JSON format)",
      "json": "JSON",
      "reset": "Reset",
      "copy": "Copy",
      "useDefault": "Use Defaults"
    },
    "modifierKeys": "Modifier Keys",
    "gestureKeys": "Gesture Keys"
  },
  "stats": {
    "title": "Statistics",
    "today": "Today",
    "yesterday": "Yesterday",
    "thisWeek": "This Week",
    "thisMonth": "This Month",
    "allTime": "All Time",
    "totalKeypresses": "Total Keypresses",
    "mostUsedKey": "Most Used Key",
    "mostUsedShortcut": "Most Used Shortcut",
    "topKeys": "Top 20 Keys",
    "topShortcuts": "Top 20 Shortcuts",
    "clearStats": "Clear Statistics",
    "clearConfirm": "Are you sure you want to clear all statistics? This cannot be undone.",
    "noData": "No Data"
  }
}
```

**Step 3: 提交**

```bash
git add modifier-keys/i18n/zh-CN.json modifier-keys/i18n/en.json
git commit -m "feat(modifier-keys): add i18n translations for statistics feature"
```

---

## Task 7: 验证和测试

**Step 1: 验证文件完整性**

```bash
ls -la modifier-keys/
# 确认文件存在：
# - KeyStats.js
# - HelpTab.qml
# - StatsTab.qml
# - Panel.qml (已修改)
# - BarWidget.qml (已修改)
# - i18n/zh-CN.json (已修改)
# - i18n/en.json (已修改)
```

**Step 2: 部署测试**

```bash
./tools/deploy.sh
```

**Step 3: 功能测试清单**

- [ ] 打开 Panel，确认有两个 Tab（帮助、统计）
- [ ] 点击帮助 Tab，确认原有功能正常
- [ ] 点击统计 Tab，确认界面显示
- [ ] 按几个键，等待 30 秒，确认统计数据更新
- [ ] 切换时间范围（今天、昨天、本周等）
- [ ] 测试清空统计数据功能

**Step 4: 最终提交**

```bash
git add -A
git commit -m "feat(modifier-keys): complete statistics feature implementation"
```

---

## Final Wave: 验证检查点

### F1: 功能验证
- [ ] Panel 显示两个 Tab
- [ ] 帮助 Tab 功能正常
- [ ] 统计 Tab 显示数据
- [ ] 按键被正确记录
- [ ] 时间筛选工作正常
- [ ] 清空功能工作正常

### F2: 代码质量
- [ ] 无 QML 语法错误
- [ ] 无 JavaScript 错误
- [ ] 遵循现有代码风格

### F3: 国际化
- [ ] 中文翻译完整
- [ ] 英文翻译完整
- [ ] 翻译键正确引用

### F4: 文档
- [ ] README.md 已更新（如需要）
- [ ] 设计文档已更新
