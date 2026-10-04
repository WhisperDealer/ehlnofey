# Archetype tiers — the roster table

**Phase 4, step 2** of `flattening.md`. Once the leveled lists are flattened the tier ladder
stops indexing *places* and starts indexing *creature families*: a flattened list has one fixed
roster, and that roster is what a player meets everywhere the list is placed.

This document assigns that roster, for every archetype, once.

Read `flattening.md` first. Inputs: `tiers.md` (the ladder), `enemy-taxonomy.md` §2 (the vanilla
ladders, `[verified]`), `lore-constraints.md` §1 (the display-name hierarchy, `[verified]`).

**The ladder:** nine named power bands (below), adopted 2026-09-28 to replace `T1–T7`. The `Band` columns
in §§3–7 still carry the old T-numbers (`T1 = 4 · T2 = 8 · T3 = 14 · T4 = 21 · T5 = 30 · T6 = 40 · T7 = 50`)
until each family is revisited.

---

## 0. The power bands (user, 2026-09-28)

> **Superseded (user, 2026-10-04) by `arch-docs/bands-of-power.md`: ten bands**, Weak 1–6 · Common 7–13 ·
> Trained 14–20 · Blooded 21–27 · Experienced 28–34 · Elite 35–41 · Powerful 42–50 · Fabled 51–65 · Mythic 66–81 ·
> Legendary 82+ (data in `census/bands.json`). The nine-band table and the "open" conflict table below are kept as history.

The faction tickets (WD-43…64) put real levels from 1 to 110, so a third of the spec's bands already read
"above T7". The bands give that range one vocabulary.

| Band | Levels | Who belongs there |
|---|---|---|
| **Weak** | 1–6 | skeevers, mudcrabs, beggars, slaughterfish |
| **Common** | 7–19 | townsfolk, farmers, shopkeepers, low bandits, most wildlife, world encounters |
| **Trained** | 20–29 | bandits, Companion whelps, entry-level soldiers, guards, Forsworn, draugr, warlocks |
| **Experienced** | 30–37 | bandit bosses, Companions, most soldiers, mages, Falmer, standard Forsworn and draugr |
| **Elite** | 38–45 | Thalmor, Penitus Oculatus, Dark Brotherhood assassins, Forsworn Briarhearts, draugr Deathlords and Scourges, Falmer Warmongers and Shadowmasters |
| **Powerful** | 46–54 | vampires, Dwemer automatons, lesser Daedra, werewolves and werebears, most named bosses |
| **Fabled** | 55–67 | named Dragon Priests, the Forgemaster, vampire lords, young and low dragons, the Ebony Warrior, average Daedra |
| **Mythic** | 68–81 | dragons, greater Daedra, and more to come; Harkon lands here at ~81 |
| **Legendary** | 82+ | Miraak, Alduin |

**What the bands are:**
- **A design vocabulary, not an in-game label.** They go on the mod page and nowhere in the game: no
  nameplate or record carries a band name. In play, legibility still rests on vanilla's display names (rule 4).
- **Rows will be keyed by display name, not by faction.** One faction spans several bands (Restless Draugr is
  Trained, a Deathlord is Elite). Each family's rows are rewritten rung by rung as it is revisited.

**Decided with the bands (user, 2026-09-28):**
- **A raised rung may keep its lower-level perks.** Raising a level without re-perking is accepted, so rule 1's
  objection no longer blocks a raise. `AutoCalcStats` brings health and skills up to the new level. Perks and
  spells stay as vanilla set them, as the draugr (WD-49) and Dwemer (WD-51) raises already do.
- **Very high levels mostly add health.** Skills cap at 100, so past that point a level buys health, magicka
  and stamina rather than new capability. `[unverified]` Accepted.
- **Named bosses are handled when their family is reached.** Each one either reverts to the top rung of its
  type (the WD-62 rule) or gets a hand-set level.

**Open: move the world to fit the bands, or fit the bands to the decided world?** Several decided levels land
outside the band the table above names:

| Group | Decided level | Lands in | Band named above |
|---|---|---|---|
| Bandit mooks · chief | 5 / 9 / 14 · 28 | Weak–Common · Trained | Trained · Experienced |
| Draugr Scourge · placed Deathlords | 36 · 30 | Experienced | Elite |
| Thalmor soldier · Penitus Oculatus | 36 | Experienced | Elite |
| Falmer Warmonger boss | 54 | Powerful | Elite |
| Werewolves | 20 / 28 / 38 | Trained–Elite | Powerful |
| Vampires | 28 / 38 / 48 | Trained–Powerful | Powerful |
| Dwemer Spider Guardian | 40 | Elite | Powerful |
| Dremora | 36 / 46 | Experienced–Powerful | Fabled ("average Daedra", if that is them) |
| Dragon Priests | 50 | Powerful | Fabled |
| Dragon (lowest rung) | 50 | Powerful | Fabled / Mythic |
| Ebony Warrior | 80 | Mythic | Fabled |
| Harkon · Miraak | 55–60 · 65 | Fabled | Mythic (~81) · Legendary |

Either the faction tickets reopen and these levels move, or the band edges shift to meet them. Until this is
decided, nothing is re-levelled to fit a band.

---

## 1. Four rules that generate every row

### Rule 1 — keep vanilla's tier records exactly as they are

**Do not re-level the tier NPCs.** `enemy-taxonomy.md` §3 measured why: level and capability are
welded into the same record. `EncBandit01TemplateMelee` (L=1) is 35 health and one perk that
*reduces* its damage; `EncBandit06TemplateMelee` (L=25) is 489 health and eleven perks including the
skill-60 ranks. `[verified]` Editing a level without re-perking produces an incoherent actor, and
re-perking 300 records is a combat overhaul — an explicit non-goal.

So Ehlnofey never writes a level onto a tier record. **The only decision is which rungs stay in the
pool.** Everything Bethesda tuned is preserved, and the tier label is descriptive: it names the
nearest rung on the ladder.

### Rule 2 — flatten the gate, keep a *weighted* pool

Every surviving rung goes in at `Level: 1` with `CalculateFromAllLevelsLessThanOrEqualPlayer` set, so
all rungs are always eligible and one is drawn at random. Weight by **repeating the entry**:
`Bandit ×3` means the entry appears three times.

> **Weighting is *literal entry duplication*, not a `Count` field.** `Count` is how many actors the
> entry spawns; `CalculateForEachItemInCount` rolls each of them separately. The engine has no weight
> field, so Ehlnofey writes the duplicates out. Costs bytes, needs nothing.

### Rule 3 — a roster spans at most three adjacent tiers, and the top rung is rare

This is the bone-2 constraint doing real work. A pool spanning the whole ladder is not a fixed
difficulty, it is *random* difficulty, and a camp whose danger cannot be predicted is illegible
however fixed its distribution. Narrow band, weighted toward the middle, one visible top rung for
texture. **The archetype's tier is the band's centre**, and that is the number the player learns.

### Rule 4 — the name must match the tier

`lore-constraints.md` §1: the display names *are* the legibility mechanism. A rung stays in the pool
under its vanilla name or not at all. Where a name implies a rung above the band — Valkynaz, Volkihar
Master, Arch Conjurer — the rung is **reserved for named, summoned or boss placements**, never
dropped and never demoted.

---

## 2. The calibration check — three ladders land 1:1 on the ladder

`lore-constraints.md` §5.2 set the test: *"if a proposed tier system cannot express the Dremora ladder
cleanly, the tier system is wrong."* It expresses it exactly. `[verified]`

| Tier | `N` | **Dremora** | **Warlock** | **Vampire** |
|---|---|---|---|---|
| T1 | 4 | — | Wizard (1) | Fledgling (1) |
| T2 | 8 | **Churl** (6) | Apprentice Conjurer (6) | Vampire (6) |
| T3 | 14 | **Caitiff** (12) | Conjurer Adept (12) | Blooded (12) |
| T4 | 21 | **Kynval** (19) | Conjurer (19) | Mistwalker (20) |
| T5 | 30 | **Kynreeve** (27) | Ascendant Conjurer (27) | Nightstalker (28) |
| T6 | 40 | **Markynaz** (36) | Master Conjurer (36) | Ancient (38) |
| T7 | 50 | **Valkynaz** (46) | Arch Conjurer (46) | Volkihar (48) |

Three independent vanilla ladders, one of them documented in an in-game book, all seven rungs, no
collisions. The draugr ladder does the same across T1–T5 — unsurprising, since `tiers.md` §3 derived
the steps from it, but the Dremora and Vampire agreement is a genuine external check.

**Consequence:** the tier number is a real cross-archetype currency. That closes
`lore-constraints.md` §6.1's open question — *"is a Draugr Scourge more dangerous than a Forsworn
Ravager?"* Under this table, **yes-or-no is answerable: they are both T5, so they are equals.**
Vanilla could not answer it because the ladders were indexed by player level, not by a shared scale.

---

## 3. Class A — the tier ladders

The main table. `Vanilla rungs` are name (level) from `lore-constraints.md` §1 and
`enemy-taxonomy.md` §2, all `[verified]`. `Roster` is the flattened pool with weights.
**Bold** = the band centre, i.e. the archetype's tier.

### 3.1 Humanoid factions

| Archetype | List | Vanilla rungs | **Ehlnofey roster** | Band |
|---|---|---|---|---|
| **Bandit** | `LCharBanditMelee1H` 039CFC &c. | Bandit 1 · Outlaw 5 · Thug 9 · Highwayman 14 · Plunderer 19 · Marauder 25 | **Outlaw ×3** · **Thug ×4** · Highwayman ×2 | **T2** (T2–T3) |
| Bandit boss | `LCharBanditBoss` 03DF16 | 6 · 10 · 16 · 21 · 28 | **28 only** (pinned — see 3.1.1) | **T5** |
| **Orc melee** (hostile Orc camps) | `LCharOrcMelee` 01E780 | reuses bandit records | Highwayman ×3 · **Plunderer ×4** · Marauder ×2 (revised 2026-09-24) | **T4** (T3–T5) |
| **Forsworn** | `LCharForswornMelee1H` 01E792 + 4 siblings | Forsworn 1 · Forager 6 · Looter 14 · Pillager 24 · Ravager 34 · Warlord 46 | Forager ×1 · Looter ×3 · **Pillager ×4** · Ravager ×1 — mean 19.8 (revised WD-43) | **T4** (T2–T5) |
| Forsworn boss | `LCharForswornBossMelee1H` 0442F2 · `…BossShaman` 0442FD | Briarheart 7 · 16 · 27 · 38 · 51 | **38 only** (pinned — see 3.1.1, WD-43) | **T6** |
| **Warlock** (all five) | `LCharWarlockFire` 01E7D1 &c. (32 lists) | Novice 1 · Apprentice 6 · Adept 12 · Mage 19 · Wizard/Ascendant 27 · Pyromancer/Master 36 · Arch 46 | Mage ×2 · **Wizard ×3** · Master ×1 — mean 25.5 (WD-46) | **T4** (T4–T6) |
| Warlock boss | `LCharWarlockBossFire` 0E1018 &c. (12 lists) | 7 · 14 · 21 · 30 · 40 · 50 | **50 only** (Arch; 40 for four voice lists — WD-46) | **T7** |
| **Thalmor soldier** | `LCharThalmorMelee1H` 02B129 + 4 siblings | 4 · 12 · 20 · 28 · 36 | **36 only** (pinned — WD-48) | **T5–T6** |
| **Thalmor wizard** | `LCharThalmorMagic` 02B128 · `…MagicMale` 0ABEDD | 4 · 12 · 20 · 28 · 36 · 44 | **44 only** (pinned — WD-48) | **T6** |
| Thalmor boss | `LCharThalmorMagicBoss` 07DCA9 | 14 · 23 · 32 · 40 · 50 | **50 only** (pinned — WD-48) | **T7** |
| **Alik'r** | `LCharAlikrMelee1H` 06766F | 1 · 6 · 14 · 24 · 34 · 44 | ~~6 ×2 · 14 ×3 · 24 ×1~~ **left flat: the list feeds one ghost.** The real Alik'r are quest NPCs at **30** (Kematu 35); the `WERJ03` encounter fixed 1 → 30 (WD-56) | **T5** |
| **Vampire** | `LCharVampire` 033973 + 4 voice lists | Fledgling 1 · Vampire 6 · Blooded 12 · Mistwalker 20 · Nightstalker 28 · Ancient 38 · Volkihar 48 · Nightlord 60 (DLC1) | Nightstalker ×1 · **Ancient ×3** · Volkihar ×2 — mean 39.7 (WD-47) | **T6** (T5–T7) |
| Vampire boss | `LCharVampireBoss` 0339A9 + 3 race lists | Master Vampire 14 · 23 · 31 · 42 · Volkihar Master 53 · Nightmaster 65 (DLC1) | **65 only** (Nightmaster; pinned — WD-47) | **above T7** |
| **Werewolf** | `LCharWerewolf` 01E791 | Werewolf 1 · Savage 6 · Brute 12 · Skinwalker 20 · Beastmaster 28 · Vargr 38 | ~~12 ×2 · 20 ×3 · 28 ×1~~ **Skinwalker ×1 · Beastmaster ×3 · Vargr ×2** — mean 30 (WD-55) | **T5** (T4–T6) |
| **Silver Hand** | `EHL_LVLN_SilverHand{Melee1H,Melee2H,Missile}` 0x802–0x804 (new) | bandit rungs (no list of their own) | **Highwayman 14 ×1 · Plunderer 19 ×3 · Marauder 25 ×1** — mean 19.2; bosses (Krev) stay on the bandit chief, 28 (WD-55) | **T4** (T3–T5) |
| **Penitus Oculatus** | `LCharPenitusOculatus` 07D99F | 1 · 4 · 8 · 13 · 18 · 23 | ~~8 ×2 · 13 ×3 · 18 ×1~~ **36 only** (rung 06 raised 23 → 36, pinned — WD-56) | **T5–T6** |
| **Ghost** | `LCharGhostWizard` 104B62 | 1 · 5 · 9 · 14 · 19 · 25 | Outlaw 5 ×3 · **Thug 9 ×4** · Highwayman 14 ×2, like every other ghost (WD-56) | **T2** (T2–T3) |
| **Witch** | `LCharWitchAny` 074F9D + Fire/Ice/Storm | Witch 4 · Hag 8 → **19 · 27** | Witch ×2 · **Hag ×3** — mean 23.8 (2026-09-27) | **T4** (T4–T5) |
| **Vigilant of Stendarr** | `LCharVigilantOfStendarr` 0BFB53 (2 sublists) + 8 voice lists | 5 · 9 · 14 · 19 · 25 (not a single gate — see below) | **35 only** (rung 05 raised 25 → 35, pinned — WD-56) | **T5–T6** |
| **Dawnguard** | `LCharDawnguardMelee1H` 014281 + 3 voice lists | 1 · 5 · 9 · 14 · 19 · 25 | **38 only** (rung 06 raised 25 → 38, pinned — WD-58) | **T6** |

