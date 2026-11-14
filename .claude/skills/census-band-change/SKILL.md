---
name: census-band-change
description: Apply the user's band decisions to the census ("move X to elite", "make Y level 30", "split Z out", "move W to another page", "a new page called ..."). Use whenever the user gives target bands or levels for census rows, or asks to move rows between census pages. Applies them with the census:edit script, records them in archetype-tiers.md §7.0, validates, and syncs the Confluence mirrors.
---

# Census band changes

The user decides bands in plain words, often a dozen at once. Apply them with
`site/scripts/census-edit.ts` (`npm run census:edit -- ...` in `site/`), never by hand-editing JSON
or writing a one-off script.

## Bands

Weak I 1–6 · Common II 7–13 · Trained III 14–20 · Blooded IV 21–27 · Experienced V 28–34 ·
Elite VI 35–41 · Powerful VII 42–50 · Fabled VIII 51–65 · Mythic IX 66–81 · Godlike X 82+
(`census/bands.json`). The script takes a numeral or a name (`elite`), and derives the band from
`--level` alone. A level outside the band given is an error: ask the user, don't pick one.

## Steps

1. **Find each row.** `npm run census:edit -- find <name or EditorID>` prints
   `page | rowId | name | band | records`. A name on several pages (a person filed twice, a
   shared row "A · B · C") must be resolved before editing: ask if it is ambiguous.
2. **Apply each decision.**
   - Band or level: `band <page> <rowId> [<band>] [--level N] --why "<the user's reason, short>"`.
   - One member of a shared row gets a different band: `split <page> <rowId> --names "A;B" [<band>] [--level N] --why "..."`.
     The shared row must name its members `A · B · C`, one record each; otherwise split by hand.
   - To another page: `move <from> <rowId> <to> [--after <rowId>] [--why "..."]`. It carries the
     row's placed and gear rows and adds a `filedElsewhere` pointer on the old group page. Fix
     anything that still names the row on the old page (the page or group `holds`/intro text,
     `drawnBy`, notes); the Quest Foes description kept naming moved rows once.
   - New page: `new-page <group>/<family> --title "..." --holds "..."`, then `move` rows into it.
   The `--why` is the user's reason in their words ("chief, but cowardly"); the script writes
   `user, <today>: <why>` and status `proposed`.
3. **Own levels.** A row whose level comes from a shared list or template (`level.kind` `list` or
   `template`, or a `Stats` template) cannot take a band different from the list's without a level of
   its own. Add "; it takes `Stats` from <list>, so it needs a level of its own" to the `--why`.
4. **Record the decisions** in `arch-docs/design/archetype-tiers.md` §7.0: one bullet per batch,
   dated, naming each row and its band or level, in the user's terms.
5. **Validate.** `npm run schema`. A dead `drawnBy` page link means a move left a pointer behind.
6. **Sync the mirrors** with the `census-confluence-sync` skill.
7. **Commit** census, `archetype-tiers.md` and `confluence-synced.json` together. Deploy the site
   only when the user asks (`gh workflow run pages.yml --ref main`).

## Report back

A short table: row, page, before → after. Say which rows needed a level of their own and anything
you could not apply (ambiguous names, shared rows that could not be split).
