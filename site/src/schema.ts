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
  .refine((r) => r.edid || r.formKey, 'a ref needs an edid or a formKey');

export const Confidence = z.enum(['verified', 'community', 'unverified']);

// Where a record's level comes from. Mirrors the census Level column.
export const Level = z.discriminatedUnion('kind', [
  // `also`: the levels of the row's later records, in record order, when they differ (shown "10 / 20").
  z.strictObject({ kind: z.literal('fixed'), value: z.number().int().min(0), also: z.array(z.number().int().min(0)).optional() }),
  z.strictObject({
    kind: z.literal('pcMult'),
    mult: z.number().positive(),
    min: z.number().int().min(0),
    max: z.number().int().min(0),
    from: Ref.optional(), // set when the record takes its level (Stats) from a template
  }),
  z.strictObject({ kind: z.literal('template'), value: z.number().int().min(0), from: Ref }),
  z.strictObject({ kind: z.literal('list'), from: Ref, rungs: z.array(z.number().int().min(0)).min(1) }),
]);

// The Ehlnofey target. The one non-vanilla field in the census (see CLAUDE.md, "Census site").
export const Target = z.strictObject({
  band: BandId,
  level: z.number().int().positive().optional(),
  status: z.enum(['decided', 'proposed']),
  source: z.string().min(1),
});

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

const ListRow = z.strictObject({
  list: Ref,
  override: z.string().optional(),
  gate: z.string().optional(),
  entries: z.array(ListEntry).optional(),
  seeFamily: z.string().optional(), // the list is documented in full on that family's page
  note: z.string().optional(),
  owner: z.string().min(1),
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
    z.strictObject({ list: Ref, gate: z.string(), rolls: z.string(), levels: z.array(z.number().int()) }),
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
  meta: Meta,
  intro: z.string().optional(),
  families: z.array(z.strictObject({ id: z.string(), holds: z.string() })).min(1),
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

export type FamilyData = z.infer<typeof Family>;
export type GroupData = z.infer<typeof Group>;
export type BandsData = z.infer<typeof Bands>;
export type LevelData = z.infer<typeof Level>;
export type RefData = z.infer<typeof Ref>;
export type RecordRowData = z.infer<typeof RecordRow>;
