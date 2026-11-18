# Noctalia v5 插件 API 调研与 modifier-keys 迁移依据

调研日期: 2026-11-18
目标环境: 本机安装的 `noctalia-git 1:5.5.0.r6391.g4e1dcb6eb-1`, 二进制实际版本 `noctalia v5.5.0 (v5.5.0-43-g4e1dcb6eb2da)` [S1]

## 0. 结论摘要

1. **前提需要纠正: v5.5.0 不是 Quickshell/QML shell, 没有 QML 插件 API.** 本机 `/usr/bin/noctalia` 是原生 ELF 二进制, 由 `noctalia-git` 提供, 使用 C++/OpenGL ES 与 Luau 插件宿主 [S1][S2]. `/etc/xdg/quickshell/noctalia-shell` 下的 QML 代码由另一个包 `noctalia-shell 4.7.7-4` 提供, 是 v4 遗留, 不是 v5 [S2]. 因此 `qs.Commons`, `qs.Widgets`, `qs.Services.UI`, `NText`, `Style.*`, `Color.m*`, `pluginApi.openPanel/openSettings` 在 v5 中全部不存在, 也没有 `qs.Plugins` 之类的新 QML 导入 [S6][S7].

2. **v5 插件 = `plugin.toml` + `.luau` entry scripts + `translations/*.json`.** 插件由 Luau VM 执行, 通过全局命名空间 `noctalia.*`, `barWidget.*`, `panel.*`, `ui.*` 等驱动 UI [S12][S13][S21]. 旧 `manifest.json` / `entryPoints` / `BarWidget.qml` / `Panel.qml` / `Settings.qml` 不会被 v5 扫描或加载 [S7][S11][S26].

3. **旧插件 `modifier-keys` 必须重写, 不能只改 manifest.** 但可以双轨维护: 保留 v4 的 `manifest.json` 与 QML 文件, 同时新增 v5 的 `plugin.toml` 与 `.luau` 文件. v5 只读 `plugin.toml` [S7][S11].

4. **本机 v5 已经为迁移后的插件预留了配置.** `[plugins].enabled` 已包含 `"forty/modifier-keys"`, 三处 bar widget 已写成 `type = "forty/modifier-keys:bar"` [S24]. 新插件的 widget entry id 必须是 `bar`, 否则现有 bar 配置匹配不上.

5. **没有官方 v4→v5 插件迁移指南.** v5 文档明确说明 v5 是全新安装, 不迁移 v4 设置; 旧插件仓库已归档为 `legacy-v4-plugins` [S6][S25]. 文档只提供 v5 内部 `plugin_api` 版本兼容说明, 不提供 QML→Luau 迁移映射. 本文的对照表是依据 v5.5.0 源码与官方插件代码整理的等价映射.

6. **旧 QML 插件 (`show-keys`, `network-indicator`, `privacy-indicator`, `mpris-lyric`, `clipper`, `timer`, `todo` 等) 不能作为 v5 参考.** 它们位于 v4 路径 `~/.config/noctalia/plugins/`, manifest 使用 `entryPoints` 和 QML, 且不在 v5 的 `noctalia msg plugins list` 中 [S3][S25][S26]. v5 的官方/社区插件是 `~/.local/state/noctalia/plugins/materialized/<source>/` 下的 Luau 插件 [S3][S22].

> 资料冲突说明: 搜索摘要中出现过 `ctx.ui.open({ panel })`, `definePlugin(...)`, `legacyPluginApi` 兼容开关等说法. 本机 v5.5.0 二进制与 v5.5.0 源码中均不存在这些接口或兼容层. 实际接口是 `noctalia.togglePanel(id)`, `noctalia.openSettings()`, `panel.render()` 等 [S1][S7][S8][S21]. 本文以本机实际 v5.5.0 为准.

## 1. 事实基线: 本机运行的是 v5, QML 是 v4 遗留

| 项目 | 实际内容 | 证据 |
|---|---|---|
| 运行中的 shell | `noctalia v5.5.0 (v5.5.0-43-g4e1dcb6eb2da)`, 原生 ELF | `noctalia --version`, `/usr/bin/noctalia` [S1] |
| v5 包 | `noctalia-git 1:5.5.0.r6391.g4e1dcb6eb-1` | `pacman -Q` [S1] |
| v4 包 | `noctalia-shell 4.7.7-4`, `noctalia-qs 0.0.12-3` | `pacman -Q` [S2] |
| QML 代码归属 | `/etc/xdg/quickshell/noctalia-shell/shell.qml` 属于 `noctalia-shell 4.7.7-4` | `pacman -Qo` [S2] |
| v5 插件源码目录 | `~/.local/state/noctalia/plugins/materialized/<source>/<plugin>/` | 实际目录 [S3] |
| v5 本地插件源目录 | `~/.local/share/noctalia/plugins/` | 源码 `plugin_source_paths.cpp:42-48` [S9] |
| v4 插件目录 | `~/.config/noctalia/plugins/` | 实际目录 [S25] |
| v5 插件清单 | `noctalia msg plugins list` 共 378 行, 14 个 official, 363 个 community | 命令输出 [S3] |
| v5 中 `modifier-keys` | 未出现在 `plugins list`, 但已在 `[plugins].enabled` 和 bar 配置中 | [S3][S24] |

关键证据链:

- v5 二进制字符串包含 `plugin.toml`, `.luau`, `catalog.toml`, `plugin_api`, `LuauHost`, `openSettings`, `barWidget`; 不含 `entryPoints`, `manifest.json` 或 QML 相关符号 [S1][S7].
- v5.5.0 源码树中搜索 `manifest.json`, `entryPoints`, `.qml`, `Quickshell` 无匹配; 插件宿主只解析 `plugin.toml` 并执行 `.luau` [S7][S11].
- v5 文档: "Plugins ... all driven by trusted Luau scripts running in isolated VMs. A plugin is a directory containing a static `plugin.toml` manifest and one or more `.luau` entry scripts." [S12]
- v5 FAQ: "Noctalia v5 is a fresh install, not an automatic upgrade from the Quickshell-based v4 line." [S18]
- 旧插件仓库 `github.com/noctalia-dev/noctalia-plugins` 301 跳转到 `github.com/noctalia-dev/legacy-v4-plugins`, README 标题为 "Noctalia Legacy V4 Plugins Registry" [S25].

### 1.1 旧插件侧的 QML 证据

| 文件 | 内容 |
|---|---|
| `/home/forty/code/fortystory/noctalia-plugins/modifier-keys/manifest.json:2-22` | `id: "modifier-keys"`, `minNoctaliaVersion`, `entryPoints: {barWidget, panel, settings}`, `metadata.defaultSettings` |
| `/home/forty/code/fortystory/noctalia-plugins/modifier-keys/BarWidget.qml:1-9` | `import Quickshell`, `Quickshell.Io`, `qs.Commons`, `qs.Services.UI`, `qs.Widgets` |
| `.../BarWidget.qml:22` | `Settings.data.bar.position` |
| `.../BarWidget.qml:312-329` | `Process { command: ["libinput", "debug-events", "--show-keycodes"] }` + `SplitParser` |
| `.../BarWidget.qml:733-766` | `pluginApi.openSettings(...)`, `pluginApi.openPanel(...)` |
| `.../Panel.qml:8-17` | QML `Item` 根, `panelGeometry`, `contentPreferredWidth/Height`, `allowAttach` |
| `.../Settings.qml:190-218` | `saveSettings()` 调用 `pluginApi.saveSettings()` |
| `.../KeyStats.js:4,25-29` | `QtQuick.LocalStorage` + `openDatabaseSync` |

