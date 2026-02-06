# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

Noctalia Shell 开发者工具插件项目。这是一个基于 QML/Qt Quick 的 Noctalia Shell 插件，提供开发者常用工具集合，包括时间戳转换和 JSON 格式化功能。

## 常用开发命令

### 构建和部署
- **构建插件**: `./tools/build.sh` - 将插件复制到构建目录
- **部署插件**: `./tools/deploy.sh` - 安装插件到用户目录
- **验证 QML 语法**: `qmllint plugins/developer-tools/qml/**/*.qml`（如果安装了 qmllint）
- **测试运行**: `qmlscene --quit plugins/developer-tools/qml/main.qml`（基本语法检查）

### 开发工作流
1. 编辑 QML 文件
2. 运行构建脚本验证文件完整性
3. 部署到 Noctalia Shell 插件目录进行测试
4. 使用 Noctalia Shell 重新加载插件或重启进行验证

## 架构和代码结构

### 插件架构
本项目使用 Noctalia Shell 插件架构：
- **bar-widget 类型**: 在状态栏显示按钮，点击打开弹出窗口
- **QML 界面**: 使用 Qt Quick 2.15 和 Qt Quick Controls 2.15
- **模块化设计**: 工具组件化，便于扩展

### 项目结构
```
plugins/developer-tools/
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
├── translations/         # 国际化翻译文件
│   ├── en_US.ts
│   └── zh_CN.ts
└── tools/               # 构建和部署脚本
    ├── build.sh
    └── deploy.sh
```

## 开发注意事项

### 技术栈
- **界面**: QML 2.15 + Qt Quick Controls 2.15
- **主题系统**: 自定义 Theme.qml 组件管理颜色、尺寸、字体
- **国际化**: Qt 翻译系统 (qsTr() 函数 + .ts/.qm 文件)
- **Noctalia API**: `org.noctalia.shell 1.0` 模块集成

### 需要关注的配置文件
- `manifest.json`: 插件元数据、权限、窗口设置
- `.gitignore`: 通常包括构建目录、临时文件
- `.claude/settings.local.json`: Claude Code 权限设置

### 编码规范
1. **组件化**: 每个功能独立组件，通过属性和信号通信
2. **主题化**: 所有颜色、尺寸、字体从 Theme.qml 获取
3. **国际化**: 所有用户可见字符串使用 qsTr() 包装
4. **错误处理**: 添加必要的边界检查和错误处理
5. **性能**: 避免不必要的重新绑定，合理使用属性绑定

## 相关资源

- **Noctalia Shell 文档**: [https://docs.noctalia.dev/](https://docs.noctalia.dev/) - Noctalia Shell 官方文档
- **插件开发指南**: [https://docs.noctalia.dev/development/plugins/overview/](https://docs.noctalia.dev/development/plugins/overview/) - Noctalia 插件开发文档
- **Qt QML 文档**: [https://doc.qt.io/qt-6/qmlapplications.html](https://doc.qt.io/qt-6/qmlapplications.html) - Qt QML 官方文档
- **项目设计文档**: `docs/plans/` - 项目设计和实施计划文档

## 更新此文件

随着项目发展，请更新此文件：
1. 实际的构建、测试和部署命令
2. 新增的组件和工具描述
3. 插件配置和权限变更
4. 开发工作流优化
5. 新增的相关资源链接