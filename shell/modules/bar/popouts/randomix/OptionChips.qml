pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// A wrapping row of removable chips bound to a string list. The caller owns the
// list and persists it; this only reports which index to drop.
Flow {
    id: root

    property alias model: repeater.model

    signal removeRequested(int index)

    spacing: Tokens.spacing.extraSmall

    Repeater {
        id: repeater

        delegate: Item {
            id: chip

            required property int index
            required property string modelData

            readonly property real chipPadding: Tokens.padding.small

            implicitWidth: row.implicitWidth + chipPadding
            implicitHeight: row.implicitHeight + chipPadding * 0.5

            StyledRect {
                anchors.fill: parent
                radius: height / 2
                color: Colours.tPalette.m3secondaryContainer
            }

            RowLayout {
                id: row

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: chip.modelData
                    color: Colours.on(Colours.tPalette.m3secondaryContainer)
                    font: Tokens.font.label.medium
                }

                IconButton {
                    type: ButtonBase.Text
                    icon: "close"
                    onClicked: root.removeRequested(chip.index)
                }
            }
        }
    }
}