这些接口在 v5.5.0 中不存在 [S7][S8][S21].

特别说明: 任务中指定的 `show-keys` (`Main.qml`/`Settings.qml`), `network-indicator 2.0.0` (`BarWidget.qml`), `privacy-indicator` (`BarWidget.qml`) 都是 v4 QML 插件. `network-indicator` manifest 使用 `minNoctaliaVersion: "4.7.6"` 和 `entryPoints: {barWidget, panel, settings}`; `show-keys/Main.qml` 导入 `qs.Commons`; `privacy-indicator/BarWidget.qml` 导入 `qs.Commons`/`qs.Services.UI`/`qs.Widgets` [S25]. 它们不能证明 v5 写法; 真正的 v5 示例见第 4 节.

## 2. v5 的 manifest 与目录

### 2.1 `plugin.toml` 必填字段与 entry 类型

v5 manifest 是 TOML, 不是 JSON. 必填字段 [S13][S7]:

```toml
id         = "forty/modifier-keys"  # 必须 "<author>/<plugin>"
name       = "Modifier Keys"
version    = "2.0.0"                # 严格 MAJOR.MINOR.PATCH
plugin_api = 22                     # 必填, 正整数, 插件所需最低 API level
author     = "forty"
license    = "MIT"                  # 可省略, 默认 MIT
description = "..."
tags        = ["bar", "indicator", "system"]
dependencies = ["libinput"]         # 外部工具, 不阻止启用
```

- `id` 必须是 `author/plugin`, 且只能有一个 `/`; 运行时校验见 `plugin_manifest.cpp:846-873` [S7].
- `plugin_api` 是 v5 插件的兼容级别, 不是 Noctalia 版本号; v5.5.0 支持 3 到 53 [S8][S13].
- 旧 `minNoctaliaVersion` 没有对应字段; 用 `plugin_api` 代替 [S13].
- 旧 `metadata.defaultSettings` 没有对应字段; 用 `[[setting]] default` 代替 [S13][S7].
- 旧 `dependencies.plugins` 是插件依赖; v5 的 `dependencies` 是外部工具/包列表, 不阻止启用 [S13].

支持的 entry 表 [S13]:

| 表 | 类型 | 用途 |
|---|---|---|
| `[[widget]]` | bar widget | 状态栏部件, 有 update/click/IPC |
| `[[panel]]` | panel | 弹出面板, 用 id 打开 |
| `[[shortcut]]` | control-center tile | 控制中心磁贴 |
| `[[desktop_widget]]` | desktop widget | 桌面部件 |
| `[[launcher_provider]]` | launcher provider | 启动器结果提供器 |
| `[[layer]]` | layer surface | 插件自有 layer-shell 表面 |
| `[[service]]` | headless service | 后台逻辑, 无 UI |

entry 地址统一为 `author/plugin:entry-id`, 例如 `forty/modifier-keys:bar` [S13].

### 2.2 旧 manifest 能否被 v5 加载

不能. 具体失败点:

1. v5 只扫描 `plugin.toml`, 不读 `manifest.json` [S7][S11].
2. 即使把旧 JSON 改名为 `plugin.toml`, `id: "modifier-keys"` 不含 `/`, 触发 `invalid plugin id 'modifier-keys' (expected author/plugin)` [S7].
3. 旧 manifest 没有 `plugin_api`, 触发 `missing mandatory key 'plugin_api'` [S7].
4. 旧 `entryPoints` 不是 v5 的 entry 表, 不会被解析 [S7][S13].
5. 旧 `BarWidget.qml` / `Panel.qml` / `Settings.qml` 不会被任何 v5 代码路径加载 [S7][S11].

结论: 旧 manifest 在 v5 中连"部分加载"都做不到; 必须新增 `plugin.toml`.

### 2.3 目录与安装位置

| 用途 | 路径 | 说明 |
|---|---|---|
| 本地开发源 | `~/.local/share/noctalia/plugins/<plugin>/` | v5 作为内置 local source 扫描; 需 enable [S12][S9] |
| path source | 任意目录, 每个插件一个子目录 | 仓库根下 `modifier-keys/plugin.toml`; path source 直接扫描, 不 materialize [S11] |
| git source 缓存 | `~/.local/state/noctalia/plugins/sources/<source>/repo` | v5 管理, 不手改 [S9][S3] |
| git source 运行副本 | `~/.local/state/noctalia/plugins/materialized/<source>/<plugin>/` | enable 后导出 [S12][S3] |
| 插件持久数据 | `~/.local/state/noctalia/plugins/data/<author/plugin>/` | `noctalia.pluginDataDir()` [S9][S16] |
| 旧 v4 插件 | `~/.config/noctalia/plugins/` | v5 不扫描 [S25][S9] |

发布/源索引:

- git source 需要仓库根 `catalog.toml`; path source 可选, 没有时直接扫描 `*/plugin.toml` [S11][S17].
- 旧 `registry.json` / `~/.config/noctalia/plugins.json` 不是 v5 的源索引; v5 源码中没有 `registry.json` 读取路径 [S11].
- 发布到 community store 需要 `plugin.toml`, entry 脚本, `README.md`, `thumbnail.webp`, `translations/en.json` [S17].
- `thumbnail.webp` 要求 960x540, 最大 512 KiB [S19].

### 2.4 本机 v5 现状 (关键)

`/home/forty/.local/state/noctalia/settings.toml` [S24]:

```toml
[plugins]
enabled = [
    "noctalia/bongocat",
    "noctalia/screen_recorder",
    "forty/modifier-keys",      # 已启用
    ...
]

    [[plugins.source]]
    enabled = false             # forty 源当前被禁用
    kind = "path"
    location = "/home/forty/code/fortystory/noctalia-plugins"
    name = "forty"

[widget.bar]
type = "forty/modifier-keys:bar"

[widget.bar_2]
type = "forty/modifier-keys:bar"

[widget.bar_3]
type = "forty/modifier-keys:bar"
```

因此迁移后的 v5 插件必须满足:

- `id = "forty/modifier-keys"`.
- widget entry `id = "bar"`, 对应三处 `type = "forty/modifier-keys:bar"`.
- 需要先把 path source `forty` 启用 (当前 `enabled = false`) [S24].
- 插件目录下的 `plugin.toml` 一旦存在, v5 会把它识别为 path source 插件; 当前 `plugins list` 没有 `forty/...`, 因为源被禁用且没有 `plugin.toml` [S3].

## 3. QML API 变更对照表 (旧 → v5)

> 说明: v5 没有 QML 插件 API, 下表是"旧 QML 能力 → v5 Luau 等价能力". 不是同名 API 的签名变化.

