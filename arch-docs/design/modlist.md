# Ehlnofey as a modlist

**Status: DECIDED in outline (user, 2026-11-14); the list itself is not assembled yet.**

## The change

Ehlnofey was planned as one self-contained mod that delevels the whole game. Built that way it would
need a compatibility patch for nearly every mod a player might add. **Ehlnofey is now a modlist** (an
MO2 list) that other people can build on, and the deleveling patch is one part of it.

## What was decided (user, 2026-11-14)

| Question | Decision |
|---|---|
| Ehlnofey's own plugin | **Kept, as the list's patch.** `Ehlnofey.esp` (`src/Ehlnofey/EhlnofeyESP`) is still authored here, from vanilla, and generated from the ledgers (`ledgers.md`). |
| Third-party mods | **Allowed in the list.** The list may include other mods, and the patch may take them as masters where a record needs it. |
| Rule engines | **Still not used for our own changes.** Ehlnofey's changes stay plugin records: no SkyPatcher, no SPID, no Synthesis. Mods in the list may use whatever they use. |
| Copying records | Unchanged: nothing is copied from `ProofOfConceptESP` (it is derived from a third-party mod) and no third-party mod's records are copied into the patch without its author's permission. |

The three bones are unchanged: they are the rules of the patch. The method is unchanged too:
`flattening.md` still describes how the patch delevels.

## What changes in practice

- **"One plugin" is no longer a goal in itself.** The patch stays one ESL plugin, but the list may add
  mods beside it, and a mod in the list may need its own small patch.
- **Compatibility is curated, not patched.** A mod that re-levels lists (or injects into them at
  runtime) either goes in the list with a patch, or stays out.
- **The modlist is the test bed.** `modlist/` (gitignored, MO2) is where the patch is deployed and
  launched (`mod-deploy` skill); it becomes the list itself rather than a scratch install.

## Open questions

1. **Distribution.** A Wabbajack list, an MO2 profile with a mod manifest, or a Nexus collection?
2. **Which mods are in it**, and does the list stay "deleveling plus essentials" (the bones'
   non-goals: no combat, perk or survival overhaul *in the patch*), or does it grow into a full
   gameplay list?
3. **Built upon by whom.** If players add mods on top, which load-order slot does `Ehlnofey.esp` need
   to keep (last, so its flat lists win?), and how do we tell them?
4. **Where the list's manifest lives** in the repo (a `modlist/` manifest committed, the instance
   gitignored?).
