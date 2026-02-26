# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

Noctalia Shell 插件项目，包含多个插件：
- **developer-tools**: 开发者工具集合（时间戳转换、JSON 格式化）
- **query-tracker**: Shell 命令执行结果监控器
- **modifier-keys**: 键盘修饰键状态显示（Super、Alt、Ctrl、Shift）及触摸板手势识别

## 常用开发命令

### 构建和部署
- **构建插件**: `./tools/build.sh` - 将插件复制到构建目录
- **部署插件**: `./tools/deploy.sh` - 安装插件到用户目录
- **验证 QML 语法**: `qmllint plugins/developer-tools/qml/**/*.qml`（如果安装了 qmllint）

### 开发工作流
1. 编辑 QML 文件
2. 运行构建脚本验证文件完整性
3. 部署到 Noctalia Shell 插件目录进行测试
4. 使用 Noctalia Shell 重新加载插件或重启进行验证

## 架构和代码结构

### 插件架构
本项目使用 Noctalia Shell 插件架构：
- **bar-widget 类型**: 在状态栏显示按钮，点击打开弹出窗口
- **panel 类型**: 弹出式面板，显示详细信息
- **settings 类型**: 设置界面，配置插件选项
- **QML 界面**: 使用 Qt Quick 2.15 和 Qt Quick Controls 2.15

### 项目结构

#### developer-tools/
```
developer-tools/
├── manifest.json          # 插件配置元数据
├── icon.svg              # 插件图标
├── README.md             # 插件说明
├── qml/
│   ├── main.qml          # 主窗口入口
│   ├── ToolButton.qml    # 状态栏按钮组件
│   └── components/       # 可重用组件
│       ├── Theme.qml     # 主题定义
│       ├── TextEditor.qml # 代码编辑器
│       └── Sidebar.qml   # 侧边栏导航
├── tools/                # 工具页面组件
│   ├── ToolBase.qml      # 工具基类
│   ├── TimestampTool.qml # 时间戳转换工具
│   └── JsonFormatter.qml # JSON 格式化工具
├── translations/         # 国际化翻译文件 (.ts)
│   ├── en_US.ts
│   └── zh_CN.ts
└── tools/               # 构建和部署脚本
    ├── build.sh
    └── deploy.sh
```

#### query-tracker/
```
query-tracker/
├── manifest.json          # 插件配置元数据
├── BarWidget.qml          # 状态栏组件（终端图标 + 失败计数徽章）
├── Settings.qml           # 设置面板（命令管理 + 编辑/删除对话框）
├── Panel.qml              # 结果面板（列表展示命令结果）
├── README.md              # 插件说明
└── i18n/                 # 国际化翻译文件 (.json)
    ├── en.json
    └── zh-CN.json
```

#### modifier-keys/
```
modifier-keys/
├── manifest.json          # 插件配置元数据
├── BarWidget.qml          # 状态栏组件（修饰键图标 + 最近按键）
├── Panel.qml              # 帮助面板（展示各键名称）
├── README.md              # 插件说明
└── i18n/                 # 国际化翻译文件 (.json)
    ├── en.json
    └── zh-CN.json
```

## 开发注意事项

### 技术栈
- **界面**: QML 2.15 + Qt Quick Controls 2.15
- **主题系统**: Noctalia Style 组件（Color.m*、Style.*）
- **国际化**: JSON 格式翻译文件
  - 格式: `{ "key": "value" }`
  - 使用: `pluginApi?.tr("key", "default")`
- **Noctalia API**: `org.noctalia.shell 1.0` 模块集成

### 翻译文件格式

**推荐 JSON 格式（query-tracker 使用）**:
```json
{
  "settings": {
    "add": "Add",
    "commandName": "Name"
  },
  "widget": {
    "title": "Query Tracker",
    "refresh": "Refresh"
  }
}
```

**使用方法**:
```qml
text: pluginApi?.tr("settings.add", "Add") || "Add"
```

### 需要关注的配置文件
- `manifest.json`: 插件元数据、权限、窗口设置
- `registry.json`: 插件注册表
- `.gitignore`: 构建目录、临时文件

### 编码规范
1. **组件化**: 每个功能独立组件，通过属性和信号通信
2. **主题化**: 使用 `Color.m*` 和 `Style.*` 系统
3. **国际化**: 所有用户可见字符串使用 `pluginApi?.tr()` 包装
4. **错误处理**: 添加必要的边界检查和错误处理
5. **性能**: 避免不必要的重新绑定，合理使用属性绑定
6. **图标**: 使用 Nerd Fonts 图标库

### 常见图标
- `terminal` - 终端/命令
- `settings` - 设置
- `edit` - 编辑
- `minus` - 删除
- `check` - 成功
- `close` - 失败/关闭
- `refresh` - 刷新
- `clock` - 时间
- `code` - 代码

## 相关资源

- **Noctalia Shell 文档**: [https://docs.noctalia.dev/](https://docs.noctalia.dev/) - Noctalia Shell 官方文档
- **插件开发指南**: [https://docs.noctalia.dev/development/plugins/overview/](https://docs.noctalia.dev/development/plugins/overview/) - Noctalia 插件开发文档
- **Qt QML 文档**: [https://doc.qt.io/qt-6/qmlapplications.html](https://doc.qt.io/qt-6/qmlapplications.html) - Qt QML 官方文档

## 更新此文件

随着项目发展，请更新此文件：
1. 实际的构建、测试和部署命令
2. 新增的组件和工具描述
3. 插件配置和权限变更
4. 开发工作流优化
5. 新增的相关资源链接
