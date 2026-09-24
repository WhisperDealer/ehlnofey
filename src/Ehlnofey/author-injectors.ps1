# Runtime leveled-list injectors - neutralise them, and re-add by place what we want to keep.
#
# Some quests call LeveledActor.AddForm / LeveledItem.AddForm on VANILLA lists from a start-up stage
# fragment, at a player-level gate. Nothing in any plugin overrides those lists, so no load-order scan
# can see it, and the result lives in the save for good. Each one re-levels a list we flattened.
# Every gate below was read from the disassembled .pex (the packs ship no .psc); the audit that found
# them is in CLAUDE.md ("runtime AddForm" gotcha).
#
#   DLC2Init 016E02 (Dragonborn): Nordic weapons at gate 23 into the six LItemBandit* and six
#     LItemBanditBoss* weapon lists, Nordic armor at 25 into the five boss armor lists, the Nordic bow at
#     25..28, Hulking Draugr at 26 into LCharDraugrMelee1HMale. The boss armor lists lacked the all-levels
#     flag, so from player level 25 Nordic was the ONLY eligible entry: chiefs in iron at level 1, full
#     Nordic at 40. Observed in game 2026-09-24.
#   The 15 CC Bandit Armor packs (ccbgssse050..064-ba_*): the pack's SubCharBandit0NBoss into
#     LCharBanditBoss at gate 2..48 plus its armor into ~15 loot lists; VeryHard's bump rule then pushed
#     chiefs to a level-6 silver rung. Observed in game 2026-09-23.
#   ccvsvsse003-necroarts: its necromancer bosses at gates 1/6/12/19/27/36/46 into the three voice-boss
#     lists - an enemy-level ladder.
#   ccbgssse001-fish: honed draugr mace/warhammer at 12..24 into LItemDraugr02Weapon1H/2H, conjurer
#     robes at 1..40 into LItemRobesConjuration.
#   ccbgssse014-spellpack01: enchanted master robes at 1..40 into four robe lists.
#   ccbgssse002-exoticarrows: fire (10) and bone (30) arrows into bandit arrows, ice/bone (14/30) into
#     vampire arrows, and its own gated vendor sublist (6x, gates 1..20) into three arrow loot lists.
#   ccasvsse001-almsivi: Ordinator armor and ebony mace/scimitar at gate 36 into 13 Solstheim lists.
#   cccbhsse001-gaunt: injects at level 1, but what it injects are its own sublists gated 1..48 - so
#     the quest is left alone and the two sublists are flattened instead.
#
# The fix: override each injector quest and DELETE the properties that point at an affected leveled
# list. The fragment then calls AddForm on None - one Papyrus log error per call, and nothing is added.
# Every other property, alias, stage and script is kept verbatim, so the quest still does its other work
# (and its harmless level-1 injections - spell tomes, books, food - still happen). Injections are
# RunOnce and live in the save: this fixes new games only.
#
# Then, by place (user decision 2026-09-24: keep the CC content): every item a stripped call used to add
# goes into the same list as ONE entry at level 1 - flatten the gate, keep the pool. Nordic gear goes
# into the bandit-chief lists only; the necromancer voice lists get the CC necromancer of each tier the
# list already holds, so the pin does not move.
#
# Reads reference/Base/ and reference/mods/CreationClubYaml/. Run AFTER author-bucket-d.ps1 (and after
# extract-requiem.ps1, which regenerates the leveled lists this edits).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$cc   = Join-Path $root 'reference\mods\CreationClubYaml'
$base = Join-Path $root 'reference\Base'
$esp  = Join-Path $root 'src\Ehlnofey\EhlnofeyESP'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$loadOrder = @('01Skyrim', '02Update', '03Dawnguard', '04HearthFires', '05Dragonborn')

