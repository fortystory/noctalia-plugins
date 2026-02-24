import QtQuick
import QtQuick.Layouts
import Quickshell
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

    // Update modifier states periodically
    Timer {
        id: modifierTimer
        interval: 16  // ~60fps
        running: true
        repeat: true
        onTriggered: {
            const mods = Qt.application.keyboardModifiers;
            shiftPressed = (mods & Qt.ShiftModifier) !== 0;
            ctrlPressed = (mods & Qt.ControlModifier) !== 0;
            altPressed = (mods & Qt.AltModifier) !== 0;
            superPressed = (mods & Qt.MetaModifier) !== 0;
        }
    }

    Component.onCompleted: {
        Logger.d("Modifier Keys", "BarWidget loaded");
    }

    readonly property real visualContentWidth: rowLayout.implicitWidth + Style.marginS * 2
    readonly property real visualContentHeight: rowLayout.implicitHeight + Style.marginS * 2

    readonly property real contentWidth: Math.max(80, isVertical ? Style.capsuleHeight : visualContentWidth)
    readonly property real contentHeight: Math.max(28, isVertical ? visualContentHeight : Style.capsuleHeight)

    implicitWidth: contentWidth
    implicitHeight: contentHeight

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
