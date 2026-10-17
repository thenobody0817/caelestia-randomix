pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// The roulette's recent options, with Randomix's pin / delete / restore.
//
// Restoring is a click on the row: it puts the value back into the option list
// (subject to the duplicate setting) so it can be spun again. Pinned rows
// survive the service's trimming and sit above everything unpinned.
ColumnLayout {
    id: root

    spacing: Tokens.spacing.extraSmall

    StyledText {
        Layout.fillWidth: true
        text: qsTr("Recent")
        color: Colours.tPalette.m3onSurfaceVariant
        font: Tokens.font.label.large
    }

    StyledText {
        Layout.fillWidth: true
        visible: Randomix.recent.length === 0
        text: qsTr("Nothing spun yet")
        color: Colours.tPalette.m3onSurfaceVariant
        font: Tokens.font.label.small
    }

    Repeater {
        model: Randomix.recent

        delegate: RowLayout {
            id: row

            required property var modelData

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: value.implicitHeight + Tokens.padding.small
                radius: Tokens.rounding.small
                color: Colours.tPalette.m3surfaceContainerHigh

                StateLayer {
                    radius: Tokens.rounding.small
                    onClicked: Randomix.restoreRecent(row.modelData.value)
                }

                StyledText {
                    id: value

                    anchors.centerIn: parent
                    text: row.modelData.value
                    color: Colours.tPalette.m3onSurface
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }
            }

            IconButton {
                type: ButtonBase.Text
                isToggle: true
                checked: row.modelData.pinned
                icon: "push_pin"
                onClicked: Randomix.togglePin(row.modelData.value)
            }

            IconButton {
                type: ButtonBase.Text
                icon: "delete"
                onClicked: Randomix.removeRecent(row.modelData.value)
            }
        }
    }
}