# ---------------------------------------------------------------- masters
# Every CC plugin this file names, in Skyrim.ccc load order.
$ccMasters = @(
    'ccasvsse001-almsivi.esm', 'ccbgssse001-fish.esm', 'ccbgssse002-exoticarrows.esl',
    'ccbgssse014-spellpack01.esl',
    'ccbgssse050-ba_daedric.esl', 'ccbgssse052-ba_iron.esl', 'ccbgssse054-ba_orcish.esl',
    'ccbgssse058-ba_steel.esl', 'ccbgssse059-ba_dragonplate.esl', 'ccbgssse061-ba_dwarven.esl',
    'ccbgssse064-ba_elven.esl', 'ccbgssse063-ba_ebony.esl', 'ccbgssse062-ba_dwarvenmail.esl',
    'ccbgssse060-ba_dragonscale.esl', 'ccbgssse056-ba_silver.esl', 'ccbgssse055-ba_orcishscaled.esl',
    'ccbgssse053-ba_leather.esl', 'ccbgssse051-ba_daedricmail.esl', 'ccbgssse057-ba_stalhrim.esl',
    'ccvsvsse003-necroarts.esl', 'cccbhsse001-gaunt.esl'
)

# ---------------------------------------------------------------- injector quests
# Src = decompile path under reference/. Strip = property names to delete; $null = every property whose
# name is a leveled list (right for quests that inject nothing harmless).
$quests = @(
    @{ Src = 'Base\05Dragonborn\Quests\DLC2Init - 016E02_Dragonborn.esm.yaml'; Strip = $null }
    @{ Src = 'mods\CreationClubYaml\ccasvsse001-almsivi\Quests\ccASVSSE001_QuestA - 000CA0_ccasvsse001-almsivi.esm.yaml'; Strip = $null }
    @{ Src = 'mods\CreationClubYaml\ccbgssse001-fish\Quests\ccBGSSSE001_DLCDetectionQuest - 0008BF_ccbgssse001-fish.esm.yaml'
       Strip = @('LItemDraugr02Weapon1H', 'LItemDraugr02Weapon2H', 'LItemRobesConjuration') }
    @{ Src = 'mods\CreationClubYaml\ccbgssse002-exoticarrows\Quests\ccBGSSSE002_StartUpQuest - 00081C_ccbgssse002-exoticarrows.esl.yaml'
       Strip = @('LItemBanditWeaponArrows', 'LItemVampireWeaponArrows', 'LItemArrowsAll', 'DLC2LItemArrowsAll', 'LItemMiscVendorArrows75') }
    @{ Src = 'mods\CreationClubYaml\ccbgssse014-spellpack01\Quests\ccBGSSSE014_SpellPack_StartupQuest - 00083C_ccbgssse014-spellpack01.esl.yaml'
       Strip = @('LItemRobesCollegeConjuration', 'LItemRobesCollegeDestruction', 'LItemRobesConjuration', 'LItemRobesDestruction') }
    @{ Src = 'mods\CreationClubYaml\ccvsvsse003-necroarts\Quests\ccVSVSSE003_MainQuest - 0008B7_ccvsvsse003-necroarts.esl.yaml'
       Strip = @('LCharWarlockBossNecroFemaleCondescending', 'LCharWarlockBossNecroMaleCondescending', 'LCharWarlockNecroBossMaleElfHaughty') }
)
$packQuests = [ordered]@{
    'ccbgssse050-ba_daedric'      = 'ccBGSSSE050_MiscQuest - 00081D'
    'ccbgssse052-ba_iron'         = 'ccBGSSSE052_MiscQuest - 00082F'
    'ccbgssse054-ba_orcish'       = 'ccBGSSSE054_MiscQuest - 000823'
    'ccbgssse058-ba_steel'        = 'ccBGSSSE058_MiscQuest - 000819'
    'ccbgssse059-ba_dragonplate'  = 'ccBGSSSE059_MiscQuest - 00082B'
    'ccbgssse061-ba_dwarven'      = 'ccBGSSSE061_MiscQuest - 00082B'
    'ccbgssse064-ba_elven'        = 'ccBGSSSE064_Quest - 000819'
    'ccbgssse063-ba_ebony'        = 'ccBGSSSE063_MiscQuest - 000855'
    'ccbgssse062-ba_dwarvenmail'  = 'ccBGSSSE062_Quest - 00081A'
    'ccbgssse060-ba_dragonscale'  = 'ccBGSSSE060_Quest - 00081B'
    'ccbgssse056-ba_silver'       = 'ccBGSSSE056_MiscQuest - 000823'
    'ccbgssse055-ba_orcishscaled' = 'ccBGSSSE055_MiscQuest - 000833'
    'ccbgssse053-ba_leather'      = 'ccBGSSSE053_MiscQuest - 000828'
    'ccbgssse051-ba_daedricmail'  = 'ccBGSSSE051_Quest - 000819'
    'ccbgssse057-ba_stalhrim'     = 'ccBGSSSE057_Quest - 00081A'
}
foreach ($p in $packQuests.Keys) {
    $quests += @{ Src = "mods\CreationClubYaml\$p\Quests\$($packQuests[$p])_$p.esl.yaml"; Strip = $null }
}

