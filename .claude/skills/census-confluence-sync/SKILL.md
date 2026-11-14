---
name: census-confluence-sync
description: Push changed census pages to their Confluence mirrors and verify them. Use after editing census/ JSON, when the user asks to "update Confluence", "push the mirrors" or "sync Confluence", or before ending a session that changed the census. Finds the pages that changed, pushes each with the Atlassian MCP, checks it came back intact, and records it as synced.
---

# Census → Confluence sync

`census/` is the source of truth; each migrated page has a Confluence mirror (page ids in
`site/scripts/confluence-pages.json`). `site/scripts/confluence-sync.ts` knows what was last pushed
(a hash per page in `site/scripts/confluence-synced.json`, committed), so never guess which pages
changed: ask it.

## Steps

1. **Validate first.** `npm run schema` (in `site/`). Never push a census that fails it.
2. **List the pages to push.** `npm run confluence:sync -- status`. It renders every page to
   `site/.confluence/<key>.md` and prints `key → page id → file` for each page whose render differs
   from what was last pushed. A changed group page or a renamed family can change *other* pages'
   renders (titles, links); that is expected, push them too. Nothing listed means nothing to do.
   - A family with no id in `confluence-pages.json` is not mirrored (the World families). A new
     family that should be mirrored needs a page created under its group page first
     (`createConfluencePage`, then add the id to the JSON, keys sorted).
3. **Push each page.** `updateConfluencePage` with `cloudId: whisperdealer.atlassian.net`, the page
   id, `contentFormat: "markdown"`, the page's current title, and as `body` the **exact contents of
   the rendered file**: Read the file and pass it unchanged. Never retype, summarise, or "fix" it.
   Put a short `versionMessage` saying what changed (no Jira ticket numbers).
   - Do it yourself, one page at a time; subagents copying bodies is how a typo ("the Silvia")
     reached Confluence before. For many pages, a subagent may push a batch, but it must follow
     this skill, including step 4, and report each page's verify line.
   - A timeout is not a failure of the content: retry once, then verify (the push may have landed).
4. **Verify each page.** `getConfluencePage` (`contentFormat: "markdown"`). If the harness saved
   the result to a file, pass that file; otherwise write the returned `body` to a scratchpad file.
   Then `npm run confluence:sync -- verify <key> <file>` (accepts the body, the page JSON, or the
   saved tool result). It compares line by line, ignoring Markdown escaping and table padding.
   A mismatch means re-push from the rendered file, then verify again.
5. **Mark it synced.** `npm run confluence:sync -- mark <key> [<key>...]` for the pages that
   verified. Never `mark` a page you did not push and verify (`mark --all` only re-baselines when
   every mirror is known to match, e.g. after a full verified push).
6. **Commit** `site/scripts/confluence-synced.json` with the census change it belongs to.

## Notes

- The Atlassian MCP's first call in a session prints a deprecation notice about the V1 endpoint;
  tell the user once, as the server asks.
- Confluence is never edited by hand. If a mirror page was edited in Confluence, the census wins:
  re-push the render.
- Pages under the census are public on the site; the Confluence pages are internal. Don't copy
  Confluence links or ids into `census/` or `site/src/`.