| 旧 QML 写法 | v5 写法 | 依据 |
|---|---|---|
| `manifest.json` + `entryPoints.barWidget/panel/settings` | `plugin.toml` + `[[widget]]`/`[[panel]]`/`[[setting]]`/`[[service]]` | [S13][S7] |
| `minNoctaliaVersion` | `plugin_api` | [S13] |
| `metadata.defaultSettings` | `[[setting]] default` / `[[widget.setting]] default` | [S13] |
| `import qs.Commons` / `qs.Widgets` / `qs.Services.UI` | 无 import; Luau 全局命名空间 `noctalia`, `ui`, `barWidget`, `panel` | [S12][S21] |
| `pluginApi.pluginSettings` | `noctalia.getConfig("key")` | [S16][S13] |
| `pluginApi.saveSettings()` | 无; 用户在 Settings GUI 修改, 插件只读 | [S16][S13] |
| `pluginApi.tr(key, default)` | `noctalia.tr(key)` / `noctalia.tr(key, subst)` / `noctalia.trp(key, count)`; 无 default 参数 | [S16][S10] |
| `pluginApi.openPanel(screen, root)` | `noctalia.togglePanel("author/plugin:entry")` | [S16][S21] |
| `pluginApi.togglePanel(screen, root)` | `noctalia.togglePanel("author/plugin:entry")` | [S16] |
| `pluginApi.openSettings(screen, root)` | `noctalia.openSettings()` (API 15) | [S16][S21] |
| `pluginApi.withCurrentScreen(cb)` | 无回调版; 用 `noctalia.focusedOutputName()` / `barWidget.outputName()` | [S16][S21] |
| `pluginApi.closePanel(...)` | 面板内部 `panel.close()`; 外部用 `noctalia.togglePanel()` | [S21] |
| `pluginApi.panelOpenScreen` | 无直接等价; panel 无 screen 参数, 由宿主管理 | [S21] |
| `pluginApi.barWidget` (Component) | 全局 `barWidget.*` 方法, 不是组件 | [S21] |
| `pluginApi.mainInstance` | `noctalia.state` 跨 entry 共享; 或用 `[[service]]` | [S16] |
| `BarWidget.qml` 根 `Item` + `implicitWidth/Height` | `.luau` 全局回调 + `barWidget.render(tree)`; 尺寸由 bar 胶囊控制 | [S14][S15] |
| `Settings.data.bar.position` | `barWidget.isVertical()`; 多显示器用 `barWidget.outputName()` | [S14][S21] |
| `Settings.data.bar.*` / 其他 shell 配置 | `noctalia.getSetting(path)` (API 26) | [S16] |
| `NText`, `NIcon`, `NButton`, `NDivider`, `NLabel`, `NTextInput` | `ui.label`, `ui.glyph`, `ui.button`, `ui.separator`, `ui.label`, `ui.input` | [S15][S21] |
| `Style.marginS/M/L`, `Style.fontSize*`, `Style.radius*` | `ui` 属性里的数字 (gap/padding/radius/fontSize); 宿主按 UI scale 缩放 | [S15] |
| `Style.capsuleColor/BorderColor`, `Color.m*` | bar 胶囊由宿主绘制; 颜色用 palette role 字符串或 `#RRGGBB` | [S15][S14] |
| `Color.mPrimary` | `"primary"` | [S15] |
| `Color.mOnSurface` | `"on_surface"` | [S15] |
| `Color.mOnSurfaceVariant` | `"on_surface_variant"` | [S15] |
| `Color.mSurfaceVariant` | `"surface_container"` (API 43) | [S8][S15] |
| `Color.mOutlineVariant` | `"outline_variant"` (API 43) | [S8][S15] |
| `Color.mError` | `"error"` | [S15] |
| `Process` + `SplitParser` | `noctalia.runStream(cmd, onLine)`; 一次性命令用 `runAsync` | [S16][S20] |
| `QtQuick.LocalStorage` / `KeyStats.js` | `noctalia.pluginDataDir()` + `noctalia.readFile/writeFile/json` | [S16] |
| `Panel.qml` 根 `Item`, `panelGeometry`, `contentPreferredWidth/Height`, `allowAttach` | `[[panel]]` 的 `width`/`height`/`placement`/`position`; `panel.render(tree)` | [S15][S13] |
| `Settings.qml` + `saveSettings()` | manifest `[[setting]]` schema; 宿主生成设置 UI, 无插件保存回调 | [S13][S16] |
| `Panel.qml` 的 `FocusScope`/`anchors` | 宿主管理焦点与布局; `keyboard_focus`, `capture_keys`, `dismiss_on_outside_click` | [S15] |
| `i18n/<lang>.json` + `pluginApi.tr` | `translations/<lang>.json` + `noctalia.tr/trp` | [S10][S16] |
| `Main.qml` | 无 `main` entry; 后台逻辑用 `[[service]]` | [S13] |
| `settings.json` | v5 不读; 设置存于 v5 settings.toml / state | [S12][S16] |

### 3.1 逐项说明

**导入.** v5 插件脚本没有 import 语句. 宿主在执行前注入全局 `noctalia`, `ui`, `barWidget`, `panel`, `shortcut`, `launcher`, `desktopWidget`, `layer` [S21]. 模块用 `require("./x.luau")` (API 22) [S14].

**pluginApi.** v5 没有 `pluginApi` 对象. 旧插件里所有 `pluginApi.*` 调用都要改写成全局命名空间或 `noctalia.*` [S21]. `pluginApi.openPanel(screen, root)` 的 screen/root 参数没有对应物; v5 用完整 entry id 打开面板 [S16].

**设置读写.** v5 插件不能写配置. `noctalia.getConfig(key)` 只读; 用户在 Settings GUI 修改, 宿主持久化 [S16][S13]. 需要运行时开关时用 `noctalia.state` (内存, 不持久化) 或自己写 `pluginDataDir()` 文件 [S16].

**BarWidget 尺寸/颜色.** v5 bar 胶囊由宿主绘制; 插件树被裁剪到 bar 厚度. 不要声明 `implicitWidth/Height`, 不要画 capsule 背景. 横向 bar 用 row, 纵向 bar 用 column; 用 `barWidget.isVertical()` 分支 [S15][S14]. v5 不向脚本传 `screen` / `widgetId` / `section`; 需要输出信息时用 `barWidget.outputName()`, 需要方向时用 `barWidget.isVertical()` [S21].

**点击.** `onClick`, `onRightClick`, `onMiddleClick`, `onScroll(axis, steps, startsGesture)` 是全局函数 [S14]. `onMiddleClick` 默认不会触发, 因为 v5 给每个 widget 内置 `middle = "settings-open-widget"`; 要覆盖需在 manifest 或用户配置里声明 `middle = "none"` [S13][S21].

**Panel.** v5 面板尺寸由 manifest 的 `width`/`height` 决定, 不是 QML 根属性; 打开时用 `panel.render(tree)` 渲染. `panel.close()` 关闭. 默认 `dismiss_on_outside_click = true`, `keyboard_focus = "on_demand"` [S15][S13][S21].

**Settings 页面.** v5 没有 `Settings.qml`. 设置控件由宿主根据 `[[setting]]` schema 生成. 插件只声明 key/type/label_key/default/min/max/options 等, 然后 `noctalia.getConfig(key)` 读取 [S13][S7]. `getConfig` 只解析已声明的 key; 未声明 key 返回 `nil` 并打警告 [S13]. 旧 `saveSettings()` 不存在. 如果确实需要自定义配置 UI, 应做成一个普通 `[[panel]]`, 用 `ui.toggle`/`ui.input`/`ui.select`/`ui.slider`/`ui.colorPicker` 等控件, 而不是 `Settings.qml` [S15].