> **Werewolves, Silver Hand, minor factions (WD-55 / WD-56, user 2026-09-27). Verified in game by the user.**
> - **Werewolves** keep their six named rungs; the list rolls Skinwalker ×1 · Beastmaster ×3 · Vargr ×2. Sinding's boss list is
>   left for the named-boss ticket. **Werebears 30**: the three placed Snowclad Ruins werebears (were 17), the `DLC2WE07` trio (took
>   `Stats` from bandit berserkers, 5–14; now own it) and `DLC2EncWerebear` (Torkild and the Beast Stone summon, 25 → 30).
> - **Silver Hand** had no list: every `LvlSilverhand*` took `Stats` from a bandit list. They now point at three new lists built
>   from the same bandit rungs, two up from the mooks. The ambush and `MeleeAny` records lose their race/voice list and draw from the
>   one-handed list. Krev and the other two bosses stay on the bandit chief (28).
> - **Penitus Oculatus 36**, level with the Thalmor soldiers. The Katariah archers (`LvlPenitusOculatusMissileAmbush`) lacked the
>   `Stats` flag and were level 1 (vanilla bug); fixed. **Gear:** the POC left them with no bow or gear (the Imperial trap, §6):
>   the Imperial bow is back in `PenitusGearWithBow`, and the steel dagger, gold, food, drink, torch and Imperial symbol in `PenitusGear`.
> - **Vigilants 35**, pinned: every list (the two sublists that were capped at 5, the seven Hall voice lists that still rolled
>   5–25 and Dawnguard's `…NordM`) rolls rung 05 only. Carcette 45, Tolan 35 (§7). Their gear was already flat.
> - **The CC Daedric Invasion pack's Vigilants are 35 too** (WD-64). Its `LCharVigilantOfStendarr` 1B2CCD (27 placements)
>   rolls three sublists of vanilla leaves that gated 1–25, one holding only rung 03 (14). All three are pinned to rung 05.
>   Its content-aware script filled its own Enforcer armor and crossbow lists with gated items from two other CC packs
>   (Vigil Veteran armor at 30, crossbows at 18 / 35). Those list properties are stripped and the items re-added at level 1.
> - **Ghost wizards** roll the bandit ghosts' 5/9/14.
> - **Alik'r:** unchanged, except the level-1 `WERJ03` encounter (see the row).
> - **Berserkers:** vanilla's `SubCharBandit02Melee2HBerserk` held the level-1 `EncBandit01` berserkers, so the dropped level-1 bandit
>   rung still rolled 3 times in 9 for every berserker and berserker ghost. Its leaves are now the `EncBandit02` (Outlaw) ones.

**Thalmor (WD-48, user 2026-09-26). Levels and gear verified in game by the user.** A specialist force sent into Skyrim, so better than
the average soldier. Only the `EncThalmor00*` templates carry a name ("Thalmor Soldier", "Thalmor Wizard"), and every
rung leaf takes `Traits`, so no band is legible and all three are pinned.
- **Soldiers, melee and archers: 36** (rung 05), in `LCharThalmorMelee1H`, `…Melee1HFemale`, `…Missile` and the two
  Dragonborn male lists. Above every hold guard and civil-war soldier (25/30/35). The plain, shield and dual-wield
  leaves all stay. The embassy reception guards (`MQ201PartyGuard`, `…2`) templated straight onto a level-20 leaf; they
  move to the same sex's rung-05 leaf.
- **Wizards: 44** (rung 06: Chain Lightning, Incinerate, Thunderbolt, Ironflesh, storm atronach).
- **Boss wizards: 50** (`EncThalmor06MagicBossM`, +300 HP). Still named "Thalmor Wizard". Placed only as the
  Northwatch Interrogator and Agent Lorcalin, plus CC spawns.
- **Gear: Elven.** Every soldier wears plain Elven armor and carries Elven weapons, dagger, bow and shield. Every soldier list is
  pinned to its Elven entries. Wizards wear Thalmor robes with an Elven dagger.
- **Rare glass for the higher ranks only** (user): the **Justiciars** (`WEThalmorElvenArmor*`, "Thalmor Justiciar",
  the WE32/33/34 and WERoad03 patrols) draw their weapon from `EHL_LVLI_ThalmorJusticiarWeapon1H` 000800 (Elven 9 : glass
  1). Their armor comes from the Justiciar-only no-helmet outfit, which now rolls Elven with or without a helmet 9 : 9
  and glass with or without 1 : 1. The helmeted Justiciar was moved onto that outfit. Their shield stays Elven (shared).
  The **boss wizard** owns its inventory and carries `EHL_LVLI_ThalmorBossDagger` 000801 (Elven 9 : glass 1). These
  are the plugin's first new FormIDs: every Thalmor list is shared with the soldiers, and the user chose clearly named
  new lists over repurposing orphaned vanilla sublists. The Justiciar mage keeps the wizard's Elven dagger.
- **Archers had bandit bows.** `LvlThalmorMissile` does not inherit `Inventory`; its own held an iron dagger, the bandit
  bow list and iron arrows. That is the archer at the Embassy, Northwatch Keep and the Ratway. It now carries the
  Thalmor bow (Elven bow + Elven arrows) and dagger. Only the Solstheim archers and the `Enc*` leaves had the Elven bow before.
- **Loot and gold** were already flat. No quest injects into any Thalmor list (base, DLC, CC).
- **Left alone:** named Thalmor (Elenwen 30, Ancano/Rulindil/Ondolemar/Linwe `PcLevelMult`) belong to the named-boss
  ticket.
- **The CC Redguard pack's own Thalmor** (`ccEDHSSE003_*`, three soldiers) owned a fixed level 18. They are raised to 36 (user),
  which adds `ccedhsse003-redguard.esl` as a master. Their health, gear and spells are the pack's own. The other CC
  Thalmor (Bandit Armor packs) already roll the pinned lists.

**Vampires (WD-47, user 2026-09-26). Levels, mix and thralls verified in game by the user.** Vampires are immortal and carry a Daedric
prince's gift, so they sit well above the average mage (warlock mooks mean 25.5): Nightstalker ×1 · Ancient ×3 ·
Volkihar ×2 (28/38/48, mean 39.7) in `LCharVampire` and the three Dawnguard female voice lists. Every rank-and-file
leaf is female. The one male list, `DLC1LCharVampireMaleNordM`, borrows the male boss leaves at 31/42/53 with the same
weights. The Nightlord (60) is out: it would out-level Harkon.
- **Bosses are pinned to 65, the Nightmaster** (user), in `LCharVampireBoss` and the three race lists. That is
  **above Harkon** (55, 60 as Vampire Lord, `author-constants.ps1`). Flagged for the named-bosses ticket.
- **Serana** (§7, T6 = 40) was meant to sit above the generic vampire band. At 40 she now sits in the middle of it.
  Flagged for the Followers ticket.
- **Weapons:** every generic vampire carries `LItemVampireWeaponBase` (vampires only), which pointed at the bandit
  sword and war-axe lists (70% iron). It now holds steel, orcish, dwarven and elven, one sword and one war axe
  each: 25% per material, no iron, no glass.
- **Armor:** `LItemVampireAttire` holds vampire armor and enchanted vampire robes only: no Leather, Orcish, Elven or
  Glass sets.
- **Companions** (`LCharVampireCompanion`, `…Frost`): death hound, giant frostbite spider, small gargoyle and
  gargoyle. The skeever and the small spiders are dropped.
- **CC bone arrow** cut from `LItemVampireWeaponArrows`, and from the exotic-arrows vendor sublist, which sits in
  `LItemArrowsAll`. **Eight `LItemVampire*` lists are referenced by nothing**, arrows and bow included: boots,
  cuirass, gauntlets, robes, dagger, boss dagger, bow and arrows. The boss armor outfit and boss weapon list are
  also unused. Every generic vampire, boss or not, wears `vampireOutfit`.
- **Death hounds** (`LCharVampireWolf`, level 5) are unchanged.
- **Vampire's Thralls are level 25** (user, after play, 2026-09-26). A thrall owns no level. It takes `Stats` and
  `Traits` straight from a bandit ladder (`LCharBanditMelee1H`, the voice lists, missile, wizard), so it rolled the
  bandit mook rungs 5/9/14. Those lists are shared with every bandit camp, so the 37 thrall records are repointed at
  their ladder's gate-25 Marauder entry instead (`author-retargets.ps1`). That is what vanilla spawned at player
  level 25+, and class, health, race and voice come with it. **Every melee thrall is two-handed** (user): a
  vampire fights with spells or a blade and a spell, and its thrall closes in, deals damage and soaks it. That covers
  the 1H, any-melee and sword-and-shield thralls. Commoner-voice (Imperial) thralls become Nord Marauders of the same
  sex, because there is no Imperial two-handed Marauder.
  The Castle Volkihar feast thralls are non-combat and left alone.

**Warlocks (WD-46, user 2026-09-26). Levels verified in game by the user.** Mages turn up in many kinds of
place, so the band is wide: Mage ×2 · Wizard/Ascendant ×3 · Pyromancer/Master ×1 (19/27/36), across all five
schools, their `Omit01` variants and the 22 race/voice lists (32 in all). `LCharWarlockStormElfHaughtyF` gates
its level-19 rung at 18 (vanilla typo). An earlier 19×1 · 27×3 · 36×3 · 46×1 draft was dropped the same day.
- **Bosses are pinned to 50, the Arch rung** — a rung and a name no mook has. Vanilla's boss lists stop at 40;
  the `LCharWarlock07Boss*` sublists exist but vanilla never used them, so each boss list is pinned to its school's
  `07Boss` sublist. There is no Necro one, so the Necro lists take its two level-50 leaves.
- **Voice lists keep their voice.** Four have no level-50 leaf in their race and sex and are pinned at **40**:
  `…BossNecroMaleCondescending`, `…FireBossFemaleElfHaughty`, `…IceBossFemaleElfHaughty`,
  `…StormBossFemaleElfHaughty`.
- **CC necro-arts bosses** (21/30/40) stay only in `…BossNecroMaleCondescending`, as its level-40 Breton M.
- **Malkoran** (`DA03Wizard`, Rimerock Burrow) templates on `LCharWarlockBossConjurer`, so he is level 50.
- **Gear stays flat at whatever the lists already hold, low tiers included** (user: mages may carry lower-level gear).
- **Witches and Hags follow the warlocks** (user, after play 2026-09-27). They are the only NPCs named "Witch" or
  "Hag": the six `EncWitch01/02Template{Fire,Ice,Storm}` records, which own Stats and SpellList for every leaf of
  `LCharWitch*` (Darklight Tower, the hagraven nests). Vanilla fixed them at 4 and 8. **Witch = the Mage rung (19,
  +75 HP, +100 magicka), Hag = the Wizard rung (27, +100/+100)**, weighted 2 : 3 in all four lists (mean 23.8). Two
  names, two levels, so the band reads. Their spells stay low (Flames + Firebolt, Frostbite + Ice Spike or Sparks + Lightning Bolt, a ward, Oakflesh/
  Stoneflesh), as warlock gear was left alone.
- **The CC Bone Wolf pack's Necromancer** (`ccBGSSSE036_Necromancer`, ×1.2 [12–70]) is fixed at **36**, the Master
  rung: a named quest foe, below the lair bosses. His Thrall Wolves go to 12 with the Bonewolf (§5).

**Forsworn (WD-43, user 2026-09-25).** Forsworn gear is weak, so the *levels* carry the threat. That is why
the band sits a tier above the doc's first draft (mean ≈ 20). The roster spans four tiers, which WD-42 allows
per faction. The plain level-1 "Forsworn" is dropped, as the level-1 bandit was. All five rank-and-file lists
(`Melee1H`, `MeleeFemale`, `Missile`, `MissileFemale`, `Shaman`) share the roster. Briarhearts are pinned to **38**.
The shaman list rolls its Magic sublist, not the melee one.
- **Armor:** Forsworn armor at every level, unchanged. Every armor list was already Forsworn-only.
- **Low rungs:** Forsworn weapons only (`LItemForswornWeapon1H`).
- **Briarhearts and Ravagers:** `LItemForswornBossWeapon1H`, which is Forsworn ×10 · Elven ×4 · Dwarven ×4 ·
  enchanted Elven ×1 · enchanted Dwarven ×1 · Glass ×1 (≈ 5% glass, no ebony). Ravagers reach it through two
  `NPC_` retargets (`EncForsworn05TemplateMelee` 044287 and its Berserker leaf 0F961A).
- **Leave-alone lists:**
  - `LItemForswornMace`, `…BossMace`, `…Sword` and `…WarAxe` are **referenced by nothing** in base+DLC, and were
    left alone.
- **Revised after play (2026-09-26):**
  - `LItemWeaponDaggerBoss` turned out to be Forsworn-only: it is used by the `EncForsworn0NBossMagic` records
    and nothing else. So the Briarheart shaman dagger is reweighted in place: Steel 4 · Orcish 4 · Dwarven 5 ·
    Elven 5 · ench Dwarven 2 · ench Elven 2 · Glass 1 · Ebony 1. That is glass and ebony at 1 in 24 each,
    and enchanted at 1 in 12 each.
  - Archer arrows are Forsworn or iron, 50/50.
  - The 15% bonus arrow roll (`LootForswornArrows15`) now rolls the Forsworn arrow list. Before, it rolled
    `LItemArrowsAll`, which holds the CC Exotic Arrows sublist; those were the fire and ice arrows seen in play.

#### 3.1.1 The naming test — a band is only allowed where the rungs have different names

Found in play (2026-07-30): the Swindler's Den chief was a lottery. That turned out to be the
POC's first naive flatten, but investigating it exposed a rule this table had been breaking.

`flattening.md`'s legibility argument is the whole of it — *"the tier must agree
with the display name of everything in the pool"*, because with encounter zones gone the **name is
the only signal the player gets.** A ×2/×2/×1 band is therefore only legible if the three rungs
*have three names*. Test it, per family, before writing a band:

> Walk each rung's leaf to a `FULL`. A leaf with no name and no `Traits` in its `TemplateFlags`
> stops the chain — the name then falls through to the **placed reference's base**, which is a single
> record, so **every rung displays the same string**.

| Boss family | Rung names in vanilla | Verdict |
|---|---|---|
| Draugr | Overlord · Wight Lord · Scourge Lord · Death Overlord | **band OK** — 4 names, 4 rungs |
| Falmer | Skulker · Gloomlurker · Nightprowler · Shadowmaster | **band OK** |
| **Bandit** | *none* → `LvlBanditBoss` 03DF17 = "Bandit Chief" | **pinned to 28** |
| **Forsworn** | "Forsworn Briarheart" at all five rungs | **pinned to 38** (WD-43) |
| **Warlock** | nameless leaves, no `Traits` (templates are named per rung) | **pinned to 50** (WD-46) |
| **Thalmor** | "Thalmor Wizard" at all seven rungs | **pinned to 50** (WD-48) |
| **Vampire** | nameless leaves, no `Traits` (templates: "Master Vampire" ×4, then Volkihar Master, Nightmaster) | **pinned to 65** (WD-47) |

So the bandit boss is pinned to a single rung: a Bandit Chief is the same level in Swindler's Den, in
Halted Stream and on Solstheim, forever. Gate 29 appears twice in the `*M` lists (1H and 2H) and
weight 1 keeps both, so the pin costs the level spread and nothing else — the 1H/2H and per-race
variety survives.

**The rung is 28 — the top of the vanilla ladder, ≈T5 — not the T4 rung 21** (decided 2026-07-30;
21 was the first pass). This is the one row in §3.1 where the band centre is *not* the right pin.
The reasoning is the camp, not the archetype: bandit mooks sit at **T2** and there is nothing else in
a bandit camp to carry difficulty, so the chief is the only fight in it that can. Pinning at 21 left
a T2 camp with a T4 capstone — a step, but a small one against a player who has any business being
there. 28 makes the chief a genuine wall, and it is still a *vanilla* rung, so no record is invented
and the gear the rung already carries (steel, dwarven) comes with it.

This is a deliberate consequence: **bandit camps become bimodal** — trivial mooks, dangerous chief.
That is the honest shape of a fixed world where one faction spans T1–T5, and §8's "bandits become
trivial after ~T3" warning applies to the mooks only, not to the capstone.

**The mook ladder passes the test and keeps its band**: 1 · 5 · 9 · 14 really are Bandit · Bandit
Outlaw · Bandit Thug · Bandit Highwayman, four levels behind four names. Only `EncBandit01*` is
nameless, and it is the rung the placed base's own name already describes.

**The other four families are pinned too — decided 2026-09-25 (user, WD-42).** Naming the rungs
was rejected: it is unproven (the "Bandit Runt" rename never showed in game, below) and it would invent
lore vocabulary. Each faction ticket picks its family's rung, the way 28 was picked for the chief —
the camp's capstone, not necessarily the band centre.

**The level-1 rung is dropped** (revised 2026-09-24, after play; supersedes the 2026-07-30
"rare, and called Bandit Runt" revision).

The roster is now **Outlaw ×3 · Thug ×4 · Highwayman ×2** — gates 5/9/14, odds 3/9 · 4/9 · 2/9, mean
drawn level 9.1. The level-1 rung goes the way Plunderer and Marauder already had: out of every mook
list. Chiefs are unaffected (pinned at 28, §3.1.1).

The 2026-07-30 revision kept the rung at ×1 and renamed it "Bandit Runt" — the mod's first invented
display name. **It never showed in game**, first with `FULL` on the three `EncBandit01Template*`
records, then on all 44 `EncBandit01*` records (`author-names.ps1`). Level-1 bandits still read
"Bandit". The deploy was byte-identical, the name was read back from the built binary, and
`Ehlnofey.esp` loads last, so the model of how a nameless leaf resolves its `FULL` is simply wrong
(see the CLAUDE.md gotcha). A rung that cannot be named apart from the family fails the legibility
test, so it was removed rather than renamed, and the 44 `NPC_` overrides were deleted with
`author-names.ps1` — they changed nothing visible and would only have conflicted with other mods.

**Vigilants are the precedent, not the bug.** `enemy-taxonomy.md` §2.1 flags them as the one vanilla
humanoid faction that already satisfies bone 1. They need no edit and they are proof the shape works.

**Penitus Oculatus fixes itself.** Vanilla's ladder is inverted — gates reach 46 but the top tier is
level 23, so they get *relatively weaker* as the player levels `[verified]`. Flattening deletes the
inversion; no special handling.

**`LCharOrcMelee` is the only place Bandit Plunderer survives, and it is six placements.** This row
was labelled "Orc stronghold", which is half right at best. The list is reached by four base records,
and their placements across the whole base game are `[verified]`:

| Base record | Where | Count |
|---|---|---:|
| `DA06LvlOrcMelee` 08CDA2 | *The Cursed Tribe* — Largashbur, a real stronghold | 3 |
| `LvlOrcMelee` 01E7BB · `LvlOrcMelee_Aggro1024` 0D1FBA | **Rift Watchtower** | 2 |
| `LvlOrcMelee_Aggro1024` 0D1FBA | **Cracked Tusk Keep** | 1 |
| `WE24Orc` 062128 | a world encounter — spawned, never placed | 0 |

So two thirds of it is Orc-manned *bandit* forts, not strongholds. The stronghold Orcs you can walk
up to and talk to at Dushnikh Yal, Mor Khazgur and Narzulbur are **not** on this list at all — they
are unique `NPC_` records, class C, and nothing in this document touches them.

**Nothing was moved into this list.** Vanilla's `LCharOrcMelee` already held all six bandit rungs
(gates 1/5/9/14/19/25); the roster above simply bands it **one rung higher** than the ordinary bandit
list — T3 (Outlaw→Plunderer) against T2 (Bandit→Highwayman). That single-rung offset is the entire
reason Plunderer has anywhere left to appear.

**Bandit Marauder (level 25) survives in zero lists** — checked against every `LVLN` in the built
plugin. It is the one vanilla rung the mod deletes outright from ordinary spawns. `EncBandit06Boss*`
(level 28) is a different record set and is very much still in play: it is what the pinned chief
draws from.

> **Revised 2026-09-24 (user, after play): the hostile Orc camps are a band of their own.**
> `LCharOrcMelee` is now **Highwayman ×3 · Plunderer ×4 · Marauder ×2** — the ordinary roster's 3:4:2
> shape two rungs up, mean level ≈ 19. So Marauder is back, in this list only. The Largashbur defenders
> and the Old Orc no longer draw from it: `author-retargets.ps1` retargets `DA06LvlOrcMelee` and
> `WE24Orc` to `LCharBanditMeleeOrcM`, the ordinary Orc-bandit roster. The camps' archers come from
> `LCharOrcMissile`, whose Orc Hunter ranks all inherit Stats from `EncOrcHunterTemplate` 0D9447 — fixed
> at **level 1** in vanilla `[verified]`; it is raised to **19**. Bilegulch Mine's lone
> `LvlBanditMissileOrcM` (vanilla points it at a *melee* list) is retargeted to that Hunter list. The
> three ordinary Orc bandits placed from the shared `LCharBanditMeleeOrcM` inside Cracked Tusk Keep and
> outside Bilegulch are left as they are, because moving them means overriding cells.

### 3.2 Draugr — the anchor ladder

The rungs are **sublists**, not NPCs — `SubCharDraugr0N<role>` `[verified]` — so a roster is expressed
by keeping and re-weighting the sublist references. Bethesda's own head-variant weighting inside them
(`SubCharDraugr04Melee2HMSublist` repeats `HeadM01/02/03` three times each) is left untouched.

| List | Vanilla rungs | **Ehlnofey roster** | Band |
|---|---|---|---|
| `LCharDraugrMelee1HMale` 055936, `Melee2H` 01E772, `Missile` 0A6844 | Draugr 1 · Restless 6 · Wight 13 · Scourge 21 · Deathlord 30 · Ebony Deathlord 40 | `SubCharDraugr02` Restless ×3 · **`SubCharDraugr03` Wight ×3** · `SubCharDraugr04` Scourge ×2 | **T3** (T2–T4) |
| `LCharDraugrWarlockMale` 0BF7BB | 6 · 13 · 21 | 6 ×1 · **13 ×3** · 21 ×2 | **T3** (T2–T4) |
| `LCharDraugrBoss` 042480 | Overlord 7 · Wight Lord 15 · Scourge Lord 24 · Death Overlord 34 · Ebony Death Overlord 45 · Dragon Priest sublist | ~~Wight Lord ×1 · Scourge Lord ×2 · Death Overlord ×1 · Ebony ×1~~ → **Death Overlord 45 ×1 · Ebony Death Overlord 45 ×1** (revised, below) | **T7-** (pinned 45) |
| `LCharDraugrBossNoDragonPriest` 0DD9D8 | 7 · 15 · 24 · 34 · 45 | same as above | **T4** |

> **Built (WD-49, 2026-09-27).** The mook roster is as the table says, across all eleven melee and missile
> lists. The warlock lists get the same shape at 6 ×1 · 13 ×3 · 21 ×2 (they have no level-1 rung). The
> **boss row was revised by the user**. It is a four-rung band, 15 / 24 / 34 / 45 at 1 : 2 : 1 : 1 (mean 28). The
> Deathlord (30) is **not** moved into it, so both Deathlord rungs leave the game's leveled lists. They survive
> only where they are placed directly. The level-60 Dragon Priest sublist stays out of the boss list.
> The 34 and the 45 share the name "Draugr Death Overlord". Only the 45 carries Ebony, on the three lists
> that rung uses. **Every other draugr's gear tops out at ancient Nord: no ebony in any other draugr weapon
> or armor list.** Draugr corpses and the Dragon Priest carry vanilla's gold, and draugr corpses also drop bone
> meal. The Hulking Draugr stay out: DLC2Init was their only route in, and it stays stripped (user decision).
>
> **Revised the same day (user): the ranks are raised, and the boss is pinned.** This is a deliberate exception
> to rule 1. Restless, Wight and Scourge go up +15 to **21 / 28 / 36** (mean 27.4). The change is on the nine
> `EncDraugr0{2,3,4}Template{,Missile,Magic}` records that own their level. All nine have `AutoCalcStats`, so
> health and skills follow the level, but perks and spells stay as they were. At that level the mooks passed
> the boss band, so the band is dropped. The boss is now **"Draugr Death Overlord" at 45, ×1 plain and ×1
> Ebony**. `EncDraugr05TemplateBoss` is raised from 34 to 45, so the two differ only in gear. The Dragon Priests
> (50) still outrank everything in the barrow. Hand-placed Deathlords (30) now sit below the Scourge.

**Narrowed from T1–T5 to T2–T4 (2026-07-29).** The draft gave draugr the widest band in the table on
the argument that, with the tomb gone as an input, the *spread* had to carry the texture. Rejected:
a five-tier pool is not a fixed difficulty, it is a random one, and §1 rule 3 exists precisely to stop
that. A barrow is now reliably Restless→Wight→Scourge, and reads as one place rather than a lottery.

Two rungs leave the generic pool, and rule 4 says reserve rather than drop:

- **Deathlord (L=30, T5) moves to the boss list**, at ×2. That is where a player meets one in practice
  — guarding the word wall or the sarcophagus — and L=30 sits neatly between Scourge Lord (24) and
  Death Overlord (34), so the boss band absorbs it without stretching.
- **The Ebony Deathlord** (gate 40) is the same L=30 actor in better gear `[verified]` — a *gear*
  upgrade, not a tier. It follows the Deathlord into boss placements.

**One consequence to decide separately:** the plain **Draugr (L=1)** now appears in no generic pool at
all, so the archetype's own base name effectively leaves the game. That is defensible — a tomb full
of Restless Draugr is a better tomb — but it is a legibility cost under rule 4, and the cheapest
mitigation is to keep `SubCharDraugr01` ×1 on the *Missile* list only, where a weak skirmisher reads
naturally. **Flagged, not taken** (declined again in WD-49).

**And it raises the floor.** The old pool was 2/9 plain Draugr; the new floor is Restless (L=6). Every
Nordic tomb in the game gets harder at the bottom and easier at the top. **Bleak Falls Barrow is the
one to watch** — it is main-quest-critical and reached at character level ~2–5.

**Lore invariant preserved:** the Dragon Priest (fixed 50, T7) outranks every draugr in his barrow —
the boss band tops at 45. `[verified]` against `lore-constraints.md` §3. WD-49 re-checked all eleven: every
generic and named priest (Vokun, Krosis, Otar, Hevnoraak, Rahgot, Morokei, Nahkriin, Volsung, Vahlok) is a
fixed 50, and Zahkriisos is the 60 capstone. None is overridden.

**Castle Volkihar's skeletons share the draugr lists.** `DLC1VCSkeletonWarrior2h`, `…Missile1/2` and
`DLC1VCSkeletonMage` template onto `LCharDraugrMelee2HMale`, `LCharDraugrMissile` and `LCharDraugrWarlockMale`, as do
the Labyrinthian and Rannveig skeleton mages. They take only `Stats` from the list and keep their own name
("Skeleton"), so they roll the draugr **levels**: 21 / 28 / 36 since WD-49. `[verified]` from the records.

### 3.3 Falmer, Dwemer, Dremora

| Archetype | List | Vanilla rungs | **Ehlnofey roster** | Band |
|---|---|---|---|---|
| **Falmer** (melee/missile) | `LCharFalmerMelee` 01E77D | Falmer 9 · Skulker 15 · Gloomlurker 22 · Nightprowler 30 · Shadowmaster 38 | Falmer ×2 · **Skulker ×3** · Gloomlurker ×2 · Nightprowler ×1 | **T3** (T2–T5) |
| Falmer (shaman) | `LCharFalmerShaman` 01E77F | 5 · 8 · 14 · 19 · 25 | 14 ×2 · **19 ×2** · 25 ×1 | **T4** (T3–T5) |
| Falmer (boss) | `LCharFalmerBoss` 05238F | 18 · 26 · 35 · 44 | 26 ×2 · **35 ×2** · 44 ×1 | **T5** (T4–T6) |
| **Dwarven spider** | `LCharDwarvenSpider` 10EC90 | 6 · 12 · 16 | 12 ×2 · **16 ×2** | **T3** (T3–T4) |
| **Dwarven sphere** | `LCharDwarvenSphere` 10EC8F | 16 · 24 · 30 | 16 ×1 · **24 ×3** · 30 ×1 | **T4** (T4–T5) |
| **Dwarven centurion** | `LCharDwarvenCenturion` 10FCE5 | 24 · 30 · 36 | **30 ×2** · 36 ×1 | **T5** (T5–T6) |
| Dwarven mixed | `LCharDwarvenAutomaton` 01E783 | 6 · 12 · 16 · 24 · 30 · 36 | spider 16 ×3 · **sphere 24 ×3** · centurion 30 ×1 | **T4** (T4–T5) |
| **Dremora** | `LCharDremoraMelee` 01E79B · `…Missile` · `…Warlock` | Churl 6 · Caitiff 12 · Kynval 19 · Kynreeve 27 · Markynaz 36 · Valkynaz 46 | **Markynaz ×1 · Valkynaz ×1** — mean 41 (WD-52) | **T6** (T6–T7) |

> **Built (WD-50, 2026-09-27; user decisions). This replaces the three Falmer rows above.**
> - **Rank and file:** the melee, archer, spellsword and shaman lists roll Gloomlurker ×1 · Nightprowler ×3 ·
>   Shadowmaster ×2 (22/30/38, mean 31.3). That is a notch above the draugr: the hive is the deeper, harder
>   dungeon. The melee list keeps its Dawnguard heavy-armor leaf at each rung.
> - **Shamans:** they own their level, and it trailed the rung (14/19/25). The three kept rungs are raised to
>   **22 / 30 / 38**, so the caster is as strong as the fighter beside it. That closes the shaman defect.
> - **Boss:** pinned one rung above the mooks' top, to the Dawnguard **Warmonger boss, level 54** (melee and
>   spellsword, 1 : 1). The boss leaves take their name from the rung template, so a lower boss would read the
>   same as a mook. No mook is a Warmonger.
> - **Chaurus:** `DLC1LCharChaurusNoHunter` now matches `LCharChaurus` at Chaurus ×3 · Reaper ×1 (12 / 20). The
>   Chaurus Hunters and Frozen Falmer are left to the Dawnguard ticket.
> - **Unchanged:** gear and loot are Falmer material only and were already flat. No quest injects into these
>   lists.
> - **Unknown:** what a shaman's nameplate shows. Dawnguard's shaman leaves carry no name and no `Traits` flag
>   (CLAUDE.md naming gotcha).

