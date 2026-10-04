import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { Family, Group } from './schema.ts';

// census/<group>/group.json is a group page; every other census/<group>/*.json is a family page.
const families = defineCollection({
  loader: glob({ base: '../census', pattern: ['*/*.json', '!*/group.json', '!schema/**'] }),
  schema: Family,
});

const groups = defineCollection({
  loader: glob({ base: '../census', pattern: '*/group.json', generateId: ({ entry }) => entry.split('/')[0] }),
  schema: Group,
});

export const collections = { families, groups };
