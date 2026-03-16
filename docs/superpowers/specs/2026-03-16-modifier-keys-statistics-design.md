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
// 数据库连接
function initDatabase() { ... }
function openDatabase() { ... }

// 写入操作
function recordKeyEvent(keyName, modifiers, shortcut) { ... }
function flushBuffer() { ... }

// 聚合操作
function aggregateToday() { ... }
function cleanupOldData() { ... }

// 查询操作
function getTotalCount(dateRange) { ... }
function getTopKeys(dateRange, limit) { ... }
function getTopShortcuts(dateRange, limit) { ... }

// 管理操作
function clearAllStats() { ... }
```

### 3.3 BarWidget.qml 修改

在 `parseKeyboardEvent()` 函数中添加统计记录：

```javascript
function parseKeyboardEvent(line) {
    // ... 现有逻辑 ...

    // 记录统计（仅记录按下事件）
    if (isPressed) {
        KeyStats.recordKeyEvent(keyName, activeModifiers, shortcut);
    }
}
```

### 3.4 Panel.qml 重构

改造为 Tab 面板容器：

```qml
RowLayout {
    // Tab 导航
    TabBar { ... }

    // Tab 内容
    StackLayout {
        HelpTab { }      // 原帮助内容
        StatsTab { }     // 新统计内容
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