**i18n.** v5 只读 `translations/<lang>.json`; 先加载 `en.json`, 再加载当前语言, 覆盖同名 key. 缺失 key 返回 key 本身并打警告, 没有 default 参数 [S10][S16]. 旧 `i18n/zh-CN.json` 应改为 `translations/zh-Hans.json`, 因为 v5 支持的语言代码是 `zh-Hans` / `zh-Hant`, 不是 `zh-CN` [S23].

**颜色.** v5 用 palette role 字符串 (`primary`, `on_surface`, `on_surface_variant`, `surface`, `error`, ...) 或 `#RRGGBB`. `surface_container` / `outline_variant` 等容器角色需要 `plugin_api >= 43` [S8][S15]. 旧 `Color.m*` 不能直接使用.

**进程.** `noctalia.runStream(cmd, onLine)` 是长驻进程的标准替代; 运行时会在脚本 reload/卸载/停止时终止流 [S16]. 官方 `bongocat` 用 `runStream` 读 `evtest` [S20]; 本机社区插件 `keyviz` 用 `runStream` 读 Python listener [S22].

**持久化.** `noctalia.state` 只在内存, plugin 停止即清空; 持久数据用 `noctalia.pluginDataDir()` + JSON 文件 [S16]. 旧 `QtQuick.LocalStorage` 的 SQLite 数据不会自动迁移.

## 4. 官方/本机 v5 代码示例

### 4.1 官方 `noctalia/example` bar widget

来源: `/tmp/official-plugins/example/plugin.toml:7-40`, `example/hello.luau:19-45` (commit `5dc1d19b1aa6be331ee6506034dc8448aca5c446`) [S19].

```toml
id = "noctalia/example"
name = "Example"
version = "1.4.1"
plugin_api = 43

[[widget]]
id = "hello"
entry = "hello.luau"

  [[widget.setting]]
  key = "label"
  type = "string"
  label_key = "settings.label.label"
  default = "Hello"
```

```lua
--!nonstrict
local label = noctalia.getConfig("label")
local glyph = noctalia.getConfig("glyph")
local showGlyph = noctalia.getConfig("show_glyph")

local function render()
  if showGlyph then
    barWidget.setGlyph(glyph)
  end
  barWidget.setText(label)
  barWidget.setTooltip(noctalia.tr("title"))
end

function update()
  noctalia.setUpdateInterval(1000)
  render()
end

function onClick()
  noctalia.notify(noctalia.tr("title"), "clicked")
  render()
end
```

要点: `plugin_api` 必填; `[[widget.setting]]` 的 default 是唯一默认值来源; `barWidget.*` 是全局; `noctalia.tr` 只传 key.

### 4.2 官方 `noctalia/timer` bar + panel

来源: `/tmp/official-plugins/timer/plugin.toml:44-66`, `timer/bar.luau:42-103` [S20].

```toml
[[widget]]
id = "bar"
entry = "bar.luau"

[[panel]]
id = "panel"
entry = "panel.luau"
width = 320
height = 280
placement = "attached"
position = "auto"
open_near_click = true

[[service]]
id = "timer"
entry = "service.luau"
```

```lua
-- bar.luau
local function render()
  if barWidget.isVertical() then
    barWidget.render(ui.column({ align = "center" }, {
      ui.glyph({ name = "hourglass" }),
    }))
  else
    barWidget.render(ui.row({ gap = 6, align = "center" }, {
      ui.glyph({ name = "hourglass", color = "primary" }),
      ui.label({ text = formattedTime, fontWeight = "bold" }),
    }))
  end
end

function onClick()
  noctalia.togglePanel("noctalia/timer:panel")
end
```

要点: `barWidget.render` 直接返回 UI 树; panel 尺寸在 manifest; 点击用 `noctalia.togglePanel(完整 entry id)`.

### 4.3 官方 `noctalia/bongocat` 读取键盘事件

来源: `/tmp/official-plugins/bongocat/bongocat.luau:206-255` [S20].

```lua
local command = "for device in " .. table.concat(patterns, " ")
  .. '; do [ -e "$device" ] || continue; ' .. quotedExecutable
  .. ' "$device" 2>/dev/null & done; wait'

if not noctalia.runStream(command, onEvtestLine) then
  noctalia.notifyError("Bongo Cat", "Unable to start input device reader")
end
```

这是 modifier-keys 最直接的参考: 长驻输入进程 + 逐行解析 + `noctalia.state` 广播. `runStream` 在脚本 reload/卸载时自动终止 [S16].

### 4.4 本机社区插件 `h-jangra/keyviz` (v5, 已 materialize)

来源: `/home/forty/.local/state/noctalia/plugins/materialized/community/keyviz/` [S22].

`plugin.toml` 片段:

```toml
id = "h-jangra/keyviz"
plugin_api = 13

[[service]]
id = "keylistener"
entry = "service.luau"

[[panel]]
id = "overlay"
entry = "overlay.luau"
width = 340
height = 48
placement = "floating"
position = "bottom_center"
persistent = true
dismiss_on_outside_click = false
keyboard_focus = "none"

[[widget]]
id = "widget"
entry = "widget.luau"
```

`service.luau:72-135`:

```lua
noctalia.runStream(`python3 -u "{script}"`, function(line)
  local ok, event = decodeJson(line)
  if not ok or type(event) ~= "table" then return end

  if event.type ~= "press" or not active then return end

  local combo = event.combo or event.key
  table.insert(keys, combo)
  noctalia.state.set("active_keys", copy)
  openPanel()
end)
```

`widget.luau:6-55`:

```lua
local function render()
  local isVert = barWidget.isVertical()
  local container = isVert and ui.column or ui.row
  barWidget.render(container({
    align = "center", justify = "center", gap = 6,
  }, {
    ui.glyph({ name = "keyboard", size = 14, color = isActive and "primary" or "on_surface_variant" }),
  }))
end

noctalia.state.watch("is_active", function(val)
  isActive = val == true
  render()
end)

function onClick()
  isActive = not isActive
  noctalia.state.set("is_active", isActive)
  render()
end
```

`overlay.luau:58-163` 用 `panel.render` 构造键帽 UI, 用 `noctalia.state.watch("active_keys", render)` 刷新.

要点: 这是与 modifier-keys 最接近的 v5 实例; 它证明了 `runStream` + `state` + `barWidget.render` + `panel.render` 的组合可行.

### 4.5 建议的 `modifier-keys` v5 manifest

以下为迁移建议, 不是官方代码. entry id 必须匹配本机已有配置 `forty/modifier-keys:bar` [S24].

