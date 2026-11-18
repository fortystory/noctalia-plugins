# Modifier Keys

在状态栏显示键盘修饰键（Super、Alt、Ctrl、Shift）的按下状态、最近按下的普通按键，以及触摸板手势。

## 兼容性

- **Noctalia v5**：`plugin.toml` + `.luau` 插件（`plugin_api = 22`）。入口：`bar`、`panel`、`input` service。
- **Noctalia v4（legacy）**：同目录保留 `manifest.json`、`BarWidget.qml`、`Panel.qml`、`Settings.qml`、`KeyStats.js` 与 `i18n/`。
  v5 只读取 `plugin.toml`，两套文件互不影响。

v5 与 v4 的插件运行时完全不同（v5 为 Luau 声明式 UI），v4 的 QML 代码不会被 v5 加载。

## 功能

### 键盘
- 实时显示 4 个修饰键状态：⌘ ⌥ ⌃ ⇧
- 按键按下时图标高亮显示（颜色变化）
- 显示最近按下的普通按键（最多 1 个）
- 高亮延迟消失：松开后保持一段时间再淡出（默认 800 ms，可配置）
- 左键打开帮助 / 统计面板

### 触摸板手势
- 光标移动：单指滑动时显示光标图标
- 单指点击：显示左键图标
- 双指点击：显示右键图标
- 三指点击：显示中键图标
- 双指滚动：显示滚动方向
- 三指滑动 / 四指滑动：显示滑动方向
- 双指缩放：显示放大 / 缩小

### 按键统计（v5）
- 每日总按键数、最常用按键、最常用组合键
- 今天 / 昨天 / 本周 / 本月 / 全部时间
- 按键与快捷键 TOP 20
- 统计写入 `~/.local/state/noctalia/plugins/data/forty/modifier-keys/stats.json`
- 历史 v4 SQLite 统计不会迁移

## 安装（Noctalia v5）

1. 将本目录作为 path 插件源，在 `~/.local/state/noctalia/settings.toml` 中启用：

   ```toml
   [[plugins.source]]
   enabled = true
   kind = "path"
   location = "/path/to/noctalia-plugins"
   name = "forty"
   ```

   或通过 **Settings → Plugins** 启用该源。

2. 确认插件已启用（`~/.local/state/noctalia/settings.toml`）：

   ```toml
   [plugins]
   enabled = [ "forty/modifier-keys" ]
   ```

3. 把 widget 加入某条 bar 的 `start` / `center` / `end` 列表：

   ```toml
   [bar.top]
   end = [ "tray", "network", "clock", "bar" ]

   [widget.bar]
   type = "forty/modifier-keys:bar"
   ```

   `bar` 是这个插件 widget 入口的固定 id，对应 `forty/modifier-keys:bar`。

4. 修改后 `noctalia msg config-reload`，或重启 Noctalia。

## 安装（Noctalia v4）

将插件复制到 Noctalia v4 插件目录：

```bash
./tools/deploy.sh
```

## 设置（v5）

**中键点击小组件**（或 Settings → Plugins 中该 widget 的齿轮）打开 widget 设置弹窗：

| 设置 | 说明 | 默认 |
|------|------|------|
| 符号间距 | 修饰键与按键符号之间的像素间距 | 2 |
| 符号槽宽度 | 每个符号的固定槽宽；避免不同按键切换时整体宽度抖动 | 16 |
| 符号字体 | 符号使用的字体族，留空继承状态栏字体 | 空 |
| 高亮颜色 | 按下 / 高亮时的颜色（主题色下拉或自定义） | `primary` |
| 未高亮颜色 | 未高亮状态的颜色（主题色下拉或自定义） | `on_surface_variant` |
| 显示手势 | 显示触摸板手势与指针移动 | 开 |
| Actions | 左键 / 右键 / 中键点击动作，可从 `noctalia msg` 命令中选择 | 左键开面板，右键/中键开设置 |

