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

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$cc   = Join-Path $root 'reference\mods\CreationClubYaml'
$base = Join-Path $root 'reference\Base'
$esp  = Join-Path $root 'src\Ehlnofey\ProofOfConceptESP'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$loadOrder = @('01Skyrim', '02Update', '03Dawnguard', '04HearthFires', '05Dragonborn')

# ---------------------------------------------------------------- masters
# Every CC plugin this file names, in Skyrim.ccc load order.
$ccMasters = @(
    'ccasvsse001-almsivi.esm', 'ccbgssse001-fish.esm', 'ccbgssse002-exoticarrows.esl',
    'ccbgssse014-spellpack01.esl', 'ccbgssse036-petbwolf.esl', 'ccmtysse002-ve.esl',
    'ccbgssse050-ba_daedric.esl', 'ccbgssse052-ba_iron.esl', 'ccbgssse054-ba_orcish.esl',
    'ccbgssse058-ba_steel.esl', 'ccbgssse059-ba_dragonplate.esl', 'ccbgssse061-ba_dwarven.esl',
    'ccbgssse064-ba_elven.esl', 'ccbgssse063-ba_ebony.esl', 'ccbgssse062-ba_dwarvenmail.esl',
    'ccbgssse060-ba_dragonscale.esl', 'ccbgssse056-ba_silver.esl', 'ccbgssse055-ba_orcishscaled.esl',
    'ccbgssse053-ba_leather.esl', 'ccbgssse051-ba_daedricmail.esl', 'ccbgssse057-ba_stalhrim.esl',
    'ccbgssse067-daedinv.esm', 'ccvsvsse003-necroarts.esl', 'ccffbsse002-crossbowpack.esl', 'ccedhsse003-redguard.esl',
    'cccbhsse001-gaunt.esl'
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
    # Daedric Invasion (WD-64): its content-aware script (OnInit and every load) fills the pack's OWN Vigilant Enforcer
    # and crossbow lists from two other CC packs, gated: Vigil Veteran armor at 30, crossbows at 18/35. It never touches
    # our lists. The five target properties are stripped (the AddForms then hit None and do nothing); the items are
    # re-added below at level 1. Its backpack and survival-mode additions are level 1 / not gear, and stay.
    @{ Src = 'mods\CreationClubYaml\ccbgssse067-daedinv\Quests\ccBGSSSE067_Quest - 06BFC1_ccbgssse067-daedinv.esm.yaml'
       Strip = @('ccBGSSSE067_CC_LItemVigilantEnforcerBoots', 'ccBGSSSE067_CC_LItemVigilantEnforcerGauntlets', 'ccBGSSSE067_CC_LItemVigilantEnforcerHelmet',
                 'ccBGSSSE067_CC_LItemVigilantEnforcerTorso', 'ccBGSSSE067_CC_LItemWeaponCrossbows') }
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
    # ---- Thalmor Justiciars (WD-48, user 2026-09-26): Elven, with a rare chance of glass. Both Justiciar records
    # (WE32/33/34, WERoad03) are pointed at the no-helmet outfit by author-retargets.ps1; its list is used by that
    # outfit alone, and now rolls both looks: Elven with or without a helmet 9 : 9, glass with or without 1 : 1
    # (10% glass). Weights in $weights. Every other Thalmor soldier's outfit stays plain Elven.
    @{ List = '07D97A:Skyrim.esm'; Items = @(@('07D973:Skyrim.esm', 1), @('07D978:Skyrim.esm', 1), @('07D977:Skyrim.esm', 1)) }   # LItemThalmorArmorNoHelmetAll <- Elven w/ helmet, Glass w/o and w/ helmet
    # ---- Vampires (WD-47, user 2026-09-26). Every generic vampire, mook or boss, carries LItemVampireWeaponBase
    # (used by vampires only), which pointed at the BANDIT sword and war-axe lists: 70% iron. It now holds its
    # own steel / orcish / dwarven / elven sword and war axe, one each (25% per material, no iron, no glass).
    # The two bandit-list entries are cut in $cuts.
    @{ List = '10962B:Skyrim.esm'; Items = @(@('013989:Skyrim.esm', 1), @('013991:Skyrim.esm', 1), @('013999:Skyrim.esm', 1), @('0139A1:Skyrim.esm', 1),
                                             @('013983:Skyrim.esm', 1), @('01398B:Skyrim.esm', 1), @('013993:Skyrim.esm', 1), @('01399B:Skyrim.esm', 1)) }   # LItemVampireWeaponBase <- Steel/Orcish/Dwarven/Elven Sword + WarAxe
    # ---- Draugr (WD-49, user 2026-09-27). Requiem took Ebony off every draugr: the "Ebony" lists hold plain ancient Nord
    # and a steel shield. Ebony goes back on the Ebony Death Overlord (45) only, the top rung of the boss band, as the
    # only thing that tells it apart from the Death Overlord (34) under the same name. These three lists are used only
    # by the Ebony rung (boss leaves and their mook Deathlord twins, which no longer spawn from any list); the old
    # entries are cut in $cuts. Plain Ebony, as vanilla. Everything else stays ancient Nord (Requiem's ceiling).
    @{ List = '02432D:Skyrim.esm'; Items = @(@('0139B1:Skyrim.esm', 1), @('0139AB:Skyrim.esm', 1)) }                            # LItemDraugr05EWeapon1H   <- EbonySword, EbonyWarAxe
    @{ List = '024330:Skyrim.esm'; Items = @(@('0139AF:Skyrim.esm', 1), @('0139AC:Skyrim.esm', 1), @('0139B2:Skyrim.esm', 1)) }  # LItemDraugr05EWeapon2H   <- EbonyGreatsword, EbonyBattleaxe, EbonyWarhammer
    @{ List = '0559FB:Skyrim.esm'; Items = @(,@('013964:Skyrim.esm', 1)) }                                                       # LItemDraugrEbonyShield50 <- ArmorEbonyShield
    # Vanilla gold on draugr corpses (user, WD-49). Requiem cut it for a guaranteed bone meal, which stays. All four
    # lists put back are already flat: DeathItemDraugrGold (25%, coin), the Golden Touch perk bonus, the Imperial
    # racial bonus, and the Dragon Priest's 50-250 boss gold.
    @{ List = '03AD7F:Skyrim.esm'; Items = @(@('04F78C:Skyrim.esm', 1), @('0424EB:Skyrim.esm', 1), @('0AA02C:Skyrim.esm', 1)) }  # DeathItemDraugr      <- DeathItemDraugrGold, LootPerkGoldenTouchChange, LootImperialLuck
    @{ List = '10FACC:Skyrim.esm'; Items = @(@('04F78C:Skyrim.esm', 1), @('0424EB:Skyrim.esm', 1), @('0AA02C:Skyrim.esm', 1)) }  # DeathItemDraugrMage  <- same
    @{ List = '03AD7E:Skyrim.esm'; Items = @(,@('088513:Skyrim.esm', 1)) }                                                       # DeathItemDragonPriest <- LootDraugrGoldBoss01
    # ---- Dragons (WD-53, user 2026-09-27): vanilla's gold and gems back on dragon corpses. Requiem cut them and left
    # bones and scales only; its bone and scale counts stay. Every list put back is already flat. Vanilla's 25% armor and
    # weapon rolls (LootDragonArmor25 / Weapon25) stay out: they point at the game-wide All lists, iron to Daedric at random.
    # Counts are vanilla's. The Revered and Legendary death items add a second dragon gold roll, as vanilla did; their 25%
    # Daedric roll stays out for the same reason.
    @{ List = '03ADA5:Skyrim.esm'; Items = @(@('0F77F2:Skyrim.esm', 1), @('037C2B:Skyrim.esm', 2), @('0424EB:Skyrim.esm', 5),
                                             @('0AA02C:Skyrim.esm', 5), @('0F77F7:Skyrim.esm', 1), @('0FFF52:Skyrim.esm', 1)) }
                                             # DeathItemDragon01 <- LootDragonGold, LootGoldChange, LootPerkGoldenTouchChange,
                                             #                      LootImperialLuck, LootDragonGems25, TGLootProwlersProfit
    @{ List = '010963:Dawnguard.esm'; Items = @(,@('0F77F2:Skyrim.esm', 1)) }   # DLC1DeathItemDragon06 <- LootDragonGold
    @{ List = '010964:Dawnguard.esm'; Items = @(,@('0F77F2:Skyrim.esm', 1)) }   # DLC1DeathItemDragon07 <- LootDragonGold
    # Penitus Oculatus (WD-56): bucket B had stripped Requiem's REQ_LI_Weapon_PenitusMissile and REQ_LI_Gear_Penitus, the same
    # bug the Imperials had. Archers had no bow, and every agent had lost vanilla's dagger, gold, food, drink, torch and Imperial
    # symbol. Requiem's LItemPenitusWeapon1H (the Imperial sword) stays in PenitusGear, which the bow list nests.
    @{ List = '10FF0A:Skyrim.esm'; Items = @(,@('013841:Skyrim.esm', 1)) }   # PenitusGearWithBow <- ImperialBow
    @{ List = '10FF09:Skyrim.esm'; Items = @(@('013986:Skyrim.esm', 1), @('04F78D:Skyrim.esm', 1), @('04F78D:Skyrim.esm', 1), @('10E0DE:Skyrim.esm', 1),
                                             @('10E0E1:Skyrim.esm', 1), @('10E8A8:Skyrim.esm', 1), @('10FAF9:Skyrim.esm', 1), @('10FAFB:Skyrim.esm', 1)) }
                                             # PenitusGear <- SteelDagger, LootGoldChange25 x2, LootDrinkList25, LItemFoodInnCommon10,
                                             #                LootGoldChange50, LItemTorch50, LItemImperialSymbol10
    # Dawnguard (WD-58): Requiem moved the war axe into its axe-and-shield lists, bucket B stripped them, and every Dawnguard
    # mook carried only the two-handed warhammer. The axe is back, 1:1 with the hammer, as in vanilla.
    @{ List = '01421C:Dawnguard.esm'; Items = @(,@('00D098:Dawnguard.esm', 1)) }   # LItemDawnguardWeaponAny <- DLC1DawnguardAxe
    # Berserkers (2026-09-27): vanilla's SubCharBandit02Melee2HBerserk holds the level-1 EncBandit01 berserkers, not the
    # Outlaw (02) ones, so the berserker roll kept the dropped level-1 rung 3 times in 9. Its five leaves are swapped for the
    # EncBandit02 ones (cut and weighted below, keeping vanilla's 1/2/2/1/2 race mix). The berserker ghosts share the list.
    @{ List = '03DEBB:Skyrim.esm'; Items = @(@('03DEA4:Skyrim.esm', 1), @('03DEA5:Skyrim.esm', 1), @('03DEA6:Skyrim.esm', 1),
                                             @('03DEA7:Skyrim.esm', 1), @('03DEA8:Skyrim.esm', 1)) }   # EncBandit02Melee2HBerserk NordF/NordM/OrcM/RedguardF/RedguardM
    # Solstheim boss chests (WD-59, user: glass and above in boss chests only). The eight DLC2LItemWeapon* lists feed both
    # plain and boss chests and carried glass, Stalhrim, ebony and Daedric at level 1; those are cut below. The three
    # DLC2Loot*Weapon100 lists are the boss chests only (bandit and werewolf, draugr, Dwemer); each gains the rare list as one
    # more entry beside the eight weapon types, so a boss chest's weapon is glass or better 1 time in 10 (1 in 11 for Dwemer chests).
    @{ List = '02BC3D:Dragonborn.esm'; Items = @(,@('000805:Ehlnofey.esp', 1)) }   # DLC2LootBanditWeapon100  <- EHL_LVLI_SolstheimBossWeaponRare
    @{ List = '02C448:Dragonborn.esm'; Items = @(,@('000805:Ehlnofey.esp', 1)) }   # DLC2LootDraugrWeapon100  <- same
    @{ List = '02C452:Dragonborn.esm'; Items = @(,@('000805:Ehlnofey.esp', 1)) }   # DLC2LootDwarvenWeapon100 <- same
)

