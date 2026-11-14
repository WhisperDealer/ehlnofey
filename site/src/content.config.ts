import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { Family, Group, Ledger } from './schema.ts';

// census/<group>/group.json is a group page; every other census/<group>/*.json is a family page.
const families = defineCollection({
  loader: glob({ base: '../census', pattern: ['*/*.json', '!*/group.json', '!schema/**'] }),
  schema: Family,
});

const groups = defineCollection({
  loader: glob({ base: '../census', pattern: '*/group.json', generateId: ({ entry }) => entry.split('/')[0] }),
  schema: Group,
});

// ledgers/<id>.json: Ehlnofey's decisions for a group (arch-docs/design/ledgers.md).
const ledgers = defineCollection({
  loader: glob({ base: '../ledgers', pattern: '*.json' }),
  schema: Ledger,
});

export const collections = { families, groups, ledgers };
