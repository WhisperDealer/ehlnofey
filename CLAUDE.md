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
- **Game scripts, decompiled:** `reference/scripts/psc/` (gitignored) holds all 15,161 vanilla, DLC
  and CC scripts (DLC scripts live inside `Skyrim - Misc.bsa`; CC ones in the `cc*.bsa` of the Steam
  Data folder). Grep it for script behaviour. Rebuild with `bsa-extract` (`--regex '\.pex$'`) then
  `pex-decompile`.
- **Papyrus:** Ehlnofey has no scripts yet. The toolchain (extract → decompile → compile) is in
  `README.md` and the `bsa-extract` / `pex-decompile` / `papyrus-compile` skills. Record any import
  directory a script needs here the first time it is needed.
- **Testing** in an MO2 modlist: use the `mod-deploy` skill, never copy by hand.
- **Census site:** `site/` (Astro). `npm run dev` previews at `http://localhost:4321/ehlnofey/`;
  `npm run schema` validates `census/`; `npm run confluence` renders the Confluence mirror pages.

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
census/                 # the enemy census as JSON, source of truth for migrated groups (Dragons first)
  bands.json            #   the ten bands of power; <group>/group.json + <family>.json; schema/
site/                   # Astro site that renders census/ to GitHub Pages (Node, site only)
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

**The ten bands of power** (`arch-docs/bands-of-power.md`, poster `arch-docs/Ehlnofey Level Bands.png`,
data `census/bands.json`): Weak 1–6 · Common 7–13 · Trained 14–20 · Blooded 21–27 · Experienced 28–34 ·
Elite 35–41 · Powerful 42–50 · Fabled 51–65 · Mythic 66–81 · Legendary 82+. **This is the band
authority** (user, 2026-10-04): it supersedes the nine-band table and the decided dragon levels in
`archetype-tiers.md`, which carry a superseded note.

## Current phase

**Back in design as of 2026-09-30: the enemy census.** Phase 4 (the rebuild, restarted 2026-09-27)
is **paused**. Before any more records are authored, we map every enemy and document it.

**The census site (since 2026-10-04).** The census is moving from Confluence into the repo as JSON and is
**live** at **https://whisperdealer.github.io/ehlnofey/** (Astro, `site/`; GitHub Pages builds from
Actions: `.github/workflows/pages.yml` deploys on every push to `main` that touches `census/` or `site/`).
Site and research gotchas from building it are in `gotchas.md` (§ Census site, and the 2026-10-04 research
rules).
- **`census/` is the source of truth for every migrated group**: `census/<group>/group.json` (the group
  page) plus one `<family>.json` per family page; `census/bands.json` is the home page. The schema is
  `site/src/schema.ts` (Zod); `npm run schema` regenerates `census/schema/*.schema.json` and validates
  everything, `build/Test-CensusJson.ps1` is the no-Node quick check. **Migrated so far: Dragons.** Every
  other group stays Confluence-first until it is migrated.
- **The site is public; keep it free of internal tooling** (user, 2026-10-04): no Jira ticket
  numbers (the tickets are deleted; `WD-xx` in the docs is history only) and no Confluence links or
  page ids in `census/` or `site/src/`. Confluence is internal documentation that supports the site.
- **To change a migrated page:** edit the JSON, run `npm run schema`, then `npm run confluence --
  <group>/<family>` and push its output with `updateConfluencePage` (`contentFormat: markdown`) to
  the page id in `site/scripts/confluence-pages.json`. Confluence is a mirror, never edited by hand.
- **A named boss's page** (user, 2026-10-04; Alduin and Miraak are the models): Records rows are its
  **fights**, one per place the player fights it, with `encounter` naming the place, since only those
  levels need changing. Every other copy (base record, cutscenes, test copies) goes in
  `otherRecords`, a collapsible log. **No Placed table.** Keep **Also owns its level** only when it
  says which record to edit (Alduin: `AlduinBase` moves the Throat of the World fight, Sovngarde owns
  its own); drop it otherwise (Miraak). **Its gear is what the player can loot**: a `loot` table walked
  from the fought record's **death item**, each list to its tiers, and no fight-gear tables (fight gear
  is often `NonPlayable`, and the death item can drop gear the boss never wears, e.g. Miraak's Sword).
