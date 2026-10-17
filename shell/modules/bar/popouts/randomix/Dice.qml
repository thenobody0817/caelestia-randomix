pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

// Dice: 1-10 of d4/d6/d10/d12/d20, with the 3-vs-3 contest and the
// no-repeated-face option from the app.
//
// A "roll" is a short tumble: a timer re-draws the tray a few times before
// settling, which is what makes the numbers feel thrown rather than computed.
// The settle frame is the one that counts, and it comes from
// rollDiceWithoutDuplicates() so the option is applied to the real result.
StyledFlickable {
    id: root

    readonly property var faces: root.roll ? root.roll.faces : []
    readonly property var groupA: Randomix.threeVsThree ? root.faces.slice(0, 3) : root.faces
    readonly property var groupB: Randomix.threeVsThree ? root.faces.slice(3, 6) : []

    readonly property int trayCount: Randomix.threeVsThree ? 6 : Randomix.diceCount
    readonly property int dieSize: root.trayCount > 6 ? 34 : root.trayCount > 4 ? 40 : 48

    property var roll: null
    property bool rolling: false

    function doRoll(): void {
        if (root.rolling)
            return;

        root.rolling = true;
        tumble.restart();
        Randomix.play("roll");
    }

    function setCount(delta: int): void {
        Randomix.diceCount = Math.max(1, Math.min(10, Randomix.diceCount + delta));
        root.roll = Randomix.rollDiceWithoutDuplicates();
    }

    Component.onCompleted: {
        Randomix.registerPrimary(Randomix.tabs.indexOf("dice"), root.doRoll);
        root.roll = Randomix.rollDiceWithoutDuplicates();
    }

    contentWidth: width
    contentHeight: col.implicitHeight
    clip: true

    Timer {
        id: tumble

        property int ticks: 0

        interval: 70
        repeat: true

        onRunningChanged: {
            if (running)
                ticks = 0;
        }

        onTriggered: {
            ticks++;
            root.roll = Randomix.rollDiceWithoutDuplicates();
            if (ticks >= 9) {
                stop();
                root.rolling = false;
            }
        }
    }

    component Die: StyledRect {
        id: die

        required property int face
        required property bool d6

        readonly property var pipMap: [
            [],
            [[0.5, 0.5]],
            [[0.28, 0.28], [0.72, 0.72]],
            [[0.28, 0.28], [0.5, 0.5], [0.72, 0.72]],
            [[0.28, 0.28], [0.72, 0.28], [0.28, 0.72], [0.72, 0.72]],
            [[0.28, 0.28], [0.72, 0.28], [0.5, 0.5], [0.28, 0.72], [0.72, 0.72]],
            [[0.28, 0.28], [0.72, 0.28], [0.28, 0.5], [0.72, 0.5], [0.28, 0.72], [0.72, 0.72]]
        ]

        implicitWidth: root.dieSize
        implicitHeight: root.dieSize
        radius: Tokens.rounding.small
        color: Colours.tPalette.m3surfaceContainerHighest
        border.width: 1
        border.color: Colours.tPalette.m3outlineVariant

        StyledText {
            anchors.centerIn: parent
            visible: !die.d6
            text: die.face < 10 ? `0${die.face}` : String(die.face)
            color: Colours.tPalette.m3onSurface
            font: Tokens.font.body.medium
        }

        Repeater {
            model: die.d6 ? die.pipMap[die.face] ?? [] : []

            delegate: StyledRect {
                required property var modelData

                width: die.width * 0.19
                height: width
                radius: width / 2
                x: die.width * modelData[0] - width / 2
                y: die.height * modelData[1] - height / 2
                color: Colours.tPalette.m3onSurface
            }
        }
    }

    ColumnLayout {
        id: col

        width: root.width
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                text: qsTr("Dice")
                color: Colours.tPalette.m3onSurfaceVariant
                font: Tokens.font.label.large
            }

            IconButton {
                type: ButtonBase.Tonal
                icon: "remove"
                enabled: !Randomix.threeVsThree && Randomix.diceCount > 1
                onClicked: root.setCount(-1)
            }

            StyledText {
                Layout.preferredWidth: Tokens.font.body.large.pointSize * 2
                horizontalAlignment: Text.AlignHCenter
                text: String(Randomix.diceCount)
                color: Colours.tPalette.m3onSurface
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
            }

            IconButton {
                type: ButtonBase.Tonal
                icon: "add"
                enabled: !Randomix.threeVsThree && Randomix.diceCount < 10
                onClicked: root.setCount(1)
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: qsTr("Roll")
                type: ButtonBase.Filled
                onClicked: root.doRoll()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: Randomix.diceTypes

                delegate: TextButton {
                    required property string modelData

                    Layout.fillWidth: true

                    text: modelData
                    type: ButtonBase.Tonal
                    isToggle: true
                    checked: Randomix.diceType === modelData
                    onClicked: {
                        Randomix.diceType = modelData;
                        root.roll = Randomix.rollDiceWithoutDuplicates();
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("3 vs 3")
                color: Colours.tPalette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            StyledSwitch {
                checked: Randomix.threeVsThree
                onToggled: {
                    Randomix.threeVsThree = checked;
                    root.roll = Randomix.rollDiceWithoutDuplicates();
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Allow equal dice")
                color: Colours.tPalette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            StyledSwitch {
                checked: Randomix.allowEqualDice
                onToggled: Randomix.allowEqualDice = checked
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.dieSize + Tokens.spacing.small

            RowLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.groupA

                    delegate: Die {
                        required property int modelData

                        face: modelData
                        d6: Randomix.diceType === "d6"
                    }
                }

                StyledText {
                    visible: Randomix.threeVsThree
                    text: qsTr("vs")
                    color: Colours.tPalette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }

                Repeater {
                    model: root.groupB

                    delegate: Die {
                        required property int modelData

                        face: modelData
                        d6: Randomix.diceType === "d6"
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: {
                const r = root.roll;
                if (!r)
                    return "";
                if (!Randomix.threeVsThree)
                    return qsTr("Total: %1").arg(r.total);
                if (r.winner === "tie")
                    return qsTr("%1 — %2 · tie").arg(r.a).arg(r.b);
                return qsTr("%1 — %2 · %3 wins").arg(r.a).arg(r.b).arg(r.winner === "a" ? qsTr("first") : qsTr("second"));
            }
            color: Colours.tPalette.m3primary
            font: Tokens.font.body.builders.large.weight(Font.Medium).build()
        }
    }
}
