// Theme.qml - 主题定义和工具函数
import QtQuick 2.15
import QtGraphicalEffects 1.15

QtObject {
    id: theme

    // 颜色定义
    property color primaryColor: "#3b82f6"
    property color secondaryColor: "#64748b"
    property color successColor: "#10b981"
    property color warningColor: "#f59e0b"
    property color errorColor: "#ef4444"
    property color backgroundColor: "#ffffff"
    property color surfaceColor: "#f8fafc"
    property color textColor: "#1e293b"
    property color borderColor: "#e2e8f0"

    // 暗色主题颜色
    property color darkBackgroundColor: "#1e293b"
    property color darkSurfaceColor: "#334155"
    property color darkTextColor: "#f1f5f9"
    property color darkBorderColor: "#475569"

    // 阴影颜色
    property color shadowColor: "#1f2937"
    property color shadowColorTransparent: shadowColor + "20"  // 带透明度

    // 尺寸定义
    property int spacingSmall: 5
    property int spacingMedium: 10
    property int spacingLarge: 15
    property int borderRadius: 6
    property int borderWidth: 1
    property int shadowRadius: 4

    // 字体定义
    property string fontFamily: "Inter, system-ui, sans-serif"
    property int fontSizeSmall: 11
    property int fontSizeNormal: 13
    property int fontSizeLarge: 15
    property int fontSizeTitle: 17

    // 工具函数：获取合适的颜色
    function getColor(type, isDark) {
        if (isDark) {
            switch(type) {
                case "background": return darkBackgroundColor
                case "surface": return darkSurfaceColor
                case "text": return darkTextColor
                case "border": return darkBorderColor
                default: return type
            }
        }
        // 亮色主题颜色映射
        switch(type) {
            case "background": return backgroundColor
            case "surface": return surfaceColor
            case "text": return textColor
            case "border": return borderColor
            default: return type
        }
    }

    // 工具函数：应用阴影
    function applyShadow(item) {
        item.layer.enabled = true
        item.layer.effect = DropShadow {
            horizontalOffset: 0
            verticalOffset: 2
            radius: shadowRadius
            samples: 17
            color: "#1f2937" + "20" // 带透明度
        }
    }

    // 工具函数：创建圆角矩形
    function createRoundedRect(parent, color) {
        return Qt.createQmlObject(`
            import QtQuick 2.15
            Rectangle {
                radius: ${borderRadius}
                color: "${color}"
                border.width: ${borderWidth}
                border.color: "${borderColor}"
            }
        `, parent)
    }
}