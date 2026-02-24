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

    readonly property real visualContentWidth: rowLayout.implicitWidth + Style.marginS * 2
    readonly property real visualContentHeight: rowLayout.implicitHeight + Style.marginS * 2

    readonly property real contentWidth: Math.max(80, isVertical ? Style.capsuleHeight : visualContentWidth)
    readonly property real contentHeight: Math.max(28, isVertical ? visualContentHeight : Style.capsuleHeight)

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Component.onCompleted: {
        Logger.d("Modifier Keys", "BarWidget loaded");
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
        interval: 2000
        onTriggered: {
            if (!keyboardMonitor.running) {
                keyboardMonitor.running = true;
            }
        }
    }

    function parseLibinputLine(line) {
        // libinput debug-events output format:
        // event4   KEYBOARD_KEY    +2.15s	KEY_LEFTSHIFT (42) pressed
        // event4   KEYBOARD_KEY    +2.18s	KEY_LEFTSHIFT (42) released

        if (!line.includes("KEYBOARD_KEY")) return;

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
            if (shiftPressed !== state) shiftPressed = state;
        } else if (keyName === "LEFTCTRL" || keyName === "RIGHTCTRL") {
            if (ctrlPressed !== state) ctrlPressed = state;
        } else if (keyName === "LEFTALT" || keyName === "RIGHTALT") {
            if (altPressed !== state) altPressed = state;
        } else if (keyName === "LEFTMETA" || keyName === "RIGHTMETA") {
            if (superPressed !== state) superPressed = state;
        }
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
                color: superPressed ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: superPressed
                opacity: superPressed ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Alt (⌥)
            NText {
                text: "\u2325"
                pointSize: Style.barFontSize
                color: altPressed ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: altPressed
                opacity: altPressed ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Ctrl (⌃)
            NText {
                text: "\u2303"
                pointSize: Style.barFontSize
                color: ctrlPressed ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: ctrlPressed
                opacity: ctrlPressed ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }

            // Shift (⇧)
            NText {
                text: "\u21e7"
                pointSize: Style.barFontSize
                color: shiftPressed ? Color.mPrimary : Color.mOnSurfaceVariant
                font.bold: shiftPressed
                opacity: shiftPressed ? 1.0 : 0.5

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on opacity { NumberAnimation { duration: 100 } }
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
