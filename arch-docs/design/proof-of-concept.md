# The proof of concept — archived Phase 4 architecture

> **ARCHIVED 2026-09-27.** This was the architecture of the first build, now at
> `src/Ehlnofey/ProofOfConceptESP/` (generators in `src/Ehlnofey/proof-of-concept/`). It extracted
> its flat lists and level grafts from the Requiem mod, so it is a derivative work and is not
> released. The rebuild follows **`flattening.md`**, which takes the same method and authors every
> record from vanilla. Links into `prior-art/` below are dead: that folder was deleted on 2026-09-27.
> Paths to the generators predate their move into `proof-of-concept/`.
>
> Kept for two things: the evidence in §§2–5, which `flattening.md` summarises, and §10, the record
> of what the build shipped and what play found — read it before starting a faction.

**Original status: DECIDED (2026-07-29), on branch `design/requiem-method`.** This superseded
`implementation-strategy.md` §1's zone-first hybrid.

Read first: `prior-art/requiem/plugin-analysis.md` (what Requiem actually does),
`probe-test-protocol.md` §§5–6 (what we measured in-game), `implementation-strategy.md` §6 (the
overworld census).

---

## 1. The decision

> **Delevel by flattening the leveled lists, as Requiem does — not by clamping encounter zones.**
> Difficulty becomes a property of the **archetype**, fixed once and legible from its name.
> Encounter zones survive in one role only: **container loot**, the one thing they are verified to
> govern and the one place bone 3 still lives.

| Layer | Mechanism | Scales with player? |
|---|---|---|
| **Actors** — who spawns | flatten the 269 gated `LVLN` to fixed rosters | **no** — anywhere, including the overworld |
| **Worn gear** — what they carry | truncate/flatten the outfit-reachable `LVLI` | **no** |
| **Container loot** — chests, urns, hoards | **keep vanilla gating + the 355 zone bands** | **no** — verified, zone-bound |
| **NPC levels** | all `PcLevelMult` → fixed, **followers included** | **no** |

Four moves, one exception, and the exception is the twist that keeps the mod's name honest.

---

## 2. Why — the evidence for the pivot

### 2.1 Encounter zones govern 0.3% of the outdoors

`[verified]`, `implementation-strategy.md` §6.1, full scan of the Tamriel worldspace:

| | count |
|---|---|
| Tamriel exterior cell files | 12,148 |
| …carrying an `EncounterZone` | **40 (0.3%)** |
| unzoned leveled actor refs | **3,512** vs 367 zoned |

A zone-first design governs interiors and almost nothing else. The remedy §6 proposed — flatten 65
lists, bolt zones onto 238 cells — is already half Requiem's method. Doing it everywhere is simpler
than doing it in one population and clamping in the other.

### 2.2 Worn gear scales with the player, and no zone can reach it

The probe separated the two loot tracks and they came back **opposite** `[verified]`:

| Track | Resolves against | Evidence |
|---|---|---|
| **Containers** | **the zone** ✅ | Test 3. Bleak Falls pinned to 4, player 45: vanilla arm gave a **glass dagger**; with `fSpecialLootMinPCLevelMult = 0` the same chest gave low-tier loot, **identical at player 1 and 45** |
| **NPC-worn gear** | **the player** ❌ | Test 2b. The Swindler's Den chief was **level 28 in both runs** but wore **iron at player 5, Nordic at player 45** |

There is no zone operand anywhere on an outfit's material list (`probe-test-protocol.md` §6.1,
mechanism traced end to end). Flattening the list is the only fix, and flattening the list is
Requiem's method.

**This kills `loot-model.md` §1's headline** — *"the tier ladder IS the material ladder, no truncation
pass needed"* — and with it the claim that bone 3 falls out of the difficulty map for free.

### 2.3 What the pivot costs, measured on this branch

Stated plainly, because it is real and it was not free. **Vanilla's dungeon rosters vary by *role*,
not by *tier*.** Census of all `Skyrim.esm` interior cells, resolving `PlacedNpc` bases through the
filename index `[verified]`, this branch:

| | |
|---|---|
| interior cells with placed NPCs | 498 |
| …placing leveled bases | 182 |
| distinct leveled bases in the vocabulary | 207 |
| distinct roster-sets across those 182 cells | **172** |

172 near-unique rosters looks like place topography — but the vocabulary says otherwise. The entire
draugr vocabulary is **role-shaped**: `Melee1H` · `Melee2H` · `Missile` · `Warlock` · `Berserker` ·
`Defender` · `Ambush` · `Boss` · male/female · helmet/no-helmet. There is no `LvlDraugrElite`, no
tier axis at all. **All tier information lives in the `LChar*` gate ladder — precisely what
flattening deletes.**

So under this architecture Bleak Falls Barrow and Volunruud get the same draugr. They differ in
*role mix*, not in danger. That is the price, it is paid knowingly, and §4.1–§4.2 are how it is
partly bought back.

### 2.4 Why the price cannot simply be bought back with rules

The obvious rescue is to fork each list per tier and repoint the placed references. SkyPatcher's
`reference/` module looked like the lever. **It is not, and the reason is in its source.**

`reference.cpp:15–19` exposes exactly three keys — `filterByRefs`, `filterByRefsExcluded`,
`replaceBaseObject`, `disable`. The swap is applied from a `Load3DREFR` hook
(`main.cpp:938–977`) `[verified]`:

```cpp
SKSE::GetTaskInterface()->AddTask([a_this, boundobj]() {
    if (a_this) {
        a_this->SetObjectReference(boundobj);
        a_this->Enable(false);          // ← force-enables the reference
    }
});
```

Two disqualifying problems for mass use:

1. **It force-enables every ref it touches.** Vanilla disables spawns deliberately and re-enables
   them through quest enable-parents — the four Ustengrav bandits in `probe-test-protocol.md` §4 are
   parented to `MQ105EnableDungeonMarker`. Applied to thousands of refs this turns on content the
   player has not unlocked.
2. **It fires at 3D load, not at reference init**, so whether it re-rolls a leveled actor at all is
   `[unverified]` and structurally doubtful — the list is resolved long before.

There is also no filter but the FormID list, so all ~2,147 LVLN-backed interior refs plus 3,512
overworld refs would need enumerating. **Repointing placed refs is therefore a plugin `ACHR` job or
nothing** — thousands of overrides with a heavy conflict surface, which is the option A ceiling this
project has rejected since Phase 2.

Conclusion: **archetype-level difficulty is not a shortcut, it is the architecture.** Plan around it
rather than budgeting to undo it.

### 2.5 What is *not* wrong with the design being replaced

Three of the four gating tests passed, and the parts they validated are kept in §4.1 rather than
discarded:

- **Test 2a passed outright.** Swindler's Den pinned to 30, observed at player 5 **and** 45,
  **identical both times** — levels 1 / 5 / 9 / 19 / 28. `[verified]`
- **Test 1 passed.** `LevelModifier: None` honours the zone. Zero records to fix.
- **Test 3 passed.** Zeroing the PC floor zone-locks special loot instead of disabling it.

---

## 3. The four moves, as Requiem does them

All `[verified]` in `prior-art/requiem/plugin-analysis.md`:

1. **Flatten the `LVLN` gate, keep the pool.** All 328 vanilla lists Requiem overrides become
   single-gate; 518 of 571 gate at `Level: 1`. Entry count only falls to **81.6%** of vanilla, so the
   list stops being a ladder and becomes a uniform random draw over variants.
   `LCharDraugrBoss`: 13 entries across 7 gates → **one entry**.
2. **Same for `LVLI`.** 2,034 of 2,125 overrides single-gate; only **5 live lists** keep any player
   gating at all.
3. **Convert `PcLevelMult` → fixed.** 261 converted. (Requiem retains 68; Ehlnofey does not — §4.3.)
4. **Do not use encounter zones for actors.** 8 records out of 358, none for levelling. Once the
   lists are flat there is nothing left for a zone to clamp.

### 3.1 The job, sized in our own decompile

Base + Dawnguard + Dragonborn, Hearthfire excluded per `difficulty-map.md` scope. "Real gate" = more
than one *distinct* entry `Level` on the record — CLAUDE.md's *count the entries, not the flag* rule.
`[verified]`, this branch:

| | records | **real-gated** | entries | entries in gated lists |
|---|---|---|---|---|
| `LeveledNpcs` | 681 | **269** | 4,022 | 1,836 |
| `LeveledItems` | 3,824 | **1,756** | 25,438 | 13,325 |