$listName = '^(DLC2)?L(Char|[Ii]tem)'
$questDir = Join-Path $esp 'Quests'
if (-not (Test-Path -LiteralPath $questDir)) { [void](New-Item -ItemType Directory -Path $questDir) }

$total = 0
foreach ($q in $quests) {
    $src = Join-Path (Join-Path $root 'reference') $q.Src
    if (-not (Test-Path -LiteralPath $src)) { throw "missing quest decompile: $src" }
    $file  = Split-Path -Leaf $src
    $lines = @(Get-Content -LiteralPath $src -Encoding UTF8)

    # Properties are '<pad>- MutagenObjectType: Script*Property' blocks with fields at <pad>+2. The pad
    # is 4 for a quest script and 6 for an alias script (ccbgssse001-fish), so it is read, not assumed.
    $out = New-Object System.Collections.ArrayList
    $block = $null; $cut = @(); $field = ''
    foreach ($l in $lines) {
        if ($block -ne $null) {
            if ($l.StartsWith($field)) { [void]$block.Add($l); continue }
            $name = ($block | Where-Object { $_.StartsWith("${field}Name: ") } | Select-Object -First 1).Substring($field.Length + 6)
            $drop = if ($q.Strip -eq $null) { $name -match $listName } else { $q.Strip -contains $name }
            if ($drop) { $cut += $name } else { foreach ($b in $block) { [void]$out.Add($b) } }
            $block = $null
        }
        if ($l -match '^( +)- MutagenObjectType: Script\w+Property$') {
            $field = $Matches[1] + '  '
            $block = New-Object System.Collections.ArrayList; [void]$block.Add($l); continue
        }
        [void]$out.Add($l)
    }
    if ($block -ne $null) { throw "$file ended inside a property block" }
    if ($cut.Count -eq 0) { throw "$file had no leveled-list properties - wrong quest?" }
    if ($q.Strip -ne $null) {
        $missing = @($q.Strip | Where-Object { $cut -notcontains $_ })
        if ($missing.Count) { throw "$file has no property named $($missing -join ', ')" }
    }

    [System.IO.File]::WriteAllLines((Join-Path $questDir $file), $out, $utf8NoBom)
    "{0,-72} {1,2} list properties removed" -f $file, $cut.Count
    $total += $cut.Count
}

