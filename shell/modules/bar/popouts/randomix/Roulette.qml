pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

// Roulette: options with a Canvas wheel, custom ranges, presets, and the
// recent-options list.
//
// Geometry: slices are cut from angle 0 (3 o'clock) and run clockwise, so after
// rotating by A a slice that began at s occupies [s + A, ...). The pointer sits
// at the top, -90 degrees. The winner is drawn first and the landing angle is
// solved for it, rather than reading whichever slice the animation happens to
// stop over.
StyledFlickable {
    id: root

    readonly property var options: Randomix.options
    readonly property bool canSpin: root.options.length >= 2
    readonly property int wheelSize: 230

    property real angle: 0
    property string winner: ""
    property int number: -1

    readonly property real sliceDeg: root.options.length > 0 ? 360 / root.options.length : 360

    readonly property var sliceColours: [Colours.tPalette.m3primaryContainer, Colours.tPalette.m3secondaryContainer, Colours.tPalette.m3tertiaryContainer]
    readonly property var sliceOnColours: [Colours.on(Colours.tPalette.m3primaryContainer), Colours.on(Colours.tPalette.m3secondaryContainer), Colours.on(Colours.tPalette.m3tertiaryContainer)]

    function addOption(): void {
        const text = newOption.text.trim();
        if (!text)
            return;
        Randomix.addOption(text);
        newOption.text = "";
    }

    function spin(): void {
        const index = Randomix.pickIndex();
        if (index < 0)
            return;

        root.winner = "";
        const targetMod = ((-90 - index * root.sliceDeg - root.sliceDeg / 2) % 360 + 360) % 360;
        const turns = 3 + Math.floor(Math.random() * 2);
        const target = root.angle + turns * 360 + ((targetMod - root.angle) % 360 + 360) % 360;

        spinAnim.index = index;
        spinAnim.to = target;
        spinAnim.restart();
        Randomix.play("spin");
    }

    function drawNumber(): void {
        root.number = Randomix.pickNumber();
        Randomix.play("answer");
    }

    function commitRange(): void {
        const lo = Math.max(0, Math.min(99999, parseInt(minField.text) || 0));
        const hi = Math.max(0, Math.min(99999, parseInt(maxField.text) || 0));
        Randomix.rangeMin = lo;
        Randomix.rangeMax = hi;
    }

    Component.onCompleted: Randomix.registerPrimary(Randomix.tabs.indexOf("roulette"), root.spin)

    contentWidth: width
    contentHeight: col.implicitHeight
    clip: true

    NumberAnimation {
        id: spinAnim

        property int index: -1

        target: root
        property: "angle"
        duration: 3600
        easing: Easing.OutCubic

        onFinished: {
            if (spinAnim.index < 0)
                return;
            const value = root.options[spinAnim.index];
            root.winner = value ?? "";
            Randomix.commitRoulette(spinAnim.index);
            Randomix.play("answer");
        }
    }

    ColumnLayout {
        id: col

        width: root.width
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: [
                    {
                        label: qsTr("Letters"),
                        key: "letters"
                    },
                    {
                        label: qsTr("Cards"),
                        key: "cards"
                    },
                    {
                        label: qsTr("Numbers"),
                        key: "numbers"
                    }
                ]

                delegate: TextButton {
                    required property var modelData

                    Layout.fillWidth: true

                    text: modelData.label
                    type: ButtonBase.Tonal
                    isToggle: true
                    checked: Randomix.preset === modelData.key
                    onClicked: Randomix.applyPreset(Randomix.preset === modelData.key ? "" : modelData.key)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledTextField {
                id: newOption

                Layout.fillWidth: true
                placeholderText: qsTr("Add an option…")
                onAccepted: root.addOption()
            }

            TextButton {
                text: qsTr("Add")
                type: ButtonBase.Filled
                enabled: newOption.text.trim().length > 0
                onClicked: root.addOption()
            }

            TextButton {
                text: qsTr("Clear")
                type: ButtonBase.Text
                onClicked: Randomix.clearOptions()
            }
        }

        OptionChips {
            Layout.fillWidth: true

            visible: Randomix.options.length > 0
            model: Randomix.options

            onRemoveRequested: index => Randomix.removeOption(index)
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.wheelSize

            Canvas {
                id: wheel

                anchors.centerIn: parent
                width: Math.min(parent.width, root.wheelSize)
                height: width

                onPaint: {
                    const ctx = getContext("2d");
                    const w = wheel.width;
                    const h = wheel.height;
                    const cx = w / 2;
                    const cy = h / 2;
                    const radius = Math.min(cx, cy) - 8;
                    const offset = root.angle * Math.PI / 180;

                    ctx.clearRect(0, 0, w, h);
                    ctx.lineWidth = 1;

                    const options = root.options;
                    if (options.length < 2) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, 0, 2 * Math.PI);
                        ctx.fillStyle = Colours.tPalette.m3surfaceContainerHigh;
                        ctx.fill();
                    } else {
                        const slice = 2 * Math.PI / options.length;
                        for (let i = 0; i < options.length; i++) {
                            ctx.beginPath();
                            ctx.moveTo(cx, cy);
                            ctx.arc(cx, cy, radius, i * slice + offset, (i + 1) * slice + offset);
                            ctx.closePath();
                            ctx.fillStyle = root.sliceColours[i % root.sliceColours.length];
                            ctx.fill();
                            ctx.strokeStyle = Colours.tPalette.m3surface;
                            ctx.stroke();
                        }

                        ctx.font = `${Tokens.font.label.small.pointSize}px ${Tokens.font.label.small.family}`;
                        ctx.textAlign = "center";
                        ctx.textBaseline = "middle";
                        for (let i = 0; i < options.length; i++) {
                            const label = options[i].length > 12 ? options[i].slice(0, 11) + "…" : options[i];
                            ctx.save();
                            ctx.translate(cx, cy);
                            ctx.rotate(i * slice + slice / 2 + offset - Math.PI / 2);
                            ctx.fillStyle = root.sliceOnColours[i % root.sliceOnColours.length];
                            ctx.fillText(label, radius * 0.7, 0);
                            ctx.restore();
                        }
                    }

                    ctx.beginPath();
                    ctx.arc(cx, cy, radius * 0.22, 0, 2 * Math.PI);
                    ctx.fillStyle = Colours.tPalette.m3surface;
                    ctx.fill();
                    ctx.strokeStyle = Colours.tPalette.m3outlineVariant;
                    ctx.stroke();

                    const p = radius * 0.09;
                    ctx.beginPath();
                    ctx.moveTo(cx, cy - radius + p);
                    ctx.lineTo(cx - p, cy - radius - p * 1.2);
                    ctx.lineTo(cx + p, cy - radius - p * 1.2);
                    ctx.closePath();
                    ctx.fillStyle = Colours.tPalette.m3primary;
                    ctx.fill();
                }

                Connections {
                    function onAngleChanged(): void {
                        wheel.requestPaint();
                    }

                    target: root
                }

                Connections {
                    function onOptionsChanged(): void {
                        wheel.requestPaint();
                    }

                    target: Randomix
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                visible: root.winner !== ""
                text: root.winner === "" ? "" : qsTr("Winner: %1").arg(root.winner)
                color: Colours.tPalette.m3primary
                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
            }

            TextButton {
                text: qsTr("Spin")
                type: ButtonBase.Filled
                enabled: root.canSpin
                onClicked: root.spin()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Custom range (0–99999)")
            color: Colours.tPalette.m3onSurfaceVariant
            font: Tokens.font.label.large
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledTextField {
                id: minField

                Layout.fillWidth: true
                text: Randomix.rangeMin
                placeholderText: qsTr("Min")
                validator: IntValidator {
                    bottom: 0
                    top: 99999
                }
                onEditingFinished: root.commitRange()
            }

            StyledTextField {
                id: maxField

                Layout.fillWidth: true
                text: Randomix.rangeMax
                placeholderText: qsTr("Max")
                validator: IntValidator {
                    bottom: 0
                    top: 99999
                }
                onEditingFinished: root.commitRange()
            }

            TextButton {
                text: qsTr("Draw")
                type: ButtonBase.Tonal
                onClicked: root.drawNumber()
            }

            StyledText {
                visible: root.number >= 0
                text: root.number < 0 ? "" : String(root.number)
                color: Colours.tPalette.m3primary
                font: Tokens.font.body.builders.medium.weight(Font.Bold).build()
            }
        }

        History {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
        }
    }
}
