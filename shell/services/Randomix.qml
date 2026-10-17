pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

// Randomix: the four random-choice modes from the Android app of the same name
// (m-i-n-a-r/randomix), ported to the Caelestia shell as a bar popout.
//
// The service owns everything that outlives the popout: the panel-visible
// request, the selected mode, every persisted setting, and the random draws
// themselves. The QML modules under qs.modules.bar.popouts.randomix only
// animate and display what this hands back, so the same draw can be replayed
// by a test without a wheel on screen.
//
// Persistence lives in ${Paths.state}/randomix.json rather than shell.json
// because Caelestia.Config is a compiled schema plugin: an unknown "randomix"
// section in shell.json would never round-trip through it. GameMode.qml next
// door stashes to the same directory with the same FileView pattern.
//
// The `ready` gate matters: Quickshell re-applies a singleton's default
// property values when it instantiates one, which fires the change signals
// before the FileView has read anything, and a `setText` from that moment
// cancels the pending load. Nothing is written until the first load (or its
// failure) resolves, so startup can never race the read.
Singleton {
    id: root

    readonly property string statePath: `${Paths.state}/randomix.json`

    // Where the four sound cues are installed, relative to this file.
    readonly property url soundDir: Qt.resolvedUrl("../assets/randomix/")

    // True once the initial load resolved; before that, save() refuses.
    property bool ready: false

    // ------------------------------------------------------------- panel --

    // The bar popout mirrors this. Opening from the keybind or IPC cannot reach
    // the per-screen popout state directly, so it is requested here and the
    // popouts wrapper follows.
    property bool visible: false

    property int currentTab: 0

    readonly property var tabs: ["roulette", "coin", "dice", "magicball", "settings"]

    // Primary action of whichever mode owns the current tab (spin, flip, roll,
    // ask). Tabs register their own index so a StackLayout keeping all four
    // instantiated cannot have them clobber each other.
    property var primaryActions: ({})

    function registerPrimary(index: int, action: var): void {
        const next = Object.assign({}, root.primaryActions);
        next[index] = action;
        root.primaryActions = next;
    }

    function triggerPrimary(): void {
        const action = root.primaryActions[root.currentTab];
        if (action)
            action();
    }

    function open(): void {
        root.visible = true;
    }

    function close(): void {
        root.visible = false;
    }

    function toggle(): void {
        root.visible ? root.close() : root.open();
    }

    // --------------------------------------------------------- persisted --

    // Roulette
    property var options: ["Yes", "No", "Maybe"]
    property bool duplicates: false
    property string preset: ""
    property int rangeMin: 1
    property int rangeMax: 100
    property var recent: [] // [{ value: string, pinned: bool }]
    property bool removeLastChosen: false

    // Dice
    property int diceCount: 1
    property string diceType: "d6"
    property bool threeVsThree: false
    property bool allowEqualDice: false

    // Magic ball
    property var customAnswers: []
    property bool rudeAnswers: false

    // Shared
    property bool sounds: true
    property bool hideDescriptions: false

    readonly property var diceTypes: ["d4", "d6", "d8", "d10", "d12", "d20"]
    readonly property int diceSides: parseInt(root.diceType.substring(1)) || 6

    // The classic twenty, in Randomix's order.
    readonly property var defaultAnswers: [
        "It is certain",
        "It is decidedly so",
        "Without a doubt",
        "Yes definitely",
        "You may rely on it",
        "As I see it, yes",
        "Most likely",
        "Outlook good",
        "Yes",
        "Signs point to yes",
        "Reply hazy, try again",
        "Ask again later",
        "Better not tell you now",
        "Cannot predict now",
        "Concentrate and ask again",
        "Don't count on it",
        "My reply is no",
        "My sources say no",
        "Outlook not so good",
        "Very doubtful"
    ]

    // Randomix ships a second, blunter set behind "allow rude answers".
    readonly property var rudeBaseAnswers: [
        "Absolutely",
        "No way",
        "Obviously",
        "Are you serious?",
        "Don't be ridiculous",
        "Of course not",
        "Hell yes",
        "Hell no",
        "You're joking, right?",
        "Ask someone who cares",
        "I couldn't care less",
        "Not in a million years",
        "Sure, whatever",
        "Think again",
        "You already know the answer",
        "Give up already",
        "Why are you asking me?",
        "Try asking a friend",
        "Nope, not happening",
        "Dream on"
    ]

    readonly property var magicAnswers: (root.rudeAnswers ? root.rudeBaseAnswers : root.defaultAnswers).concat(root.customAnswers)

    // ------------------------------------------------------------- roulette --

    function addOption(text: string): void {
        text = text.trim();
        if (!text)
            return;
        if (root.options.length >= 30)
            return;
        if (!root.duplicates && root.options.includes(text))
            return;
        root.options = root.options.concat([text]);
        root.preset = "";
    }

    function removeOption(index: int): void {
        const list = root.options.slice();
        list.splice(index, 1);
        root.options = list;
        root.preset = "";
    }

    function clearOptions(): void {
        root.options = [];
        root.preset = "";
    }

    function applyPreset(name: string): void {
        if (name === "letters") {
            const letters = [];
            for (let i = 0; i < 26; i++)
                letters.push(String.fromCharCode(65 + i));
            root.options = letters;
        } else if (name === "numbers") {
            const numbers = [];
            for (let i = 1; i <= 10; i++)
                numbers.push(String(i));
            root.options = numbers;
        } else if (name === "cards") {
            const ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
            const suits = ["S", "H", "D", "C"];
            const cards = [];
            for (const suit of suits)
                for (const rank of ranks)
                    cards.push(rank + suit);
            root.options = cards;
        } else {
            root.options = [];
        }
        root.preset = name;
    }

    // Uniform index into options, or -1 when there is nothing to choose.
    function pickIndex(): int {
        const n = root.options.length;
        if (n < 1)
            return -1;
        return Math.floor(Math.random() * n);
    }

    // A random integer inside the inclusive custom range.
    function pickNumber(): int {
        const lo = Math.min(root.rangeMin, root.rangeMax);
        const hi = Math.max(root.rangeMin, root.rangeMax);
        return lo + Math.floor(Math.random() * (hi - lo + 1));
    }

    function recordRecent(value: string): void {
        let list = root.recent.filter(entry => entry.value !== value);
        list.unshift({
            value: value,
            pinned: false
        });
        // Keep pinned entries forever, cap the rest so state stays small.
        const pinned = list.filter(entry => entry.pinned);
        const unpinned = list.filter(entry => !entry.pinned).slice(0, 24);
        root.recent = pinned.concat(unpinned);
    }

    function togglePin(value: string): void {
        root.recent = root.recent.map(entry => entry.value === value ? {
            value: entry.value,
            pinned: !entry.pinned
        } : entry);
    }

    function removeRecent(value: string): void {
        root.recent = root.recent.filter(entry => entry.value !== value);
    }

    function restoreRecent(value: string): void {
        root.addOption(value);
    }

    // Called by the wheel once a spin lands, so the draw and its bookkeeping
    // stay in one place.
    function commitRoulette(index: int): void {
        const value = root.options[index];
        if (value === undefined)
            return;
        root.recordRecent(value);
        if (root.removeLastChosen)
            root.removeOption(index);
    }

    // ---------------------------------------------------------------- coin --

    // true = heads
    function flipCoin(): bool {
        return Math.random() < 0.5;
    }

    // ---------------------------------------------------------------- dice --

    // Returns { faces, total, a, b, winner } where a/b are the two 3v3 totals
    // (equal to total/0 when not in 3v3) and winner is "a", "b", "tie" or "".
    function rollDice(): var {
        const faces = [];
        const sides = root.diceSides;

        const draw = count => {
            const out = [];
            for (let i = 0; i < count; i++)
                out.push(1 + Math.floor(Math.random() * sides));
            return out;
        };

        if (root.threeVsThree) {
            const aFaces = draw(3);
            const bFaces = draw(3);
            const a = aFaces.reduce((s, v) => s + v, 0);
            const b = bFaces.reduce((s, v) => s + v, 0);
            return {
                faces: aFaces.concat(bFaces),
                total: a + b,
                a: a,
                b: b,
                winner: a > b ? "a" : b > a ? "b" : "tie"
            };
        }

        const rolled = draw(root.diceCount);
        return {
            faces: rolled,
            total: rolled.reduce((s, v) => s + v, 0),
            a: 0,
            b: 0,
            winner: ""
        };
    }

    // A roll is "fair" for the allow-equal-dice setting: when it is off, reroll
    // duplicates within a single tray. The attempt cap keeps a d4/10-dice tray
    // from spinning forever, since it cannot satisfy the constraint at all.
    function rollDiceWithoutDuplicates(): var {
        if (root.allowEqualDice)
            return root.rollDice();

        let result = root.rollDice();
        for (let attempt = 0; attempt < 64; attempt++) {
            if (new Set(result.faces).size === result.faces.length)
                return result;
            result = root.rollDice();
        }
        return result;
    }

    // ---------------------------------------------------------- magic ball --

    function magicAnswer(): string {
        const pool = root.magicAnswers;
        if (pool.length === 0)
            return "";
        return pool[Math.floor(Math.random() * pool.length)];
    }

    function addAnswer(text: string): void {
        text = text.trim();
        if (!text || root.customAnswers.includes(text))
            return;
        root.customAnswers = root.customAnswers.concat([text]);
    }

    function removeAnswer(index: int): void {
        const list = root.customAnswers.slice();
        list.splice(index, 1);
        root.customAnswers = list;
    }

    // ----------------------------------------------------------------- sound --

    function play(name: string): void {
        if (!root.sounds)
            return;
        const path = Paths.toLocalFile(root.soundDir + name + ".ogg");
        if (path)
            Quickshell.execDetached(["pw-play", path]);
    }

    // ------------------------------------------------------------- storage --

    function restoreDefaults(): void {
        root.options = ["Yes", "No", "Maybe"];
        root.duplicates = false;
        root.preset = "";
        root.rangeMin = 1;
        root.rangeMax = 100;
        root.recent = [];
        root.removeLastChosen = false;
        root.diceCount = 1;
        root.diceType = "d6";
        root.threeVsThree = false;
        root.allowEqualDice = false;
        root.customAnswers = [];
        root.rudeAnswers = false;
        root.sounds = true;
        root.hideDescriptions = false;
    }

    function save(): void {
        if (!root.ready)
            return;
        storage.setText(JSON.stringify({
            options: root.options,
            duplicates: root.duplicates,
            preset: root.preset,
            rangeMin: root.rangeMin,
            rangeMax: root.rangeMax,
            recent: root.recent,
            removeLastChosen: root.removeLastChosen,
            diceCount: root.diceCount,
            diceType: root.diceType,
            threeVsThree: root.threeVsThree,
            allowEqualDice: root.allowEqualDice,
            customAnswers: root.customAnswers,
            rudeAnswers: root.rudeAnswers,
            sounds: root.sounds,
            hideDescriptions: root.hideDescriptions,
            lastTab: root.currentTab
        }, null, 2));
    }

    function load(data: var): void {
        if (Array.isArray(data.options))
            root.options = data.options;
        if (typeof data.duplicates === "boolean")
            root.duplicates = data.duplicates;
        if (typeof data.preset === "string")
            root.preset = data.preset;
        if (Number.isInteger(data.rangeMin))
            root.rangeMin = data.rangeMin;
        if (Number.isInteger(data.rangeMax))
            root.rangeMax = data.rangeMax;
        if (Array.isArray(data.recent))
            root.recent = data.recent.filter(e => e && typeof e.value === "string").map(e => ({
                value: e.value,
                pinned: e.pinned === true
            }));
        if (typeof data.removeLastChosen === "boolean")
            root.removeLastChosen = data.removeLastChosen;
        if (Number.isInteger(data.diceCount))
            root.diceCount = data.diceCount;
        if (typeof data.diceType === "string")
            root.diceType = data.diceType;
        if (typeof data.threeVsThree === "boolean")
            root.threeVsThree = data.threeVsThree;
        if (typeof data.allowEqualDice === "boolean")
            root.allowEqualDice = data.allowEqualDice;
        if (Array.isArray(data.customAnswers))
            root.customAnswers = data.customAnswers;
        if (typeof data.rudeAnswers === "boolean")
            root.rudeAnswers = data.rudeAnswers;
        if (typeof data.sounds === "boolean")
            root.sounds = data.sounds;
        if (typeof data.hideDescriptions === "boolean")
            root.hideDescriptions = data.hideDescriptions;
        if (Number.isInteger(data.lastTab))
            root.currentTab = data.lastTab;
    }

    onOptionsChanged: root.save()
    onDuplicatesChanged: root.save()
    onPresetChanged: root.save()
    onRangeMinChanged: root.save()
    onRangeMaxChanged: root.save()
    onRecentChanged: root.save()
    onRemoveLastChosenChanged: root.save()
    onDiceCountChanged: root.save()
    onDiceTypeChanged: root.save()
    onThreeVsThreeChanged: root.save()
    onAllowEqualDiceChanged: root.save()
    onCustomAnswersChanged: root.save()
    onRudeAnswersChanged: root.save()
    onSoundsChanged: root.save()
    onHideDescriptionsChanged: root.save()
    onCurrentTabChanged: root.save()

    FileView {
        id: storage

        path: root.statePath
        printErrors: false

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.load(data);
            } catch (e) {
                console.warn("randomix: could not parse state, using defaults:", e);
            }
            root.ready = true;
        }

        onLoadFailed: err => {
            root.ready = true;
            if (err === FileViewError.FileNotFound)
                Qt.callLater(() => root.save());
        }
    }

    IpcHandler {
        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            root.toggle();
        }

        function mode(name: string): void {
            const index = root.tabs.indexOf(name);
            if (index !== -1) {
                root.currentTab = index;
                root.open();
            }
        }

        function trigger(): void {
            root.triggerPrimary();
        }

        target: "randomix"
    }
}
