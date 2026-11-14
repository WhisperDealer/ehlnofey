// The ledger maths and checks, shared by the site pages and scripts/emit-schema.ts. Pure functions
// over parsed data (no astro:content import), so Node can run them directly.
import type { BandsData, FamilyData, GearData, LedgerData, RecordRowData, RosterData } from '../schema.ts';

export type Census = FamilyData[];
type Band = BandsData['bands'][number];

export const bandOf = (bands: BandsData, v: number): Band =>
  bands.bands.find((b) => v >= b.min && (b.max === null || v <= b.max))!;

export function resolveRow(census: Census, pointer: string): { family: FamilyData; row: RecordRowData } | undefined {
  const [page, rowId] = pointer.split('#');
  const [group, id] = page.split('/');
  const family = census.find((f) => f.group === group && f.id === id);
  const row = family?.records.rows.find((r) => r.id === rowId);
  return family && row ? { family, row } : undefined;
}

// The level a row's rung spawns at: its own fixed level (a rung owns its level).
export const rowLevel = (row: RecordRowData): number | undefined =>
  row.level.kind === 'fixed' || row.level.kind === 'template' ? row.level.value : undefined;

export interface RosterEntryStat {
  row: string;
  name: string;
  level: number | undefined;
  weight: number;
  odds: number; // 0..1 of the kept weight
  why?: string;
}

export interface RosterStats {
  entries: RosterEntryStat[];
  kept: RosterEntryStat[];
  total: number;
  mean: number | undefined; // mean drawn level, when every kept rung has a level
  pinned: number | undefined; // the level, when the roster keeps a single rung
}

export function rosterStats(census: Census, roster: RosterData): RosterStats {
  const total = roster.entries.reduce((s, e) => s + e.weight, 0);
  const entries = roster.entries.map((e) => {
    const hit = resolveRow(census, e.row);
    return {
      row: e.row,
      name: hit?.row.name ?? e.row,
      level: hit ? rowLevel(hit.row) : undefined,
      weight: e.weight,
      odds: total ? e.weight / total : 0,
      why: e.why,
    };
  });
  const kept = entries.filter((e) => e.weight > 0);
  const mean = kept.every((e) => e.level !== undefined)
    ? kept.reduce((s, e) => s + e.level! * e.weight, 0) / total
    : undefined;
  return { entries, kept, total, mean, pinned: kept.length === 1 ? kept[0].level : undefined };
}

// The level vanilla spawns at, by player level, from the entries' gates: the mean of every unlocked
// rung ('all') or the highest unlocked rung ('highest'). Undefined when the roster has no gates.
export function vanillaCurve(census: Census, roster: RosterData, maxPlayer = 50): { p: number; v: number }[] | undefined {
  const rungs = roster.entries
    .map((e) => ({ gate: e.gate, level: resolveRow(census, e.row) && rowLevel(resolveRow(census, e.row)!.row) }))
    .filter((r): r is { gate: number; level: number } => r.gate !== undefined && r.level !== undefined);
  if (!rungs.length || !roster.vanillaRoll) return undefined;
  const out: { p: number; v: number }[] = [];
  for (let p = 1; p <= maxPlayer; p++) {
    const open = rungs.filter((r) => r.gate <= p);
    if (!open.length) continue;
    const v =
      roster.vanillaRoll === 'highest'
        ? open.reduce((a, b) => (b.gate > a.gate ? b : a)).level
        : open.reduce((s, r) => s + r.level, 0) / open.length;
    out.push({ p, v });
  }
  return out;
}

// One gear choice as a bar segment key: "steel", "steel+e", or the item's label.
export const choiceKey = (c: GearData['choices'][number]) =>
  c.material ? `${c.material}${c.enchanted ? '+e' : ''}` : (c.item?.label ?? c.item?.edid ?? '?');

// What vanilla rolls at player level p, approximately: one entry per gated choice (the real lists
// hold several weapon types per material, so this is the material mix, not exact odds).
export function vanillaGear(gear: GearData, p: number): { key: string; weight: number }[] | undefined {
  const gated = gear.choices.filter((c) => c.gate !== undefined);
  if (!gated.length || !gear.vanillaRoll) return undefined;
  const open = gated.filter((c) => c.gate! <= p);
  const top = Math.max(...open.map((c) => c.gate!));
  const pick = gear.vanillaRoll === 'highest' ? open.filter((c) => c.gate === top) : open;
  return pick.map((c) => ({ key: choiceKey(c), weight: 1 }));
}

export interface Finding {
  level: 'error' | 'warn';
  where: string; // roster / gear / pin id, or the census row
  text: string;
}

const hexOf = (fk: string) => fk.split(':')[0];

