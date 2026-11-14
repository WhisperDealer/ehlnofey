// Scripted edits to census/ JSON for the common band decisions, so they are not hand-rolled per
// batch. Every write stamps meta.updated with today's date; run `npm run schema` afterwards.
//
//   npm run census:edit -- find <text>
//       every records row whose id, name or record EditorID contains <text> (case-insensitive)
//   npm run census:edit -- band <group>/<family> <rowId> [<band>] [--level N] --why "<reason>"
//       set the row's target; <band> is a numeral (VI) or a name (elite); with --level alone the
//       band is derived from the level
//   npm run census:edit -- split <group>/<family> <rowId> --names "A;B" [<band>] [--level N] --why "<reason>"
//       pull the named members of a shared row (name "A · B · C", one record each) into rows of
//       their own with the given target; the rest stay on the shared row
//   npm run census:edit -- move <group>/<family> <rowId> <group>/<family> [--after <rowId>] [--why "<reason>"]
//       move a row, with its placed rows and gear rows, to another page; the old group's page
//       gets a filedElsewhere pointer
//   npm run census:edit -- new-page <group>/<family> --title "<Title>" --holds "<what it holds>"
//       an empty family page in an existing group (add rows with move)
//
// The source written is "user, <today>: <reason>" and the status "proposed": a user decision
// stays proposed until the built mod sets the level (CLAUDE.md). Record each decision in
// arch-docs/design/archetype-tiers.md §7.0 as well; this script does not touch the docs.
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

process.on('uncaughtException', (e) => { console.error(`census:edit: ${e.message}`); process.exit(1); });

const census = join(import.meta.dirname, '..', '..', 'census');
const today = new Date().toLocaleDateString('sv'); // YYYY-MM-DD, local
type Json = any; // census files are validated by `npm run schema`, not here

const bands: { id: string; name: string; min: number; max: number | null }[] = JSON.parse(
  readFileSync(join(census, 'bands.json'), 'utf8'),
).bands;

const file = (page: string) => {
  if (!/^[a-z0-9-]+\/[a-z0-9-]+$/.test(page)) throw new Error(`page is <group>/<family>: ${page}`);
  return join(census, `${page}.json`);
};
const load = (page: string): Json => {
  const f = file(page);
  if (!existsSync(f)) throw new Error(`no census page ${page}`);
  return JSON.parse(readFileSync(f, 'utf8'));
};
const save = (page: string, j: Json) => {
  if (j.meta) j.meta.updated = today;
  writeFileSync(file(page), JSON.stringify(j, null, 2) + '\n');
  console.log(`wrote census/${page}.json`);
};
const slug = (s: string) => s.toLowerCase().normalize('NFD').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

// --- arguments
const argv = process.argv.slice(2);
const flags: Record<string, string> = {};
const pos: string[] = [];
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) flags[argv[i].slice(2)] = argv[++i] ?? '';
  else pos.push(argv[i]);
}
const need = (k: string) => {
  if (!flags[k]) throw new Error(`--${k} is required`);
  return flags[k];
};

function bandOf(level: number) {
  const b = bands.find((x) => level >= x.min && (x.max === null || level <= x.max));
  if (!b) throw new Error(`no band holds level ${level}`);
  return b;
}
function target(bandArg: string | undefined): Json {
  const level = flags.level ? Number(flags.level) : undefined;
  if (level !== undefined && !(Number.isInteger(level) && level > 0)) throw new Error(`bad --level ${flags.level}`);
  let band = bandArg
    ? bands.find((b) => b.id === bandArg.toUpperCase() || b.name.toLowerCase() === bandArg.toLowerCase())
    : level !== undefined ? bandOf(level) : undefined;
  if (!band) throw new Error(bandArg ? `unknown band ${bandArg}` : 'give a band or --level');
  if (level !== undefined && bandOf(level).id !== band.id)
    throw new Error(`level ${level} is in band ${bandOf(level).id}, not ${band.id}`);
  const why = need('why');
  return Object.assign({ band: band.id }, level !== undefined ? { level } : {}, {
    status: 'proposed',
    source: `user, ${today}: ${why}`,
  });
}
function row(j: Json, rowId: string) {
  const r = j.records.rows.find((x: Json) => x.id === rowId);
  if (!r) throw new Error(`no row ${rowId}; rows: ${j.records.rows.map((x: Json) => x.id).join(', ')}`);
  return r;
}
const describe = (t: Json) => (t.band ? `${t.band}${t.level ? ' ' + t.level : ''}` : t.scales ? 'scales' : 'unchanged');
const edids = (r: Json) => r.records.map((x: Json) => x.edid ?? x.formKey ?? x.label);

