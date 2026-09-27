# The vanilla scaling machinery — levers and FormKey constants

Moved out of CLAUDE.md on 2026-09-27. The levers a deleveling mod has to touch, and the FormKeys worth
having to hand. `flattening.md` says which levers Ehlnofey actually pulls.

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