**The Falmer shaman defect is closed by construction.** Vanilla caps shamans at 25 while melee Falmer
reach 38 `[verified]`; `lore-constraints.md` permits closing it. The rosters above put shamans at T4
and melee at T3, so the caster is now the *stronger* of the pair — which is what a hive's spellcaster
should be, and it costs nothing but rung selection.

**Automatons are the safest hard-fix in the game** (`lore-constraints.md` §3): machines in a sealed
ruin, fictionally static, with a clean Spider < Sphere < Centurion order that vanilla already honours.

> **Built (WD-51, 2026-09-27; user decisions; verified in game). This replaces the four Dwarven rows above.** The user wanted
> "Guardians on every one, average 40–50; Dwemer automatons should be deadly".
> - **Pinned to the Guardian rung, one name per list:** Spider Guardian **40** · Sphere Guardian **45** · Ballista
>   Guardian **45** (Dragonborn) · Centurion Guardian **50**. Each Guardian owns its level and has AutoCalcStats, so
>   health follows. The other rungs template on them *without* `Stats` and keep their vanilla level.
> - **Mixed list** `LCharDwarvenAutomaton`: spider ×3 · sphere ×3 · centurion ×1, mean 43.6. Vanilla's only centurion
>   there is the Master (36), so the Centurion Guardian is pinned in.
> - **Lost to the Ages** (Dawnguard `DLC1LD_*`): the spider and sphere lists roll their Guardian leaves, which take `Stats`
>   from the base Guardians. The **Forgemaster** is pinned at **60** (vanilla ×1 [36–60]).
> - **Aetherial Staff:** the summoned Sphere Guardian drops its `Stats` flag and keeps its own vanilla 24, so the
>   player's summon is not raised.
> - **Inherits the raise:** the CC "Dwarven Sphere Overseer" (`ccAFDSSE001`) takes `Stats` from the Sphere Guardian, so
>   it is 45 too.
> - **Hand-placed automatons keep vanilla levels.** A scan of every placed ref in `Cells/` and `Worldspaces/` finds 32 of
>   them: 24 plain Dwarven Spiders (12), 2 `EncDwarvenSpiderAmbush` (12), 2 Spider Workers (6), 3 Centurions (24) and 1
>   Centurion Master (36). The Master is now weaker than a Guardian. No Guardian and no Sphere Master is placed by hand.
> - **Loot:** flat, every entry at level 1 (soul-gem size follows the machine). No quest injects into these
>   lists. Automaton weapons are natural attacks, so there is no gear to fix.

