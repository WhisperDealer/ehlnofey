// Renders census JSON as the Markdown body of its Confluence mirror page, in the census page
// layout (Records, Also owns its level, Lists that draw them, Placed, Gear). Confluence is a
// mirror: edit the JSON, render, then push the output with the Atlassian MCP
// (updateConfluencePage, contentFormat "markdown", the page id from scripts/confluence-pages.json).
//
//   npm run confluence -- dragons/common-dragons     one family, to stdout
//   npm run confluence -- dragons                    the group page, to stdout
//   npm run confluence -- --all                      every page, to site/.confluence/<group>/<id>.md
//
// Page ids live in scripts/confluence-pages.json (key <group>/<family>), not in the census:
// the site publishes census/ and must not reference Confluence.
import { mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { Bands, Family, Group, type FamilyData, type GroupData, type LevelData, type RefData } from '../src/schema.ts';

const census = join(import.meta.dirname, '..', '..', 'census');
const bands = Bands.parse(JSON.parse(readFileSync(join(census, 'bands.json'), 'utf8'))).bands;

// Confluence Markdown: brackets and pipes must be escaped, everything else passes through.
const cell = (s: string) => s.replace(/\[/g, '\\[').replace(/\]/g, '\\]').replace(/\|/g, '\\|').replace(/\n/g, ' ');

// The census convention: `EditorID` then the FormID, with the master only when it is not Skyrim.esm.
function ref(r: RefData): string {
  const [hex, master] = r.formKey ? r.formKey.split(':') : [];
  const fk = r.formKey ? (master === 'Skyrim.esm' ? hex : `${hex}:${master}`) : '';
  const name = r.edid ? `\`${r.edid}\`` : (r.label ?? '');
  return [name, fk].filter(Boolean).join(' ');
}
const refs = (rs: RefData[], sep = ' · ') => rs.map(ref).join(sep);

function level(l: LevelData): string {
  switch (l.kind) {
    case 'fixed': return String(l.value);
    case 'pcMult': return `PC×${l.mult} [${l.min}–${l.max}]${l.from ? `, from ${ref(l.from)}` : ''}`;
    case 'template': return `${l.value}, from ${ref(l.from)}`;
    case 'list': return `from ${ref(l.from)} (${l.rungs.join(' · ')})`;
  }
}

const table = (head: string[], rows: string[][]) =>
  [`| ${head.join(' | ')} |`, `| ${head.map(() => '---').join(' | ')} |`, ...rows.map((r) => `| ${r.map(cell).join(' | ')} |`)].join('\n');

const conf = (c: string) => `\`[${c}]\``;
const banner = (path: string) =>
  `> Generated from \`census/${path}.json\` in the repo, which is the source of truth: edit the JSON, not this page. ` +
  `The site renders it at https://whisperdealer.github.io/ehlnofey/${path.replace(/\/group$/, '')}/`;

export function renderFamily(f: FamilyData, titles: Record<string, string> = {}): string {
  const out: string[] = [banner(`${f.group}/${f.id}`), ''];

  out.push(`## Records ${conf(f.records.confidence)}`, '');
  out.push(
    table(
      ['Record', 'Name', 'Level', 'Target'],
      f.records.rows.map((r) => {
        const b = bands.find((x) => x.id === r.target.band)!;
        let rec = refs(r.records);
        if (r.race) rec += ` (${ref(r.race)})`;
        if (r.factions) rec += ` (in ${refs(r.factions, ' and ')})`;
        const flags = r.flags?.length ? ` (${r.flags.map((x) => `\`${x}\``).join(', ')})` : '';
        const target = `${b.id} ${b.name}${r.target.level ? ` ${r.target.level}` : ''} (${r.target.status}; ${r.target.source})`;
        return [rec, r.encounter ? `${r.name}, ${r.encounter}` : r.name, level(r.level) + flags, target];
      }),
    ),
  );

  if (f.otherRecords) {
    out.push('', `## Other records ${conf(f.otherRecords.confidence)}`, '', 'Copies that are never fought: the base record, cutscenes, test copies.', '');
    out.push(table(['Record', 'Name', 'Level', 'Where'], f.otherRecords.rows.map((o) => [refs(o.records), o.name, level(o.level), o.where])));
  }

  if (f.ownsLevel) {
    out.push('', `## Also owns its level ${conf(f.ownsLevel.confidence)}`, '');
    out.push(...f.ownsLevel.items.map((i) => `- ${i.replace(/\[/g, '\\[').replace(/\]/g, '\\]')}`));
  }

  if (f.stats) {
    const s = f.stats;
    const at = (k: 'health' | 'magicka' | 'stamina') => [k[0].toUpperCase() + k.slice(1), String(s.stored[k]), String(s.race.start[k]), `+${s.offsets[k]}`, String(s.class.statWeights[k]), String(s.race.regen[k])];
    out.push('', `## Stats ${conf(s.confidence)}`, '', `${ref(s.record)}: ${s.flags.map((x) => `\`${x}\``).join(', ')}.`, '');
    out.push(table(['', 'Stored', 'Race start', 'Offset', 'Class weight', 'Regen'], [at('health'), at('magicka'), at('stamina')]));
    out.push('', table(['Skill', 'Stored', 'Class weight'], [...s.skills].sort((a, b) => b.stored - a.stored).map((k) => [k.skill, String(k.stored), String(k.weight)])));
    const ai = s.ai ? ' · ' + Object.entries(s.ai).map(([k, v]) => `${k} ${v}`).join(' · ') : '';
    out.push('', cell(`Race ${ref(s.race.ref)} · class ${ref(s.class.ref)}${s.combatStyle ? ` · combat style ${ref(s.combatStyle)}` : ''} · speed ${s.speed}%${ai}.`));
    if (s.note) out.push('', cell(s.note));
  }

  if (f.loot) {
    out.push('', `## Loot ${conf(f.loot.confidence)}`, '', cell(`From ${f.loot.source}.${f.loot.rule ? ` ${f.loot.rule[0].toUpperCase()}${f.loot.rule.slice(1)}.` : ''}`), '');
    out.push(
      table(
        ['Item', 'Kind', 'List', 'Tiers'],
        f.loot.rows.map((l) => [
          l.item,
          l.kind,
          ref(l.list),
          l.tiers.map((t) => `@${t.at} ${ref(t.record)}${t.enchantment ? ` (${ref(t.enchantment)})` : ''}`).join(' · '),
        ]),
      ),
    );
  }

  if (f.lists) {
    out.push('', `## Lists that draw them ${conf(f.lists.confidence)}`, '');
    out.push(
      table(
        ['List', 'Draws', 'Owner'],
        f.lists.rows.map((l) => {
          const qual = [l.override, l.gate].filter(Boolean).join('; ');
          const draws = l.seeFamily
            ? `see *${titles[l.seeFamily] ?? l.seeFamily}*`
            : (l.entries ?? [])
                // "Fire + Frost" already says two; a bare label with a count says "×2".
                .map((e) => `${e.label}${e.count && e.count > 1 && !e.label.includes(' + ') ? ` ×${e.count}` : ''} @${e.at}`).join(' · ') + (l.note ? ` (${l.note})` : '');
          return [ref(l.list) + (qual ? ` (${qual})` : ''), draws, l.owner];
        }),
      ),
    );
  }

  if (f.placed) {
    out.push('', `## ${f.placed.title} ${conf(f.placed.confidence)}`, '');
    out.push(
      table(
        ['Name', 'Placed in'],
        f.placed.rows.map((p) => {
          const base = [p.base ? refs(p.base) : '', p.baseNote ?? ''].filter(Boolean).join(', ');
          const name = base ? `${p.name} (${base})` : p.name;
          const locs = (p.locations ?? []).map((l) =>
            [
              ref(l.cell) + (l.persistent ? ' persistent' : ''),
              l.ref ? `ref ${ref(l.ref)}` : '',
              l.refText ?? '',
              l.disabled ? 'initially disabled' : '',
              l.note ?? '',
            ].filter(Boolean).join(', '),
          );
          const where = [p.notPlaced ? 'not placed' : '', locs.join(' · '), p.quest ?? '', p.note ?? ''].filter(Boolean).join('; ');
          return [name, where];
        }),
      ),
    );
  }

  if (f.gear) {
    out.push('', `## Gear ${conf(f.gear.confidence)}`, '');
    out.push(table(['Records', 'Weapons', 'Armor', 'Skin'], f.gear.rows.map((g) => [g.records, g.weapons, g.armor, g.skin])));
  }
  if (f.gearLists) {
    out.push('', `## Gear lists ${conf(f.gearLists.confidence)}`, '');
    out.push(table(['List', 'Rolls'], f.gearLists.rows.map((g) => [`${ref(g.list)} (${g.gate})`, `${g.rolls} @${g.levels.join(' · ')}`])));
  }
  if (f.gearItems) {
    out.push('', `## Gear items ${conf(f.gearItems.confidence)}`, '');
    out.push(
      table(['Item', 'Kind', 'Wearable by the player'], f.gearItems.rows.map((g) => [g.item, g.kind, (g.playable ? 'yes' : 'no') + (g.note ? ` (${g.note})` : '')])),
    );
  }
  return out.join('\n') + '\n';
}

