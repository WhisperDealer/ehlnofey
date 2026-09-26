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
# Row shape: @{ List = <list FormKey>; Items = @(@(<item FormKey>, <count>), ...); AllLevels = $true }
# List may be on any master. AllLevels (optional) also sets CalculateFromAllLevelsLessThanOrEqualPlayer,
# so every entry is a uniform roll over the whole pool. Grouped by faction; add a block per faction.
$readdByPlace = @(
    # ---- Bandits: DLC2Init's Nordic pairs, into the bandit-chief lists only (user decision 2026-09-24)
    @{ List = '03DF1E:Skyrim.esm'; Items = @(,@('01CDAD:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossBattleaxe   <- DLC2NordicBattleaxe
    @{ List = '03DF23:Skyrim.esm'; Items = @(,@('01CDAF:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossGreatsword  <- DLC2NordicGreatsword
    @{ List = '03DF21:Skyrim.esm'; Items = @(,@('01CDB3:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossWarhammer   <- DLC2NordicWarhammer
    @{ List = '03DF1F:Skyrim.esm'; Items = @(,@('01CDB0:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossMace        <- DLC2NordicMace
    @{ List = '03DF1D:Skyrim.esm'; Items = @(,@('01CDB1:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossSword       <- DLC2NordicSword
    @{ List = '03DF20:Skyrim.esm'; Items = @(,@('01CDB2:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossWarAxe      <- DLC2NordicWarAxe
    @{ List = '03DF1A:Skyrim.esm'; Items = @(,@('01CD96:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossBoots       <- DLC2ArmorNordicHeavyBoots
    @{ List = '03DF19:Skyrim.esm'; Items = @(,@('01CD97:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossCuirass     <- DLC2ArmorNordicHeavyCuirass
    @{ List = '03DF18:Skyrim.esm'; Items = @(,@('01CD98:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossGauntlets50 <- DLC2ArmorNordicHeavyGauntlets
    @{ List = '03DF1B:Skyrim.esm'; Items = @(,@('01CD99:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossHelmet50    <- DLC2ArmorNordicHeavyHelmet
    @{ List = '03DF22:Skyrim.esm'; Items = @(,@('026236:Dragonborn.esm', 1)); AllLevels = $true }   # LItemBanditBossShield      <- DLC2ArmorNordicShield
    # ---- Forsworn (WD-43, user 2026-09-25): Forsworn armor at every level, Forsworn weapons for the low
    # rungs. Briarhearts and Ravagers (via author-retargets.ps1) draw from LItemForswornBossWeapon1H, whose
    # two lists get elven, dwarven and a rare glass back - vanilla had them gated 12..36, Requiem stripped
    # them. Enchanted elven/dwarven boss sublists too; no enchanted glass, no ebony. Weights in $weights.
    @{ List = '044301:Skyrim.esm'; Items = @(@('0139A1:Skyrim.esm', 1), @('013999:Skyrim.esm', 1), @('0139A9:Skyrim.esm', 1),
                                             @('0DDD8E:Skyrim.esm', 1), @('0DDD8C:Skyrim.esm', 1)) }   # LItemForswornBossSword  <- Elven/Dwarven/Glass, ench Elven/Dwarven
    @{ List = '044302:Skyrim.esm'; Items = @(@('01399B:Skyrim.esm', 1), @('013993:Skyrim.esm', 1), @('0139A3:Skyrim.esm', 1),
                                             @('0DDD9E:Skyrim.esm', 1), @('0DDD9C:Skyrim.esm', 1)) }   # LItemForswornBossWarAxe <- same, war axes
    # Briarheart shaman dagger (user, after play 2026-09-26). LItemWeaponDaggerBoss is used ONLY by the
    # EncForsworn0NBossMagic records, so it is edited in place. Enchanted elven/dwarven added; weights below.
    @{ List = '08CA38:Skyrim.esm'; Items = @(@('0CAF01:Skyrim.esm', 1), @('0C9A33:Skyrim.esm', 1)) }   # LItemWeaponDaggerBoss <- LItemEnchElvenDagger, LItemEnchDwarvenDagger
    # Archer arrows: Forsworn or iron, 50/50 (user, 2026-09-26). Requiem made LItemForswornArrows all iron
    # (x22 / x15 / x12); a Forsworn arrow entry at each of the same counts evens it. Also used by the CC
    # Crowstooth (ccbgssse059), a Forsworn, who gets the same.
    @{ List = '10FABD:Skyrim.esm'; Items = @(@('0CEE9E:Skyrim.esm', 22), @('0CEE9E:Skyrim.esm', 15), @('0CEE9E:Skyrim.esm', 12)) }   # LItemForswornArrows <- ForswornArrow
    # The 15% bonus arrow roll every Forsworn archer carries (LootForswornArrows15, Forsworn-only) pointed at
    # LItemArrowsAll: steel-to-Nordic arrows plus the CC exotic-arrow sublist ($ccReadd) - the fire and ice
    # arrows seen in play. It now rolls the Forsworn arrow list instead; LItemArrowsAll is cut in $cuts.
    @{ List = '06A3CD:Skyrim.esm'; Items = @(,@('10FABD:Skyrim.esm', 1)) }   # LootForswornArrows15 <- LItemForswornArrows
    # ---- Imperial soldiers and Imperial-held hold guards (WD-44/45, found in play 2026-09-26: they fought
    # bare-handed). Requiem moved their weapons into its own lists (REQ_LI_Weapon_ImperialMissile AD3944,
    # REQ_LI_Weapon_Imperial1H AD3945, REQ_Weapon_Imperial_Dagger 7F8C37); bucket B stripped those as
    # Requiem-only and left the chain with no weapon at all. Vanilla's set goes back where Requiem put it,
    # so the NoBow variant still gets a blade.
    @{ List = '10FAFC:Skyrim.esm'; Items = @(,@('013841:Skyrim.esm', 1)) }                            # CWSoldierImperialGearNoTorch      <- ImperialBow
    @{ List = '10FAFD:Skyrim.esm'; Items = @(@('0135B8:Skyrim.esm', 1), @('013986:Skyrim.esm', 1)) }  # CWSoldierImperialGearNoTorchNoBow <- Imperialsword, SteelDagger
    # ---- Thalmor archers had arrows but no bow: same bucket-B strip. Requiem wrapped each bow in a one-item
    # list (REQ_LI_Weapon_ThalmorBowElven AD3942, ...Glass AD3941). Vanilla's bow goes back; which Thalmor
    # rank gets which sublist is for the Thalmor ticket.
    @{ List = '07D983:Skyrim.esm'; Items = @(,@('01399D:Skyrim.esm', 1)) }   # SublistThalmorBowAndArrowsElven <- ElvenBow
    @{ List = '07D984:Skyrim.esm'; Items = @(,@('0139A5:Skyrim.esm', 1)) }   # SublistThalmorBowAndArrowsGlass <- GlassBow
)

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
    @{ List = '039D2F:Skyrim.esm'; Items = @(,@("000830:$arrows", 12)) }                        # LItemBanditWeaponArrows: fire (10). Bone (30) dropped: 26 damage
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
    # Not overridden yet: start from the WINNING vanilla record (last in load order), or for a list
    # defined by a Creation Club plugin, from that plugin's decompile.
    $src = $null
    $roots = @($loadOrder | ForEach-Object { Join-Path $base $_ })
    if ($ccMasters -contains $master) { $roots += Join-Path $cc ([System.IO.Path]::GetFileNameWithoutExtension($master)) }
    foreach ($srcRoot in $roots) {
        foreach ($dir in 'LeveledItems', 'LeveledNpcs') {
            $hit = @(Get-ChildItem -LiteralPath (Join-Path $srcRoot $dir) -Filter "* - ${id}_$master.yaml" -ErrorAction SilentlyContinue)
            if ($hit.Count -eq 1) { $src = $hit[0]; $srcDir = $dir }
        }
    }
    if ($src -eq $null) { throw "no leveled list $formKey in the plugin, reference/Base or the CC decompiles" }
    $dst = Join-Path (Join-Path $esp $srcDir) $src.Name
    Copy-Item -LiteralPath $src.FullName -Destination $dst
    return $dst
}

$allLevels = '- CalculateFromAllLevelsLessThanOrEqualPlayer'
$added = 0
foreach ($r in ($readdByPlace + $ccReadd)) {
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

# ---------------------------------------------------------------- cuts and weights
# Keyed by the list's full FormKey, on any master (a list not yet overridden is copied from its winning
# record first - see Find-ListFile). Grouped by faction; add a block per faction.
#   $cuts    '<list FormKey>' = @('<entry FormKey>', ...)            every entry with that Reference is removed
#   $weights '<list FormKey>' = [ordered]@{ '<entry FormKey>' = N }  that Reference ends up with exactly N entries
#
# ---- Bandits. User decisions 2026-09-24, after play:
#  - A chief is the camp's T5 fight, so no iron - steel is the floor; and bandits never carry glass or
#    ebony (dungeon-hoard material). Removes the plain iron armor, enchanted iron weapons and the enchanted
#    glass mace from the chief lists. A recursive scan of every LItemBandit*/LootBandit*/DeathItemBandit*
#    list found no other glass or ebony gear (the only ebony left is an ingot in the shared
#    LItemLootIMineralsProcessed loot pool). The chief armor lists also feed
#    BanditArmorHeavyBossNoShieldOutfit, three named outfits (dunCraglsaneButcher, dunMistwatchFjolaArmor,
#    MS10Haldyn) and DLC2LItemBanditArmorAll; they lose the iron too, on purpose.
#  - An archer always has a bow. Requiem's LItemBanditWeaponBow points half its entries at the 1H and 2H
#    melee lists, so ~50% of archers spawned bowless with a full quiver. Those entries are cut; archers
#    keep the dagger their own inventory already carries. The list is shared with Thalmor archers, the
#    embassy guards, Penitus Oculatus and a few quest archers - all of them gain the fix.
#  - Bandit arrows: iron, with a 10% chance of fire. The CC bone arrow (26 damage, above Daedric's 24) is
#    not re-added at all (see $ccReadd). The list is also the Dremora and Thalmor archers' arrow list.
$cuts = [ordered]@{
    '03DF19:Skyrim.esm' = @('012E49:Skyrim.esm', '013948:Skyrim.esm')   # LItemBanditBossCuirass     - ArmorIronCuirass, ArmorIronBandedCuirass
    '03DF1A:Skyrim.esm' = @('012E4B:Skyrim.esm')                        # LItemBanditBossBoots       - ArmorIronBoots
    '03DF18:Skyrim.esm' = @('012E46:Skyrim.esm')                        # LItemBanditBossGauntlets50 - ArmorIronGauntlets
    '03DF1B:Skyrim.esm' = @('012E4D:Skyrim.esm')                        # LItemBanditBossHelmet50    - ArmorIronHelmet
    '03DF1F:Skyrim.esm' = @('0DDD98:Skyrim.esm', '0DDD97:Skyrim.esm')   # LItemBanditBossMace        - LItemEnchIronMaceBoss, LItemEnchGlassMaceBoss
    '03DF1D:Skyrim.esm' = @('0DDD90:Skyrim.esm')                        # LItemBanditBossSword       - LItemEnchIronSwordBoss
    '03DF20:Skyrim.esm' = @('0DDDA0:Skyrim.esm')                        # LItemBanditBossWarAxe      - LItemEnchIronWarAxeBoss
    '039D2E:Skyrim.esm' = @('037C1B:Skyrim.esm', '037C21:Skyrim.esm')   # LItemBanditWeaponBow       - LItemBanditWeapon1H, LItemBanditWeapon2H
    '039D2F:Skyrim.esm' = @('00082E:ccbgssse002-exoticarrows.esl')      # LItemBanditWeaponArrows    - CC bone arrow (belt and braces: never re-added)
    '06A3CD:Skyrim.esm' = @('068839:Skyrim.esm')                        # LootForswornArrows15       - LItemArrowsAll (CC fire/ice arrows, steel+)
}
# Weight = the exact number of entries a reference should have (entries are the engine's only weight).
$weights = [ordered]@{
    '039D2F:Skyrim.esm' = [ordered]@{ '037C0D:Skyrim.esm' = 9 }         # LItemBanditWeaponArrows: BaseArrowIron75 x9 : fire x1 = 90 / 10
    # Forsworn high tier: Forsworn 10 · Elven 4 · Dwarven 4 · ench Elven 1 · ench Dwarven 1 · Glass 1
    # = 48% / 19% / 19% / 5% / 5% / 5% (21 entries).
    '044301:Skyrim.esm' = [ordered]@{ '0CADE9:Skyrim.esm' = 10; '0139A1:Skyrim.esm' = 4; '013999:Skyrim.esm' = 4 }   # LItemForswornBossSword
    '044302:Skyrim.esm' = [ordered]@{ '0CC829:Skyrim.esm' = 10; '01399B:Skyrim.esm' = 4; '013993:Skyrim.esm' = 4 }   # LItemForswornBossWarAxe
    # Briarheart shaman dagger: Steel 4 · Orcish 4 · Dwarven 5 · Elven 5 · ench Dwarven 2 · ench Elven 2 ·
    # Glass 1 · Ebony 1 (24). Glass and ebony cut from 1-in-6 each to 1-in-24; the freed share went to
    # elven and dwarven (~29% each, 1-in-12 of the total enchanted). User, after play 2026-09-26.
    '08CA38:Skyrim.esm' = [ordered]@{ '013986:Skyrim.esm' = 4; '01398E:Skyrim.esm' = 4; '013996:Skyrim.esm' = 5
                                      '01399E:Skyrim.esm' = 5; '0C9A33:Skyrim.esm' = 2; '0CAF01:Skyrim.esm' = 2
                                      '0139A6:Skyrim.esm' = 1; '0139AE:Skyrim.esm' = 1 }   # LItemWeaponDaggerBoss
}

function Get-Blocks([string[]]$lines) {
    # Splits a leveled list into head / '- Data:' entry blocks / tail. A block ends at the next '- ' or top-level line.
    $head = New-Object System.Collections.ArrayList; $tail = New-Object System.Collections.ArrayList
    $blocks = New-Object System.Collections.ArrayList
    $cur = $null; $seen = $false
    foreach ($l in $lines) {
        if ($cur -ne $null) {
            if ($l -match '^  ') { [void]$cur.Add($l); continue }
            [void]$blocks.Add($cur); $cur = $null
        }
        if ($l -eq '- Data:') { $cur = New-Object System.Collections.ArrayList; [void]$cur.Add($l); $seen = $true; continue }
        if ($seen) { [void]$tail.Add($l) } else { [void]$head.Add($l) }
    }
    if ($cur -ne $null) { [void]$blocks.Add($cur) }
    return @{ Head = $head; Blocks = $blocks; Tail = $tail }
}
function Get-Ref($block) { ($block | Where-Object { $_ -match '^    Reference: ' } | Select-Object -First 1) -replace '^    Reference: ', '' }

$removed = 0
foreach ($id in @($cuts.Keys) + @($weights.Keys | Where-Object { $cuts.Keys -notcontains $_ })) {
    if ($id -notmatch '^[0-9A-F]{6}:.+\.es[mlp]$') { throw "cut/weight key '$id' is not a full FormKey (<hex>:<master>)" }
    $path  = Find-ListFile $id
    $p     = Get-Blocks @(Get-Content -LiteralPath $path -Encoding UTF8)
    $kept  = New-Object System.Collections.ArrayList
    $cut   = 0
    foreach ($b in $p.Blocks) { if ($cuts.Contains($id) -and $cuts[$id] -contains (Get-Ref $b)) { $cut++ } else { [void]$kept.Add($b) } }
    $changed = $cut -gt 0
    if ($weights.Contains($id)) {
        foreach ($ref in $weights[$id].Keys) {
            $mine = @($kept | Where-Object { (Get-Ref $_) -eq $ref })
            if ($mine.Count -eq 0) { throw "weight target $ref not in $path" }
            $want = $weights[$id][$ref]
            if ($mine.Count -ne $want) {
                $proto = $mine[0]
                foreach ($m in $mine) { [void]$kept.Remove($m) }
                for ($i = 0; $i -lt $want; $i++) { [void]$kept.Insert(0, $proto) }
                $changed = $true
                "{0,-72} {1} x{2}" -f (Split-Path -Leaf $path), $ref, $want
            }
        }
    }
    if (-not $changed) { continue }   # idempotent
    $out = New-Object System.Collections.ArrayList
    [void]$out.AddRange($p.Head); foreach ($b in $kept) { [void]$out.AddRange($b) }; [void]$out.AddRange($p.Tail)
    [System.IO.File]::WriteAllLines($path, $out, $utf8NoBom)
    if ($cut) { "{0,-72} -{1} entries" -f (Split-Path -Leaf $path), $cut }
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

"injectors: $($quests.Count) quests overridden ($total list properties removed), $added entries re-added at level 1, $removed entries cut, $($flatten.Count) CC sublists flattened, $($ccMasters.Count) CC masters"
