# Ehlnofey — Workspace Guide

> **This file is the most valuable thing in the repo.** It is what a future session reads instead of
> re-deriving your conventions from scratch. When you learn something the hard way — a FormID
> allocation, a record shape that didn't work, a compile import you needed — write it here.
>
> Everything above *[The mod](#the-mod-ehlnofey)* is generic workspace mechanics. Everything below it
> is Ehlnofey: what we are building, what phase we are in, and where the research lives.

## What this is

**Ehlnofey** is a **deleveling overhaul for SkyrimSE** — it replaces vanilla's player-level scaling
with fixed, hand-set rules so that difficulty and reward belong to *places*, not to the player's
level. See [The mod](#the-mod-ehlnofey) for the design thesis and current phase.

The repo it lives in is a Spriggit YAML workspace: plugins are decompiled to YAML, edited as text,
and re-packed to `.esp`/`.esm`. **Never hand-edit binary plugins — edit the YAML.**

- Spriggit package/source: `Spriggit.Yaml.Skyrim`
- Spriggit CLI version: `0.40.0`
- CLI path + all tool paths: `.claude/config/tools.json` (gitignored; see Tooling config below).

## Knowledge base (oculory-rag) — search it before answering

If the `oculory-rag` MCP tools are available, use them **before** answering from memory and
before grepping `reference/` by hand:

- **`search`** — the written knowledge base: engine behaviour, record patterns, SPID, Spriggit
  and Mutagen workflow, third-party mod analyses, prior art and design notes.
- **`game_search` / `game_read`** — the decompiled game files themselves: ~331k records and
  ~19k Papyrus scripts, looked up by EditorID, FormID, FormKey or in-game name. Prefer these
  over walking `reference/` by hand; they are indexed and answer in milliseconds.
- Pass `game="skyrim"` for this repo, so Enderal facts do not leak into a Skyrim answer.

Cite the doc id or FormKey a claim rests on, and keep the `[verified]` / `[community]` /
`[unverified]` marks honest — retrieved text is evidence, not proof.

These tools are an optional local index. If they are not present, work in this repo exactly as
before: nothing here depends on them.

## Tooling config (no hardcoded paths)

All tool paths and per-machine settings live in **`.claude/config/tools.json`** (gitignored;
template at `tools.example.json`). Skills load it via `.claude/config/tools.ps1`, which exposes
`$Tools` (e.g. `$Tools.spriggitCli`, `$Tools.papyrusCompiler`, `$Tools.creationKit`,
`$Tools.gameSourceScripts`) and an `Assert-Tool` guard. **Never reintroduce a hardcoded path into a
skill — change the config instead.**

- **Modlists:** a Wabbajack `.wabbajack` list installs a full MO2 instance (game copy + mods +
  tools, often the **Creation Kit** and Papyrus compiler) that can be hundreds of GB. It is
  gitignored (`/modlist/`, `/downloads/`). Run the **`modlist-install`** skill to install one and
  auto-discover its tool paths into `tools.json`.
- Without a modlist, fill `tools.json` by hand from `tools.example.json`.

## Workflow (round-trip)

```
.esp/.esm  ──serialize──►  YAML (committed)  ──deserialize──►  .esp/.esm
                 ▲                                                  │
                 └──────────── you edit the YAML ◄──────────────────┘
```

Serialize/deserialize commands: see `README.md`. After editing YAML, deserialize and load the plugin
in xEdit/CK to verify before shipping.

## Folder map

```
src/                       # EVERY mod lives here — one folder per mod, add as many as you like
  <ModName>/
    <ModName>ESP/          # Spriggit YAML — COMMITTED, source of truth
    Scripts/source/*.psc   # Papyrus source — COMMITTED
    Scripts/compiled/*.pex # COMMITTED via a .gitignore exception (CI can't compile Papyrus)
build/                     # build.ps1 + manifest.json + committed FOMOD trees
arch-docs/                 # world research + design spec + record-pattern guide (see arch-docs map)
reference/                 # gitignored — vanilla/third-party decompiles, LOOKUP ONLY
                           #   Base/       Skyrim.esm, Update.esm and the 3 DLCs: Phase 1's evidence
                           #   mods/       third-party plugins as downloaded — the CC packs
                           #   mods/*Yaml/ Spriggit decompiles of them (CreationClubYaml/)
modlist/                   # gitignored — an installed MO2 instance, hundreds of GB
```

`src/` is the only place mod content goes. A repo can hold several mods side by side — a main
plugin and its compatibility patches, say — each its own `src/<ModName>/` folder with its own
`build/manifest.json` release entry. Only `src/`, `build/`, `arch-docs/`, `.claude/` and the root
configs are committed.

## Guardrails — how to work in this repo

These are distilled from real failures in this workspace's lineage. They cost test cycles to learn.

1. **Ground-truth before claiming.** Do not conclude a patch is or isn't needed, or that a record
   does what its name suggests, from the name alone. Read the serialized record, trace the
   FormKeys, and **show the evidence alongside the verdict**. If a mechanic depends on a third-party
   mod's compiled script, read that script's decompiled source — data-driven parts extend to your
   records, hardcoded index checks do not.
2. **Prefer a proven archetype to an invented mechanism.** Read
   `arch-docs/skyrim-record-patterns.md` first. Skyrim fails silently: an inert record produces no
   error, so an invented mechanism costs a full build-deploy-launch-test cycle to disprove.
3. **Copy records verbatim; never retype hex.** When basing a record on an existing one, copy the
   file and edit the fields that differ. Hand-transcribing `Data:` blobs has produced odd-length hex
   that fails the build, and dropped array entries that fail silently. Prefer a script over
   retyping. Re-check array lengths after any edit.
4. **Ask for paths; don't hunt for them.** Install locations, modlist names, MO2 folders and mod
   names live in `tools.json` or in the user's head. Read the config or ask — filesystem-searching
   for them wastes time and lands on the wrong candidate.
5. **Verify the deploy target before blaming the records.** A mod in a wrongly-named MO2 folder is
   invisible; the game runs fine and the change simply isn't there. The `mod-deploy` skill checks
   this. Rule out "never loaded" before debugging "loaded but broken".
6. **A clean build is not a working mod.** Deserialize, xEdit and the Papyrus compiler all passing
   proves it *builds*. Only launching the game proves it *runs*. Say which of the two you have
   actually established.
7. **Recompile and re-commit `.pex` whenever a `.psc` changes.** CI cannot run the Creation Kit
   compiler. `build/build.ps1` fails on a *missing* `.pex` but cannot detect a *stale* one.
8. **PowerShell 5.1 is the target** for build scripts and skills: `Set-StrictMode` is on, there is
   no `&&`/`||`, no ternary, no null-coalescing, and no built-in YAML parser. Write `-Encoding utf8`
   explicitly when a file will be read by other tools.

## FormKey discipline

- New records use this plugin's name as the FormKey suffix: `<hex>:<YourMod>.esp`.
  Records that **override** a base/third-party record keep the original suffix
  (e.g. `09BC43:Skyrim.esm`) — that is how you tell at a glance which records you invented.
- **ESL (`Small`) plugins are constrained to FormIDs `0x800–0xFFF`.** Confirm with the user before
  exceeding; there is headroom but it is finite.
- Allocate a **contiguous block per feature** for readable diffs.
- ALWAYS grep the whole workspace (your plugin folders + `reference/`) for a hex FormID before
  assigning it — use the `formkey-check` skill.

## Papyrus toolchain

Scripts go through extract → decompile → edit → compile → package. Use the matching skills; the
`papyrus-script-engineer` subagent handles decompiled-source cleanup and compile-error fixing.

**Tool paths:** all resolved from `.claude/config/tools.json` — do not hardcode.

| Step | Tool | Config key |
|------|------|------------|
| Extract `.bsa`/`.ba2` | `bsab.exe` | `$Tools.bsab` |
| Decompile `.pex`→`.psc` | `Champollion.exe` | `$Tools.champollion` |
| Compile `.psc`→`.pex` | `PapyrusCompiler.exe` | `$Tools.papyrusCompiler` |
| Open Creation Kit | `CreationKit.exe` | `$Tools.creationKit` |

**Compiler imports:** base-game source = `$Tools.gameSourceScripts` (extract
`<gameDataDir>/Scripts.zip` once, or use what the modlist ships). Flags file: `$Tools.papyrusFlags`.

**Per-project import dirs** — persist in `tools.json`'s `importDirs` array (the `papyrus-compile`
skill appends them to `-i`). Record each one here as you discover it:

| API / framework | Source `.psc` dir |
|-----------------|-------------------|
| _(base only)_ | Nothing in Ehlnofey compiles against anything but base-game source yet. Add SKSE/SkyUI/MCM/PapyrusUtil dirs here the first time a script needs them. |

**Testing:** MO2 modlists under `$Tools.modlistsRoot`, or a Wabbajack instance at
`$Tools.modlistRoot`. Use the `mod-deploy` skill rather than copying by hand.

## Workspace gotchas

- **FOMOD images that actually render in MO2** — a config can build clean, pass
  `build.ps1 -CheckFomod`, open its wizard normally, and still show *no image at all*. Nothing
  warns you. This recipe is confirmed working in MO2. **There is no longer a worked example in this
  repo** — it went with `ExampleMod`; the live copy is `build/fomod-example/` in the `claudemoddev`
  template workspace. Follow the four points below rather than re-deriving:
  1. `path=` is relative to the **archive root**, so an image at `fomod/images/foo.jpg` is
     referenced as `path="fomod\images\foo.jpg"` — *including* the `fomod` prefix.
  2. Use **backslashes** in `path=`, as the shipped configs do.
  3. Declare an `<installSteps>` block, even for a mod with no real choices (one
     `SelectExactlyOne` group holding a single `Recommended` plugin). A config with only
     `<requiredInstallFiles>` gives MO2 no wizard page to draw the banner on.
  4. Use a **baseline** JPEG or a PNG, not a progressive JPEG. Check with
     `od -A d -t x1 -v img.jpg | grep -oE 'ff c[0-9a-f]'`: `ff c0` is baseline (fine), `ff c2` is
     progressive. Re-encode progressive files via `System.Drawing` before shipping.

  These four were fixed **together** after several one-at-a-time attempts each failed, so which is
  individually decisive is unverified — treat the set as the known-good recipe, and do not drop one
  on the assumption it does not matter.

  `build/build.ps1 -CheckFomod` now enforces points 1, 2 and 4: an unresolvable `path=` or a
  progressive JPEG **fails** the check (with a "did you mean `fomod\…`?" hint for the missing
  prefix), and forward slashes warn. It cannot check point 3 — whether an `<installSteps>` block
  exists at all — because a config legitimately may not want one.
- **Decompiled `.psc` is a reconstruction** (Champollion): auto-named vars, reconstructed control
  flow, lost comments/flags. Always recompile and test in-game; a clean compile is not proof.
- **Missing-type compile errors** → the referenced API's source isn't on the import path; add its
  `Source\Scripts` dir to `importDirs` in `tools.json` and record it in the imports table above.
- **YAML comments do not survive a re-serialize.** Spriggit rewrites the folder from the binary
  plugin, so any `#` comment you add to a record file is lost the next time anyone runs
  `/spriggit-serialize`. Put durable explanation in this file, not in the record YAML.
- Edit `.psc`/YAML, never the binary `.pex`/`.esp`. Commit source, not build artifacts.
- See `arch-docs/skyrim-record-patterns.md` for the in-game failure modes that produce no build
  error — that list is the single highest-value read before authoring a new mechanic.

---

# The mod: Ehlnofey

## The idea, and the name

**Ehlnofey delevels Skyrim.** Vanilla scales the world to the player: bandits, draugr and loot are
generated relative to your level, so a dungeon cleared at level 5 is the same fight at level 40 and
the map has no topography of danger. Ehlnofey replaces that with **fixed, hand-set rules** — every
enemy, dungeon and hoard has a level and a loot profile that does not move — aiming at an
*immersive, lore-friendly and gameplay-optimised* result rather than a difficulty-slider mod.

The name is the thesis. The Ehlnofey were et'Ada who stopped wandering: instead of remaining free,
mutable spirits, they bound themselves into the substance of Nirn and became its fixed laws — the
Earth Bones, the unchanging structure under everything. That is exactly the operation this mod
performs on Skyrim: it takes a world that bends to the player and re-imprints static, indifferent
rules onto it. Docs and record names lean on that vocabulary (**bones** = the fixed structure).

## The three bones (design rules)

Every design decision has to answer to these. If a proposal violates one, it needs an explicit
exception recorded in `arch-docs/design/`, not a quiet pass.

1. **The world does not scale.** Difficulty and reward are properties of a place and a creature, set
   once. Nothing recalculates against the player's level.
2. **Danger is legible.** If the player can be killed by walking somewhere, the world must have told
   them first — geography, lore, faction, visual tier, NPC dialogue, quest gating. A fixed world is
   only fair if it can be read.
   > **This is the load-bearing bone.** `progression.md` found that vanilla gates content by level
   > essentially nowhere (30 conditions across 1,811 quests, none on any questline) and that 20 gold
   > buys a carriage ride to any hold capital from minute one. Legibility is not a nice-to-have — it
   > is the *only* protection a player has once the world stops scaling.
   > **The mechanism already exists: tier display names.** Draugr → Restless Draugr → Wight → Scourge
   > → Deathlord; Dremora Churl → Caitiff → Kynval → Kynreeve → Markynaz → Valkynaz. These are
   > lore-ordered, player-facing, and map 1:1 onto the level ladders. Keeping name aligned with power
   > is a hard constraint — see `lore-constraints.md`.
3. **Reward follows place, not level.** Good loot exists because of *where* it is (a Nordic tomb, a
   Dwemer ruin, a dragon's hoard, a named boss), never because the player happened to be level 40.

**Non-goals** (keep scope honest): not a combat overhaul, not a perk/skill overhaul, not a survival
mod, not a new-content mod. Ehlnofey changes *where the numbers come from*, and nothing else.

## Current phase

**Phase 4 restarted on 2026-09-27: `Ehlnofey.esp` is being rebuilt from scratch.** The live
architecture is **`arch-docs/design/flattening.md` — read it first**; its §6 is the order of work.
The spec it executes is **`arch-docs/design/archetype-tiers.md`**: every family's levels, rosters,
weights, pins and gear, as decided by the user faction by faction (Jira WD-43…64).

**The method is called *flattening the leveled lists*:** strip the player-level gates from every
`LVLN`/`LVLI` while keeping the pool, weight the pool by duplicate entries, and give every
`PcLevelMult` actor a fixed level — followers included.

**The rule of the rebuild: every record is authored here, from vanilla.** Inputs are
`reference/Base/` (the five Bethesda masters), `reference/mods/CreationClubYaml/` (only for CC plugins
the mod takes as masters) and the design docs. **No third-party mod's records are an input, and
nothing is copied from `ProofOfConceptESP`.** Generators for the rebuild live in `src/Ehlnofey/`.

**Status:** scaffold only. `src/Ehlnofey/EhlnofeyESP/` holds a header (ESL-flagged; Skyrim, Update,
Dawnguard, Dragonborn) and builds clean. No records yet. **Next:** the constants, then the `LVLN`
(`flattening.md` §6 steps 2–3).

**Decisions carried over from the proof of concept** (user; revisit if they no longer fit):
- **Creation Club is a hard requirement** (2026-09-23: AE is near-universal). CC packs whose start-up
  quests re-gate our lists become masters so those injectors can be neutralised.
- **Rung levels are vanilla's**; a fixed vanilla level is kept. Only `PcLevelMult` actors get a new one.
- **Illegible boss bands are pinned**, one level per displayed name.
- **Dragon gear is craft-only** (WD-63).
- **No SkyPatcher, no Synthesis.** The mod is one plugin.

### The proof of concept (archived)

`src/Ehlnofey/ProofOfConceptESP/` is the first build: **3,013 records**, extracted from a third-party
deleveling mod and then hand-tuned faction by faction. It proved the method in play — Bleak Falls
Barrow and Swindler's Den gave the same spread of enemies at player level 1 and 45, and most
factions' levels and gear were verified in game. It is **not released** (the manifest builds
`EhlnofeyESP`), and it is a derivative work that cannot be published.

Its generators are in `src/Ehlnofey/proof-of-concept/` and write only into `ProofOfConceptESP`. The
full record of what it shipped, what play found and which bugs it hit is
`arch-docs/design/proof-of-concept.md` §10. **Read that before starting a faction** — nearly every bug
it found (unarmed factions, inert level grafts, runtime injectors, game-wide list leaks) is a trap the
rebuild can walk into again.

### Phase 3 record

The four decisions Phase 3 made:

| Decision | Verdict |
|---|---|
| **The ladder** | **T1–T7 = 4 / 8 / 14 / 21 / 30 / 40 / 50** (`design/tiers.md`) |
| **The map** | all **355 zones** assigned, generated from rules, in `difficulty-map.md` §7 |
| **Loot** | ~~no truncation pass needed~~ — **overturned** by the gear-resolution test: worn gear follows the player, not the zone (`flattening.md` §2.2) |
| **Architecture** | ~~hybrid: zones in the plugin, actors in rules~~ — **superseded** by flattening (`flattening.md` §2) |

**Scope:** Skyrim + Dawnguard + Dragonborn. Hearthfire content is excluded (no zone, dungeon or
region), though `HearthFires.esm` may still be needed as a master if an overridden record points at it.

Two Phase 3 findings still hold. **Vanilla's zone floors must be stretched, not ratified**: 73% of
Skyrim's 280 zones sit at level ≤ 8 and none exceeds 24, while the content ladders run to 46–60. And
**the tier ladder lands exactly on the vanilla gear ladder**: T1–T7 select Steel / Orcish / Dwarven /
Elven / Glass / Ebony / Daedric, which matters if containers stay zone-gated (`flattening.md` §5.4).
The five gating engine questions are answered in `design/engine-behaviour.md`, and the in-game probe
results are in `design/probe-test-protocol.md`.

## Phase plan

| Phase | Output | Done when |
|---|---|---|
| **0 — Workspace** | Spriggit round-trip, skills, CI, base+DLC decompiles in `reference/` | ✅ complete |
| **1 — World research** | `arch-docs/world/*` — enemy taxonomy, factions, dungeons, regions, progression, lore constraints, DLC deltas | Every hostile archetype and every dungeon is in a table with its vanilla scaling behaviour cited from `reference/` |
| **2 — Prior art & method** | how other deleveling mods do it | ✅ complete. Its write-ups were deleted on 2026-09-27: the rebuild takes no third-party mod as an input |
| **3 — Design spec** | `arch-docs/design/*` — tier system, region difficulty map, loot model, and the **implementation-strategy decision** | ✅ complete — 5 documents; all 355 zones assigned; architecture decided |
| **4 — Build** | `src/Ehlnofey/EhlnofeyESP/` — plugin YAML, its generators, release. **Restarted 2026-09-27**; the first attempt is archived as `ProofOfConceptESP` | Deserializes clean, opens clean in xEdit, **and has been launched in-game** |

Phases 1–3 are documentation work. **Do not start authoring records in `src/` before Phase 3 has a
written spec** — the whole point of the arch-docs is that a deleveling pass touches thousands of
records and reversing a bad taxonomy afterwards is far more expensive than deciding it on paper.

## arch-docs map

Research and design live here; this file stays the index. Create these as the phases produce them.

```
arch-docs/
  skyrim-record-patterns.md      # EXISTS — read before authoring any mechanic
  world/
    overview.md                  # EXISTS — bird's-eye census of the base game; read this first
    enemy-taxonomy.md            # EXISTS — every hostile archetype, its ladder, its scaling class
    unique-enemies.md            # EXISTS — named bosses + unique enemy races, base game + DLC
    factions.md                  # EXISTS — combat factions, membership counts, relation graph, filter viability
    dungeons.md                  # EXISTS — all 226 dungeons by hold: type, zone, level, boss, word wall
    regions.md                   # EXISTS — the nine holds: map position, composition, the real gradient
    progression.md               # EXISTS — routes, level gates (almost none), the carriage problem
    lore-constraints.md          # EXISTS — what the fiction permits; tier names ARE the lore hierarchy
    dlc-deltas.md                # Dawnguard / Hearthfire / Dragonborn additions and their zones
                                 #   (DLC coverage currently lives inline: taxonomy §2.7, dungeons §3,
                                 #    factions §6, regions §4 — consolidate here if it outgrows them)
  design/
    flattening.md                # EXISTS — READ FIRST. THE live architecture: why flatten and not
                                 #   clamp zones, the rules of the method, scope, and §6 = the order
                                 #   of work for the rebuild. Supersedes implementation-strategy.md §1.
    archetype-tiers.md           # EXISTS — THE SPEC: every family's levels, rosters, weights, pins and
                                 #   gear, decided faction by faction (WD-43…64), + the biome rosters.
    faction-playbook.md          # EXISTS — READ BEFORE ANY FACTION: survey, rungs, gear, "who uses
                                 #   this list", game-wide-list leaks, injector audit, close-out.
    proof-of-concept.md          # ARCHIVED — the first build's architecture (third-party extract) and,
                                 #   in §10, the full log of what it shipped and what play found.
    lvli-reachability.ps1        # EXISTS — plus roster-census / leveled-list-census / lvli-fork-*
                                 #   / biome-rosters .ps1: the evidence behind flattening.md §5 and
                                 #   archetype-tiers.md §4.1.
    engine-behaviour.md          # EXISTS — the five gating engine questions, answered with sources
                                 #   (ECZN clamp scope, Min==Max, loot, LevelModifier, SkyPatcher
                                 #    timing/saves). Read before tiers/difficulty-map/implementation.
    tiers.md                     # EXISTS — the T1–T7 ladder (4/8/14/21/30/40/50), the LevelModifier
                                 #   GMST decision, archetype home bands, class-D fixed levels, and
                                 #   the bone-1 exception verdicts. Read before difficulty-map/loot.
    difficulty-map.md            # EXISTS — all 355 zones assigned T1–T7, generated. The rules are
                                 #   type→tier + word-wall bump + region floor/ceiling + 44 explicit.
    build-difficulty-map.py      # EXISTS — regenerates difficulty-map.md §7 from reference/.
                                 #   Change the seven numbers in TIER and re-run to recalibrate.
    loot-model.md                # EXISTS — the tier ladder IS the material ladder. Its "no truncation
                                 #   pass needed" headline is DEAD (flattening.md §2.2).
    implementation-strategy.md   # EXISTS — the Phase 3 zone-first hybrid, SUPERSEDED by flattening.md.
                                 #   §6 (the overworld census) is still cited as evidence.
    probe-test-protocol.md       # EXISTS — the instrument + script for the three gating in-game
                                 #   tests (§9 step 1). §4 holds a census that CUTS the
                                 #   LevelModifier:None exposure from ~1,928 refs to 9.
```

## Research rules (Phases 1–3)

The repo's guardrails apply with extra force here, because deleveling research is exactly where
plausible-sounding claims are cheapest to make and most expensive to act on:

- **Cite `reference/`, not memory.** A claim like "bandits use a level multiplier" must name the
  record and the field as serialized: `reference/Base/01Skyrim/…`. Grep the decompile; quote it.
- **Mark confidence** the same way `skyrim-record-patterns.md` does: `[verified]` = read in
  `reference/` or observed in-game here; `[community]` = established modding knowledge, not re-tested;
  `[unverified]` = plausible, needs checking. Never silently upgrade a mark.
- **Prior art gets read, not recalled.** Before writing that a mod "does X", read its plugin (via
  `/spriggit-decompile-reference` into `reference/mods/`), its INIs, or its documentation. Third-party
  behaviour that lives in a compiled script or SKSE DLL is not knowable from the record data alone.
- **Follow the template chain before concluding.** A leveled spawn's stats can come from an actor
  template rather than the NPC record you are looking at, so "this NPC is level 6" is a claim about
  whichever record actually owns the level. Trace it.

## The vanilla scaling machinery

The levers a deleveling mod has to touch. Field names below are concepts — **confirm the exact
Mutagen/Spriggit field name in `reference/` before writing YAML**, and record the confirmed name here.

| Mechanism | Record type | Why it matters to Ehlnofey |
|---|---|---|
| Static vs. player-relative level | `NPC_` (level is either a fixed number or a PC-level multiplier with calc-min/calc-max) | The core lever. "Delevel an NPC" mostly means replacing the multiplier with a fixed level. `[community]` |
| Actor templates | `NPC_` template + template flags | A spawn may inherit stats/traits from another record, so editing the visible NPC can do nothing. Trace before editing. `[community]` |
| Leveled actor lists | `LVLN` | Chooses which variant spawns, with per-entry level gates and chance-none. Deleveling means flattening or splitting these per tier. `[community]` |
| Leveled item lists | `LVLI` | The loot side of the same machinery — vanilla gates gear tiers by player level here. `[community]` |
| Encounter zones | `ECZN` | Per-location min/max level and flags. A zone *clamps* the level the leveled-spawn machinery computes, so once the lists are flat there is nothing left for it to clamp for actors — **the `ECZN` and `LVLN` decisions are one decision.** Zones still govern container loot (`flattening.md` §5.4). **Clamp semantics now researched** (`design/engine-behaviour.md`): the zone level is `clamp(playerLevel, min, max)` computed on first visit, **stored in the save, never recalculated** until zone reset; it governs leveled-list selection (and, per docs, loot lists) but **`PcLevelMult` actors ignore it** — they need per-NPC fixing. `[community]` |
| Placed-actor difficulty | `ACHR` / `PlacedNpc` field `LevelModifier` (`Easy`/`Medium`/`Hard`/`VeryHard`) | Vanilla's hand-tuning layer, on **5,685 of 10,504** placed actors (2,524 of 4,452 interior); the four values map to `fLeveledActorMult*` = 0.33/0.67/1/1.25. It multiplies a leveled-list *lookup* level, so it is **inert once the lists are flat**. `design/tiers.md` §4 had chosen 0.70 / 0.85 / 1.00 / 1.25 for the zone architecture; under flattening the GMSTs are not overridden. `[verified]` |
| Global knobs | `GMST` (level-scaling and difficulty multipliers) | Blunt but cheap; changes everything at once. Use deliberately, never as a substitute for tiering. `[community]` |
| Spawn gating by player level | 12 `LevelGate*` `GLOB` records (Spriggan 8 … Giant 24) | Vanilla's only systematic level gate — it withholds world-encounter *creatures* until the player is roughly their level. **This is a bone-1 violation that already exists**; delete or document as an exception. `[verified]` |
| Capability, not level | `PERK`, `SPEL`, `CSTY` (combat style) | A level-20 bandit's threat comes largely from perks/spells/AI. Deleveling levels without capability produces a flat, boring world. `[community]` |

## Naming & FormKey conventions

Fixed now so Phase 4 does not have to argue about it:

- **Plugin:** `Ehlnofey.esp`, **ESL-flagged**. Masters: `Skyrim.esm`, `Update.esm`, `Dawnguard.esm`,
  `Dragonborn.esm`. Add a master only when a record needs it, and record why here. Expect
  `HearthFires.esm` and a set of Creation Club plugins once the runtime injectors are neutralised
  (`flattening.md` §5.5): the proof of concept ended with 31 masters, 26 of them CC — among them
  `HearthFires.esm`, needed because an overridden CC quest pointed at Hearthfire records and Spriggit
  cannot write a FormKey whose plugin is not a master. Its list is in `ProofOfConceptESP/RecordData.yaml`.
  Keep CC masters in `Skyrim.ccc` order.
- **EditorID prefix:** `EHL_`, then the domain, then the specific: `EHL_LVLI_DraugrBossHoard_T4`,
  `EHL_ECZN_BleakFalls`. Tier suffixes are `_T<n>` against the ladder in `design/tiers.md`.
- **New records** start at `0x800` and are allocated in a **contiguous block per feature** (one block
  for encounter zones, one for leveled lists, …). Record each block here as it is claimed.
- **Overrides keep the original master's suffix** (`09BC43:Skyrim.esm`), which is how you tell an
  invented record from a vanilla one at a glance. Ehlnofey will be override-heavy, so this matters
  more here than in a content mod.
- **ESL decision: RESOLVED — yes, ESL-flag it.** The mod is almost all overrides; new records (a few
  new leveled lists, forked material ladders if containers stay gated) are tens against ESL's
  **2,048-slot** `0x800–0xFFF` range.
- Always `/formkey-check` before claiming a block.

**FormID usage** (claimed blocks; everything else is an override):

| Block | Feature | Records |
|---|---|---|
| — | none claimed yet | |

**Next free: `0x800`.** `ProofOfConceptESP` shares the ModKey `Ehlnofey.esp` and claimed `0x800`–`0x805`
(Thalmor rare glass, Silver Hand lists, Solstheim boss-chest weapons), so `/formkey-check` will report
those as taken. They are not collisions: the two folders are different builds of the same plugin and
are never loaded together. Reuse the numbers freely.

## Useful FormKey constants

Add the encounter-zone, faction and leveled-list FormKeys here as Phase 1 confirms them — that table
is the payoff of the research phase.

| FormKey | Meaning |
|---|---|
| `000014:Skyrim.esm` | PlayerRef |
| `000038:Skyrim.esm` | GameHour global |
| `000039:Skyrim.esm` | GameDaysPassed global |
| `00003C:Skyrim.esm` | Tamriel worldspace |
| `038AB1:Skyrim.esm` | BleakFallsBarrowZone (ECZN) — one of only 6 vanilla+DLC zones with a `MaxLevel` (see `design/engine-behaviour.md` §2) |
| `039CFC:Skyrim.esm` | LCharBanditMelee1H (LVLN) — the worked example of vanilla's scaling chain |
| `0130DB:Skyrim.esm` | LocTypeDungeon keyword (202 locations) |
| `0F5E80:Skyrim.esm` | LocTypeClearable keyword (199 locations) |
| `039CFC:Skyrim.esm` | LCharBanditMelee1H — canonical level-gated LVLN ladder |
| `0E7B2C:Skyrim.esm` | LCharGuardImperial — canonical `PcLevelMult` cluster (guards, ×1, [20–50]) |
| `08E4F1:Skyrim.esm` | AlduinBase — the only fully player-scaled boss (`PcLevelMult` ×1.2, [10–100]) |
| `016771:Skyrim.esm` | LocTypeHold keyword — **10** holds, not 9: Skyrim's nine + `DLC2SolstheimLocation` |
| `016E2A:Dragonborn.esm` | DLC2SolstheimLocation — a tenth `LocTypeHold` root (levels 6–40) |
| `016E2B:Dragonborn.esm` | DLC2ApocryphaLocation — root with **no keywords**; 7 Black Books, all level 25 |
| `000013:Skyrim.esm` | CreatureFaction — the creature/humanoid divide (660 NPCs) |
| `01A1D9` / `01A1DB` / `01A1DA` / `023C0B` `:Skyrim.esm` | `fLeveledActorMult` Easy/Medium/Hard/VeryHard — vanilla 0.33/0.67/1/1.25, Ehlnofey 0.70/0.85/1.00/1.25 (`design/tiers.md` §4) |
| `10FEDD` / `10FEDF` / `10FEDE` `:Skyrim.esm` | `fSpecialLootMinZoneLevelMult` 0.4 / `…MaxZoneLevelMult` 1.0 / `…MinPCLevelMult` 0.6 — the boss-chest loot roll. The `…MinPCLevelMult` is a **live bone-1 leak** (floor at 0.6 × *player* level, zone-independent); one record to close |
| `01E60D:Skyrim.esm` | `EncBandit04TemplateMelee` — the vanilla `L=0` bug; Ehlnofey sets it to 14 |

The full primary-source list is `arch-docs/world/enemy-taxonomy.md` §8 — cite from there rather than
re-deriving.

## Ehlnofey gotchas

Fill this as the project teaches you things.

- **Mutagen omits default-valued scalars in the YAML.** An absent field means *the default*, not
  "not configured". `EncBandit04TemplateMelee` (01E60D) serializes its level as
  `Level: {MutagenObjectType: NpcLevel}` with no `Level:` line — that is level **0**. Never read
  absence as "unset". `[verified]`
- **`TemplateFlags` decides which record owns a stat.** If an NPC lists `Stats` in `TemplateFlags`,
  its own `Level:` is inert and the template's value wins. Read the flags before believing a number
  on an NPC record. `[verified]`
- **Follow the template chain all the way to an `LVLN`, not just one hop.** A named boss like
  `JyrikGauldurson` templates onto `LvlDraugrAmbushWarlock`, which templates onto `LvlDraugrWarlockMale`,
  which templates onto the **leveled list** `LCharDraugrWarlockMale`. Stopping at the first NPC hop
  reports `L=1` and is wrong — 21 of Skyrim's named bosses have no fixed level at all. A resolver must
  treat "template is a `LeveledNpcs` record" as a distinct terminal case. `[verified]`
- **Nobody here knows how a nameless NPC resolves its displayed name. Do not reason about it — put
  the name on every record in the set.** `[verified that the obvious model is wrong]`
  An NPC's name and its level travel on different template flags (`Traits` carries the name, `Stats`
  the level), so they can diverge — that much holds. What does **not** hold is any tidy rule for what
  a leaf with no `FULL` and no `Traits` flag falls back to. Two vanilla facts contradict every model
  tried so far: `EncBandit01*` and `EncBandit02*` leaves are structurally *identical* (both nameless,
  both without `Traits`) yet display "Bandit" and "Bandit Outlaw" respectively — so the chain is
  walked; but naming `EncBandit01TemplateMelee` (the exact record `EncBandit02TemplateMelee` uses for
  "Bandit Outlaw") changed nothing in game — so it is not walked the way that implies. Ruled out:
  stale deploy (byte-identical), load order (`Ehlnofey.esp` loads last), and the record not being
  written (read back out of the built binary).
  **Naming all 44 `EncBandit01*` records (templates and every leaf) failed in game too** — still
  "Bandit". The rename was reverted on 2026-09-24 and `author-names.ps1` deleted; the level-1 rung is
  now dropped from the roster instead. **Do not attempt another display-name change on a leveled
  rung without first finding, in game, which record the nameplate actually reads.**
  ⚠️ **This undermines `design/archetype-tiers.md` §3.1.1's premise**, which asserts that all rungs of
  `LCharBanditBoss` display "Bandit Chief" because the name falls through to `LvlBanditBoss` 03DF17.
  That was never observed on a nameplate, only inferred from the same broken model. Pinning the chief
  to one level is still a fine design call, but **its stated justification is unverified** — check it
  in game before relying on it for the four open boss families.