**Dremora (WD-52, user 2026-09-26). Verified in game by the user.** Daedra from the planes of Oblivion. The user asked for
them to be "very high level, on par with vampires at the very least". That supersedes the T3 roster and the reservation
below. All three lists (melee, archer, warlock) roll Markynaz 36 and Valkynaz 46 evenly, mean 41. The rungs are named
differently, so the band reads in play.
- **Summoning:** a conjurer binds a Dremora by persuasion or by beating it into submission. So only the **arch
  conjurer boss (50)**, which outclasses the level-46 Dremora Lord it summons, gets Conjure Dremora Lord.
  `EncWarlock07TemplateBossConjurer` now owns its spell list, with the Dremora Lord in place of the storm atronach.
  Master conjurers (36) keep storm atronachs. In vanilla no generic conjurer summoned a Dremora.
- **Gear:** every Dremora carries enchanted Daedric (user; every Dremora weapon list is pinned to its enchanted
  Daedric entries) and wears Daedric armor. The Dremora
  warlocks' bandit weapon list was repointed to the Dremora list.
- **Atronachs** (§4): Flame ×2 · Frost ×2 · Storm ×1 (5/16/30), in `LCharAtronach` and Fellglow Keep's two lists.
  Summoned atronach levels are unchanged: flame 5/10, frost 16/24, storm 30/35.

