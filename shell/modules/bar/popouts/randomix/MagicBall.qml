pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

// Magic ball: the classic twenty, plus a user pool and the blunter set behind
// "rude answers". The question is never stored or interpreted - the ball only
// needs to know that one was asked, which is why the field is cleared again
// after each answer.
StyledFlickable {
    id: root

    property string answer: ""

    function ask(): void {
        root.answer = Randomix.magicAnswer();
        shake.restart();
        Randomix.play("answer");
    }

    function addAnswer(): void {
        const text = newAnswer.text.trim();
        if (!text)
            return;

        Randomix.addAnswer(text);
        newAnswer.text = "";
    }

    Component.onCompleted: Randomix.registerPrimary(Randomix.tabs.indexOf("magicball"), root.ask)

    contentWidth: width
    contentHeight: col.implicitHeight
    clip: true

    SequentialAnimation {
        id: shake

        NumberAnimation {
            target: ball
            property: "rotation"
            to: -8
            duration: 60
        }
        NumberAnimation {
            target: ball
            property: "rotation"
            to: 8
            duration: 90
        }
        NumberAnimation {
            target: ball
            property: "rotation"
            to: 0
            duration: 160
            easing: Easing.OutElastic
        }
    }

    ColumnLayout {
        id: col

        width: root.width
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            visible: !Randomix.hideDescriptions
            text: qsTr("Magic Ball")
            color: Colours.tPalette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        StyledText {
            Layout.fillWidth: true
            visible: !Randomix.hideDescriptions
            text: qsTr("The magic ball will tell you the answers! Ask something and it will help you.")
            color: Colours.tPalette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            wrapMode: Text.WordWrap
        }

        StyledTextField {
            id: question

            Layout.fillWidth: true
            placeholderText: qsTr("Ask a question…")
            onAccepted: root.ask()
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 130

            StyledRect {
                id: ball

                anchors.centerIn: parent
                implicitWidth: 120
                implicitHeight: 120
                radius: width / 2
                color: Colours.tPalette.m3surfaceContainerHighest
                border.width: 2
                border.color: Colours.tPalette.m3outlineVariant

                transformOrigin: Item.Center

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "auto_awesome"
                    color: Colours.tPalette.m3primary
                    fontStyle: Tokens.font.icon.builders.extraLarge.build()
                }

                StateLayer {
                    anchors.fill: parent
                    radius: parent.radius
                    onClicked: root.ask()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: answerText.implicitHeight + Tokens.spacing.small
            clip: true

            StyledText {
                id: answerText

                anchors.verticalCenter: parent.verticalCenter
                x: parent.width
                text: root.answer === "" ? qsTr("Tap the ball") : root.answer
                color: root.answer === "" ? Colours.tPalette.m3onSurfaceVariant : Colours.tPalette.m3primary
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()

                SequentialAnimation on x {
                    id: marqueeAnim
                    running: root.answer !== ""
                    loops: Animation.Infinite

                    PropertyAnimation {
                        from: parent.width
                        to: -answerText.implicitWidth
                        duration: Math.max(3000, answerText.implicitWidth * 30)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Rude answers (%1 in the pool)").arg(Randomix.magicAnswers.length)
                color: Colours.tPalette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            StyledSwitch {
                checked: Randomix.rudeAnswers
                onToggled: Randomix.rudeAnswers = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledTextField {
                id: newAnswer

                Layout.fillWidth: true
                placeholderText: qsTr("Add your own answer…")
                onAccepted: root.addAnswer()
            }

            TextButton {
                text: qsTr("Add")
                type: ButtonBase.Filled
                enabled: newAnswer.text.trim().length > 0
                onClicked: root.addAnswer()
            }

            TextButton {
                text: qsTr("Ask")
                type: ButtonBase.Filled
                onClicked: root.ask()
            }
        }

        OptionChips {
            Layout.fillWidth: true

            visible: Randomix.customAnswers.length > 0
            model: Randomix.customAnswers

            onRemoveRequested: index => Randomix.removeAnswer(index)
        }
    }
}