- **Drop records nothing in the game uses** (user, 2026-10-04): not placed, no template user, and no
  list, quest, script, spell or package names it. Remove it from every page; don't list it as "not
  placed". Prove "unused" first: `gotchas.md` has the checklist (a trigger script enabled the
  "unused" `BleakFallsDragon`).
- **Linked records share a row** (user, 2026-10-04): a record the user ties to a rung's level is listed
  on that rung's row beside it, with the vanilla levels as `fixed` + `also` ("10 / 20"); the decision
  goes in `archetype-tiers.md`. Example: `BleakFallsDragon` on the Dragon row.
- **Name rows by what the player sees.** A `lvl*` wrapper whose placed refs fill quest aliases takes
  the alias `DisplayName` (Kruziikrel · Relonikiv, not "by rung"); say so in the row's `note`. File a
  named enemy by what it is, not by its DLC (Sahrotaar and Krosulhah are Unique Dragons, not Dragonborn).
- **To migrate a group:** fetch its pages, transcribe them into JSON (FormKeys always
  `<hex>:<Master>`, never bare hex; check the EditorID/FormKey pairs against the `reference/Base`
  filenames), add a target band per row, build, then re-render the Confluence pages. The version
  message names the version that holds the hand-written page.
- **Node is for the site only** (`site/`, Node ≥ 22.18, `npm ci` then `npm run dev`). The mod toolchain
  stays PowerShell 5.1 (Guardrail 8).

- **Scope, per enemy:** its **level** (and which record owns it; follow the template chain), its
  **gear** (outfit, inventory, death item, walked to the leaves), and every **leveled list** it
  resolves through (`LVLN` and `LVLI`, with entries, levels, counts and gate flags).
- **Perks are out of scope for now.** They may join the census in a later update; don't document them
  unless the user asks.
- **Stats are out of scope** (user, 2026-10-04): the mod adjusts levels only. No health, magicka,
  stamina, skills, class, AI or auto-calc on census pages (a Stats section was added to Miraak and
  removed the same day).
- **Document, don't author.** This phase writes no records in `EhlnofeyESP`. Record what vanilla
  (plus DLC and the CC masters) actually does, with FormKeys and confidence marks (Guardrails 1 and 9).
  Design changes that fall out of it go into `archetype-tiers.md` once the user decides them.
  **Census pages hold vanilla data only** (user, 2026-09-30): no Ehlnofey levels, rosters or weights
  until the census is done. Where a page had them, the version message names the version that holds them.
  **One exception, the target band** (user, 2026-10-04): every record row in `census/` JSON carries
  `target: { band, level?, status, source }`, its Ehlnofey band from `arch-docs/bands-of-power.md`.
  `decided` only where the bands doc names it or the user decides it (e.g. Alduin X 100 on the Throat
  of the World, 150 in Sovngarde; Miraak X 100); everything else is `proposed`, drawn dashed on the
  site. No levels, rosters or weights beyond that.
  **Page layout** (user, 2026-09-30; the Mudcrab page is the model): no source line (the group
  page cites the spec), just three headed tables and **no prose** (one `note` per row where needed):
  1. **Records**: Record · Name · Level, one row per *distinct* enemy. Variants that inherit their
     level are dropped, not described.
     **Also owns its level** (user, 2026-10-03; Frostbite Spider is the model): a short bullet list
     under Records, not rows. For each Records row, name every record that uses it as its template
     *without* `Stats` (so keeps its own level, e.g. the Helgen `MQ101FrostbiteSpider`), any same-race
     record with no template filed elsewhere (point to its page), and one closing bullet that the rest
     carry `Stats`. Check `TemplateFlags` across the masters and the CC plugins.
  2. **Lists that draw them**: List · Draws · Owner.
  3. **Placed only**: Name · Placed in (cell EditorID + FormKey, plus the quest alias if a quest owns
     it), for every enemy no list draws; an unused record goes here as "not placed".
  No gear, AI, faction or notes sections unless the user asks. Keep the survey notes in an earlier page
  version and name it in the version message. **Armed enemies get gear** (user, 2026-10-01; Common
  Falmer is the model): a **Gear** table (Records · Weapons · Armor · Skin), **Gear lists** (each
  weapon/outfit list walked to its leaves) and **Gear items** (whether the player can wear each one;
  skins are `NonPlayable`).
