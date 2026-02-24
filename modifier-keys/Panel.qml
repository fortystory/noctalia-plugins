import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Scope {
    id: root

    property var pluginApi: null
    property var barWidget: null

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow

            property ShellScreen screenData: modelData

            visible: false
            screen: screenData

            color: "transparent"
            WlrLayershell.layer: WlrLayershell.Overlay
            WlrLayershell.keyboardFocus: WlrLayershell.OnDemand

            implicitWidth: contentColumn.implicitWidth + Style.marginL * 2
            implicitHeight: contentColumn.implicitHeight + Style.marginL * 2

            anchors {
                margins: Style.marginM
            }

            Rectangle {
                id: background
                anchors.fill: parent
                radius: Style.radiusL
                color: Color.mSurface
                border.color: Color.mOutlineVariant
                border.width: Style.cardBorderWidth

                ColumnLayout {
                    id: contentColumn
                    anchors.centerIn: parent
                    spacing: Style.marginM

                    // Title
                    NText {
                        text: pluginApi?.tr("title", "Modifier Keys") || "Modifier Keys"
                        pointSize: Style.fontSizeL
                        font.bold: true
                        color: Color.mOnSurface
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // Separator
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Color.mOutlineVariant
                    }

                    // Key list
                    Repeater {
                        model: [
                            { icon: "\u2318", name: pluginApi?.tr("super", "Super (Win)") || "Super (Win)", key: "Meta" },
                            { icon: "\u2325", name: pluginApi?.tr("alt", "Alt") || "Alt", key: "Alt" },
                            { icon: "\u2303", name: pluginApi?.tr("ctrl", "Ctrl") || "Ctrl", key: "Ctrl" },
                            { icon: "\u21e7", name: pluginApi?.tr("shift", "Shift") || "Shift", key: "Shift" }
                        ]

                        RowLayout {
                            spacing: Style.marginM

                            NText {
                                text: modelData.icon
                                pointSize: Style.fontSizeL
                                color: Color.mPrimary
                                Layout.preferredWidth: 30
                                Layout.alignment: Qt.AlignHCenter
                            }

                            NText {
                                text: modelData.name
                                pointSize: Style.fontSizeM
                                color: Color.mOnSurface
                            }

                            NText {
                                text: modelData.key
                                pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                                Layout.rightMargin: Style.marginS
                            }
                        }
                    }
                }
            }

            // Close on click outside
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if (!background.contains(mapToItem(background, mouse.x, mouse.y))) {
                        panelWindow.visible = false;
                    }
                }
            }
        }
    }

    function open(screen, widget) {
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i] === screen) {
                const panel = children[i];
                if (panel) {
                    panel.visible = true;
                    break;
                }
            }
        }
    }

    function close() {
        for (let i = 0; i < children.length; i++) {
            children[i].visible = false;
        }
    }
}
