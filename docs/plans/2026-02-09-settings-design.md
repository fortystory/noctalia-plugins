# Noctalia开发者工具插件 - 设置功能设计文档

## 概述

为Noctalia开发者工具插件添加基本设置功能，包括主题偏好、默认启动工具和窗口位置记忆配置。设置功能将实现为简洁的模态对话框，与现有UI风格保持一致，使用现有Noctalia API进行数据持久化。

## 设计决策总结

### 1. 设置功能范围
基于用户选择，实现**基本设置**功能，包括：
- **主题偏好**：跟随系统/浅色/深色主题选择
- **默认启动工具**：插件启动时默认打开的工具
- **窗口位置记忆**：是否记住窗口关闭时的位置和大小

### 2. UI设计选择
- **对话框类型**：简洁模态对话框，与现有侧边栏风格一致
- **布局方式**：垂直排列的设置项，每个设置项包含标签和输入控件
- **按钮区域**：确定、取消、应用三个标准按钮

### 3. 架构设计
- **组件化设计**：独立设置对话框组件，通过信号/槽与主窗口通信
- **数据持久化**：复用现有Noctalia `pluginApi.settings` API
- **错误处理**：边界情况检查和用户友好提示

## 详细设计

### 1. 架构和组件结构

#### 1.1 新组件
1. **SettingsDialog.qml** - 模态对话框容器
   - 对话框窗口属性和样式
   - 背景遮罩和模态行为
   - 按钮区域布局

2. **SettingsContent.qml** - 设置内容布局
   - 设置项垂直排列
   - 每个设置项的标签和控件
   - 设置项分组和分隔线

3. **SettingsManager**（QML对象） - 设置管理逻辑
   - 封装`pluginApi.settings`交互
   - 设置值读写和验证
   - 默认值管理

#### 1.2 现有组件修改
1. **Sidebar.qml** - 修改设置按钮点击处理
   - 触发显示设置对话框
   - 传递必要的上下文（主题引用、工具模型）

2. **main.qml** - 集成设置功能
   - 创建设置对话框实例
   - 处理设置保存和应用
   - 协调设置与现有功能

### 2. 设置项的具体配置

#### 2.1 主题偏好设置
- **设置键**: `"preferences/theme"` (字符串)
- **选项值**:
  - `"system"` - 跟随系统（默认）
  - `"light"` - 浅色主题
  - `"dark"` - 深色主题
- **UI控件**: 下拉菜单（ComboBox）
- **行为**: 重启插件后生效，对话框显示提示信息

#### 2.2 默认启动工具设置
- **设置键**: `"preferences/defaultTool"` (整数)
- **选项值**: 工具索引（0=时间戳，1=JSON）
- **UI控件**: 下拉菜单（ComboBox），从工具模型动态加载
- **默认值**: `0`（时间戳工具）
- **行为**: 下次启动插件时生效

#### 2.3 窗口位置记忆开关
- **设置键**: `"preferences/windowPositionMemory"` (布尔)
- **UI控件**: 开关（Switch）
- **默认值**: `true`（开启）
- **行为**: 立即生效，关闭时将清除现有位置存储

### 3. 数据持久化和错误处理

#### 3.1 数据存储策略
1. **存储结构**: 键值对存储，前缀`"preferences/"`区分设置类型
2. **读写时机**:
   - **读取**: 对话框打开时从`settings`加载到UI控件
   - **写入**: 用户点击"确定"或"应用"时保存到`settings`
3. **数据类型转换**:
   - 字符串类型直接存储
   - 整数类型转换为QVariant
   - 布尔类型存储为true/false

#### 3.2 错误处理和边界情况
1. **无效设置值处理**:
   - 下拉菜单：存储值不在选项中时使用第一个选项
   - 开关控件：非布尔类型时使用`true`作为默认
2. **设置加载失败**:
   - `pluginApi.settings`不可用时使用内存默认值
   - 记录警告日志但不阻止对话框显示
3. **用户输入验证**:
   - 下拉菜单：确保选择值在有效范围内
   - UI控件本身提供输入限制，无需额外验证

#### 3.3 与应用集成
1. **主题设置应用**: 重启插件后生效，对话框显示提示
2. **默认工具应用**: 存储在设置中，插件启动时读取
3. **位置记忆开关**: 立即生效，关闭时清除现有位置存储

### 4. UI布局设计

#### 4.1 对话框结构
```
┌─────────────────────────────────────┐
│ 设置                       [×]关闭  │
├─────────────────────────────────────┤
│ 主题偏好:      [跟随系统 ▼]         │
│                                      │
│ 默认启动工具:  [时间戳 ▼]           │
│                                      │
│ 窗口位置记忆:  [✓] 启用             │
├─────────────────────────────────────┤
│           [取消] [应用] [确定]      │
└─────────────────────────────────────┘
```