# ---------------------------------------------------------------- re-add by place, at level 1
# One entry per item, whatever gate(s) the script used. Count is the script's count.
$nordicChief = @(   # DLC2Init's pairs, into the bandit-chief lists only
    @{ List = '03DF1E:Skyrim.esm'; Items = @(,@('01CDAD:Dragonborn.esm', 1)) }   # LItemBanditBossBattleaxe   <- DLC2NordicBattleaxe
    @{ List = '03DF23:Skyrim.esm'; Items = @(,@('01CDAF:Dragonborn.esm', 1)) }   # LItemBanditBossGreatsword  <- DLC2NordicGreatsword
    @{ List = '03DF21:Skyrim.esm'; Items = @(,@('01CDB3:Dragonborn.esm', 1)) }   # LItemBanditBossWarhammer   <- DLC2NordicWarhammer
    @{ List = '03DF1F:Skyrim.esm'; Items = @(,@('01CDB0:Dragonborn.esm', 1)) }   # LItemBanditBossMace        <- DLC2NordicMace
    @{ List = '03DF1D:Skyrim.esm'; Items = @(,@('01CDB1:Dragonborn.esm', 1)) }   # LItemBanditBossSword       <- DLC2NordicSword
    @{ List = '03DF20:Skyrim.esm'; Items = @(,@('01CDB2:Dragonborn.esm', 1)) }   # LItemBanditBossWarAxe      <- DLC2NordicWarAxe
    @{ List = '03DF1A:Skyrim.esm'; Items = @(,@('01CD96:Dragonborn.esm', 1)) }   # LItemBanditBossBoots       <- DLC2ArmorNordicHeavyBoots
    @{ List = '03DF19:Skyrim.esm'; Items = @(,@('01CD97:Dragonborn.esm', 1)) }   # LItemBanditBossCuirass     <- DLC2ArmorNordicHeavyCuirass
    @{ List = '03DF18:Skyrim.esm'; Items = @(,@('01CD98:Dragonborn.esm', 1)) }   # LItemBanditBossGauntlets50 <- DLC2ArmorNordicHeavyGauntlets
    @{ List = '03DF1B:Skyrim.esm'; Items = @(,@('01CD99:Dragonborn.esm', 1)) }   # LItemBanditBossHelmet50    <- DLC2ArmorNordicHeavyHelmet
    @{ List = '03DF22:Skyrim.esm'; Items = @(,@('026236:Dragonborn.esm', 1)) }   # LItemBanditBossShield      <- DLC2ArmorNordicShield
)
foreach ($r in $nordicChief) { $r.AllLevels = $true }   # every piece a uniform roll over the whole pool

