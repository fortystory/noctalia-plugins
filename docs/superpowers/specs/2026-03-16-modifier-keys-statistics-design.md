# Modifier Keys 按键统计功能设计文档

**日期**: 2026-03-16
**状态**: 草稿
**作者**: Atlas (AI Assistant)

---

## 1. 概述

### 1.1 目标

为 `modifier-keys` 插件添加按键统计功能，追踪用户的键盘使用模式，提供可视化的统计数据展示。

### 1.2 功能范围

- **统计范围**: 全面统计所有按键及修饰键组合（如 Ctrl+C、Alt+Tab）
- **时间维度**: 今天、昨天、本周、本月、全部时间
- **展示内容**:
  - 总按键次数
  - TOP 20 最常用按键
  - TOP 20 快捷键组合
- **界面位置**: 现有 Panel.qml 中新增 Tab 页签
- **持久化**: 使用 SQLite (Qt Quick LocalStorage)

### 1.3 非目标

- 实时统计推送（不需要 WebSocket）
- 多设备同步
- 按键内容记录（仅统计按键事件，不记录输入内容）

---

## 2. 技术架构

### 2.1 技术栈

| 组件 | 技术 |
|------|------|
| 数据库 | SQLite (QtQuick.LocalStorage) |
| UI 框架 | Qt Quick 2.15 + Qt Quick Controls 2.15 |
| 数据采集 | libinput debug-events |
| 国际化 | JSON 翻译文件 |

### 2.2 数据库 Schema

```sql
-- 1. 原始事件表（仅保留当天）
CREATE TABLE IF NOT EXISTS key_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key_name TEXT NOT NULL,
    modifiers TEXT,
    shortcut TEXT,
    timestamp INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_events_timestamp ON key_events(timestamp);

-- 2. 每日统计表（永久存储）
CREATE TABLE IF NOT EXISTS key_stats_daily (
    date TEXT NOT NULL,
    stat_type TEXT NOT NULL,
    stat_key TEXT NOT NULL,
    count INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (date, stat_type, stat_key)
);

CREATE INDEX IF NOT EXISTS idx_daily_stat ON key_stats_daily(stat_type, stat_key);
CREATE INDEX IF NOT EXISTS idx_daily_date ON key_stats_daily(date);

-- 3. 每日总计数
CREATE TABLE IF NOT EXISTS daily_totals (
    date TEXT PRIMARY KEY,
    total_keypresses INTEGER NOT NULL DEFAULT 0
);
```

### 2.3 数据聚合流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  按键事件   │ ──► │  内存缓冲   │ ──► │ key_events  │
│  (实时)     │     │  (50次/30s) │     │  (当天)     │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼ 每5分钟
                                        ┌─────────────┐
                                        │ key_stats_  │
                                        │   daily     │
                                        └─────────────┘
```

**聚合规则**:
- 实时写入内存缓冲区
- 每 50 次按键 或 每 30 秒 批量写入 `key_events`
- 每 5 分钟 聚合当天数据到 `key_stats_daily`
- 每日午夜 清理超过 1 天的原始事件数据

---

## 3. 组件设计

### 3.1 文件结构

```
modifier-keys/
├── BarWidget.qml          # [修改] 添加统计采集逻辑
├── Panel.qml              # [修改] 改造为 Tab 面板容器
├── HelpTab.qml            # [新增] 原帮助内容独立组件
├── StatsTab.qml           # [新增] 统计 Tab 组件
├── KeyStats.js            # [新增] 数据库操作模块
├── i18n/
│   ├── en.json            # [修改] 添加统计翻译
│   └── zh-CN.json         # [修改] 添加统计翻译
└── manifest.json          # [无需修改]
```

### 3.2 KeyStats.js 模块

```javascript
// ==================== 常量定义 ====================

// 数据库名称（使用插件 ID 确保唯一性）
const DB_NAME = "modifier-keys-stats";
const DB_VERSION = "1.0";
const DB_DESCRIPTION = "Modifier Keys Statistics Database";
const DB_SIZE = 5 * 1024 * 1024;  // 5 MB

// 修饰键标准化顺序（按优先级排序）
const MODIFIER_ORDER = ["Super", "Ctrl", "Alt", "Shift"];