- **The census lives in Confluence** (except the groups migrated to `census/`, above). Space *WhisperDealer*
  (`~71202046a32e88a7ba474cbdae20a1db1fba60`), root page **Ehlnofey** (id `12451841`), on
  `whisperdealer.atlassian.net` through the `atlassian` MCP. The tree is **root → one group page per
  ticket (now deleted) → one child page per family**. **Factions** (user, 2026-10-02) is a top-level page
  that holds the faction groups: Forsworn, Dawnguard, Vigilants, Companions, Silver Hand, Minor
  Factions, Thalmor, Imperial Legion, Stormcloaks, Guards, Housecarls, Dark Brotherhood, Thieves Guild, College of
  Winterhold and **Sovngarde** (user, 2026-10-03: everyone found in Sovngarde; records already on another
  page get a pointer line). The groups so far: College of Winterhold (WD-90, under Factions: *Named College of Winterhold*
  (the `CollegeofWinterholdFaction` members and Savos's ghost) and *College of Winterhold Foes* (the MG07
  Enthralled Wizards); Ancano and Estormo stay on Named Thalmor, the other questline foes on their kinds'
  pages), Thieves Guild (WD-89, under Factions: *Named Thieves Guild* (the `ThievesGuildFaction` members, Mercer
  included, and Gallus) and *Thieves Guild Foes* (the Goldenglow mercenaries and Aringoth, Vald, the
  Nightingale Sentinels, the `WERJ02` holdup thieves); `WIThief` stays on Common Bandits), Dark Brotherhood (WD-88, under Factions: *Named Dark Brotherhood* (the Falkreath Sanctuary family, their
  quest and dead copies, the Dawnstar initiates) and *Dark Brotherhood Assassins* (the `WEJS28` assassins,
  `WEAssassinSubChar` PC×1.1 [6–45], the Hag's End assassin, the CC Bow of Shadows and Daedric-armor
  assassins) and *Dark Brotherhood Targets* (the `DB01`–`DB11`, side-contract and `DBrecurring` victims,
  Agnis and Maluril included; the Maros stay on Penitus Oculatus, Helvard on Jarls)), Warlocks
  (WD-87, top-level, the hostile mages: *Common Warlocks* (five schools × seven rungs, 1–46, every
  wrapper, MS06 cultists, Southfringe crew), *Warlock Bosses* (7–40; the 50
  rung is in no list; CC Necromantic Grimoire injects boss leaves), *Witches* (Witch 4, Hag 8),
  *Named Warlocks* (`DA03Wizard` is Sebastian Lort by quest alias, not Malkoran); the Soul Cairn mage
  souls are on Undead → *Soul Cairn Undead*; the CC Dawnfang Guardians are ghosts, on
  *Ghost Bosses*, by the user's call), Bandits
  (WD-86, top-level: *Common Bandits* (the six-rung ladder Bandit … Bandit Marauder, 1–25, the unnamed
  `LvlBandit*` wrappers and the gangs: Blackblood, Blood Horkers, Dainty Sload, Cragslane, Mistwatch,
  Ratway, Black-Briar, thieves, CC Saints/Seducers), *Bandit Chiefs* (boss leaves own 6/10/16/21/28;
  the 14 CC armor packs inject boss sublists into `LCharBanditBoss` at runtime), *Reavers* (the DLC2
  ladder and its bosses), *Named Bandits*, *Hired Thugs* (the three `WIThug*` records, boss ladder
  via the chief wrappers; their own page by the user's call, 2026-10-04), *Mercenaries* (user,
  2026-10-04: Taron Dreth's guards, the Silver-Blood Mercenaries, the CC puzzle-dungeon mercenaries;
  employers' mercenaries such as Goldenglow's stay with the employer); Makhel Abbas is unused and
  out of the census; the group page holds the injector table; non-bandits that
  take `Stats` from a bandit list live on their own family's page with a "borrows its level" note;
  the undecided ones are still on Uncategorised → *Bandit Level Borrowers*), Housecarls
  (WD-85, under Factions: *Player Housecarls* (the five hold housecarls and the three HearthFires
  ones) and *Jarls* (both Jarls of every hold with their housecarls; Hrongar, Bryling, Erikur are in
  the jarl faction but hold nothing)), Guards (WD-84, under
  Factions: *Hold Guards* (one combined Hold Guard row, user 2026-10-02: every guard in its hold's
  uniform, level from `LCharGuard{Imperial,Sons}`, PC×1 [20–50]; the guards in Imperial or Stormcloak
  army armour, i.e. the occupying side's garrison, and the guard-list leaves are on *Common Legion* /
  *Common Stormcloaks*), *Redoran Guards*, *Other Guards* (College Guard, East Empire Wardens and Mercenaries,
  Wizards' Guards, Kolbjorn guards), *Unique Guards* (Caius, Sinmir, Urzoga, Veleth, CC Aldepius);
  Captain Aldis stays on Named Legion; Orc stronghold members in `IsGuardFaction` are not guards),
  Imperial Legion (WD-82) and
  Stormcloaks (WD-83), under Factions, each with a *Common* page (the `LCharSoldier{Imperial,Sons}`
  lists: nine leaves at PC×0.25 [1–50], owned by `EncSoldierImperialTemplate` for both sides; every
  wrapper, the siege archers and mages, Helgen, the CC Imperial Dragon soldiers) and a *Named* page
  (*Named Legion*: Tullius, Rikke, Hadvar, Aldis, Metilius, the nine legates, the CC Imperial
  Champion; *Named Stormcloaks*: Ulfric, Galmar, Ralof, the nine field commanders, the CC Stormcloak
  Champion and Klija); the hold guards are on Guards, Thalmor (WD-81, under Factions: *Common Thalmor* (the
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
  are the AtrForge copies its quest spawns), *Barbas* and *Shadow* (the CC Shadowrend doppelgangers, which copy the player's level; user, 2026-10-03); **atronachs are out of the census** (user,
  2026-10-02); the Dremora Butler and Merchant and the Daedric Princes are not enemies; the Princes'
  mortal followers are here too, by the user's call (2026-10-02): *The Afflicted* (`DA13`, ladder 1–24,
  Orchendor), *Boethiah Cultists* (bandit ladders, CC Goldbrand, the Champion), *Hunters of Hircine*,
  *Mythic Dawn (CC)* (The Cause), *Vaermina Devotees* (Storm ladder, Orcish Invaders, Veren and Thorek) and
  *Daedric Quest Foes* (Namira's Eola, Nimphaneth, Sanyon; Molag Bal's Logrolf)), Creation Club creatures (WD-71: no group page; each is on its kind's page under
  World Creatures), Vampires (WD-72, a sub-group under Undead since 2026-10-02: *Common Vampires*, *Vampire Boss*, *Vampire Lord* (Harkon, plus Serana and Valerica by the user's call),
  *Volkihar Court*, *Vampire's Thrall*, *Death Hound*; *Gargoyle* moved to World Creatures → Monsters;
  thralls take bandit levels and gear;
  the Bloodchill Manor CC vampires are on *Common Vampires* and *Vampire Boss*),
  Dawnguard (WD-76: *Common Dawnguard* (the six-rung ladder, every rung named "Dawnguard"),
  *Dawnguard Members* (Isran and the named members), *Husky*), Vigilants (WD-77: *Common Vigilants*
  (the five-rung ladder, The Cause's Vigil Enforcers) and *Named Vigilants* (Carcette, Tyranus, Tolan,
  Adalvald, the Vigil Enforcer pack's two); vampiric Vigilants stay under Vampires), Companions
  (WD-78: *The Circle* (Kodlak, Skjor, Aela, Farkas, Vilkas), *Companions Members* and *Companion Ghosts*
  (the Ysgramor's Tomb ghosts, moved from Common Ghosts by the user's call); their
  werewolf forms are scripted race changes with no record; the wolf spirits stay under Werebeasts),
  Silver Hand (WD-79, its own group under Factions: *Common Silver Hand* and *Silver Hand Leaders*:
  wrappers that take only `Stats` from the bandit lists; Krev and the radiant camp leader are
  alias-named), Minor Factions (WD-79: single family pages **Alik'r** (the `LCharAlikr*` ladder is
  unused; the real Alik'r are `MS08`/`WERJ03` records plus the Lord's Mail CC ones, and the Redguard Elite Armaments Remnant Warriors, allies, by the user's call), **Penitus Oculatus**
  and **Morag Tong** (Dragonborn; takes `Stats` from the Reaver ladder; the Severins join by script),
  and **Ghosts of the Tribunal** (the CC pack's Temple: Ordinators, Her Hands, priests; its Erden Relvel
  is on World → *Solstheim Countryside*, its Ash Zombies on Ash), and **Miraak Cultists** (the `DLC2LCharCultist` ladder 12 · 19 ·
  27 · 36 · 46 with summoner copies; Miraak himself is on Dragons → *Miraak*, his dragons on *Unique Dragons*; his
  Acolytes, Seekers and Lurkers are not), **Blades** (Delphine, Esbern; the recruits are
  followers with no record) and **Greybeards** (the four at High Hrothgar; Paarthurnax moved to Dragons → *Unique
  Dragons*; the `MQ105PhantomFormActor` summon is on neither) and **Khajiit Caravans** (user, 2026-10-03:
  the caravan Khajiit and Grushnag; Ma'randru-jo stays on *Dark Brotherhood Targets*)), Undead (WD-73: draugr included,
  **Vampires** a sub-group (above); **Draugr** is a sub-group page with *Common Draugr*, *Draugr Warlock* and *Draugr Boss*,
  the Falmer layout; **Skeletons** likewise, with *Common Skeletons*, *Soul Cairn Undead*, *Shades* and
  *Bone Wolves (CC)*, and **Ghosts**, with *Common Ghosts*, *Ghost Bosses* and *Spectral Warhound*;
  Karstaag stays on Giant; **Ash** is a sub-group with *Ash Spawn*, *Ash Guardian* and *Ash Zombie (CC)*, undead by the
  user's call, 2026-10-01, although none of their races carries `ActorTypeUndead` and the Ash Guardian's
  carries `ActorTypeDaedra`; their summons are on Conjured → *Undead Summons*), Conjured (WD-74: anything that exists only as a summon; a placed version stays with its
  family; sub-groups **Summoned Creatures** (*Summoned Atronachs*, *Familiars & Spirit Animals*,
  *Undead Summons*, *Daedric Summons*, *Constructs & Dragons*) and **Summoned NPCs** (*Summoned
  Dremora*, *Heroes & Spirits*), each page with a "Summoned by" table: player source and NPC casters),
  Dragons (WD-91, top-level: *Common Dragons*, *Unique Dragons* (Paarthurnax included), *Alduin*,
  *Dragonborn* and *Miraak* (with his gear; Alduin and Miraak have their own pages, user 2026-10-04); **migrated to `census/dragons/`, so edit the JSON, not Confluence**), World (WD-92, top-level, user 2026-10-03: the named
  NPCs, hold by hold; one page per hold (*Haafingar*, *Hjaalmarch*, *The Pale*, *Winterhold Hold*,
  *Eastmarch*, *The Rift*, *Whiterun Hold*, *Falkreath Hold*, *The Reach*, *Solstheim*), each with a
  city child (Solitude, Morthal, Dawnstar, Winterhold, Windhelm, Riften, Whiterun, Falkreath, Markarth,
  Raven Rock; Solstheim also has *Skaal Village*, by the user's call) and a *<Hold> Countryside* child for the rest of the hold, plus an *Orc Strongholds* section (user, 2026-10-03): *Largashbur*, *Dushnikh Yal*, *Mor Khazgur*, *Narzulbur*, their residents kept off the hold pages. A resident is every named NPC
  whose home location (the `LCTN` `UniqueActorReferences`, else the placed ref's cell location) sits
  under the city's or the hold's `LCTN` tree; anyone already on another census page is left off (user,
  2026-10-03). Every hold and Solstheim mapped (the College sits under the hold LCTN but its stragglers are filed on Winterhold with the town); Thorald Gray-Mane is filed on Whiterun though his only ref is at Northwatch, by the user's call; named *enemies* with a home go here too (user, 2026-10-03), e.g. Ehlhiel and Zaharia on *Falkreath Countryside*; where a location has no hold parent the home is the nearest map marker's hold, said in the row. **World Encounters** (user, 2026-10-03) is a group under World for people met on the road: *Wanderers*, *Bounty Hunters*, *Peddlers*, *Adventurers*, *Hunters*, *Sailors*, *Couriers*, *Random Encounter NPCs*), Leveled Uniques (WD-93, top-level, user 2026-10-03: every unique weapon or armour handed out through an LVLI of copies of one named item at rising levels, e.g. Chillrend 1 · 11 · 19 · 27 · 36 · 46; 28 lists plus Miraak's four fight lists, and one CC set (Spell Knight quest reward, Iron 1 · Steel 10 · Ebony 20 through nested lists); the CC player homes' display FormLists name every vanilla variant, so collapsing a unique must keep them valid; the Amulet of Articulation's seven copies are all level 1, so random, not leveled; the rebuild will pick one static variant each), Loot (WD-94, top-level, user 2026-10-03: every
  container and merchant chest and the lists they draw, for the `flattening.md` §5.4 decision; a list is
  *gated* when it or any list under it has an entry above level 1. **Containers** (*Dungeon Chests*, *Boss
  Chests*, *Clutter Containers*, *Unique Containers*, *Ungated Containers*: 530 records, 17,059 placed
  refs, 4,680 of them drawing a gated list), **Merchants** (one page per vendor type, sorted by the
  faction's `VendorBuySellList`: 240 factions, 146 chests via `MerchantContainer`, 104 gated) and **Loot
  Lists** (the 569 lists a container names directly, split *Chest Loot* / *Shared Item* / *Flat*, and
  the 1,406 gated ladders under them by kind (gear, enchanted weapon / armour / jewellery, consumables,
  valuables, magic items); the 912 `SublistEnch*` lists collapse to 15 material-tier level patterns,
  e.g. Ebony and Stalhrim 37 · 40 · 43)), Level Gates (WD-95, top-level, user 2026-10-03: everything
  outside the leveled lists that reads the player's level, from record conditions and the decompiled
  scripts. *Encounter Gates* (the 12 `LevelGate*` globals, 7 of them read by nothing; the
  `defaultEnableEncLinkedRef` triggers; other scripted spawn gates; aliases filled by level), *Quest
  Start Gates* (15 story manager nodes, e.g. Ebony Warrior ≥ 80; quest scripts; CC
  `ccStartAfterChargenScript` quests), *Random Encounter Gates* (41 quests), *Dialogue Gates* (42
  lines), *Level-Scaled Effects* (trap effects, the exploding Dwarven spiders, Civil War ally health,
  Bloodskal, Aetherial Staff, werewolf/Vampire Lord tiers), *Level-Scaled Rewards* (Companions
  radiant and CC Fishing gold) and *Leveled Spell Lists* (the 13 multi-tier `LVSP`; they resolve by
  the caster's school skill `[community]`, which `AutoCalcStats` derives from its level, so a fixed
  NPC level fixes the spell tier)), Quest Rewards (WD-96, top-level, user 2026-10-03: every gated list
  reaching the player or an actor outside containers, NPC records and outfits, each use classified from
  the decompiled scripts. *Reward Lists* (75; the four `LvlQuestReward01`–`04` gold ladders, 250–1,800
  by level 40, sit under most generic rewards), *Reward Givers* (128 quests), *Mining and Fishing*
  (every ore vein rolls `lItemGems10`; CC fishing catches), *Alias Inventories* (21) and *Item List
  Injectors* (52 `AddForm` groups: `DLC2Init` Nordic gear into the bandit lists at 23/25, the CC armour
  and weapon packs at 1–48)), Uncategorised (WD-75: the holding group for anything that fits no group yet; the 2026-10-03 sweep of every NPC record in the masters and the 74 CC plugins against every census page put the leftovers on *Unfiled NPCs* (named: wanderers, random encounters, Sovngarde, quest NPCs, CC; the Daedric Prince voices were dropped from the census, user 2026-10-04: not enemies) and *Unfiled Leveled Wrappers* (unnamed wrappers grouped by the template they draw); audio templates, test actors, chargen presets, voice-type holders and mannequins were left out; CC enemies
  in it go one level deeper, under its **Creation Club** page, one child per pack; *Forsworn Level
  Borrowers* is retired (user, 2026-10-03): the Sanctuary Guardians are on *Dark Brotherhood
  Assassins*, Silvia on *Witches*, Moric Sidrey on *Named Vigilants*, each with a note that it takes
  `Stats` from a Forsworn list or template; 2026-10-03 re-categorisation, user: the wrappers went to
  their families, the named NPCs with a home to World, the encounter NPCs to World Encounters, the
  Soul Cairn souls to *Soul Cairn Undead*, Queen Potema to *Ghost Bosses*, the CC Shadow to Daedra →
  *Shadow*; *Warlock Level Borrowers* is retired; what stays here has no home or no decided group.
  A moved record that takes `Stats` from another family carries a "borrows its level" note). CC creatures
  are filed by kind, not by pack: CC Daedra under Daedra, CC undead under Undead, CC creatures on
  (or beside) their vanilla family's page under World Creatures (Frenzied Mudcrabs on Mudcrab,
  Fangtusk on Horker, Corrupted Spriggans on Spriggan). **Confluence titles are unique per space**, so a group and a family
  cannot share a name (the family pages are *Common Falmer* and *Common Forsworn*). The MCP has no delete: retire a
  page by retitling it `DELETE ME - <title>` and ask the user to delete it.
  A new family follows the same
  shape: a group page citing its spec section, and a child page per family. Search the tree
  (`ancestor = 12451841`) before creating a page, and update the existing page rather than duplicating it.
- **Start from what exists:** the Confluence pages, `world/enemy-taxonomy.md`,
  `world/unique-enemies.md`, the census scripts in `design/*.ps1` and `archetype-tiers.md` already cover
  much of the ground. Extend them; don't re-derive.

The rebuild resumes from the plan below once the census is done:

- **Architecture: `arch-docs/design/flattening.md` — read it first.** Its §6 is the order of work.
- **Spec: `arch-docs/design/archetype-tiers.md`** — every family's levels, rosters, weights, pins and
  gear, decided by the user faction by faction (the WD-43…64 tickets, now deleted).
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
- **"Template without `Stats`" = does not follow its level.** Before saying no record follows X, grep
  for records that *do* carry `Stats` from X (Paarthurnax follows `EncDragon01Fire`; Alduin does not).
- **An initially disabled ref is not an unused one.** A trigger script in the dungeon's cells can
  enable it (`BleakFallsDragon`); check placed refs' script properties before dropping a record.
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