~~**Markynaz (T6) and Valkynaz (T7) are reserved**~~ *(superseded by WD-52)*, per rule 4 and the in-game book's *"the Valkynaz are
rarely encountered on Tamriel"* `[verified]`. They appear only via conjuration and named placements —
which also satisfies `lore-constraints.md` §4 item 5: a Master Conjurer (T6) summons a Markynaz (T6),
in step.

### 3.4 Dragons and the DLC families

> **Dragon levels superseded (user, 2026-10-04).** `bands-of-power.md` now sets the dragons: low-level dragons
> Fabled (VIII), dragons Mythic (IX), Miraak 100 and Alduin 150 (Legendary, X). The dragon levels decided here and
> in the dragon rows further down (WD-53: Dragon 50 … Legendary 80, Paarthurnax 90, Odahviing 85, Alduin 100/110,
> Miraak 65) no longer stand; each dragon row in `census/dragons/*.json` carries its target band, most of them
> `proposed`. The rung levels are to be re-decided.

| Archetype | List | Vanilla rungs | **Ehlnofey roster** | Band |
|---|---|---|---|---|
| **Dragon** | `LCharDragonAny` 05EACF | Dragon 10 · Blood 20 · Frost 30 · Elder 40 · Ancient 50 · (Revered 62 · Legendary 75) | ~~Dragon ×2 · Blood ×3 · Frost ×2 · Elder ×1~~ → **Dragon 50 ×2 · Blood 55 ×3 · Frost 60 ×2 · Elder 65 ×2 · Ancient 70 ×1** (WD-53, below) | **above T7** (mean 58.5) |
| Dragon (Solstheim) | `DLC2LCharDragonAny` 036135 | + Serpentine 58 | as above · **Serpentine 72 ×2** | **above T7** (mean 60.75) |
| **Riekling** | `DLC2LCharRieklingMelee` 01B653 · `…Missile` 01B654 · `…ThirskMelee` 038AB6 | 6 · 11 · 16 · 23 | 6 ×2 · **11 ×3** · 16 ×2 (WD-59); mounted rieklings unchanged (25/32/40) | **T2** (T2–T4) |
| **Ash Spawn** | `DLC2LCharAshSpawn1H` 01B63C · `…2H` 0322BB · `…Magic` 0322C2 | Ash Spawn 20 · Skirmisher 30 · Immolator 40 (not a single gate) | **30 ×3** · Immolator 40 ×1 (20 and 30 share a name; WD-59) | **T5** (T5–T6) |
| **Cultist** | `DLC2LCharCultist` 030CDC · `…Summoner` 03564D | 12 · 19 · 27 · 36 · 46 | 19 ×2 · **27 ×3** · 36 ×1 (WD-59) | **T5** (T4–T6) |
| **Seeker** | `DLC2LCharSeeker` 028E87 | 21 · 32 · 42 | ~~21 ×1 · 32 ×3 · 42 ×1~~ **32 only** (one name shows — pinned, WD-59) | **T5** |
| **Lurker** | `DLC2LCharLurker` 01B64D | 24 · 34 · 44 · 54 | ~~34 ×2 · 44 ×2~~ **44 only** (pinned, WD-59) | **T6** |
| **Gargoyle** | `LCharGargoyle` 017704 | 13 · 25 · 43 | 13 ×1 · **25 ×3** · 43 ×1 — mean 26 (WD-58) | **T4** (T3–T6) |
| **Chaurus Hunter** | `DLC1LCharChaurusHunter` 0029A2 | 16 · 32 | ~~16 ×2 · 32 ×1~~ **16 ×1 · 32 ×1** — mean 24 (WD-58) | **T4** (T3–T5) |
| **Armored Troll** | `DLC1LCharTrollArmored` 00D0BB | 14 · 22 | ~~14 ×2 · 22 ×1~~ rungs raised: **26 ×1 · 36 ×1** — mean 31 (WD-58) | **T5** (T5–T6) |
| **Frozen Falmer / Shaman / Chaurus** | `DLC1_BF_LCharFrozen{Falmer,Shaman,Chaurus}` 015124 / 015126 / 01511A | 1 · 10 · 20 · 30 · 40 (chaurus 10–50) | **40 only** (one name each — pinned, WD-58) | **T6** |
| **Solstheim bandit** | `DLC2LCharBanditMelee1H` 01E8A9 | parallel records, 1–25 | **mirrors §3.1's mainland bandit** (5 ×3 · 9 ×4 · 14 ×2; chief 28) — already built | **T2** |

> **Dawnguard and Dragonborn families (WD-58 / WD-59, user 2026-09-27). Verified in game by the user.**
> - **Dawnguard 38**, just above the Vigilants. `DLC1EncHunterTemplate` owns Agmaer, Beleval and the Fort's guards: it is
>   38 too (WD-61 may refine the two followers). **Weapons:** in the POC every mook carried only the warhammer, because
>   the war axe had been lost from the weapon list; the Dawnguard war axe is in `LItemDawnguardWeaponAny`, 1:1 with the warhammer.
> - **Armored trolls:** the Armored Frost Troll took `Stats` from `EncTrollFrost` (every frost troll), so it owns its level now. The
>   tamed follower trolls follow both.
> - **Soul Cairn:** Keepers **50**, the Reaper **65**. The Keepers still drop their Dragonbone weapons (user:
>   a place reward, kept). The Bonemen archers' `LItemArrowsAll` (CC magic arrows) is now the bandit arrow list.
> - **Forgotten Vale:** Frozen Falmer, Frozen Shaman and Frozen Chaurus pinned at 40. The Frost Giant (50) and the Earth Mother (30)
>   are kept as place exceptions.
> - **Solstheim:** the Raven Rock attack's Ash Spawn (two `PcLevelMult` records) fixed at 30. The Frost Giant 32 → 38, level with the
>   mainland giants. **Haknir 55**. Karstaag 90 and the Ebony Warrior 80 are kept (§7).
> - **Solstheim chest loot:** the eight `DLC2LItemWeapon*` lists (plain and boss chests alike) lose glass, Stalhrim, ebony, the
>   Daedric sublists and the almsivi ebony mace and scimitar. Those 34 go into `EHL_LVLI_SolstheimBossWeaponRare` 0x805, added to the
>   three boss-chest lists (`DLC2Loot{Bandit,Draugr,Dwarven}Weapon100`), so a boss chest's weapon is glass or better 1 time in 10 (1 in 11 in Dwemer chests).
>   The Town lists keep their almsivi re-add.

> **Dragons, as built (WD-53, user 2026-09-27): endgame content, level 50 minimum, types kept.** The T4/T5 rosters above
> were superseded. Every dragon type is raised on the one template that owns its level, keeping vanilla's order and names:
> **Dragon 50 · Blood 55 · Frost 60 · Elder 65 · Ancient 70 · Serpentine 72 · Revered 75 · Legendary 80**. Every variant
> follows, because it takes `Stats` from its type: fire/frost, NoScript, the Solstheim `_MQ06` copies, Mirmulnir, Sahloknir,
> the resurrected dragons, Vulthuryol (Ancient, 70), Krosulhah (Frost/Elder/Ancient), Sahrotaar and Miraak's dragons
> (Serpentine, 72), and Naaslaarum, Voslaarum and the ice-lake list (Legendary, 80). Revered and Legendary are out of the world
> pool. The skeletal dragons and the Skuldafn dragon owned a flat 721 health, so they gain `AutoCalcStats` at 50.
> **Mirmulnir is pinned to the Dragon rung, 50** (user: the floor holds even for the first dragon; not yet play-tested at
> main-quest level). Named: **Alduin 100, Sovngarde 110, Paarthurnax 90, Odahviing 85, Durnehviir 80** (§7). The player's
> summons (Durnehviir 20, the Spectral Dragon and the Fire Wyrm) are unchanged. **Loot:** dragon death items drop dragon bones
> and scales, plus vanilla's dragon gold, gold change and 25% gem roll, and the Revered and Legendary death items keep their second
> gold roll. The 25% armor, weapon and Daedric rolls are cut: they point at game-wide All lists. No injectors.

**Apocrypha stays flat and high** — `lore-constraints.md` §3 explicitly permits it: *"one realm,
entered by one means, and Mora's servants have no reason to be graded by which book you opened."*
Seekers T5, Lurkers T6, no internal gradient.

**Solstheim's higher ceiling is kept** (`lore-constraints.md` §5.5), not normalised away: its dragons,
Lurkers and Acolytes all sit above their mainland equivalents.

---

## 4. Class B — species substitution and the biome lists

Different mechanism, different fix. `enemy-taxonomy.md` §2.3: **creature levels are already fixed on
the record**; the leveled list substitutes a *species* as the player levels. Flattening therefore does
not set a level — it fixes **which animals live where**.

| List | Vanilla substitution | **Ehlnofey roster** |
|---|---|---|
| `LCharFrostbiteSpider` 01E77C | Spider 1 → Large 6 → Giant 14 | Spider ×3 · **Large ×3** · Giant ×1 |
| `LCharBearAll` 042266 | Bear 12 → Cave 16 → Snow 20 | **Bear ×3** · Cave ×2 · Snow ×1 |
| `LCharBearPlainsForestHills` 01E796 | Bear 12 → Cave 16 | **Bear ×3** · Cave ×1 |
| `LCharSabrecat` 0FE2D5 | Sabre Cat 6 → Snowy 11 | **Sabre Cat ×3** · Snowy ×1 |
| `LCharChaurus` 01FA27 | Chaurus 12 → Reaper 20 | **Chaurus ×3** · Reaper ×1 |
| `LCharSpriggan` 10EC84 | Spriggan 8 → Matron 18 | **Spriggan ×3** · Matron ×1 |
| `LCharAtronach` 01E77A | Flame 5 → Frost 16 → Storm 30 | **Flame ×2 · Frost ×2 · Storm ×1** — summon-tier, keep the spread |
| `LCharMudcrab` 02183E | Medium 1 → Large → Giant | **Medium ×3** · Large ×2 · Giant ×1 |
| `LCharCustomIceWraithFrostTroll` 106386 | Ice Wraith 9 → Frost Troll 22 | **Ice Wraith ×2** · Frost Troll ×1 |

### 4.1 The biome ambient lists — enumerated

`flattening.md`: Bethesda **already partitions wilderness by biome** `[verified]`, so
flattening each list in place yields fixed *and* regionally varied wildlife with zero new records.
Pulled from `reference/` by `arch-docs/design/biome-rosters.ps1`. **19 lists exist**, not 18.

#### 4.1.1 The finding that decides how to flatten them

**The ambient lists are a density ramp, not a tier ladder.** They repeat the *same* creature at
successive gates, so as the player levels, more copies of the dangerous species enter the pool while
the harmless ones stay at a fixed count. `LCharAnimalForestPredator` (042297) in full `[verified]`:

```
Wolf@1 ×4  Skeever@1  SpiderLarge@6,7,8,10  Bear@12,13,13,14,14  Troll@14,15,15,16
BearCave@16,20,24,28,28,30,30,35
```

Eligible mix by player level — the same 26 entries, filtered:

| PC | eligible | mix |
|---|---|---|
| 4 | 5 | Wolf ×4 · Skeever ×1 |
| 8 | 8 | Wolf ×4 · SpiderLarge ×3 · Skeever ×1 |
| **14** | 15 | **Bear ×5 · SpiderLarge ×4 · Wolf ×4 · Troll ×1 · Skeever ×1** |
| 21 | 20 | Bear ×5 · SpiderLarge ×4 · Troll ×4 · Wolf ×4 · BearCave ×2 · Skeever ×1 |
| 30 | 25 | **BearCave ×7** · Bear ×5 · Troll ×4 · Wolf ×4 · SpiderLarge ×4 · Skeever ×1 |

Two consequences, and the first is a trap:

1. **Naive flattening inherits the level-35 mix.** Move every entry to `Level: 1` and a Falkreath
   pine wood becomes cave-bear soup — 7 of 26 draws, the *most* dangerous composition vanilla ever
   produces. The flattening must therefore **target a reference level**, not just collapse the gates.
2. **It vindicates the weighting mechanism** (§1 rule 2): vanilla weights by literal entry
   duplication, exactly as Ehlnofey will. This is not an invented technique.

