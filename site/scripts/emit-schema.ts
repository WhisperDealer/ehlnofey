// Writes census/schema/*.schema.json and ledgers/schema/*.schema.json from src/schema.ts, then
// validates every census and ledger JSON file against the Zod schema, and runs the ledger checks
// (src/lib/ledger.ts). Run after changing src/schema.ts or any JSON: `npm run schema`.
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { z } from 'zod';
import { Bands, Family, Group, Ledger } from '../src/schema.ts';
import { checkLedger } from '../src/lib/ledger.ts';

const census = join(import.meta.dirname, '..', '..', 'census');
const ledgers = join(import.meta.dirname, '..', '..', 'ledgers');

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

mkdirSync(join(ledgers, 'schema'), { recursive: true });
writeFileSync(
  join(ledgers, 'schema', 'ledger.schema.json'),
  JSON.stringify(z.toJSONSchema(Ledger, { unrepresentable: 'any', io: 'input' }), null, 2) + '\n',
);
console.log('wrote ledgers/schema/ledger.schema.json');

let failed = 0;
const families: z.infer<typeof Family>[] = [];
for (const group of readdirSync(census)) {
  const dir = join(census, group);
  if (!statSync(dir).isDirectory() || group === 'schema') continue;
  for (const file of readdirSync(dir).filter((f) => f.endsWith('.json'))) {
    const path = join(dir, file);
    const schema = file === 'group.json' ? Group : Family;
    const result = schema.safeParse(JSON.parse(readFileSync(path, 'utf8')));
    const rel = relative(join(census, '..'), path).split(sep).join('/');
    // Cross-page links must name a family file that exists.
    const missing: string[] = [];
    if (result.success && file !== 'group.json')
      for (const l of (result.data as z.infer<typeof Family>).lists?.rows ?? [])
        for (const d of l.drawnBy ?? [])
          if (d.page && !existsSync(join(census, `${d.page}.json`))) missing.push(`drawnBy page "${d.page}" has no census/${d.page}.json`);
    if (missing.length) {
      failed++;
      console.log(`FAIL  ${rel}\n${missing.map((m) => `✖ ${m}`).join('\n')}`);
    } else if (result.success) {
      console.log(`ok    ${rel}`);
      if (file !== 'group.json') families.push(result.data as z.infer<typeof Family>);
    }
    else {
      failed++;
      console.log(`FAIL  ${rel}\n${z.prettifyError(result.error)}`);
    }
  }
}
const bands = Bands.safeParse(JSON.parse(readFileSync(join(census, 'bands.json'), 'utf8')));
if (!bands.success) { failed++; console.log(`FAIL  census/bands.json\n${z.prettifyError(bands.error)}`); }
else console.log('ok    census/bands.json');

// The ledgers: schema, then the checks against the census. Errors fail the run; warnings are
// decisions still owed, shown on the ledger page too.
for (const file of existsSync(ledgers) ? readdirSync(ledgers).filter((f) => f.endsWith('.json')) : []) {
  const rel = `ledgers/${file}`;
  const result = Ledger.safeParse(JSON.parse(readFileSync(join(ledgers, file), 'utf8')));
  if (!result.success) {
    failed++;
    console.log(`FAIL  ${rel}\n${z.prettifyError(result.error)}`);
    continue;
  }
  if (!bands.success) continue;
  const findings = checkLedger(result.data, families, bands.data);
  const errors = findings.filter((f) => f.level === 'error');
  if (errors.length) failed++;
  console.log(`${errors.length ? 'FAIL' : 'ok  '}  ${rel}${findings.length ? ` (${errors.length} errors, ${findings.length - errors.length} warnings)` : ''}`);
  for (const f of findings) console.log(`  ${f.level === 'error' ? '✖' : '⚠'} ${f.where}: ${f.text}`);
}
process.exit(failed ? 1 : 0);