#### 4.2 视觉设计
- **主题继承**: 使用现有`Theme.qml`的颜色、字体、间距
- **动画效果**: 对话框淡入淡出，与现有窗口动画一致
- **响应式布局**: 适应不同窗口尺寸和文本长度

### 5. 测试策略

#### 5.1 单元测试
1. **设置管理器测试**:
   - 验证数据读写功能
   - 测试类型转换和默认值处理
   - 边界情况测试（无效值、缺失设置）
2. **模拟API测试**:
   - 模拟`pluginApi.settings`的不同状态
   - 测试API不可用时的降级处理

#### 5.2 集成测试
1. **对话框集成测试**:
   - 验证侧边栏设置按钮正确打开对话框
   - 测试对话框与主窗口的主题同步
2. **设置与应用集成测试**:
   - 验证主题设置影响插件外观
   - 测试默认工具设置正确应用
   - 验证位置记忆开关功能

#### 5.3 手动测试清单
1. **基本功能测试**:
   - 打开设置对话框，修改各项设置
   - 点击"取消"验证不保存更改
   - 点击"应用"验证保存但不关闭
   - 点击"确定"验证保存并关闭
2. **持久化测试**:
   - 修改设置后重启插件验证设置保持
   - 不同设置组合的跨会话测试
3. **错误场景测试**:
   - 模拟API故障时的用户界面
   - 无效设置值的恢复测试

## 技术实现细节

### 1. QML实现要点
```qml
// SettingsDialog.qml 关键属性
Dialog {
    id: settingsDialog
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel | Dialog.Apply
    title: qsTr("设置")

    // 主题继承
    property var theme: parent.theme

    // 设置值属性
    property string themePreference: "system"
    property int defaultToolIndex: 0
    property bool windowPositionMemory: true

    // 初始化设置值
    function loadSettings() {
        themePreference = settingsManager.getValue("preferences/theme", "system")
        // ... 其他设置加载
    }
}
```

### 2. 设置管理器设计
```qml
// SettingsManager QML对象
QtObject {
    id: settingsManager
    property var pluginApi

    function getValue(key, defaultValue) {
        if (!pluginApi || !pluginApi.settings) {
            console.warn("Settings API not available, using default:", defaultValue)
            return defaultValue
        }
        var value = pluginApi.settings.value(key, defaultValue)
        return validateValue(key, value, defaultValue)
    }

    function setValue(key, value) {
        if (pluginApi && pluginApi.settings) {
            pluginApi.settings.setValue(key, value)
            return true
        }
        console.error("Failed to save setting:", key)
        return false
    }

    function validateValue(key, value, defaultValue) {
        // 根据设置键验证值有效性
        switch(key) {
            case "preferences/theme":
                return ["system", "light", "dark"].includes(value) ? value : defaultValue
            // ... 其他设置验证
        }
    }
}
```

### 3. 信号/槽通信
```qml
// 主窗口连接设置对话框
Connections {
    target: settingsDialog
    function onAccepted() {
        // 应用所有设置
        settingsManager.applyAllSettings()
        console.log("Settings saved and applied")
    }

    function onApplied() {
        // 应用但不关闭
        settingsManager.applyAllSettings()
        console.log("Settings applied")
    }
}
```

## 验收标准

1. ✅ 侧边栏设置按钮可点击并打开对话框
2. ✅ 设置对话框显示正确的当前设置值
3. ✅ 主题偏好设置可修改并正确保存
4. ✅ 默认启动工具设置可修改并正确保存
5. ✅ 窗口位置记忆开关功能正常
6. ✅ 设置值在插件重启后保持
7. ✅ 错误场景有适当的用户反馈
8. ✅ 对话框UI与现有主题一致
9. ✅ 确定、取消、应用按钮功能正确
10. ✅ 性能良好，无明显延迟

## 扩展性考虑

### 1. 未来设置项添加
- 预留设置模型系统，便于添加新设置项
- 使用设置组概念，支持分类管理
- 考虑设置导入/导出功能

### 2. 与现有架构兼容
- 保持与现有主题系统的兼容
- 不影响现有工具功能
- 最小化对主窗口逻辑的修改

### 3. 维护性考虑
- 清晰的设置项定义和文档
- 设置键命名规范便于维护
- 统一的错误处理模式

## 相关资源

1. [Noctalia插件API文档](https://docs.noctalia.dev/development/plugins/api/) - 设置API参考
2. [Qt QML Dialog组件](https://doc.qt.io/qt-6/qml-qtquick-dialogs-dialog.html) - 对话框组件文档
3. [Qt Quick Controls 2](https://doc.qt.io/qt-6/qtquickcontrols-index.html) - UI控件库

---
*设计文档创建时间：2026-02-09*
*设计目标：为Noctalia开发者工具插件添加基本设置功能*
*状态：已完成设计，待实施*