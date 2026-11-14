// Census coverage check: is every NPC record in the five masters and the CC plugins accounted
// for by a census page, or knowingly left out?
//
//   npm run coverage              check, using the cached game index if there is one
//   npm run coverage -- --rescan  rebuild the game index from reference/ first (minutes: it reads
//                                 every cell and worldspace file for placed refs)
//
// A record is ACCOUNTED when a census page names it (EditorID, FormKey, a `Pattern*` or {a,b}
// pattern in backticks, or plain prose), inherits its level from a record that is, or sits in a
// list the census names. The rest are sorted by rule (test actors, audio templates, presets, voice
// holders, mannequins, atronachs, corpses, Daedric Prince voices, unused), by a decision in
// scripts/coverage-decisions.json, or by whether anything marks them hostile:
//   REVIEW  an unaccounted record with a hostile signal (not Unaggressive, a hostile faction, in
//           a leveled list) and no decision: read it, then file it on a page or add a decision
//   CIVIL   unaccounted, no hostile signal: townsfolk and the like, by rule
// It also checks every census ref that pairs an EditorID with a FormKey against the game files.
//
// The report goes to site/.coverage/report.md (gitignored); the summary to stdout. Exit code 1
// when there is anything to review or a ref mismatch.
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const repo = join(import.meta.dirname, '..', '..');
const census = join(repo, 'census');
const reference = join(repo, 'reference');
const cacheDir = join(repo, 'site', '.coverage');
const gameCache = join(cacheDir, 'game.json');
const decisionsFile = join(import.meta.dirname, 'coverage-decisions.json');
type Json = any;

// ---------------------------------------------------------------- the game side (cached)
type Npc = {
  fk: string; edid: string; name?: string; template?: string; race?: string; aggr?: string;
  ltype?: string; level?: string; mult?: string; min?: string; max?: string;
  tflags: string[]; factions: string[];
};
type Game = {
  edidOf: Record<string, string>; names: Record<string, string[]>; factions: Record<string, string>; races: Record<string, string>;
  npcs: Record<string, Npc>; origin: Record<string, string>;
  lvln: Record<string, { edid: string; entries: [number, string][] }>;
  refBy: Record<string, string[]>;
  placed: Record<string, [string, string, number][]>; // base fk → [ref fk, cell, startsDead]
};

function roots(): string[] {
  const base = join(reference, 'Base');
  const cc = join(reference, 'mods', 'CreationClubYaml');
  if (!existsSync(base)) throw new Error(`no ${base}: serialize the masters first (spriggit-decompile-reference)`);
  return [
    ...readdirSync(base).sort().map((d) => join(base, d)),
    ...(existsSync(cc) ? readdirSync(cc).sort().map((d) => join(cc, d)) : []),
  ];
}
const yamls = (p: string) => (existsSync(p) ? readdirSync(p).filter((f) => f.endsWith('.yaml')) : []);
const parseName = (f: string) => {
  const m = f.match(/^(.*) - ([0-9A-F]{6})_(.*)\.yaml$/);
  return m ? { edid: m[1], fk: `${m[2]}:${m[3]}`.toLowerCase() } : null;
};