```toml
id          = "forty/modifier-keys"
name        = "Modifier Keys"
version     = "2.0.0"
plugin_api  = 22          # 使用 require 模块; 不用模块可降到 15
author      = "forty"
license     = "MIT"
icon        = "keyboard"
description = "Display keyboard modifier keys status and trackpad gestures in the status bar"
tags        = ["bar", "indicator", "system"]
dependencies = ["libinput"]

[[setting]]
key             = "capture_command"
type            = "string"
label_key       = "settings.capture_command.label"
description_key = "settings.capture_command.description"
default         = "libinput debug-events --show-keycodes"

[[setting]]
key             = "modifier_symbols"
type            = "string"
label_key       = "settings.modifier.label"
description_key = "settings.modifier.description"
default         = ""

[[setting]]
key             = "gesture_symbols"
type            = "string"
label_key       = "settings.gesture.label"
description_key = "settings.gesture.description"
default         = ""

[[setting]]
key             = "fade_ms"
type            = "int"
label_key       = "settings.fade.label"
description_key = "settings.fade.description"
default         = 800
min             = 0
max             = 5000

[[setting]]
key             = "stats_retention_days"
type            = "int"
label_key       = "settings.stats_retention.label"
description_key = "settings.stats_retention.description"
default         = 30
min             = 1
max             = 3650

[[widget]]
id    = "bar"
entry = "bar.luau"

  [[widget.setting]]
  key       = "show_gesture"
  type      = "bool"
  label_key = "settings.show_gesture.label"
  default   = true

[[panel]]
id              = "panel"
entry           = "panel.luau"
width           = 640
height          = 500
placement       = "floating"
position        = "center"
open_near_click = true

[[service]]
id    = "input"
entry = "input.luau"
```

说明:

- `plugin_api = 22` 覆盖 `require("./stats.luau")` (API 22), `noctalia.openSettings()` (API 15), `string` 设置等 [S8].
- 如果不用模块, 且不使用 `surface_container` / `outline_variant`, 可降到 15.
- `dependencies = ["libinput"]` 只是提示; 不阻止启用 [S13].
- 旧的 `gestureSymbols` / `modifierSymbols` JSON 字符串保留为 `string` 设置, 迁移成本最低; 后续可改成 `string_map` 或 `glyph` 类型 [S13].

### 4.6 建议的 service/bar/panel 骨架

`input.luau`:

```lua
--!nonstrict
local MOD_KEYS = {
  LEFTMETA = "super", RIGHTMETA = "super",
  LEFTALT = "alt", RIGHTALT = "alt",
  LEFTCTRL = "ctrl", RIGHTCTRL = "ctrl",
  LEFTSHIFT = "shift", RIGHTSHIFT = "shift",
}

local Stats = require("./stats.luau")

local mods = { super = false, alt = false, ctrl = false, shift = false }
local keys = {}
local gesture = nil

local function publish()
  noctalia.state.set("mods", mods)
  noctalia.state.set("keys", keys)
  noctalia.state.set("gesture", gesture)
  noctalia.state.set("stats", Stats.snapshot())
end

local function handle(line)
  -- 这里复用旧 BarWidget.qml:352-603 的 parseLibinputLine 逻辑
  -- 按键按下时调用 Stats.record(keyName, activeModifiers)
end

local command = noctalia.getConfig("capture_command")
  or "libinput debug-events --show-keycodes"

if not noctalia.runStream(command, handle) then
  noctalia.notifyError("Modifier Keys", "cannot start: " .. command)
end

function update()
  Stats.flushIfDue()
  publish()
end

function onExit()
  -- runStream 由宿主终止; 这里只做统计 flush
  Stats.flush()
end

publish()
```

注意: `input.luau` 不要定义 `onConfigChanged()`. v5 对定义了该回调的 service 只做原地设置更新; 不定义时会在设置变更后重启 service, 从而用新的 `capture_command` 重新启动 `runStream` [S14]. 另外, v5 `runStream` 没有进程退出回调; 旧插件的 `restartTimer` 需要改成 shell 监督循环 (例如 `while true; do libinput debug-events --show-keycodes; sleep 1; done`) 或用 `runAsync` 回调自行重启 [S16][S26].

`bar.luau`:

```lua
--!nonstrict
local mods = noctalia.state.get("mods") or { super = false, alt = false, ctrl = false, shift = false }
local keys = noctalia.state.get("keys") or {}
local gesture = noctalia.state.get("gesture")

local DEFAULT_SYMBOLS = { super = "⌘", alt = "⌥", ctrl = "⌃", shift = "⇧" }

local function readSymbols()
  local raw = noctalia.getConfig("modifier_symbols")
  if type(raw) == "string" and raw ~= "" then
    local ok, decoded = pcall(noctalia.json.decode, raw)
    if ok and type(decoded) == "table" then return decoded end
  end
  return DEFAULT_SYMBOLS
end

local function render()
  local sym = readSymbols()
  local vertical = barWidget.isVertical()
  local container = vertical and ui.column or ui.row
  local children = {}

  for _, name in ipairs({ "super", "alt", "ctrl", "shift" }) do
    table.insert(children, ui.label({
      text = sym[name] or name,
      color = mods[name] and "primary" or "on_surface_variant",
      opacity = mods[name] and 1.0 or 0.45,
      fontWeight = "bold",
    }))
  end

  local last = keys[#keys]
  if last then
    table.insert(children, ui.label({ text = last, color = "primary", fontWeight = "bold" }))
  end

  if noctalia.getConfig("show_gesture") ~= false and gesture then
    table.insert(children, ui.label({ text = gesture, color = "primary" }))
  end

  barWidget.render(container({ gap = 4, align = "center" }, children))
end

noctalia.state.watch("mods", function(value)
  if type(value) == "table" then mods = value end
  render()
end)
noctalia.state.watch("keys", function(value)
  keys = type(value) == "table" and value or {}
  render()
end)
noctalia.state.watch("gesture", function(value)
  gesture = value
  render()
end)

function update() render() end
function onClick() noctalia.togglePanel("forty/modifier-keys:panel") end
function onRightClick() noctalia.openSettings() end
function onConfigChanged() render() end

render()
```

`panel.luau`:

```lua
--!nonstrict
local tab = "help"
local mods = {}
local stats = {}

local render

local function tabButton(id, label)
  return ui.button({
    text = label,
    variant = tab == id and "primary" or "ghost",
    onClick = function()
      tab = id
      render()
    end,
  })
end

local function helpView()
  return ui.scroll({ flexGrow = 1, gap = 8 }, {
    ui.label({ text = noctalia.tr("help"), fontSize = 16, fontWeight = "bold" }),
    ui.label({ text = noctalia.tr("gestures") }),
  })
end

local function statsView()
  return ui.scroll({ flexGrow = 1, gap = 8 }, {
    ui.label({ text = noctalia.tr("stats.title"), fontSize = 16, fontWeight = "bold" }),
    ui.label({ text = noctalia.tr("stats.totalKeypresses") .. ": " .. tostring(stats.total or 0) }),
  })
end

function render()
  panel.render(ui.column({ gap = 12, flexGrow = 1 }, {
    ui.row({ gap = 8, justify = "space_between" }, {
      ui.row({ gap = 8 }, {
        tabButton("help", noctalia.tr("help")),
        tabButton("stats", noctalia.tr("stats.title")),
      }),
      ui.button({ glyph = "close", onClick = "onCloseClicked" }),
    }),
    tab == "help" and helpView() or statsView(),
  }))
end

function onOpen()
  mods = noctalia.state.get("mods") or {}
  stats = noctalia.state.get("stats") or {}
  render()
end

function onClose() end
function onCloseClicked() panel.close() end

noctalia.state.watch("mods", function(value)
  mods = type(value) == "table" and value or {}
  render()
end)
noctalia.state.watch("stats", function(value)
  stats = type(value) == "table" and value or {}
  render()
end)

render()
```

