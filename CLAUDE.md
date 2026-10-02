# Ehlnofey — Workspace Guide

> **This file is the most valuable thing in the repo.** A future session reads it instead of
> re-deriving the conventions, so keep it to what every session needs. Detail lives in `arch-docs/`:
> gotchas in full in **`arch-docs/gotchas.md`**, the architecture in **`arch-docs/design/flattening.md`**.
> When you learn something the hard way, add it to `gotchas.md`, and add a one-liner here only if a
> session must know it before touching records.

## What this is

**Ehlnofey** is a **deleveling overhaul for SkyrimSE**: it replaces vanilla's player-level scaling with
fixed, hand-set rules, so difficulty and reward belong to places and creatures, not to the player's level.

The repo is a Spriggit YAML workspace: plugins are decompiled to YAML, edited as text, and re-packed to
`.esp`. **Never hand-edit binary plugins — edit the YAML.** Spriggit `Spriggit.Yaml.Skyrim` 0.40.0.
Serialize/deserialize commands are in `README.md`.

## Tooling

- **All tool paths live in `.claude/config/tools.json`** (gitignored; template `tools.example.json`),
  loaded by `.claude/config/tools.ps1` as `$Tools` with an `Assert-Tool` guard. **Never hardcode a path
  in a skill — change the config.**
- **oculory-rag** (optional MCP): `search` for the knowledge base, `game_search` / `game_read` for the
  decompiled game (records and Papyrus, by EditorID, FormKey or name). Use them before grepping
  `reference/` by hand, pass `game="skyrim"`, and cite the doc id or FormKey.
- **Papyrus:** Ehlnofey has no scripts yet. The toolchain (extract → decompile → compile) is in
  `README.md` and the `bsa-extract` / `pex-decompile` / `papyrus-compile` skills. Record any import
  directory a script needs here the first time it is needed.
- **Testing** in an MO2 modlist: use the `mod-deploy` skill, never copy by hand.

## Folder map

```
src/Ehlnofey/
  EhlnofeyESP/          # THE plugin — Spriggit YAML, committed, source of truth (the rebuild)
  ProofOfConceptESP/    # archived first build — do not copy from it (see Current phase)
  proof-of-concept/     # its generators; they write only into ProofOfConceptESP
build/                  # build.ps1, Test-RecordYaml.ps1, manifest.json (releases EhlnofeyESP)
arch-docs/              # research, design spec, gotchas (map below)
reference/              # gitignored, LOOKUP + BUILD INPUT: Base/ = the five Bethesda masters,
                        #   mods/CreationClubYaml/ = the CC packs
modlist/                # gitignored MO2 instance
```

## Guardrails

Distilled from real failures in this workspace. They cost test cycles to learn.

1. **Ground-truth before claiming.** Never conclude what a record does from its name. Read the
   serialized record, trace the FormKeys, and **show the evidence alongside the verdict**.
2. **Prefer a proven archetype to an invented mechanism.** Read `arch-docs/skyrim-record-patterns.md`
   first. Skyrim fails silently: an inert record costs a full build-deploy-launch cycle to disprove.
3. **Copy records verbatim; never retype hex.** Base a record on a copied file and edit the fields that
   differ. Prefer a script. Re-check array lengths after any edit.
4. **Ask for paths; don't hunt for them.** Read `tools.json` or ask the user.
5. **Verify the deploy target before blaming the records.** Rule out "never loaded" first.
6. **A clean build is not a working mod.** Only launching the game proves it runs. Say which of the
   two you have established.
7. **Recompile and re-commit `.pex` whenever a `.psc` changes.** CI cannot compile Papyrus.
8. **PowerShell 5.1 is the target**: `Set-StrictMode`, no `&&`/`||`, ternary or null-coalescing, no
   YAML parser. Write YAML without a BOM (see gotchas).
9. **Follow the template chain before concluding.** "This NPC is level 6" is a claim about whichever
   record owns the level. Mark confidence `[verified]` / `[community]` / `[unverified]` and never
   silently upgrade a mark.

---

# The mod

## The three bones (design rules)

The name is the thesis: the Ehlnofey were et'Ada who bound themselves into Nirn as its fixed laws, the
Earth Bones. Ehlnofey re-imprints static rules onto a world that bends to the player. Every decision
answers to these; a violation needs an explicit exception recorded in `arch-docs/design/`.