**269 `LVLN` is the actor job in full.** The 1,756 `LVLI` is a *ceiling*, not a target — see §5.1.

---

## 4. Ehlnofey's twists

### 4.1 Twist 1 — keep the 355 zones, for container loot only

Requiem drops encounter zones because they are inert once actor lists are flat. **They are not inert
for containers**, and test 3 is our own primary-source proof of it.

So Ehlnofey keeps the zone half of `implementation-strategy.md` §2 exactly as specified — the 355
`MinLevel == MaxLevel` bands from `difficulty-map.md` §7, plus `fSpecialLootMinPCLevelMult = 0` —
and **leaves container leveled-item lists gated**. The result:

```
actors   :  flat list           → fixed by ARCHETYPE, everywhere, no zone needed
worn gear:  flat list           → fixed by ARCHETYPE
containers: gated list + zone   → fixed by PLACE        ← bone 3 lives here
```

Why this is the right asymmetry:

- **It is free.** The zones are already specified and generated; `build-difficulty-map.py` needs no
  change. `difficulty-map.md` stops being dead work.
- **It is verified**, which is more than can be said for any alternative bone-3 mechanism.
- **Containers are where "reward follows place" is actually legible to a player.** A Nordic tomb's
  boss chest is the thing you remember; the exact tier of the third draugr in a corridor is not.
- **The overworld objection does not apply.** Unzoned exterior containers are a rounding error next
  to unzoned exterior *actors*, which this architecture fixes by flattening anyway.

**Consequence to accept:** `fLeveledActorMult*` (Easy/Medium/Hard/VeryHard, `tiers.md` §4) becomes
**inert for actors** — the modifier multiplies a leveled-list lookup level, and flat lists have
nothing to look up. Those two GMST overrides are **dropped from the plugin**. Vanilla's hand-tuning
layer on 5,685 placed actors is a casualty of flattening; that is Requiem's trade too.

### 4.2 Twist 2 — the tier ladder moves from places to archetypes, and the lore already wrote it

`tiers.md`'s **T1–T7 = 4 / 8 / 14 / 21 / 30 / 40 / 50** survives intact. What changes is what it
indexes: **a creature family's rung, not a dungeon's.**

This is the one place the pivot makes the mod *more* legible, not less, and `lore-constraints.md`
already identified the mechanism: **vanilla's display names are a lore-ordered power hierarchy.**

| Family | The ladder vanilla already ships |
|---|---|
| Draugr | Draugr → Restless Draugr → Wight → Scourge → Deathlord |
| Dremora | Churl → Caitiff → Kynval → Kynreeve → Markynaz → Valkynaz |

Under the zone architecture those names were only *correlated* with power — the player met a Wight
because a zone was tier 4. **Under flattening the name becomes the fact.** A Draugr Scourge is
level 30 in Bleak Falls Barrow, in Labyrinthian, and in a random barrow at the edge of the map,
forever. Bone 2 (*danger is legible*) is served by the enemy's name rather than by the dungeon's, and
a name travels with the enemy in a way a zone never did.

**Authoring rule:** every flattened `LVLN` leaf is assigned a tier, and the tier must agree with the
display name of everything in the pool. Where vanilla's ladder has more rungs than the pool needs,
collapse; where a name implies a rung the pool does not hold, the pool is wrong. `lore-constraints.md`
is the arbiter, not convenience.

### 4.3 Twist 3 — followers are deleveled too, at hand-set lore levels

Requiem retains 68 `PcLevelMult` NPCs, almost all followers, housecarls and hirelings. **Ehlnofey does
not take that exception.** Bone 1 applies literally: nothing in the world scales, and a companion is
in the world.

This is a real departure and it has a real consequence — a follower fixed at 30 trivialises the early
game, and one fixed at 15 is dead weight late. **Turn that into the design rather than absorbing it:**

- Set each follower's level from **role and lore**, not from balance. A Whiterun housecarl is a
  competent hold soldier; Aela is a veteran of the Companions; Marcurio is a working mage for hire.
- **Choosing a follower becomes a decision with consequences** — an early-game character genuinely
  benefits from a strong companion, and outgrows them. That is the same "fixed world, legible
  danger" contract applied to allies.
- The roster is small and already enumerated: `prior-art/requiem/plugin-analysis.md` §1a lists the
  68 by name. Use it as the work list, then invert the verdict.

Everything else in the `PcLevelMult` population (~454 actors: guards, soldiers, hunters, Nightingales,
`WE*` adventurers) converts by **SkyPatcher rule**, not by override — `filterByPCLevelMult=true` is a
predicate that also catches NPCs from other mods and future patches, where 454 overrides would only
be a snapshot. That argument from `implementation-strategy.md` §4 is unaffected by the pivot and
stands. The follower set is the part done by hand, because hand-set levels are the point.

### 4.4 Twist 4 — adopt Requiem's three record conventions now

Free, pure record technique, no patcher (`prior-art/requiem/lessons-for-ehlnofey.md` §4):

| Convention | Use |
|---|---|
| **`Level: 9999`** | disable an entry in place. It stays in the record so diffs and merges still see it, but can never roll. Better than deletion for the truncation pass |
| **`EHL_NULL_` rename** | retire a record without deleting it — deletion breaks every reference. Requiem has 197 such `LVLI`, 63 `LVLN` |
| **Weighting by duplicate entries** | Skyrim has no weight field, and a flat pool makes every variant equally likely. Repeat the entry N times to weight it |

The third is not optional here. **Flattening costs variety** — Requiem had to build a whole actor
variation generator to pay it back. Weighting is how a flattened bandit pool stays mostly grunts with
the occasional chief instead of a coin flip. Budget for it in the first archetype, not the last.

> **Note the mechanism, which is easy to get wrong.** Weighting is *literal entry duplication*, not a
> `Count` field: `Count` is how many actors an entry spawns, and `CalculateForEachItemInCount` rolls
> each of them separately. Requiem's `_CLI_` convention writes `Count: 5` as authoring shorthand and
> its **patcher unrolls it into five entries** (`lessons-for-ehlnofey.md` §4). Ehlnofey has no
> patcher, so it writes the duplicates out — costs bytes, needs nothing.

---

## 5. Scope control — the loot job is 202 lists, not 1,756

### 5.1 The reachability census — DONE (2026-07-29, this branch)

Under Twist 1, **container-only lists keep their gates and need no edit.** Only lists reachable from
an **outfit or an NPC `Items:` block** are bone-1 leaks. `arch-docs/design/lvli-reachability.ps1`
measures the split: roots are NPC `Items:` plus `DefaultOutfit`/`SleepingOutfit` → `OTFT Items:`
(actor side) and `CONT Items:` (container side), closed transitively over `LVLI → LVLI` edges, load
order last-wins. All `[verified]`:

| gated `LVLI` (1,754 of 3,817) | count |
|---|---|
| reachable from **both** actors and containers | **986** |
| container-only — **no edit** | 410 |
| actor-only | 181 |
| unreached from either root | 177 |

Taken at face value that says 1,167 lists to fix. **It massively overstates the job**, because the
actor side does not need every *reachable* list rewritten — only the ones an outfit or inventory
points at **directly**. Everything below that is subtree, fixed implicitly once the entry point is
flattened.

**The boundary is 202 lists** `[verified]`:

| | count | treatment |
|---|---|---|
| gated lists an actor references **directly** | **202** | |
| ↳ actor-only — **flatten in place** | **126** | free; no fork, no repointing |
| ↳ also container-reachable — **fork or judge** | **76** | §5.2 |

That is the number the whole loot half was waiting on, and it is closer to the Swindler's Den trace's
five lists than to 1,756. (`probe-test-protocol.md` §6.1: the entire bandit-chief wardrobe ran
through `LItemBanditCuirass` `037C22`, `LItemBanditBoots` `037C23`, `LItemBanditGauntlets50`
`037C25`, `LItemBanditShield20` `0C0196`, plus the already-flat `LItemBanditWeapon1H` `037C1B`.)

### 5.2 The 76 shared lists split three ways, and only one band needs forking

Naming them settles it. Of the 76, **only the generic material ladders actually conflict** — the rest
are already scoped to an archetype or a category, so flattening them in place is correct on *both*
sides. `[verified]`, with the count of NPCs holding a direct reference:

