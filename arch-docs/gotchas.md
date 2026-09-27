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
- See `arch-docs/skyrim-record-patterns.md` for the in-game failure modes that produce no build
  error — that list is the single highest-value read before authoring a new mechanic.
