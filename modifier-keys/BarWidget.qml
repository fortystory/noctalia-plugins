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

    // Default gesture symbols
    readonly property var defaultGestureSymbols: ({
        "scroll": ["⮆", "⮇", "⮄", "⮅"],
        "swipe3": ["🡆", "🡇", "🡄", "🡅"],
        "swipe4": ["⭲", "⭳", "⭰", "⭱"],
        "click": "󰳽",
        "rightClick": "󰳾",
        "middleClick": "󰻃",
        "motion": "󰆽",
        "pinchIn": "󰘖",
        "pinchOut": "󰘕"
    })

    // Load gesture symbols from settings
    function loadGestureSymbols() {
        if (!pluginApi) return defaultGestureSymbols;
        const saved = pluginApi.getSetting("gestureSymbols", "");
        if (!saved || saved.trim() === "") return defaultGestureSymbols;
        try {
            const parsed = JSON.parse(saved);
            // Merge: default + parsed (parsed overrides default)
            var result = {};
            for (var k in defaultGestureSymbols) result[k] = defaultGestureSymbols[k];
            for (var k in parsed) result[k] = parsed[k];
            return result;
        } catch (e) {
            return defaultGestureSymbols;
        }
    }

    // Current gesture symbols (reactive)
    property var gestureSymbols: loadGestureSymbols()

    // Reload symbols when settings change
    function reloadSymbols() {
        gestureSymbols = loadGestureSymbols();
    }

    // Modifier key data - data-driven approach
    readonly property var modifierData: [
        { key: "Meta", pressedProperty: "superPressed", fadingProperty: "superFading", comboProperty: "superInCombo", icon: "\u2318", names: ["LEFTMETA", "RIGHTMETA"] },
        { key: "Alt", pressedProperty: "altPressed", fadingProperty: "altFading", comboProperty: "altInCombo", icon: "\u2325", names: ["LEFTALT", "RIGHTALT"] },
        { key: "Ctrl", pressedProperty: "ctrlPressed", fadingProperty: "ctrlFading", comboProperty: "ctrlInCombo", icon: "\u2303", names: ["LEFTCTRL", "RIGHTCTRL"] },
        { key: "Shift", pressedProperty: "shiftPressed", fadingProperty: "shiftFading", comboProperty: "shiftInCombo", icon: "\u21e7", names: ["LEFTSHIFT", "RIGHTSHIFT"] }
    ]

    // Modifier key states (reactive properties)
    property bool superPressed: false
    property bool ctrlPressed: false
    property bool altPressed: false
    property bool shiftPressed: false

    property bool superFading: false
    property bool ctrlFading: false
    property bool altFading: false
    property bool shiftFading: false

    property bool superInCombo: false
    property bool ctrlInCombo: false
    property bool altInCombo: false
    property bool shiftInCombo: false

    // Normal keys (max 5)
    property var pressedKeys: []

    // Display keys (for showing, with fade delay)
    property var displayKeys: []
    property bool isFading: false

    // Trackpad gesture state
    property string gestureSymbol: ""
    property bool gestureActive: false
    property bool gestureFading: false

    property real gestureDeltaX: 0
    property real gestureDeltaY: 0
    property int gestureFingerCount: 0

    // Pinch state
    property real pinchScale: 1.0
    property bool pinchActive: false

    // Motion state
    property bool motionActive: false

    readonly property real visualContentWidth: rowLayout.implicitWidth + Style.marginS * 2
    readonly property real visualContentHeight: rowLayout.implicitHeight + Style.marginS * 2

    readonly property real contentWidth: Math.max(80, isVertical ? Style.capsuleHeight : visualContentWidth)
    readonly property real contentHeight: Math.max(28, isVertical ? visualContentHeight : Style.capsuleHeight)

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Component.onCompleted: {
        Logger.d("Modifier Keys", "BarWidget loaded");
    }

    // Key display name mapping
    function getKeyDisplayName(keyName) {
        const keyMap = {
            "F1": "󱊫", "F2": "󱊬", "F3": "󱊭", "F4": "󱊮", "F5": "󱊯", "F6": "󱊰",
            "F7": "󱊱", "F8": "󱊲", "F9": "󱊳", "F10": "󱊴", "F11": "󱊵", "F12": "󱊶",
            "HOME": "", "END": "", "PAGEUP": "", "PAGEDOWN": "",
            "INSERT": "", "DELETE": "󰹾",
            "UP": "↑", "DOWN": "↓", "LEFT": "←", "RIGHT": "→",
            "PLAYPAUSE": "󰐎", "PAUSE": "", "STOP": "", "PREVIOUS": "󰒮", "NEXT": "󰒭",
            "PREVIOUSSONG": "󰒮", "NEXTSONG": "󰒭",
            "MUTE": "", "VOLUMEUP": "", "VOLUMEDOWN": "",
            "SPACE": "󱁐", "TAB": "", "ENTER": "󰌑", "ESCAPE": "⎋","ESC":"⎋",
            "BACKSPACE": "󰁮", "CAPSLOCK": "⇪", "PRINT": "\uf57d",
            "NUMLOCK": "\uf7c3", "SCROLLLOCK": "\uf86c",
            "LEFTSHIFT": "\uf17d", "RIGHTSHIFT": "\uf17e",
            "LEFTCTRL": "\uf201", "RIGHTCTRL": "\uf202",
            "LEFTALT": "\uf19a", "RIGHTALT": "\uf19b",
            "LEFTMETA": "\uf17b", "RIGHTMETA": "\uf17c",
            "SLASH":"/","BACKSLASH":"\\","APOSTROPHE":"\"","SEMICOLON":";","LEFTBRACE":"[","RIGHTBRACE":"]",
            "COMMA":",","DOT":".","KPPLUS":"+","MINUS":"-","EQUAL":"=","GRAVE":"`"
        };

        if (keyMap[keyName]) return keyMap[keyName];
        if (/^[A-Z]$/.test(keyName)) return keyName.toLowerCase();
        if (/^[0-9]$/.test(keyName)) return keyName;
        return keyName;
    }

    // Add key to pressed keys list
    function addKey(keyName) {
        const modifiers = ["LEFTSHIFT", "RIGHTSHIFT", "LEFTCTRL", "RIGHTCTRL",
                          "LEFTALT", "RIGHTALT", "LEFTMETA", "RIGHTMETA"];
        if (modifiers.includes(keyName)) return;

        for (let i = 0; i < pressedKeys.length; i++) {
            if (pressedKeys[i] === keyName) return;
        }

        shiftFading = false;
        ctrlFading = false;
        altFading = false;
        superFading = false;

        shiftInCombo = shiftPressed;
        ctrlInCombo = ctrlPressed;
        altInCombo = altPressed;
        superInCombo = superPressed;

        const newKeys = pressedKeys.slice();
        newKeys.push(keyName);
        if (newKeys.length > 1) newKeys.shift();
        pressedKeys = newKeys;

        displayKeys = [newKeys[newKeys.length - 1]];
        isFading = false;
        fadeTimer.stop();
    }

    // Remove key from pressed keys list
    function removeKey(keyName) {
        const newKeys = [];
        for (let i = 0; i < pressedKeys.length; i++) {
            if (pressedKeys[i] !== keyName) newKeys.push(pressedKeys[i]);
        }
        pressedKeys = newKeys;

        if (pressedKeys.length > 0) {
            displayKeys = [pressedKeys[pressedKeys.length - 1]];
            isFading = true;
            fadeTimer.stop();
            fadeTimer.start();
        } else {
            isFading = true;
            fadeTimer.stop();
            fadeTimer.start();
        }
    }

    // Timer for fade delay
    Timer {
        id: fadeTimer
        interval: 500
        onTriggered: {
            displayKeys = [];
            isFading = false;
            shiftInCombo = false;
            ctrlInCombo = false;
            altInCombo = false;
            superInCombo = false;
        }
    }

    // Timer for modifier key fade delay
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
            pinchActive = false;
            pinchScale = 1.0;
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

    // Process to monitor keyboard events
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

    // Clear keyboard display and combo states
    function clearKeyboardState() {
        displayKeys = [];
        isFading = false;
        shiftInCombo = false;
        ctrlInCombo = false;
        altInCombo = false;
        superInCombo = false;
        fadeTimer.stop();
    }

    function parseLibinputLine(line) {
        if (line.includes("kernel bug") || line.includes("Touch jump detected")) return;

        if (line.includes("KEYBOARD_KEY")) {
            parseKeyboardEvent(line);
            return;
        }

        if (line.includes("POINTER_BUTTON")) {
            parsePointerButton(line);
        } else if (line.includes("POINTER_SCROLL_FINGER")) {
            parseScrollEvent(line);
        } else if (line.includes("GESTURE_SWIPE")) {
            parseSwipeEvent(line);
        } else if (line.includes("GESTURE_PINCH")) {
            parsePinchEvent(line);
        } else if (line.includes("POINTER_MOTION")) {
            parseMotionEvent(line);
        }
    }

    function parseKeyboardEvent(line) {
        const isPressed = line.includes("pressed");
        const isReleased = line.includes("released");
        if (!isPressed && !isReleased) return;

        const keyMatch = line.match(/KEY_(\w+)\s*\(/);
        if (!keyMatch) return;

        const keyName = keyMatch[1].toUpperCase();
        const state = isPressed;

        // Find which modifier category this key belongs to
        for (let i = 0; i < modifierData.length; i++) {
            const mod = modifierData[i];
            if (mod.names.includes(keyName)) {
                const pressed = mod.pressedProperty + "Changed";
                const fading = mod.fadingProperty;

                if (root[mod.pressedProperty] !== state) {
                    if (!state) {
                        root[fading] = true;
                        modifierFadeTimer.stop();
                        modifierFadeTimer.start();
                    } else {
                        shiftFading = false;
                        ctrlFading = false;
                        altFading = false;
                        superFading = false;
                    }
                    root[mod.pressedProperty] = state;
                }
                return;
            }
        }

        // Normal key
        if (state) {
            addKey(keyName);
        } else {
            removeKey(keyName);
        }
    }

    function parsePointerButton(line) {
        const buttonMatch = line.match(/BTN_(\w+)\s*\(/);
        if (!buttonMatch) return;

        const button = buttonMatch[1];
        const isPressed = line.includes("pressed");

        if (isPressed) {
            clearKeyboardState();

            if (button === "LEFT") {
                gestureSymbol = gestureSymbols.click || "󰳽";
            } else if (button === "RIGHT") {
                gestureSymbol = gestureSymbols.rightClick || "󰳾";
            } else if (button === "MIDDLE") {
                gestureSymbol = gestureSymbols.middleClick || "󰻃";
            }
            gestureActive = true;
            gestureFading = false;
            gestureFadeTimer.stop();
        } else {
            gestureActive = false;
            gestureFading = true;
            gestureFadeTimer.stop();
            gestureFadeTimer.start();
        }
    }

    function parseScrollEvent(line) {
        const vertMatch = line.match(/vert\s+(-?[\d.]+)\//);
        const horizMatch = line.match(/horiz\s+(-?[\d.]+)\//);

        if (!vertMatch || !horizMatch) return;

        const vert = parseFloat(vertMatch[1]);
        const horiz = parseFloat(horizMatch[1]);

        const isNewGesture = (gestureDeltaX === 0 && gestureDeltaY === 0 && !gestureActive);

        gestureDeltaX += horiz;
        gestureDeltaY += vert;

        if (isNewGesture) {
            clearKeyboardState();
        }

        const threshold = 15;
        let direction = -1;

        if (Math.abs(gestureDeltaX) > threshold || Math.abs(gestureDeltaY) > threshold) {
            if (Math.abs(gestureDeltaX) > Math.abs(gestureDeltaY)) {
                direction = gestureDeltaX > 0 ? 2 : 0;
            } else {
                direction = gestureDeltaY > 0 ? 1 : 3;
            }

            const symbols = gestureSymbols.scroll || ["⮆", "⮇", "⮄", "⮅"];
            gestureSymbol = symbols[direction];
            gestureActive = true;
            gestureFading = false;
            gestureFadeTimer.stop();
        }

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
        if (line.includes("GESTURE_SWIPE_BEGIN")) {
            const fingerMatch = line.match(/GESTURE_SWIPE_BEGIN\s+\+[\d.]+s\s+(\d)/);
            if (fingerMatch) {
                gestureFingerCount = parseInt(fingerMatch[1]);
                gestureDeltaX = 0;
                gestureDeltaY = 0;
            }
            clearKeyboardState();
            gestureFadeTimer.stop();
            gestureActive = true;
            gestureFading = false;
        } else if (line.includes("GESTURE_SWIPE_UPDATE")) {
            const deltaMatch = line.match(/\s\d\s+(-?[\d.]+)\/(-?[\d.]+)/);
            if (deltaMatch) {
                gestureDeltaX += parseFloat(deltaMatch[1]);
                gestureDeltaY += parseFloat(deltaMatch[2]);
            }

            const threshold = 20;
            let direction = -1;

            if (Math.abs(gestureDeltaX) > threshold || Math.abs(gestureDeltaY) > threshold) {
                if (Math.abs(gestureDeltaX) > Math.abs(gestureDeltaY)) {
                    direction = gestureDeltaX > 0 ? 2 : 0;
                } else {
                    direction = gestureDeltaY > 0 ? 1 : 3;
                }

                if (gestureFingerCount === 3) {
                    const symbols = gestureSymbols.swipe3 || ["🡆", "🡇", "🡄", "🡅"];
                    gestureSymbol = symbols[direction];
                } else if (gestureFingerCount === 4) {
                    const symbols = gestureSymbols.swipe4 || ["⭲", "⭳", "⭰", "⭱"];
                    gestureSymbol = symbols[direction];
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

    function parsePinchEvent(line) {
        // Format: event14  GESTURE_PINCH_BEGIN  +0.033s    2
        //          event14  GESTURE_PINCH_UPDATE  +0.035s  2  0.95/0.95  0.0
        //          event14  GESTURE_PINCH_END     +0.292s  2

        if (line.includes("GESTURE_PINCH_BEGIN")) {
            clearKeyboardState();
            gestureFadeTimer.stop();
            gestureActive = true;
            gestureFading = false;
            pinchActive = true;
            pinchScale = 1.0;
        } else if (line.includes("GESTURE_PINCH_UPDATE")) {
            // Extract scale: "0.95/0.95"
            const scaleMatch = line.match(/(\d+\.\d+)\/(\d+\.\d+)/);
            if (scaleMatch) {
                const newScale = parseFloat(scaleMatch[1]);
                if (newScale !== pinchScale) {
                    const delta = newScale - pinchScale;
                    pinchScale = newScale;

                    // Determine pinch direction
                    if (delta > 0.05) {
                        gestureSymbol = gestureSymbols.pinchOut || "󰩮"; // Zoom out / spread
                    } else if (delta < -0.05) {
                        gestureSymbol = gestureSymbols.pinchIn || "󰩯"; // Zoom in / pinch
                    }
                    gestureActive = true;
                    gestureFading = false;
                    gestureFadeTimer.stop();
                }
            }
        } else if (line.includes("GESTURE_PINCH_END")) {
            gestureActive = false;
            gestureFading = true;
            gestureFadeTimer.stop();
            gestureFadeTimer.start();
            pinchActive = false;
            pinchScale = 1.0;
        }
    }

    function parseMotionEvent(line) {
        if (gestureActive) return;

        const isNewMotion = !motionActive;

        if (isNewMotion) {
            clearKeyboardState();
        }

        motionActive = true;
        motionFadeTimer.stop();
        motionFadeTimer.start();
    }

    // Dynamic modifier rendering
    function getModifierState(index) {
        const mod = modifierData[index];
        return {
            pressed: root[mod.pressedProperty],
            fading: root[mod.fadingProperty],
            inCombo: root[mod.comboProperty]
        };
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

            // Render modifier keys dynamically
            Repeater {
                model: root.modifierData
                delegate: NText {
                    text: modelData.icon
                    pointSize: Style.barFontSize
                    color: (root[modelData.pressedProperty] || root[modelData.fadingProperty] || (isFading && root[modelData.comboProperty])) ? Color.mPrimary : Color.mOnSurfaceVariant
                    font.bold: root[modelData.pressedProperty] || root[modelData.fadingProperty] || (isFading && root[modelData.comboProperty])
                    opacity: root[modelData.pressedProperty] ? 1.0 : (root[modelData.fadingProperty] ? 0.8 : ((isFading && root[modelData.comboProperty]) ? 0.8 : 0.5))

                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }
            }

            // Normal keys / Gesture display
            RowLayout {
                id: normalKeysRow
                spacing: 0
                Layout.preferredWidth: 16

                Item {
                    width: 16
                    NText {
                        anchors.centerIn: parent
                        text: gestureSymbol.length > 0 ? gestureSymbol :
                              (motionActive ? (gestureSymbols.motion || "󰆽") :
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
            // Left click: open panel, Right click: open settings
            if (mouse.button === Qt.RightButton) {
                try {
                    pluginApi.openSettings(root.screen, root);
                } catch (e) {
                    try {
                        pluginApi.openSettings(screen);
                    } catch (err) {
                        // Settings not available, open panel instead
                        openPanel();
                    }
                }
            } else {
                openPanel();
            }
        }
    }

    function openPanel() {
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
