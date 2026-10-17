# caelestia-randomix

Randomix — the roulette, coin, dice and magic-ball from the Android app
[m-i-n-a-r/randomix](https://github.com/m-i-n-a-r/randomix) — ported to the
[Caelestia](https://github.com/caelestia-dots/shell) shell as a bar popout widget.

![screenshot placeholder](https://github.com/thenobody0817/caelestia-randomix)

## Features

Full fidelity with the source app:

- **Roulette** — wheel with `Letters`, `Cards`, `Numbers` presets, free-form
  option editor with removable chips, custom inclusive range `0–99999` with a
  separate draw, and a recent-options list with pin / delete / restore.
  Settings: allow duplicate options, remove the last chosen option.
- **Coin** — fair flip with a running heads/tails tally and reset.
- **Dice** — 1–10 dice of d4 / d6 / d10 / d12 / d20, real pips on d6,
  a 3-vs-3 contest with a winner, and an "allow equal dice" toggle.
- **Magic ball** — the classic twenty answers, a custom answer pool, and the
  blunter set behind "rude answers". Shake animation on each ask.
- **Settings** tab — every toggle above plus a sounds toggle and a preview of
  the four sound cues. All state persists to
  `~/.local/state/caelestia/randomix.json`.

Behaviour in the shell:

- Opens on **hover** over its bar glyph (like the other popouts).
- **Detach** button floats it as its own window with keyboard focus, so the
  text fields are usable — the same mechanism as the Nexus/audio popouts.
- **`SUPER + CTRL + R`** toggles it (the bind ships in
  `~/.config/caelestia/hypr-user.lua`).
- **`caelestia shell randomix toggle`** (or `qs -c caelestia ipc call randomix
  toggle`) — also `open`, `close`, `mode <name>`, `trigger`.

## Install

```sh
git clone https://github.com/thenobody0817/caelestia-randomix
cd caelestia-randomix
./install.sh
```

Then restart the shell:

```sh
caelestia shell restart   # or: qs -c caelestia
```

`install.sh` copies the new files and applies idempotent patches to
`Bar.qml`, `Content.qml`, `Wrapper.qml`, `PopoutState.qml` and
`Shortcuts.qml`, plus adds a `randomix` entry to `bar.entries` in
`shell.json`. Every touched file is backed up as `<name>.bak.<epoch>`.

Options:

```sh
./install.sh /path/to/quickshell/caelestia   # non-default shell tree
```

## Uninstall

```sh
./uninstall.sh
```

## Sound cues

Four short cues (`spin`, `flip`, `roll`, `answer`) are synthesised with
`ffmpeg` (see `assets/sounds/generate.sh`) and played with `pw-play`, so no
extra runtime dependency beyond PipeWire. Toggle them in the Settings tab.

## Credits

- Original app: [m-i-n-a-r/randomix](https://github.com/m-i-n-a-r/randomix)
  (Kotlin/Android, MIT).
- Shell: [caelestia-dots/shell](https://github.com/caelestia-dots/shell).

This is an independent port, not affiliated with either project.

## License

MIT — see [LICENSE](LICENSE).
