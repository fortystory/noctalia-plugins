import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property bool isVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"

    // Modifier key states
    property bool shiftPressed: false
    property bool ctrlPressed: false
    property bool altPressed: false
    property bool superPressed: false

    // Normal keys (max 5)
    property var pressedKeys: []

    readonly property real visualContentWidth: rowLayout.implicitWidth + Style.marginS * 2
    readonly property real visualContentHeight: rowLayout.implicitHeight + Style.marginS * 2

    readonly property real contentWidth: Math.max(80, isVertical ? Style.capsuleHeight : visualContentWidth)
    readonly property real contentHeight: Math.max(28, isVertical ? visualContentHeight : Style.capsuleHeight)

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Component.onCompleted: {
        Logger.d("Modifier Keys", "BarWidget loaded");
    }

    // Key display name mapping (Nerd Fonts symbols)
    // 始终显示原始键值，不根据修饰键状态转换
    function getKeyDisplayName(keyName) {
        const keyMap = {
            // Function keys
            "F1": "󱊫", "F2": "󱊬", "F3": "󱊭", "F4": "󱊮", "F5": "󱊯", "F6": "󱊰",
            "F7": "󱊱", "F8": "󱊲", "F9": "󱊳", "F10": "󱊴", "F11": "󱊵", "F12": "󱊶",
            // Navigation keys (Nerd Fonts)
            "HOME": "", "END": "", "PAGEUP": "", "PAGEDOWN": "",
            "INSERT": "", "DELETE": "󰹾",
            // Arrow keys (Nerd Fonts)
            "UP": "↑", "DOWN": "↓", "LEFT": "←", "RIGHT": "→",
            // Media keys (Nerd Fonts)
            "PLAYPAUSE": "󰐎", "PAUSE": "", "STOP": "", "PREVIOUS": "󰒮", "NEXT": "󰒭",
            "PREVIOUSSONG": "󰒮", "NEXTSONG": "󰒭",
            "MUTE": "", "VOLUMEUP": "", "VOLUMEDOWN": "",
            // Special keys (Nerd Fonts)
            "SPACE": "󱁐", "TAB": "", "ENTER": "󰌑", "ESCAPE": "⎋","ESC":"⎋",
            "BACKSPACE": "󰁮", "CAPSLOCK": "⇪", "PRINT": "\uf57d",
            "NUMLOCK": "\uf7c3", "SCROLLLOCK": "\uf86c",
            // Modifiers (for display, though handled separately)
            "LEFTSHIFT": "\uf17d", "RIGHTSHIFT": "\uf17e",
            "LEFTCTRL": "\uf201", "RIGHTCTRL": "\uf202",
            "LEFTALT": "\uf19a", "RIGHTALT": "\uf19b",
            "LEFTMETA": "\uf17b", "RIGHTMETA": "\uf17c",
            //symbls
            "SLASH":"/","BACKSLASH":"\\","APOSTROPHE":"\"","SEMICOLON":";","LEFTBRACE":"[","RIGHTBRACE":"]",
            "COMMA":",","DOT":".","KPPLUS":"+","MINUS":"-","EQUAL":"=","GRAVE":"`"
        };

        if (keyMap[keyName]) return keyMap[keyName];

        // Letters A-Z - 始终显示小写（原始键值）
        if (/^[A-Z]$/.test(keyName)) {
            return keyName.toLowerCase();
        }

        // Numbers 0-9 - 始终显示数字（原始键值）
        if (/^[0-9]$/.test(keyName)) {
            return keyName;
        }

        // Other keys - return as-is
        return keyName;
    }

    // Display keys (for showing, with fade delay)
    property var displayKeys: []

    // 是否处于延迟显示状态
    property bool isFading: false

    // 记录在按下普通键时哪些修饰键是激活的（用于延迟时高亮）
    property bool shiftInCombo: false
    property bool ctrlInCombo: false
    property bool altInCombo: false
    property bool superInCombo: false

    // 单独按修饰键时的延迟状态
    property bool shiftFading: false
    property bool ctrlFading: false
    property bool altFading: false
    property bool superFading: false

    // Trackpad gesture state
    property string gestureSymbol: ""
    property bool gestureActive: false
    property bool gestureFading: false

    // 累计滚动/滑动距离（用于判断方向）
    property real gestureDeltaX: 0
    property real gestureDeltaY: 0
    property int gestureFingerCount: 0

    // Gesture symbols (Nerd Fonts)
    // 方向: 左 上 右 下
    readonly property var scrollSymbols: ["⇇", "⇈", "⇉", "⇊"] // ⇇⇈⇉⇊
    readonly property var swipe3Symbols: ["󰛁", "󰛃", "󰛂", "󰛀"] // 󰛁󰛃󰛂󰛀
    readonly property var swipe4Symbols: ["󰧘", "󰧜", "󰧚", "󰧖"] // 󰧘󰧜󰧚󰧖
    readonly property string clickSymbol: "󰳽 " // 󰳽 左键点击
    readonly property string rightClickSymbol: "󰳾" // 󰳾 右键点击
    readonly property string middleClickSymbol: "󰻃" // 󰻃 中键点击
    readonly property string motionSymbol: "󰆽" // 󰆽 光标移动

    // 光标移动状态
    property bool motionActive: false

    // Add key to pressed keys list
    function addKey(keyName) {
        // Don't add modifier keys to the list
        const modifiers = ["LEFTSHIFT", "RIGHTSHIFT", "LEFTCTRL", "RIGHTCTRL",
                          "LEFTALT", "RIGHTALT", "LEFTMETA", "RIGHTMETA"];
        if (modifiers.includes(keyName)) return;

        // Check if already in list
        for (let i = 0; i < pressedKeys.length; i++) {
            if (pressedKeys[i] === keyName) return;
        }

        // 按下新普通键时，清除所有之前的修饰键 fading 状态
        // 只根据当前是否按下来决定高亮
        shiftFading = false;
        ctrlFading = false;
        altFading = false;
        superFading = false;

        // 重新检查当前修饰键状态
        shiftInCombo = shiftPressed;
        ctrlInCombo = ctrlPressed;
        altInCombo = altPressed;
        superInCombo = superPressed;

        // Add to list (max 1 keys)
        const newKeys = pressedKeys.slice();
        newKeys.push(keyName);
        if (newKeys.length > 1) {
            newKeys.shift(); // Remove oldest
        }
        pressedKeys = newKeys;

        // Update display immediately (only keep 1)
        displayKeys = [newKeys[newKeys.length - 1]];
        isFading = false;

        // 停止之前的定时器，按键按下时不启动定时器
        fadeTimer.stop();
    }

    // Remove key from pressed keys list
    function removeKey(keyName) {
        const newKeys = [];
        for (let i = 0; i < pressedKeys.length; i++) {
            if (pressedKeys[i] !== keyName) {
                newKeys.push(pressedKeys[i]);
            }
        }
        pressedKeys = newKeys;

        // 始终更新 displayKeys 为当前按下的键（只保留最新1个）
        if (pressedKeys.length > 0) {
            displayKeys = [pressedKeys[pressedKeys.length - 1]];
            isFading = true;
            fadeTimer.stop();
            fadeTimer.start();
        } else {
            // 所有键都松开了，进入延迟状态
            // 保持 displayKeys 不变（最后按下的键）
            isFading = true;
            fadeTimer.stop();
            fadeTimer.start();
        }
    }

    // Timer for fade delay (2 seconds)
    Timer {
        id: fadeTimer
        interval: 500
        onTriggered: {
            displayKeys = [];
            isFading = false;
            // 清除组合标记
            shiftInCombo = false;
            ctrlInCombo = false;
            altInCombo = false;
            superInCombo = false;
        }
    }

    // Timer for modifier key fade delay (2 seconds)
    Timer {
        id: modifierFadeTimer
        interval: 500
        onTriggered: {
            shiftFading = false;
            ctrlFading = false;
            altFading = false;
            superFading = false;
        }
    }

    // Timer for gesture fade delay
    Timer {
        id: gestureFadeTimer
        interval: 500
        onTriggered: {
            gestureSymbol = "";
            gestureFading = false;
            gestureActive = false;
            gestureDeltaX = 0;
            gestureDeltaY = 0;
            gestureFingerCount = 0;
        }
    }

    // Timer for motion fade delay
    Timer {
        id: motionFadeTimer
        interval: 200
        onTriggered: {
            motionActive = false;
        }
    }

    // Process to monitor keyboard events via libinput
    Process {
        id: keyboardMonitor

        command: ["libinput", "debug-events", "--show-keycodes"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                parseLibinputLine(data.toString());
            }
        }

        onExited: (code, status) => {
            Logger.w("Modifier Keys", "libinput process exited:", code, status);
            // Restart after a delay if it crashes
            restartTimer.start();
        }
    }

    Timer {
        id: restartTimer
        interval: 500
        onTriggered: {
            if (!keyboardMonitor.running) {
                keyboardMonitor.running = true;
            }
        }
    }

    function parseLibinputLine(line) {
        // Skip kernel bug warnings
        if (line.includes("kernel bug") || line.includes("Touch jump detected")) return;

        // Handle keyboard events
        if (line.includes("KEYBOARD_KEY")) {
            parseKeyboardEvent(line);
            return;
        }

        // Handle trackpad events
        if (line.includes("POINTER_BUTTON")) {
            parsePointerButton(line);
        } else if (line.includes("POINTER_SCROLL_FINGER")) {
            parseScrollEvent(line);
        } else if (line.includes("GESTURE_SWIPE")) {
            parseSwipeEvent(line);
        } else if (line.includes("POINTER_MOTION")) {
            parseMotionEvent(line);
        }
    }

    function parseKeyboardEvent(line) {
        // libinput debug-events output format:
        // event4   KEYBOARD_KEY    +2.15s	KEY_LEFTSHIFT (42) pressed
        // event4   KEYBOARD_KEY    +2.18s	KEY_LEFTSHIFT (42) released

        const isPressed = line.includes("pressed");
        const isReleased = line.includes("released");

        if (!isPressed && !isReleased) return;

        // Extract key name
        const keyMatch = line.match(/KEY_(\w+)\s*\(/);
        if (!keyMatch) return;

        const keyName = keyMatch[1].toUpperCase();
        const state = isPressed;

        // Map keys to modifiers
        if (keyName === "LEFTSHIFT" || keyName === "RIGHTSHIFT") {
            if (shiftPressed !== state) {
                if (!state) {
                    // 松开时启动延迟
                    shiftFading = true;
                    modifierFadeTimer.stop();
                    modifierFadeTimer.start();
                } else {
                    // 按下时清除其他修饰键的 fading 状态
                    shiftFading = false;
                    ctrlFading = false;
                    altFading = false;
                    superFading = false;
                }
                shiftPressed = state;
            }
        } else if (keyName === "LEFTCTRL" || keyName === "RIGHTCTRL") {
            if (ctrlPressed !== state) {
                if (!state) {
                    ctrlFading = true;
                    modifierFadeTimer.stop();
                    modifierFadeTimer.start();
                } else {
                    // 按下时清除其他修饰键的 fading 状态
                    shiftFading = false;
                    ctrlFading = false;
                    altFading = false;
                    superFading = false;
                }
                ctrlPressed = state;
            }
        } else if (keyName === "LEFTALT" || keyName === "RIGHTALT") {
            if (altPressed !== state) {
                if (!state) {
                    altFading = true;
                    modifierFadeTimer.stop();
                    modifierFadeTimer.start();
                } else {
                    // 按下时清除其他修饰键的 fading 状态
                    shiftFading = false;
                    ctrlFading = false;
                    altFading = false;
                    superFading = false;
                }
                altPressed = state;
            }
        } else if (keyName === "LEFTMETA" || keyName === "RIGHTMETA") {
            if (superPressed !== state) {
                if (!state) {
                    superFading = true;
                    modifierFadeTimer.stop();
                    modifierFadeTimer.start();
                } else {
                    // 按下时清除其他修饰键的 fading 状态
                    shiftFading = false;
                    ctrlFading = false;
                    altFading = false;
                    superFading = false;
                }
                superPressed = state;
            }
        } else {
            // Handle normal keys
            if (state) {
                addKey(keyName);
            } else {
                removeKey(keyName);
            }
        }
    }

    function parsePointerButton(line) {
        // Format: event14  POINTER_BUTTON  +6.772s	BTN_LEFT (272) pressed
        const buttonMatch = line.match(/BTN_(\w+)\s*\(/);
        if (!buttonMatch) return;

        const button = buttonMatch[1];
        const isPressed = line.includes("pressed");

        if (isPressed) {
            // Clear keyboard display when showing gesture
            displayKeys = [];
            fadeTimer.stop();

            if (button === "LEFT") {
                gestureSymbol = clickSymbol;
            } else if (button === "RIGHT") {
                gestureSymbol = rightClickSymbol;
            } else if (button === "MIDDLE") {
                gestureSymbol = middleClickSymbol;
            }
            gestureActive = true;
            gestureFading = false;
            gestureFadeTimer.stop();
        } else {
            // Button released - start fade
            gestureActive = false;
            gestureFading = true;
            gestureFadeTimer.stop();
            gestureFadeTimer.start();
        }
    }

    function parseScrollEvent(line) {
        // Format: event14  POINTER_SCROLL_FINGER  +2.104s	vert 0.00/0.0 horiz -8.73/0.0* (finger)
        const vertMatch = line.match(/vert\s+(-?[\d.]+)\//);
        const horizMatch = line.match(/horiz\s+(-?[\d.]+)\//);

        if (!vertMatch || !horizMatch) return;

        const vert = parseFloat(vertMatch[1]);
        const horiz = parseFloat(horizMatch[1]);

        // Accumulate delta
        gestureDeltaX += horiz;
        gestureDeltaY += vert;

        // Clear keyboard display
        displayKeys = [];
        fadeTimer.stop();

        // Determine direction based on accumulated delta
        const threshold = 15;
        let direction = -1;

        if (Math.abs(gestureDeltaX) > threshold || Math.abs(gestureDeltaY) > threshold) {
            if (Math.abs(gestureDeltaX) > Math.abs(gestureDeltaY)) {
                direction = gestureDeltaX > 0 ? 2 : 0; // right : left
            } else {
                direction = gestureDeltaY > 0 ? 1 : 3; // up : down
            }

            gestureSymbol = scrollSymbols[direction];
            gestureActive = true;
            gestureFading = false;
            gestureFadeTimer.stop();
        }

        // Check if scroll ended (near zero values)
        if (Math.abs(vert) < 0.5 && Math.abs(horiz) < 0.5 && (Math.abs(gestureDeltaX) > 5 || Math.abs(gestureDeltaY) > 5)) {
            gestureActive = false;
            gestureFading = true;
            gestureFadeTimer.stop();
            gestureFadeTimer.start();
            gestureDeltaX = 0;
            gestureDeltaY = 0;
        }
    }

    function parseSwipeEvent(line) {
        // Format: event14  GESTURE_SWIPE_BEGIN  +14.209s	3
        //         event14  GESTURE_SWIPE_UPDATE  +14.220s	3  1.04/-8.99
        //         event14  GESTURE_SWIPE_END     +14.434s	3

        if (line.includes("GESTURE_SWIPE_BEGIN")) {
            const fingerMatch = line.match(/GESTURE_SWIPE_BEGIN\s+[\d.]+s\s+(\d)/);
            if (fingerMatch) {
                gestureFingerCount = parseInt(fingerMatch[1]);
                gestureDeltaX = 0;
                gestureDeltaY = 0;
            }
            // Clear keyboard display
            displayKeys = [];
            fadeTimer.stop();
            gestureFadeTimer.stop();
            gestureActive = true;
            gestureFading = false;
        } else if (line.includes("GESTURE_SWIPE_UPDATE")) {
            // Extract delta: "3  1.04/-8.99"
            const deltaMatch = line.match(/\d\s+(-?[\d.]+)\/(-?[\d.]+)/);
            if (deltaMatch) {
                gestureDeltaX += parseFloat(deltaMatch[1]);
                gestureDeltaY += parseFloat(deltaMatch[2]);
            }

            // Determine direction
            const threshold = 20;
            let direction = -1;

            if (Math.abs(gestureDeltaX) > threshold || Math.abs(gestureDeltaY) > threshold) {
                if (Math.abs(gestureDeltaX) > Math.abs(gestureDeltaY)) {
                    direction = gestureDeltaX > 0 ? 2 : 0; // right : left
                } else {
                    direction = gestureDeltaY > 0 ? 1 : 3; // up : down
                }

                if (gestureFingerCount === 3) {
                    gestureSymbol = swipe3Symbols[direction];
                } else if (gestureFingerCount === 4) {
                    gestureSymbol = swipe4Symbols[direction];
                }
            }
        } else if (line.includes("GESTURE_SWIPE_END")) {
            gestureActive = false;
            gestureFading = true;
            gestureFadeTimer.stop();
            gestureFadeTimer.start();
            gestureDeltaX = 0;
            gestureDeltaY = 0;
            gestureFingerCount = 0;
        }
    }

    function parseMotionEvent(line) {
        // Format: event14  POINTER_MOTION  +0.011s	  6.77/ -1.28 (+34.00/ -6.41)
        // 单指滑动移动光标
        if (gestureActive) return; // 如果正在进行其他手势，忽略

        // Clear keyboard display
        displayKeys = [];
        fadeTimer.stop();

        motionActive = true;
        motionFadeTimer.stop();
        motionFadeTimer.start();
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusM
        color: Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: Style.marginS

            // Super (⌘)
            NText {
                text: "\u2318"
                pointSize: Style.barFontSize
                color: (superPressed || superFading || (isFading && superInCombo)) ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: superPressed || superFading || (isFading && superInCombo)
                opacity: superPressed ? 1.0 : (superFading ? 0.8 : ((isFading && superInCombo) ? 0.8 : 0.5))

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Alt (⌥)
            NText {
                text: "\u2325"
                pointSize: Style.barFontSize
                color: (altPressed || altFading || (isFading && altInCombo)) ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: altPressed || altFading || (isFading && altInCombo)
                opacity: altPressed ? 1.0 : (altFading ? 0.8 : ((isFading && altInCombo) ? 0.8 : 0.5))

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Ctrl (⌃)
            NText {
                text: "\u2303"
                pointSize: Style.barFontSize
                color: (ctrlPressed || ctrlFading || (isFading && ctrlInCombo)) ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: ctrlPressed || ctrlFading || (isFading && ctrlInCombo)
                opacity: ctrlPressed ? 1.0 : (ctrlFading ? 0.8 : ((isFading && ctrlInCombo) ? 0.8 : 0.5))

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Shift (⇧)
            NText {
                text: "\u21e7"
                pointSize: Style.barFontSize
                color: (shiftPressed || shiftFading || (isFading && shiftInCombo)) ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: shiftPressed || shiftFading || (isFading && shiftInCombo)
                opacity: shiftPressed ? 1.0 : (shiftFading ? 0.8 : ((isFading && shiftInCombo) ? 0.8 : 0.5))

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Normal keys / Gesture display (max 1) - always show 1 placeholder slot
            RowLayout {
                id: normalKeysRow
                spacing: 0
                // 固定1个位置宽度: 16
                Layout.preferredWidth: 16

                // Placeholder slot (always show 1) - 固定宽度16
                Item {
                    width: 16
                    NText {
                        anchors.centerIn: parent
                        // 优先显示手势，其次光标移动，最后显示按键
                        text: gestureSymbol.length > 0 ? gestureSymbol :
                              (motionActive ? motionSymbol :
                              (displayKeys.length > 0 ? root.getKeyDisplayName(displayKeys[0]) : ""))
                        pointSize: Style.barFontSize - 1
                        color: (gestureSymbol.length > 0 || motionActive || displayKeys.length > 0) ? Color.mPrimary : Color.mOnSurfaceVariant
                        font.bold: gestureSymbol.length > 0 || motionActive || displayKeys.length > 0
                        opacity: (gestureSymbol.length > 0 || motionActive || displayKeys.length > 0) ?
                                  ((gestureFading || isFading) ? 0.6 : 1.0) : 0.2
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!pluginApi) return;
            try {
                pluginApi.openPanel(root.screen, root);
            } catch (e) {
                try {
                    pluginApi.openPanel(screen);
                } catch (err) {
                    Logger.w("Modifier Keys", "openPanel failed:", err);
                }
            }
        }
    }
}
