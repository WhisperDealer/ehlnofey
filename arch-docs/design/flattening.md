# Flattening the leveled lists — Phase 4 architecture

**Status: LIVE (2026-09-27).** This is the architecture the rebuild of `Ehlnofey.esp` follows. It
replaces the extract-based build now archived as `proof-of-concept.md`; the method is the same, but
every record is authored here, from vanilla, with no third-party plugin as an input.

Read first: `archetype-tiers.md` (what every family is fixed at — the spec this method executes),
`probe-test-protocol.md` §§5–6 (what we measured in game), `implementation-strategy.md` §6 (the
overworld census).

---

## 1. The method

> **Delevel by flattening the leveled lists.** Every leveled list keeps its pool of variants but
> loses its player-level gates, so it becomes a fixed, weighted draw. Every actor that scales with the
> player gets a fixed level. Difficulty becomes a property of the **archetype**, fixed once and
> legible from its name.

| Layer | Move | Scales with player? |
|---|---|---|
| **Actors** — who spawns | flatten every gated `LVLN` to a fixed roster (`archetype-tiers.md`) | **no** — anywhere, including the overworld |
| **Worn gear** — what they carry | flatten the `LVLI` an outfit or inventory reaches | **no** |
| **NPC levels** | every `PcLevelMult` → a fixed level, **followers included** | **no** |
| **Container loot** — chests, urns, hoards | **open decision** (§5.4) | — |

Four moves. The fourth layer is the one decision the rebuild still has to take.

---

## 2. Why flatten, and not clamp encounter zones

Phase 3 chose zero-width encounter zones (`implementation-strategy.md` §1). Two measurements killed
that design.

### 2.1 Encounter zones govern 0.3% of the outdoors

`[verified]`, `implementation-strategy.md` §6.1, full scan of the Tamriel worldspace:

| | count |
|---|---|
| Tamriel exterior cell files | 12,148 |
| …carrying an `EncounterZone` | **40 (0.3%)** |
| unzoned leveled actor refs | **3,512** vs 367 zoned |

A zone-first design governs interiors and almost nothing else.

### 2.2 Worn gear scales with the player, and no zone can reach it

The probe separated the two loot tracks and they came back **opposite** `[verified]`:

| Track | Resolves against | Evidence |
|---|---|---|
| **Containers** | **the zone** ✅ | Test 3. Bleak Falls pinned to 4, player 45: vanilla gave a **glass dagger**; with `fSpecialLootMinPCLevelMult = 0` the same chest gave low-tier loot, **identical at player 1 and 45** |
| **NPC-worn gear** | **the player** ❌ | Test 2b. The Swindler's Den chief was **level 28 in both runs** but wore **iron at player 5, Nordic at player 45** |

There is no zone operand anywhere on an outfit's material list (`probe-test-protocol.md` §6.1).
Flattening the list is the only fix. This also kills `loot-model.md` §1's *"no truncation pass
needed"*.

### 2.3 What flattening costs

**Vanilla's dungeon rosters vary by *role*, not by *tier*** `[verified]`: 182 interior cells place
leveled bases, drawn from a vocabulary of 207 that is entirely role-shaped (`Melee1H` · `Missile` ·
`Warlock` · `Boss` · …). All tier information lives in the `LChar*` gate ladder — precisely what
flattening deletes. So Bleak Falls Barrow and Volunruud get the same draugr; they differ in *role
mix*, not in danger. That is the price, paid knowingly.

Buying it back by forking lists per tier means repointing placed references — thousands of `ACHR`
overrides with a heavy conflict surface. **Archetype-level difficulty is not a shortcut, it is the
architecture.**

---

## 3. The job, sized in our own decompile

Base + Dawnguard + Dragonborn. "Real gate" = more than one *distinct* entry `Level` on the record
(count the entries, not the flag). `[verified]`:

| | records | **real-gated** | entries | entries in gated lists |
|---|---|---|---|---|
| `LeveledNpcs` | 681 | **269** | 4,022 | 1,836 |
| `LeveledItems` | 3,824 | **1,756** | 25,438 | 13,325 |

