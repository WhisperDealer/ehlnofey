# Gotchas — the full list

Moved out of CLAUDE.md on 2026-09-27 to keep it short. CLAUDE.md keeps a one-line index of the ones that
bite most often while authoring; this file holds every entry in full, with its evidence. **Add new
gotchas here**, and add a one-liner to CLAUDE.md only if a session must know it before touching records.

## Ehlnofey — records, the decompile, scripts and play

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
- **The name travels on `BaseData`, not `Traits`** (found 2026-10-01; explains every observation
  below; **not yet confirmed by an in-game edit**). A record with `BaseData` in `TemplateFlags`
  ignores its own `Name:` and inherits it from its template; without the flag it shows its own.
  Evidence `[verified]` in the data: every `EncBandit01*` record *including* `EncBandit01TemplateMelee`
  039CFD sets `BaseData`, so all 44 inherit "Bandit" from `EncBandit00Template` 039CF4 — which is why
  naming them changed nothing; `EncBandit02TemplateMelee` 01BCD9 does **not** set it, so its own
  "Bandit Outlaw" shows. Named bosses that template a generic for `Stats`/`Traits` but not `BaseData`
  (Rahgot 035351, Holgeir 03D722) keep their own names, as the game shows. **Census pages written
  before 2026-10-01 resolved names through `Traits` and report some nameplates as "none"/"unknown"
  that `BaseData` resolves** (female draugr, draugr warlocks, Falmer shamans and B variants). Until an
  in-game rename confirms it, still name every record in a set when authoring.
- **A quest alias can name a nameless boss.** An alias with `DisplayName: <MESG>` renames its
  `ForcedReference` in game, whatever the base record shows. Vampire bosses found 2026-10-01
  `[verified]` in the data: Movarth Piquine (`dunMovarthVampireBoss` 08BB91, ref 01F593, `MS14` alias
  `BossVampireMorvath` → `MS14BossName` 02EBE8), Vighar (05B830, ref 05B824,
  `FreeformFalkreathQuest03B` → 0B83C9), Lokil (00F4FF:Dawnguard.esm, ref 00FBF5, `DLC1VQ01` →
  00FC10). All three are list wrappers with `BaseData` and no name, so the record alone reads as a
  generic Master Vampire. **For a named boss, grep quest aliases for its placed ref's FormKey**
  (`ForcedReference: <ref>` followed by `DisplayName:`), not only for the base record. Census pages
  written before this may miss alias-named bosses.
- **(Superseded by the entry above; kept for its evidence.) Nobody here knows how a nameless NPC
  resolves its displayed name. Do not reason about it — put the name on every record in the set.**
  `[verified that the obvious model is wrong]`
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

- **A flag census is not a gate census.** `overview.md` and `enemy-taxonomy.md` §4 both sized the loot
  job as "1,959 of 3,075 `LVLI` are player-gated" — that is the count carrying
  `CalculateFromAllLevelsLessThanOrEqualPlayer`. Only **1,382** have any entry above level 1, and only
  **1,378** have more than one distinct entry level. **1,693 lists (55%) are flat variety pools
  carrying the flag over entries that are all level 1.** Always count the entries, not the flag.
  `[verified]`
- **Never conclude from a truncated read.** `head -40` on `LItemBanditCuirass` (`037C22`) shows forty
  consecutive `Level: 1` entries and looks like a flat pool; its gates at 6/7/8/9/19…28 are further
  down the file. Spriggit orders entries as authored, not by level. Parse the whole record — or at
  minimum `grep` for the field across it — before saying what shape it is. `[verified]`
- **Search `GameSettings/` by keyword before believing a mechanic is undocumented.** The engine names
  its own operands: `fSpecialLootMinZoneLevelMult` / `…MaxZoneLevelMult` / `…MinPCLevelMult` settled a
  question (does the zone level reach loot?) that UESP itself tags as needing verification, and turned
  up a live bone-1 leak in the process. 1,584 GMSTs exist; `ls | grep -i <concept>` is seconds.
  `[verified]`
