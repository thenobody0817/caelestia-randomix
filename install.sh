#!/usr/bin/env bash
# install.sh — install Randomix into a Caelestia shell tree.
#
# Copies the shipped QML modules and sound assets into the shell directory
# (~/.config/quickshell/caelestia by default) and applies the small, idempotent
# patches to the five upstream files that wire a new bar entry into place.
#
# Every file it touches is backed up first as <name>.bak.<epoch>.
#
# Usage:  ./install.sh [shell-dir]   (default: ~/.config/quickshell/caelestia)
set -euo pipefail

SHELL_DIR="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia"
SHELL_JSON="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/shell.json"
EPOCH="$(date +%s)"

if [ ! -d "$SHELL_DIR" ]; then
    echo "error: shell directory not found: $SHELL_DIR" >&2
    echo "       install caelestia-shell first, or pass the directory as an argument" >&2
    exit 1
fi

backup() {
    local f="$1"
    if [ -f "$f" ]; then
        cp -a "$f" "$f.bak.$EPOCH"
    fi
}

echo "==> installing files into $SHELL_DIR"
# New QML modules
install -Dm644 "$REPO_DIR/shell/services/Randomix.qml" \
    "$SHELL_DIR/services/Randomix.qml"
install -Dm644 "$REPO_DIR/shell/modules/bar/components/RandomixButton.qml" \
    "$SHELL_DIR/modules/bar/components/RandomixButton.qml"