export function renderGroup(g: GroupData, titles: Record<string, string>): string {
  const out: string[] = [banner(`${g.id}/group`), ''];
  if (g.meta.spec) out.push(`Spec \`${g.meta.spec}\`.`, '');
  if (g.intro) out.push(g.intro, '');
  out.push(table(['Page', 'Holds'], g.families.map((f) => [`*${titles[f.id] ?? f.id}*`, f.holds])));
  if (g.sweep) out.push('', `## ${g.sweep.title} ${conf(g.sweep.confidence)}`, '', g.sweep.text);
  if (g.filedElsewhere) out.push('', '### Filed elsewhere', '', table(['Record', 'What it is', 'Where it belongs'], g.filedElsewhere.map((r) => [r.record, r.what, r.where])));
  if (g.neverMet) out.push('', '### Never met as enemies', '', table(['Record', 'What it is', 'Why'], g.neverMet.map((r) => [r.record, r.what, r.why])));
  if (g.neverInGame) out.push('', `### Records never met in game ${conf(g.neverInGame.confidence)}`, '', table(['Record', 'Why'], g.neverInGame.rows.map((r) => [r.record, r.why])));
  return out.join('\n') + '\n';
}

function render(path: string): string {
  const [group, id] = path.split('/');
  if (!id || id === 'group') {
    const g = Group.parse(JSON.parse(readFileSync(join(census, group, 'group.json'), 'utf8')));
    const titles = Object.fromEntries(
      g.families.map((f) => [f.id, Family.parse(JSON.parse(readFileSync(join(census, group, `${f.id}.json`), 'utf8'))).title]),
    );
    return renderGroup(g, titles);
  }
  const titles = Object.fromEntries(
    readdirSync(join(census, group))
      .filter((x) => x.endsWith('.json') && x !== 'group.json')
      .map((x) => { const d = JSON.parse(readFileSync(join(census, group, x), 'utf8')); return [d.id, d.title]; }),
  );
  return renderFamily(Family.parse(JSON.parse(readFileSync(join(census, group, `${id}.json`), 'utf8'))), titles);
}

const arg = process.argv[2];
if (!arg) {
  console.error('usage: npm run confluence -- <group>[/<family>] | --all');
  process.exit(1);
} else if (arg === '--all') {
  for (const group of readdirSync(census)) {
    if (group === 'schema' || !statSync(join(census, group)).isDirectory()) continue;
    for (const f of readdirSync(join(census, group)).filter((x) => x.endsWith('.json'))) {
      const path = `${group}/${f.slice(0, -5)}`;
      const file = join(import.meta.dirname, '..', '.confluence', `${path}.md`);
      mkdirSync(dirname(file), { recursive: true });
      writeFileSync(file, render(path));
      console.log(`wrote site/.confluence/${path}.md`);
    }
  }
} else process.stdout.write(render(arg));