| Band | Lists | NPC refs | Treatment |
|---|---|---|---|
| **Gold** — `LootBanditGold` (303), `LootBanditGoldBoss` (71), `LootCWImperialsGold`, `LootCWSonsGold`, `LootDraugrGold*`, `TGRewardGold` | 7 | **383** | **flatten in place.** A fixed purse and a fixed strongbox are both correct |
| **Consumables & sundries** — potions (168), soul gems (101), `LItemGems`, jewelry, minerals, hunter parts, vendor stock, poisons | ~39 | ~270 | **flatten in place.** Category-scoped, no tier meaning |
| **Material ladders** — `LItemWeaponDagger` (67), `LItemWeaponMace` (52), `LItemArmorShieldHeavy` (19), `LItemArrowsAll` (19), `LItemStaffsAll` (15), `LItemWeaponDaggerBest` (14), `LItemWeaponBow`/`Sword`/`WarAxe`/`Warhammer`/`BattleAxe` + `…Town`/`…Best` variants, `LItemEnchWeapon*`, `LItemArmor*`, `LItemSoldierSons*` | **~30** | **~250** | **FORK.** These carry the entire gear leak |

So the real fork set is **~30 lists**, not 76 — and the residual cost is the **~250 NPC records**
holding a direct `Items:` reference to one of them.

### 5.3 What can and cannot be done by rule — read from source

`[verified]` against `reference/mods/SkyPatcherSrc/npc.cpp`, this branch:

| Need | Verdict |
|---|---|
| Repoint an NPC's **outfit** at a forked list | ✅ `outfitDefault=` (`npc.cpp:138`), `outfitSleep=` (`:140`). **This closes `probe-test-protocol.md` §6.3's open question** — SkyPatcher *can* set `DefaultOutfit`. Only **16 of 605** outfits reference a fork list, so this half is trivial |
| Repoint an NPC's **inventory** (`Items:`) | ❌ **no key exists.** `npc.cpp` has `outfitDefault`, `outfitSleep`, `deathItem` and nothing else item-shaped. The ~250 must be **plugin `NPC_` overrides** |
| Flatten a list | ✅ `leveledList/` `clear` + `addToLLs` + `calcLevelAndEachItem` |

**Do not invert the fork direction.** Forking the *container* side instead — leaving the shared list
flat for actors and giving chests a gated copy — looks cheaper until it is measured: the 76 sit
*below* container sublists, so their upward cone is **521 `LVLI`** and **267 of 571 containers**
reach one. Forking downstream of 521 lists is far worse than 250 NPC overrides. `[verified]`

### 5.4 Two more subtractions

- **The 23 already-flat overworld lists** need nothing — `LCharSoldierImperial`, `LCharSoldierSons`
  (all 943 Civil War refs) and `LCharAmbientCreatures` (623 refs). The single biggest block of
  overworld actors was never a scaling problem `[verified]`.
- **Biome partitioning is already done.** `LCharAnimalForestPredator`, `…MountainSnowPredator`,
  `…CoastSnowPredator`, `LCharAnimalHills`, `LCharMudcrab` (209 refs) and kin already split wildlife
  by biome, so flattening each list *in place* yields fixed **and** regionally varied wildlife with
  zero new records `[verified]`. This is the population where Requiem's method is strictly better
  than the zone architecture, and it retires §6.4's 238-cell bolt-on for the wildlife half outright.

### 5.5 The loot half, costed

| Work | Size |
|---|---|
| Flatten in place — 126 actor-only + ~46 safe shared | **~172 `LVLI` overrides** |
| Fork the material ladders | **~30 new `LVLI`** (first real FormID block) |
| Repoint outfits | 16 — **by rule**, `outfitDefault=` |
| Repoint NPC inventories | **~250 `NPC_` overrides** — plugin only |
| Container-only gated lists | **410 — untouched**, the zone supplies their level |
| Unreached gated lists | 177 — see §8.5 |

**~450 records total for the entire loot half.** Against Requiem's 2,125 `LVLI` overrides and MLU's
400-list truncation pass, that is a small mod — and it is small precisely *because* Twist 1 keeps the
zones, which lets 410 lists keep their gates untouched.

### 5.2 Two more subtractions

- **The 23 already-flat overworld lists** need nothing — `LCharSoldierImperial`, `LCharSoldierSons`
  (all 943 Civil War refs) and `LCharAmbientCreatures` (623 refs). The single biggest block of
  overworld actors was never a scaling problem `[verified]`.
- **Biome partitioning is already done.** `LCharAnimalForestPredator`, `…MountainSnowPredator`,
  `…CoastSnowPredator`, `LCharAnimalHills`, `LCharMudcrab` (209 refs) and kin already split wildlife
  by biome, so flattening each list *in place* yields fixed **and** regionally varied wildlife with
  zero new records `[verified]`. This is the population where Requiem's method is strictly better
  than the zone architecture, and it retires §6.4's 238-cell bolt-on for the wildlife half outright.

---

## 6. Order of work

**Step 1 — the outfit-reachability census.** ✅ **DONE** (§5.1–§5.5). The loot half is ~450 records.

**Step 2 — assign every archetype family its tier** (§4.2). ✅ **DONE** — `archetype-tiers.md`.
~67 lists and ~76 NPC records for the whole actor half. It also closes `lore-constraints.md` §6.1:
the Dremora, Warlock and Vampire ladders each land 1:1 on T1–T7, so the tier number is a real
cross-archetype currency and "is a Draugr Scourge worse than a Forsworn Ravager" becomes answerable.

**Step 3 — delete `src/ExampleMod/` and `src/EhlnofeyProbe/`.** ✅ **DONE.** `build/staging/Example
Mod/fomod/` is **kept deliberately** — CLAUDE.md's FOMOD-image gotcha cites it as the only
confirmed-working worked example, and `build.ps1` iterates `manifest.releases` only, so an unreferenced
staging tree is inert.

**Step 4 — scaffold `Ehlnofey.esp`.** ✅ **DONE.** ESL-flagged, four masters, own FOMOD, own manifest
release. Empty scaffold built clean before any record was added.

**Step 5 — the constants.** ✅ **DONE — 19 records** (not 20; see §7.1 of `archetype-tiers.md`):
`fSpecialLootMinPCLevelMult` → 0, the 12 `LevelGate*` globals → 1, and 6 named capstones converted
from `PcLevelMult` to fixed levels. The two `fLeveledActorMult*` overrides are dropped (§4.1), and
`EncBandit04TemplateMelee` turned out to need no record at all.

Verified four ways: `build.ps1` clean · `build.ps1 -CheckFomod` parity OK · `Test-RecordYaml.ps1`
20 files no issues · **Spriggit round-trip byte-identical on content**. Every FormKey reference was
also machine-checked against the declared master list — all resolve, no HearthFires leak.

**Not verified: the xEdit pass and the launch.** See §9.

### Steps 6–9 were replaced by the extract (2026-07-30)

Scope was cut to **one deliverable: a copy of Requiem with only the deleveling in it**. Steps 6–8 as
written above assumed Ehlnofey would re-derive every flat list from `reference/Base/` by rule — ~962
records of original authoring. It does not have to: Requiem's flat records are overwhelmingly built
from **vanilla FormKeys only**, and an override keeps its defining master's FormKey suffix, so for
most records the job is a file copy. `src/Ehlnofey/extract-requiem.ps1` does it in five buckets.

> **Release note.** Verbatim-copied records make the plugin a derivative of Requiem — fine to build
> and play privately, but publishing needs their permission. Bucket D, the part that most defines
> the mod's character, can't be copied anyway and stays original Ehlnofey work.

**Step 6 — the extract.** ✅ **DONE — 2,845 records.**

| | | |
|---|---:|---|
| **A** copied verbatim | 1,896 | `LVLN`/`LVLI` whose every FormKey is one of our four masters |
| **B** stripped | 173 | `LVLI` that also referenced Requiem-only gear; those entries dropped |
| **C** vanilla flatten | 259 | Requiem never covered it, or B emptied it: vanilla record, `Level` → 1 |
| **D** provisional `LVLN` | 66 | nothing copyable — see below |
| **E** level graft | 437 | vanilla `NPC_` record, Requiem's `Configuration.Level` only |
| *skipped* | 1,900 | not ours: Requiem's own records, HearthFires, Creation Club, USSEP |
| *skipped* | 307 | ITMs |

Closure is the result that made this viable: of every vanilla `LVLN` reachable from Requiem's flat
lists **0 remain player-gated**, and for `LVLI` only 7. Of the **257** gated vanilla `LVLN` in the
whole game Requiem covers **249**. There is no `REQ_NULL_` contamination — 0 entries in live lists
point at a record Requiem neutered.