// ==================== 数据库连接 ====================

let _db = null;

function openDatabase() {
    if (_db) return _db;
    _db = LocalStorage.openDatabaseSync(DB_NAME, DB_VERSION, DB_DESCRIPTION, DB_SIZE);
    initDatabase(_db);
    return _db;
}

function initDatabase(db) {
    db.transaction(function(tx) {
        tx.executeSql('CREATE TABLE IF NOT EXISTS key_events (...)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS key_stats_daily (...)');
        tx.executeSql('CREATE TABLE IF NOT EXISTS daily_totals (...)');
    });
}

// ==================== 快捷键标准化 ====================

function normalizeShortcut(modifiers, keyName) {
    if (!modifiers || modifiers.length === 0) return null;
    
    // 按固定顺序排序修饰键
    const sorted = modifiers.slice().sort((a, b) => {
        return MODIFIER_ORDER.indexOf(a) - MODIFIER_ORDER.indexOf(b);
    });
    
    // 组合成快捷键字符串
    return sorted.join("+") + "+" + keyName;
}

// ==================== 按键名称标准化 ====================

function normalizeKeyName(rawKeyName) {
    // 移除 KEY_ 前缀
    let name = rawKeyName.replace(/^KEY_/, "");
    
    // 特殊键映射
    const keyMap = {
        "LEFTMETA": "Super", "RIGHTMETA": "Super",
        "LEFTALT": "Alt", "RIGHTALT": "Alt",
        "LEFTCTRL": "Ctrl", "RIGHTCTRL": "Ctrl",
        "LEFTSHIFT": "Shift", "RIGHTSHIFT": "Shift"
    };
    
    return keyMap[name.toUpperCase()] || name.toUpperCase();
}

// ==================== 时间范围查询 ====================

function getDateRangeCondition(range) {
    const now = new Date();
    const today = formatDate(now);
    
    switch(range) {
        case "today":
            return `date = '${today}'`;
        case "yesterday":
            const yesterday = formatDate(new Date(now - 86400000));
            return `date = '${yesterday}'`;
        case "week":
            // 本周 = 周一到今天
            const weekStart = getWeekStart(now);
            return `date >= '${formatDate(weekStart)}'`;
        case "month":
            // 本月 = 1日到今天
            const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
            return `date >= '${formatDate(monthStart)}'`;
        case "all":
            return "1=1";
        default:
            return `date = '${today}'`;
    }
}

function formatDate(date) {
    return date.toISOString().split('T')[0];  // YYYY-MM-DD
}

function getWeekStart(date) {
    const d = new Date(date);
    const day = d.getDay();
    const diff = d.getDate() - day + (day === 0 ? -6 : 1);  // 周一为一周开始
    return new Date(d.setDate(diff));
}

// ==================== 写入操作 ====================

let _buffer = [];
const BUFFER_SIZE = 50;
const FLUSH_INTERVAL = 30000;  // 30秒

function recordKeyEvent(keyName, modifiers, shortcut) {
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
    const today = formatDate(new Date());
    
    db.transaction(function(tx) {
        for (const event of _buffer) {
            // 写入原始事件
            tx.executeSql(
                'INSERT INTO key_events (key_name, modifiers, shortcut, timestamp) VALUES (?, ?, ?, ?)',
                [event.keyName, event.modifiers, event.shortcut, event.timestamp]
            );
            
            // 更新每日统计
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
            
            // 更新每日总数
            tx.executeSql(
                'INSERT OR REPLACE INTO daily_totals (date, total_keypresses) VALUES (?, COALESCE((SELECT total_keypresses FROM daily_totals WHERE date=?), 0) + 1)',
                [today, today]
            );
        }
    });
    
    _buffer = [];
}

// ==================== 生命周期管理 ====================

// 在 BarWidget.qml 中调用
function onPluginDestroy() {
    flushBuffer();  // 插件卸载前刷新缓冲区
}

// ==================== 查询操作 ====================

function getTotalCount(dateRange) {
    const db = openDatabase();
    const condition = getDateRangeCondition(dateRange);
    let result = 0;
    
    db.readTransaction(function(tx) {
        const rs = tx.executeSql(`SELECT SUM(total_keypresses) as total FROM daily_totals WHERE ${condition}`);
        if (rs.rows.length > 0) {
            result = rs.rows.item(0).total || 0;
        }
    });
    
    return result;
}