注意: `stats.luau` 只应由 `input.luau` require. v5 每个 entry 有独立的模块缓存, panel/bar 再 require 同一模块会得到不同实例, 还可能并发写同一个 JSON 文件. panel 通过 `noctalia.state` 读取 service 发布的统计快照 [S14][S16].

说明:

- panel 的尺寸在 manifest, 不要写 QML 根属性 [S15].
- `ui.scroll` 在 panel 中可用; 在 bar widget 中会被跳过 [S15].
- 闭包回调需要 API 9, 本方案 `plugin_api = 22` 满足 [S8].

### 4.7 建议的 i18n 目录

```text
modifier-keys/
├── plugin.toml
├── bar.luau
├── input.luau
├── panel.luau
├── stats.luau
├── translations/
│   ├── en.json
│   └── zh-Hans.json
├── README.md            # 已有, 发布用
├── thumbnail.webp       # 发布用, 960x540
├── manifest.json        # 保留给 v4
├── BarWidget.qml        # 保留给 v4
├── Panel.qml            # 保留给 v4
└── Settings.qml         # 保留给 v4
```

`translations/en.json` 片段:

```json
{
  "title": "Modifier Keys",
  "help": "Help",
  "gestures": "Gestures",
  "stats": {
    "title": "Statistics",
    "totalKeypresses": "Total Keypresses"
  },
  "settings": {
    "capture_command": {
      "label": "Capture command",
      "description": "Command used to read input events"
    },
    "modifier": {
      "label": "Modifier symbols",
      "description": "JSON object for super/alt/ctrl/shift symbols"
    },
    "gesture": {
      "label": "Gesture symbols",
      "description": "JSON object for gesture symbols"
    },
    "fade": {
      "label": "Fade duration",
      "description": "How long the key display stays visible in milliseconds"
    },
    "stats_retention": {
      "label": "Statistics retention",
      "description": "Number of days to keep key statistics"
    },
    "show_gesture": {
      "label": "Show gesture symbol"
    }
  }
}
```

注意:

- v5 的 `label_key`/`description_key` 必须是全小写点路径; 旧 key `settings.modifierKeys` 含大写, 发布校验会拒绝 [S19].
- `translations/en.json` 中每个对象 key 不能含点; 嵌套用对象表达 [S19].
- 其他语言由 i18n 平台同步; 本地至少保留 `en.json`, 中文用 `zh-Hans.json` [S23].

## 5. 对 modifier-keys 的具体影响

### 5.1 文件级影响

| 旧文件 | v5 处理 | 说明 |
|---|---|---|
| `manifest.json` | 保留给 v4; 新增 `plugin.toml` | v5 不读 manifest.json [S7] |
| `BarWidget.qml` (767 行) | 重写为 `bar.luau` | 输入解析与显示逻辑可复用; QML 组件/尺寸/颜色全部废弃 [S7][S21] |
| `Panel.qml` (95 行) | 重写为 `panel.luau` | `panel.render` + `panel.close`; 无 QML 根/anchors [S15] |
| `Settings.qml` (221 行) | 删除 v5 对应; 改为 `plugin.toml` 的 `[[setting]]` | 无 `saveSettings`; 宿主生成设置 UI [S13][S16] |
| `KeyStats.js` (280 行) | 重写为 `stats.luau`, 只由 service 使用 | `QtQuick.LocalStorage` 不可用; 改 JSON 文件; 避免多 entry 模块实例并发写 [S14][S16] |
| `HelpTab.qml` (137 行) | 合并进 `panel.luau` 的 help view | UI 树用 `ui.*` [S15] |
| `StatsTab.qml` (409 行) | 合并进 `panel.luau` 的 stats view | 统计数据从 `noctalia.state.get("stats")` 读取 [S16] |
| `i18n/en.json` | 移到 `translations/en.json` | 键格式可保留嵌套 [S10] |
| `i18n/zh-CN.json` | 改名为 `translations/zh-Hans.json` | v5 语言代码是 `zh-Hans` [S23] |
| `settings.json` | v5 不读 | 旧用户设置不会迁移 [S6] |

### 5.2 功能映射

| 旧功能 | v5 实现 |
|---|---|
| `Process` 运行 `libinput debug-events` | `noctalia.runStream(command, onLine)` 放在 `[[service]]` [S16][S20] |
| 解析 `KEYBOARD_KEY` / `POINTER_BUTTON` / `GESTURE_*` | 原样移植到 `input.luau` 的 `handle(line)`; Luau 字符串/正则能力足够 |
| modifier 状态 | `mods` 表 + `noctalia.state.set("mods", mods)` [S16] |
| 普通按键显示 | `keys` 数组 + `state.set("keys", keys)` [S16] |
| 手势显示 | `gesture` 字符串 + `state.set("gesture", gesture)` [S16] |
| bar 显示 | `bar.luau` 的 `barWidget.render(ui.row/column(...))` [S15] |
| 横向/纵向 bar | `barWidget.isVertical()` [S21] |
| 左键打开面板 | `onClick()` -> `noctalia.togglePanel("forty/modifier-keys:panel")` [S16] |
| 右键打开设置 | `onRightClick()` -> `noctalia.openSettings()` [S16] |
| panel 帮助/统计 tab | `panel.luau` 内部 `tab` 状态 + `ui.button` + 重新 `panel.render` [S15] |
| 自定义符号设置 | `[[setting]]` 的 `modifier_symbols` / `gesture_symbols` 字符串; `noctalia.getConfig` 读取 [S13] |
| 统计记录 | service 独占 `stats.luau` + `pluginDataDir()/stats.json`; 定期 flush, 通过 `state` 发布快照 [S14][S16] |
| 统计清空 | panel 的 `ui.button` -> `stats.clear()` + `stats.save()` [S16] |
| 旧设置 JSON | 不迁移; 用户重新填写或写一次性迁移脚本 |
| 旧统计 SQLite | 不迁移; 如需保留, 手工导出旧 DB 后转 JSON (见不确定项) |

### 5.3 入口 id 与现有 v5 配置

本机 v5 配置已经写死:

- `[plugins].enabled` 包含 `"forty/modifier-keys"` [S24].
- `[widget.bar]`, `[widget.bar_2]`, `[widget.bar_3]` 的 `type = "forty/modifier-keys:bar"` [S24].

因此:

- `plugin.toml` 的 `id` 必须是 `forty/modifier-keys`.
- `[[widget]]` 的 `id` 必须是 `bar`.
- `[[panel]]` 的 id 建议 `panel`; bar 的 `onClick` 用 `noctalia.togglePanel("forty/modifier-keys:panel")`.
- `[[service]]` 的 id 建议 `input`; 不需要出现在 bar 配置中.
- 迁移后无需修改现有 bar 配置; 只需启用 `forty` path source.

### 5.4 安装/启用步骤 (建议)

1. 在 `/home/forty/code/fortystory/noctalia-plugins/modifier-keys/` 新增 `plugin.toml`, `bar.luau`, `input.luau`, `panel.luau`, `stats.luau`, `translations/en.json`, `translations/zh-Hans.json` [S12][S17].
2. 启用 v5 的 path source `forty`:
   - 当前 `settings.toml:357-361` 是 `enabled = false` [S24].
   - 可在 Settings -> Plugins 中打开该 source 的开关; 或把 `enabled` 改为 `true`/删除该行后 reload.
   - 具体 CLI 是否有 `source enable` 未在文档中列出 (见不确定项).
