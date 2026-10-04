// Rendering helpers shared by the pages and the Confluence renderer. They return HTML strings,
// so Astro templates use them with set:html. Everything goes through esc() first.
import type { LevelData, RefData } from '../schema.ts';

export const esc = (s: string) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

// The census inline markup: `code` and *italic*. Bare FormIDs after an EditorID stay plain text.
export function md(s: string): string {
  return esc(s)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/(^|[\s(])\*([^*\s][^*]*?)\*(?=[\s).,;:]|$)/g, '$1<em>$2</em>');
}

const master = (fk: string) => fk.split(':')[1];
const hex = (fk: string) => fk.split(':')[0];

// EditorID plus FormID, the census convention: the master is shown only when it is not Skyrim.esm.
// The full FormKey is copied on click.
export function ref(r: RefData): string {
  const name = r.edid ? `<code>${esc(r.edid)}</code>` : r.label ? esc(r.label) : '';
  if (!r.formKey) return name;
  const m = master(r.formKey);
  const fk = `<span class="fk" data-copy="${esc(r.formKey)}" title="${esc(r.formKey)} (click to copy)">${hex(
    r.formKey,
  )}${m === 'Skyrim.esm' ? '' : `<span class="master">:${esc(m)}</span>`}</span>`;
  return name ? `${name} ${fk}` : fk;
}

export const refs = (rs: RefData[], sep = ' · ') => rs.map(ref).join(sep);

export function levelText(l: LevelData): string {
  switch (l.kind) {
    case 'fixed':
      return String(l.value);
    case 'pcMult':
      return `PC×${l.mult} [${l.min}–${l.max}]${l.from ? `, from ${ref(l.from)}` : ''}`;
    case 'template':
      return `${l.value}, from ${ref(l.from)}`;
    case 'list':
      return `from ${ref(l.from)} (${l.rungs.join(' · ')})`;
  }
}

// What the level-on-bands strip draws for a vanilla level.
export type LevelMark =
  | { kind: 'point'; v: number }
  | { kind: 'range'; min: number; max: number }
  | { kind: 'rungs'; vs: number[] };

export function levelMark(l: LevelData): LevelMark {
  switch (l.kind) {
    case 'fixed':
    case 'template':
      return { kind: 'point', v: l.value };
    case 'pcMult':
      return { kind: 'range', min: l.min, max: l.max };
    case 'list':
      return { kind: 'rungs', vs: l.rungs };
  }
}

export const levelSpan = (l: LevelData): [number, number] => {
  const m = levelMark(l);
  if (m.kind === 'point') return [m.v, m.v];
  if (m.kind === 'range') return [m.min, m.max];
  return [Math.min(...m.vs), Math.max(...m.vs)];
};