- **A "player-visible signal" is only a differentiator if it is not collinear with one you already
  use.** `difficulty-map.md`'s first draft bumped dungeon tier on an ancient tileset
  (`LocSetNordicRuin` / `LocSetDwarvenRuin`) as well as on the type keyword — but essentially every
  `DraugrCrypt` *is* a `NordicRuin`, so the rule differentiated nothing and merely relabelled the
  whole type one tier up. Check the cross-tab before adding a signal. `[verified]`
- **`ls */ | grep` over `reference/` times out the same way `grep -rl` does.** The gotcha above
  about filename matching applies to *globbed* directory listings too — `ls Npcs | grep <id>` is
  instant, `ls */ | grep <id>` is a 2-minute timeout. Name the one directory. `[verified]`

- **`LevelModifier` is inert unless the placed ref's base resolves to an `LVLN`.** It multiplies the
  *leveled-list lookup level*, so a fixed-level NPC has nothing to modify and a `PcLevelMult` actor
  ignores zones anyway. Censusing "placed refs with no modifier" therefore massively overstates the
  exposure: across 291 zoned interior cells, 1,106 refs are unmodified but only **9** have a leveled
  ladder behind them (1,014 are fixed-level corpses/skeevers/quest NPCs, 83 are `PcLevelMult`).
  Always resolve the template chain to a terminal class before sizing a job off a field census —
  this is the "count records, not lines" gotcha one level deeper. See
  `design/probe-test-protocol.md` §4. `[verified]`
- **Spriggit's canonical field order is not the order you'd write by hand.** An `ECZN` serializes as
  `MinLevel` → `Flags` → `MaxLevel`, so hand-authoring `MinLevel`/`MaxLevel` adjacently builds a
  correct plugin that re-serializes to a *different* file, producing a phantom diff on the next
  round-trip. Fix: after the first deserialize, **re-serialize and adopt Spriggit's output as the
  source**. `[verified]`
- **Line endings will always differ between fresh Spriggit output and a checked-out working copy.**
  Spriggit 0.40 on Windows writes **CRLF**; `.gitattributes` forces `*.yaml text eol=lf`. Both are
  deliberate and neither is wrong — but it means a raw `diff -r <src> <fresh-serialize>` reports
  *every line changed* on a clean round-trip. Compare with **`diff -r --strip-trailing-cr`** (or
  `git diff`, which normalizes) and judge the round-trip on content only. Note `.gitattributes`'
  own comment says Spriggit "uses LF" — that is inaccurate for 0.40 on Windows. `[verified]`
- **`[System.IO.File]` does not use PowerShell's current directory.** `Set-Location` moves the
  PowerShell provider's location; `[Environment]::CurrentDirectory` is a separate thing and stays
  wherever the process started or was last set. So `WriteAllLines('src/…/x.yaml', …)` can silently
  resolve against an unrelated directory and throw `DirectoryNotFoundException` with a path that
  looks nonsensical (`…\reference\Base\src\Ehlnofey\…`). The same script had worked earlier in the
  session, which makes it look intermittent. **Resolve to an absolute path first**
  (`(Resolve-Path $dir).Path`) whenever mixing `[System.IO.File]` with relative paths — and note the
  BOM gotcha below means you often *have* to use it rather than `Set-Content`. `[verified]`