> **This refines `enemy-taxonomy.md` §2.3.** That section found the wilderness *already* effectively
> deleveled above ~level 20 — *"forest predators top out at a level-16 cave bear"* — and concluded the
> overworld gradient largely exists already. **True of the species ceiling, false of the
> composition:** the species stops climbing at 16 but its *share of the pool* keeps climbing to gate
> 35. The wilderness does not stop scaling at 20; it stops introducing new animals at 20 and goes on
> concentrating the worst one.

#### 4.1.2 The rule: freeze each biome at its own tier

Each list keeps **vanilla's own eligible mix, frozen at the reference level of the tier assigned to
that biome.** Zero invention — every roster below is a filtered vanilla list, and the weights are
Bethesda's.

| List | FormKey | **Tier** | **Roster (frozen mix)** |
|---|---|---|---|
| `LCharAnimalPlainsPredator` | 042293 | **T2** | Wolf ×4 · SabreCat ×1 · Skeever ×1 |
| `LCharAnimalForestPredator` | 042297 | **T3** | Bear ×5 · SpiderLarge ×4 · Wolf ×4 · Troll ×1 · Skeever ×1 |
| `LCharAnimalCanyonPredator` | 04229B | **T3** | Bear ×4 · Wolf ×4 · SabreCat ×3 · Skeever ×1 |
| `LCharAnimalMarshPredator` | 042295 | **T3** | Chaurus ×3 · SpiderLarge ×3 · Spider ×2 · Troll ×1 |
| `LCharAnimalHills` | 01E78F | **T3** | Bear ×3 · Wolf ×3 · SabreCat ×2 · Skeever ×1 |
| `LCharAnimalCoastSnowPredator` | 0422A3 | **T3** | SabreCatSnow ×4 · WolfIce ×4 · Wolf ×2 |
| `LCharAnimalForestSnowPredator` | 042299 | **T4** | IceWraith ×4 · SabreCatSnow ×3 · SpiderSnowLarge ×3 · BearSnow ×2 · SpiderSnow ×1 |
| `LCharAnimalMountainSnowPredator` | 04229D | **T5** | IceWraith ×4 · WolfIce ×4 · BearSnow ×3 · SabreCatSnow ×3 · **TrollFrost ×3** · Wolf ×2 |
| `LCharAnimalSnowFields` | 01E78E | **T4** | WolfIce ×3 · SabreCatSnow ×2 · IceWraith ×2 · BearSnow ×1 |
| `LCharAnimalForest` | 01E790 | **T3** | Bear ×2 · SabreCat ×2 · Wolf ×1 |
| `LCharAnimalPlains` | 01E78D | **T2** | Wolf ×3 · SabreCat ×1 |
| `DLC2LCharAnimalForestPredator` | 01E1C5:DB | **T3** | Bear ×5 · **BoarWild ×4** · Wolf ×4 · Troll ×1 · Skeever ×1 |
| `DLC2LCharAnimalMountainSnowPredator` | 01E1C6:DB | **T5** | as mainland mountain, BoarWild ×4 in place of the spiders |

**The gradient falls out geographically**: plains T2 → forest / canyon / marsh / hills / coast T3 →
snowy forest and snow fields T4 → **mountains T5**. That is a legible map with no zone anywhere in it.

> **Built 2026-07-30 by the POC's `author-bucket-d.ps1`.** The cap rule stated above reproduces
> this table **exactly** for all eight flagged predator lists — verified entry-for-entry against the
> built plugin. Two rows needed a decision, because the table and the prose disagree:
>
> - **`LCharAnimalSnowFields`** is listed with `IceWraith ×2`, but Ice Wraith sits at **gate 28**,
>   above T4's own reference level of 21. The build follows the rule, not the row:
>   `WolfIce ×3 · SabreCatSnow ×2 · BearSnow ×1 · Wolf ×1`. Frost Troll is excluded either way, so
>   §4.1.2's "T5 is the only band holding `TrollFrost`" still holds.
> - **`LCharMudcrab`** appears twice with different weights — `Medium ×3` in §4's substitution table,
>   `Medium ×2` in §4.1.4. The build uses **§4's** (`Medium ×3 · Large ×2 · Giant ×1`), since §4 is
>   the canonical table for species-substitution lists.
>
> The three unflagged lists (`LCharAnimalForest`, `…Plains`, `…SnowFields`) hold one entry per
> species, so a bare cap would give a flat 1:1:1 mix — the cap decides *which* species are in and
> the table's weights are applied on top.

**Mountains at T5 are doing specific work.** `tiers.md` §8 sets the twelve `LevelGate*` globals to 1,
which removes vanilla's only systematic protection against a level-5 character meeting a frost troll.
`lore-constraints.md` §4 item 4 says the geography must then carry the warning instead: *"frost trolls
belong on mountains, and the player must be able to see the mountain."* T5 is the only band whose
frozen mix contains `TrollFrost` — it appears at gate 28 and nowhere below. **The mountain is the
warning, and it is visible from anywhere in Skyrim.**

> **Gaps built 2026-09-26 (WD-54, verified in game by the user).** A naive flatten (every entry at 1, no cap) leaves these wrong:
> - **`LCharAnimalForestSnowPredator`** held frost trolls ×3. It is now capped at T4 (21), so it has no frost troll.
> - **The Solstheim forest list** held cave bears ×8. It is now capped at T3.
> - **The Solstheim mountain list** held frost trolls ×6. It is now capped at T5, where it holds ×3.
> - **The §4 substitution rosters are now built:** spiders 3 : 3 : 1, and 1 : 1 in the two no-giant lists. Bears
>   3 : 2 : 1 and 3 : 1. Ice wraith 2 : 1 against frost troll. Spriggans 3 : 1, still without the Earth Mother.
> - **Spriggan companions** are wolves ×2 and a sabre cat, with no bears; the frost version is ice wolves ×2 and a
>   snowy sabre cat.
>
> **Frost trolls now appear only in the two mountain lists, with frost hagravens, and in their own
> `LCharCustomIceWraithFrostTroll`.** `dunClearspringTarnLCharPredator` stays a flat 1 : 1 : 1 : 1 (sabre cat, bear,
> troll, cave bear). `LCharGargoyle` belongs to WD-58.

#### 4.1.3 Seven prey lists need no edit at all

Already flat, every entry at gate 1 `[verified]`:

| List | Contents |
|---|---|
| `LCharAnimalForestPrey` 042298 · `MarshPrey` 042296 · `PlainsPrey` 042294 | `LCharElk` + `LCharDeer` |
| `LCharAnimalCanyonPrey` 04229C · `MountainSnowPrey` 0422A2 | `EncGoatWild` (L=1) |
| `LCharAnimalCoastSnowPrey` 0422A4 | `EncHorker` (L=3) |
| `LCharDeer` 0ABEDC · `LCharElk` 0DB2AC · `LCharDeerSprigganCompanion` 0D2071 | L=1 |

#### 4.1.4 The remaining ambient lists

| List | FormKey | **Tier** | **Roster** | Note |
|---|---|---|---|---|
| `LCharMudcrab` | 02183E | **T1** | Medium ×2 · Large ×2 · Giant ×1 | levels are 1 / 2 / **3** — "Giant" is a size, not a tier |
| `LCharBearPlainsForestHills` | 01E796 | **T3** | Bear ×3 · BearCave ×1 | |
| `LCharSpriggan` | 10EC84 | **T2** | Spriggan ×3 · Matron ×1 | **Dawnguard overrides this record** and adds `DLC1EncSprigganEarthMother` (L=30) at gate 30 `[verified]` — reserve it, per rule 4 |
| `LCharSprigganCompanion` | 01E776 | **T2** | Wolf ×2 · SabreCat ×1 | must track the spriggan that summons it |
| `LCharSprigganCompanionFrost` | 0640BD | **T3** | WolfIce ×2 · SabreCatSnow ×1 | |
| `LCharWitchAny` | 074F9D | ~~T2~~ **T4** | `LCharWitch01Any` ×2 · `LCharWitch02Any` ×3 | superseded 2026-09-27: warlock Mage/Wizard levels, §3.1 |

#### 4.1.5 Flattening makes the flag question moot

Three lists carry **no `Flags:` block** — `LCharAnimalForest`, `LCharAnimalPlains`,
`LCharAnimalSnowFields`, plus `LCharMudcrab`, `LCharBearPlainsForestHills` `[verified]` — so vanilla
selects only the highest qualifying rung rather than drawing from all of them
(`enemy-taxonomy.md` §1). **Once every entry sits at `Level: 1` the two behaviours coincide**: the
highest qualifying level *is* 1, and every entry is at it. So Ehlnofey does not need to normalise the
flag on any flattened list, and `enemy-taxonomy.md` §1's warning — *"Ehlnofey must not assume the flag
is uniformly set"* — stops applying to this population. It still applies to any list left gated.

**Hard lore constraint, carried:** giants, mammoths and most `PredatorFaction` wildlife are
**passive** and must stay passive (`lore-constraints.md` §4 item 1). Difficulty comes from what they
are, never from making them aggressive. A level-32 giant standing peacefully in a T1 meadow *is* the
design working.

**Species levels stay vanilla (WD-54, user 2026-09-26)**, from skeever 1 to mammoth 38, with three exceptions. **Wolves are raised to 5** (user, after play: at 2 they died
faster than mudcrabs). `EncWolf` owns the level for red, bandit and spriggan wolves; the White River Watch and trapped
wolves own theirs and move with it. **Giants
are raised to 38**, on a par with the mammoths they herd (`EncGiant01` owns the level for every generic giant, Grok and
the Largashbur and Karthspire giants). The
**hagraven is raised to 40**. At 20 it sat below the Forsworn Briarhearts (38) it commands. `EncHagraven` owns the
level for every generic hagraven and for Moira, Drascua and the Glenmoril Witches. The four named hagravens that own
their level (Melka; Ettiene, Fallaise and Isobel at the Altar of Thrond) are raised with it. A hagraven's companion
keeps no vermin: trolls ×2 and a giant spider, or frost trolls ×2 and a giant snow spider. Hag's End's own list has
no giant spider, so it rolls frost trolls only. Creature death items were already flat. No quest adds to a creature
list at runtime; WEJS20 only spawns a hagraven.

### 4.2 Creation Club creatures — WD-71 (user, 2026-09-30)

Surveyed from `reference/mods/CreationClubYaml/`; the evidence is on the Confluence pages under *Creation Club
Creatures*. Not yet built.

| Creature | Record(s) | Vanilla | **Ehlnofey** | Band |
|---|---|---|---|---|
| Goblin (one name, 9 records) | `ccBGSSSE040_EncGoblin0{1,2,3}Melee…`, `…04Hammer` | 6 | **6** (keep) | Weak |
| Blue God (goblin boss) | `ccBGSSSE040_Blorc` 0009A0 | ×1 [5–60] | **20** | Trained |
| Nix-Hound | `ccBGSSSE035_EncNixHoundEnemy` 000804 | 16 | **16** (keep) | Common |
| Frenzied Mudcrab | `ccBGSSSE001_EncMudcrab{Medium,Large,Giant}Aggressive` | 9 / 13 / 20 | **keep**; `LCharMudcrabAggressive` 0009ED flattened to Medium ×2 · Large ×2 · Giant ×1 | Common |
| Fangtusk (vampire horker) | `ccBGSSSE001_MiscWindhelm_Fangtusk` 000BF9 | ×1.25 [10–80] | **20** | Trained |
| Corrupted Spriggan | `ccBGSSSE025_EncCorruptedSpriggan{Dementia,Mania}` | ×1 [8–54] | **24** | Trained |
| Elytra Nymph | `ccBGSSSE025_ElytraNymph{Dementia,Mania}` | ×0.6, max 26 | **10** | Common |