$fish = 'ccbgssse001-fish.esm'; $arrows = 'ccbgssse002-exoticarrows.esl'; $spell = 'ccbgssse014-spellpack01.esl'
$alm = 'ccasvsse001-almsivi.esm'; $necro = 'ccvsvsse003-necroarts.esl'
$ccReadd = @(
    # fish: conjurer robes 01..05 (gates 1..40) + spellpack master robes Ench01/03/04/05 (1..40)
    @{ List = '10F9B0:Skyrim.esm'; Items = @(@("04D04D:$fish", 1), @("04D04C:$fish", 1), @("04D049:$fish", 1), @("000E53:$fish", 1), @("04D04A:$fish", 1),
                                             @("000835:$spell", 1), @("000837:$spell", 1), @("000838:$spell", 1), @("000839:$spell", 1)) }   # LItemRobesConjuration
    @{ List = '0242FC:Skyrim.esm'; Items = @(@("000E46:$fish", 1), @("08A1EE:$fish", 1)) }   # LItemDraugr02Weapon1H: draugr mace (1), honed (12..24)
    @{ List = '024300:Skyrim.esm'; Items = @(@("000E47:$fish", 1), @("08A1EF:$fish", 1)) }   # LItemDraugr02Weapon2H: draugr warhammer (1), honed (12..24)
    # spellpack: master robes Ench01..05 (gates 1/8/16/24/32 college, 1/10/20/30/40 general)
    @{ List = '016E1D:Skyrim.esm'; Items = @(@("000827:$spell", 1), @("000829:$spell", 1), @("00082A:$spell", 1), @("00082B:$spell", 1), @("00082C:$spell", 1)) }   # LItemRobesCollegeDestruction
    @{ List = '10F9B1:Skyrim.esm'; Items = @(@("000827:$spell", 1), @("000829:$spell", 1), @("00082A:$spell", 1), @("00082B:$spell", 1), @("00082C:$spell", 1)) }   # LItemRobesDestruction
    @{ List = '016E1F:Skyrim.esm'; Items = @(@("000835:$spell", 1), @("000836:$spell", 1), @("000837:$spell", 1), @("000838:$spell", 1), @("000839:$spell", 1)) }   # LItemRobesCollegeConjuration
    # exoticarrows (its Ice and Lightning properties both point at 00082F - a CC bug, copied as-is)
    @{ List = '09AF09:Skyrim.esm'; Items = @(,@("000810:$arrows", 15)) }                        # LItemMiscVendorArrows75 <- vendor sublist (6x, gates 1..20)
    @{ List = '068839:Skyrim.esm'; Items = @(,@("000810:$arrows", 15)) }                        # LItemArrowsAll
    @{ List = '02BC16:Dragonborn.esm'; Items = @(,@("000810:$arrows", 15)) }                    # DLC2LItemArrowsAll
    @{ List = '039D2F:Skyrim.esm'; Items = @(@("000830:$arrows", 12), @("00082E:$arrows", 12)) }   # LItemBanditWeaponArrows: fire (10), bone (30)
    @{ List = '02DF9F:Skyrim.esm'; Items = @(@("00082F:$arrows", 12), @("00082E:$arrows", 12)) }   # LItemVampireWeaponArrows: ice (14), bone (30)
    # almsivi: Ordinator armor and ebony mace/scimitar, all at gate 36
    @{ List = '0374EE:Dragonborn.esm'; Items = @(,@("000817:$alm", 1)) }   # DLC2LItemArmorBootsHeavyTown
    @{ List = '02BC19:Dragonborn.esm'; Items = @(,@("000817:$alm", 1)) }   # DLC2LItemArmorBootsHeavy
    @{ List = '0374EF:Dragonborn.esm'; Items = @(,@("000818:$alm", 1)) }   # DLC2LItemArmorCuirassHeavyTown
    @{ List = '02BC1B:Dragonborn.esm'; Items = @(,@("000818:$alm", 1)) }   # DLC2LItemArmorCuirassHeavy
    @{ List = '0374F1:Dragonborn.esm'; Items = @(,@("000819:$alm", 1)) }   # DLC2LItemArmorGauntletsHeavyTown
    @{ List = '02BC1D:Dragonborn.esm'; Items = @(,@("000819:$alm", 1)) }   # DLC2LItemArmorGauntletsHeavy
    @{ List = '0374F3:Dragonborn.esm'; Items = @(,@("00081A:$alm", 1)) }   # DLC2LItemArmorHelmetHeavyTown
    @{ List = '02BC1F:Dragonborn.esm'; Items = @(,@("00081A:$alm", 1)) }   # DLC2LItemArmorHelmetHeavy
    @{ List = '0374E2:Dragonborn.esm'; Items = @(,@("000E37:$alm", 1)) }   # DLC2LItemWeaponMaceTown
    @{ List = '02BC11:Dragonborn.esm'; Items = @(,@("000E37:$alm", 1)) }   # DLC2LItemWeaponMace
    @{ List = '0374E7:Dragonborn.esm'; Items = @(,@("000E38:$alm", 1)) }   # DLC2LItemWeaponSwordTown
    @{ List = '02BC12:Dragonborn.esm'; Items = @(,@("000E38:$alm", 1)) }   # DLC2LItemWeaponSword
    @{ List = '0374EA:Dragonborn.esm'; Items = @(@("000E37:$alm", 1), @("000E38:$alm", 1)) }   # DLC2LItemWeaponAny1HTown (new override)
    # necroarts: the CC boss of each tier the pinned voice list already holds (vanilla 05/06, 04/05/06)
    @{ List = '0E106D:Skyrim.esm'; Items = @(@("00092A:$necro", 1), @("000924:$necro", 1)) }                       # MaleCondescending: 05/06 BretonM
    @{ List = '0E2217:Skyrim.esm'; Items = @(@("000929:$necro", 1), @("000923:$necro", 1)) }                       # FemaleCondescending: 05/06 BretonF
    @{ List = '081EF3:Skyrim.esm'; Items = @(@("000930:$necro", 1), @("00092C:$necro", 1), @("000926:$necro", 1)) } # MaleElfHaughty: 04/05/06 HighElfM
)