- **PowerShell 5.1's `Set-Content -Encoding utf8` writes a BOM; Spriggit does not.** Any record file
  authored by a script that way differs from Spriggit's output on line 1 and produces a phantom diff
  on the next round-trip. Write YAML with
  `[System.IO.File]::WriteAllLines($path, $lines, (New-Object System.Text.UTF8Encoding($false)))`.
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
  **Two CC packs inject into one shared master list.** `ccBGS_LCharUndeadListMaster` 003024:Update.esm
  is reached by `ccBGSSSE003_LvlBoneWolfZombie` 003025:Update.esm (19 Tamriel refs, 18 enable-parented
  to the initially-disabled marker `ccBGSSSE003_BoneWolfZombieREF` 003026:Update.esm). The Zombies pack
  overrides the list to its zombie melee list only, which cuts the Bone Wolf slot 003280 out. The Bone
  Wolf pack gets back in at runtime: `ccBGSSSE036_SeedQuest` (start-game enabled, run once) does `AddForm`
  of `ccBGSSSE003_LCharBonewolf` at level 2 and enables the marker. The Zombies pack does the same with
  its melee list, gated on its quest's stage 40. So the plugin data and the in-game list disagree.
  `[verified]` from the decompiled fragments, 2026-10-01. The CC `.bsa` files are in the Steam install
  (`C:/Gaming/steamapps/common/Skyrim Special Edition/Data`), not the modlist's Stock Game.
  **An empty list in a plugin can be filled at runtime from another CC pack.** The Cause
  (`ccbgssse067-daedinv.esm`) ships its Vigil Enforcer armor lists 06BFBB–06BFBE **empty**;
  `ccBGSSSE067_ContentAwareScript` (quest `ccBGSSSE067_Quest` 06BFC1, `OnInit` and `OnPlayerLoadGame`)
  uses `GetFormFromFile` to add the Vigil Enforcer pack's (`ccMTYSSE002-VE.esl`) Enforcer pieces at 1 and
  Veteran pieces at 30, or the vanilla `LItemVigilant*` lists when that pack is absent (that branch sets
  no flag, so it re-adds them on every load). It does the same for the Crossbow Pack (crossbows at 1 /
  18 / 35), the Backpacks pack and Survival Mode. An empty `LeveledItem` in a CC plugin is a signal to
  read the pack's scripts. `[verified]` from the decompiled `.pex`, 2026-10-01.
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
- **Dropping `Stats` to give a borrower its own level also drops its class, skills and offsets.** The
  `Stats` template flag carries the whole Stats tab: level, class, skills, health/magicka/stamina offsets,
  speed and auto-calc (CK wiki *Template Data*: "level, attributes, skills, and class") `[community]`.
  Records that borrow a faction list's level often carry the placeholder class `EncClassDremoraMelee`
  017008 and no `AutoCalcStats` (the vampire thralls; the Boethiah cultists, e.g. `DA02CultistF1`
  04D8D1, which takes `Stats` from `LvlBanditMelee1H` → `LCharBanditMelee1H`). Without `Stats` they
  fall back to those placeholder fields. Either follow the Morag Tong pattern (own level, the matched
  rung's class and offsets, `AutoCalcStats` on, `Stats` dropped), or keep `Stats` and repoint
  `Template` at a different rung or list. Found 2026-10-05.
- **In the decompile, match the string `- Language: English`, not `Language: English`.** The latter hits
  `TargetLanguage: English` on the line above first, and a name parse silently returns the wrong field.
  `[verified]` 2026-09-25.

## Scope, DLC and design traps

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
- **Placed refs live in two shapes; a scanner must read both** (2026-10-03, the World census). Cell
  files (`Cells/…/RecordData.yaml`) list refs at column 0 (`- MutagenObjectType: PlacedNpc`, fields
  at 2 spaces). A worldspace's **persistent cell** is nested inside the worldspace's own
  `Worldspaces/<World>/RecordData.yaml`, two spaces deeper. A column-0 split missed ~1,000 refs,
  among them Brynjolf, Maul and every carriage driver. Also bound each entry by indentation, not by
  the next `- MutagenObjectType:`: a script property inside a ref (`ScriptObjectProperty`) uses the
  same key and cuts the entry short (Severio Pelagia lost his `Base:`). A persistent ref often has no
  `PersistentLocation`; fall back to the location's `UniqueActorReferences`, then the cell's or
  worldspace's `Location:`.
- **A merchant's chest is a placed ref, not a container record** (2026-10-03, the Loot census). A
  vendor faction's `MerchantContainer:` holds the FormKey of a `PlacedObject` (Belethor:
  `09CAF9`), whose `Base:` is the `CONT` (`MerchantWhiterunBelethorsGoodsChest` `09CAF8`). Resolve
  it through a placed-ref index before reading the stock. The 240 vendor factions resolve to 146 chest records. An `LVLI`'s
  `ChanceNone` is serialized as a fraction (`0.85`), not a percentage.
