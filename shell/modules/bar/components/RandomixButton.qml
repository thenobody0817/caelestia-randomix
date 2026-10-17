import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Bar entry for Randomix.
//
// Hovering opens the popout through Bar.checkPopout, exactly like the status
// icons. Clicking the glyph is the playful path: it opens the popout when
// closed, and otherwise replays whichever mode is showing (spin, flip, roll,
// ask), so a draw never needs the panel on screen.
Item {
    id: root

    required property var bar

    readonly property var popouts: root.bar?.popouts
    readonly property bool opened: !!root.popouts && root.popouts.hasCurrent && root.popouts.currentName === "randomix"

    implicitWidth: glyph.implicitHeight + Tokens.padding.small
    implicitHeight: glyph.implicitHeight + Tokens.padding.small

    function openPopout(): void {
        const p = root.popouts;
        if (!p)
            return;

        p.currentName = "randomix";
        p.currentCenter = root.mapToItem(root.bar, 0, root.implicitHeight / 2).y;
        p.hasCurrent = true;
    }

    StateLayer {
        anchors.fill: parent
        radius: Tokens.rounding.full
        onClicked: {
            if (root.opened)
                Randomix.triggerPrimary();
            else
                root.openPopout();
        }
    }

    MaterialIcon {
        id: glyph

        anchors.centerIn: parent
        text: "casino"
        color: Colours.palette.m3primary
        fill: root.opened ? 1 : 0
        fontStyle: Tokens.font.icon.builders.medium.weight(Font.Bold).build()

        Behavior on fill {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