$fish = 'ccbgssse001-fish.esm'; $arrows = 'ccbgssse002-exoticarrows.esl'; $spell = 'ccbgssse014-spellpack01.esl'
$alm = 'ccasvsse001-almsivi.esm'; $necro = 'ccvsvsse003-necroarts.esl'
$dinv = 'ccbgssse067-daedinv.esm'; $ve = 'ccmtysse002-ve.esl'; $xbow = 'ccffbsse002-crossbowpack.esl'
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
    @{ List = '02DF9F:Skyrim.esm'; Items = @(,@("00082F:$arrows", 12)) }                        # LItemVampireWeaponArrows: ice (14). Bone (30) dropped (WD-47)
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
    @{ List = '0374E7:Dragonborn.esm'; Items = @(,@("000E38:$alm", 1)) }   # DLC2LItemWeaponSwordTown
    @{ List = '0374EA:Dragonborn.esm'; Items = @(@("000E37:$alm", 1), @("000E38:$alm", 1)) }   # DLC2LItemWeaponAny1HTown (new override)
    # necroarts: the CC boss of the rung the pinned voice list holds. Its bosses stop at 06 (level 40), so only
    # MaleCondescending, pinned at 40 for want of a level-50 Breton M, takes one; the lists pinned at 50 take
    # none (WD-46, user 2026-09-26).
    @{ List = '0E106D:Skyrim.esm'; Items = @(,@("000924:$necro", 1)) }   # MaleCondescending: 06 BretonM
    # Daedric Invasion (WD-64): what its script put into its own lists, all at level 1. The Enforcer lists are empty on
    # disk; the script also added the four vanilla Vigilant gear lists to them at level 1, and those go back too.
    @{ List = "06BFBB:$dinv"; Items = @(@("000D63:$ve", 1), @("000D7A:$ve", 1), @('10BFF2:Skyrim.esm', 1)) }   # EnforcerBoots: Enforcer, Veteran (30), LItemVigilantHeavyBoots
    @{ List = "06BFBC:$dinv"; Items = @(@("000D62:$ve", 1), @("000D7C:$ve", 1), @('10BFF3:Skyrim.esm', 1)) }   # EnforcerGauntlets: Enforcer, Veteran (30), LItemVigilantHeavyGauntlets50
    @{ List = "06BFBD:$dinv"; Items = @(@("000D65:$ve", 1), @("000D64:$ve", 1), @("000D7D:$ve", 1), @('10C460:Skyrim.esm', 1)) }   # EnforcerHelmet: Enforcer, Veteran full + helmet (30), LItemVigilantHood
    @{ List = "06BFBE:$dinv"; Items = @(@("000D61:$ve", 1), @("000D7B:$ve", 1), @("000800:$ve", 1), @('10C45F:Skyrim.esm', 1)) }   # EnforcerTorso: Enforcer, Veteran + sash (30), LItemVigilantRobes
    @{ List = "06BFC0:$dinv"; Items = @(@("00080B:$xbow", 1), @("00080C:$xbow", 1), @("00080D:$xbow", 1), @("00080E:$xbow", 1), @("00080F:$xbow", 1)) }   # Crossbows: Imperial, Nordic, Orcish (1), Silver (18), Stalhrim (35)
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