- **A leveled spell list reads the caster's skill, not a level** (2026-10-03, the Level Gates census)
  `[community]`. An `LVSP` entry's `Level` is compared against the caster's skill in the spell's school
  (CK wiki *LeveledSpell*, quoted by search; not re-tested). The data agree: `DLC2ZahkriisosShockSpell`
  gates at 100 and `DLC2LSpellConjureLeftHand` at 75, unreachable by their casters' level caps (60,
  70). Every user of a multi-tier `LVSP` has `AutoCalcStats`, so its skills follow its level, and the
  player's level reaches the spell only through a `PcLevelMult` caster. Fixing the caster's level is
  enough; the `LVSP` needs no flattening. Confirm in game before relying on it.
- **Publishing generated tables to Confluence: collapse repetition, then verify by ADF** (2026-10-03,
  the Loot census). The MCP takes the page body as a tool argument, so a generated file has to be
  re-emitted verbatim. Long, highly repetitive bodies (identical rows, the same name at four levels)
  got cut off mid-row twice. Collapse first: one row per shared record, "same as X", level ranges.
  Then check: fetch the page with `contentFormat: "adf"` (the result is always large enough to be saved
  to a file) and diff each table row against the source file with a script.
- **"Uses X as its template but not for `Stats`" means it does NOT follow X's level** (2026-10-04, the
  Dragons pages). Two traps. **(a)** Phrase it as "changing X does not move it"; "changing X also needs Y"
  read as the opposite. **(b)** Before writing "no record follows X", grep the other direction too:
  records that **do** carry `Stats` from X. `EncDragon01Fire` looked like it moved nothing, yet
  Paarthurnax and the MQ206 and MQ306 dragons take its level, while `AlduinBase`, the other rungs and
  `BleakFallsDragon` only take its look. `[verified]`
- **"Unused" needs proof, and an initially disabled ref is not proof** (2026-10-04). Before dropping a
  record, check all of these: placed refs (the census sweep, or the cells of its dungeon and
  worldspace); `Template:` in `Npcs/`; `LeveledNpcs`, `Quests` (aliases, forced refs, script
  properties), `Scenes`, `Packages`, `FormLists`, `MagicEffects`, `Spells`; and `reference/scripts/psc`
  by EditorID. Grep each directory by name; a recursive grep over `reference/` times out.
  **Then check its placed ref's FormKey inside the dungeon's cell files**: a trigger box's script
  properties (`VirtualMachineAdapter` → `Object:`) can enable it. `BleakFallsDragon` (one initially
  disabled ref, owned by a quest whose own script never enables it) is a live ambush:
  `BFBdragonFlyoverSCRIPT` on a trigger outside Bleak Falls Barrow enables it once a trigger inside has
  set the quest's stage 90 and `MQ105` stage 5 has enabled the dragon marker. `DLC2DragonSkeleton` and
  `dunSkuldafnDragonDraugr` failed every check and were dropped. `[verified]`
- **A boss's loot is its death item, not its outfit** (2026-10-04, Miraak). The fight outfit and its
  leveled lists can be `NonPlayable` and never drop, and the death item can drop gear the boss never
  wears. `DLC2MiraakMQ06` → `DLC2DeathItemMiraak` (`UseAll`: every entry drops) → five reward lists
  (sword, staff, light and heavy mask, robes; tiers @1 · 45 · 60). Documenting the outfit missed
  Miraak's Sword. Start from `DeathItem:` on the fought record and walk it to the leaves. `[verified]`
- **`LVLN`/`LVLI` gate flags decide which entry rolls** `[community]`.
  `CalculateFromAllLevelsLessThanOrEqualPlayer` picks at random among **every** entry at or below the
  player's level, so a level-50 player can still roll the level-10 rung, and a stray entry rolls too
  (`DLC2LCharDragonAnyMQ06` holds the level-1 test NPC `AADeleteWhenDoneTestJeremyBig` @27). With no
  flags, the list gives the single highest entry at or below the player's level (Miraak's reward
  lists).
