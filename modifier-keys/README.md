# Modifier Keys

在状态栏显示键盘修饰键（Super、Alt、Ctrl、Shift）的按下状态，并支持显示最近按下的普通按键。

## 功能

- 实时显示 4 个修饰键状态：⌘ ⌥ ⌃ ⇧
- 按键按下时图标高亮显示（颜色变化）
- 显示最近按下的普通按键（最多1个）
- 延迟消失机制：按键松开后延迟0.5秒再消失
- 点击显示帮助面板，展示各键名称

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

需要将当前用户加入 `input` 用户组以读取键盘事件：

```bash
sudo usermod -aG input $USER
```

然后重新登录或重启系统使权限生效。

## 安装

将插件复制到 Noctalia Shell 插件目录：

```bash
./tools/deploy.sh
```

## 使用

- 状态栏显示 4 个图标，分别对应 Super、Alt、Ctrl、Shift 键
- 按下对应按键时，图标会变亮并显示强调色
- 按下普通按键时，会在修饰键后面显示（最多1个）
- 松开按键后，延迟0.5秒再消失
- 点击图标区域可打开帮助面板

## 显示示例

- 单独按 `j`：显示 `j`（0.5秒后消失）
- 按 `Shift + j`：显示 `⇧ j`（修饰键高亮，0.5秒后消失）
- 按 `Ctrl + c`：显示 `⌃ c`（修饰键高亮，0.5秒后消失）