3. 重新扫描/重载:
   - `noctalia msg plugins list` 应出现 `forty/modifier-keys`.
   - `noctalia msg plugins enable forty/modifier-keys` 或 Settings 中启用 [S12].
4. 验证:
   - bar 上三处 `bar` widget 应显示.
   - `noctalia msg panel-toggle forty/modifier-keys:panel` 打开面板 [S17].
   - 右键 bar 应打开插件设置页 (`noctalia.openSettings()`).
5. 发布 (可选):
   - 在仓库根新增 `catalog.toml`, 包含 `[[plugin]] id="forty/modifier-keys"` 等字段 [S17].
   - 补 `thumbnail.webp` (960x540) 和完整 `translations/en.json` [S17][S19].
   - 旧 `registry.json` 对 v5 无效, 可保留给 v4 或删除.

### 5.5 可直接复用的旧逻辑

- `BarWidget.qml:352-603` 的 libinput 行解析, modifier 状态机, 手势/缩放/移动识别逻辑, 以及 `:188-217` 的按键缓冲逻辑, 可以逐段翻译成 Luau. 这部分与 UI 无关.
- `BarWidget.qml` 的默认符号表 (`super/alt/ctrl/shift`, scroll/swipe3/swipe4/click/... ) 可原样作为 Luau 表 [S26].
- `KeyStats.js` 的统计聚合逻辑 (按天/周/月/全部, top keys/shortcuts) 可翻译成 Luau; 只需把 SQLite 换成 JSON 文件 [S26].
- `HelpTab.qml` / `StatsTab.qml` 的文案与布局意图可复用, 但控件要改成 `ui.*` [S26].

### 5.6 必须废弃的部分

- 所有 `import` 和 QML 类型 (`Item`, `Rectangle`, `MouseArea`, `Loader`, `Repeater`, `Text`, `ColumnLayout`, ...) [S7].
- `pluginApi.*` 全部调用 [S21].
- `Settings.data.*` / `Style.*` / `Color.m*` [S15].
- `QtQuick.LocalStorage` [S16].
- `Settings.qml` 的 `saveSettings()` 模式 [S13].
- `Panel.qml` 的 `panelGeometry` / `contentPreferredWidth` / `allowAttach`; v5 panel 没有这些 QML 属性 [S15].

## 6. 不确定项

1. **`forty` path source 的启用方式.** 当前 `settings.toml` 中 `enabled = false` [S24]. 文档只列出 `plugins source list/add/remove`, 没列出 `source enable` [S12]. 需要通过 Settings GUI 或手改 settings.toml 后 reload. 未在本机实际修改验证.
2. **`forty/modifier-keys` 在 source 启用后是否会自动加载.** 它已在 `[plugins].enabled` 和 bar 配置中 [S24], 但 path source 被禁用时不会扫描 [S12]. 预期启用 source 后会直接加载; 需实际验证.
3. **`libinput debug-events` 在 `runStream` 下的行缓冲行为.** 官方 `bongocat` 使用 `evtest` 验证可行 [S20]; `keyviz` 使用 Python 直接读 `/dev/input` [S22]. 旧插件使用 `libinput debug-events`; `runStream` 逐行回调理论上可用, 但未在本机 v5 实测. 若出现缓冲/权限问题, 改用 `evtest` 或 Python listener.
4. **旧统计 SQLite 的位置与迁移.** `QtQuick.LocalStorage` 的数据库路径依赖 v4 Quickshell 实现, 本次未定位/导出. v5 不会自动读取. 如需保留历史统计, 需要单独写迁移脚本; 否则从空统计开始.
5. **旧用户设置不迁移.** v5 明确不迁移 v4 设置 [S6][S18]; 旧 `gestureSymbols` / `modifierSymbols` 值不会出现在 `[plugin_settings."forty/modifier-keys"]`. 用户需重新配置, 或在 `plugin.toml` 中把旧默认值作为 default.
6. **`plugin_api` 具体取值.** 本文建议 22 (require 模块 + openSettings). 如果去掉 `require`, 可降到 15; 如果使用 `surface_container` / `outline_variant` 颜色角色, 需要 43 [S8]. 最终取值取决于实现.
7. **颜色角色选择.** 旧 `Color.mSurfaceVariant` / `mOutlineVariant` 在 v5 API 43 中改名为 `surface_container` / `outline_variant` [S8]; 如果不想抬高 API level, 可只用 `surface` / `on_surface` / `on_surface_variant` / `primary` / `error`.
8. **v5.5.0 文档与 main 文档的 API 上限差异.** v5.5.0 文档写 3-53 [S13]; main/rolling 文档写 3-55. 本机 v5.5.0 源码 `plugin_api.h` 当前是 53 [S8]. 以 v5.5.0 为准, 不要使用 54/55 的新能力.
9. **旧 `qs`/v4 测试环境.** 本机 `qs` 当前报 Qt private API 符号错误 (`qs: symbol lookup error`), 因此不能依赖 v4 shell 做对照测试. v4 插件仍保留在 `~/.config/noctalia/plugins/`, 但 v5 不加载 [S2][S25].
10. **文档 URL 迁移.** 任务中给的 `https://docs.noctalia.dev/development/plugins/overview/` 返回 404; 当前 v5.5.0 插件文档路径是 `https://docs.noctalia.dev/noctalia/v5.5.0/plugins/development/...` [S12]. 旧链接不可用.

## 7. 来源清单

