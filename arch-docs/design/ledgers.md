# The Ledgers — the next phase (planned)

**Status: PLANNED (user, 2026-11-14). Nothing here is built yet.** This document prepares the phase
that follows the census: it fixes what a ledger is, where its data lives, and the order of work, so the
first ledger can start without re-deciding any of it. Open questions are in §7; settle them with the
user before building the part they touch.

Read with: `modlist.md` (why Ehlnofey is now a modlist with its own patch), `flattening.md` (the method
the ledgers feed), `archetype-tiers.md` (the decisions taken so far, in prose).

---

## 1. What a ledger is

The census records what **vanilla** does. A ledger records what **Ehlnofey** does instead: the
decisions for one family, in a form a generator can turn into records and the site can show and edit.

A ledger holds three kinds of decision:

| Decision | Example (Bandits, from `archetype-tiers.md` §3.1.1) |
|---|---|
| **Roster** — which rungs a leveled list keeps, and their weights | the mook lists drop Bandit (1), Plunderer (19) and Marauder (25) and keep **Outlaw ×3 · Thug ×4 · Highwayman ×2** |
| **Pin** — a fixed level for a rung or record | every Bandit Chief is **level 28** |
| **Gear** — what a rung wears and wields, by material | the chief's rung keeps the steel and dwarven gear it already carries; a mook rung's weapon and armour lists keep a chosen set of materials |

The name comes from the proof of concept's *faction ledgers* (read-only pages, one per faction;
`proof-of-concept.md` §11). The new ledgers are the same idea made **editable**, in the repo, on the
census site.

## 2. Where the data lives (user, 2026-11-14)

- **`ledgers/` JSON in the repo is the source of truth**, beside `census/`. One file per ledger.
- **The site edits it only under `npm run dev`.** The editor writes the JSON files on disk; the change
  is then reviewed and committed like any other. The public site (GitHub Pages) renders the ledgers
  **read-only**; there is no server and no shared database.
- **The schema is Zod, in `site/src/schema.ts`**, emitted to `ledgers/schema/` by `npm run schema`,
  the way `census/` works today. A no-Node quick check follows `build/Test-CensusJson.ps1`.
- **The generator reads the JSON**, not the site: a PowerShell 5.1 script in `src/Ehlnofey/`
  (`ConvertFrom-Json` is available; Guardrail 8) writes the `LVLN`, `LVLI` and `NPC_` YAML into
  `EhlnofeyESP`. The site never writes records.
- **Public-site rules still apply** (`census-site` gotchas): no Jira, no Confluence ids, no tooling
  paths in `ledgers/`.

### Dev-only editing, the intended mechanism `[unverified]`

The site is a static Astro build, so a write endpoint cannot ship. The plan is a Vite plugin in
`astro.config.mjs` whose `configureServer` hook adds a `POST` middleware (e.g. `/__ledger/<id>`): it
validates the body against the Zod schema and writes the file. `configureServer` runs only under the dev
server, so the production build has no write path by construction. The page shows its edit controls
only when `import.meta.env.DEV` is true. Prove both halves when building it (the build output must
contain no write call).

## 3. How a ledger relates to the census

- **A ledger points at census rows; it never copies them.** A roster entry names a census row as
  `<group>/<family>#<row-id>` (e.g. `bandits/common-bandits#bandit-outlaw`), and a list by its
  FormKey, so the record facts (EditorIDs, FormKeys, vanilla levels, vanilla list entries) stay in one
  place. `npm run schema` checks every pointer resolves, as it does for `drawnBy.page`.
- **Census pages stay vanilla-only** (CLAUDE.md, user 2026-09-30). The only Ehlnofey data on them is
  the `target` band; see §7 Q1 for whether the ledger takes that over.
- **One ledger per census family page**, by default (the page the rows are filed on); a ledger may
  also own a list that several families draw (the bandit mook lists are drawn by Silver Hand, thralls
  and others; their `drawnBy` already names them). See §7 Q2.
- **`archetype-tiers.md` remains the narrative**: why a roster is shaped the way it is. The ledger is
  the number the build uses. When the two disagree, the ledger wins and the doc gets a dated note.

## 4. A sketch of the data (to be firmed up in step 2 of §6)

Illustrative only; field names will settle when the schema is written.