function Find-ListFile([string]$formKey) {
    $id, $master = $formKey -split ':'
    foreach ($dir in 'LeveledItems', 'LeveledNpcs') {
        $hit = @(Get-ChildItem -LiteralPath (Join-Path $esp $dir) -Filter "* - ${id}_$master.yaml" -ErrorAction SilentlyContinue)
        if ($hit.Count -eq 1) { return $hit[0].FullName }
    }
    # Not overridden yet: start from the WINNING vanilla record (last in load order).
    $src = $null
    foreach ($m in $loadOrder) {
        foreach ($dir in 'LeveledItems', 'LeveledNpcs') {
            $hit = @(Get-ChildItem -LiteralPath (Join-Path $base "$m\$dir") -Filter "* - ${id}_$master.yaml" -ErrorAction SilentlyContinue)
            if ($hit.Count -eq 1) { $src = $hit[0]; $srcDir = $dir }
        }
    }
    if ($src -eq $null) { throw "no leveled list $formKey in the plugin or reference/Base" }
    $dst = Join-Path (Join-Path $esp $srcDir) $src.Name
    Copy-Item -LiteralPath $src.FullName -Destination $dst
    return $dst
}

$allLevels = '- CalculateFromAllLevelsLessThanOrEqualPlayer'
$added = 0
foreach ($r in ($nordicChief + $ccReadd)) {
    $path  = Find-ListFile $r.List
    $lines = @(Get-Content -LiteralPath $path -Encoding UTF8)
    $new   = @($r.Items | Where-Object { $lines -notcontains "    Reference: $($_[0])" })   # idempotent
    $flag  = $r.ContainsKey('AllLevels') -and -not ($lines -contains $allLevels)
    if ($new.Count -eq 0 -and -not $flag) { continue }
    if ($lines -notcontains 'Entries:') { throw "no Entries: block in $path" }
    if ($flag -and $lines -notcontains 'Flags:') { throw "no Flags: block in $path" }

    $entries = New-Object System.Collections.ArrayList
    foreach ($i in $new) { foreach ($e in @('- Data:', '    Level: 1', "    Reference: $($i[0])", "    Count: $($i[1])")) { [void]$entries.Add($e) } }
    $out = New-Object System.Collections.ArrayList
    $inEntries = $false
    foreach ($l in $lines) {
        if ($inEntries -and $l -match '^\S' -and $l -notmatch '^- ') { [void]$out.AddRange($entries); $inEntries = $false }
        [void]$out.Add($l)
        if ($flag -and $l -eq 'Flags:') { [void]$out.Add($allLevels) }
        if ($l -eq 'Entries:') { $inEntries = $true }
    }
    if ($inEntries) { [void]$out.AddRange($entries) }
    [System.IO.File]::WriteAllLines($path, $out, $utf8NoBom)
    "{0,-72} +{1}{2}" -f (Split-Path -Leaf $path), $new.Count, $(if ($flag) { ', all-levels flag set' } else { '' })
    $added += $new.Count
}

# ---------------------------------------------------------------- steel floor for bandit chiefs
# User decision 2026-09-24, after play: a chief is the camp's T5 fight, so no iron - steel is the floor.
# Removes the plain iron armor and the enchanted iron weapons from the chief lists. The same armor lists
# also feed BanditArmorHeavyBossNoShieldOutfit, three named outfits (dunCraglsaneButcher,
# dunMistwatchFjolaArmor, MS10Haldyn) and DLC2LItemBanditArmorAll; they lose the iron too, on purpose.
$noIron = [ordered]@{
    '03DF19' = @('012E49:Skyrim.esm', '013948:Skyrim.esm')   # LItemBanditBossCuirass     - ArmorIronCuirass, ArmorIronBandedCuirass
    '03DF1A' = @('012E4B:Skyrim.esm')                        # LItemBanditBossBoots       - ArmorIronBoots
    '03DF18' = @('012E46:Skyrim.esm')                        # LItemBanditBossGauntlets50 - ArmorIronGauntlets
    '03DF1B' = @('012E4D:Skyrim.esm')                        # LItemBanditBossHelmet50    - ArmorIronHelmet
    '03DF1F' = @('0DDD98:Skyrim.esm')                        # LItemBanditBossMace        - LItemEnchIronMaceBoss
    '03DF1D' = @('0DDD90:Skyrim.esm')                        # LItemBanditBossSword       - LItemEnchIronSwordBoss
    '03DF20' = @('0DDDA0:Skyrim.esm')                        # LItemBanditBossWarAxe      - LItemEnchIronWarAxeBoss
}
$removed = 0
foreach ($id in $noIron.Keys) {
    $path  = Find-ListFile "${id}:Skyrim.esm"
    $lines = @(Get-Content -LiteralPath $path -Encoding UTF8)
    # Entries are '- Data:' blocks; a block ends at the next '- ' or top-level line.
    $out = New-Object System.Collections.ArrayList
    $block = $null; $cut = 0
    foreach ($l in @($lines) + @('')) {
        if ($block -ne $null) {
            if ($l -match '^  ') { [void]$block.Add($l); continue }
            $ref = ($block | Where-Object { $_ -match '^    Reference: ' } | Select-Object -First 1) -replace '^    Reference: ', ''
            if ($noIron[$id] -contains $ref) { $cut++ } else { [void]$out.AddRange($block) }
            $block = $null
        }
        if ($l -eq '- Data:') { $block = New-Object System.Collections.ArrayList; [void]$block.Add($l); continue }
        [void]$out.Add($l)
    }
    $out.RemoveAt($out.Count - 1)   # the '' sentinel
    if ($cut -eq 0) { continue }    # idempotent: already removed
    [System.IO.File]::WriteAllLines($path, $out, $utf8NoBom)
    "{0,-72} -{1} iron" -f (Split-Path -Leaf $path), $cut
    $removed += $cut
}