// Every check the ledger can make without the game files (ledgers.md §5).
export function checkLedger(ledger: LedgerData, census: Census, bands: BandsData): Finding[] {
  const out: Finding[] = [];
  const censusText = JSON.stringify(census.filter((f) => ledger.census.includes(f.group)));

  // Pointers resolve; lists are ones the census documents.
  const pointers = [
    ...ledger.rosters.flatMap((r) => r.entries.map((e) => ({ where: r.id, row: e.row }))),
    ...ledger.pins.map((p) => ({ where: `pin ${p.row}`, row: p.row })),
  ];
  for (const p of pointers)
    if (!resolveRow(census, p.row)) out.push({ level: 'error', where: p.where, text: `row "${p.row}" is not a census Records row` });
  for (const l of [...ledger.rosters, ...ledger.gear].flatMap((x) => x.lists.map((list) => ({ id: x.id, list }))))
    if (!censusText.includes(l.list.edid) && !censusText.includes(hexOf(l.list.formKey)))
      out.push({ level: 'warn', where: l.id, text: `\`${l.list.edid}\` is not named on any census page of ${ledger.census.join(', ')}` });

  // A list belongs to one roster, and a row to one pin.
  const seen = new Map<string, string>();
  for (const r of ledger.rosters)
    for (const l of r.lists) {
      if (seen.has(l.formKey)) out.push({ level: 'error', where: r.id, text: `\`${l.edid}\` is also in roster "${seen.get(l.formKey)}"` });
      seen.set(l.formKey, r.id);
    }

  // Vanilla gates must be gates the census records for the list (its entries' `at`).
  const listRows = census.flatMap((f) => f.lists?.rows ?? []);
  for (const r of ledger.rosters) {
    const doc = listRows.find((l) => l.list.formKey === r.lists[0].formKey && l.entries?.length);
    if (!doc) continue;
    const ats = new Set(doc.entries!.map((e) => e.at));
    for (const e of r.entries)
      if (e.gate !== undefined && !ats.has(e.gate))
        out.push({ level: 'error', where: r.id, text: `gate ${e.gate} for ${e.row} is not a gate of \`${r.lists[0].edid}\` in the census (${[...ats].join(', ')})` });
  }
  const gearRows = census.flatMap((f) => f.gearLists?.rows ?? []);
  for (const g of ledger.gear) {
    const doc = gearRows.find((l) => l.levels?.length && JSON.stringify(l.list).includes(g.lists[0].edid));
    if (!doc) continue;
    for (const c of g.choices)
      if (c.gate !== undefined && !c.runtime && !doc.levels!.includes(c.gate))
        out.push({ level: 'warn', where: g.id, text: `gate ${c.gate} (${choiceKey(c)}) is not a level the census gives for \`${g.lists[0].edid}\` (${doc.levels!.join(', ')})` });
  }

  const pinned = new Set(ledger.pins.map((p) => p.row));
  for (const r of ledger.rosters) {
    const s = rosterStats(census, r);
    // A kept rung's own level should sit in the band the census targets for it.
    for (const e of s.kept) {
      const hit = resolveRow(census, e.row);
      if (!hit || e.level === undefined || !('band' in hit.row.target) || pinned.has(e.row)) continue;
      const own = bandOf(bands, e.level);
      if (own.id !== hit.row.target.band)
        out.push({
          level: 'warn',
          where: e.row,
          text: `${e.name} is kept at its vanilla level ${e.level} (${own.name}), but its census target is band ${hit.row.target.band}: raise the rung with a pin, or move the target`,
        });
    }
    // Legibility: every kept rung needs its own name (archetype-tiers.md §3.1.1).
    const names = s.kept.map((e) => e.name);
    const dup = names.find((n, i) => names.indexOf(n) !== i);
    if (dup) out.push({ level: 'warn', where: r.id, text: `two kept rungs are both named "${dup}": the player cannot tell them apart; pin instead` });
    // Spread: at most three adjacent bands, and the top rung is not the commonest (Rule 3).
    const levels = s.kept.map((e) => e.level).filter((v): v is number => v !== undefined);
    if (levels.length > 1) {
      const ids = [...new Set(levels.map((v) => bandOf(bands, v).id))];
      if (ids.length > 3) out.push({ level: 'warn', where: r.id, text: `the kept rungs span ${ids.length} bands (${ids.join(', ')}); Rule 3 allows three` });
      const top = s.kept.reduce((a, b) => ((b.level ?? 0) > (a.level ?? 0) ? b : a));
      if (top.weight >= Math.max(...s.kept.map((e) => e.weight)))
        out.push({ level: 'warn', where: r.id, text: `the top rung (${top.name}) is the commonest; Rule 3 keeps it rare` });
    }
    // Band agreement: census rows that take their level from these lists, against what the roster draws.
    const drawn = s.pinned ?? (s.mean !== undefined ? Math.round(s.mean) : undefined);
    if (drawn === undefined) continue;
    const band = bandOf(bands, drawn);
    const fks = new Set(r.lists.map((l) => l.formKey));
    for (const f of census)
      for (const row of f.records.rows) {
        const ptr = `${f.group}/${f.id}#${row.id}`;
        if (row.level.kind !== 'list' || !row.level.from.formKey || !fks.has(row.level.from.formKey) || pinned.has(ptr)) continue;
        if ('band' in row.target && row.target.band !== band.id)
          out.push({
            level: 'warn',
            where: ptr,
            text: `${row.name} draws \`${row.level.from.edid}\`, which now spawns ${s.pinned ? `level ${drawn}` : `a mean of ${drawn}`} (${band.name}), but its census target is band ${row.target.band}: it needs a level of its own (a pin) or a different list`,
          });
      }
  }

  // Pins sit in their row's target band.
  for (const p of ledger.pins) {
    const hit = resolveRow(census, p.row);
    if (hit && 'band' in hit.row.target && bandOf(bands, p.level).id !== hit.row.target.band)
      out.push({ level: 'warn', where: `pin ${p.row}`, text: `level ${p.level} is band ${bandOf(bands, p.level).id}, but the census target is band ${hit.row.target.band}` });
  }

  // Gear: the schema already refuses a list that keeps nothing (an emptied weapon list spawns the NPC
  // unarmed) and has no dragon materials (craft-only). Nothing more to check here yet.
  return out;
}