**269 `LVLN` is the actor job in full.** The 1,756 `LVLI` is a ceiling, not a target (§5).

---

## 4. Rules of the method

### 4.1 The tier ladder indexes archetypes, and the lore already wrote it

Vanilla's display names are a lore-ordered power hierarchy (`lore-constraints.md`):

| Family | The ladder vanilla already ships |
|---|---|
| Draugr | Draugr → Restless Draugr → Wight → Scourge → Deathlord |
| Dremora | Churl → Caitiff → Kynval → Kynreeve → Markynaz → Valkynaz |

Under flattening **the name becomes the fact**: a Draugr Scourge is the same level in every barrow,
forever. Bone 2 is served by the enemy's name, which travels with the enemy in a way a zone never did.

**Authoring rule:** every flattened `LVLN` leaf has a level, and it must agree with the display name of
everything in the pool. A band of levels under **one** name is illegible and gets pinned
(`archetype-tiers.md` §3.1.1).

### 4.2 Followers are deleveled too

Bone 1 applies literally: nothing in the world scales, and a companion is in the world. Followers get
hand-set levels by role and lore (`archetype-tiers.md` §6.1). Choosing a follower becomes a decision
with consequences — an early character benefits from a strong companion and later outgrows them.

### 4.3 Three record conventions

| Convention | Use |
|---|---|
| **`Level: 9999`** | disable an entry in place. It stays in the record, so diffs and merges still see it, but it can never roll |
| **`EHL_NULL_` rename** | retire a record without deleting it — deletion breaks every reference |
| **Weighting by duplicate entries** | Skyrim has no weight field. Repeat an entry N times to weight it |

Weighting is **literal entry duplication**, not a `Count` field: `Count` is how many actors one entry
spawns. Flattening costs variety, and weighting is how a flattened bandit pool stays mostly grunts
with the occasional veteran instead of a coin flip.

### 4.4 Find the level's owner before writing a level

A level written on an `NPC_` that takes `Stats` from a template is inert. Follow `Stats` templates —
through `LVLN` entries if need be — to the record without the flag, and write the level there.
See the template-chain gotchas in `arch-docs/gotchas.md`.

---

## 5. Scope — the loot job

### 5.1 Only the lists an actor points at directly

Only `LVLI` reachable from an **outfit or an NPC `Items:` block** leak player level onto actors.
`lvli-reachability.ps1` measures the split `[verified]`:

| gated `LVLI` (1,754 of 3,817) | count |
|---|---|
| reachable from **both** actors and containers | 986 |
| container-only | 410 |
| actor-only | 181 |
| unreached from either root | 177 |

The actor side does not need every *reachable* list rewritten — only the entry points an outfit or
inventory references **directly**; the subtree is fixed once they are flat. **The boundary is 202
lists**: 126 actor-only (flatten in place) and 76 shared with containers.

### 5.2 The 76 shared lists

| Band | Lists | Treatment |
|---|---|---|
| **Gold** — `LootBanditGold`, `LootBanditGoldBoss`, `LootDraugrGold*`, … | 7 | flatten in place |
| **Consumables & sundries** — potions, soul gems, gems, jewelry, … | ~39 | flatten in place; no tier meaning |
| **Material ladders** — `LItemWeaponDagger`, `LItemArmor*`, `LItemArrowsAll`, … | ~30 | the whole gear leak. Flatten or fork depending on §5.4 |

### 5.3 Two subtractions

- **23 overworld lists are already flat** — `LCharSoldierImperial`, `LCharSoldierSons`,
  `LCharAmbientCreatures` among them.
- **Wildlife is already biome-partitioned** (`LCharAnimalForestPredator`, `…MountainSnowPredator`,
  `LCharMudcrab`, …), so flattening in place keeps regional variety for free.

### 5.4 Open decision — containers

Two options, both consistent with the three bones:

| | A. Flatten containers too | B. Keep containers gated, pin the zones |
|---|---|---|
| How | every gated `LVLI` flat; loot quality set by *which list* a chest uses | leave container lists gated; the 355 `Min == Max` zone bands of `difficulty-map.md` §7 fix their level; `fSpecialLootMinPCLevelMult` → 0 |
| Bone 3 | by list (boss chest vs urn) | by place — the dungeon's tier picks the material |
| Material ladders | flatten in place | **fork** ~30: a flat copy for actors, the gated original for chests; repoint ~250 `NPC_` |
| Verified | no | test 3 (boss chest only; ordinary urns unconfirmed) |

The proof of concept built no zones. It flattened most shared lists, so its containers were largely
flat without that being decided, and its boss-chest loot was never verified.

### 5.5 Also in scope

- **Runtime injectors.** Quests that call `LeveledActor.AddForm`/`LeveledItem.AddForm` at start-up
  re-gate lists invisibly (`DLC2Init` and a number of Creation Club packs). They have to be
  neutralised and their content re-added at level 1. The audit of which ones matter is in `arch-docs/gotchas.md`
  (the runtime `AddForm` gotcha) and `proof-of-concept.md` §10.
- **The 177 unreached gated lists** — quest rewards (`LvlQuestReward*`), death items, unique gear.
  Reached from `QUST`, `FLST` and death-item roots the census does not walk. Mostly one-offs where a
  fixed level is the answer; triage them.
- **Constants:** `fSpecialLootMinPCLevelMult` → 0 and the 12 `LevelGate*` globals → 1.
  `fLeveledActorMult*` is inert once actor lists are flat, so it is not overridden.

---

## 6. Order of work

Nothing is copied from `ProofOfConceptESP`: most of it is third-party-derived. Its lessons are in
`proof-of-concept.md` and `arch-docs/gotchas.md`. Generators are new, live in `src/Ehlnofey/`, and read
only `reference/Base/` (and `reference/mods/CreationClubYaml/` for CC masters).

1. **Scaffold** — ✅ done 2026-09-27. Header only, ESL-flagged, four masters; builds clean.
2. **Constants** (§5.5).
3. **Flatten the `LVLN`** — the 269, faction by faction, from `archetype-tiers.md`.
4. **Fix every `PcLevelMult` actor** — find the level owner (§4.4). Finish with a coverage audit:
   zero `PcLevelMult` left in the base game and DLC.
5. **Flatten the actor-reachable `LVLI`** (§5.1–5.2). For every faction, check each gear list still
   holds a weapon after the edit — an emptied weapon list spawns the NPC unarmed, silently.
6. **Take the container decision** (§5.4) and build it.
7. **Neutralise the runtime injectors** (§5.5).
8. **Launch** (guardrail 6). Level-1 character in one barrow, `player.setlevel 40` in a different
   uncleared one: same spawns, same loot tier.

---

## 7. Open risks

1. **Variety collapse.** A flat pool draws uniformly. Weighting (§4.3) is the mitigation; only play
   can say if it is enough.
2. **Deleveling is curation, not an algorithm.** Plan for a long tail of individual NPCs and a
   coverage-audit script, not a clean sweep.
3. **Ordinary containers** (if §5.4 B): zone-bound resolution was verified for the boss-chest roll
   only. Open an ordinary urn in a pinned zone at two player levels.
4. **Name legibility is unverified mechanically.** Nobody here knows how a nameless leveled leaf
   resolves its displayed name (`arch-docs/gotchas.md`). Check pins against the nameplate in game.

## Sources

`design/probe-test-protocol.md` §§4–6 (in-game results) · `design/implementation-strategy.md` §§2,
6 · `design/loot-model.md` §§1–4 · `design/tiers.md` · `design/difficulty-map.md` §7 ·
`design/archetype-tiers.md` · `world/lore-constraints.md` ·
`reference/Base/01Skyrim/Cells/` (§2.3 roster census) ·
`reference/Base/{01Skyrim,02Update,03Dawnguard,05Dragonborn}/{LeveledNpcs,LeveledItems}/` (§3).

---

## Appendix — Phase 3 record (moved from CLAUDE.md, 2026-09-27)

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
