// Publishes the census JSON as-is at /data/<group>/<family>.json, /data/bands.json, plus
// /data/index.json, a manifest of every file, so other tools can read the census straight off the site.
import type { APIRoute } from 'astro';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';

const census = join(process.cwd(), '..', 'census');

function files(): string[] {
  const out = ['bands'];
  for (const group of readdirSync(census)) {
    const dir = join(census, group);
    if (group === 'schema' || !statSync(dir).isDirectory()) continue;
    for (const f of readdirSync(dir)) if (f.endsWith('.json')) out.push(`${group}/${f.slice(0, -5)}`);
  }
  return out;
}

export function getStaticPaths() {
  return [...files(), 'index'].map((path) => ({ params: { path } }));
}

export const GET: APIRoute = ({ params }) => {
  const body =
    params.path === 'index'
      ? JSON.stringify({ files: files().map((f) => `${f}.json`) }, null, 2)
      : readFileSync(join(census, `${params.path}.json`), 'utf8');
  return new Response(body, { headers: { 'Content-Type': 'application/json' } });
};
