pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

// Settings: the persisted toggles, plus a preview of the four sound cues so the
// sounds setting can be checked without drawing anything.
//
// Each row carries its own Binding onto the switch's checked, because a Switch
// breaks its declarative binding the moment it is clicked; without it,
// "Restore defaults" would leave every switch showing the old value.
StyledFlickable {
    id: root

    contentWidth: width
    contentHeight: col.implicitHeight
    clip: true

    component SettingSwitch: RowLayout {
        id: row

        property string label
        property string hint: ""
        property bool value

        signal toggled(bool checked)

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: row.label
                color: Colours.tPalette.m3onSurface
                font: Tokens.font.label.large
            }

            StyledText {
                Layout.fillWidth: true
                visible: row.hint !== ""
                text: row.hint
                color: Colours.tPalette.m3onSurfaceVariant
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }

        StyledSwitch {
            id: control

            onToggled: row.toggled(checked)

            Binding {
                target: control
                property: "checked"
                value: row.value
            }
        }
    }

    component SectionLabel: StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.small
        color: Colours.tPalette.m3onSurfaceVariant
        font: Tokens.font.label.large
    }

    ColumnLayout {
        id: col

        width: root.width
        spacing: Tokens.spacing.small

        SectionLabel {
            text: qsTr("Roulette")
        }

        SettingSwitch {
            label: qsTr("Allow duplicate options")
            hint: qsTr("Lets the same value sit in the list more than once, weighting the odds towards it")
            value: Randomix.duplicates
            onToggled: checked => Randomix.duplicates = checked
        }

        SettingSwitch {
            label: qsTr("Remove last chosen option")
            hint: qsTr("Takes the winning option out of the list as soon as it is drawn")
            value: Randomix.removeLastChosen
            onToggled: checked => Randomix.removeLastChosen = checked
        }

        SectionLabel {
            text: qsTr("Dice")
        }

        SettingSwitch {
            label: qsTr("Allow equal dice")
            hint: qsTr("Lets two dice in one tray land on the same face")
            value: Randomix.allowEqualDice
            onToggled: checked => Randomix.allowEqualDice = checked
        }

        SectionLabel {
            text: qsTr("Magic ball")
        }

        SettingSwitch {
            label: qsTr("Rude answers")
            hint: qsTr("Swaps the classic twenty for the blunter set")
            value: Randomix.rudeAnswers
            onToggled: checked => Randomix.rudeAnswers = checked
        }

        SectionLabel {
            text: qsTr("Sound")
        }

        SettingSwitch {
            label: qsTr("Sounds")
            hint: qsTr("Play a cue on each draw")
            value: Randomix.sounds
            onToggled: checked => Randomix.sounds = checked
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: ["spin", "flip", "roll", "answer"]

                delegate: TextButton {
                    required property string modelData

                    Layout.fillWidth: true

                    text: modelData
                    type: ButtonBase.Tonal
                    enabled: Randomix.sounds
                    onClicked: Randomix.play(modelData)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.extraSmall

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: qsTr("Clear history")
                type: ButtonBase.Text
                enabled: Randomix.recent.length > 0
                onClicked: Randomix.recent = []
            }

            TextButton {
                text: qsTr("Restore defaults")
                type: ButtonBase.Tonal
                onClicked: Randomix.restoreDefaults()
            }
        }
    }
}