function getTopKeys(dateRange, limit) {
    const db = openDatabase();
    const condition = getDateRangeCondition(dateRange);
    const results = [];
    
    db.readTransaction(function(tx) {
        const rs = tx.executeSql(`SELECT stat_key, SUM(count) as total FROM key_stats_daily WHERE stat_type='key' AND ${condition} GROUP BY stat_key ORDER BY total DESC LIMIT ?`, [limit]);
        for (let i = 0; i < rs.rows.length; i++) {
            results.push(rs.rows.item(i));
        }
    });
    
    return results;
}

function getTopShortcuts(dateRange, limit) {
    const db = openDatabase();
    const condition = getDateRangeCondition(dateRange);
    const results = [];
    
    db.readTransaction(function(tx) {
        const rs = tx.executeSql(`SELECT stat_key, SUM(count) as total FROM key_stats_daily WHERE stat_type='shortcut' AND ${condition} GROUP BY stat_key ORDER BY total DESC LIMIT ?`, [limit]);
        for (let i = 0; i < rs.rows.length; i++) {
            results.push(rs.rows.item(i));
        }
    });
    
    return results;
}

// ==================== 数据清理 ====================

function cleanupOldData() {
    const db = openDatabase();
    const yesterday = formatDate(new Date(Date.now() - 86400000));
    
    db.transaction(function(tx) {
        // 清理超过1天的原始事件
        tx.executeSql('DELETE FROM key_events WHERE date(timestamp/1000, "unixepoch") < ?', [yesterday]);
    });
}

function clearAllStats() {
    const db = openDatabase();
    db.transaction(function(tx) {
        tx.executeSql('DELETE FROM key_events');
        tx.executeSql('DELETE FROM key_stats_daily');
        tx.executeSql('DELETE FROM daily_totals');
    });
    _buffer = [];
}
```

### 3.3 BarWidget.qml 修改

在 `parseKeyboardEvent()` 函数中添加统计记录：

```javascript
import "KeyStats.js" as KeyStats

// 添加到现有属性
property var lastDate: ""  // 用于检测日期变化

// 在 Component.onCompleted 中初始化
Component.onCompleted: {
    Logger.d("Modifier Keys", "BarWidget loaded");
    KeyStats.openDatabase();  // 初始化数据库
    lastDate = Qt.formatDate(new Date(), "yyyy-MM-dd");
}

// 添加生命周期处理
Component.onDestruction: {
    KeyStats.flushBuffer();  // 确保退出前保存数据
}

// 日期变化检测（每分钟检查一次）
Timer {
    id: dateCheckTimer
    interval: 60000
    running: true
    repeat: true
    onTriggered: {
        const today = Qt.formatDate(new Date(), "yyyy-MM-dd");
        if (today !== lastDate) {
            KeyStats.cleanupOldData();  // 清理旧数据
            lastDate = today;
        }
    }
}

// 定期刷新缓冲区
Timer {
    id: flushTimer
    interval: 30000  // 30秒
    running: true
    repeat: true
    onTriggered: KeyStats.flushBuffer()
}

function parseKeyboardEvent(line) {
    // ... 现有逻辑 ...

    // 记录统计（仅记录按下事件）
    if (isPressed) {
        // 收集当前激活的修饰键
        const activeModifiers = [];
        if (superPressed) activeModifiers.push("Super");
        if (ctrlPressed) activeModifiers.push("Ctrl");
        if (altPressed) activeModifiers.push("Alt");
        if (shiftPressed) activeModifiers.push("Shift");
        
        KeyStats.recordKeyEvent(keyName, activeModifiers);
    }
}
```

### 3.4 Panel.qml 重构

改造为 Tab 面板容器。**注意**：Noctalia Shell 使用 Quickshell 框架，没有内置 TabBar/StackLayout 组件，需要自定义实现：

```qml
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "HelpTab.qml"
import "StatsTab.qml"