# ---------------------------------------------------------------- flatten gated CC sublists
# Injected at level 1, but gated inside. Flatten the gate, keep the pool (duplicates are the weights).
$flatten = @(
    'cccbhsse001-gaunt\LeveledItems\ccCBHSSE001_LItemArmorGauntletsHeavy - 000831_cccbhsse001-gaunt.esl.yaml'         # 1..48
    'cccbhsse001-gaunt\LeveledItems\ccCBHSSE001_LItemArmorGauntletsLight - 000832_cccbhsse001-gaunt.esl.yaml'         # 1..46
    'ccbgssse002-exoticarrows\LeveledItems\ccBGSSSE002_LItemArrowMagicAny_Vendor - 000810_ccbgssse002-exoticarrows.esl.yaml'   # 1/12/20
)
foreach ($f in $flatten) {
    $src = Join-Path $cc $f
    $out = @(Get-Content -LiteralPath $src -Encoding UTF8 | ForEach-Object { if ($_ -match '^    Level: (\d+)$' -and $Matches[1] -ne '9999') { '    Level: 1' } else { $_ } })
    [System.IO.File]::WriteAllLines((Join-Path (Join-Path $esp 'LeveledItems') (Split-Path -Leaf $src)), $out, $utf8NoBom)
    "{0,-72} flattened" -f (Split-Path -Leaf $src)
}

# ---------------------------------------------------------------- masters
# The whole master list, rewritten: the five base masters, then the CC plugins in load order.
# HearthFires.esm joined 2026-09-24 - not for any Hearthfire content, but because the fish pack's
# DLC-detection quest (overridden above) holds properties pointing at Hearthfire records.
$masters = @('Skyrim.esm', 'Update.esm', 'Dawnguard.esm', 'HearthFires.esm', 'Dragonborn.esm') + $ccMasters
$rd = Join-Path $esp 'RecordData.yaml'
$hdr = @(Get-Content -LiteralPath $rd -Encoding UTF8)
$new = New-Object System.Collections.ArrayList
$inMasters = $false
foreach ($l in $hdr) {
    if ($l -eq '  MasterReferences:') {
        $inMasters = $true; [void]$new.Add($l)
        foreach ($p in $masters) { [void]$new.Add("  - Master: $p"); [void]$new.Add('    FileSize: 0') }
        continue
    }
    if ($inMasters -and ($l -match '^  - Master: ' -or $l -match '^    FileSize: ')) { continue }
    $inMasters = $false
    [void]$new.Add($l)
}
[System.IO.File]::WriteAllLines($rd, $new, $utf8NoBom)

"injectors: $($quests.Count) quests overridden ($total list properties removed), $added entries re-added at level 1, $removed iron entries removed from chief lists, $($flatten.Count) CC sublists flattened, $($ccMasters.Count) CC masters"