Deliberately **not** taken: Requiem's perks, spells, magic effects, weapons, armour, crafting and
economy; its 8 encounter zones (none is a level record); its `fDiffMultHP*`/`fDiffMultXP*`
difficulty-slider flattening. Requiem's `HealthOffset` and its dropped `AutoCalcStats` flag are its
capability overhaul, so bucket E takes the level field and nothing else. The ~150 EditorIDs Requiem
renamed into its own taxonomy (`LItemWeaponSword` → `REQ_LI_Loot_Weapon_Sword`) are restored to the
vanilla name; `REQ_NULL_` / `REQ_LEGACY_` / `REQ_BashedPatch_` records are dropped, since
disconnecting a record is not deleveling.

Every entry in every leveled list is now `Level: 1` or the `9999` disable sentinel. Four residual
Requiem gates were flattened for bone 1: `SublistEnchElvenBattleaxeStamina` (25),
`SublistEnchOrcishSwordAbsorbHealth` (11), `SublistEnchOrcishSwordTurn` (11) and
`DLC2LCharDragonAny` (**55** — Requiem gates Solstheim's any-dragon list behind level 55; flattening
it means those dragons are reachable from level 1, which is the design, but it is a judgement call).

Verified: `build.ps1` clean · `Test-RecordYaml.ps1` 2,846 files no issues · **round-trip byte-stable**
· **zero new FormIDs** · masters exactly Skyrim/Update/Dawnguard/Dragonborn. **Not launched.**

**Step 7 — bucket D, the 66 `LVLN` that could not be copied — plus 7 more.** ✅ **DONE — `src/Ehlnofey/author-bucket-d.ps1`.**

Requiem's versions delegate to `REQ_LChar_VoiceSpawns_*` sublists that are Requiem-only **and still
player-gated** (1/2/5/8/9/10), so nothing came across and the extract left a naive vanilla flatten.
That flatten was actively wrong for the biome lists — §4.1.1 shows it inherits the level-35
density-ramp mix (`BearCave ×7` dominant), the most dangerous composition vanilla ever produces.

The rosters are now authored from `archetype-tiers.md` §3.1 / §4 / §4.1 in three shapes, every one a
**filter + weighting of the vanilla record** — no level is ever written onto an actor (rule 1), and
weighting is literal entry duplication (rule 2):

| Shape | Used for | Count |
|---|---|---:|
| `Cap` — keep vanilla's own mix frozen at the tier's reference level (§4.1.2 verbatim) | the 8 flagged biome predator lists, the Vigilant sublists, `LCharVampireCompanionFrost` | 11 |
| `Gates` — explicit per-gate weights (§3.1, §4) | the bandit ladder and bosses, the 3 unflagged ambient lists, the species-substitution lists | 51 |
| `Refs` — explicit per-reference weights, where one gate holds several species | `LCharMudcrab` | 1 |
| *dropped* — already a single gate at 1 in vanilla, so an override would be an ITM (§4.1.3) | `LCharWolf`, `LCharDeer`, `LCharElk`, `LCharSkeletonMeleeMixed`, `LCharBanditMeleeAny`, `SubCharVigilantOfStendarr01`, the 3 prey lists | 9 |

Verified entry-for-entry against the design tables: **all nine biome rosters reproduce
`archetype-tiers.md` §4.1.2 exactly**, `LCharBanditMelee1H` is `Outlaw ×3 · Thug ×4 ·
Highwayman ×2` (revised 2026-09-24: level-1 rung dropped), and the per-voice leaves keep their 1H/2H variant variety inside each weight. Two
table-vs-prose conflicts were resolved and recorded in `archetype-tiers.md` §4.1.2
(`LCharAnimalSnowFields`' out-of-band Ice Wraith; `LCharMudcrab`'s duplicated row).

**Amended 2026-07-30 after the first play report**, which found the Swindler's Den chief rolling
level 6 to 28 — the naive flatten's signature, already gone from the shipped build, but the trail led
to two real defects:

1. **`LCharBanditBoss` and its 9 per-voice siblings are pinned to level 28**, not banded 16/21/28.
   Every rung of that ladder displays the *same* name, so a 75% power swing was invisible — which
   Twist 2 forbids. The naming test and the per-family verdicts are now `archetype-tiers.md` §3.1.1.
   **Four boss families still fail it** (Forsworn, Warlock, Thalmor, Vampire) and are a decision not
   yet taken. Draugr and Falmer pass — their rungs are separately named.
2. **7 lists the extract left as a naive vanilla flatten are now authored** — `LCharBanditOnly`
   `NordM`/`RedguardF`/`OrcM`, `LCharBanditMeleeKhajiitM`, `LCharBanditMissileKhajiitM`,
   `LCharBanditWizardOmit01` (all §3.1's bandit roster) and `LCharOrcMelee` (§3.1's own row:
   Outlaw ×1 · Thug ×3 · Highwayman ×3 · Plunderer ×1). These are 6 of the **8 uncovered `LVLN`**
   §"closure" lists — Requiem never overrode them, so bucket C flattened all six rungs and left
   Plunderer and Marauder reachable in lists §3.1 caps at Highwayman. `LCharGargoyle` and
   `dunClearspringTarnLCharPredator` are the 2 still unaddressed.

**Build order is `extract-requiem.ps1` → `author-constants.ps1` → `author-bucket-d.ps1` →
`author-injectors.ps1` → `author-retargets.ps1`**, then the round-trip. `bucket-d-provisional.txt` is regenerated by the extract
and is the *input* list, not a to-do.

**Step 7b — `author-names.ps1` was removed on 2026-09-24.** It named all 44 `EncBandit01*` records
"Bandit Runt", and the name never showed in game (nor did naming only the three templates, the first
attempt). The level-1 rung is now dropped from the bandit roster instead; see `archetype-tiers.md` §3.1.

**Step 8 — launch.** Guardrail 6. Level-1 character, `coc bleakfallsbarrow01`; then
`player.setlevel 40` and enter a *different* uncleared barrow. Same spawns, same loot tier, or the
architecture is not doing what the census says it is.

**Step 9 — followers by hand** (§4.3): the 65 `PcLevelMult` allies Requiem deliberately leaves
scaling and therefore supplies no level for, plus the 114 vanilla `PcLevelMult` NPCs Requiem never
reaches. Then the rule linter (`implementation-strategy.md` §8) if any SkyPatcher rules survive.

> **Re-running the extract.** `extract-requiem.ps1` regenerates from `reference/`, so its output is
> pre-round-trip: Spriggit normalises field order, and collapses the multi-language `Values:` block
> vanilla `NPC_` records carry into a single `Value:`. After any re-run, **deserialize, re-serialize,
> and adopt Spriggit's output as the committed source** — the same rule as CLAUDE.md's field-order
> gotcha. The committed tree is already in that normalised form.

---

## 7. What this supersedes

| Document | Effect |
|---|---|
| `implementation-strategy.md` §1 | ❌ the zone-first hybrid is replaced. §§2.2–2.4, §4, §8 survive |
| `implementation-strategy.md` §2.1 (355 zones) | ✅ **kept**, re-purposed to container loot (§4.1) |
| `implementation-strategy.md` §2.2 (`fLeveledActorMult*`) | ❌ **dropped** — inert once lists are flat |
| `implementation-strategy.md` §6 (overworld) | ⚠️ wildlife half **superseded** by §5.2; humanoid half moot — flattening covers it |
| `loot-model.md` §1 "no truncation pass needed" | ❌ **dead** (§2.2) |
| `difficulty-map.md` §7 (the 355 assignments) | ✅ **kept in full** — now the loot map |
| `tiers.md` T1–T7 ladder | ✅ **kept**, re-indexed from places to archetypes (§4.2) |
| `lessons-for-ehlnofey.md` §5 (ally exception) | ❌ **explicitly rejected** (§4.3) |
| Requiem's `fDiffMult*` → 1.0 | ❌ **not adopted** — removing the player's difficulty slider is out of scope for a mod that is not a combat overhaul |
| CLAUDE.md *Implementation strategy* + *Current phase* | needs rewriting once this lands |

---

## 8. Open risks

1. **Variety collapse.** The measured cost of flattening is that every draw becomes identical.
   Requiem's entry count held at 81.6%, but it also built a generator to restore variation. Twist 4's
   weighting is the mitigation; whether it is sufficient is only answerable in-game at step 7.
2. **Archetype tiering is curation, not an algorithm.** `Changelog.md` is 2,491 lines of one-off
   delevels and Requiem *still* leaves 114 NPCs scaling after thirteen years. Plan for a long tail and
   a coverage-audit script; do not plan for a clean sweep.