- [S1] 本机命令输出: `noctalia --version` -> `noctalia v5.5.0 (v5.5.0-43-g4e1dcb6eb2da)`; `pacman -Q noctalia-git` -> `1:5.5.0.r6391.g4e1dcb6eb-1`; `/usr/bin/noctalia` 为 ELF. 二进制字符串计数: `plugin.toml`=5, `.luau`=2, `manifest.json`=0, `entryPoints`=0; 另含 `catalog.toml`, `plugin_api`, `LuauHost`, `openSettings`, `barWidget`.
- [S2] `pacman -Q noctalia-shell noctalia-qs` -> `4.7.7-4`, `0.0.12-3`; `pacman -Qo /etc/xdg/quickshell/noctalia-shell/shell.qml` -> `noctalia-shell 4.7.7-4`; `pacman -Qo /usr/bin/noctalia` -> `noctalia-git`.
- [S3] 本机命令输出: `noctalia msg plugins source list`; `noctalia msg plugins list` (378 行); `find ~/.local/state/noctalia/plugins/materialized -name plugin.toml`.
- [S24] 本机配置 `/home/forty/.local/state/noctalia/settings.toml:333-366` (`[plugins]`, sources) 与 `:461-468` (`[widget.bar*] type = "forty/modifier-keys:bar"`).
- [S25] 本机 v4 插件: `/home/forty/.config/noctalia/plugins/network-indicator/manifest.json:1-36`; `show-keys/Main.qml:1-15`; `privacy-indicator/BarWidget.qml:1-12`; `modifier-keys/manifest.json:1-24`; `BarWidget.qml:1-22,312-329,733-766`; `Panel.qml:8-17`; `Settings.qml:190-218`; `KeyStats.js:4,25-29`. 旧仓库 `github.com/noctalia-dev/noctalia-plugins` 301 -> `legacy-v4-plugins`; README 标题 "Noctalia Legacy V4 Plugins Registry".
- [S6] 本机克隆 `noctalia` tag v5.5.0 commit `c2573248a89470383e41b8e1ac432424691cbc1f`: `/tmp/noctalia-5.5/docs/user/getting-started/faq.mdx:26-31`; `docs/user/getting-started/installation.mdx:30-36`; `docs/user/index.mdx:12-16`; `CONTRIBUTING.md:132`. GitHub: `https://github.com/noctalia-dev/noctalia/blob/c2573248a89470383e41b8e1ac432424691cbc1f/docs/user/getting-started/faq.mdx#L26-L31`.
- [S7] `/tmp/noctalia-5.5/src/scripting/plugin_manifest.cpp:336-395` (settings schema), `:413-456` (entry parsing), `:846-873` (required id/name/version/plugin_api). GitHub: `https://github.com/noctalia-dev/noctalia/blob/c2573248a89470383e41b8e1ac432424691cbc1f/src/scripting/plugin_manifest.cpp`.
- [S8] `/tmp/noctalia-5.5/src/scripting/plugin_api.h:7-62`; current API 53, supported range 3-53. GitHub: `https://github.com/noctalia-dev/noctalia/blob/c2573248a89470383e41b8e1ac432424691cbc1f/src/scripting/plugin_api.h#L7-L62`.
- [S9] `/tmp/noctalia-5.5/src/scripting/plugin_source_paths.cpp:24-48` (sources/materialized/data/local data dir). GitHub: `https://github.com/noctalia-dev/noctalia/blob/c2573248a89470383e41b8e1ac432424691cbc1f/src/scripting/plugin_source_paths.cpp#L24-L48`.
- [S10] `/tmp/noctalia-5.5/src/scripting/plugin_i18n.cpp:46-50` (en then current language), `:55-61` (missing key returns key). GitHub: `https://github.com/noctalia-dev/noctalia/blob/c2573248a89470383e41b8e1ac432424691cbc1f/src/scripting/plugin_i18n.cpp#L46-L61`.
- [S11] `/tmp/noctalia-5.5/src/scripting/plugin_catalog.cpp:260-280` (path source scan / catalog optional), `:325-333` (git source requires catalog.toml); `plugin_lint.cpp:503-530` (only plugin.toml); source tree grep for `manifest.json`/`entryPoints`/`.qml`/`Quickshell` no matches. GitHub: `https://github.com/noctalia-dev/noctalia/blob/c2573248a89470383e41b8e1ac432424691cbc1f/src/scripting/plugin_catalog.cpp#L260-L333`.
- [S12] `/tmp/noctalia-5.5/docs/user/plugins/index.mdx:11` (Luau/TOML), `:22` (materialized), `:28` (settings persist state dir), `:52` (entry ids), `:88` (local data dir), `:114` (API range). URL: `https://docs.noctalia.dev/noctalia/v5.5.0/plugins/`.
- [S13] `/tmp/noctalia-5.5/docs/user/plugins/development/manifest.mdx:14-30` (required fields), `:38-50` (entry kinds), `:84` (middle click), `:131-193` (settings schema). URL: `https://docs.noctalia.dev/noctalia/v5.5.0/plugins/development/manifest/`.
- [S14] `/tmp/noctalia-5.5/docs/user/plugins/development/entries.mdx:13-30` (callbacks), `:66-72` (pointer callbacks/middle), `:105` (scroll gating), `:169-174` (service settings reload/restart), `:251-262` (barWidget reference). URL: `https://docs.noctalia.dev/noctalia/v5.5.0/plugins/development/entries/`.
- [S15] `/tmp/noctalia-5.5/docs/user/plugins/development/declarative-ui.mdx:151-173` (barWidget.render), `:177-200` (panel render/size), `:248-265` (keyboard focus/persistent panels). URL: `https://docs.noctalia.dev/noctalia/v5.5.0/plugins/development/declarative-ui/`.
- [S16] `/tmp/noctalia-5.5/docs/user/plugins/development/runtime-api.mdx:259-299` (subprocess/runStream), `:315-330` (pluginDataDir/persistence), `:533-540` (tr/trp), `:551-563` (state). URL: `https://docs.noctalia.dev/noctalia/v5.5.0/plugins/development/runtime-api/`.
- [S17] `/tmp/noctalia-5.5/docs/user/plugins/development/workflow.mdx:11` (local dev path), `:32-49` (catalog), `:76` (required publishing files). URL: `https://docs.noctalia.dev/noctalia/v5.5.0/plugins/development/workflow/`.
- [S18] `/tmp/noctalia-5.5/docs/user/getting-started/faq.mdx:26-31` (v5 fresh install, v4 settings not migrated); `docs/user/getting-started/installation.mdx:30-36`.
- [S19] 官方 v5 插件仓库 commit `5dc1d19b1aa6be331ee6506034dc8448aca5c446`, 本机克隆 `/tmp/official-plugins`: `example/plugin.toml:7-40`, `example/hello.luau:19-45`, `example/panel.luau:49-90`; `.github/actions/validate-plugins/validate-plugins.py:74-115` (id/translation/required files). URL: `https://github.com/noctalia-dev/official-plugins`.
- [S20] `/tmp/official-plugins/timer/plugin.toml:44-66`, `timer/bar.luau:42-103`; `bongocat/bongocat.luau:206-255`; `bongocat/plugin.toml:19-58`.
- [S21] `/tmp/official-plugins/noctalia.d.luau:1` (plugin_api 53), `:280-425` (noctalia API), `:935-954` (barWidget), `:994-1002` (panel), `:1012-1038` (callbacks).
- [S22] 本机已 materialize 的 v5 社区插件 `/home/forty/.local/state/noctalia/plugins/materialized/community/keyviz/`: `plugin.toml:1-112`, `service.luau:72-135`, `widget.luau:6-55`, `overlay.luau:58-163`.
- [S23] `/tmp/noctalia-5.5/src/shell/settings/supported_languages.h:43` -> `{"zh-Hans", "简体中文"}`; official plugins `translations/zh-Hans.json` (e.g. `example/translations/zh-Hans.json`). GitHub: `https://github.com/noctalia-dev/noctalia/blob/c2573248a89470383e41b8e1ac432424691cbc1f/src/shell/settings/supported_languages.h#L43`.
- [S26] 旧插件 `modifier-keys` 源文件行号: `manifest.json:1-24`, `BarWidget.qml:1-22,188-217,312-339,352-603,733-766`, `Panel.qml:8-17`, `Settings.qml:190-218`, `KeyStats.js:4,25-29`, `StatsTab.qml:80-82,401`, `HelpTab.qml:44-80`; 旧 `i18n/en.json`, `i18n/zh-CN.json`.

## 8. 一句话建议

保留 v4 的 QML 文件与 `manifest.json` 作为 legacy 版本, 在同一个 `modifier-keys/` 目录新增 `plugin.toml` + `bar.luau` + `input.luau` + `panel.luau` + `stats.luau` + `translations/`, 使用 `noctalia.runStream` 接 `libinput debug-events`, 用 `noctalia.state` 在 service/bar/panel 之间共享状态, widget id 固定为 `bar`, 然后启用 v5 的 `forty` path source. 这样既不影响 v4, 也能让现有 v5 bar 配置直接生效.