- **NPC level is a discriminated union at `Configuration.Level`**, tagged by `MutagenObjectType`:
  `NpcLevel` (field `Level:`) or `PcLevelMult` (field `LevelMult:`, with `CalcMinLevel` /
  `CalcMaxLevel` as siblings on `Configuration`). Those are the confirmed Spriggit names. `[verified]`
- **`grep -rl` across `reference/` times out (>2 min).** Match on *filenames* instead: Spriggit names
  every file `<EditorID> - <FormID>_<master>.yaml`, so `ls Npcs | grep 039D26` resolves a FormKey
  instantly. For anything bigger, build a `FormID → EditorID → type` index from filenames once and
  join against it. `[verified]`
- **Never compare a hex FormID numerically in `awk`.** `awk -v i="02E893" '$1==i'` matches *eight*
  rows, because a `-v` value is a strnum: `02E893` parses as `2×10^893` → `+inf`, and every
  similarly-shaped FormID (`02E894`, `04E852`, …) is also `+inf`. Truncation is just as bad —
  `0130DB` numifies to `130`, colliding with the whole `0130xx` keyword block. Force string context
  with `$1""==i""`, or use FormIDs only as **array subscripts** (always strings). `[verified]`
- **Never census a field with `grep -c` — count records, not lines.** `grep -c 'LevelModifier:'` over
  `Cells/` returns 2,739 where the true `PlacedNpc` count is 2,524, because 215 `PlacedObject`
  *markers* (`PatrolIdleMarker`, `XMarker`, `GuardMarker`, …) carry the field inertly. Fields recur
  across record types; always parse to the record and filter by `MutagenObjectType`. `[verified]`
