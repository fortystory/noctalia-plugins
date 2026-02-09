// SettingsManager.qml - 设置管理组件
// 封装Noctalia设置API的读写操作，提供验证和默认值处理
import QtQuick 2.15

QtObject {
    id: settingsManager

    // 必需的API引用
    property var pluginApi: null

    // 默认设置值
    property string defaultTheme: "system"
    property int defaultToolIndex: 0
    property bool defaultWindowPositionMemory: true

    // 读取设置值（带验证和默认值）
    function getValue(key, defaultValue) {
        if (!pluginApi || !pluginApi.settings) {
            console.warn("Settings API not available, using default:", defaultValue)
            return defaultValue
        }

        var value = pluginApi.settings.value(key, defaultValue)
        return validateValue(key, value, defaultValue)
    }

    // 保存设置值
    function setValue(key, value) {
        if (pluginApi && pluginApi.settings) {
            pluginApi.settings.setValue(key, value)
            console.log("Setting saved:", key, "=", value)
            return true
        }
        console.error("Failed to save setting:", key, "- API unavailable")
        return false
    }

    // 验证设置值有效性
    function validateValue(key, value, defaultValue) {
        switch(key) {
            case "preferences/theme":
                if (["system", "light", "dark"].includes(value)) {
                    return value
                }
                console.warn("Invalid theme value:", value, "- using default:", defaultValue)
                return defaultValue

            case "preferences/defaultTool":
                var intValue = parseInt(value, 10)
                if (!isNaN(intValue) && intValue >= 0) {
                    return intValue
                }
                console.warn("Invalid tool index:", value, "- using default:", defaultValue)
                return defaultValue

            case "preferences/windowPositionMemory":
                if (typeof value === "boolean") {
                    return value
                }
                if (value === "true" || value === "false") {
                    return value === "true"
                }
                if (value === 1 || value === 0) {
                    return value === 1
                }
                console.warn("Invalid boolean value:", value, "- using default:", defaultValue)
                return defaultValue

            default:
                console.warn("Unknown setting key:", key)
                return defaultValue
        }
    }

    // 批量保存所有设置
    function saveAll(themePreference, defaultToolIndex, windowPositionMemory) {
        var success = true

        success = success && setValue("preferences/theme", themePreference)
        success = success && setValue("preferences/defaultTool", defaultToolIndex)
        success = success && setValue("preferences/windowPositionMemory", windowPositionMemory)

        if (success) {
            console.log("All settings saved successfully")
        } else {
            console.error("Failed to save some settings")
        }

        return success
    }

    // 加载所有设置到对象
    function loadAll() {
        return {
            themePreference: getValue("preferences/theme", defaultTheme),
            defaultToolIndex: getValue("preferences/defaultTool", defaultToolIndex),
            windowPositionMemory: getValue("preferences/windowPositionMemory", defaultWindowPositionMemory)
        }
    }

    // 检查设置API可用性
    function isApiAvailable() {
        return pluginApi && pluginApi.settings
    }
}