// The census JSON schema. One source for three consumers: Astro's content collections
// (src/content.config.ts), the JSON Schema files editors and Test-CensusJson.ps1 read
// (scripts/emit-schema.ts → census/schema/), and the Confluence renderer.
//
// Strings may carry a little inline markup, kept from the Confluence pages:
// `code` for EditorIDs and *italic* for page names. src/lib/format.ts renders it.
import { z } from 'zod';

export const BAND_IDS = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'] as const;
export const BandId = z.enum(BAND_IDS);

// `<6 hex>:<master>`, never bare hex (CLAUDE.md: resolve FormKeys by master).
export const FormKey = z
  .string()
  .regex(/^[0-9A-F]{6}:[A-Za-z0-9 _.'-]+\.(esm|esp|esl)$/, 'FormKey must be <6 upper-case hex>:<Master.esm>');

export const Ref = z
  .strictObject({
    edid: z.string().min(1).optional(),
    formKey: FormKey.optional(),
    label: z.string().optional(), // for things with no EditorID, e.g. "Tamriel cell"
  })
  .refine((r) => r.edid || r.formKey || r.label, 'a ref needs an edid, a formKey or a label');

export const Confidence = z.enum(['verified', 'community', 'unverified']);

// Where a record's level comes from. Mirrors the census Level column.
export const Level = z.discriminatedUnion('kind', [
  // `also`: the levels of the row's later records, in record order, when they differ (shown "10 / 20").
  z.strictObject({ kind: z.literal('fixed'), value: z.number().int().min(0), also: z.array(z.number().int().min(0)).optional() }),
  z.strictObject({
    kind: z.literal('pcMult'),
    mult: z.number().positive(),
    min: z.number().int().min(0),
    max: z.number().int().min(0).optional(), // absent: no CalcMaxLevel, so no cap
    from: Ref.optional(), // set when the record takes its level (Stats) from a template
  }),
  z.strictObject({ kind: z.literal('template'), value: z.number().int().min(0), from: Ref }),
  z.strictObject({ kind: z.literal('list'), from: Ref, rungs: z.array(z.number().int().min(0)).min(1) }),
]);

// The Ehlnofey target. The one non-vanilla field in the census (see CLAUDE.md, "Census site").
export const BandTarget = z.strictObject({
  band: BandId,
  level: z.number().int().positive().optional(),
  status: z.enum(['proposed', 'implemented']), // implemented: the built mod sets this level
  source: z.string().min(1),
});
// An exception to bone 1: the record keeps scaling with the player. Only the user decides one,
// and archetype-tiers.md records it (the Shadowrend Shadow, user 2026-10-05).
export const ScalesTarget = z.strictObject({
  scales: z.literal(true),
  status: z.enum(['proposed', 'implemented']),
  source: z.string().min(1),
});
// Left out of the delevelling: the record keeps its vanilla level and the mod never touches it
// (harmless animals; user 2026-11-12: elk, cows, chickens, deer). In no band.
export const UnchangedTarget = z.strictObject({
  unchanged: z.literal(true),
  source: z.string().min(1),
});
export const Target = z.union([BandTarget, ScalesTarget, UnchangedTarget]);

const Meta = z.strictObject({
  spec: z.string().optional(),
  updated: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

export const RecordRow = z.strictObject({
  id: z.string().regex(/^[a-z0-9-]+$/),
  name: z.string().min(1),
  encounter: z.string().optional(), // where this row is fought, when a family is split by fight
  records: z.array(Ref).min(1),
  race: Ref.optional(),
  factions: z.array(Ref).optional(),
  level: Level,
  flags: z.array(z.string()).optional(),
  target: Target,
  note: z.string().optional(),
});

const ListEntry = z.strictObject({
  at: z.number().int().min(1),
  label: z.string().min(1),
  count: z.number().int().min(1).optional(),
});

// A migrated family page, `<group>/<family>` (the folder and file under census/). emit-schema.ts
// checks that the file exists.
export const PagePath = z.string().regex(/^[a-z0-9-]+\/[a-z0-9-]+$/, 'page is <group>/<family>, a census family file');

// Records filed on another page that draw this list (user, 2026-11-12: Warlocks and Bandits lend their
// lists to other families, e.g. the Vaermina Devotees take Stats from LCharWarlockStorm).
const DrawnBy = z.strictObject({
  name: z.string().min(1), // what they are, e.g. "Vaermina Devotees"
  records: z.array(Ref).min(1),
  how: z.enum(['template', 'entry']), // template: the records name the list as their template; entry: lists that hold it
  page: PagePath.optional(), // the migrated page they are filed on
  where: z.string().optional(), // a page not migrated yet, as text: "Factions → *Silver Hand*"
  note: z.string().optional(),
});

const ListRow = z.strictObject({
  list: Ref,
  override: z.string().optional(),
  gate: z.string().optional(),
  entries: z.array(ListEntry).optional(),
  seeFamily: z.string().regex(/^[a-z0-9-]+$/, 'seeFamily is a family id in the same group').optional(), // the list is documented in full on that family's page
  note: z.string().optional(),
  owner: z.string().min(1),
  drawnBy: z.array(DrawnBy).optional(),
});

const Location = z.strictObject({
  cell: Ref,
  persistent: z.boolean().optional(),
  ref: Ref.optional(),
  refText: z.string().optional(),
  disabled: z.boolean().optional(),
  note: z.string().optional(),
});

const PlacedRow = z.strictObject({
  name: z.string().min(1),
  base: z.array(Ref).optional(),
  baseNote: z.string().optional(),
  locations: z.array(Location).optional(),
  quest: z.string().optional(),
  notPlaced: z.boolean().optional(),
  note: z.string().optional(),
});

const section = <T extends z.ZodType>(row: T) =>
  z.strictObject({ confidence: Confidence, rows: z.array(row) });

export const Family = z.strictObject({
  $schema: z.string().optional(),
  id: z.string().regex(/^[a-z0-9-]+$/),
  group: z.string().regex(/^[a-z0-9-]+$/),
  title: z.string().min(1),
  order: z.number().int(),
  meta: Meta,
  records: section(RecordRow),
  // Records of the same enemy that are never fought (cutscenes, bases, test copies): a log, not rows.
  otherRecords: section(
    z.strictObject({ records: z.array(Ref).min(1), name: z.string(), level: Level, where: z.string() }),
  ).optional(),
  ownsLevel: z.strictObject({ confidence: Confidence, items: z.array(z.string()) }).optional(),
  // Conjured pages: how each summon is reached, by the player and by NPCs.
  summonedBy: section(
    z.strictObject({ name: z.string().min(1), spell: z.string(), player: z.string(), npcs: z.string() }),
  ).optional(),
  // Gear the player can take from the enemy: each list it drops, walked to its tiers.
  loot: z
    .strictObject({
      confidence: Confidence,
      source: z.string(), // where the loot comes from, e.g. the death item
      rule: z.string().optional(), // how a tier is picked
      rows: z.array(
        z.strictObject({
          item: z.string(),
          kind: z.string(),
          list: Ref,
          tiers: z.array(z.strictObject({ at: z.number().int().min(1), record: Ref, enchantment: Ref.optional() })).min(1),
        }),
      ),
    })
    .optional(),
  lists: section(ListRow).optional(),
  placed: z
    .strictObject({ title: z.enum(['Placed only', 'Placed']), confidence: Confidence, rows: z.array(PlacedRow) })
    .optional(),
  gear: section(
    z.strictObject({ records: z.string(), weapons: z.string(), armor: z.string(), skin: z.string() }),
  ).optional(),
  gearLists: section(
    // gate and levels are absent for an outfit or a plain list with no level gates.
    z.strictObject({ list: Ref, gate: z.string().optional(), rolls: z.string(), levels: z.array(z.number().int()).optional() }),
  ).optional(),
  gearItems: section(
    z.strictObject({ item: z.string(), kind: z.string(), playable: z.boolean(), note: z.string().optional() }),
  ).optional(),
});

export const Group = z.strictObject({
  $schema: z.string().optional(),
  id: z.string().regex(/^[a-z0-9-]+$/),
  title: z.string().min(1),
  order: z.number().int(),
  // A sub-group names its parent group (Vampires under Undead). A parent lists its sub-groups on its
  // page, and its own families may be empty while every family sits in a sub-group.
  parent: z.string().regex(/^[a-z0-9-]+$/).optional(),
  meta: Meta,
  intro: z.string().optional(),
  families: z.array(z.strictObject({ id: z.string(), holds: z.string() })),
  sweep: z.strictObject({ title: z.string(), confidence: Confidence, text: z.string() }).optional(),
  filedElsewhere: z.array(z.strictObject({ record: z.string(), what: z.string(), where: z.string() })).optional(),
  neverMet: z.array(z.strictObject({ record: z.string(), what: z.string(), why: z.string() })).optional(),
  neverInGame: section(z.strictObject({ record: z.string(), why: z.string() })).optional(),
});

export const Bands = z.strictObject({
  $schema: z.string().optional(),
  source: z.string(),
  title: z.string(),
  tagline: z.string(),
  scaleMax: z.number().int(),
  bands: z
    .array(
      z.strictObject({
        id: BandId,
        name: z.string(),
        min: z.number().int(),
        max: z.number().int().nullable(),
        colour: z.string().regex(/^#[0-9a-f]{6}$/i),
        who: z.string(),
        named: z.array(z.strictObject({ name: z.string(), level: z.number().int() })).optional(),
        // The home page lists only these census names for the band, in this order, when set.
        featured: z.array(z.string()).optional(),
      }),
    )
    .length(10),
});

// ---------------------------------------------------------------------------------------------
// The ledgers (arch-docs/design/ledgers.md): Ehlnofey's decisions for a group, in ledgers/<id>.json.
// A ledger points at census rows and lists; it never copies their vanilla facts.

// `<group>/<family>#<row-id>`: a Records row on a census family page.
export const RowPointer = z
  .string()
  .regex(/^[a-z0-9-]+\/[a-z0-9-]+#[a-z0-9-]+$/, 'row is <group>/<family>#<row-id>, a census Records row');

// proposed: suggested, not yet the user's call · decided: the user's call · implemented: the built patch does it.
export const DecisionStatus = z.enum(['proposed', 'decided', 'implemented']);

// A list or outfit the ledger edits: always a real record, so the generator can find it.
const ListRef = z.strictObject({ edid: z.string().min(1), formKey: FormKey });

// The gear materials a choice may keep. Dragonplate, dragonscale and dragonbone are absent on
// purpose: dragon smithing gear is craft-only (CLAUDE.md), so no ledger can put it in a list.
export const MATERIALS = {
  iron: 'Iron',
  'banded-iron': 'Banded Iron',
  steel: 'Steel',
  'steel-plate': 'Steel Plate',
  imperial: 'Imperial',
  fur: 'Fur',
  hide: 'Hide',
  studded: 'Studded',
  leather: 'Leather',
  scaled: 'Scaled',
  orcish: 'Orcish',
  dwarven: 'Dwarven',
  elven: 'Elven',
  glass: 'Glass',
  ebony: 'Ebony',
  daedric: 'Daedric',
  nordic: 'Nordic',
  stalhrim: 'Stalhrim',
  bonemold: 'Bonemold',
  chitin: 'Chitin',
  'ancient-nord': 'Ancient Nord',
  falmer: 'Falmer',
  forsworn: 'Forsworn',
  hunting: 'Hunting (bow)',
  long: 'Long (bow)',
} as const;
export const Material = z.enum(Object.keys(MATERIALS) as [keyof typeof MATERIALS, ...(keyof typeof MATERIALS)[]]);

const Decision = { status: DecisionStatus, source: z.string().min(1) };

// Which rungs a leveled list keeps, and how heavily (weight = duplicate entries; 0 = dropped).
// One roster may apply to several lists that share it (the bandit mook ladder and its voice lists).
export const Roster = z.strictObject({
  id: z.string().regex(/^[a-z0-9-]+$/),
  title: z.string().min(1),
  lists: z.array(ListRef).min(1),
  // How vanilla rolls the first list: every unlocked gate (`CalculateFromAllLevels…`) or the highest
  // only. With each entry's `gate`, it draws the vanilla line on the level chart.
  vanillaRoll: z.enum(['all', 'highest']).optional(),
  entries: z
    .array(
      z.strictObject({
        row: RowPointer,
        weight: z.number().int().min(0),
        gate: z.number().int().min(1).optional(), // the player level at which vanilla unlocks this rung (checked against the census list)
        why: z.string().optional(), // say why a rung is dropped or weighted unusually
      }),
    )
    .min(1)
    .refine((es) => es.some((e) => e.weight > 0), 'a roster must keep at least one rung'),
  note: z.string().optional(),
  ...Decision,
});

// One thing a gear list may roll: a material (optionally enchanted) or a named item.
export const GearChoice = z
  .strictObject({
    material: Material.optional(),
    item: Ref.optional(), // a specific item that is not a plain material, e.g. fire arrows
    enchanted: z.boolean().optional(),
    weight: z.number().int().min(0),
    gate: z.number().int().min(1).optional(), // the player level at which vanilla unlocks it (for the vanilla bars)
    runtime: z.boolean().optional(), // added at `gate` by a start-up quest, not by the list itself
    why: z.string().optional(),
  })
  .refine((c) => (c.material ? !c.item : !!c.item), 'a choice is a material or an item, not both');

export const Gear = z.strictObject({
  id: z.string().regex(/^[a-z0-9-]+$/),
  title: z.string().min(1),
  slot: z.enum(['weapon', 'armor', 'shield', 'ammo']),
  lists: z.array(ListRef).min(1),
  wornBy: z.string().min(1), // who reaches these lists, in words: "the one-handed and tank leaves"
  chanceNone: z.number().int().min(0).max(100).optional(), // the list's own chance of rolling nothing
  vanillaRoll: z.enum(['all', 'highest']).optional(), // as on Roster; with the choices' gates, draws the vanilla bars
  choices: z
    .array(GearChoice)
    .min(1)
    .refine((cs) => cs.some((c) => c.weight > 0), 'a gear list must keep at least one choice'),
  note: z.string().optional(),
  ...Decision,
});

// A fixed level for one census row that owns its level (follow the template chain first).
export const Pin = z.strictObject({
  row: RowPointer,
  level: z.number().int().positive(),
  note: z.string().optional(),
  ...Decision,
});

export const Ledger = z.strictObject({
  $schema: z.string().optional(),
  id: z.string().regex(/^[a-z0-9-]+$/),
  title: z.string().min(1),
  order: z.number().int(),
  meta: Meta,
  census: z.array(z.string().regex(/^[a-z0-9-]+$/)).min(1), // the census groups this ledger decides for
  intro: z.string().optional(),
  rosters: z.array(Roster),
  pins: z.array(Pin),
  gear: z.array(Gear),
  open: z.array(z.strictObject({ title: z.string().min(1), text: z.string().min(1) })).optional(),
});

export type LedgerData = z.infer<typeof Ledger>;
export type RosterData = z.infer<typeof Roster>;
export type GearData = z.infer<typeof Gear>;

export type FamilyData = z.infer<typeof Family>;
export type GroupData = z.infer<typeof Group>;
export type BandsData = z.infer<typeof Bands>;
export type LevelData = z.infer<typeof Level>;
export type RefData = z.infer<typeof Ref>;
export type RecordRowData = z.infer<typeof RecordRow>;
