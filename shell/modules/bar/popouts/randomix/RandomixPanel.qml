pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// The Randomix card: a mode switcher over the five panels.
//
// `popouts` is deliberately untyped. PopoutState lives in the parent module
// (qs.modules.bar.popouts) and a child importing its own parent to name the
// type would be circular; the only thing done with it is emitting
// detachRequested/attachRequested, which the wrapper listens for.
//
// The same component renders the detached (floating) variant with
// detached: true, which is what Wrapper's "randomix" detached mode mounts.
ColumnLayout {
    id: root

    required property var popouts
    property bool detached: false

    readonly property var tabModel: [
        {
            icon: "rotate_right",
            key: "roulette"
        },
        {
            icon: "paid",
            key: "coin"
        },
        {
            icon: "casino",
            key: "dice"
        },
        {
            icon: "auto_awesome",
            key: "magicball"
        },
        {
            icon: "tune",
            key: "settings"
        }
    ]

    spacing: Tokens.spacing.small
    implicitWidth: root.detached ? 620 : 380
    implicitHeight: root.detached ? 680 : 500

    Item {
        Layout.fillWidth: true
        implicitHeight: Math.max(title.implicitHeight, buttons.implicitHeight)

        StyledText {
            id: title

            anchors.left: parent.left
            anchors.right: buttons.left
            anchors.rightMargin: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Randomix")
            color: Colours.tPalette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
            elide: Text.ElideRight
        }

        RowLayout {
            id: buttons

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.extraSmall

            IconButton {
                type: ButtonBase.Tonal
                isToggle: root.detached
                checked: root.detached
                icon: root.detached ? "close_fullscreen" : "open_in_full"
                onClicked: {
                    if (root.detached)
                        root.popouts.attachRequested();
                    else
                        root.popouts.detachRequested("randomix");
                }
            }

            IconButton {
                type: ButtonBase.Tonal
                icon: "close"
                onClicked: Randomix.close()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall

        Repeater {
            model: root.tabModel

            delegate: IconButton {
                required property var modelData
                required property int index

                Layout.fillWidth: true

                isToggle: true
                checked: Randomix.currentTab === index
                icon: modelData.icon
                onClicked: Randomix.currentTab = index
            }
        }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: Randomix.currentTab

        Roulette {}
        Coin {}
        Dice {}
        MagicBall {}
        SettingsTab {}
    }
}
