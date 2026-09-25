# One-line NPC_ edits: retarget a record's Template (which list the spawn draws from) or fix one field.
#
# Each edit copies the WINNING vanilla record verbatim (last in load order, CLAUDE.md "last-wins") and
# replaces exactly one line (guardrail 3). It replaces any earlier override of that record in the plugin,
# including a bucket-E level graft from extract-requiem.ps1, so the edit's From line is matched against
# vanilla. Any master works: Npc is a full FormKey.
#
# Overriding a vanilla NPC_ collapses its name to English (non-localized plugin; see CLAUDE.md).
# Run AFTER author-injectors.ps1.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$base = Join-Path $root 'reference\Base'
$dst  = Join-Path $root 'src\Ehlnofey\EhlnofeyESP\Npcs'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$loadOrder = @('01Skyrim', '02Update', '03Dawnguard', '04HearthFires', '05Dragonborn')

$edits = @(
    # ---- Hostile Orc camps - Cracked Tusk Keep, Bilegulch Mine, Rift Watchtower (user, 2026-09-24).
    # The camps draw from four lists. Only the parts that do not leak into other places are changed:
    #   LCharOrcMelee 01E780    -> Highwayman x3 / Plunderer x4 / Marauder x2, authored in author-bucket-d.ps1.
    #   LCharOrcMissile 01E781  -> untouched list of Orc Hunters; the HUNTERS are raised, below.
    #   LCharBanditMeleeOrcM    -> shared with ~10 ordinary bandit camps, so left alone, and the three refs
    #                              placed from it at Cracked Tusk (interior) and Bilegulch stay ordinary
    #                              bandits (user decision: no cell edits).
    #   LCharBanditBossOrcM     -> the chiefs, already pinned at 28.
    # DA06LvlOrcMelee and WE24Orc keep their own name and race (no Traits flag), so they stay on the
    # ordinary Orc-bandit mix. LvlBanditMissileOrcM is placed only outside Bilegulch Mine; vanilla points
    # this "missile" record at a melee list, and it now spawns an Orc Hunter archer. All six Orc Hunter
    # ranks inherit Stats from EncOrcHunterTemplate, so every hunter was level 1 (-20 HP) in vanilla and
    # Requiem; only the five EncOrcHunter0NM leaves use it, reachable only through LCharOrcMissile.
    @{ Npc = '08CDA2:Skyrim.esm'; From = 'Template: 01E780:Skyrim.esm'; To = 'Template: 01B0E9:Skyrim.esm' }   # DA06LvlOrcMelee: Largashbur, "The Cursed Tribe"
    @{ Npc = '062128:Skyrim.esm'; From = 'Template: 01E780:Skyrim.esm'; To = 'Template: 01B0E9:Skyrim.esm' }   # WE24Orc: the Old Orc of "A Good Death"
    @{ Npc = '0EEFE4:Skyrim.esm'; From = 'Template: 01B0E9:Skyrim.esm'; To = 'Template: 01E781:Skyrim.esm' }   # LvlBanditMissileOrcM -> LCharOrcMissile
    @{ Npc = '0D9447:Skyrim.esm'; From = '    Level: 1';                To = '    Level: 19' }                  # EncOrcHunterTemplate

    # ---- Forsworn Ravagers (level 34) carry the Briarheart weapon mix (WD-43, user 2026-09-25): Forsworn,
    # elven, dwarven, rare glass. Lower rungs keep LItemForswornWeapon1H (Forsworn sword/axe only). Seven
    # EncForsworn05Melee1H leaves inherit Inventory from the template; the Berserker leaf does not and holds
    # its own copy. EncForsworn05TemplateBossMelee also templates on it but owns its inventory - no leak.
    @{ Npc = '044287:Skyrim.esm'; From = '    Item: 043BD5:Skyrim.esm'; To = '    Item: 044303:Skyrim.esm' }   # EncForsworn05TemplateMelee
    @{ Npc = '0F961A:Skyrim.esm'; From = '    Item: 043BD5:Skyrim.esm'; To = '    Item: 044303:Skyrim.esm' }   # EncForsworn05Melee1HBretonBerserk
)

foreach ($e in $edits) {
    $id, $master = $e.Npc -split ':'
    $src = $null
    foreach ($m in $loadOrder) {
        $hit = @(Get-ChildItem -LiteralPath (Join-Path $base "$m\Npcs") -Filter "* - ${id}_$master.yaml" -ErrorAction SilentlyContinue)
        if ($hit.Count -eq 1) { $src = $hit[0] }
    }
    if ($src -eq $null) { throw "no vanilla NPC_ $($e.Npc) in reference/Base" }
    $lines = @(Get-Content -LiteralPath $src.FullName -Encoding UTF8)
    $n = @($lines | Where-Object { $_ -eq $e.From }).Count
    if ($n -ne 1) { throw "$($src.Name): expected exactly one '$($e.From)', found $n" }
    $out = @($lines | ForEach-Object { if ($_ -eq $e.From) { $e.To } else { $_ } })
    [System.IO.File]::WriteAllLines((Join-Path $dst $src.Name), $out, $utf8NoBom)
    "{0,-50} {1} -> {2}" -f $src.Name, $e.From.Trim(), $e.To.Trim()
}
"retargets: $($edits.Count) NPC_ records"