- **A `lvl*` wrapper NPC is a list roll in disguise** (2026-10-04). Level 1, template = an `LVLN`, nearly
  every template flag set: each spawn becomes whichever rung rolls. Its level is set on the list, not
  the wrapper. If its placed refs fill quest aliases, the alias `DisplayName` names them:
  `DLC2lvlDragon_MQ06` is Kruziikrel and Relonikiv (aliases `Dragon2`/`Dragon3` of `DLC2MQ06`, names in
  `MESG` records `02A75A`/`02A75B`).
- **Parsing `reference/` YAML in a script: normalise CRLF first.** The decompiled files have Windows line
  endings, so a regex on `\n` silently matches nothing. Read with `.replace(/\r\n/g, '\n')` (Node) or
  `tr -d '\r'` (shell). An absent enum is its default here too: a light-armour piece simply has no
  `ArmorType:` line (`DLC2MKMiraakMask1L`; its `ArmorLight` keyword `06BBD3` confirms it).
- **Auto-calc stats, for reference only: stats are out of scope** (user, 2026-10-04). Should they ever
  come back: health = race start + offset + 5 × (level − 1) + the class's share of 10 × (level − 1)
  (CK wiki *Class*; UESP *Skyrim:Classes*) reproduced `DLC2MiraakMQ06`'s stored 747 / 378 / 335 exactly
  at level 35, with magicka taking the leftover point. Skills (A. Beals' reverse-engineered method)
  came within 1–2 points of the stored ones. `[community]`

## Workspace — FOMOD, Papyrus, Spriggit

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

## Census site (`site/`, Astro)

- **A stale `astro preview` serves the old build.** A preview left running keeps port 4321, so a new
  `npx astro preview` silently moves to 4322, and a screenshot of `localhost:4321` shows the old page.
  Stop every listener first: `Get-NetTCPConnection -State Listen | ? LocalPort -in 4321..4325 |
  % { Stop-Process -Id $_.OwningProcess -Force }`. (Dev mode, `npm run dev`, hot-reloads instead.)
- **Screenshots without the Chrome extension: headless Edge.** `msedge.exe --headless=new
  --hide-scrollbars --window-size=1280,2400 --virtual-time-budget=4000 --screenshot=<path> <url>`.
  Headless windows have a minimum width, so a `--window-size=390,…` shot is clipped, not a phone
  layout. For a 375px check, screenshot a local HTML page holding the site in a 375px `<iframe>`.
- **Astro's `glob()` loader skips files whose names start with `_`**, so the group page is
  `census/<group>/group.json`, not `_group.json`.
- **The site is public.** No Jira numbers, Confluence links or page ids in `census/` or `site/src/`.
  The Confluence page ids live in `site/scripts/confluence-pages.json`, which only the renderer reads.
- **Confluence pushes: render, then send the output verbatim.** `npm run confluence -- <group>/<family>`
  is the only source of a mirror body. After pushing, diff a fresh render against what was sent.
- **Deploy:** GitHub Pages is set to build from GitHub Actions (`build_type: workflow`, enabled
  2026-10-04). **Manual deploys only**: `.github/workflows/pages.yml` has just `workflow_dispatch`, so a
  push never publishes. Run it from the Actions tab or `gh workflow run pages.yml --ref main`; the site
  at https://whisperdealer.github.io/ehlnofey/ updates in about a minute.
- **Keep GitHub actions on Node 24 majors.** The `@v4` majors of `checkout`, `cache` and
  `upload-artifact` run on the retiring Node 20 runtime and print a deprecation warning on every run.
  Since 2026-10-04 the repo uses `checkout@v7`, `cache@v6`, `upload-artifact@v7`. Before bumping, check
  `runs.using` in the action's `action.yml` at the new tag, and that every `with:` input still exists.
- See `arch-docs/skyrim-record-patterns.md` for the in-game failure modes that produce no build
  error — that list is the single highest-value read before authoring a new mechanic.
