#!/usr/bin/env bash
# uninstall.sh — remove Randomix from a Caelestia shell tree.
#
# Removes the files install.sh added and restores the five patched upstream
# files from their most recent *.bak.<epoch> backup. If no backup is found the
# upstream files are left untouched (remove the inserted blocks by hand).
#
# Usage:  ./uninstall.sh [shell-dir]
set -euo pipefail

SHELL_DIR="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/caelestia}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia"

if [ ! -d "$SHELL_DIR" ]; then
    echo "error: shell directory not found: $SHELL_DIR" >&2
    exit 1
fi

echo "==> removing added files"
rm -f "$SHELL_DIR/services/Randomix.qml"
rm -f "$SHELL_DIR/modules/bar/components/RandomixButton.qml"
rm -rf "$SHELL_DIR/modules/bar/popouts/randomix"
rm -rf "$SHELL_DIR/assets/randomix"
echo "    done"

echo "==> restoring upstream files from backups"
for rel in \
    "modules/bar/Bar.qml" \
    "modules/bar/popouts/Content.qml" \
    "modules/bar/popouts/PopoutState.qml" \
    "modules/bar/popouts/Wrapper.qml" \
    "modules/Shortcuts.qml"; do
    f="$SHELL_DIR/$rel"
    # find the newest backup
    latest="$(ls -1 "$f".bak.* 2>/dev/null | sort -V | tail -n1 || true)"
    if [ -n "$latest" ] && [ -f "$latest" ]; then
        cp -a "$latest" "$f"
        echo "    restored $rel  (from $(basename "$latest"))"
    else
        echo "    no backup for $rel — remove the randomix blocks by hand"
    fi
done

echo "==> (optional) remove the state file: $STATE_DIR/randomix.json"
echo "==> (optional) remove the bar entry from ${XDG_CONFIG_HOME:-$HOME/.config}/caelestia/shell.json"
echo "==> done. Restart the shell: qs -c caelestia"
