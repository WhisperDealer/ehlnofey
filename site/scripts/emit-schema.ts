// Writes census/schema/*.schema.json from src/schema.ts, then validates every census JSON file
// against the Zod schema. Run after changing src/schema.ts: `npm run schema`.
import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { z } from 'zod';
import { Bands, Family, Group } from '../src/schema.ts';

const census = join(import.meta.dirname, '..', '..', 'census');

const out: Record<string, z.ZodType> = {
  'census-family.schema.json': Family,
  'census-group.schema.json': Group,
  'census-bands.schema.json': Bands,
};
for (const [file, schema] of Object.entries(out)) {
  const json = z.toJSONSchema(schema, { unrepresentable: 'any', io: 'input' });
  writeFileSync(join(census, 'schema', file), JSON.stringify(json, null, 2) + '\n');
  console.log(`wrote census/schema/${file}`);
}

let failed = 0;
for (const group of readdirSync(census)) {
  const dir = join(census, group);
  if (!statSync(dir).isDirectory() || group === 'schema') continue;
  for (const file of readdirSync(dir).filter((f) => f.endsWith('.json'))) {
    const path = join(dir, file);
    const schema = file === 'group.json' ? Group : Family;
    const result = schema.safeParse(JSON.parse(readFileSync(path, 'utf8')));
    const rel = relative(join(census, '..'), path).split(sep).join('/');
    if (result.success) console.log(`ok    ${rel}`);
    else {
      failed++;
      console.log(`FAIL  ${rel}\n${z.prettifyError(result.error)}`);
    }
  }
}
const bands = Bands.safeParse(JSON.parse(readFileSync(join(census, 'bands.json'), 'utf8')));
if (!bands.success) { failed++; console.log(`FAIL  census/bands.json\n${z.prettifyError(bands.error)}`); }
else console.log('ok    census/bands.json');
process.exit(failed ? 1 : 0);
