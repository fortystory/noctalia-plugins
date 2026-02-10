// SettingsContent.qml - 设置内容布局组件
// 包含所有设置项的垂直布局，带标签和输入控件
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ColumnLayout {
    id: settingsContent

    // 属性定义
    property var theme: Theme {}
    property var settingsManager: null
    property var toolModel: null

    // 设置值属性
    property string themePreference: "system"
    property int defaultToolIndex: 0
    property bool windowPositionMemory: true

    // 间距配置
    spacing: theme.spacingLarge

    // 主题设置组
    GroupBox {
        id: themeGroup
        Layout.fillWidth: true
        title: qsTr("Appearance")
        background: Rectangle {
            color: theme.surfaceColor
            border.color: theme.borderColor
            border.width: theme.borderWidth
            radius: theme.borderRadius
        }
        label: Label {
            text: themeGroup.title
            font.pixelSize: theme.fontSizeLarge
            font.bold: true
            color: theme.textColor
            padding: 5
        }

        ColumnLayout {
            spacing: theme.spacingMedium
            width: parent.width

            // 主题偏好设置
            RowLayout {
                spacing: theme.spacingLarge

                Label {
                    text: qsTr("Theme preference:")
                    font.pixelSize: theme.fontSizeNormal
                    color: theme.textColor
                    Layout.preferredWidth: 120
                }

                ComboBox {
                    id: themeComboBox
                    Layout.fillWidth: true
                    model: [
                        { value: "system", text: qsTr("Follow system") },
                        { value: "light", text: qsTr("Light theme") },
                        { value: "dark", text: qsTr("Dark theme") }
                    ]

                    textRole: "text"
                    valueRole: "value"

                    currentIndex: {
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].value === themePreference) {
                                return i
                            }
                        }
                        return 0
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0) {
                            themePreference = model[currentIndex].value
                        }
                    }

                    background: Rectangle {
                        color: theme.backgroundColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                        radius: theme.borderRadius
                    }

                    contentItem: Text {
                        text: themeComboBox.displayText
                        font.pixelSize: theme.fontSizeNormal
                        color: theme.textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }

                    ToolTip {
                        visible: themeComboBox.hovered
                        text: qsTr("Select plugin theme appearance")
                        delay: 300
                    }
                }
            }

            // 主题设置提示
            Text {
                text: qsTr("Theme changes will take effect after restarting the plugin")
                font.pixelSize: theme.fontSizeSmall
                color: theme.secondaryColor
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // 默认工具设置组
    GroupBox {
        id: toolGroup
        Layout.fillWidth: true
        title: qsTr("Startup settings")
        background: Rectangle {
            color: theme.surfaceColor
            border.color: theme.borderColor
            border.width: theme.borderWidth
            radius: theme.borderRadius
        }
        label: Label {
            text: toolGroup.title
            font.pixelSize: theme.fontSizeLarge
            font.bold: true
            color: theme.textColor
            padding: 5
        }

        ColumnLayout {
            spacing: theme.spacingMedium
            width: parent.width

            // 默认启动工具设置
            RowLayout {
                spacing: theme.spacingLarge

                Label {
                    text: qsTr("Default startup tool:")
                    font.pixelSize: theme.fontSizeNormal
                    color: theme.textColor
                    Layout.preferredWidth: 120
                }

                ComboBox {
                    id: toolComboBox
                    Layout.fillWidth: true

                    // 从工具模型动态加载
                    model: toolModel ? toolModel : []
                    textRole: "name"

                    currentIndex: defaultToolIndex

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0) {
                            defaultToolIndex = currentIndex
                        }
                    }

                    background: Rectangle {
                        color: theme.backgroundColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                        radius: theme.borderRadius
                    }

                    contentItem: Text {
                        text: toolComboBox.displayText
                        font.pixelSize: theme.fontSizeNormal
                        color: theme.textColor
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }

                    ToolTip {
                        visible: toolComboBox.hovered
                        text: qsTr("Select default tool when plugin starts")
                        delay: 300
                    }
                }
            }

            // 工具设置提示
            Text {
                text: qsTr("Default tool will take effect after restarting the plugin")
                font.pixelSize: theme.fontSizeSmall
                color: theme.secondaryColor
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // 窗口设置组
    GroupBox {
        id: windowGroup
        Layout.fillWidth: true
        title: qsTr("Window behavior")
        background: Rectangle {
            color: theme.surfaceColor
            border.color: theme.borderColor
            border.width: theme.borderWidth
            radius: theme.borderRadius
        }
        label: Label {
            text: windowGroup.title
            font.pixelSize: theme.fontSizeLarge
            font.bold: true
            color: theme.textColor
            padding: 5
        }

        ColumnLayout {
            spacing: theme.spacingMedium
            width: parent.width

            // 窗口位置记忆开关
            RowLayout {
                spacing: theme.spacingLarge

                Label {
                    text: qsTr("Window position memory:")
                    font.pixelSize: theme.fontSizeNormal
                    color: theme.textColor
                    Layout.preferredWidth: 120
                }

                Switch {
                    id: positionSwitch
                    checked: windowPositionMemory

                    onCheckedChanged: {
                        windowPositionMemory = checked
                    }

                    background: Rectangle {
                        implicitWidth: 48
                        implicitHeight: 24
                        radius: 12
                        color: positionSwitch.checked ? theme.primaryColor : theme.surfaceColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                    }

                    indicator: Rectangle {
                        x: positionSwitch.checked ? parent.width - width : 0
                        y: (parent.height - height) / 2
                        width: 24
                        height: 24
                        radius: 12
                        color: theme.backgroundColor
                        border.color: theme.borderColor
                        border.width: theme.borderWidth
                    }

                    ToolTip {
                        visible: positionSwitch.hovered
                        text: qsTr("Remember window position and size when closed")
                        delay: 300
                    }
                }

                Label {
                    text: positionSwitch.checked ? qsTr("Enabled") : qsTr("Disabled")
                    font.pixelSize: theme.fontSizeNormal
                    color: positionSwitch.checked ? theme.primaryColor : theme.textColor
                }
            }

            // 窗口设置提示
            Text {
                text: qsTr("Disabling position memory will clear existing window position storage")
                font.pixelSize: theme.fontSizeSmall
                color: theme.secondaryColor
                font.italic: true
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    // API状态显示（当API不可用时）
    Rectangle {
        visible: settingsManager && !settingsManager.isApiAvailable()
        Layout.fillWidth: true
        height: 40
        radius: theme.borderRadius
        color: theme.warningColor
        opacity: 0.9

        RowLayout {
            anchors.fill: parent
            anchors.margins: theme.spacingSmall

            Text {
                text: "⚠️"
                font.pixelSize: 16
                color: "white"
                Layout.alignment: Qt.AlignCenter
            }

            Text {
                text: qsTr("Settings API unavailable, changes will not persist")
                font.pixelSize: theme.fontSizeSmall
                color: "white"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    // 初始化函数
    function initialize(manager, model) {
        settingsManager = manager
        toolModel = model

        if (settingsManager) {
            var settings = settingsManager.loadAll()
            themePreference = settings.themePreference
            defaultToolIndex = settings.defaultToolIndex
            windowPositionMemory = settings.windowPositionMemory
        }
    }

    // 保存设置函数
    function saveSettings() {
        if (settingsManager) {
            return settingsManager.saveAll(themePreference, defaultToolIndex, windowPositionMemory)
        }
        return false
    }

    // 重置为默认值
    function resetToDefaults() {
        themePreference = settingsManager ? settingsManager.defaultTheme : "system"
        defaultToolIndex = settingsManager ? settingsManager.defaultToolIndex : 0
        windowPositionMemory = settingsManager ? settingsManager.defaultWindowPositionMemory : true
    }
}