function parseNpc(txt: string): Npc {
  const L = txt.split(/\r?\n/);
  const n: Npc = { fk: '', edid: '', tflags: [], factions: [] };
  let sect = '';
  for (let i = 0; i < L.length; i++) {
    const l = L[i];
    let m: RegExpMatchArray | null;
    if (/^[A-Za-z]/.test(l)) sect = l.replace(/:.*/, '');
    if ((m = l.match(/^FormKey: (\S+)/))) n.fk = m[1].toLowerCase();
    else if ((m = l.match(/^EditorID: (.*)/))) n.edid = m[1].trim();
    else if ((m = l.match(/^Template: (\S+)/))) n.template = m[1].toLowerCase();
    else if ((m = l.match(/^Race: (\S+)/))) n.race = m[1].toLowerCase();
    else if ((m = l.match(/^  Aggression: (\S+)/)) && sect === 'AIData') n.aggr = m[1];
    else if ((m = l.match(/^- Faction: (\S+)/)) && sect === 'Factions') n.factions.push(m[1].toLowerCase());
    else if (sect === 'Configuration') {
      if ((m = l.match(/^    MutagenObjectType: (\w+)/))) n.ltype = m[1];
      else if ((m = l.match(/^    Level: (\S+)/))) n.level = m[1];
      else if ((m = l.match(/^    LevelMult: (\S+)/))) n.mult = m[1];
      else if ((m = l.match(/^  CalcMinLevel: (\S+)/))) n.min = m[1];
      else if ((m = l.match(/^  CalcMaxLevel: (\S+)/))) n.max = m[1];
      else if (/^  TemplateFlags:/.test(l)) for (let k = i + 1; k < L.length && /^  - /.test(L[k]); k++) n.tflags.push(L[k].slice(4).trim());
    } else if (sect === 'Name' && !n.name) {
      if (/Language: English/.test(l) && (m = (L[i + 1] ?? '').match(/String: (.*)/))) n.name = m[1];
    }
    if ((m = l.match(/^Name: (\S.*)$/))) n.name = m[1];
  }
  return n;
}

function scanGame(): Game {
  const g: Game = { edidOf: {}, names: {}, factions: {}, races: {}, npcs: {}, origin: {}, lvln: {}, refBy: {}, placed: {} };
  const rs = roots();
  console.error(`scanning ${rs.length} plugins`);
  for (const r of rs)
    for (const sub of ['Factions', 'Races', 'LeveledNpcs', 'Quests', 'Npcs', 'FormLists', 'MagicEffects', 'Spells', 'Packages', 'Activators'])
      for (const f of yamls(join(r, sub))) {
        const p = parseName(f);
        if (!p) continue;
        g.edidOf[p.fk] = p.edid;
        if (!(g.names[p.fk] ??= []).includes(p.edid)) g.names[p.fk].push(p.edid); // an override can rename a record
        if (sub === 'Factions') g.factions[p.fk] = p.edid;
        if (sub === 'Races') g.races[p.fk] = p.edid;
      }
  for (const r of rs) {
    const label = r.split(/[\\/]/).pop()!;
    for (const f of yamls(join(r, 'Npcs'))) {
      const p = parseName(f);
      if (!p) continue;
      const n = parseNpc(readFileSync(join(r, 'Npcs', f), 'utf8'));
      n.fk = p.fk;
      n.edid ||= p.edid;
      g.origin[p.fk] ??= label;
      g.npcs[p.fk] = n; // load order: the last override wins
    }
    for (const f of yamls(join(r, 'LeveledNpcs'))) {
      const p = parseName(f);
      if (!p) continue;
      const t = readFileSync(join(r, 'LeveledNpcs', f), 'utf8');
      g.lvln[p.fk] = { edid: p.edid, entries: [...t.matchAll(/Level: (\d+)\s*\n\s*Reference: (\S+)/g)].map((m) => [+m[1], m[2].toLowerCase()]) };
    }
    for (const sub of ['Quests', 'MagicEffects', 'FormLists', 'Spells', 'Scenes', 'Packages', 'StoryManagerQuestNodes', 'Activators', 'Furniture', 'Hazards', 'Explosions'])
      for (const f of yamls(join(r, sub))) {
        const p = parseName(f);
        if (!p) continue;
        const t = readFileSync(join(r, sub, f), 'utf8');
        for (const fk of new Set([...t.matchAll(/\b([0-9A-F]{6}:[\w-]+\.es[mpl])/g)].map((x) => x[1].toLowerCase())))
          (g.refBy[fk] ??= []).push(`${sub.slice(0, 4)}:${p.edid}`);
      }
  }
  // Placed refs, from every cell and worldspace file.
  const files: string[] = [];
  const walk = (p: string) => {
    for (const e of readdirSync(p, { withFileTypes: true })) {
      const q = join(p, e.name);
      if (e.isDirectory()) walk(q);
      else if (e.name.endsWith('.yaml')) files.push(q);
    }
  };
  for (const r of rs) for (const s of ['Cells', 'Worldspaces']) if (existsSync(join(r, s))) walk(join(r, s));
  console.error(`reading ${files.length} cell and worldspace files for placed refs`);
  const cellOf = (f: string) => {
    const parts = f.split(/[\\/]/);
    for (let i = parts.length - 2; i >= 0; i--) {
      const m = parts[i].match(/^(.*) - [0-9A-F]{6}_.*$/);
      if (m) return m[1];
    }
    return '?';
  };
  for (const f of files) {
    const txt = readFileSync(f, 'utf8');
    if (!txt.includes('PlacedNpc')) continue;
    const cell = cellOf(f);
    let cur: { ref?: string; base?: string; dead?: boolean } | null = null;
    let ind = -1;
    const flush = () => {
      if (cur?.base) (g.placed[cur.base.toLowerCase()] ??= []).push([cur.ref ?? '', cell, cur.dead ? 1 : 0]);
      cur = null;
    };
    for (const l of txt.split(/\r?\n/)) {
      const m = l.match(/^(\s*)- MutagenObjectType: (\w+)/);
      if (m) {
        if (cur && m[1].length <= ind) flush();
        if (m[2] === 'PlacedNpc') { flush(); cur = {}; ind = m[1].length; }
        continue;
      }
      if (!cur) continue;
      const i2 = l.search(/\S/);
      if (i2 >= 0 && i2 <= ind) { flush(); continue; }
      let mm: RegExpMatchArray | null;
      if (!cur.ref && (mm = l.match(/^\s*FormKey: (\S+)/))) cur.ref = mm[1];
      else if (!cur.base && (mm = l.match(/^\s*Base: (\S+)/))) cur.base = mm[1];
      else if (/StartsDead/.test(l)) cur.dead = true;
    }
    flush();
  }
  mkdirSync(cacheDir, { recursive: true });
  writeFileSync(gameCache, JSON.stringify(g));
  return g;
}