**Settings → Plugins → Modifier Keys**（插件级设置）：

| 设置 | 说明 | 默认 |
|------|------|------|
| 输入捕获命令 | 解析键盘/触摸板事件的 shell 命令 | `libinput debug-events --show-keycodes` |
| 修饰键符号 | 自定义修饰键符号（JSON） | `{"super":"⌘","alt":"⌥","ctrl":"⌃","shift":"🡅"}` |
| 手势符号 | 自定义手势符号（JSON） | 见下表 |
| 高亮保持时长 | 松开后保持高亮的毫秒数 | 800 |
| 统计保留天数 | 超过该天数的按日统计会删除 | 90 |

点击动作通过 manifest 的 `[widget.actions]` 声明默认值，用户可在 widget 设置的 **Actions** 中按实例覆盖。绑定动作后不再调用脚本的 `onClick` / `onRightClick`。

v4 的自定义符号设置（`settings.json`）不会迁移到 v5，请在 v5 设置中重新填写。

## 自定义符号

修饰键符号（JSON，键名不区分大小写）：

```json
{"super":"⌘","alt":"⌥","ctrl":"⌃","shift":"🡅"}
```

手势符号（JSON，键名不区分大小写）：

| 键名 | 描述 | 默认值 |
|------|------|--------|
| scroll | 滚动方向 [左, 上, 右, 下] | ["⥤", "⥥", "⥢", "⥣"] |
| swipe3 | 三指滑动 [左, 上, 右, 下] | ["🡆", "🡇", "🡄", "🡅"] |
| swipe4 | 四指滑动 [左, 上, 右, 下] | ["⭲", "⭳", "⭰", "⭱"] |
| click | 左键点击 | 󰳽 |
| rightClick | 右键点击 | 󰳾 |
| middleClick | 中键点击 | 󰻃 |
| motion | 光标移动 | 󰆽 |
| pinchIn | 缩小 | 󰘖 |
| pinchOut | 放大 | 󰘕 |

## 依赖

### 系统依赖

- **libinput**：用于捕获键盘事件

  ```bash
  # Arch Linux
  sudo pacman -S libinput

  # Debian/Ubuntu
  sudo apt install libinput
  ```

### 权限配置

需要将当前用户加入 `input` 用户组以读取输入事件：

```bash
sudo usermod -aG input $USER
```

然后重新登录或重启系统使权限生效。

## 使用

- 状态栏显示 4 个符号，分别对应 Super、Alt、Ctrl、Shift 键
- 按下对应按键时，符号变亮并显示强调色
- 按下普通按键时，在修饰键后面显示（最多 1 个）
- 松开后保持高亮，到时自动淡出
- 左键点击打开帮助 / 统计面板
- 右键点击打开插件设置
- 中键默认为 Noctalia 的 widget 设置（`middle = "settings-open-widget"`）

## 显示示例

### 键盘
- 单独按 `j`：显示 `j`（高亮保持后消失）
- 按 `Shift + j`：显示 `⇧ j`（Shift 高亮）
- 按 `Ctrl + c`：显示 `⌃ c`（Ctrl 高亮）

### 触摸板手势符号

| 事件类型 | 手指数量 | 物理动作 | 显示符号（左 上 右 下） |
|---------|---------|---------|---------------------|
| 光标移动 | 1 | 单指滑动 | 󰆽 |
| 点击 | 1 | 按下触摸板 | 󰳽 |
| 右键 | 2 | 双指点击 | 󰳾 |
| 中键 | 3 | 三指点击 | 󰻃 |
| 滚动 | 2 | 双指位移 | ⥤ ⥥ ⥢ ⥣ |
| 切换 | 3 | 三指滑动 | 🡆 🡇 🡄 🡅 |
| 调度 | 4 | 四指滑动 | ⭲ ⭳ ⭰ ⭱ |
| 缩放 | 2 | 双指捏合 | 󰘖 󰘕 |