1. **The world does not scale.** Difficulty and reward are set once, on a place or a creature.
2. **Danger is legible.** A fixed world is only fair if it can be read. **This is the load-bearing
   bone**: vanilla gates content by level almost nowhere (`progression.md`), so legibility is the
   player's only protection. The mechanism is vanilla's **tier display names** (Draugr → Restless
   Draugr → Wight → Scourge → Deathlord). Keeping name aligned with power is a hard constraint
   (`lore-constraints.md`).
3. **Reward follows place, not level.** Good loot exists because of *where* it is.

**Non-goals:** not a combat, perk, survival or new-content mod. Ehlnofey changes *where the numbers come
from*, and nothing else.

## Current phase

**Back in design as of 2026-09-30: the enemy census.** Phase 4 (the rebuild, restarted 2026-09-27)
is **paused**. Before any more records are authored, we map every enemy and document it.

- **Scope, per enemy:** its **level** (and which record owns it; follow the template chain), its
  **gear** (outfit, inventory, death item, walked to the leaves), and every **leveled list** it
  resolves through (`LVLN` and `LVLI`, with entries, levels, counts and gate flags).
- **Perks are out of scope for now.** They may join the census in a later update; don't document them
  unless the user asks.
- **Document, don't author.** This phase writes no records in `EhlnofeyESP`. Record what vanilla
  (plus DLC and the CC masters) actually does, with FormKeys and confidence marks (Guardrails 1 and 9).
  Design changes that fall out of it go into `archetype-tiers.md` once the user decides them.
  **Census pages hold vanilla data only** (user, 2026-09-30): no Ehlnofey levels, rosters or weights
  until the census is done. Where a page had them, the version message names the version that holds them.
  **Page layout** (user, 2026-09-30; the Mudcrab page is the model): no source line (the group
  page cites the ticket), just three headed tables and **no prose**:
  1. **Records**: Record · Name · Level, one row per *distinct* enemy. Variants that inherit their
     level are dropped, not described.
  2. **Lists that draw them**: List · Draws · Owner.
  3. **Placed only**: Name · Placed in (cell EditorID + FormKey, plus the quest alias if a quest owns
     it), for every enemy no list draws; an unused record goes here as "not placed".
  No gear, AI, faction or notes sections unless the user asks. Keep the survey notes in an earlier page
  version and name it in the version message. **Armed enemies get gear** (user, 2026-10-01; Common
  Falmer is the model): a **Gear** table (Records · Weapons · Armor · Skin), **Gear lists** (each
  weapon/outfit list walked to its leaves) and **Gear items** (whether the player can wear each one;
  skins are `NonPlayable`).
