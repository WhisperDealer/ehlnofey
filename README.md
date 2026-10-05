# Ehlnofey

**A deleveling overhaul for Skyrim Special Edition — fixed laws imprinted back onto the world.**

Vanilla Skyrim scales itself to you. Bandits, draugr and chest loot are generated relative to your
level, so a dungeon cleared at level 5 is the same fight at level 40, and the map has no topography
of danger — nowhere is genuinely above you, and nowhere is ever safely behind you.

Ehlnofey replaces that with **fixed, hand-set rules**: every enemy, every dungeon and every hoard has
a level and a loot profile that never moves. The world stops being a mirror and becomes terrain — it
is *immersive* (the world exists on its own terms), *lore-friendly* (danger and reward follow the
fiction), and *gameplay-optimised* (progression comes from learning the map, not from a scaling
formula).

## Why "Ehlnofey"

The Ehlnofey were et'Ada who stopped wandering. Where other spirits stayed free and mutable, these
bound themselves into the substance of Nirn and became its fixed laws — the Earth Bones, the
unchanging structure beneath everything. That is precisely the operation this mod performs: it takes
a world that bends to the player and re-imprints static, indifferent rules onto it. The design docs
use that vocabulary too — the **bones** are the fixed structure everything else hangs off.

## The three bones

Every design decision answers to these three rules:

1. **The world does not scale.** Difficulty and reward are properties of a place and a creature, set
   once. Nothing recalculates against the player's level.
2. **Danger is legible.** If walking somewhere can kill you, the world has to have told you first —
   through geography, faction, lore, visual tier or dialogue. A fixed world is only fair if it can be
   read.
3. **Reward follows place, not level.** Good loot exists because of *where* it is — a Nordic tomb, a
   Dwemer ruin, a dragon's hoard, a named boss — never because you happened to be level 40.

**Non-goals:** not a combat overhaul, not a perk or skill overhaul, not a survival mod, not new
content. Ehlnofey changes *where the numbers come from*, and nothing else.

## The ten bands of power

Every creature is set into one of ten fixed bands, from Weak to Godlike. The bands are defined in
[`arch-docs/bands-of-power.md`](arch-docs/bands-of-power.md), with the data in
[`census/bands.json`](census/bands.json).

![The ten bands of power: Weak 1–6, Common 7–13, Trained 14–20, Blooded 21–27, Experienced 28–34, Elite 35–41, Powerful 42–50, Fabled 51–65, Mythic 66–81, Godlike 82+](arch-docs/Ehlnofey%20Level%20Bands.png)

## Status: rebuilding (Phase 4, build)

**Ehlnofey is being rebuilt from scratch** (2026-09-27). Every record in the new plugin is authored in
this workspace from the vanilla game data and the design docs. No other mod's records are an input.