3. **Container gating assumes zone-bound resolution holds for ordinary chests**, not just the
   `SpecialLoot`-flagged boss roll that test 3 exercised. `[community]`, worth one cheap confirmation
   at step 6 — open an ordinary urn in a pinned zone at two player levels.
4. **Deleveled followers are untested as a design.** §4.3 argues it is a feature; nobody has played
   it. Revisit after step 9 with actual play, and treat reverting to Requiem's exception as a live
   option rather than a defeat.

### 8.5 The 177 unreached gated lists

Gated `LVLI` that neither an NPC/outfit nor a container references. Sampling them shows what they
are: quest rewards (`LvlQuestReward*`, `DLC2MQ06MiraakRewardMaskL`), death items
(`DLC1DeathItemGargoyle`), dungeon-specific enchanted sets (`dunSilentMoonsLItemEnchSteel*`),
`SublistEnch*` fragments, and unique gear (`LItemWeaponNightingaleSword`, `TGLvlItemNightingaleBoots`).

They are reached from roots this census does not walk — `QUST` reward packages, `FLST` form lists,
`NPC_` death items, and leveled items placed directly as world references. **Most are one-offs where
a fixed level is the right answer anyway**, but the set has not been individually triaged. Triage it
during step 8; it is a read, not a redesign, and `deathItem=` is rule-expressible (`npc.cpp:142`).

---

## 9. Environment blockers found at step 5

Neither is a defect in the mod; both stop guardrail 6 from being satisfied and need the user's input.

1. **`tools.json` points at a game install with no DLC.** `gameDataDir` is
   `claudemoddev/modlist/Game Root/Data`, which holds **only `Skyrim.esm`** — a tooling stub, not a
   playable install. Ehlnofey masters `Update`, `Dawnguard` and `Dragonborn`, so nothing can load it
   there. A full set does exist at `C:/modding/modlists/LoreRim/Stock Game/Data` (all five masters).
   **Decision needed:** repoint `gameDataDir` (and possibly the other `claudemoddev` tool paths) at
   LoreRim, or install the DLC into the stub. Not changed unilaterally — `papyrusCompiler`,
   `creationKit`, `champollion` and the xEdit tools all point into `claudemoddev`, and moving one
   path without the others is how a workspace ends up half-configured.

2. **`SSEEditQuickAutoClean` blocks on a GUI dialog** even with `-autoload`. The same risk applies to
   the *Check for Errors* pass on this build. The run was killed and the staged plugin and its backup
   removed from the LoreRim Data folder. This is why the `xedit-audit` skill was **deleted from the
   workspace** — headless xEdit does not work here, so the skill could never do its job.
   **Consequence: no xEdit audit has ever been run against Ehlnofey.esp.** The substitute checks
   above are strong for *this* slice — every record was copied verbatim from `reference/`, so its
   FormKeys are valid by construction — but they will not stay sufficient once step 8 authors records
   by transformation rather than by copy.

## Sources

`prior-art/requiem/plugin-analysis.md` §§1–5 · `prior-art/requiem/lessons-for-ehlnofey.md` §§2–6 ·
`prior-art/skypatcher.md` §§2, 4.2, 5 · `design/probe-test-protocol.md` §§4, 5, 6, 6.1 (in-game
results) · `design/implementation-strategy.md` §§2, 4, 6, 7.1 · `design/loot-model.md` §§1–4 ·
`design/tiers.md` §4 · `design/difficulty-map.md` §7 · `world/lore-constraints.md` ·
`reference/mods/SkyPatcherSrc/reference.cpp`, `main.cpp:938–977` (§2.4, read this branch) ·
`reference/Base/01Skyrim/Cells/` (§2.3 roster census, run this branch) ·
`reference/Base/{01Skyrim,02Update,03Dawnguard,05Dragonborn}/{LeveledNpcs,LeveledItems}/` (§3.1).

---

## 10. What the proof of concept shipped (moved from CLAUDE.md, 2026-09-27)

This was CLAUDE.md's "Current phase" section on the day the rebuild started, verbatim. Script
paths in it predate the generators' move into `src/Ehlnofey/proof-of-concept/`.

**Phase 4 is under way and `Ehlnofey.esp` exists: 3,013 records** (2026-09-27; 2,877 at the first extract, 2026-07-31, branch
`design/requiem-method`). Read **`arch-docs/design/requiem-method.md` first** — it is the live
architecture doc, and its §6 is the current order of work. Everything below it in this section is
the Phase 3 record, kept because most of it still holds, but **the architecture it decided has been
replaced.**

**What changed.** Encounter zones govern only 0.3% of the outdoors and cannot reach worn gear, so the
zone-first hybrid could not deliver bone 1. The mod pivoted to **Requiem's method** — flatten the
`LVLN`/`LVLI` gate, keep the pool, fix `PcLevelMult` NPCs — and then to the cheapest possible way of
getting it: **extract Requiem's deleveling layer directly.** Requiem's flat records are
overwhelmingly built from vanilla FormKeys only, and an override keeps its defining master's FormKey
suffix, so most of the job is a file copy. `src/Ehlnofey/extract-requiem.ps1` is the generator.

| | | |
|---|---:|---|
| A copied verbatim | 1,896 | `LVLN`/`LVLI`, every FormKey one of our four masters |
| B stripped | 173 | `LVLI` minus their Requiem-only gear entries |
| C vanilla flatten | 259 | not covered by Requiem, or emptied by B |
| D authored | 64 | the `LCharBandit*` ladder + the biome rosters, from `archetype-tiers.md` (+9 dropped as already-flat) |
| E level graft | 434 | vanilla `NPC_` record + Requiem's `Configuration.Level`, nothing else |

Every entry in every leveled list is now `Level: 1` or the `9999` disable sentinel. Builds clean,
`Test-RecordYaml.ps1` passes 2,878 files, round-trip is byte-stable, **zero new FormIDs**, masters
exactly Skyrim/Update/Dawnguard/Dragonborn. It **has** been launched, and **Bleak Falls Barrow and
Swindler's Den both give a consistent spread of enemy types at player level 1 and 45** — the first
real evidence bone 1 holds in play. Boss-chest loot is still unverified (guardrail 6).

**The first play report found a design bug, not a build bug** (2026-07-30): a band of levels is only
legible if its rungs have *different names*, and the bandit boss ladder's do not. See
`archetype-tiers.md` §3.1.1 for the naming test — **four boss families still fail it** (Forsworn,
Warlock, Thalmor, Vampire) and are an open decision.

