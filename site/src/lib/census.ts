// Loads the census for the pages: the bands, the groups and their families, in order.
import { getCollection } from 'astro:content';
import bandsJson from '../../../census/bands.json';
import { Bands, type BandsData } from '../schema.ts';

export const bands: BandsData = Bands.parse(bandsJson);
export type Band = BandsData['bands'][number];

export const bandById = (id: string) => bands.bands.find((b) => b.id === id)!;
export const bandOfLevel = (v: number) => bands.bands.find((b) => v >= b.min && (b.max === null || v <= b.max))!;

// The scale every strip and bar shares. Bands I–IX take one unit per level (1–81), so each
// segment is as wide as its range, as on the Bands of Power poster. Band X is a fixed cap that
// maps 82–200 linearly, wide enough to show Miraak at 100 and Alduin at 150 apart.
const CAP_UNITS = 16;
const CAP_TOP = 200;
const TOTAL = bands.scaleMax + CAP_UNITS;

export function pos(v: number): number {
  const units =
    v <= bands.scaleMax
      ? Math.max(v, 1) - 0.5
      : bands.scaleMax + ((Math.min(v, CAP_TOP) - (bands.scaleMax + 1)) / (CAP_TOP - bands.scaleMax - 1)) * CAP_UNITS;
  return (units / TOTAL) * 100;
}

export function segment(b: Band): { left: number; width: number } {
  if (b.max === null) return { left: (bands.scaleMax / TOTAL) * 100, width: (CAP_UNITS / TOTAL) * 100 };
  return { left: ((b.min - 1) / TOTAL) * 100, width: ((b.max - b.min + 1) / TOTAL) * 100 };
}

export const bandRange = (b: Band) => (b.max === null ? `Level ${b.min}+` : `Levels ${b.min}–${b.max}`);

// Every group, top-level and sub-group alike, in order. A sub-group (`parent`) carries its parent's
// id and title; a parent carries its sub-groups. Pages that list groups show only the top level.
export async function loadCensus() {
  const groups = (await getCollection('groups')).map((g) => g.data).sort((a, b) => a.order - b.order);
  const families = (await getCollection('families')).map((f) => f.data).sort((a, b) => a.order - b.order);
  const withPages = groups.map((g) => {
    const parent = g.parent ? groups.find((p) => p.id === g.parent) : undefined;
    if (g.parent && !parent) throw new Error(`census/${g.id}/group.json names parent "${g.parent}", which has no census/${g.parent}/group.json`);
    return {
      ...g,
      parentGroup: parent ? { id: parent.id, title: parent.title } : undefined,
      familyPages: g.families.map((ref) => {
        const fam = families.find((f) => f.group === g.id && f.id === ref.id);
        if (!fam) throw new Error(`census/${g.id}/group.json lists "${ref.id}", which has no census/${g.id}/${ref.id}.json`);
        return { ...fam, holds: ref.holds };
      }),
    };
  });
  type Node = (typeof withPages)[number] & { subgroups: Node[] };
  const nodes: Node[] = withPages.map((g) => ({ ...g, subgroups: [] }));
  for (const n of nodes) n.subgroups = nodes.filter((s) => s.parent === n.id);
  return nodes;
}

export type CensusGroup = Awaited<ReturnType<typeof loadCensus>>[number];

// Breadcrumbs down to a group: its parent first, when it has one.
export const groupCrumbs = (g: CensusGroup) => [
  ...(g.parentGroup ? [{ label: g.parentGroup.title, path: `${g.parentGroup.id}/` }] : []),
  { label: g.title, path: `${g.id}/` },
];

// Every family page in a group and its sub-groups, for counts on cards that show the parent.
export const allFamilies = (g: CensusGroup): CensusGroup['familyPages'] => [...g.familyPages, ...g.subgroups.flatMap(allFamilies)];

export const href = (path = '') => `${import.meta.env.BASE_URL.replace(/\/$/, '')}/${path}`;
