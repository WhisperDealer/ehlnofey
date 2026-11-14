// Loads the ledgers for the pages, with the census families their pointers resolve against.
import { getCollection } from 'astro:content';
import type { FamilyData, LedgerData } from '../schema.ts';
import { bands, href } from './census.ts';
import { checkLedger, resolveRow } from './ledger.ts';

export async function loadLedgers() {
  const census: FamilyData[] = (await getCollection('families')).map((f) => f.data);
  const ledgers: LedgerData[] = (await getCollection('ledgers')).map((l) => l.data).sort((a, b) => a.order - b.order);
  return { census, ledgers: ledgers.map((l) => ({ ledger: l, findings: checkLedger(l, census, bands) })) };
}

// A census row pointer as a link to its row on the family page.
export function rowLink(census: FamilyData[], pointer: string) {
  const hit = resolveRow(census, pointer);
  const [page, row] = pointer.split('#');
  return { name: hit?.row.name ?? pointer, page: hit?.family.title ?? page, url: href(`${page}/#rec-${row}`), row: hit?.row };
}
