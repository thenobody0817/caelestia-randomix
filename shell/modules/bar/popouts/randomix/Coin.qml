pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

// Coin: a single fair flip, with a running tally.
//
// The flip is done by collapsing the face horizontally (scale.x 1 -> 0), swapping
// which side it shows at the narrow point, then growing it back. Cheaper than a
// 3D rotation and it reads as a flip at coin size.
StyledFlickable {
    id: root

    property bool heads: true
    property int headsCount: 0
    property int tailsCount: 0

    function flip(): void {
        if (flipAnim.running)
            return;

        flipAnim.nextHeads = Randomix.flipCoin();
        flipAnim.restart();
        Randomix.play("flip");
    }

    Component.onCompleted: Randomix.registerPrimary(Randomix.tabs.indexOf("coin"), root.flip)

    contentWidth: width
    contentHeight: col.implicitHeight
    clip: true

    SequentialAnimation {
        id: flipAnim

        property bool nextHeads: true

        NumberAnimation {
            target: face
            property: "scale"
            to: 0
            duration: 150
            easing: Easing.InQuad
        }

        ScriptAction {
            script: face.heads = flipAnim.nextHeads
        }

        NumberAnimation {
            target: face
            property: "scale"
            to: 1
            duration: 260
            easing: Easing.OutBack
        }

        onFinished: {
            if (face.heads)
                root.headsCount++;
            else
                root.tailsCount++;
        }
    }

    ColumnLayout {
        id: col

        width: root.width
        spacing: Tokens.spacing.medium

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 140

            StyledRect {
                id: face

                property bool heads: true

                anchors.centerIn: parent
                implicitWidth: 120
                implicitHeight: 120
                radius: width / 2
                color: face.heads ? Colours.tPalette.m3primaryContainer : Colours.tPalette.m3tertiaryContainer
                border.width: 2
                border.color: Colours.tPalette.m3outlineVariant

                transformOrigin: Item.Center

                StyledText {
                    anchors.centerIn: parent
                    text: face.heads ? "H" : "T"
                    color: face.heads ? Colours.on(Colours.tPalette.m3primaryContainer) : Colours.on(Colours.tPalette.m3tertiaryContainer)
                    font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
                }

                StateLayer {
                    anchors.fill: parent
                    radius: parent.radius
                    onClicked: root.flip()
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: face.heads ? qsTr("Heads") : qsTr("Tails")
            color: Colours.tPalette.m3onSurface
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("%1 heads · %2 tails").arg(root.headsCount).arg(root.tailsCount)
                color: Colours.tPalette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            TextButton {
                text: qsTr("Reset")
                type: ButtonBase.Text
                enabled: root.headsCount + root.tailsCount > 0
                onClicked: {
                    root.headsCount = 0;
                    root.tailsCount = 0;
                }
            }

            TextButton {
                text: qsTr("Flip")
                type: ButtonBase.Filled
                onClicked: root.flip()
            }
        }
    }
}
