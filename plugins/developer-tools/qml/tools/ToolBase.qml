// ToolBase.qml - 所有工具页面的基类
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: toolBase

    // 公共属性
    property string toolName: ""
    property string toolIcon: ""
    property string toolDescription: ""
    property bool isActive: false

    // 配置属性
    property int spacing: 10
    property int margin: 15
    property int fontSize: 12
    property int titleFontSize: 14

    // 信号定义
    signal copyToClipboard(string text)
    signal showMessage(string message, string type)
    signal toolInitialized()
    signal toolDeactivated()

    // 初始化方法
    function initialize() {
        console.log("Initializing tool:", toolName)
        toolInitialized()
    }

    // 清理方法
    function cleanup() {
        console.log("Cleaning up tool:", toolName)
        toolDeactivated()
    }

    // 验证输入方法（子类可重写）
    function validateInput(input) {
        return input !== ""
    }

    // 格式化时间戳（工具方法）
    function formatTimestamp(timestamp, isMilliseconds) {
        if (isMilliseconds) {
            return new Date(timestamp).toLocaleString()
        } else {
            return new Date(timestamp * 1000).toLocaleString()
        }
    }

    // 获取当前时间戳（工具方法）
    function getCurrentTimestamp(isMilliseconds) {
        const now = Date.now()
        return isMilliseconds ? now : Math.floor(now / 1000)
    }

    // 组件加载完成
    Component.onCompleted: {
        console.log("Tool component loaded:", toolName)
    }

    // 组件销毁
    Component.onDestruction: {
        cleanup()
    }
}