Item {
    id: root
    property var pluginApi: null
    property int currentTab: 0  // 0: 帮助, 1: 统计

    // Tab 导航按钮（自定义实现）
    RowLayout {
        id: tabBar
        spacing: 0
        
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
                
                NText {
                    id: tabText
                    anchors.centerIn: parent
                    text: modelData.text
                    color: currentTab === modelData.tab ? Color.mOnPrimary : Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeM
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: currentTab = modelData.tab
                }
            }
        }
    }

    // Tab 内容（使用 Loader 按需加载）
    ColumnLayout {
        anchors.top: tabBar.bottom
        anchors.topMargin: Style.marginS
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        
        Loader {
            id: contentLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: currentTab === 0 ? helpTabComponent : statsTabComponent
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

### 3.5 StatsTab.qml 组件

```qml
ColumnLayout {
    // 时间选择器
    TabBar { today, yesterday, week, month, all }

    // 汇总卡片
    StatsSummaryCard { }

    // TOP 20 按键列表
    TopKeysList { model: topKeysModel }

    // TOP 20 快捷键列表
    TopShortcutsList { model: topShortcutsModel }

    // 清空按钮
    NButton { text: "清空统计数据"; onClicked: confirmClear() }
}
```

---

## 4. UI 设计

### 4.1 布局

```
┌─────────────────────────────────────┐
│  [⌨️ 修饰键]  [📊 统计]              │  Tab 导航
├─────────────────────────────────────┤
│                                     │
│  [今天] [昨天] [本周] [本月] [全部]  │  时间筛选
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 总按键: 12,345              │   │  汇总卡片
│  │ 最常用: Space (1,234)       │   │
│  │ 最常用组合: Ctrl+C (567)    │   │
│  └─────────────────────────────┘   │
│                                     │
│  最常用按键 TOP 20                  │
│  ┌─────────────────────────────┐   │
│  │ 1. Space      ████████ 1234 │   │  带进度条列表
│  │ 2. Enter      ██████    890 │   │
│  │ ...                         │   │
│  └─────────────────────────────┘   │
│                                     │
│  快捷键组合 TOP 20                  │
│  ┌─────────────────────────────┐   │
│  │ 1. Ctrl+C     ██████    567 │   │
│  │ ...                         │   │
│  └─────────────────────────────┘   │
│                                     │
│  [🗑️ 清空统计数据]                  │  危险操作
└─────────────────────────────────────┘
```

### 4.2 交互

| 操作 | 行为 |
|------|------|
| 点击 Tab | 切换修饰键帮助 / 统计视图 |
| 点击时间筛选 | 刷新统计数据为对应时间范围 |
| 点击清空按钮 | 弹出确认对话框，确认后清空所有数据 |

### 4.3 视觉规范

- 使用 Noctalia Shell 现有主题系统 (Color.m*, Style.*)
- 进度条使用 `Color.mPrimary` 渐变
- 列表项使用 `Style.capsuleColor` 背景
- 危险操作按钮使用 `Color.mError` 颜色

---

## 5. 数据流

### 5.1 写入流程

```
用户按键
    │
    ▼
BarWidget.parseKeyboardEvent()
    │
    ▼
KeyStats.recordKeyEvent() ──► 内存缓冲区
    │
    ▼ (50次 或 30秒)
KeyStats.flushBuffer() ──► key_events 表
    │
    ▼ (每5分钟)
KeyStats.aggregateToday() ──► key_stats_daily 表
```

### 5.2 查询流程

```
用户选择时间范围
    │
    ▼
StatsTab.loadStats(dateRange)
    │
    ▼
KeyStats.getTotalCount(dateRange) ──► 汇总卡片
KeyStats.getTopKeys(dateRange, 20) ──► 按键列表
KeyStats.getTopShortcuts(dateRange, 20) ──► 快捷键列表
```

---

## 6. 国际化

### 6.1 新增翻译键

```json
{
  "stats": {
    "title": "按键统计",
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

---

## 7. 性能考虑

### 7.1 写入优化

- 内存缓冲区批量写入，减少数据库事务
- 每 50 次按键 或 每 30 秒 刷新一次
- 预估：每天 10,000 次按键 ≈ 200 次数据库写入

### 7.2 查询优化

- 复合索引 `(stat_type, stat_key)` 加速 TOP N 查询
- `daily_totals` 表避免聚合计算
- 查询时间复杂度：O(n log n) for TOP N

### 7.3 存储估算

| 数据类型 | 每条记录大小 | 每天 10k 按键 |
|----------|-------------|---------------|
| 原始事件 | ~50 bytes | ~500 KB (当天) |
| 每日统计 | ~30 bytes | ~30 KB (永久) |
| 每月总计 | - | ~1 MB |

---

## 8. 错误处理

### 8.1 数据库错误

```javascript
try {
    db.transaction(function(tx) { ... });
} catch (e) {
    Logger.e("KeyStats", "Database error:", e);
    // 降级：禁用统计功能，保持插件其他功能正常
}
```

### 8.2 数据迁移

首次启动时检测数据库版本，执行必要迁移：

```javascript
function migrateDatabase(db) {
    if (db.version === "") {
        // 新安装，创建表
        createTables(db);
        db.changeVersion("", "1.0");
    }
}
```

---

## 9. 测试计划

### 9.1 单元测试

- [ ] KeyStats.recordKeyEvent() 正确记录按键
- [ ] KeyStats.getTopKeys() 返回正确的 TOP N
- [ ] 快捷键标准化逻辑（Ctrl+Alt vs Alt+Ctrl）

### 9.2 集成测试

- [ ] 按键事件正确触发数据库写入
- [ ] 时间筛选正确过滤数据
- [ ] 清空功能完全清除数据

### 9.3 性能测试

- [ ] 1000 次/秒按键不阻塞 UI
- [ ] 查询 TOP 20 响应时间 < 100ms
- [ ] 数据库文件大小增长合理

---

## 10. 实施计划

### Phase 1: 数据层 (1-2 天)
- [ ] 创建 KeyStats.js 模块
- [ ] 实现数据库初始化和 Schema
- [ ] 实现写入和查询函数

### Phase 2: 采集层 (0.5 天)
- [ ] 修改 BarWidget.qml 添加统计采集
- [ ] 实现批量写入缓冲区

### Phase 3: UI 层 (1-2 天)
- [ ] 创建 HelpTab.qml（重构现有内容）
- [ ] 创建 StatsTab.qml
- [ ] 改造 Panel.qml 为 Tab 容器

### Phase 4: 完善和测试 (1 天)
- [ ] 添加国际化翻译
- [ ] 端到端测试
- [ ] 性能优化

**预估总工时**: 3-5 天

---

## 11. 风险和缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 数据库损坏 | 丢失历史数据 | 定期备份，错误时重建 |
| 高频按键导致性能问题 | UI 卡顿 | 批量写入，异步聚合 |
| 存储空间增长过快 | 磁盘占用 | 自动清理旧数据 |

---

## 12. 未来扩展

- [ ] 按应用分类统计（需要窗口管理器集成）
- [ ] 导出统计数据为 CSV/JSON
- [ ] 按键热力图可视化
- [ ] 设置数据保留策略（保留 N 天/周/月）

---

## 附录 A: 规格审查问题修复记录

### 审查轮次 1 发现的问题及修复

| # | 问题 | 修复方式 |
|---|------|----------|
| 1 | 时间范围定义模糊 | 添加 `getDateRangeCondition()` 函数，明确本周=周一到今天，本月=1日到今天 |
| 2 | 快捷键检测逻辑缺失 | 在 BarWidget.qml 修改部分添加修饰键收集逻辑 |
| 3 | 快捷键标准化算法未定义 | 添加 `normalizeShortcut()` 函数，修饰键按 Super>Ctrl>Alt>Shift 顺序排序 |
| 4 | 数据库文件位置未指定 | 添加 `DB_NAME = "modifier-keys-stats"` 常量定义 |
| 5 | 应用生命周期处理缺失 | 添加 `Component.onDestruction` 调用 `flushBuffer()` |
| 6 | 按键名称存储规范不清 | 添加 `normalizeKeyName()` 函数，移除 KEY_ 前缀，标准化修饰键名称 |
| 7 | 每日午夜清理触发器缺失 | 添加 `dateCheckTimer` 每分钟检查日期变化，触发 `cleanupOldData()` |
| 8 | TabBar 组件未明确 | 重写 Panel.qml 使用自定义 Tab 导航，不依赖 Qt Quick Controls TabBar |