function* pages(): Generator<[string, Json]> {
  for (const g of readdirSync(census)) {
    if (g === 'schema' || !statSync(join(census, g)).isDirectory()) continue;
    for (const f of readdirSync(join(census, g)))
      if (f.endsWith('.json') && f !== 'group.json') yield [`${g}/${f.slice(0, -5)}`, JSON.parse(readFileSync(join(census, g, f), 'utf8'))];
  }
}

const [cmd] = pos;
if (cmd === 'find') {
  const q = (pos[1] ?? '').toLowerCase();
  if (!q) throw new Error('usage: find <text>');
  let n = 0;
  for (const [page, j] of pages())
    for (const r of j.records?.rows ?? [])
      if ([r.id, r.name, ...edids(r)].some((s: string) => String(s).toLowerCase().includes(q))) {
        console.log(`${page} | ${r.id} | ${r.name} | ${describe(r.target)} | ${edids(r).join(' · ')}`);
        n++;
      }
  if (!n) console.log('no row matches');
} else if (cmd === 'band') {
  const [, page, rowId, bandArg] = pos;
  const j = load(page);
  const r = row(j, rowId);
  const before = describe(r.target);
  r.target = target(bandArg);
  save(page, j);
  console.log(`${r.name}: ${before} → ${describe(r.target)}`);
} else if (cmd === 'split') {
  const [, page, rowId, bandArg] = pos;
  const names = need('names').split(';').map((s) => s.trim()).filter(Boolean);
  const j = load(page);
  const rows = j.records.rows;
  const i = rows.findIndex((x: Json) => x.id === rowId);
  const shared = row(j, rowId);
  const parts = shared.name.split(' · ');
  if (parts.length !== shared.records.length)
    throw new Error(`${rowId}: ${parts.length} names but ${shared.records.length} records; split by hand`);
  const t = target(bandArg);
  const out: Json[] = [];
  const keep: { name: string; rec: Json }[] = [];
  parts.forEach((n: string, k: number) => {
    if (names.includes(n)) out.push({ ...shared, id: slug(n), name: n, records: [shared.records[k]], target: t });
    else keep.push({ name: n, rec: shared.records[k] });
  });
  const missing = names.filter((n) => !parts.includes(n));
  if (missing.length) throw new Error(`not on ${rowId}: ${missing.join(', ')} (names: ${parts.join(' · ')})`);
  const rest = keep.length
    ? [{ ...shared, id: keep.length === 1 ? slug(keep[0].name) : slug(keep.map((x) => x.name).join('-')), name: keep.map((x) => x.name).join(' · '), records: keep.map((x) => x.rec) }]
    : [];
  const ids = new Set(rows.filter((_: Json, k: number) => k !== i).map((x: Json) => x.id));
  for (const r of [...out, ...rest]) if (ids.has(r.id)) throw new Error(`row id ${r.id} already exists on ${page}`);
  rows.splice(i, 1, ...out, ...rest);
  save(page, j);
  for (const r of [...out, ...rest]) console.log(`${r.id} | ${r.name} | ${describe(r.target)}`);
  console.log('check the shared row\'s note and the page\'s placed rows: they may name the split members');
} else if (cmd === 'move') {
  const [, from, rowId, to] = pos;
  if (!to) throw new Error('usage: move <from> <rowId> <to> [--after <rowId>]');
  const src = load(from);
  const dst = load(to);
  const r = row(src, rowId);
  if (dst.records.rows.some((x: Json) => x.id === r.id)) throw new Error(`row id ${r.id} already exists on ${to}`);
  src.records.rows = src.records.rows.filter((x: Json) => x !== r);
  if (flags.why) r.target = { ...r.target, source: `${r.target.source}; moved from ${from} (user, ${today}: ${flags.why})` };
  const at = flags.after ? dst.records.rows.findIndex((x: Json) => x.id === flags.after) + 1 : dst.records.rows.length;
  if (flags.after && at === 0) throw new Error(`no row ${flags.after} on ${to}`);
  dst.records.rows.splice(at, 0, r);

  // Placed rows: by base record or by the row's name. Gear rows: their records text names it.
  const keys = new Set(edids(r).map((s: string) => s.toLowerCase()));
  const hits = (p: Json) =>
    p.name === r.name || (p.base ?? []).some((b: Json) => keys.has(String(b.edid ?? b.formKey ?? '').toLowerCase()));
  const placed = (src.placed?.rows ?? []).filter(hits);
  if (placed.length) {
    src.placed.rows = src.placed.rows.filter((p: Json) => !placed.includes(p));
    dst.placed ??= { title: 'Placed only', confidence: src.placed.confidence, rows: [] };
    dst.placed.rows.push(...placed);
  }
  const named = (s: string) => s.includes(r.name) || [...keys].some((k) => s.toLowerCase().includes(k));
  const gear = (src.gear?.rows ?? []).filter((g: Json) => named(g.records));
  if (gear.length) {
    src.gear.rows = src.gear.rows.filter((g: Json) => !gear.includes(g));
    dst.gear ??= { confidence: src.gear.confidence, rows: [] };
    dst.gear.rows.push(...gear);
  }
  if (src.placed?.rows.length === 0) delete src.placed;
  if (src.gear?.rows.length === 0) delete src.gear;

  // A pointer on the old group's page.
  const [fromGroup] = from.split('/');
  const [toGroup, toFamily] = to.split('/');
  if (fromGroup !== toGroup) {
    const gf = join(census, fromGroup, 'group.json');
    const g = JSON.parse(readFileSync(gf, 'utf8'));
    const gTo = JSON.parse(readFileSync(join(census, toGroup, 'group.json'), 'utf8'));
    g.filedElsewhere ??= [];
    g.filedElsewhere.push({
      record: r.records.map((x: Json) => '`' + (x.edid ?? x.label) + '`' + (x.formKey ? ' ' + x.formKey.split(':')[0] : '')).join(' · '),
      what: r.name,
      where: `${gTo.title} → *${dst.title}*`,
    });
    writeFileSync(gf, JSON.stringify(g, null, 2) + '\n');
    console.log(`wrote census/${fromGroup}/group.json (filedElsewhere → ${gTo.title} → ${dst.title})`);
  }
  save(from, src);
  save(to, dst);
  console.log(`moved ${r.name} with ${placed.length} placed row(s) and ${gear.length} gear row(s); ${toFamily}`);
  if (!gear.length && src.gear) console.log('no gear row named it: check the old page\'s gear, gearLists and gearItems by hand');
  console.log('check drawnBy rows elsewhere that point at the old page: `npm run schema` flags dead links');
} else if (cmd === 'new-page') {
  const [, page] = pos;
  const [group, id] = page.split('/');
  if (existsSync(file(page))) throw new Error(`${page} exists`);
  const gf = join(census, group, 'group.json');
  if (!existsSync(gf)) throw new Error(`no group ${group}`);
  const g = JSON.parse(readFileSync(gf, 'utf8'));
  g.families.push({ id, holds: need('holds') });
  writeFileSync(gf, JSON.stringify(g, null, 2) + '\n');
  save(page, {
    $schema: '../schema/census-family.schema.json',
    id,
    group,
    title: need('title'),
    order: g.families.length,
    meta: { updated: today },
    records: { confidence: 'verified', rows: [] },
  });
  console.log(`added ${id} to census/${group}/group.json; give it a Confluence page id in site/scripts/confluence-pages.json if it is mirrored`);
} else {
  console.error('usage: npm run census:edit -- find | band | split | move | new-page (see the header of scripts/census-edit.ts)');
  process.exitCode = 1;
}