- **The census lives in Confluence, not in the repo.** Space *WhisperDealer*
  (`~71202046a32e88a7ba474cbdae20a1db1fba60`), root page **Ehlnofey** (id `12451841`), on
  `whisperdealer.atlassian.net` through the `atlassian` MCP. The tree is **root → one group page per
  Jira ticket → one child page per family**. **Factions** (user, 2026-10-02) is a top-level page
  that holds the faction groups: Forsworn, Dawnguard, Vigilants, Companions, Silver Hand, Minor
  Factions and Thalmor. The groups so far: Thalmor (WD-81, under Factions: *Common Thalmor* (the
  soldier, archer and wizard ladders, Justiciars, Northwatch, the Embassy, Solstheim, CC soldiers),
  *Thalmor Boss* (the boss wizard ladder, the Northwatch Interrogator, Agent Lorcalin), *Named Thalmor*
  (Captain Valmir included: an undercover agent, by the user's call)), Automatons (WD-80: *Dwarven Spider*, *Dwarven Sphere*, *Dwarven
  Centurion*, *Dwarven Ballista*, *Unique Automatons* (the Forgemaster, CC The Messenger and The Sky
  Orchestrator); the Aetherial Staff summons stay on Conjured, the CC Sanctuary constructs are
  `PlayerFaction` allies), World Creatures (WD-65; one level deeper, under
  sub-group pages **Animals**, **Aquatic**, **Beasts**, **Insectoids**, **Sentient** (giants, goblins,
  wisp mothers, spriggans, hagravens, rieklings), **Monsters** (trolls, ice wraiths, magic anomalies, gargoyles)
  and **Mounts** (horses, unicorns, reindeer, and *Otherworldly Horses*: Arvak and the Daedric
  Horses, summoned mounts included by the user's choice); there is no Forgotten Vale page, its creatures are on
  their families' pages),
  Falmer (WD-66: chaurus, Frozen Chaurus and chaurus hunters live under World Creatures → Insectoids;
  *Snow Elves* holds Vyrthur and Gelebor),
  Forsworn (WD-67: *Common Forsworn*, *Forsworn Briarheart*, *Named Forsworn* (the Cidhna Mine
  prisoners, the MS01 Markarth agents, CC Crowstooth and Alvasorr); the hagravens live under World
  Creatures → Sentient, the Forsworn dog on *Dog*), Werebeasts (WD-68:
  *Werewolf* (the six-rung ladder), *Werewolf Boss* (the boss ladder, Sinding, Arnbjorn), *Werebear*
  (the Solstheim werebears, Torkild), *Wolf Spirits*; the Beast Stone werebear is on Conjured),
  Rieklings (WD-69: no group page; under World Creatures → Sentient),
  Daedra (WD-70: *Dremora* (the six-rung ladder, the one-offs, The Cause's and Arms of Chaos's
  Dremora), *Seeker*, *Lurker*, *Golden Saints & Dark Seducers* (Saints & Seducers; the hostile ones
  are the AtrForge copies its quest spawns) and *Barbas*; **atronachs are out of the census** (user,
  2026-10-02); the Dremora Butler and Merchant and the Daedric Princes are not enemies), Creation Club creatures (WD-71: no group page; each is on its kind's page under
  World Creatures), Vampires (WD-72, a sub-group under Undead since 2026-10-02: *Common Vampires*, *Vampire Boss*, *Vampire Lord* (Harkon, plus Serana and Valerica by the user's call),
  *Volkihar Court*, *Vampire's Thrall*, *Death Hound*; *Gargoyle* moved to World Creatures → Monsters;
  thralls take bandit levels and gear;
  the Bloodchill Manor CC vampires are on *Common Vampires* and *Vampire Boss*),
  Dawnguard (WD-76: *Common Dawnguard* (the six-rung ladder, every rung named "Dawnguard"),
  *Dawnguard Members* (Isran and the named members), *Husky*), Vigilants (WD-77: *Common Vigilants*
  (the five-rung ladder, The Cause's Vigil Enforcers) and *Named Vigilants* (Carcette, Tyranus, Tolan,
  Adalvald, the Vigil Enforcer pack's two); vampiric Vigilants stay under Vampires), Companions
  (WD-78: *The Circle* (Kodlak, Skjor, Aela, Farkas, Vilkas) and *Companions Members*; their
  werewolf forms are scripted race changes with no record; the wolf spirits stay under Werebeasts),
  Silver Hand (WD-79, its own group under Factions: *Common Silver Hand* and *Silver Hand Leaders*:
  wrappers that take only `Stats` from the bandit lists; Krev and the radiant camp leader are
  alias-named), Minor Factions (WD-79: single family pages **Alik'r** (the `LCharAlikr*` ladder is
  unused; the real Alik'r are `MS08`/`WERJ03` records plus the Lord's Mail CC ones, and the Redguard Elite Armaments Remnant Warriors, allies, by the user's call), **Penitus Oculatus**
  and **Morag Tong** (Dragonborn; takes `Stats` from the Reaver ladder; the Severins join by script)), Undead (WD-73: draugr included,
  **Vampires** a sub-group (above); **Draugr** is a sub-group page with *Common Draugr*, *Draugr Warlock* and *Draugr Boss*,
  the Falmer layout; **Skeletons** likewise, with *Common Skeletons*, *Soul Cairn Undead*, *Shades* and
  *Bone Wolves (CC)*, and **Ghosts**, with *Common Ghosts*, *Ghost Bosses* and *Spectral Warhound*;
  Karstaag stays on Giant; **Ash** is a sub-group with *Ash Spawn*, *Ash Guardian* and *Ash Zombie (CC)*, undead by the
  user's call, 2026-10-01, although none of their races carries `ActorTypeUndead` and the Ash Guardian's
  carries `ActorTypeDaedra`; their summons are on Conjured → *Undead Summons*), Conjured (WD-74: anything that exists only as a summon; a placed version stays with its
  family; sub-groups **Summoned Creatures** (*Summoned Atronachs*, *Familiars & Spirit Animals*,
  *Undead Summons*, *Daedric Summons*, *Constructs & Dragons*) and **Summoned NPCs** (*Summoned
  Dremora*, *Heroes & Spirits*), each page with a "Summoned by" table: player source and NPC casters), Uncategorised (WD-75: the holding group for anything that fits no group yet; CC enemies
  in it go one level deeper, under its **Creation Club** page, one child per pack; *Forsworn Level
  Borrowers* holds the non-Forsworn enemies that take `Stats` from a Forsworn list: Sanctuary
  Guardians, Champion of Boethiah, Silvia, Moric Sidrey, to be filed later). CC creatures
  are filed by kind, not by pack: CC Daedra under Daedra, CC undead under Undead, CC creatures on
  (or beside) their vanilla family's page under World Creatures (Frenzied Mudcrabs on Mudcrab,
  Fangtusk on Horker, Corrupted Spriggans on Spriggan). **Confluence titles are unique per space**, so a group and a family
  cannot share a name (the family pages are *Common Falmer* and *Common Forsworn*). The MCP has no delete: retire a
  page by retitling it `DELETE ME - <title>` and ask the user to delete it.
  A new family follows the same
  shape: a group page citing its ticket and spec section, and a child page per family. Search the tree
  (`ancestor = 12451841`) before creating a page, and update the existing page rather than duplicating it.
- **Start from what exists:** the Confluence pages, `world/enemy-taxonomy.md`,
  `world/unique-enemies.md`, the census scripts in `design/*.ps1` and `archetype-tiers.md` already cover
  much of the ground. Extend them; don't re-derive.

The rebuild resumes from the plan below once the census is done:

- **Architecture: `arch-docs/design/flattening.md` — read it first.** Its §6 is the order of work.
- **Spec: `arch-docs/design/archetype-tiers.md`** — every family's levels, rosters, weights, pins and
  gear, decided by the user faction by faction (Jira WD-43…64).
- **Method — *flattening the leveled lists*:** strip the player-level gates from every `LVLN`/`LVLI`
  while keeping the pool, weight the pool by duplicate entries, and give every `PcLevelMult` actor a
  fixed level, followers included.
- **Rule of the rebuild: every record is authored here, from vanilla.** Inputs are `reference/Base/`,
  `reference/mods/CreationClubYaml/` (only for CC plugins taken as masters) and the design docs. **No
  third-party mod's records are an input, and nothing is copied from `ProofOfConceptESP`.** Generators
  for the rebuild live in `src/Ehlnofey/`.

**Status:** scaffold only — a header (ESL; Skyrim, Update, Dawnguard, Dragonborn) that builds clean. No
records yet. **Next:** the enemy census (above). After it, the constants, then the `LVLN`
(`flattening.md` §6 steps 2–3).

**Decisions carried over from the proof of concept** (user; revisit if they no longer fit):
- **Creation Club is a hard requirement** (AE is near-universal). CC packs whose start-up quests
  re-gate our lists become masters so those injectors can be neutralised.
- **Rung levels are vanilla's**; a fixed vanilla level is kept. Only `PcLevelMult` actors get a new one.
- **Illegible boss bands are pinned**, one level per displayed name.
- **Dragon gear is craft-only** (WD-63).
- **No SkyPatcher, no Synthesis.** The mod is one plugin.

**The proof of concept** (`ProofOfConceptESP`, 3,013 records) was extracted from a third-party
deleveling mod and hand-tuned per faction. It proved the method in play, but it is a derivative work: not
released, not publishable. **Before starting a faction, read `design/proof-of-concept.md` §10** — the log of
what it shipped and what play found. Nearly every bug it hit is a trap the rebuild can walk into again.

## Conventions

- **Plugin:** `Ehlnofey.esp`, ESL-flagged. Add a master only when a record needs it, and record why
  here. Expect `HearthFires.esm` and several CC plugins once the injectors are neutralised (the proof of
  concept ended with 31; its list is in `ProofOfConceptESP/RecordData.yaml`). Keep CC masters in
  `Skyrim.ccc` order.
- **EditorIDs:** `EHL_<domain>_<specific>`, e.g. `EHL_LVLI_DraugrBossHoard`.
- **Overrides keep the original master's suffix** (`09BC43:Skyrim.esm`); new records use
  `<hex>:Ehlnofey.esp`.
- **New FormIDs:** ESL range `0x800–0xFFF` (confirm with the user before exceeding). One contiguous
  block per feature, recorded below. Run `/formkey-check` first. It will report `0x800`–`0x805` as
  taken by `ProofOfConceptESP`, which shares the ModKey. That is not a real collision: the two are never
  loaded together.

| Block | Feature | Records |
|---|---|---|
| — | none claimed yet | |

**Next free: `0x800`.**

## Gotchas you must know before authoring

The full entries, with evidence, are in **`arch-docs/gotchas.md`**. These are the ones that bite:

- **Absent field = default value**, not "unset": a `Level:`-less `NpcLevel` is level 0.
- **Find the level's owner.** If an NPC lists `Stats` in `TemplateFlags`, its own level is inert.
  Follow templates, through `LVLN` entries if need be, to the record without the flag.
- **NPC level** is `Configuration.Level`: `NpcLevel` (`Level:`) or `PcLevelMult` (`LevelMult:`, with
  `CalcMinLevel`/`CalcMaxLevel` beside it).
- **The displayed name follows the `BaseData` template flag, not `Traits`** (2026-10-01; explains the
  failed bandit rename, not yet confirmed by an in-game edit). A record with `BaseData` set shows its
  template's name. Until tested in game, still name every record of a rung when authoring.
- **A quest alias `DisplayName` can name a nameless boss** (Movarth, Vighar, Lokil): grep quest
  aliases for the placed ref's FormKey, not just the base record's.
- **Runtime injectors:** start-up quests (`DLC2Init`, several CC packs) call `AddForm` on leveled lists.
  This is invisible to load-order scans and stored in the save for good. Grep quest properties for a
  list's FormKey before trusting it.
- **Edited gear can leave a faction unarmed**, silently. Walk each outfit to its leaves after an edit.
- **A game-wide "All" list inherits everything added to it.** A faction list pointing there leaks.
- **Grep a list's users before calling it shared or live.** Its name proves neither.
- **Count entries, not flags:** 55% of `LVLI` carrying the gate flag are flat pools.
- **Resolve FormKeys by master** (`<hex>:<master>`), never bare hex; load base + DLC last-wins.
- **After a round-trip, grep `Npcs/` for `Value: ''` under `Name:`.** A blank name blanks the NPC in game.
- **Round-trip hygiene:** after authoring, deserialize → re-serialize → adopt Spriggit's output
  (field order differs from hand order). Compare with `diff -r --strip-trailing-cr`. Write YAML with
  `UTF8Encoding($false)` (no BOM), and resolve absolute paths before `[System.IO.File]`.
- **Never override an exterior cell.** It drags in the whole Tamriel worldspace record.
- **`grep -rl` / `ls */` over `reference/` time out.** Match filenames in one named directory.

## arch-docs map

```
arch-docs/
  gotchas.md                  # every gotcha in full + research rules + FOMOD/workspace recipes
  skyrim-record-patterns.md   # read before authoring any mechanic
  world/                      # Phase 1 research — overview.md first; enemy-taxonomy, unique-enemies,
                              #   factions, dungeons, regions, progression, lore-constraints
  design/
    flattening.md             # READ FIRST — the live architecture; §6 order of work
    archetype-tiers.md        # THE SPEC — levels, rosters, weights, pins, gear per family
    faction-playbook.md       # read before any faction: survey → rungs → gear → users → injectors
    scaling-machinery.md      # the vanilla levers + useful FormKey constants
    proof-of-concept.md       # ARCHIVED first build; §10 its log, §11 the faction ledger pages
    engine-behaviour.md       # the five engine questions, answered with sources
    probe-test-protocol.md    # the in-game probe tests and their results
    tiers.md · difficulty-map.md (+ build-difficulty-map.py) · loot-model.md
                              # Phase 3 spec: T1–T7 ladder, the 355 zone assignments, loot model
    implementation-strategy.md  # Phase 3 zone-first hybrid, SUPERSEDED; §6 overworld census still cited
    *.ps1                     # census scripts behind flattening.md §5 and archetype-tiers.md §4.1
```
