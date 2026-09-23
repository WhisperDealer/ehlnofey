# Creation Club "Bandit Armor" compatibility - neutralise the runtime leveled-list injections.
#
# Fifteen CC armor packs (ccbgssse050..064-ba_*) each ship a quest whose start-up stage fragment calls
# LeveledActor.AddForm / LeveledItem.AddForm on VANILLA lists at runtime:
#   - LCharBanditBoss 03DF16 (DLC2LCharBanditBoss for stalhrim) gets the pack's own SubCharBandit0NBoss
#     at gate 2..48. That re-creates a zone-scaled chief ladder, and VeryHard's bump rule ("if the pick
#     equals the Hard pick, take the next-higher entry") pushes past the lookup level: in a min-6 zone
#     Hard and VeryHard both pick steel (gate 6), so the chief bumps to silver (gate 10) - a level-6
#     chief in silver. Observed in game 2026-09-23 at Robber's Gorge and Swindler's Den.
#   - ~15 LItemArmor* / LItemBanditBoss* loot lists get the pack's armor at player-level gates.
# Nothing in any plugin overrides those lists, so no load-order scan can see this; the levels were read
# from the disassembled QF .pex in each pack's BSA.
#
# The fix: override each injector quest and DELETE the properties that point at a vanilla leveled list.
# The fragment then calls AddForm on None - one Papyrus log error per call, and nothing is added. Every
# other property, alias, stage and script is kept verbatim, so each pack's own note/quest still works.
# The injections are RunOnce and live in the save: this fixes new games only.
#
# Reads reference/mods/CreationClubYaml/ (serialized from the CC plugins). Run AFTER author-names.ps1.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$cc   = Join-Path $root 'reference\mods\CreationClubYaml'
$esp  = Join-Path $root 'src\Ehlnofey\EhlnofeyESP'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Pack plugin -> injector quest file. Ordered as the packs load (master order).
$packs = [ordered]@{
    'ccbgssse050-ba_daedric.esl'      = 'ccBGSSSE050_MiscQuest - 00081D'
    'ccbgssse052-ba_iron.esl'         = 'ccBGSSSE052_MiscQuest - 00082F'
    'ccbgssse054-ba_orcish.esl'       = 'ccBGSSSE054_MiscQuest - 000823'
    'ccbgssse058-ba_steel.esl'        = 'ccBGSSSE058_MiscQuest - 000819'
    'ccbgssse059-ba_dragonplate.esl'  = 'ccBGSSSE059_MiscQuest - 00082B'
    'ccbgssse061-ba_dwarven.esl'      = 'ccBGSSSE061_MiscQuest - 00082B'
    'ccbgssse064-ba_elven.esl'        = 'ccBGSSSE064_Quest - 000819'
    'ccbgssse063-ba_ebony.esl'        = 'ccBGSSSE063_MiscQuest - 000855'
    'ccbgssse062-ba_dwarvenmail.esl'  = 'ccBGSSSE062_Quest - 00081A'
    'ccbgssse060-ba_dragonscale.esl'  = 'ccBGSSSE060_Quest - 00081B'
    'ccbgssse056-ba_silver.esl'       = 'ccBGSSSE056_MiscQuest - 000823'
    'ccbgssse055-ba_orcishscaled.esl' = 'ccBGSSSE055_MiscQuest - 000833'
    'ccbgssse053-ba_leather.esl'      = 'ccBGSSSE053_MiscQuest - 000828'
    'ccbgssse051-ba_daedricmail.esl'  = 'ccBGSSSE051_Quest - 000819'
    'ccbgssse057-ba_stalhrim.esl'     = 'ccBGSSSE057_Quest - 00081A'
}
# A property is an injection target when its name is a vanilla leveled list.
$listName = '^(DLC2)?L(Char|[Ii]tem)'

$questDir = Join-Path $esp 'Quests'
if (-not (Test-Path -LiteralPath $questDir)) { [void](New-Item -ItemType Directory -Path $questDir) }

$total = 0
foreach ($plugin in $packs.Keys) {
    $file = "$($packs[$plugin])_$plugin.yaml"
    $src  = Join-Path $cc ("{0}\Quests\{1}" -f [IO.Path]::GetFileNameWithoutExtension($plugin), $file)
    if (-not (Test-Path -LiteralPath $src)) { throw "missing CC quest decompile: $src" }
    $lines = @(Get-Content -LiteralPath $src -Encoding UTF8)

    # Properties are '    - MutagenObjectType: ...' blocks (4-space dash) with 6-space fields.
    $out = New-Object System.Collections.ArrayList
    $block = $null; $cut = 0
    foreach ($l in $lines) {
        if ($block -ne $null) {
            if ($l -match '^      ') { [void]$block.Add($l); continue }
            $name = ($block | Where-Object { $_ -match '^      Name: ' } | Select-Object -First 1) -replace '^      Name: ', ''
            if ($name -match $listName) { $cut++ } else { foreach ($b in $block) { [void]$out.Add($b) } }
            $block = $null
        }
        if ($l -match '^    - MutagenObjectType: Script\w+Property$') {
            $block = New-Object System.Collections.ArrayList; [void]$block.Add($l); continue
        }
        [void]$out.Add($l)
    }
    if ($block -ne $null) { throw "$file ended inside a property block" }
    if ($cut -eq 0) { throw "$file had no leveled-list properties - wrong quest?" }

    [System.IO.File]::WriteAllLines((Join-Path $questDir $file), $out, $utf8NoBom)
    "{0,-34} {1,2} list properties removed" -f $plugin, $cut
    $total += $cut
}

# Masters: the four base masters, then the packs in load order. Idempotent.
$rd = Join-Path $esp 'RecordData.yaml'
$hdr = @(Get-Content -LiteralPath $rd -Encoding UTF8)
$new = New-Object System.Collections.ArrayList
$inMasters = $false
foreach ($l in $hdr) {
    if ($l -eq '  MasterReferences:') { $inMasters = $true; [void]$new.Add($l); continue }
    if ($inMasters) {
        if ($l -match '^  - Master: ' -or $l -match '^    FileSize: ') {
            if ($l -match '^  - Master: (.+)$' -and $Matches[1] -like 'cc*') { $skip = $true } elseif ($l -match '^  - Master: ') { $skip = $false }
            if (-not $skip) { [void]$new.Add($l) }
            continue
        }
        foreach ($p in $packs.Keys) { [void]$new.Add("  - Master: $p"); [void]$new.Add('    FileSize: 0') }
        $inMasters = $false
    }
    [void]$new.Add($l)
}
[System.IO.File]::WriteAllLines($rd, $new, $utf8NoBom)

"cc-compat: $($packs.Count) quests overridden, $total list properties removed, $($packs.Count) masters added"
