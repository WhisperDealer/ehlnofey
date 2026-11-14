// Colours for the gear bars, tuned for the site's dark sky. One per material; enchanted shares its
// material's colour and is hatched; named items take the ITEM colours in order.
import { MATERIALS } from '../schema.ts';
import type { GearData } from '../schema.ts';

export const MATERIAL_COLOURS: Record<keyof typeof MATERIALS, string> = {
  fur: '#8c6b4b',
  hide: '#b08f5f',
  studded: '#8a725c',
  leather: '#7a5638',
  scaled: '#948d6b',
  iron: '#6b737a',
  'banded-iron': '#545b62',
  steel: '#9aa5ae',
  'steel-plate': '#c6cfd6',
  imperial: '#a0574a',
  orcish: '#5f7f45',
  dwarven: '#b5843a',
  elven: '#cbb554',
  glass: '#5fa88f',
  ebony: '#5a4f66',
  daedric: '#9a3a32',
  nordic: '#5a7fa6',
  stalhrim: '#8fc6d6',
  bonemold: '#c8b89a',
  chitin: '#6f8f5a',
  'ancient-nord': '#7a776a',
  falmer: '#a08a5a',
  forsworn: '#7a5a3a',
  hunting: '#9a7a4e',
  long: '#7d6340',
};
const LIGHT = new Set(['steel', 'steel-plate', 'elven', 'hide', 'scaled', 'stalhrim', 'bonemold']);
const ITEM = ['#d5622e', '#c9c2b0', '#7fb0d0', '#b07fc0'];

export interface Segment {
  key: string;
  label: string;
  colour: string;
  dark: boolean; // draw the label in dark ink
  enchanted: boolean;
}

// Every segment a ledger's gear can draw, keyed as choiceKey() keys them.
export function segments(gear: GearData[]): Map<string, Segment> {
  const out = new Map<string, Segment>();
  let item = 0;
  for (const g of gear)
    for (const c of g.choices) {
      if (c.material) {
        const key = `${c.material}${c.enchanted ? '+e' : ''}`;
        if (!out.has(key))
          out.set(key, {
            key,
            label: `${c.enchanted ? 'Enchanted ' : ''}${MATERIALS[c.material]}`,
            colour: MATERIAL_COLOURS[c.material],
            dark: LIGHT.has(c.material),
            enchanted: !!c.enchanted,
          });
      } else {
        const key = c.item?.label ?? c.item?.edid ?? '?';
        if (!out.has(key)) out.set(key, { key, label: key, colour: ITEM[item++ % ITEM.length], dark: false, enchanted: false });
      }
    }
  return out;
}