**Generators, and the order they must run in:** `extract-requiem.ps1` → `author-constants.ps1` →
`author-bucket-d.ps1` → `author-injectors.ps1` → `author-retargets.ps1` (was `author-orc-camps.ps1`), then deserialize → re-serialize →
adopt Spriggit's output as the source. `author-injectors.ps1` (was `author-cc-compat.ps1`) reads
`reference/Base/` and `reference/mods/CreationClubYaml/` (Spriggit decompiles of the CC plugins in the
Baseline modlist's `mods/Creation Club Files`).

**Creation Club is a hard requirement since 2026-09-23** (user decision: AE is near-universal). The
plugin takes the 15 Bandit Armor packs (`ccbgssse050`–`064-ba_*.esl`) as masters and overrides their
injector quests — see the "runtime `AddForm`" gotcha below. **Verified in game 2026-09-23:** on a
fresh chargen start, the Robber's Gorge and Swindler's Den chiefs are both level 28 (were 6).

**Dragonborn's `DLC2Init` 016E02 is overridden the same way** (2026-09-24): its start-up fragment
injected Nordic weapons (gate 23) and armor (gate 25) into every bandit and bandit-chief gear list, plus
Hulking Draugr (gate 26) into `LCharDraugrMelee1HMale`. Chiefs wore iron at player level 1 and full
Nordic at 40. The 24 list properties are removed; Nordic gear is put back **by place** as one level-1
entry in each of the 11 `LItemBanditBoss*` lists (user decision), which also now all carry
`CalculateFromAllLevelsLessThanOrEqualPlayer`. Built clean; **not yet verified in game.**

**The injector audit is done** (2026-09-24): 28 quests across the base game, DLC and all 74 CC plugins
hold leveled-list properties. **Six more re-levelled our lists** and are now handled the same way
(user decision: keep the CC content, re-add it by place at level 1): `ccvsvsse003-necroarts`
(necromancer bosses on a 1–46 ladder into the three voice-boss lists; the CC boss of each tier the pinned
list already holds is added), `ccbgssse001-fish` (honed draugr weapons 12–24, conjurer robes 1–40),
`ccbgssse014-spellpack01` (master robes 1–40), `ccbgssse002-exoticarrows` (magic arrows 10–30 into bandit
and vampire arrows, a gated sublist into arrow loot), `ccasvsse001-almsivi` (Ordinator gear at 36 into 13
Solstheim lists), `cccbhsse001-gaunt` (injects at 1, but its own sublists gate 1–48 — those two
sublists are flattened, the quest is left alone). Only the offending properties are stripped, so each
quest's harmless level-1 injections (spell tomes, books, food, clothes) still run. The rest — Dawnguard
books, Hearthfire food and children's clothes, and ~15 CC packs — inject flat and were left alone.
**The plugin now has 26 masters**: the five base masters (Hearthfire included — see Naming) plus 21 CC
plugins (27 and 22 since WD-48 added the Redguard pack). Overriding CC quests collapses their 9-language strings to English (the non-localized-`.esp`
gotcha), so non-English players see English text in those quests.

**Bandit chiefs have a steel floor** (2026-09-24, after play confirmed the chief mix is the same at
levels 1 and 40): `author-injectors.ps1` removes plain iron armor and the enchanted iron weapons from 7
`LItemBanditBoss*` lists. The armor lists also feed the no-shield chief outfit, three named outfits
(Craglane's butcher, Fjola, Haldyn) and `DLC2LItemBanditArmorAll`, which lose the iron too. The Solstheim
chief's own outfit (`DLC2BanditArmorBoss`: bonemold/chitin) never had any. Glass and ebony are excluded from every
bandit list as well (the enchanted glass mace was the only one). **Archers always carry a bow** (Requiem's
`LItemBanditWeaponBow` pointed half its entries at the melee lists) and **bandit arrows are 90% iron /
10% fire** — the CC bone arrow (26 damage, above Daedric) is dropped. Both lists are shared with Thalmor,
Penitus Oculatus, embassy guards and Dremora archers, who get the same fix. All in `author-injectors.ps1`'s
cuts/weights table.

**Hostile Orc camps** (Cracked Tusk Keep, Bilegulch Mine, Rift Watchtower; 2026-09-24) are **not** the
Orc strongholds — `archetype-tiers.md` §3.1 conflated them. `LCharOrcMelee` is now Highwayman ×3 ·
Plunderer ×4 · Marauder ×2; `author-retargets.ps1` retargets its two non-camp users (Largashbur's
`DA06LvlOrcMelee`, the Old Orc `WE24Orc`) to the ordinary Orc-bandit list, points Bilegulch's
`LvlBanditMissileOrcM` at the Orc Hunter list, and raises `EncOrcHunterTemplate` from **level 1** (every
Orc Hunter rank inherits it — vanilla's archers were all level 1) to 19. Three ordinary Orc bandits placed
directly in those cells stay on the shared bandit list (no cell edits, user decision). Re-asked after play
(2026-09-25) and declined again once the cost was clear: two of the three are in *exterior* cells.

**Faction work is tracked in Jira** (project WD, epic WD-27): one story per faction, WD-43…WD-62, and
dragon gear craft-only is WD-63. **Two cross-cutting design decisions were made on 2026-09-25 (WD-42)**,
and are recorded in `archetype-tiers.md` §3.1.1 and §9:
- **Rung levels are vanilla's.** Bucket E now grafts only `PcLevelMult` records (179). The 256
  overrides that carried Requiem's rebalance of already-fixed levels were deleted. The plugin is
  **2,607 records**.
- **Illegible boss bands are pinned.** Each faction ticket picks the rung.
- **Rule 3 (at most three tiers)** is decided per faction.

The same pass fixed two shipped bugs:
- **The capstones.** `author-constants.ps1` ran *before* the extract, so bucket E overwrote them:
  Alduin shipped at 250, Harkon at 80 and Miraak at 120. The chain order is now extract → constants.
- **36 NPCs with blank names.** See the DLC-names gotcha.

**Forsworn are done (WD-43, 2026-09-26). Levels, spawn mix and gear were verified in game by the user.**
- **Mooks:** Forager ×1 · Looter ×3 · Pillager ×4 · Ravager ×1, mean ≈ 20, across all five rank-and-file lists.
- **Briarhearts:** pinned to 38, where Requiem shipped 51. Shaman Briarhearts cast again.
- **Gear:** Forsworn armor always. Only Briarhearts and Ravagers draw elven, dwarven or rare glass weapons, from
  `LItemForswornBossWeapon1H`.
- **Shaman Briarheart dagger:** glass and ebony at 1 in 24 each.
- **Arrows:** Forsworn or iron, 50/50.
- **CC arrows:** the fire and ice arrows came from the 15% bonus roll (`LootForswornArrows15`), which pointed at
  `LItemArrowsAll`. It now rolls the Forsworn arrow list.
- **Plugin size:** 2,610 records (+2 `NPC_` retargets, +1 `LVLI`).

See `archetype-tiers.md` §3.1.

**Guards and civil-war soldiers are built (WD-44/45, 2026-09-26). This is not yet verified in game.**
- **Level: hold guards and soldiers roll 25, 30 or 35**, a third each (user, after play: 25 lost to bandits).
  Each of the 36 guard and soldier leaves owns its level. Rank *names* are not possible yet: the nameplate shows
  the hold record's name. The single fixed records sit at **30**, the spread's average: the siege soldier and siege
  archer templates, Redoran guards and the MQ104 Whiterun guards. The guard and soldier templates hold 25, but
  nothing reads their level any more. See `archetype-tiers.md` §6.
- **Guards were still scaling 20–50 before this.** The extract's level-25 grafts sat on `EncGuardImperialM0x` leaves,
  which take their Stats from `EncGuardImperialTemplate`, so the grafts had no effect.
- **Gear:** Stormcloaks keep Requiem's iron/steel weapon mix and hide/steel shields (user decision). **Imperials
  had no weapon at all.** Bucket B had stripped Requiem's Imperial weapon lists, so every Imperial soldier and guard
  fought bare-handed in play. The Imperial sword, bow and steel dagger are re-added by `author-injectors.ps1`.
  **The Thalmor bow sublists had the same bug** (`SublistThalmorBowAndArrows{Elven,Glass}`: arrows, no bow). The
  Elven and glass bows are back. Which rank gets which sublist is still for the Thalmor ticket.
- **Plugin size:** 2,646 records (+36 `NPC_`).

**Warlocks are done (WD-46, 2026-09-26). Levels were verified in game by the user.**
- **Mooks:** Mage ×2 · Wizard/Ascendant ×3 · Pyromancer/Master ×1 (19/27/36), across 32 lists (five schools, their
  `Omit01` variants, 22 race/voice lists).
- **Bosses:** pinned to **50** (Arch). Four voice lists with no level-50 leaf in their race and sex sit at 40. Vanilla's
  boss lists never reached 50, so `author-bucket-d.ps1` gained a `Pin` rule for references a vanilla list lacks.
- **Gear:** left alone (user decision). Malkoran (`DA03Wizard`) is a level-50 Conjurer boss.
- **Plugin size:** unchanged at 2,646 (all 46 lists were already overridden). See `archetype-tiers.md` §3.1.

**Vampires are done (WD-47, 2026-09-26). Levels, mix and thralls were verified in game by the user.**
- **Mooks:** Nightstalker ×1 · Ancient ×3 · Volkihar ×2 (28/38/48, mean ≈ 40, T6), well above the warlocks (user:
  immortal, Daedric-blessed). The four female lists roll the same roster. The male Nord list borrows boss leaves at 31/42/53.
- **Bosses:** pinned to **65, the Nightmaster** (user), which is **above Harkon** (55/60). Serana's planned 40 now sits
  inside the mook band. Both are flagged for their own tickets.
- **Gear:** `LItemVampireWeaponBase` holds its own steel/orcish/dwarven/elven swords and war axes; it had pointed at the
  bandit lists (70% iron). The armor is vampire armor and robes only; Requiem's glass/elven/orcish/leather sets were cut.
- **Arrows:** the CC bone arrow is gone from the vampire arrows and from the exotic-arrows vendor sublist. That sublist
  sits in `LItemArrowsAll`, so its flatten now runs before the cuts.
- **Thralls: level 25** (user, after play: they were 5). A "Vampire's Thrall" owns no level; it templates onto a
  bandit ladder. `author-retargets.ps1` points 37 thrall records at that ladder's gate-25 Marauder entry. Melee thralls are all
  two-handed (user): they close in and soak damage for the vampire. Dropping
  `Stats` was not safe: thralls carry the placeholder class `EncClassDremoraMelee` and no `AutoCalcStats`.
- **Plugin size:** 2,684 records (+1 `LVLI`, `LItemVampireWeaponBase`; +37 thrall `NPC_`).

**Thalmor are done (WD-48, 2026-09-26). Levels and gear were verified in game by the user.**
- **Levels, all pinned** (one name per band): soldiers and archers **36**, above every guard. Wizards **44**. Boss wizards **50**.
- **Gear:** Elven for everyone. **Rare glass (1 in 10) goes only to the Justiciars** (weapon and armor) **and the boss wizard**
  (dagger), through two new lists and the Justiciar-only no-helmet outfit.
- **Archer fix:** `LvlThalmorMissile` (the Embassy, Northwatch and Ratway archers) owned the bandit bow and iron arrows.
  It now carries the Thalmor Elven bow and dagger.
- **CC Redguard pack:** its three Thalmor soldiers (`ccEDHSSE003_EncThalmor*`) owned a fixed level 18. They are now 36
  like every other soldier (verified in game), which makes `ccedhsse003-redguard.esl` the **27th master** (22 CC plugins).
- **Plugin size:** 2,694 records (+2 new `LVLI`, +9 `NPC_`). See `archetype-tiers.md` §3.1.

**Wildlife and monsters are done (WD-54, 2026-09-26). Verified in game by the user; the wolf raise came from that play.**
- **Species levels stay vanilla** (skeever 1 … mammoth 38), except **wolves: 5** (was 2; they died faster than mudcrabs), **giants: 38** (was 32, on a par with mammoths)
  and **hagravens: 40** (was 20). That covers
  `EncHagraven` and the four named hagravens that own their level.
- **The biome gaps are fixed:** the snowy-forest list has no frost trolls, and the two Solstheim lists are frozen at T3
  and T5.
- **The §4 rosters are built** for spiders, bears, the ice-wraith/frost-troll list, spriggans and spriggan companions.
- **Hagraven companions** are trolls and giant spiders only.
- **Plugin size:** 2,703 records (+9 `NPC_`; 16 `LVLN` re-authored). See `archetype-tiers.md` §4 and §5.

**Daedra are done (WD-52, 2026-09-26). Verified in game by the user.**
- **Dremora:** Markynaz ×1 · Valkynaz ×1 (36/46, mean 41, on par with vampires) in the melee, archer and warlock lists.
- **Arch conjurer bosses (50)** summon a Dremora Lord (46) instead of a storm atronach. Master conjurers keep storm
  atronachs.
- **Gear:** every Dremora carries enchanted Daedric. The warlocks' bandit weapons were repointed.
- **Atronachs:** Flame ×2 · Frost ×2 · Storm ×1. Summon levels are unchanged.
- **Plugin size:** 2,706 records (+3 `NPC_`; 6 `LVLN` re-authored). See `archetype-tiers.md` §3.3.

**Witches, Hags and the CC Bone Wolf pack are built (2026-09-27, after play). This is not yet verified in game.**
- **Witch 19 · Hag 27**, the warlock Mage and Wizard rungs with their HP and magicka bonuses, weighted 2 : 3 in the four
  `LCharWitch*` lists. Vanilla was fixed at 4 and 8, so they were flat but far below the warlocks. The six
  `EncWitch0NTemplate*` own the level for every leaf. Spells unchanged.
- **Bone Wolf pack (`ccbgssse036-petbwolf.esl`):** the hostile Bonewolf and the two Thrall Wolves are fixed at **12** (were
  ×1 [5–30] and [5–60]). Its quest Necromancer is fixed at **36** (was ×1.2 [12–70]). The pet is untouched. The pack is
  the **28th master** (23 CC plugins).
- **Plugin size:** 2,716 records (+10 `NPC_`; 4 `LVLN` re-authored). See `archetype-tiers.md` §3.1 and §5.

**Draugr are done (WD-49, 2026-09-27). Verified in game by the user.**
- **Mooks:** Restless ×3 · Wight ×3 · Scourge ×2 across all eleven melee and missile lists. Warlocks get the same shape
  at ×1 · ×3 · ×2. **All three ranks are raised +15 to 21 / 28 / 36** (user), mean 27.4, on the nine templates that own their
  level (`AutoCalcStats`, so health and skills follow; perks do not). Plain Draugr and both Deathlord rungs leave the leveled
  lists. Requiem had kept all six rungs, weighted low (mean ≈ 7).
- **Bosses: pinned to "Draugr Death Overlord" at 45.** The plain one is raised from 34 to match the Ebony one, and the two roll
  50/50 (user). Requiem had pinned the list at 34, so Bleak Falls Barrow's boss was level 34 at player level 1.
- **Gear:** Requiem's ancient Nord ceiling stays. **Ebony comes back on the Ebony Death Overlord only**, which is the only
  visible difference between the two bosses: its three lists, plus a retarget of `EncDraugr05TemplateBossEbony`, whose own
  list Requiem had turned into enchanted ancient Nord.
- **Loot:** vanilla gold is back on draugr corpses and on the Dragon Priest (50–250). Requiem's bone meal stays.
- **Dragon priests** are all fixed at 50 already, so they needed no change. **Hulking Draugr stay out** (user).
- **Castle Volkihar skeletons** take `Stats` from the draugr lists, so they now roll the same 21/28/36.
- **Plugin size:** 2,727 records (+11 `NPC_`). See `archetype-tiers.md` §3.2.

**Falmer are done (WD-50, 2026-09-27). Verified in game by the user.**
- **Mooks:** Gloomlurker ×1 · Nightprowler ×3 · Shadowmaster ×2 (22/30/38, mean 31.3) across the melee, archer, spellsword and
  shaman lists. Requiem had pinned every Falmer list to Shadowmaster 38 (bosses 44).
- **Shamans** own their level. The three kept rungs are raised from 14/19/25 to their rung's 22/30/38 (shaman defect closed).
- **Boss:** pinned to the Dawnguard Warmonger boss, level 54. Boss names are rung names, so it sits one rung above every mook.
- **Chaurus:** the Dawnguard no-hunter list is aligned to Chaurus ×3 · Reaper ×1. Gear and loot were already flat, and no
  quest injects into these lists.
- **Plugin size:** 2,730 records (+3 `NPC_`; 6 `LVLN` re-authored). See `archetype-tiers.md` §3.3.

**Dwemer automatons are done (WD-51, 2026-09-27). Verified in game by the user.**
- **Every list rolls only its Guardian** (user: "deadly", average 40–50): Spider 40 · Sphere 45 · Ballista 45 ·
  Centurion 50. The mixed list rolls spider ×3 · sphere ×3 · centurion ×1, mean 43.6. Requiem had kept every rung at ×1.
- **Forgemaster pinned at 60** (the extract had grafted Requiem's 120). The Aetherial Staff's summoned sphere keeps 24.
- **Loot unchanged** (already flat). No injectors.
- **Plugin size:** 2,735 records (+5 `NPC_`; 8 `LVLN` re-authored). See `archetype-tiers.md` §3.3.

**Dragons are built (WD-53, 2026-09-27). This is not yet verified in game.**
- **Levels: 50 minimum, types kept** (user). The rungs are Dragon 50 · Blood 55 · Frost 60 · Elder 65 · Ancient 70 ·
  Serpentine 72 · Revered 75 · Legendary 80, each raised on the template that owns every variant's `Stats`.
- **World pool:** Dragon ×2 · Blood ×3 · Frost ×2 · Elder ×2 · Ancient ×1 (mean 58.5). Solstheim adds Serpentine ×2. Revered and
  Legendary are ice-lake only.
- **Mirmulnir is pinned at 50.** Whether he can be killed at main-quest level is the open play-test.
- **Named:** Alduin 100 (110 in Sovngarde), Paarthurnax 90, Odahviing 85 (given his own stats: `AutoCalcStats` and the dragon
  class, off the Dremora placeholder) and Durnehviir 80. The extract had left Requiem's 250 on `MQ304Alduin` and 100 on Durnehviir.
- **Skeletal and Skuldafn dragons** owned a flat 721 health, so they gain `AutoCalcStats`. `author-retargets.ps1` has a new
  `Insert` op for that.
- **Loot:** vanilla gold and gems are back on dragon corpses, and Requiem's bones and scales stay. The armor and weapon rolls stay
  out: they point at the game-wide All lists.
- **Plugin size:** 2,754 records (+19 `NPC_`). See `archetype-tiers.md` §3.4 and §7.

**WD-55…59 are done (2026-09-27): built as one batch and verified in game by the user in one play-test.**
- **Werewolves and the Silver Hand (WD-55).** The werewolf list rolls Skinwalker ×1 · Beastmaster ×3 · Vargr ×2 (20/28/38, mean 30).
  The Silver Hand owned no level; they rode the bandit lists (5/9/14). They now point at three **new** Silver Hand lists
  (`EHL_LVLN_SilverHand*` 0x802–0x804), built from the same bandit rungs two up: Highwayman ×1 · Plunderer ×3 · Marauder ×1
  (14/19/25). Krev and the other bosses stay at the bandit chief's 28. **Werebears 30:** the placed three were 17, the `DLC2WE07` trio
  took bandit berserker stats (5–14), and `DLC2EncWerebear` (Torkild and the Beast Stone summon) was 25.
- **Minor factions (WD-56).** Penitus Oculatus pinned at **36**, level with the Thalmor. The Katariah archers were level 1 (a vanilla
  bug: no `Stats` flag). Penitus archers had **no bow** (the bucket-B strip again): the Imperial bow and vanilla `PenitusGear` are
  re-added. Vigilants are pinned at **35** across all ten lists; the ticket's "already flat at 5" was wrong, since the Hall's voice
  lists rolled 5–25. Carcette 45, Tolan 35. Ghost wizards roll the bandit ghosts' 5/9/14 (Requiem had pinned 25). The Alik'r keep
  their quest grafts of 30/35; the level-1 `WERJ03` Alik'r is fixed to 30.
- **World encounters and assassins (WD-57).**
  - **Hunters 10.** The same template also sets farmers', fishermen's and pilgrims' levels.
  - **Adventurers:** all nine at **25**. Four were still scaling with no cap.
  - **Road thief 19.** The DB "marked for death" assassin is **25**; it was 45 and arrives from player level 5.
  - **DB:** the initiates are 25, and the Sanctuary keeps 45–50.
  - **Nightingales** keep 45.
  - **Morag Tong 30**, with their own `Stats` and a real class, off the Solstheim bandit ladder.
  - Minor stragglers were fixed as well.
- **Dawnguard DLC (WD-58).**
  - **Dawnguard pinned at 38.** `DLC1EncHunterTemplate`'s live graft of 50 (Agmaer, Beleval, the Fort guards) is now 38 too.
  - **The Dawnguard war axe is back**; mooks had only the warhammer.
  - **Gargoyles** roll 13 ×1 · 25 ×3 · 43 ×1.
  - **Chaurus Hunters** 1:1.
  - **Armored trolls** raised to 26 / 36, 1:1. The frost one now owns its level.
  - **Soul Cairn:** Keepers 50, the Reaper 65. The Keepers' Dragonbone drops are kept (user).
  - **Frozen Falmer, Shaman and Chaurus** pinned at 40.
- **Dragonborn DLC (WD-59).**
  - **Rieklings:** 6 ×2 · 11 ×3 · 16 ×2.
  - **Cultists:** 19 ×2 · 27 ×3 · 36 ×1.
  - **Seekers and Lurkers** pinned at 32 / 44, since one name shows.
  - **Ash Spawn:** 30 ×3 · 40 ×1. The Raven Rock attackers are 30.
  - **Haknir 55**; he shipped at **200** from the extract.
  - **Frost Giant** 32 → 38.
  - **Solstheim chest weapons:** glass and above (glass, Stalhrim, ebony, Daedric, almsivi ebony) are cut from the plain lists. They
    now sit only in boss chests, through `EHL_LVLI_SolstheimBossWeaponRare` 0x805.
- **Across tickets.**
  - **Berserkers:** vanilla's level-5 berserker sublist held the level-1 leaves, so the dropped level-1 bandit rung was still rolling.
    It is fixed.
  - **Arrows:** the CC magic-arrow leak through `LItemArrowsAll` is closed on the ranged adventurers, the Morag Tong and the Soul Cairn
    Bonemen.
- **Generator changes.** `author-bucket-d.ps1` can now build a **new** `LVLN` from a vanilla one (`From =`). `author-retargets.ps1`
  now lets `Level =` share a row with the line ops.
- **Plugin size:** 2,812 records (+58: 4 new lists, 54 overrides). The CC Daedric Invasion pack's Vigilant injector is **WD-64** (done, see below).

**Followers are built (WD-61, 2026-09-27). This is not yet verified in game.**
- **Fixed by role, set against the finished factions** (user). Requiem left them scaling. The ticket's planned tiers
  (8–21) sat under the world they walk into.
- **Levels:**

  | Group | Level |
  |---|---|
  | Standard followers (Faendal, Sven, J'zargo and the rest) | 20 |
  | Hirelings | 25 |
  | Companion whelps | 30 |
  | Housecarls, Hearthfire's three included | 35 |
  | Dawnguard followers | 38 |
  | The Circle | 45 |
  | Serana | 50 (kept) |

- **Requiem's follower grafts stay:** Uthgerd and six others 30, Mjoll 40, Roggi 20.
- **Gear is unchanged.** Every list the followers draw from is already flat.
- **Plugin size:** 2,851 records (+39 `NPC_`). See `archetype-tiers.md` §6.1.
- **Open play test:** recruit Lydia and a hireling at player level 1, `player.setlevel 40`, and check their levels do not move.

**Named bosses and the long tail are built (WD-62, 2026-09-27). This is not yet verified in game.**
- **A named boss sits at the top rung of its own type** (user).
  - Jyrik, Sigdis and Kvenel are **45**, the Deathlord after the +15 draugr raise, where Red Eagle and Curalmil already sit.
  - Captain Hargar, the Lost Knife boss and the Cragslane Butcher are **28**, the chief.
  - Sinding is **42**; the werewolf-boss list is pinned to the Vargr boss.
  - The Southfringe boss and Vals Veran are **50**, the Arch Necromancer.
- **How the named bosses own their level:** their own level, the matched rung's class and offsets, `AutoCalcStats`, and
  `Stats` dropped (the Morag Tong pattern).
- **Questline finals:** Ancano 60 (was 80) and Vyrthur 60 (was 75). Mercer, Astrid and Potema stay 50, Harkon 55/60, Miraak 65.
- **Villains still scaling:**
  - The Volkihar court template is 53, and Valerica 60.
  - Lu'ah and the Ritual Master are 50; Rulindil and Estormo 44.
  - Ulfric and Tullius are 45, Galmar and Rikke 40, Metilius 36.
- **The other 111 still-scaling NPCs** get the level vanilla gives a level-25 player, clamped to their own min and max.
- **Coverage audit:** no `PcLevelMult` actor is left in the base game or the DLC.
- **Plugin size:** 3,004 records (+153 `NPC_`; 1 `LVLN` re-authored). See `archetype-tiers.md` §7.0.

**The CC Daedric Invasion pack is handled (WD-64, 2026-09-27). This is not yet verified in game.**
- **Its Vigilants are pinned at 35**, like ours. Its three sublists had rolled 14, 19 or 35.
- **Its script never touched our lists.** It filled the pack's own Enforcer armor and crossbow lists with gated items from two
  other CC packs: Vigil Veteran armor at 30, crossbows at 18 and 35. Those five properties are stripped and the items re-added at
  level 1, along with the vanilla Vigilant gear the script also added (user: neutralize).
- **Three new masters:** `ccbgssse067-daedinv.esm` (an `.esm`, not an `.esl`), `ccmtysse002-ve.esl` and
  `ccffbsse002-crossbowpack.esl`. That makes **31 masters, 26 of them CC**.
- **Generator changes:**
  - `author-bucket-d.ps1` can pin a CC-defined `LVLN`.
  - `author-injectors.ps1` can re-add into a list that is empty on disk.
- **Plugin size:** 3,013 records (+9: the quest, 5 `LVLI`, 3 `LVLN`).
- **How the script was read:** it was pulled from the pack's BSA and disassembled with a short Python PEX reader, because
  `tools.json` has no `bsab` or `champollion` path. The pack's BSA is uncompressed.

**Owed next:** the launch verification proper (draugr tier and boss-chest loot fixed across two
player levels), then the `LvlQuestReward*` loot lists (WD-40). **Deferred (user, 2026-09-24):** the
translation loss on the 21 overridden injector quests. Preferred fix: stop overriding them and ship a
small quest that calls `Revert()` on the affected lists after the injectors run - no text touched, and it
also fixes existing saves.

**Licensing:** verbatim-copied records make the plugin a derivative of Requiem. Private use is fine;
publishing needs their permission.

---

## 11. Faction ledgers (moved from CLAUDE.md, 2026-09-27)

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
