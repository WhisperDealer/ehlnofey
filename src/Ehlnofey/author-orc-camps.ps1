# Hostile Orc camps - Cracked Tusk Keep, Bilegulch Mine, Rift Watchtower (user, 2026-09-24).
#
# The camps draw from four lists. Only the parts that do not leak into other places are changed:
#   LCharOrcMelee 01E780    -> Highwayman x3 / Plunderer x4 / Marauder x2, authored in author-bucket-d.ps1.
#   LCharOrcMissile 01E781  -> untouched list of Orc Hunters; the HUNTERS are raised, below.
#   LCharBanditMeleeOrcM    -> shared with ~10 ordinary bandit camps, so left alone, and the three refs
#                              placed from it at Cracked Tusk (interior) and Bilegulch stay ordinary
#                              bandits (user decision: no cell edits).
#   LCharBanditBossOrcM     -> the chiefs, already pinned at 28.
#
# Three actor-record retargets (Template = which list the spawn draws from) and one level:
#   DA06LvlOrcMelee 08CDA2   Largashbur's defenders in "The Cursed Tribe"   LCharOrcMelee -> LCharBanditMeleeOrcM
#   WE24Orc 062128           the Old Orc of "A Good Death"                  LCharOrcMelee -> LCharBanditMeleeOrcM
#       Both keep their own name and race (no Traits flag), so they stay on the ordinary Orc-bandit mix.
#   LvlBanditMissileOrcM 0EEFE4   placed only outside Bilegulch Mine        LCharBanditMeleeOrcM -> LCharOrcMissile
#       Vanilla points this "missile" record at a melee list; it now spawns an Orc Hunter archer.
#   EncOrcHunterTemplate 0D9447   level 1 -> 19. All six Orc Hunter ranks inherit Stats from it, so every
#       hunter was level 1 (-20 HP) in vanilla and Requiem. Only the five EncOrcHunter0NM leaves use it,
#       and they are reachable only through LCharOrcMissile, which only the hostile camps place.
#
# Overriding these records collapses their names to English (non-localized plugin; see CLAUDE.md).
# Guardrail 3: copy the vanilla record verbatim and change only the one line. Run AFTER author-bucket-d.ps1.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$src  = Join-Path $root 'reference\Base\01Skyrim\Npcs'
$dst  = Join-Path $root 'src\Ehlnofey\EhlnofeyESP\Npcs'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$edits = @(
    @{ Id = '08CDA2'; From = 'Template: 01E780:Skyrim.esm'; To = 'Template: 01B0E9:Skyrim.esm' }   # DA06LvlOrcMelee
    @{ Id = '062128'; From = 'Template: 01E780:Skyrim.esm'; To = 'Template: 01B0E9:Skyrim.esm' }   # WE24Orc
    @{ Id = '0EEFE4'; From = 'Template: 01B0E9:Skyrim.esm'; To = 'Template: 01E781:Skyrim.esm' }   # LvlBanditMissileOrcM
    @{ Id = '0D9447'; From = '    Level: 1';                To = '    Level: 19' }                  # EncOrcHunterTemplate
)
foreach ($e in $edits) {
    $hit = @(Get-ChildItem -LiteralPath $src -Filter "* - $($e.Id)_Skyrim.esm.yaml")
    if ($hit.Count -ne 1) { throw "expected one vanilla NPC_ $($e.Id), found $($hit.Count)" }
    $lines = @(Get-Content -LiteralPath $hit[0].FullName -Encoding UTF8)
    $n = @($lines | Where-Object { $_ -eq $e.From }).Count
    if ($n -ne 1) { throw "$($hit[0].Name): expected exactly one '$($e.From)', found $n" }
    $out = @($lines | ForEach-Object { if ($_ -eq $e.From) { $e.To } else { $_ } })
    [System.IO.File]::WriteAllLines((Join-Path $dst $hit[0].Name), $out, $utf8NoBom)
    "{0,-50} {1} -> {2}" -f $hit[0].Name, $e.From.Trim(), $e.To.Trim()
}
"orc camps: $($edits.Count) NPC_ records"