```jsonc
{
  "id": "bandits",
  "title": "Bandits",
  "meta": { "updated": "2026-11-14" },
  "rosters": [
    {
      "list": { "edid": "LCharBanditMeleeAny", "formKey": "<hex>:Skyrim.esm" },
      "entries": [
        { "row": "bandits/common-bandits#bandit",            "weight": 0, "why": "level-1 rung dropped" },
        { "row": "bandits/common-bandits#bandit-outlaw",     "weight": 3 },
        { "row": "bandits/common-bandits#bandit-thug",       "weight": 4 },
        { "row": "bandits/common-bandits#bandit-highwayman", "weight": 2 },
        { "row": "bandits/common-bandits#bandit-plunderer",  "weight": 0 },
        { "row": "bandits/common-bandits#bandit-marauder",   "weight": 0 }
      ],
      "status": "decided", "source": "user, 2026-09-24"
    }
  ],
  "pins": [
    { "row": "bandits/bandit-chiefs#<row-id>", "level": 28, "status": "decided", "source": "user, 2026-07-30" }
  ],
  "gear": [
    {
      "row": "bandits/common-bandits#bandit-thug",
      "weapons": { "list": { "edid": "<weapon LVLI>", "formKey": "<hex>:Skyrim.esm" }, "materials": { "iron": 1, "steel": 2 } },
      "armor":   { "list": { "edid": "<armour LVLI>", "formKey": "<hex>:Skyrim.esm" }, "materials": { "hide": 1, "leather": 1 } }
    }
  ]
}
```

What the shape has to carry, whatever the field names:

- **Weight = duplicate entries** (`flattening.md` §4.3). A weight of 0 means the rung leaves the list;
  keep it in the ledger with its reason so a drop is a visible decision, not a missing line.
- **Derived numbers are computed, never stored**: the odds per rung and the mean drawn level (the
  Bandits roster: 3/9 · 4/9 · 2/9, mean 9.1) are shown by the site from the weights and the census
  levels.
- **Gear by material.** The vanilla weapon and armour `LVLI` resolve by level to a material tier
  (iron, steel, orcish, dwarven, elven, glass, ebony, daedric; hide, leather, scaled, etc. for light
  armour). The ledger chooses which tiers survive and how heavily, per rung; the generator writes the
  flattened list. Material vocabulary is a fixed enum in the schema, taken from the census gear pages.
- **Every decision carries `status` and `source`**, as the census `target` does: `proposed` /
  `decided` (user) / `implemented` (the built patch sets it).

## 5. Checks the ledger must make (from the gotchas)

These are the traps the proof of concept hit; the schema or a check script should catch each one:

- **No empty weapon list.** After a roster or gear edit, every rung still resolves to at least one
  weapon (`gotchas.md`: an emptied weapon list spawns the NPC unarmed, silently).
- **Legibility.** A roster may only span rungs with different display names (`archetype-tiers.md`
  §3.1.1, the naming test); a family whose rungs share a name gets a pin, not a roster.
- **Spread.** A roster spans at most three adjacent tiers and the top rung is rare (`archetype-tiers.md`
  §1, Rule 3). Warn, don't refuse: the user may override.
- **Level owner.** A pin names the record that owns the level (CLAUDE.md: follow the template chain),
  never a leaf that carries `Stats`.
- **Band agreement.** A pinned level or a roster's mean sits in the census row's target band, or the
  site flags it.
- **No dragon smithing gear** in any gear choice (craft-only).
- **Injectors.** A list that a start-up quest re-gates (`DLC2Init`, the CC packs) is flagged on the
  ledger, because a flat roster there is undone at runtime.

## 6. Order of work

1. **Close the census.** The groups still Confluence-first (Leveled Uniques, Loot, Level Gates, Quest
   Rewards, Uncategorised) are not enemy families; decide with the user whether any must migrate before
   the ledgers start.
2. **Write the `Ledger` schema** and one hand-written ledger, **Bandits**, transcribed from
   `archetype-tiers.md` §3.1 (rosters, the chief pin at 28, the Orc-camp roster). Validate it with
   `npm run schema`.
3. **Render ledgers read-only on the site**: roster with odds and mean level, pins, gear by material,
   linked to the census rows they point at.
4. **The dev editor** (§2): weights, drops, pins, gear materials; writes the JSON.
5. **The generator**: ledger JSON → `EhlnofeyESP` YAML, then build, round-trip, deploy, launch
   (`flattening.md` §6 steps 3–5 now read their numbers from the ledgers).
6. **Ledger by ledger** for the remaining families, in the faction order of `archetype-tiers.md`.

## 7. Open questions

1. **Does the ledger take over the census `target` band?** Either the ledger owns every Ehlnofey
   level and the census `target` is derived from it (one source), or both stay and a check keeps them
   in step.
2. **Granularity.** One ledger per census family, per top-level group (Bandits = one ledger over its
   seven pages), or per leveled list?
3. **Gear depth.** Material per rung only, or also weapon type (one-handed, two-handed, bow, staff)
   and enchanted variants? Enchanted lists (`SublistEnch*`) collapse to 15 level patterns on the Loot
   census pages, which may be the unit to choose from.
4. **Non-humanoids.** Draugr, Falmer and Dwemer have their own gear ladders (ancient Nord, Falmer,
   Dwarven); the material enum needs those too. Creatures have no gear: their ledger is roster and pins
   only.
5. **Containers.** `flattening.md` §5.4 is still open; is container loot a ledger too, or a separate
   decision?