- **EditorIDs are not a reliable search key for a named set.** Only four of Skyrim's eight named
  Dragon Priests have "Priest" in their EditorID, and Vokun's is `Ianusu`. When enumerating a named
  group, match on the English `Name:` string; use EditorIDs only once you have the FormKeys.
  `[verified]`
- **~~DLC plugins have no display names in the decompile.~~ They do now, and the old decompile
  shipped a bug.** The DLC decompiles `reference/Base/` held until 2026-09-23 serialized `Name:` with
  **no `Values:` block**. Any DLC `NPC_` copied from them came out as `Value: ''` after a round-trip,
  and an override with an empty `FULL` **blanks the NPC's name in game**. The proof of concept shipped
  124 such records, including Serana, Isran, Neloth, Frea and Teldryn Sero (fixed 2026-09-25, WD-42).
  The current decompile **does** carry the strings. **After any round-trip, grep
  `Npcs/` for `Value: ''` under `Name:`**, because a blank name is silent. For other *record types*
  (and older copies of `reference/`), still identify DLC records by EditorID and FormKey rather than
  trusting `Name:`. `[verified]`
- **Resolve FormKeys by master, not by bare FormID.** A six-hex FormID is only unique *within* a
  plugin: `01A345:Dawnguard.esm` (Harkon's combat style) collides with an unrelated `Skyrim.esm`
  leveled-NPC record. A lookup that searches the base-game index first will silently return the wrong
  record with a plausible name. Always key on `<hex>:<master>`. `[verified]`
- **Never cache a derived index behind an `if [ ! -f ]` guard.** A stale `index_<dlc>.tsv` built by an
  earlier script with a shorter record-type list silently returned empty for `Classes` and
  `CombatStyles`, which reads identically to "this record has no class". Rebuild derived indexes, or
  version them by the list they were built from. `[verified]`
- **Placed records nest at different indentations.** In `Cells/` a placed ref opens at column 0
  (`- MutagenObjectType: PlacedNpc`); in `Worldspaces/` it is indented two more spaces, and the block
  itself contains inner `- MutagenObjectType: ScriptObjectProperty` entries. A parser anchored on
  column 0, or one that treats any nested `MutagenObjectType` as a record boundary, **silently drops
  records** — that mistake undercounted placed NPCs by half (5,169 vs the true 10,504). Track the
  opening line's indent and close the record only at the same or lesser indent. `[verified]`

- **`GMST` records can be *added*, not only overridden.** Skyrim has game settings that exist as
  hardcoded engine defaults with no record in `Skyrim.esm`; creating one makes it editable. There is,
  for example, no `fSmithingArmorMax` / `fSmithingWeaponMax` record in the base game at all, yet other
  mods add them as new records. So "absent from `reference/Base`" does
  not mean "not tunable". `[verified]`
- **A base+DLC index has duplicate keys; last-wins is the correct rule.** Concatenating
  `01Skyrim` … `05Dragonborn` into one `FormID_master → data` index produces **135 duplicate keys**
  for NPCs, because `Update.esm` and the DLC re-override base records under the *same*
  `<hex>:Skyrim.esm` FormKey. Only one (`072B04` Vald) actually disagrees on level type, but a
  naive `if (!(k in a))` first-wins load silently uses the *pre-Update* value. Load in load order
  and let later assignments overwrite — that reproduces the winning record, which is the baseline
  you almost always want. `[verified]`
- **Comparing a mod against vanilla means comparing against the *winning* vanilla record**, and the
  join key must be `<hex>_<master>`, never bare hex — see the "resolve FormKeys by master" gotcha
  above. `[verified]`

  `[verified]`
- **Overriding a vanilla `NPC_` in a non-localized `.esp` collapses its name to one language.**
  `Skyrim.esm` records serialize a multi-language `Values:` block (the STRINGS table); an `.esp`
  without one stores a single `Value:`, so Spriggit picks English and the other eight are gone. This
  hit every base-game NPC the proof of concept overrode. It is unavoidable without shipping `.STRINGS`
  — dropping `Name:` is *not* the fix, because a Skyrim override replaces the record wholesale and an
  NPC with no `FULL` has no name at all. Accept it, or ship a localized plugin. `[verified]`
- **A PowerShell function returning `,@(...)` breaks `foreach`, even though it fixes `.Count`.** The
  comma-wrap is needed so a 0- or 1-element result keeps `.Count`, but `foreach ($x in Get-Thing)`
  then iterates **once with `$x = @()`** instead of zero times — which reads as a phantom result, not
  an error. Assign to a variable first and check `.Count` before enumerating. `[verified]`

- **Scripts can edit a leveled list at runtime, invisibly to every load-order scan.** A Papyrus
  `LeveledActor.AddForm` / `LeveledItem.AddForm` never appears as an override in any plugin, and the
  result is stored in the save for good. The 15 Creation Club Bandit Armor packs do exactly this from a
  `RunOnce` start-up quest fired after chargen (`ccstartafterchargenscript`): they add their own
  `SubCharBandit0NBoss` to `LCharBanditBoss` at gates 2–48 and their armor to ~15 `LItemArmor*` lists.
  Symptom: bandit chiefs came out level 6 when the player walked in, but 28 via `coc` from the main menu
  (no chargen, so no injection) and via `placeatme` (no `LevelModifier`). **Before concluding a list
  is what the plugin says, grep `reference/` quest/script properties for its FormKey**, and read the
  levels from the fragment `.pex` (the CC packs ship no `.psc`). `[verified]` in game, 2026-09-23.
  **Vanilla does it too:** `DLC2Init` (Dragonborn) injects into 23 bandit gear lists and a draugr list;
  its fragment is `scripts\dlc2_qf_dlc2_mq04_02016e02.pex` in `Skyrim - Misc.bsa`. Scan for these with
  an awk over `Quests/*.yaml` for `Script*Property` names matching `^(DLC[12])?L(Char|[Ii]tem)`.
  Two traps when reading them: a property block sits at 4-space indent on a quest script but **6 on an
  alias script** (the fish pack), so read the indent rather than assume it; and an injection at level 1
  can still be a leak when **what it injects is itself a gated sublist** (the gauntlet pack) — check
  the injected form's own gates.
- **Overriding anything in an exterior cell means overriding the whole worldspace record.** In the
  plugin format an exterior `CELL` sits inside its `WRLD` group, so moving even one placed ref outside
  Bilegulch Mine drags in a full copy of **Tamriel** `00003C` — climate, water, map data, LOD settings,
  `OffsetData` and a `LargeReferences` table (~337k YAML lines in `reference/Base/01Skyrim`), copied from
  the winning master (Dragonborn; Update, Dawnguard and Hearthfire also override it). Loading last,
  Ehlnofey would then win over every weather/water/map/LOD mod that edits Tamriel. Interior cells carry
  no such cost. Prefer retargeting a base record that only that place uses. `[verified]` 2026-09-25.
- **`VeryHard` + a single-entry flattened list = always the next entry up.** The bump rule ("if the
  VeryHard pick equals the Hard pick, take the next-higher entry regardless of level",
  `design/engine-behaviour.md` §4) is harmless while a pinned list has one entry, but the moment
  anything adds more entries the bump walks up them regardless of gate. In a min-6 zone Hard (6) and
  VeryHard (≈7) both picked steel's gate-6 entry, so the bump took **silver at gate 10** — above the
  lookup level — and the chief wore silver, level 6. A flattened list is only as pinned as the thing
  that stops others adding to it. `[verified]` in game (silver-armored level-6 chief), 2026-09-23.
- **Prove a generator refactor by diffing its *raw* output before and after** (two runs from a clean
  checkout), not against the committed tree. The committed tree has been through a Spriggit round-trip,
  so it differs from fresh generator output in field order and collapsed strings. `[verified]` 2026-09-25.
- **PowerShell variable names are case-insensitive.** `$S` (a scratch path) and a loop's `foreach ($s in …)`
  are the *same variable*: the loop silently overwrote the path, and Spriggit wrote its output into a
  folder named after the last loop item in the repo root. Use distinct names. `[verified]` 2026-09-25.
- **Grep a list's users before calling it shared or live — its name proves neither.** In WD-43,
  `LItemWeaponDaggerBoss` was reported as shared with other factions' bosses, from the name alone. It is used
  only by the Forsworn shaman Briarhearts, and the user's decision was made on the wrong premise until play
  forced a recheck. The same grep found four `LItemForsworn*` weapon lists that **nothing references**.
  Editing those would have been a no-op. The command is in `design/faction-playbook.md` §4. `[verified]`
  2026-09-26.
- **A faction list that points into a game-wide "All" list inherits our own CC re-adds.** `LItemArrowsAll`
  carries the Exotic Arrows vendor sublist (the proof of concept re-added it at level 1). So the Forsworn's
  15% bonus arrow roll `LootForswornArrows15`, which pointed there, handed archers CC fire and ice arrows.
  When play shows an out-of-place item, walk the faction's loot and arrow lists to their leaves before
  suspecting a runtime injector. Fix by repointing the faction's list, not by editing the shared one.
  `[verified]` in game 2026-09-26.
- **An edited gear list can end up with no weapon.** Stripping or repointing entries can leave a faction's
  weapon list empty; the NPC then spawns unarmed and fights with fists, and nothing warns you. In the proof of
  concept, Imperial soldiers and guards, Thalmor archers, Penitus archers and Dawnguard mooks (war axe) were all
  hit. After editing a faction's gear, walk each outfit to its leaves and check a weapon is still there.
  `[verified]` in game 2026-09-26.
- **A level written on a record that takes `Stats` from a template is inert.** The nine
  `EncGuardImperialM0x` guards were given level 25 and still scaled 20–50 in game through
  `EncGuardImperialTemplate`. Before claiming an NPC is fixed, find the level **owner**: follow `Stats` templates
  through `LVLN` entries to a record without the flag. `[verified]` from the records, 2026-09-26.
- **In the decompile, match the string `- Language: English`, not `Language: English`.** The latter hits
  `TargetLanguage: English` on the line above first, and a name parse silently returns the wrong field.
  `[verified]` 2026-09-25.

## Faction ledgers

A reader-facing page per finished faction, in one shared style. Each faction ticket ends with one
(`design/faction-playbook.md` §9). Private artifacts; share from the page's own menu. **The pages
below describe the proof of concept.** Their levels and rosters are the decisions `archetype-tiers.md`
carries into the rebuild, but where they mention Requiem or the extract, that is POC history.

| Faction | Ticket | Page |
|---|---|---|
| Bandits + hostile Orc camps | WD-2x (pre-Jira) | https://claude.ai/artifact/C3vSs31Kiejw2TDTxNwLSH |
| Forsworn | WD-43 | https://claude.ai/artifact/Xff2Gm6AbjxaRoyoZXAvTv |
| Hold guards + civil-war soldiers | WD-44 / WD-45 | https://claude.ai/artifact/2g11MaAwsx2MJ5ybrXqoGd |
| Warlocks, necromancers, conjurers + witches / hags | WD-46 | https://claude.ai/artifact/WhSB5WhDyXASBzhFXQYkTi |
| Vampires + thralls | WD-47 | https://claude.ai/artifact/3eUAuGTto4q1dyxZWXPXmA |
| Thalmor | WD-48 | https://claude.ai/artifact/35EZVm54hQ5fFC25A7Qa5t |
| Wildlife & monsters + CC bonewolf | WD-54 | https://claude.ai/artifact/S7sQbvsHBKNVF21tsUAche |
| Dremora & atronachs | WD-52 | https://claude.ai/artifact/FZrcU1aZLGgqj9aFQkfPiW |
| Draugr & dragon priests | WD-49 | https://claude.ai/artifact/Jkxn5D8LCUjtrZrwfrYKVE |
| Falmer & chaurus | WD-50 | https://claude.ai/artifact/V2nSnDTicPohnWL8mFaUNV |
| Dwemer automatons | WD-51 | https://claude.ai/artifact/QFHj364NWKsoEEi5z7nwT6 |
| Dragons + named dragons | WD-53 | https://claude.ai/artifact/So9JXyEDcgMKekkH3R9XLz |
| Werewolves, Silver Hand, werebears | WD-55 | https://claude.ai/artifact/9DTPyW1iNoyTCN4CMJJbFa#wd55 |
| Penitus, Vigilants, ghosts, Alik'r | WD-56 | https://claude.ai/artifact/9DTPyW1iNoyTCN4CMJJbFa#wd56 |
| World encounters + assassins | WD-57 | https://claude.ai/artifact/9DTPyW1iNoyTCN4CMJJbFa#wd57 |
| Dawnguard DLC families | WD-58 | https://claude.ai/artifact/9DTPyW1iNoyTCN4CMJJbFa#wd58 |
| Dragonborn DLC families | WD-59 | https://claude.ai/artifact/9DTPyW1iNoyTCN4CMJJbFa#wd59 |
| Followers | WD-61 | https://claude.ai/artifact/7kUzRSazGQdcZYztMC3a3d |
| Named bosses, questline finals, the long tail | WD-62 | https://claude.ai/artifact/Bdv77DbCBrLru5zppmmc9K |

Candidates still to confirm:

- **Do not assume the DLC follow the base game's structure.** Three traps, all `[verified]`:
  **(a)** Solstheim is a **tenth `LocTypeHold`** — a hold-keyed rule written against `Skyrim.esm`
  silently excludes it. **(b)** **9 of Dawnguard's 19 encounter zones have no `Location:` field**
  (vs 270 of 280 in vanilla), so anything walking `ECZN.Location → LCTN → keywords` misses the Soul
  Cairn, Darkfall, Castle Volkihar and most of the Forgotten Vale. **(c)** Dawnguard's new-world
  locations and *all* of Apocrypha carry **no keywords at all** — invisible to both hold-keyed and
  type-keyed rules. Always test a rule against the DLC separately, never by extrapolation.
- **Hearthfire adds no worldspace, no region and no dungeon** — 22 locations and 141 factions of
  homestead bookkeeping. It is out of scope for world design; adding it as a master buys nothing.
  `[verified]`
- **Override volume vs. Spriggit.** A deleveling pass can generate thousands of override YAML files.
  Watch repo size, round-trip time and `Test-RecordYaml.ps1` runtime before committing to option A.
- **Deleveling levels without deleveling capability** produces a world that is fixed and dull.
  Threat is perks, spells and combat style as much as level.
- **A clean build proves nothing about balance.** Phase 4 is not done at "deserializes clean" — it is
  done when a character has actually walked into a zone and been correctly killed by it.