# ---------------------------------------------------------------- new lists (Ehlnofey.esp FormIDs)
# The plugin's own records, for gear that no vanilla list can carry without leaking to everyone who shares it.
# ESL range 0x800-0xFFF; claim a contiguous block per feature and record it in CLAUDE.md (Naming & FormKey).
# Row shape: @{ FormKey; EditorID; Items = @(@(<item FormKey>, <count>, <weight>), ...) }. Every entry is level 1.
#   0x800-0x801  Thalmor (WD-48)
$newLists = @(
    # Justiciar one-handed weapon: Elven sword/war axe/mace, glass 1 in 10. Only the two WEThalmorElvenArmor* records use it.
    @{ FormKey = '000800:Ehlnofey.esp'; EditorID = 'EHL_LVLI_ThalmorJusticiarWeapon1H'
       Items = @(@('01E60E:Skyrim.esm', 1, 9), @('07D97C:Skyrim.esm', 1, 1)) }   # SublistThalmorWeaponElven1H x9, SublistThalmorWeaponGlass1H x1
    # Boss wizard dagger: Elven, glass 1 in 10. Only EncThalmor06MagicBossM uses it (the level-50 boss).
    @{ FormKey = '000801:Ehlnofey.esp'; EditorID = 'EHL_LVLI_ThalmorBossDagger'
       Items = @(@('01399E:Skyrim.esm', 1, 9), @('0139A6:Skyrim.esm', 1, 1)) }   # ElvenDagger x9, GlassDagger x1
    # WD-59: what the eight DLC2LItemWeapon* lists lose (glass, Stalhrim, ebony, the Daedric sublists and the almsivi ebony
    # mace and scimitar), gathered for the Solstheim boss chests only. 0x802-0x804 are bucket D's Silver Hand LVLN.
    @{ FormKey = '000805:Ehlnofey.esp'; EditorID = 'EHL_LVLI_SolstheimBossWeaponRare'
       Items = @(@('0139A4:Skyrim.esm', 1, 1), @('01CDB4:Dragonborn.esm', 1, 1), @('0139AC:Skyrim.esm', 1, 1), @('000F0B:Skyrim.esm', 1, 1),    # battleaxe
                 @('0139A5:Skyrim.esm', 1, 1), @('026231:Dragonborn.esm', 1, 1), @('0139AD:Skyrim.esm', 1, 1), @('000F0D:Skyrim.esm', 1, 1),    # bow
                 @('0139A6:Skyrim.esm', 1, 1), @('01CDB5:Dragonborn.esm', 1, 1), @('0139AE:Skyrim.esm', 1, 1), @('000F0F:Skyrim.esm', 1, 1),    # dagger
                 @('0139A7:Skyrim.esm', 1, 1), @('01CDB6:Dragonborn.esm', 1, 1), @('0139AF:Skyrim.esm', 1, 1), @('000F11:Skyrim.esm', 1, 1),    # greatsword
                 @('0139A8:Skyrim.esm', 1, 1), @('01CDB7:Dragonborn.esm', 1, 1), @('0139B0:Skyrim.esm', 1, 1), @('000F13:Skyrim.esm', 1, 1),    # mace
                 @('0139A9:Skyrim.esm', 1, 1), @('01CDB8:Dragonborn.esm', 1, 1), @('0139B1:Skyrim.esm', 1, 1), @('000F15:Skyrim.esm', 1, 1),    # sword
                 @('0139A3:Skyrim.esm', 1, 1), @('01CDB9:Dragonborn.esm', 1, 1), @('0139AB:Skyrim.esm', 1, 1), @('000F17:Skyrim.esm', 1, 1),    # war axe
                 @('0139AA:Skyrim.esm', 1, 1), @('01CDBA:Dragonborn.esm', 1, 1), @('0139B2:Skyrim.esm', 1, 1), @('000F19:Skyrim.esm', 1, 1),    # warhammer
                 @("000E37:$alm", 1, 1), @("000E38:$alm", 1, 1)) }   # ccASVSSE001_EbonyMace, ccASVSSE001_EbonyScimitar
)
foreach ($n in $newLists) {
    $id, $master = $n.FormKey -split ':'
    $out = New-Object System.Collections.ArrayList
    foreach ($l in @("FormKey: $($n.FormKey)", "EditorID: $($n.EditorID)", 'Flags:', $allLevels, 'Entries:')) { [void]$out.Add($l) }
    foreach ($i in $n.Items) {
        for ($w = 0; $w -lt $i[2]; $w++) {
            foreach ($l in @('- Data:', '    Level: 1', "    Reference: $($i[0])", "    Count: $($i[1])")) { [void]$out.Add($l) }
        }
    }
    $path = Join-Path (Join-Path $esp 'LeveledItems') "$($n.EditorID) - ${id}_$master.yaml"
    [System.IO.File]::WriteAllLines($path, $out, $utf8NoBom)
    "{0,-72} new, {1} entries" -f (Split-Path -Leaf $path), (($out | Where-Object { $_ -eq '- Data:' }) | Measure-Object).Count
}

