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

// ==================== 数据库连接 ====================

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
        tx.executeSql('CREATE TABLE IF NOT EXISTS key_events (id INTEGER PRIMARY KEY AUTOINCREMENT, key_name TEXT NOT NULL, modifiers TEXT, shortcut TEXT, timestamp INTEGER NOT NULL)');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_events_timestamp ON key_events(timestamp)');
        
        // 每日统计表（永久存储）
        tx.executeSql('CREATE TABLE IF NOT EXISTS key_stats_daily (date TEXT NOT NULL, stat_type TEXT NOT NULL, stat_key TEXT NOT NULL, count INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (date, stat_type, stat_key))');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_daily_stat ON key_stats_daily(stat_type, stat_key)');
        tx.executeSql('CREATE INDEX IF NOT EXISTS idx_daily_date ON key_stats_daily(date)');
        
        // 每日总计数
        tx.executeSql('CREATE TABLE IF NOT EXISTS daily_totals (date TEXT PRIMARY KEY, total_keypresses INTEGER NOT NULL DEFAULT 0)');
    });
}

// ==================== 快捷键标准化 ====================

function normalizeShortcut(modifiers, keyName) {
    if (!modifiers || modifiers.length === 0) return null;
    
    const sorted = modifiers.slice().sort((a, b) => {
        return MODIFIER_ORDER.indexOf(a) - MODIFIER_ORDER.indexOf(b);
    });
    
    return sorted.join("+") + "+" + keyName;
}

// ==================== 按键名称标准化 ====================

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

// ==================== 时间范围查询 ====================

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
            return "date = '" + today + "'";
        case "yesterday":
            var yesterday = formatDate(new Date(now.getTime() - 86400000));
            return "date = '" + yesterday + "'";
        case "week":
            var weekStart = getWeekStart(now);
            return "date >= '" + formatDate(weekStart) + "'";
        case "month":
            var monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
            return "date >= '" + formatDate(monthStart) + "'";
        case "all":
            return "1=1";
        default:
            return "date = '" + today + "'";
    }
}

// ==================== 写入操作 ====================

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
            for (var i = 0; i < eventsToFlush.length; i++) {
                var event = eventsToFlush[i];
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

// ==================== 查询操作 ====================

function getTotalCount(dateRange) {
    const db = openDatabase();
    if (!db) return 0;
    
    const condition = getDateRangeCondition(dateRange);
    var result = 0;
    
    try {
        db.readTransaction(function(tx) {
            var rs = tx.executeSql("SELECT SUM(total_keypresses) as total FROM daily_totals WHERE " + condition);
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
    var results = [];
    
    try {
        db.readTransaction(function(tx) {
            var rs = tx.executeSql(
                "SELECT stat_key, SUM(count) as total FROM key_stats_daily WHERE stat_type='key' AND " + condition + " GROUP BY stat_key ORDER BY total DESC LIMIT ?",
                [limit]
            );
            for (var i = 0; i < rs.rows.length; i++) {
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
    var results = [];
    
    try {
        db.readTransaction(function(tx) {
            var rs = tx.executeSql(
                "SELECT stat_key, SUM(count) as total FROM key_stats_daily WHERE stat_type='shortcut' AND " + condition + " GROUP BY stat_key ORDER BY total DESC LIMIT ?",
                [limit]
            );
            for (var i = 0; i < rs.rows.length; i++) {
                results.push(rs.rows.item(i));
            }
        });
    } catch (e) {
        console.error("KeyStats: Failed to get top shortcuts:", e);
    }
    
    return results;
}

// ==================== 数据清理 ====================

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