The first build proved the approach and has been retired. It was released as the pre-release
[**Proof of Concept** (`v0.1.0-poc`)](https://github.com/WhisperDealer/ehlnofey/releases/tag/v0.1.0-poc),
and its source is kept in `src/Ehlnofey/ProofOfConceptESP/`. In play it gave the same spread of
enemies in the same dungeon at player level 1 and at level 45, and it fixed every faction on its own
ladder. Its levels, rosters and gear rules are the design the rebuild works from
(`arch-docs/design/archetype-tiers.md`).

| Phase | Output | State |
|---|---|---|
| **0 — Workspace** | Spriggit round-trip, Claude skills, CI, and base-game + DLC decompiles in `reference/` | ✅ complete |
| **1 — World research** | `arch-docs/world/*` — enemy taxonomy, factions, dungeons, regions, progression routes, lore constraints | ✅ complete |
| **2 — Prior art** | how other deleveling mods work, and what each costs | ✅ complete |
| **3 — Design spec** | `arch-docs/design/*` — the tier ladder, archetype tiers, loot model, and the implementation-strategy decision | ✅ complete |
| **4 — Build** | `src/Ehlnofey/EhlnofeyESP/` — the plugin YAML and its generator scripts, packaged and released | ⏸ paused for the census — scaffold only |
| **Census** | `census/*.json` + the [census site](#the-census-site): every enemy's level, lists and placements, and its target band | ▶ in progress — Dragons published |

**How it is built: flattening the leveled lists.** `Ehlnofey.esp` is a single ESL-flagged plugin of
override records, with no scripts and no runtime rules. Every leveled list (`LVLN`/`LVLI`) loses its
player-level gates but keeps its pool of variants, weighted by duplicate entries, and every
player-scaled NPC gets a fixed level — followers included. A creature's level then belongs to its
name: a Draugr Scourge is the same fight in every barrow. The architecture document is
`arch-docs/design/flattening.md`, and its §6 is the order of work.

**Requirements** (planned): Skyrim SE/AE with all three DLC and the Anniversary Edition Creation Club
content, because several Creation Club packs re-level vanilla lists from start-up scripts and have to
be neutralised.

## The census site

**https://whisperdealer.github.io/ehlnofey/** shows the design in one place: the **Ten Bands of
Power** (the level bands every creature is set into, `arch-docs/bands-of-power.md`) and the **enemy
census**, which records every enemy's vanilla level, the record that owns it, the leveled lists that
draw it, where it is placed, and the band it is meant to land in.

The data is JSON in [`census/`](census/), which is the source of truth (the Confluence census pages are
generated mirrors of it). The site is an [Astro](https://astro.build) project in `site/`, published
by `.github/workflows/pages.yml`. **Deploys are manual**: pushing does not publish. Run the
*Census site* workflow from the Actions tab (Run workflow) or with `gh workflow run pages.yml --ref main`.
The raw JSON is served too, at `/ehlnofey/data/index.json`.
Dragons is the first family migrated.

```sh
cd site
npm ci
npm run dev        # http://localhost:4321/ehlnofey/
npm run schema     # validate census/*.json, regenerate census/schema/
npm run build      # the static site, into site/dist/
```

`build/Test-CensusJson.ps1` runs the key checks without Node. Node is used for the site only; the
mod toolchain is PowerShell 5.1.

---

# The workspace

Ehlnofey is built as **text**. The repo is a version-controlled SkyrimSE mod-development workspace: it
uses [Spriggit](https://github.com/Mutagen-Modding/Spriggit) to convert Bethesda plugin files
(`.esp`/`.esm`/`.esl`) to and from human-editable YAML kept under git, and adds a command-line
Papyrus toolchain, a manifest-driven FOMOD build, GitHub Actions CI, and a set of Claude Code skills
and subagents that know how to drive all of it. **You edit the YAML, not the binary plugin.**

- **Game release:** SkyrimSE
- **Spriggit package/source:** `Spriggit.Yaml.Skyrim`
- **Spriggit version:** `0.40.0` (CLI)
- **Tool paths:** resolved from `.claude/config/tools.json` (gitignored, per-machine) — **no
  hardcoded paths in the skills.** See [Tool config & modlists](#tool-config--modlists) below.

## Fresh clone — first-run setup

Cloning brings the skills, agents, config **template**, and docs — but **not** machine-specific
paths or any large/derived content (those are gitignored). Do this once on a new machine:

1. **Create your tool config.** Copy the template to the gitignored real config:

   ```powershell
   Copy-Item ".claude/config/tools.example.json" ".claude/config/tools.json"
   ```

   You'll fill it in over the next steps.

2. **Install the Spriggit CLI** (standalone — *not* part of a modlist). Grab it from the
   [Spriggit releases](https://github.com/Mutagen-Modding/Spriggit/releases), install the .NET
   runtime if prompted, then set `spriggitCli` in `tools.json` to the `Spriggit.CLI.exe` path. See
   [Installing Spriggit locally](#installing-spriggit-locally).

3. **Point it at a modlist (optional but recommended).** A Wabbajack modlist installed through the
   Wabbajack GUI (needs a Steam-owned SkyrimSE) usually ships the **game folder, Creation Kit and
   Papyrus compiler**. Set `modlistRoot`, `gameRoot`, `creationKit` and `papyrusCompiler` in
   `tools.json` to its copies. Skip this if you'll point at a plain Steam install instead.

4. **Fill the remaining keys by hand**, following the `_help` notes in `tools.example.json`. The ones
   most often missing from a modlist are **Champollion** (`champollion`) and **BSA Browser**
   (`bsab`). Without a modlist, also set `gameRoot` / `papyrusCompiler` / `creationKit` manually.

5. **Verify.** Confirm the tools you need actually resolve:

   ```powershell
   . ".claude/config/tools.ps1"
   Assert-Tool $Tools.spriggitCli     'spriggitCli'
   Assert-Tool $Tools.papyrusCompiler 'papyrusCompiler'   # if you'll compile scripts
   $Tools | ConvertTo-Json -Depth 4
   ```

   `Assert-Tool` throws on a missing/empty path — fix those before running the skills.

6. **One-time Papyrus source** (only if you'll compile): extract the base-game script source as
   described under [One-time setup](#one-time-setup-before-first-compile) — many modlists already
   ship it, so check `$Tools.gameSourceScripts` first.

You're set: serialize/deserialize plugins, decompile references and scripts for lookup, author your
own plugin + scripts, and package for testing — all without touching a hardcoded path.

## Installing Spriggit locally

[Spriggit](https://github.com/Mutagen-Modding/Spriggit) converts Bethesda plugins to and from a
git-friendly text format so you can version-control mods like source code (diffs, branches, PRs).
It ships in two flavors:

- **CLI** (`Spriggit.CLI.exe`) — runs on Windows and Linux, scriptable, **requires a .NET runtime**.
  This is what this workspace uses.
- **GUI** — a Windows-only desktop app where you link a plugin to a folder and sync with a click.
  Same engine, friendlier for one-off conversions.

**Install (overview):**

1. Download a precompiled build from the [Releases page](https://github.com/Mutagen-Modding/Spriggit/releases)
   — grab the CLI zip (or the GUI installer) for the latest version. Unzip it anywhere.
2. Install the **.NET runtime** if prompted when first running the CLI.
3. That's it — there's nothing to register globally. Set the CLI path **once** in
   `.claude/config/tools.json` (`spriggitCli`); every skill reads it from there. If you move or
   upgrade the CLI, edit that one file — not the skills.

The serializer itself (`Spriggit.Yaml.Skyrim`) is a NuGet package that the CLI fetches on demand.
You don't install it by hand — the **`.spriggit`** file in this repo pins the package name and
version, so `deserialize` automatically downloads the exact serializer used to create the YAML.
This keeps everyone on the team producing byte-identical plugins.

For the full feature set (GUI walkthrough, merge-conflict tooling, supported games) see the
[Spriggit repo README](https://github.com/Mutagen-Modding/Spriggit).

## Tool config & modlists

Every tool path the skills use (Spriggit CLI, `bsab`, Champollion, Papyrus compiler, Creation Kit,
game folder, MO2 modlists) lives in one place:

- **`.claude/config/tools.json`** — your machine's actual paths. **Gitignored** (it's per-machine).
- **`.claude/config/tools.example.json`** — committed template with documented keys. Copy it to
  `tools.json` and fill it in.
- **`.claude/config/tools.ps1`** — dot-sourced by the skills (`. ".claude/config/tools.ps1"`) to
  expose `$Tools` (e.g. `$Tools.papyrusCompiler`) plus an `Assert-Tool` guard that fails loudly on a
  missing/empty path.

**Change a path? Edit `tools.json` — never the skills.**

### Installing a Wabbajack modlist (optional, big)

A Wabbajack `.wabbajack` file installs a complete, self-contained **MO2 instance** — its own copy of
the game, the mods, and the tools (frequently the **Creation Kit** and the Papyrus compiler). These
are **hundreds of GB**, so they are **gitignored** (`/modlist/`, `/downloads/`) and never committed.

Install it with the Wabbajack GUI, then set its paths (game root, Creation Kit, Papyrus compiler,
BSA Browser, Champollion, …) in `tools.json`. After that the whole toolchain points at the modlist
with no per-skill edits. Install the list anywhere on a large drive; if you put it under the repo,
keep it in the gitignored `modlist/` folder.

## The round-trip workflow

```
.esp/.esm  ──serialize──►  YAML (committed to git)  ──deserialize──►  .esp/.esm
                 ▲                                                          │
                 └──────────────── you edit the YAML ◄─────────────────────┘
```

1. **Serialize** your plugin once to create its YAML folder.
2. Edit the YAML as text (and commit it).
3. **Deserialize** to rebuild the plugin.
4. Load the rebuilt plugin in xEdit / Creation Kit to verify before shipping.

For Ehlnofey the plugin is not edited by hand: the generator scripts in `src/Ehlnofey/` write the
YAML, which is then deserialized, re-serialized, and Spriggit's output adopted as the source (see
`arch-docs/design/flattening.md` §6).

## The Ehlnofey release

`build/manifest.json` has one release, `Ehlnofey`. It ships **no FOMOD** (`"fomod": false`): one
`.esp` with nothing to choose, so it packs a plain `Ehlnofey.7z`. The workspace template's
`src/ExampleMod/` worked example has been deleted.

## What is committed vs. ignored

| Committed (your authored work)          | Ignored (`.gitignore`)                                   |
|-----------------------------------------|----------------------------------------------------------|
| Your own mod's YAML folder(s)           | Binary plugins (`*.esp/*.esm/*.esl`)                     |
| Papyrus source `src/<ModName>/Scripts/source/*.psc` | Compiled scripts (`*.pex`)\*, archives (`*.bsa`/`*.ba2`) |
| A release's FOMOD, if it has one (`build/staging/<release>/fomod/`) — `Ehlnofey` does not | Build output (`dist/`, `build/dist/`) and the derived `.esp`/`.pex` that `build.ps1` regenerates inside `build/staging/<release>/` |
| `.spriggit`, configs, README, CLAUDE.md | Vanilla/third-party reference decompiles (`/reference/`) |
|                                         | Editor/venv (`.vscode/`, `.venv/`)                       |

**You commit source, not build artifacts.** Your mod's YAML folder, `src/<ModName>/Scripts/source/*.psc`
and each release's `fomod/` are the source of truth. `build/staging/<release>/` itself is committed
(so it shows what the actual mod folder looks like), but the `.esp` and `.pex` files `build.ps1`
generates inside it stay ignored by the blanket `*.esp`/`*.pex` rules — only the `fomod/` subfolder
is real source there. `dist/` and the packaged `build/dist/*.7z` are ignored the same way, along with
large third-party/vanilla reference decompiles.

\* **One deliberate exception.** Compiled `.pex` are ignored by default, but a plugin that ships
scripts opts its `Scripts/compiled/` folder back in through an explicit `.gitignore` rule. CI cannot
run the Creation Kit compiler, so it packages the committed `.pex` as-is. This is the only build
artifact in the repo and it exists for that single reason.

## Per-plugin folder layout

Created automatically when you serialize a plugin:

```
src/<ModName>/<modFolderName>/
  RecordData.yaml        # plugin header: ModKey, GameRelease, masters, author, Stats.Version
  spriggit-meta.json     # { PackageName, Version, Release, ModKey }
  <RecordType>/          # one folder per record type: Activators, MagicEffects, Quests, Perks, ...
    <EditorID> - <FormID>_<PluginName>.esp.yaml
```

File naming is fixed by Spriggit: `<EditorID> - <FormID>_<PluginName>.esp.yaml`.

## Spriggit commands (CLI 0.40.0)

Flags below are verified against the installed version (`Spriggit.CLI.exe serialize --help`).
Paths/settings come from `.claude/config/tools.json` via `. ".claude/config/tools.ps1"`.

### Serialize (plugin → YAML)

```powershell
. ".claude/config/tools.ps1"
& (Assert-Tool $Tools.spriggitCli 'spriggitCli') serialize `
  --InputPath   "MyMod.esp" `
  --OutputPath  "./MyMod" `
  --GameRelease $Tools.spriggit.gameRelease `
  --PackageName $Tools.spriggit.packageName `
  --PackageVersion $Tools.spriggit.packageVersion
```

### Deserialize (YAML → plugin)

```powershell
. ".claude/config/tools.ps1"
& (Assert-Tool $Tools.spriggitCli 'spriggitCli') deserialize `
  --InputPath   "./MyMod" `
  --OutputPath  "MyMod.esp"
```

On deserialize, `--PackageName`/`--PackageVersion` can be left blank — Spriggit auto-detects
them from the folder's `spriggit-meta.json`.

### Decompiling reference masters (lookup only)

Serialize vanilla or third-party plugins into a **gitignored** `reference/<name>/` folder so
you can grep them for FormKeys without committing them:

```powershell
. ".claude/config/tools.ps1"
& (Assert-Tool $Tools.spriggitCli 'spriggitCli') serialize `
  --InputPath   "Skyrim.esm" `
  --OutputPath  "./reference/skyrimBaseGame" `
  --GameRelease $Tools.spriggit.gameRelease `
  --PackageName $Tools.spriggit.packageName `
  --PackageVersion $Tools.spriggit.packageVersion
```

## FormKey discipline

- New records use **this plugin's** name as the FormKey suffix.
- Allocate contiguous FormKey blocks per feature for readable diffs.
- **Always grep the whole workspace for a hex FormID before assigning it** (collision check).
- ESL-flagged plugins are limited to `0x800–0xFFF` — confirm before exceeding.

See `CLAUDE.md` for Ehlnofey's design rules, current phase, conventions, working guardrails and the
arch-docs map (gotchas in full are in `arch-docs/gotchas.md`) — it is what a future Claude Code session reads instead
of re-deriving the project from scratch. See `arch-docs/skyrim-record-patterns.md` for record shapes
that build cleanly and still do nothing in-game.

## Papyrus scripts & packaging

Alongside the plugin, this workspace handles **Papyrus scripts** end-to-end on the command line —
extract them from archives, decompile to source, edit, recompile, and package a loose mod to test.

### Toolchain (paths from `tools.json`)

| Step | Tool | Config key |
|------|------|------------|
| Extract `.bsa`/`.ba2` | BSA Browser CLI (`bsab.exe`) | `$Tools.bsab` |
| Decompile `.pex` → `.psc` | Champollion | `$Tools.champollion` |
| Compile `.psc` → `.pex` | Papyrus Compiler (CK) | `$Tools.papyrusCompiler` |
| Open the editor | Creation Kit | `$Tools.creationKit` |
| Build `.esp` | Spriggit (see above) | `$Tools.spriggitCli` |

### Pipeline

```
.bsa/.ba2 ──bsa-extract──► .pex ──pex-decompile──► .psc ──(edit)──► .psc
                                                                      │
   dist/<ModName>/ ◄──package-mod──┬── .pex ◄──papyrus-compile────────┘
   (install in MO2 modlist)        └── <ModName>.esp ◄──spriggit-deserialize
```

### One-time setup (before first compile)

The base-game Papyrus **source** ships zipped. Extract it once to provide the vanilla `.psc`
imports and the user-flags file the compiler needs (many Wabbajack lists already ship loose source —
check `$Tools.gameSourceScripts` first):

- Extract `<gameDataDir>/Scripts.zip` → `$Tools.gameSourceScripts`
  (yields the vanilla `*.psc` + `TESV_Papyrus_Flags.flg`).

### Folder layout

```
src/                       # EVERY mod lives here — one folder per mod
  <ModName>/
    <ModName>ESP/          # Spriggit YAML — COMMITTED (source of truth)
    Scripts/source/*.psc   # .psc you author or clean — COMMITTED
    Scripts/compiled/*.pex # build output — COMMITTED via a .gitignore exception (see above)
dist/<ModName>/            # packaged loose mod (Data layout) — gitignored
  <ModName>.esp
  Scripts/*.pex
  Source/Scripts/*.psc
```

`src/` is the only place mod content goes, and it holds as many mods as you need side by side —
a main plugin plus its compatibility patches, for instance. Each gets its own `src/<ModName>/`
folder and its own release entry in `build/manifest.json`; `/mod-new-plugin` sets both up.

### Testing (manual, in an MO2 modlist)

The modlists under `$Tools.modlistsRoot` (`STD`, `LoreRim`, `Baseline`, …) — or a Wabbajack instance
at `$Tools.modlistRoot` — are Mod Organizer 2 instances. Use the **`mod-deploy`** skill rather than
copying by hand: it reads the destination from `tools.json` and then *verifies* the mod landed under
the exact expected folder name. A mod in a wrongly-named folder is invisible to MO2 and the game
runs happily without it, so the symptom looks like a broken record rather than a bad path.

Then in MO2: refresh, enable the mod and its `.esp`, set load order, and launch through MO2.
**A clean compile is necessary but not sufficient — verify the scripts actually run in-game.**

## CI build & release (GitHub Actions)

`.github/workflows/build.yml` rebuilds every release archive on each push to `main` — as a **smoke
test only, publishing nothing** — and cuts a named GitHub Release when you push a `v*` tag. It runs
on a free `windows-latest` runner and is driven by **`build/build.ps1`** + **`build/manifest.json`**
(the plugin → release-tree mapping). The build script contains no mod-specific names — everything it
builds comes from the manifest, so adding a plugin means editing JSON, not PowerShell.

What CI does: download the pinned Spriggit CLI → `deserialize` every plugin's YAML into the
committed `build/staging/<release>/` (whose `fomod/` subfolder is already checked into git; only
the derived `.esp`/`.pex` are regenerated) → copy the committed `.pex` into that release's `Scripts/`
→ `7z` each release into `build/dist/*.7z`. On a `v*` tag only, the archives are then attached to a
new GitHub Release named for the tag.

**Archives reach you in exactly two ways:** a **PR artifact** while a change is in review, and a
**`v*` tag Release** when it ships. Nothing is published from `main`.

**CI does NOT compile Papyrus.** The Creation Kit compiler + licensed base-game script source can't
run in the cloud, so each script-shipping plugin's compiled scripts are **committed** at
`src/<ModName>/Scripts/compiled/*.pex` (an explicit exception in `.gitignore`).

> **Contract:** whenever you change a `.psc`, recompile (`/papyrus-compile`) and **commit the
> updated `.pex`** — otherwise the packaged addon ships stale scripts. `build/build.ps1` fails the
> build if any `.pex` is missing, but it cannot detect a *stale* one.

Run the same build locally with Windows PowerShell 5.1 or `pwsh` (uses the Spriggit CLI from `tools.json`):

```powershell
powershell -File build/build.ps1              # full build -> build/dist/*.7z (+ a size/SHA-256 summary)
powershell -File build/build.ps1 -CheckFomod  # only verify manifest <-> fomod/ModuleConfig.xml parity
                                              # (also checks installer image paths resolve + aren't progressive JPEGs)
```

To release: `git tag v1.0 && git push origin v1.0` → the workflow builds and attaches the archives to
a new GitHub Release named `v1.0`. The **`github-release`** skill automates the curated flow:
changelog from the previous tag, push the tag, watch the build, then replace CI's generated notes
with the curated ones and mark the release Latest.

**PR test builds.** `.github/workflows/pr-build.yml` runs the *same* build on every pull request
(open/update) and attaches the archives to the PR as a downloadable **Actions artifact** named
`pr-<number>-test-builds`, plus a sticky comment linking to the run's Artifacts (download requires
being signed in to GitHub). Each push replaces the previous artifact; merging or closing the PR
deletes it and updates the comment. The shared setup+build steps live in the composite action
`.github/actions/build-mod-archives/` (used by both workflows), so the Spriggit version and build
invocation stay in one place. (Fork PRs get a read-only token, so the comment/delete steps only work
for branches pushed to this repo.)

### Gotchas

- **Decompiled source is a reconstruction**, not the author's original — expect auto-named
  variables, reconstructed control flow, and lost comments. Always recompile + test.
- **Missing-type compile errors** mean a referenced API's source (SKSE, SkyUI, MCM, another mod)
  isn't on the import path. Add its `Source\Scripts` dir to the compiler's `-i` list and record
  required imports in `CLAUDE.md`.
- For decompiled-source cleanup and compile-error fixing, use the `papyrus-script-engineer` subagent.

## Claude skills & subagents

This workspace ships Claude Code helpers under `.claude/` (committed, so they're shared). They
bundle the verified CLI path and flags so you don't retype them.

**Skills** (invoke with `/<name>`):

| Skill | What it does |
|-------|--------------|
| `mod-new-plugin` | **Scaffold a new plugin** — YAML folder + manifest entry (FOMOD only if the install has options), buildable from the first commit |
| `spriggit-serialize` | Serialize a plugin → its YAML folder |
| `spriggit-deserialize` | Rebuild a plugin from its YAML folder (+ xEdit/CK verify reminder) |
| `spriggit-decompile-reference` | Serialize a vanilla/third-party master into gitignored `reference/` for lookups |
| `formkey-check` | Scan the workspace (+ `reference/`) for FormID collisions or the next free block |
| `bsa-extract` | Extract/list files (e.g. `*.pex`) from a `.bsa`/`.ba2` (`bsab.exe`) |
| `pex-decompile` | Decompile `.pex` → editable `.psc` (Champollion) |
| `papyrus-compile` | Compile `.psc` → `.pex` (CK `PapyrusCompiler.exe`) |
| `package-mod` | Assemble `dist/<ModName>/` (esp + scripts) for MO2 testing |
| `mod-deploy` | **Deploy into an MO2 modlist and verify it landed** under the exact expected folder name |
| `github-release` | Cut a curated `vX.Y.Z` release — changelog, tag push, then curate CI's notes |

**Subagents** (specialized agents with their own context):

| Subagent | Role |
|----------|------|
| `spriggit-record-editor` | Creates/edits Spriggit YAML records following the naming & FormKey conventions |
| `spriggit-formkey-auditor` | Read-only audit for collisions, dangling references, broken cross-record invariants, and in-game anti-patterns |
| `papyrus-script-engineer` | Cleans decompiled `.psc`, fixes compile errors, drives the extract→compile→package loop |

**Automatic checks.** `.claude/settings.json` registers a `PostToolUse` hook that runs
`build/Test-RecordYaml.ps1` after every edit to a Spriggit record file. It is a fast structural
check, not a YAML parse — tabs, BOMs, odd indentation, ESL FormID range, and whether the filename's
`<EditorID>`/`<FormID>` still agree with the contents. That last check catches a real class of
copy-paste bug: run it across a large plugin and it finds records whose EditorID was renamed but
whose filename never was. Run it by hand over the whole repo with:

```powershell
powershell -File build/Test-RecordYaml.ps1
```

**Working guardrails.** `CLAUDE.md` carries a short list of rules distilled from real failures —
ground-truth before claiming, copy records rather than retyping hex, verify the deploy path before
blaming the records, a clean build is not a working mod. They are worth reading once even if you
never use Claude Code with this repo.