$added = 0
foreach ($r in ($readdByPlace + $ccReadd)) {
    $path  = Find-ListFile $r.List
    $lines = @(Get-Content -LiteralPath $path -Encoding UTF8)
    $new   = @($r.Items | Where-Object { $lines -notcontains "    Reference: $($_[0])" })   # idempotent
    $flag  = $r.ContainsKey('AllLevels') -and -not ($lines -contains $allLevels)
    if ($new.Count -eq 0 -and -not $flag) { continue }
    # A list empty on disk (the Daedric Invasion Enforcer lists, filled only by script) has no Entries: block. Append one;
    # Spriggit puts it back in canonical order on the round-trip.
    if ($lines -notcontains 'Entries:') { $lines = @($lines + 'Entries:') }
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

# ---------------------------------------------------------------- flatten gated CC sublists
# Injected at level 1, but gated inside. Flatten the gate, keep the pool (duplicates are the weights).
# Runs BEFORE cuts and weights: it rewrites these files from the CC decompile, so a cut made earlier would be
# lost (the vendor sublist's bone arrow is cut below, WD-47).
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
#    embassy guards and a few quest archers - all of them gain the fix. (Not the Penitus Oculatus, as this said until
#    WD-56: their archers use PenitusGearWithBow, whose bow is re-added above.)
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
    # ---- Vampires (WD-47, user 2026-09-26)
    #  - Weapons: the bandit lists go; LItemVampireWeaponBase holds its own mix (see $readdByPlace).
    #  - Armor: vampire armor and enchanted vampire robes only. Requiem added the Leather/Orcish/Elven/Glass sets
    #    to LItemVampireAttire (so ~1 in 12 wore glass). The list feeds vampireOutfit, worn by every generic vampire.
    #  - Arrows: no CC bone arrow (user 2026-09-25). LItemVampireWeaponArrows is referenced by nothing in base+DLC,
    #    so that cut is belt and braces. The exotic-arrows vendor sublist, which sits in LItemArrowsAll,
    #    DLC2LItemArrowsAll and the vendor arrows, DID hold one: cut there too (the flatten below runs first).
    '10962B:Skyrim.esm' = @('037C19:Skyrim.esm', '037C1A:Skyrim.esm')   # LItemVampireWeaponBase     - LItemBanditSword, LItemBanditWarAxe
    '10C6ED:Skyrim.esm' = @('10C6EE:Skyrim.esm', '01D248:Skyrim.esm', '10C6EF:Skyrim.esm', '10C6F0:Skyrim.esm')   # LItemVampireAttire - Leather/Orc/Elven/Glass sets
    '02DF9F:Skyrim.esm' = @('00082E:ccbgssse002-exoticarrows.esl')      # LItemVampireWeaponArrows   - CC bone arrow
    '000810:ccbgssse002-exoticarrows.esl' = @('00082E:ccbgssse002-exoticarrows.esl')   # ccBGSSSE002_LItemArrowMagicAny_Vendor - CC bone arrow
    # ---- Draugr (WD-49): Requiem's ancient Nord stand-ins leave the Ebony lists (Ebony re-added above).
    '02432D:Skyrim.esm' = @('02C66F:Skyrim.esm', '01CB64:Skyrim.esm')   # LItemDraugr05EWeapon1H   - DraugrSword, DraugrBattleAxe
    '024330:Skyrim.esm' = @('0236A5:Skyrim.esm', '01CB64:Skyrim.esm')   # LItemDraugr05EWeapon2H   - DraugrGreatsword, DraugrBattleAxe
    '0559FB:Skyrim.esm' = @('013955:Skyrim.esm')                        # LItemDraugrEbonyShield50 - ArmorSteelShield
    '03DEBB:Skyrim.esm' = @('03DE6E:Skyrim.esm', '03DE6F:Skyrim.esm', '03DE70:Skyrim.esm', '03DE71:Skyrim.esm', '03DE72:Skyrim.esm')   # SubCharBandit02Melee2HBerserk - the EncBandit01 (level 1) berserkers
    # WD-59: glass and above out of the plain Solstheim weapon lists (Glass, Stalhrim, Ebony, SublistWeapon*Daedric05, almsivi)
    '02BC0D:Dragonborn.esm' = @('0139A4:Skyrim.esm', '01CDB4:Dragonborn.esm', '0139AC:Skyrim.esm', '000F0B:Skyrim.esm')   # DLC2LItemWeaponBattleAxe
    '02BC0E:Dragonborn.esm' = @('0139A5:Skyrim.esm', '026231:Dragonborn.esm', '0139AD:Skyrim.esm', '000F0D:Skyrim.esm')   # DLC2LItemWeaponBow
    '02BC0F:Dragonborn.esm' = @('0139A6:Skyrim.esm', '01CDB5:Dragonborn.esm', '0139AE:Skyrim.esm', '000F0F:Skyrim.esm')   # DLC2LItemWeaponDagger
    '02BC10:Dragonborn.esm' = @('0139A7:Skyrim.esm', '01CDB6:Dragonborn.esm', '0139AF:Skyrim.esm', '000F11:Skyrim.esm')   # DLC2LItemWeaponGreatSword
    '02BC11:Dragonborn.esm' = @('0139A8:Skyrim.esm', '01CDB7:Dragonborn.esm', '0139B0:Skyrim.esm', '000F13:Skyrim.esm', "000E37:$alm")   # DLC2LItemWeaponMace
    '02BC12:Dragonborn.esm' = @('0139A9:Skyrim.esm', '01CDB8:Dragonborn.esm', '0139B1:Skyrim.esm', '000F15:Skyrim.esm', "000E38:$alm")   # DLC2LItemWeaponSword
    '02BC13:Dragonborn.esm' = @('0139A3:Skyrim.esm', '01CDB9:Dragonborn.esm', '0139AB:Skyrim.esm', '000F17:Skyrim.esm')   # DLC2LItemWeaponWarAxe
    '02BC14:Dragonborn.esm' = @('0139AA:Skyrim.esm', '01CDBA:Dragonborn.esm', '0139B2:Skyrim.esm', '000F19:Skyrim.esm')   # DLC2LItemWeaponWarhammer
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
    # Thalmor Justiciar armor (WD-48): Elven no helmet 9 · Elven helmet 9 · glass no helmet 1 · glass helmet 1.
    '07D97A:Skyrim.esm' = [ordered]@{ '07D974:Skyrim.esm' = 9; '07D973:Skyrim.esm' = 9 }   # LItemThalmorArmorNoHelmetAll
    '03DEBB:Skyrim.esm' = [ordered]@{ '03DEA5:Skyrim.esm' = 2; '03DEA6:Skyrim.esm' = 2; '03DEA8:Skyrim.esm' = 2 }   # SubCharBandit02Melee2HBerserk: vanilla's NordM/OrcM/RedguardM x2
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
