# Faction playbook — how to run a faction ticket (WD-43 onwards)

The bandit work (WD-2x, commits `da2e4b5` → `7795f45`) and the Forsworn (WD-43, `a2c9b2e`) followed the same
steps. This is that sequence, written down so the next faction does not re-derive it. Each step names the
trap it exists to catch. Decisions (rungs, pins, weights, gear ceilings) are the user's; the playbook
decides only *what to measure before asking*.

## 1. Survey — vanilla against the plugin, list by list

For every `LChar*<Faction>*` list (the rank-and-file lists and the boss lists), print each entry's gate
and resolved EditorID, from `reference/Base/` **and** from `src/Ehlnofey/EhlnofeyESP/`.

- **Requiem did not just flatten, it re-chose.** For the Forsworn, the missile list was narrowed to
  Pillager/Ravager, the shaman list to Ravager only, both boss lists were pinned to the top rung (51), and
  the shaman boss list was pointed at the *melee* sublist. Pinned and narrowed lists look flat, so only a
  diff against vanilla shows them.
- **Say what the plugin does today** before proposing anything. The user decides against the current
  state, not against the ticket's description of it.

## 2. Rungs — levels and names, read on the template

Walk each rung to its template: `EncFoo0NTemplate{Melee,Missile,Magic,BossMelee,BossMagic}`.

- **Level and name both live on the template.** The leaves (`EncFoo0NMelee1HBretonM01`) are nameless and
  take `Stats` and `Traits` from it. In the decompile, the rung's name is the `- Language: English`
  string of the template's `Name:` block.
- **A missing `HealthOffset` means 0**, per the default-valued-scalar gotcha in CLAUDE.md.
- **Run the naming test** (`archetype-tiers.md` §3.1.1) on the boss rungs. Every rung of every boss family
  so far shares one name, so expect to pin.
- **List the rungs the lists never reach.** The Forsworn Warlord (46) is in no rank-and-file list, even in
  vanilla.

## 3. Gear — follow the template's `Items:`, not the list names

- For each rung template, read `Items:` and `DefaultOutfit:`. That is the gear actually carried. The
  Forsworn outfits held only armor. The weapons were `LItemForswornWeapon1H` on every mook rung, the boss
  weapon list on Briarhearts, and a dagger list on shamans.
- **A per-rank gear difference needs a retarget, not a list edit.** When every rank shares one weapon list,
  giving a higher rank different gear means repointing *that rank's template* `Items:` line
  (`author-retargets.ps1`). Also repoint any leaf that does **not** inherit `Inventory`. The Berserker
  leaves own their inventory.
- **Before retargeting a template, list what templates onto it.** A boss template can sit on the same
  template yet own its inventory; check its `TemplateFlags`.

## 4. Who uses this list? — grep before calling it shared, or live

A list's name is not evidence of either. `LItemWeaponDaggerBoss` sounds game-wide but is used only by the
Forsworn shaman Briarhearts. Four `LItemForswornMace`/`Sword`/`WarAxe` lists are used by nothing at all.

```bash
id=08CA38   # the list's FormID
grep -l "$id:Skyrim.esm" reference/Base/0*/{Npcs,LeveledItems,Outfits,Containers}/*.yaml \
  reference/mods/CreationClubYaml/*/{Npcs,LeveledItems}/*.yaml src/Ehlnofey/EhlnofeyESP/*/*.yaml 2>/dev/null \
  | grep -v -- "- ${id}_" | xargs -r -d '\n' -n1 basename | cut -d' ' -f1 | sort -u
```

Use the list's own master in the FormKey; for DLC lists, swap `Skyrim.esm`. No output means the list is
unused, and editing it changes nothing.

## 5. Does anything reach a game-wide list?

Walk every loot, arrow and death-item list the faction carries down to its leaves. **Any pointer into a
game-wide "All" list (`LItemArrowsAll`, …) inherits whatever the injectors re-added to it**, including CC
content. The Forsworn's 15% bonus arrow roll reached the CC Exotic Arrows that way, and it showed up in
play as fire and ice arrows. Fix it by repointing the faction's own list (add the new target, cut the old
one), not by editing the shared list.

## 6. Injector audit

Grep `Quests/` in base, DLC and CC for a `ScriptObjectProperty` whose `Object:` is any list from steps 1–5.
Properties serialize as `Object: <hex>:<master>`. The Forsworn had none; bandits had three sources (CLAUDE.md
"runtime `AddForm`" gotcha).

## 7. Implement — which generator holds what

| Change | Where |
|---|---|
| Roster: keep/drop rungs, weights, pins (`LVLN`) | `author-bucket-d.ps1`, `Add-Spec … @{ Gates = @{ gate = weight } }` |
| Add an item to a list at level 1 | `author-injectors.ps1` `$readdByPlace` |
| Remove entries by reference | `author-injectors.ps1` `$cuts` |
| Set an entry's weight (duplicate count) | `author-injectors.ps1` `$weights` |
| One-line `NPC_` edit: template, `Items:` line, level | `author-retargets.ps1` `$edits` |

Re-adds run **before** cuts and weights, so one pass can add an item and then weight it. It can also
repoint an entry: re-add the new target and cut the old one. Re-adding the same item several times with
different `Count`s works too (Forsworn arrows ×22/×15/×12). Gate weights in bucket D multiply every
entry at that gate, so a list's male/female mix survives.

## 8. Regenerate the tail only, then round-trip

Run `author-bucket-d.ps1` → `author-injectors.ps1` → `author-retargets.ps1`. **Do not re-run
`extract-requiem.ps1` for a faction change.** It pulls in the ~380-record Requiem 5.4.5 shift (CLAUDE.md),
which must be reviewed as its own change.

Then deserialize, re-serialize to scratch, and copy back only the files `diff -rq --strip-trailing-cr` flags.
The regenerated quests and orc `NPC_` show as diffs until that step; this is expected, because the
generators write the decompile's multi-language strings and Spriggit collapses them. After adoption,
`git status` should list only the faction's records. Finish with `build/Test-RecordYaml.ps1` and
`build/build.ps1`.

## 9. Close out

- Update the faction's row and paragraph in `archetype-tiers.md` §3.1, plus CLAUDE.md "Current phase".
- **Publish a faction ledger page** in the house style: levels chart, roster table, gear bars (Ehlnofey
  against vanilla at player levels 1 to 40), loot table, records table, quirks. The existing ones are in CLAUDE.md
  under "Faction ledgers". Republish it after every tweak.
- Build locally for the user's in-game test. Commit, push, comment and close the ticket only after they
  confirm.