const rescan = process.argv.includes('--rescan');
if (!rescan && !existsSync(gameCache)) console.error('no cached game index: scanning (use --rescan to refresh it later)');
const G: Game = !rescan && existsSync(gameCache) ? JSON.parse(readFileSync(gameCache, 'utf8')) : scanGame();

// ---------------------------------------------------------------- the census side
const cEdid = new Set<string>(), cTick = new Set<string>(), cFK = new Set<string>(), cWeak = new Set<string>(), cHex = new Set<string>();
const pats: RegExp[] = [];
const refPairs: { page: string; edid: string; fk: string }[] = [];

function topSplit(s: string) {
  const out: string[] = [];
  let d = 0, cur = '';
  for (const ch of s) {
    if (ch === '{') d++;
    if (ch === '}') d--;
    if (d === 0 && /[\s·/]/.test(ch)) { if (cur) out.push(cur); cur = ''; } else cur += ch;
  }
  if (cur) out.push(cur);
  return out;
}
// `LvlBandit*`, `EncAlikr0N*`, `Foo{A,B}`, `Rung1–6`, `<Race>Foo` → a regex over EditorIDs.
function toRe(tok: string): RegExp | null {
  tok = tok.replace(/^[([]+|[)\],;:.]+$/g, '');
  if (!/[{*<…]|\d[–-]\d|0N|NN/.test(tok)) return null;
  let r = '';
  let i = 0;
  while (i < tok.length) {
    const ch = tok[i];
    if (ch === '{') {
      let d = 1, j = i + 1;
      while (j < tok.length && d) { if (tok[j] === '{') d++; if (tok[j] === '}') d--; j++; }
      const inner = tok.slice(i + 1, j - 1);
      const m = inner.match(/^(\d+)[–-](\d+)$/);
      r += m
        ? '(?:' + Array.from({ length: +m[2] - +m[1] + 1 }, (_, k) => String(+m[1] + k).padStart(m[1].length, '0')).join('|') + ')'
        : '(?:' + inner.split(',').map((x) => x.replace(/[^\w]/g, '')).join('|') + ')';
      i = j;
      continue;
    }
    if (ch === '*' || ch === '…') { r += '.*'; i++; continue; }
    if (ch === '<') { const j = tok.indexOf('>', i); r += '\\w*'; i = j < 0 ? tok.length : j + 1; continue; }
    const range = tok.slice(i).match(/^(\d+)[–-](\d+)/);
    if (range) { r += '\\d+'; i += range[0].length; continue; }
    if (ch === 'N' && (/[0N]/.test(tok[i - 1] ?? '') || tok[i + 1] === 'N') && !/[a-z]/.test(tok[i + 1] ?? '')) { r += '\\d'; i++; continue; }
    r += /\w/.test(ch) ? ch : '.';
    i++;
  }
  if (r.replace(/[^A-Za-z0-9_]/g, '').length < 8) return null; // too loose to trust
  try { return new RegExp('^' + r + '$', 'i'); } catch { return null; }
}

function walkCensus(dir: string, out: string[] = []) {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const q = join(dir, e.name);
    if (e.isDirectory()) { if (e.name !== 'schema') walkCensus(q, out); } else if (e.name.endsWith('.json')) out.push(q);
  }
  return out;
}
for (const f of walkCensus(census)) {
  const page = f.slice(census.length + 1).replace(/\\/g, '/').replace(/\.json$/, '');
  const rec = (o: Json, k: string) => {
    if (typeof o === 'string') {
      if (k === 'edid') cEdid.add(o);
      for (const m of o.matchAll(/`([^`]+)`/g)) {
        for (const t of m[1].split(/[\s,·/]+/)) {
          const tt = t.replace(/[()[\]:;.]+$/, '').replace(/^[([]+/, '');
          if (tt) cTick.add(tt);
        }
        for (const t of topSplit(m[1])) { const re = toRe(t); if (re) pats.push(re); }
      }
      for (const m of o.matchAll(/\b([0-9A-Fa-f]{6}):([\w-]+\.es[mpl])/gi)) cFK.add(`${m[1]}:${m[2]}`.toLowerCase());
      for (const m of o.matchAll(/\b([A-Za-z_][A-Za-z0-9_]{3,})\b/g)) cWeak.add(m[1]);
      for (const m of o.matchAll(/\b([0-9A-F]{6})\b/g)) cHex.add(m[1]);
      return;
    }
    if (Array.isArray(o)) { for (const x of o) rec(x, k); return; }
    if (o && typeof o === 'object') {
      if (typeof o.edid === 'string' && typeof o.formKey === 'string') refPairs.push({ page, edid: o.edid, fk: o.formKey.toLowerCase() });
      for (const kk in o) rec(o[kk], kk);
    }
  };
  rec(JSON.parse(readFileSync(f, 'utf8')), '');
}

// ---------------------------------------------------------------- classify
const decisions: Record<string, { verdict: string; note?: string }> = JSON.parse(readFileSync(decisionsFile, 'utf8'));
const edidOf = (fk: string) => G.edidOf[fk] ?? G.npcs[fk]?.edid ?? G.lvln[fk]?.edid;
const how: Record<string, string> = {};
function direct(fk: string): boolean {
  const e = edidOf(fk);
  if ((e && (cEdid.has(e) || cTick.has(e))) || cFK.has(fk)) return true;
  if (!e) return false;
  if (pats.some((re) => re.test(e))) { how[fk] = 'pattern'; return true; }
  if (cWeak.has(e)) { how[fk] = 'prose'; return true; }
  return false;
}
const parents: Record<string, Set<string>> = {};
for (const l in G.lvln) for (const [, r] of G.lvln[l].entries) (parents[r] ??= new Set()).add(l);
const tUsers: Record<string, number> = {};
for (const k in G.npcs) { const t = G.npcs[k].template; if (t) tUsers[t] = (tUsers[t] ?? 0) + 1; }

type Chain = { k: 'covered'; via: string } | { k: 'owner'; fk: string } | { k: 'loop' } | { k: 'missing' };
function chain(fk: string, seen = new Set<string>()): Chain {
  if (seen.has(fk)) return { k: 'loop' };
  seen.add(fk);
  if (direct(fk)) return { k: 'covered', via: edidOf(fk) ?? fk };
  if (G.lvln[fk]) {
    for (const [, r] of G.lvln[fk].entries) { const c = chain(r, seen); if (c.k === 'covered') return { k: 'covered', via: `${G.lvln[fk].edid} > ${c.via}` }; }
    return { k: 'owner', fk };
  }
  const n = G.npcs[fk];
  if (!n) return { k: 'missing' };
  if (n.template && n.tflags.includes('Stats')) return chain(n.template, seen);
  return { k: 'owner', fk };
}
function listCovered(fk: string, seen = new Set<string>()): string | null {
  for (const p of parents[fk] ?? []) {
    if (seen.has(p)) continue;
    seen.add(p);
    if (direct(p)) return G.lvln[p].edid;
    const a = listCovered(p, seen);
    if (a) return `${G.lvln[p].edid} < ${a}`;
  }
  return null;
}

const HOSTILE = /Bandit(?!Friend)|Forsworn|Warlock|Necromancer|Vampire(?!Feed)|Enemy|Draugr|Falmer|Hagraven|Undead|Dremora|Daedra|Thalmor|SilverHand|Reaver|Cultist|Spriggan|Troll|Giant|Riekling|Werewolf|Hostile|Thug|Assassin|BountyHunter|Boss|Skeleton|Dragon(?!sreach|Bridge)|Automaton|Ghost|Predator(?!Friend)|Creature(?!Friend)|Wisp|Arena/i;
const PRINCE_VOICE = /^DA\d\d(AzuraVoice|Boethiah|ClavicusVile|Mephala|MolagBalVoice|Sheogorath|Hircine|Meridia)|^Nocturnal$|HermaeusMoraVoice|NightMotherVoice|VoiceofNamira/;

type Row = { fk: string; edid: string; name: string; origin: string; level: string; aggr: string; fac: string; lists: string; via?: string; note?: string; placed: number; cells: string; quest: string };
const cats: Record<string, Row[]> = {};
const put = (c: string, r: Row) => (cats[c] ??= []).push(r);
for (const fk in G.npcs) {
  const n = G.npcs[fk];
  const P = G.placed[fk] ?? [];
  const r: Row = {
    fk, edid: n.edid, name: n.name ?? '', origin: G.origin[fk],
    level: n.ltype === 'PcLevelMult' ? `PC×${n.mult ?? 1} [${n.min ?? 0}–${n.max ?? 0}]` : (n.level ?? '0'),
    aggr: n.aggr ?? 'Unaggressive',
    fac: n.factions.map((f) => G.factions[f] ?? f).join(', '),
    lists: [...(parents[fk] ?? [])].map((l) => G.lvln[l].edid).join(', '),
    placed: P.length,
    cells: [...new Set(P.map((x) => x[1]))].slice(0, 3).join(', '),
    quest: [...new Set([...(G.refBy[fk] ?? []), ...P.flatMap((p) => G.refBy[p[0].toLowerCase()] ?? [])])].slice(0, 4).join(', '),
  };
  const c = chain(fk);
  if (c.k === 'covered') { r.via = c.via; put(fk in how && direct(fk) ? `accounted (${how[fk]})` : direct(fk) ? 'accounted' : 'accounted (inherits)', r); continue; }
  const lc = listCovered(fk);
  if (lc) { r.via = lc; put('accounted (in a census list)', r); continue; }
  const d = decisions[n.edid];
  if (d) { r.note = d.note; put(d.verdict === 'accounted' ? 'accounted (decision)' : d.verdict, r); continue; }
  if (c.k === 'owner' && c.fk !== fk) r.via = `level from ${edidOf(c.fk) ?? c.fk}`;
  const e = n.edid;
  const race = G.races[n.race ?? ''] ?? '';
  if (/test|e3demo|DeleteWhenDone|Warehouse|DetectLife|DetectionTarget|FontActor|CrystalCaster|PlanterNPC|FishPlaque|FishHatchery|ResponsiveNPC|^PlayerInventory|Dummy/i.test(e) || /e3demo/i.test(r.cells)) put('test', r);
  else if (/AudioTemplate/i.test(e)) put('audio template', r);
  else if (/Preset\d/i.test(e)) put('chargen preset', r);
  else if (/^(DLC1)?VoiceType/i.test(e)) put('voice holder', r);
  else if (/Mannequin|Manakin/i.test(e + race)) put('mannequin', r);
  else if (/Atronach/.test(race)) put('atronach (out of the census)', r);
  else if (/corpse|Dead$|^TreasCorpse/i.test(e) || (P.length > 0 && P.every((p) => p[2]))) put('corpse', r);
  else if (PRINCE_VOICE.test(e)) put('Daedric Prince voice', r);
  else {
    const hostile = r.aggr !== 'Unaggressive' || n.factions.some((f) => HOSTILE.test(G.factions[f] ?? '')) || !!r.lists;
    const used = r.placed > 0 || !!r.lists || (tUsers[fk] ?? 0) > 0 || !!r.quest;
    if (!used) put('unused', r);
    else put(hostile ? 'REVIEW' : 'civil', r);
  }
}

// Census refs whose EditorID is none of the names the FormKey has in any plugin.
const mismatches = refPairs.filter((p) => G.names[p.fk] !== undefined && !G.names[p.fk].includes(p.edid));

// ---------------------------------------------------------------- report
const total = Object.keys(G.npcs).length;
const acc = Object.entries(cats).filter(([k]) => k.startsWith('accounted')).reduce((n, [, v]) => n + v.length, 0);
const order = Object.keys(cats).sort((a, b) => (a === 'REVIEW' ? -1 : b === 'REVIEW' ? 1 : a.localeCompare(b)));
const lines: string[] = [
  `# Census coverage, ${new Date().toLocaleDateString('sv')}`,
  '',
  `${total} NPC records in ${new Set(Object.values(G.origin)).size} plugins; ${acc} accounted for by the census.`,
  '',
  '| Category | Records |',
  '| --- | --- |',
  ...order.map((k) => `| ${k} | ${cats[k].length} |`),
  '',
];
const table = (rows: Row[]) => [
  '| EditorID | FormKey | Name | Level | Aggression | Factions | Lists | Placed | Quest | Note |',
  '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
  ...rows.map((r) => `| \`${r.edid}\` | ${r.fk} | ${r.name} | ${r.level} | ${r.aggr} | ${r.fac.slice(0, 80)} | ${r.lists} | ${r.placed}${r.cells ? ' (' + r.cells + ')' : ''} | ${r.quest} | ${[r.via, r.note].filter(Boolean).join('; ')} |`),
  '',
];
if (cats.REVIEW) lines.push('## To review', '', 'Unaccounted, with a hostile signal, and no decision in `site/scripts/coverage-decisions.json`. File each on its census page, or add a decision.', '', ...table(cats.REVIEW));
if (mismatches.length) lines.push('## EditorID / FormKey mismatches', '', '| Page | EditorID in the census | FormKey | EditorID in the game |', '| --- | --- | --- | --- |', ...mismatches.map((m) => `| ${m.page} | \`${m.edid}\` | ${m.fk} | \`${G.edidOf[m.fk]}\` |`), '');
for (const k of ['border', 'unused', 'civil']) if (cats[k]) lines.push(`## ${k}`, '', ...table(cats[k]));
mkdirSync(cacheDir, { recursive: true });
writeFileSync(join(cacheDir, 'report.md'), lines.join('\n'));

console.log(`${total} NPC records; ${acc} accounted for`);
for (const k of order) console.log(`  ${k}: ${cats[k].length}`);
console.log(`EditorID/FormKey mismatches in census refs: ${mismatches.length}`);
for (const r of cats.REVIEW ?? []) console.log(`  REVIEW ${r.edid} ${r.fk} "${r.name}" ${r.level} ${r.aggr} | ${r.fac.slice(0, 60)} | placed ${r.placed}`);
for (const m of mismatches.slice(0, 20)) console.log(`  MISMATCH ${m.page}: ${m.edid} ≠ ${G.edidOf[m.fk]} (${m.fk})`);
console.log('report: site/.coverage/report.md');
if (cats.REVIEW || mismatches.length) process.exitCode = 1;