mkdir -p "$SHELL_DIR/modules/bar/popouts/randomix"
for f in "$REPO_DIR"/shell/modules/bar/popouts/randomix/*.qml; do
    install -Dm644 "$f" "$SHELL_DIR/modules/bar/popouts/randomix/$(basename "$f")"
done
# Sound cues
mkdir -p "$SHELL_DIR/assets/randomix"
for f in "$REPO_DIR"/shell/assets/randomix/*.ogg; do
    install -Dm644 "$f" "$SHELL_DIR/assets/randomix/$(basename "$f")"
done
echo "    done"

echo "==> patching upstream files"
python3 - "$SHELL_DIR" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])

def patch(path, old, new, marker):
    p = root / path
    if not p.exists():
        print(f"    skip (missing): {path}")
        return
    s = p.read_text()
    if marker in s:
        print(f"    already patched: {path}")
        return
    if old not in s:
        print(f"    WARNING: anchor not found in {path} — skipping")
        return
    backup = p.with_suffix(p.suffix + f".bak.{__import__('time').time():.0f}")
    backup.write_text(s)
    p.write_text(s.replace(old, new, 1))
    print(f"    patched: {path}")

# Bar.qml — DelegateChoice for "randomix"
patch("modules/bar/Bar.qml",
      '''              DelegateChoice {
                  roleValue: "jumpstart"
                delegate: EntryWrapper {
                    JumpStart {
                        objectName: "taskbarJumpStart"
                    }
                }
            }''',
      '''              DelegateChoice {
                  roleValue: "jumpstart"
                delegate: EntryWrapper {
                    JumpStart {
                        objectName: "taskbarJumpStart"
                    }
                }
            }
              DelegateChoice {
                  roleValue: "randomix"
                delegate: EntryWrapper {
                    RandomixButton {
                        objectName: "taskbarRandomix"
                        bar: root
                    }
                }
            }''',
      '"randomix"')

# Bar.qml — checkPopout branch
patch("modules/bar/Bar.qml",
      '''        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = (ch.item as Item).mapToItem(root, 0, (ch.item as Item).implicitHeight / 2).y ?? 0;
            popouts.hasCurrent = true;
        }''',
      '''        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            popouts.currentName = id.toLowerCase();
            popouts.currentCenter = (ch.item as Item).mapToItem(root, 0, (ch.item as Item).implicitHeight / 2).y ?? 0;
            popouts.hasCurrent = true;
        } else if (id === "randomix") {
            popouts.currentName = "randomix";
            popouts.currentCenter = (ch.item as Item).mapToItem(root, 0, (ch.item as Item).implicitHeight / 2).y ?? 0;
            popouts.hasCurrent = true;
        }''',
      'id === "randomix"')

# Content.qml — import + Popout
patch("modules/bar/popouts/Content.qml",
      'import "./kblayout"\n',
      'import "./kblayout"\nimport "./randomix"\n',
      'import "./randomix"')
patch("modules/bar/popouts/Content.qml",
      '''        Popout {
            name: "kblayout"
            sourceComponent: KbLayout {}
        }''',
      '''        Popout {
            name: "kblayout"
            sourceComponent: KbLayout {}
        }

        Popout {
            name: "randomix"
            sourceComponent: RandomixPanel {
                popouts: root.popouts
            }
        }''',
      'name: "randomix"')

# PopoutState.qml — attach signal
patch("modules/bar/popouts/PopoutState.qml",
      '    signal detachRequested(mode: string)\n}',
      '    signal detachRequested(mode: string)\n    signal attachRequested\n}',
      'attachRequested')

# Wrapper.qml — import
patch("modules/bar/popouts/Wrapper.qml",
      'import qs.modules.windowinfo\n',
      'import qs.modules.windowinfo\nimport "./randomix"\n',
      'import "./randomix"')

# Wrapper.qml — detach branch
patch("modules/bar/popouts/Wrapper.qml",
      '''    function detach(mode: string): void {
        setAnims(true);
        if (mode === "winfo") {
            detachedMode = mode;
        } else {''',
      '''    function detach(mode: string): void {
        setAnims(true);
        if (mode === "winfo" || mode === "randomix") {
            detachedMode = mode;
        } else {''',
      'mode === "winfo" || mode === "randomix"')

# Wrapper.qml — attach function + openRandomix + visible sync + hasCurrent sync
patch("modules/bar/popouts/Wrapper.qml",
      '''    function close(): void {
        hasCurrent = false;
        detachedMode = "";
    }''',
      '''    function close(): void {
        hasCurrent = false;
        detachedMode = "";
    }

    function openRandomix(): void {
        root.currentCenter = root.screen.height / 2;
        root.currentName = "randomix";
        root.hasCurrent = true;
    }

    function attach(): void {
        setAnims(false);
        detachedMode = "";
        focus = true;
    }

    onHasCurrentChanged: {
        if (root.hasCurrent && root.currentName === "randomix") {
            if (!Randomix.visible)
                Randomix.visible = true;
        } else if (!root.hasCurrent && Randomix.visible && root.currentName === "randomix") {
            Randomix.visible = false;
        }
    }''',
      'function openRandomix()')

# Wrapper.qml — PopoutState connections
patch("modules/bar/popouts/Wrapper.qml",
      '''    PopoutState {
        id: popoutState

        onDetachRequested: mode => root.detach(mode)
    }''',
      '''    PopoutState {
        id: popoutState

        onDetachRequested: mode => root.detach(mode)
        onAttachRequested: root.attach()
    }

    Connections {
        target: Randomix

        function onVisibleChanged(): void {
            if (Randomix.visible) {
                if (!(root.hasCurrent && root.currentName === "randomix"))
                    root.openRandomix();
            } else if (root.currentName === "randomix" && !root.isDetached) {
                root.close();
            }
        }
    }''',
      'onAttachRequested: root.attach()')

# Wrapper.qml — keyboard focus condition
patch("modules/bar/popouts/Wrapper.qml",
      '        when: root.isDetached || (root.hasCurrent && root.currentName === "wirelesspassword")',
      '        when: root.isDetached || (root.hasCurrent && root.currentName === "wirelesspassword") || (root.hasCurrent && root.currentName === "randomix")',
      'root.currentName === "randomix"')

# Wrapper.qml — detached Comp
patch("modules/bar/popouts/Wrapper.qml",
      '    Behavior on implicitWidth {',
      '''    Comp {
        id: randomixDetached

        shouldBeActive: root.detachedMode === "randomix"
        anchors.centerIn: parent

        sourceComponent: RandomixPanel {
            popouts: popoutState
            detached: true
        }
    }

    Behavior on implicitWidth {''',
      'shouldBeActive: root.detachedMode === "randomix"')

# Shortcuts.qml — CustomShortcut
patch("modules/Shortcuts.qml",
      '''    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "utilities"
        description: "Toggle utilities"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = ShellState.forActive();
            screenState.utilities = !screenState.utilities;
        }
    }

    IpcHandler {''',
      '''    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "utilities"
        description: "Toggle utilities"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = ShellState.forActive();
            screenState.utilities = !screenState.utilities;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "randomix"
        description: "Toggle Randomix"
        onPressed: {
            if (root.hasFullscreen)
                return;
            Randomix.toggle();
        }
    }

    IpcHandler {''',
      'name: "randomix"')
PY
echo "    done"

echo "==> updating shell.json"
python3 - "$SHELL_JSON" <<'PY'
import json, os, sys
path = sys.argv[1]
if not os.path.exists(path):
    print("    (no shell.json found — add {\"id\":\"randomix\",\"enabled\":true} to bar.entries by hand)")
    sys.exit(0)
with open(path) as f:
    data = json.load(f)
entries = data.setdefault("bar", {}).setdefault("entries", [])
if not any(e.get("id") == "randomix" for e in entries):
    # place it right after jumpstart if present, else append
    inserted = False
    for i, e in enumerate(entries):
        if e.get("id") == "jumpstart":
            entries.insert(i + 1, {"id": "randomix", "enabled": True})
            inserted = True
            break
    if not inserted:
        entries.append({"id": "randomix", "enabled": True})
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("    added randomix entry")
else:
    print("    already present")
PY

echo "==> done. Restart the shell: qs -c caelestia (or 'caelestia shell restart')"
