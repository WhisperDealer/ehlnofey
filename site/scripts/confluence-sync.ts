// Keeps the Confluence mirror pages in step with census/ without guessing which pages changed.
// Confluence is pushed through the Atlassian MCP (updateConfluencePage, contentFormat "markdown"),
// which a script cannot call, so this script does everything around the push:
//
//   npm run confluence:sync -- status          render every page; list the mirrored pages whose
//                                               render differs from what was last pushed
//   npm run confluence:sync -- mark <key>...   record <key>'s current render as pushed (after a
//                                               successful push and verify); --all marks every page
//   npm run confluence:sync -- verify <key> <fetched.md>
//                                               compare a page fetched back from Confluence (saved
//                                               to a file) with the render, line by line, ignoring
//                                               whitespace and Markdown escaping
//
// "Last pushed" is the sha256 of each page's render, in scripts/confluence-synced.json (committed,
// so every session sees the same state). Pages with no id in confluence-pages.json (e.g. the World
// families) are not mirrored and are skipped. The census-confluence-sync skill (.claude/skills) drives it.
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const here = import.meta.dirname;
const out = join(here, '..', '.confluence');
const pagesFile = join(here, 'confluence-pages.json');
const syncedFile = join(here, 'confluence-synced.json');
const pages: Record<string, string> = JSON.parse(readFileSync(pagesFile, 'utf8'));
const synced: Record<string, string> = existsSync(syncedFile) ? JSON.parse(readFileSync(syncedFile, 'utf8')) : {};

function renderAll(): void {
  const r = spawnSync(process.execPath, [join(here, 'render-confluence.ts'), '--all'], { encoding: 'utf8' });
  if (r.status !== 0) {
    process.stderr.write(r.stderr);
    throw new Error('render-confluence --all failed');
  }
}
const mdFile = (key: string) => join(out, `${key}.md`);
const hash = (key: string) => createHash('sha256').update(readFileSync(mdFile(key))).digest('hex');
const saveSynced = () => {
  const sorted = Object.fromEntries(Object.entries(synced).sort(([a], [b]) => a.localeCompare(b)));
  writeFileSync(syncedFile, JSON.stringify(sorted, null, 2) + '\n');
};

// Confluence round-trips Markdown loosely: escapes, list markers, table padding and blank lines
// come back different. Compare the text a reader sees.
function norm(md: string): string[] {
  return md
    .replace(/\r/g, '')
    .split('\n')
    .map((l) =>
      l
        .replace(/<(https?:[^>\s]+)>/g, '$1')
        .replace(/\\([\\`*_{}[\]()#+\-.!|<>~])/g, '$1')
        .replace(/^\s*[-*+]\s+/, '- ')
        .replace(/^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?\s*$/, '|---|')
        .replace(/\s*\|\s*/g, '|')
        .replace(/[*_`]/g, '')
        .replace(/\s+/g, ' ')
        .trim(),
    )
    .filter((l) => l !== '');
}

// The fetched file may be the page body, the getConfluencePage JSON ({ body }), or a saved tool
// result ([{ type: "text", text: "<that JSON>" }]), so a large result the harness saved to a file
// can be verified without copying it.
function fetchedBody(raw: string): string {
  try {
    let j = JSON.parse(raw);
    if (Array.isArray(j) && typeof j[0]?.text === 'string') j = JSON.parse(j[0].text);
    if (j && typeof j.body === 'string') return j.body;
  } catch {
    // plain Markdown
  }
  return raw;
}

const [cmd, ...args] = process.argv.slice(2);
if (cmd === 'status') {
  renderAll();
  const changed: string[] = [];
  const missing: string[] = [];
  for (const key of Object.keys(pages).sort()) {
    if (!existsSync(mdFile(key))) { missing.push(key); continue; }
    if (synced[key] !== hash(key)) changed.push(key);
  }
  if (missing.length) console.log(`mapped but no census file (stale entry in confluence-pages.json?): ${missing.join(', ')}`);
  if (!changed.length) console.log('in sync: no mirrored page differs from what was last pushed');
  else {
    console.log(`${changed.length} page(s) to push (key → page id → file):`);
    for (const k of changed) console.log(`  ${k} → ${pages[k]} → site/.confluence/${k}.md`);
  }
} else if (cmd === 'mark') {
  renderAll();
  const keys = args[0] === '--all' ? Object.keys(pages).filter((k) => existsSync(mdFile(k))) : args;
  if (!keys.length) throw new Error('usage: mark <key>... | --all');
  for (const k of keys) {
    if (!pages[k]) throw new Error(`no page id for ${k} in confluence-pages.json`);
    synced[k] = hash(k);
  }
  saveSynced();
  console.log(`marked ${keys.length} page(s) as pushed`);
} else if (cmd === 'verify') {
  const [key, fetched] = args;
  if (!key || !fetched) throw new Error('usage: verify <key> <fetched.md>');
  renderAll();
  const want = norm(readFileSync(mdFile(key), 'utf8'));
  const got = norm(fetchedBody(readFileSync(fetched, 'utf8')));
  const gotSet = new Set(got);
  const wantSet = new Set(want);
  const lost = want.filter((l) => !gotSet.has(l));
  const extra = got.filter((l) => !wantSet.has(l));
  if (!lost.length && !extra.length) console.log(`${key}: matches the render (${want.length} lines)`);
  else {
    console.log(`${key}: ${lost.length} rendered line(s) missing from Confluence, ${extra.length} unexpected`);
    for (const l of lost.slice(0, 20)) console.log(`  - ${l}`);
    for (const l of extra.slice(0, 20)) console.log(`  + ${l}`);
    process.exitCode = 1;
  }
} else {
  console.error('usage: npm run confluence:sync -- status | mark <key>... | mark --all | verify <key> <fetched.md>');
  process.exitCode = 1;
}