Out of scope: the reindeer (the player's essential mount) and every pet. Out of scope means *no Ehlnofey
level*, not undocumented: the census (2026-09-30) still lists pets on their family's Confluence page, e.g. the
*Pets of Skyrim* skeever, spider, fox, goat and rabbit, as vanilla data only. No leveled list is placed in the world:
goblins, Nix-hounds, spriggans and nymphs are hand-placed, and the mudcrab list is reached only through the
`Crab_MQ2`/`MQ4` quest spawners. No quest property in the five packs points at any leveled list `[verified]`.

---

## 5. Class C — already fixed, verify and leave

No edit. Listed so the audit script knows they are deliberate. `[verified]`

| Archetype | Level | ≈ Tier |
|---|---|---|
| Skeleton · Deer · Elk | 1–2 | T1 |
| **Wolf** | **5** (vanilla 2; WD-54, user) | **T1–T2** |
| Death Hound | 5 | T2 |
| ~~Vigilant of Stendarr~~ | ~~5~~ — not class C: a five-rung ladder, now pinned at **35** (§3.1, WD-56) | T5–T6 |
| ~~Ash Spawn~~ | ~~20~~ — a 20/30/40 ladder, now **30 ×3 · 40 ×1** (§3.4, WD-59) | T5 |
| **Giant** | **38** (vanilla 32; WD-54, user: on a par with mammoths) | **T6** |
| **Hagraven** | **40** (vanilla 20; WD-54, user) | **T6** |
| **Bonewolf** (CC `ccbgssse036-petbwolf`) and its Thrall Wolves | **12** (were ×1 [5–30] / [5–60]; user 2026-09-27) | **T3** |
| Dragon Priest (all 8 Skyrim, + Vahlok) | 50 | **T7** |

---

## 6. Class D — the `PcLevelMult` actors, including followers

`tiers.md` §7 assigned the world-facing clusters and they are unchanged by the pivot — these actors
never honoured zones anyway (`engine-behaviour.md` §1), so flattening changes nothing about them.

| Cluster | Vanilla | **Ehlnofey** |
|---|---|---|
| City guards | ×1 [20–50] | ~~21 (T4)~~ **25** (WD-45) |
| Imperial / Stormcloak soldiers | ×0.25 [1–50] | ~~14 (T3)~~ **25** (WD-44) |
| Hunters (`EncHunter00Template` 073FBE, also farmers, fishermen, pilgrims, trappers) | ×0.5 [5–15] | ~~8 (T2)~~ **10** (WD-57) |
| Nightingales | ×1 [15–45] | ~~30 (T5)~~ **45** (late Thieves Guild, below Mercer 50 — WD-57) |
| `WE*` adventurers (9 templates) | ×1.1 [6–∞] | ~~8 (T2)~~ **25** (WD-57) |
| `WEThiefTemplate` · `WEAssassinTemplate` (the "marked for death" DB assassin) | ×1.1 [6–45] | **19 · 25** (WD-57) |
| Dark Brotherhood Sanctuary · Initiates | ×1 | **45–50 kept · 25** (WD-57) |
| Morag Tong (`DLC2LvlMoragTong{Melee1H,Missile}`) | bandit ladder | **30**, own `Stats`, real class (WD-57) |
| Zahkriisos | ×1 [25–60] | **60** — matches his fixed siblings |

> **World encounters and assassins (WD-57, user 2026-09-27). Verified in game by the user.** The level sits on the record that
> owns it, via `author-retargets.ps1` `Level = N` (no SkyPatcher). Also fixed: the Solstheim netch hunters `DLC2WE15Hunter` 20 (were
> ×0.75 [30–50]); `WEDL05Thug` 14, `WEDL07Madwoman` 6, `WEDL08DeepInHisCups` 12, the four DB torture victims 1. The Morag Tong had
> the placeholder class `EncClassDremoraMelee`, so they get CombatAssassin / CombatScout with their own level. The ranged adventurer
> and the Morag Tong archers carried `LItemArrowsAll` (CC magic arrows); now the bandit arrow list. The Spectral Assassin (60), the
> stray dog and Viding are left to WD-61 / WD-62.

**Lever (superseded):** SkyPatcher was the plan; the shipped architecture has no rules, so the lever is an
`NPC_` override of the record that **owns** the level — `author-retargets.ps1`, `Level = N` edits.

**Guards and soldiers — WD-44/45 (2026-09-26, user decision).** Both fixed at **25**, which beats every bandit
mook, sits just under a bandit chief (28), and is in the Forsworn Pillager (24) – Ravager (34) band. One level
for every uniform. The level lives on a handful of templates, not on the visible NPCs:

| Record | Vanilla | Before WD-44/45 | Now | Who takes Stats from it |
|---|---|---|---|---|
| `EncGuardImperialTemplate` 0F6F37 | ×1 [20–50] | untouched — **still scaling** | 25 | 167 NPCs: Imperial-held hold guards, via `LCharGuardImperial` |
| `EncGuardSonsTemplate` 0F6F38 | ×1 [20–50] | untouched — **still scaling** | 25 | 180 NPCs: Stormcloak-held hold guards, via `LCharGuardSons` |
| `EncSoldierImperialTemplate` 01FC5D | ×0.25 [1–50] | 35 (POC) | 25 | 146 NPCs: soldiers of **both** sides, forts, patrols, field COs, couriers |
| `EncSoldierSonsTemplate` 027498 | ×0.25 [1–50] | 35 (inert) | 25 (inert) | nothing — it takes Stats from 01FC5D |
| `EncSiege{Imperial,Sons}ArcherTemplate` 045BE0 / 045BE4 | ×1 [3–20] | 35 | 25 | siege archers |
| `DLC2RRGuardTemplate` 0195AF:Dragonborn | ×1 [20–50] | untouched | 25 | Raven Rock Redoran guards |
| `MQ104Soldier01–04` | ×0.5 [2–25] | untouched | 25 | the Whiterun guards at the Western Watchtower |

The nine `EncGuardImperialM0x` leaves carry `Stats` in `TemplateFlags`, so a level written on them is
**inert** — the POC set them to 25 and the guards still scaled 20–50 until WD-45. Read the flags.

**Hold guards: 25 / 30 / 35** (user decision after play, 2026-09-26: 25 lost to bandits). The nine guard
leaves per side (`EncGuardImperialM01–M09`, `EncGuardSons{F01–F03,M01–M06}`) have `Stats` dropped from their
`TemplateFlags` and own their level: three at each rung, and every voice-type sublist holds all three. Their
class, `HealthOffset` and skills match the template's, so only the level changes. **Soldiers get the same
spread**: the nine leaves each of `LCharSoldierImperial` 01FC5B and `LCharSoldierSons` 01FC5C, which every
patrol, garrison and battle soldier rolls from. The single fixed records are pinned at **30**, the spread's
average (user, 2026-09-26): the siege soldier templates (041B30, 045BE5, which now own their Stats), the siege
archers, the Redoran guards and the MQ104 guards. The table above shows the first pass at 25. (The leaves' cached skill values differ a little from the template's, because they
are baked per race; `AutoCalcStats` recomputes them in game.)
**Rank names were asked for and not built** (Trainee / Watchman / Hearth-Guard). A hold guard displays its hold
record's own name ("Whiterun Guard") even though it carries `Traits`, and the leaves are named "Imperial
Soldier", which never appears in game. So a rank name on a leaf would not display, and a guard's rank cannot be
read. That is a bone-2 gap, and it stays open until in-game testing finds which record the nameplate reads
(CLAUDE.md naming gotcha).

**Gear — unchanged (user decision).** Armor is a hold/faction uniform (outfit). Imperials carry a fixed
Imperial sword (steel tier) and Imperial bow. Stormcloaks — and Markarth/Dawnstar guards of either side, through
`GuardGear` 100561 — roll `LItemSoldierSons{Mace,Sword,Waraxe,Warhammer,Greatsword,Battleaxe}`, flattened to
iron/steel 50/50; shields are hide ×4 / steel ×4. Both mixes are kept. Only Stormcloaks, guards,
Helgen and Valmir use those lists, so a later change would need no fork. **Imperials were unarmed in the POC** (found in play, 2026-09-26): their Imperial sword, bow and dagger had
been lost from the gear lists, so `CWSoldierImperialGear` 0A6E61 carried no weapon. Every Imperial soldier and
Imperial-held guard fought with fists, and nothing warns of it. **Check every faction gear list still holds a
weapon.** The lists must carry vanilla's set: Imperial bow → `…NoTorch` 10FAFC, Imperial sword + steel
dagger → `…NoTorchNoBow` 10FAFD. The Thalmor bow sublists (07D983 Elven, 07D984 glass) had lost their bow the same way and must carry it too. No injector
touches any of these lists; the `CW` quest 019E53 holds `CWSoldier{Imperial,Sons}Gear` as script properties —
believed to hand gear out, not `AddForm` into it, **`[unverified]`** (script source not read).

**Left scaling, deliberately out of scope:** the named leaders (`CWBattle*` Tullius/Ulfric/Rikke/Galmar,
Captain Metilius — named-bosses story); the soldier mages `CWSiege{Sons,Imperial}Wizard`, which take Stats from
the apprentice warlock templates 045C60/045C5F (fixed level 6, shared with the warlock ladder); the
`dunCG*` quest soldiers (×1 [5–12]); the Sovngarde/`MQ301` soldier souls and the Kilkreath ghosts.

### 6.1 Followers — deleveled, by role, by hand

Decided in `flattening.md`: Ehlnofey makes **no ally exception** — followers are fixed like everyone else.
The roster is every recruitable follower (~68). These are hand-set, not rule-set — hand-setting is the point.

| Group | Vanilla | ~~Planned~~ | **Built (WD-61)** | Reasoning |
|---|---|---|---|---|
| Standard followers — Faendal, Sven, Golldir, Annekke, Benor, Cosnach, Borgakh, Ghorbash, Lob, Ogol, J'zargo, Derkeethus, Ahtar, Illia | ×1 [6/10–30] | ~~8–14~~ | **20** | Villagers and drifters: above every bandit mook, below a hireling |
| Hirelings — Belrand, Jenassa, Marcurio, Stenvar, Vorstag, Erik | ×1 [10–40] | ~~14~~ | **25** | Professionals who charge 500 gold: level with the `WE` adventurers |
| Junior Companions — Athis, Njada, Ria, Torvar | ×1 [5–25] | ~~14~~ | **30** | The guild's whelps still fight at the guard average |
| Housecarls — Lydia, Argis, Iona, Jordis, Calder; Hearthfire's Rayya, Valdimar, Gregor | ×1 [10–50] | ~~21~~ | **35** | Hold-appointed, at the **top** guard rung (guards 25/30/35) |
| Senior Companions — Aela, Farkas, Vilkas | ×1 [8–50] | ~~30~~ | **45** | The Circle: level with Erandur and Teldryn Sero |
| Dawnguard followers — Celann, Durak, Ingjard, Florentius | ×1 [10–∞] / [10–30] | ~~21~~ | **38** | The Dawnguard pin. Agmaer and Beleval already take 38 from `DLC1EncHunterTemplate` |
| Serana | ×1 [12–50] | ~~40~~ | **50** | Above every Volkihar mook (48), below Harkon (55/60) |

> **Built 2026-09-27 (WD-61, user). Not yet verified in game.** The planned tiers were set before the faction
> tickets and ended up under the world: a level-21 housecarl lost to the guard it was meant to equal. Each level is
> now set against a finished faction. 39 `NPC_` records own their level; none takes `Stats` from a template, so each
> is one `author-retargets.ps1` `Level = N` row. **The other followers are fixed individually:** Uthgerd,
> Kharjo, Ugor, Onmund, Brelyna, Eola, Aranea and Sorine 30, Mjoll and Cicero 40, Erandur and Teldryn 45, Frea 32,
> Ralis 28, Roggi 20, Gunmar 25. So J'zargo (20) sits below his classmates Onmund and Brelyna (30). **Gear is
> unchanged:** every outfit and inventory list the followers draw from is already flat. **Left to WD-62:** Katria
> (×0.75 [10–50]) and Adelaisa (×0.9 [6–25]), quest allies rather than recruitable followers.

**The design consequence, stated so it is chosen and not discovered:** a follower now has a *place* on
the same ladder as the world. A T3 hireling is a real asset to a character clearing T2 bandit camps
and a liability in a T5 barrow. Choosing and changing companions becomes a decision with
consequences — the fixed-world contract applied to allies.

**Flagged as untested** (`flattening.md`): nobody has played this. Revisit after step 9.

---

## 7. Named capstones — above the ladder

From `tiers.md` §8 and `enemy-taxonomy.md` §2.2/§2.5. These are the documented bone-1 exceptions and
the T7-and-above set.

| Record | FormKey | Vanilla | **Ehlnofey** |
|---|---|---|---|
| `AlduinBase` | 08E4F1 | ×1.2 [10–100] | ~~60~~ **100** (WD-53); MQ101/106/206 Alduin take `Stats` from it |
| `MQ304Alduin` | 04E9BC | ×1.2 [20–100] | **110** (WD-53): the Sovngarde fight. |
| `DLC1Durnehviir` | 0030D8:Dawnguard | ×1 [10–70] | **80** (WD-53); his summon stays 20 |
| `Paarthurnax` | 03C57C | 10 (Dragon rung) | **90** (WD-53), owns his `Stats` |
| `Odahviing` | 045920 | 20–50 (`lvlMQDragon`) | **85** (WD-53), owns his `Stats`, dragon class, `AutoCalcStats` |
| `DLC1Harkon` | 003BA7:Dawnguard | ×1.2 [10–60] | **55** |
| `DLC1HarkonCombat` | 01A93D:Dawnguard | ×1.4 [10–60] | **60** — both records or the transformation is a downgrade |
| `DLC2Miraak` | 017F7D:Dragonborn | ×1 [35–**200**] | **65** |
| `DLC2MiraakMQ06` | 01FB98:Dragonborn | ×1.1 [35–150] | **65** |
| `DLC2AcolyteZahkriisos` | 0248E8:Dragonborn | ×1 [25–60] | **60** — matches his fixed siblings |
| Dragon Priests ×8 + Vahlok | — | fixed 50 | **50 (T7)** — unchanged |
| Ahzidal, Dukaan | 0248E9, 0248E1 | fixed 60 | **60** — unchanged |
| `DLC2dunHaknir` | 01A373:Dragonborn | ×1.25 [40–75] | **55** (WD-59) |
| Karstaag · Ebony Warrior | 019665 · 0285C3:Dragonborn | fixed 90 · 80 | **90 · 80** — kept (WD-59), documented exceptions |
| `DLC01SoulCairnReaper` | 01A73E:Dawnguard | ×1.5 [10–100] | **65** (WD-58), the Nightmaster level |
| Soul Cairn Keepers ×3 | 0074F8 / 0074F9 / 007B0F:Dawnguard | ×1–1.2 [10–80] | **50** (WD-58) |
| `VigilantCarcette` | 0BFB55 | ×1 | **45** (WD-56), the Hall's keeper above her 35s |
| `DLC1VigilantTolan` | 00352D:Dawnguard | ×1 [15–30] | **35** (WD-56) |
| ~~`EncBandit04TemplateMelee`~~ | 01E60D | level 0 | **no record needed** — see below |

Harkon at 55/60 clears his own court (Volkihar 48 / Volkihar Master 53), satisfying
`lore-constraints.md` §3's purity requirement `[verified]`.

### 7.0 Named bosses and the long tail — WD-62 (2026-09-27, user). Not yet verified in game.

**The rule: a named boss sits at the top rung of its own type**, on Ehlnofey's scale. So a named draugr is a
Deathlord, and a named bandit leader is a chief.

**Questline finals** (user: one readable top tier):

| Final | Level |
|---|---|
| Mercer, Astrid, Queen Potema and Potema's Remains | 50 |
| Harkon | 55 / 60 |
| **Ancano** | **60** |
| **Vyrthur** | **60** |
| Miraak | 65 |
| Alduin | 100 |

**Named bosses that rode a faction list.** These carried the placeholder class `EncClassDremoraMelee` and no
`AutoCalcStats`. Each one now owns its level, taking the class and the health / magicka / stamina offsets of the
rung it matches, with `Stats` dropped. This is the Morag Tong pattern. Traits, spells, AI and gear still come from
the list.

| Boss | Was | **Now** | Matched rung |
|---|---|---|---|
| Jyrik Gauldurson | draugr warlock 21 / 28 / 36 | **45** | Deathlord (vanilla 30 + the draugr +15), draugr magic class, +660 health |
| Sigdis Gauldurson | draugr archer 21 / 28 / 36 | **45** | Deathlord, draugr missile class |
| Kvenel the Tongue (`DunVolunruudBoss`) | draugr melee 21 / 28 / 36 | **45** | Deathlord, draugr melee class |
| Red Eagle · Curalmil | Death Overlord boss pin | **45** | unchanged, already on the boss list |
| Captain Hargar · the Lost Knife boss · the Cragslane Butcher | bandit mooks 5 / 9 / 14 | **28** | bandit chief, +150 health |
| Ghunzul · the Traitor's Post boss | bandit chief | **28** | unchanged |
| Sinding | werewolf-boss list, all rungs 7–42 | **42** | `LCharWerewolfBoss` pinned to the Vargr boss |
| The Southfringe boss | necromancer mooks 19 / 27 / 36 | **50** | Arch Necromancer boss |
| Vals Veran | 40 (voice list with no level-50 leaf) | **50** | Arch Necromancer boss |
| Malkoran · Arondil · Sild · Kornalus · the Northwatch Interrogator | warlock / Thalmor boss pin | **50** | unchanged |
| Movarth · the Bloodlet Throne boss | vampire boss pin | **65** | unchanged |

**Villains and leaders that were still scaling:**
- Lu'ah Al-Skaven and the Ritual Master: **50**, the warlock boss.
- Rulindil and Estormo: **44**, the Thalmor wizard.
- **The Volkihar court: 53**, the Volkihar Master Vampire. Orthjolf, Vingalmo, Malkus, Hestla, Rargal and Feran take
  `Stats` from `DLC1EncVampireTemplate` and its magic and missile variants.
- Stalf, Salonia Caelia, Modhna and Namasur: **53**. Valerica: **60**.
- The civil war: Ulfric and Tullius **45**, Galmar and Rikke **40**, Metilius **36**, all above their soldiers
  (25 / 30 / 35). The `dunCG` Imperial soldiers are **30**, the fixed-soldier pin.
- Kodlak's wolf spirit: **42**, the Vargr boss. The Mistwatch "Bandit Leader": **28**.

**Everyone else that still scaled: 111 records.** These are merchants, the Cidhna prisoners, the Sovngarde souls,
Thirsk, quest extras, pets, Katria and Adelaisa. Each gets the level vanilla gives a **level-25 player**:
25 × its multiplier, clamped to its own `CalcMinLevel` / `CalcMaxLevel`. Titus Mede and Kyr own a fixed 1, as in
vanilla, and are left.

**Coverage audit: zero** `PcLevelMult` actors remain across Skyrim, Update, Dawnguard, Hearthfire and Dragonborn,
counting every record that owns its level (`scal.py`, 145 before). **Gear:** unchanged. The `LvlQuestReward*` lists,
among the 177 unreached gated lists, are left to WD-40.

### 7.1 The `EncBandit04TemplateMelee` bug is already fixed by Dragonborn.esm

**Found while authoring the record, 2026-07-29.** `[verified]` The L=0 bug is real in
`Skyrim.esm` — the record serializes with no `Level:` line and a vestigial `CalcMinLevel: 14`. But
**`Dragonborn.esm` overrides `01E60D:Skyrim.esm` and re-authors it properly**:

```yaml
  Level:
    MutagenObjectType: NpcLevel
    Level: 14          # <- present only in the Dragonborn override
  CalcMinLevel: 14
```

It also adds `Health: 318`, `Stamina: 152` and four stat values the `Skyrim.esm` record lacks. Since
Ehlnofey masters `Dragonborn.esm`, the winning record already carries the fix, and an Ehlnofey
override would be a pure ITM.

**This is CLAUDE.md's own last-wins gotcha catching a Phase 1 analysis that read the wrong file.**
The claim originates in `enemy-taxonomy.md` §1 (*"Reading the `L=0` entries"*), which read
`reference/Base/01Skyrim/`. Four documents repeat it and need correcting: `enemy-taxonomy.md` §1
and §8, `tiers.md` §10, `CLAUDE.md`'s *Useful FormKey constants* table, and
`implementation-strategy.md` §2.4.

**Caveat worth keeping:** the fix is Dragonborn's, so it holds *only because* Ehlnofey requires
Dragonborn. Anyone lifting this design onto a Skyrim-only plugin must re-add the override.

---

## 8. What this hands to the build

| | count |
|---|---|
| Class A lists to flatten (§3) | **~40** |
| Class B substitution lists (§4) | **9** |
| Class B biome + ambient lists (§4.1.2, §4.1.4) | **19** |
| Class B prey lists — **already flat, 0 edits** (§4.1.3) | 9 |
| Class C — verify only | 8 families, **0 edits** |
| Class D — SkyPatcher rules (§6) | **~6 lines** |
| Followers — hand-set `NPC_` overrides (§6.1) | **~68** |
| Named capstones (§7) | **8 records** |

**~68 leveled lists and ~76 NPC records** for the entire actor half — against ~450 for the loot half
(`flattening.md`). The actors were never the expensive part; `enemy-taxonomy.md` §6 said
so in Phase 1 (*"the dominant cost is E, not the actors at all"*) and the pivot has not changed it.

---

## 9. Open questions

1. ~~The draugr band (T1–T5) is the widest in the table and the least defended.~~ **RESOLVED
   2026-07-29 — narrowed to T2–T4**, Deathlords pushed to boss placements (§3.2). Two residual
   decisions are recorded there: whether the plain Draugr (L=1) keeps a home on the Missile list, and
   whether Bleak Falls Barrow survives a raised floor at main-quest level.

1a. **Rule 3 is violated by nine other rows, and narrowing draugr exposed it.** §1 rule 3 says a
   roster spans *"at most three adjacent tiers"*. These span four: Forsworn rank-and-file (T1–T4) and
   boss (T3–T6), Warlock (T2–T5), Vampire (T2–T5), Falmer melee (T2–T5), Dremora (T2–T5), Dragon
   (T3–T6), Gargoyle (T3–T6), Draugr boss (T3–T6). Either the rule relaxes to four, or those nine
   narrow the way draugr just did. **Decided 2026-09-25 (user, WD-42): per faction.** There is no
   blanket answer; each faction ticket decides which rungs its roster keeps and drops, and records
   the verdict in its own row above.
1b. **Whose level numbers do the rungs carry? — Decided 2026-09-25 (user, WD-42): vanilla's.** An
   `NPC_` that already has a *fixed* vanilla level keeps it; re-levelling those would be a rebalance, not
   deleveling, and belongs to the combat overhaul Ehlnofey does not take. **Only `PcLevelMult` actors get a
   new fixed level.** So every rung in this document's tables is at its vanilla level — which is what the
   tables always assumed — except where a faction ticket above raises a rung deliberately (and says so).
   The `PcLevelMult` actors are hand-set by WD-57/61/62. **Relaxed 2026-09-28 (user):** a raised rung may
   keep its lower-level perks, so raising a fixed level is now allowed. Whether to raise rungs to fit the
   power bands is still open (§0).
1c. **Boss bands whose rungs share one name — Decided 2026-09-25 (user, WD-42): pin.** See §3.1.1.
2. **Bandits become trivial after ~T3, and they are ~40% of the placed world.** That is the honest
   cost of a fixed world. The alternative — widening the bandit band — trades
   legibility for relevance. Do not decide this on paper; decide it after walking into three camps.
3. **Weights are guesses.** The rungs are `[verified]`; the ×3/×2/×1 ratios are design judgement with
   no vanilla precedent to copy, because vanilla never needed weights. Expect to retune.
4. **Follower tiers are untested as a design** (§6.1). Built at 20 / 25 / 30 / 35 / 38 / 45 (WD-61); the play verdict is still owed.
5. ~~Ambient biome rosters are sketched, not enumerated.~~ **CLOSED** — §4.1 now carries all 19 lists
   from `reference/`, and the exercise found the density-ramp trap (§4.1.1) that a sketch would have
   walked straight into. The biome *tier assignments* in §4.1.2 remain design judgement; the rosters
   themselves are vanilla's, filtered.
6. **`LCharAnimalSnowFields`, `…Forest` and `…Plains` are the three lists whose frozen rosters were
   hand-built rather than filtered**, because with no flags and one entry per gate there is no
   "eligible mix" to freeze. They are small (3–6 entries) but they are the only invented rows in §4.1.
7. **Do decided levels move to fit the power bands, or do the band edges move?** (§0, opened 2026-09-28.)
   The §0 table lists the groups that currently land outside their named band.

---

## Sources

`design/tiers.md` §§3, 6, 7, 8 (the ladder, home bands, class D, exceptions) ·
`design/flattening.md` · `world/enemy-taxonomy.md` §§1, 2.1–2.7, 3, 6
(every vanilla rung, `[verified]`) · `world/lore-constraints.md` §§1, 2, 3, 4, 5 (the name hierarchy
and the fictional constraints).
