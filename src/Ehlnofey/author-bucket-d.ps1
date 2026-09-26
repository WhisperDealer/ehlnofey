# Bucket D - the 66 LVLN the Requiem extract could not copy.
#
# Requiem's versions of these delegate to REQ_LChar_VoiceSpawns_* sublists that are Requiem-only AND
# still player-gated (1/2/5/8/9/10), so nothing was liftable. extract-requiem.ps1 leaves a naive
# vanilla flatten as a placeholder; this script replaces it with the designed rosters from
# arch-docs/design/archetype-tiers.md. Run AFTER extract-requiem.ps1.
#
# Every roster is a FILTER + WEIGHTING of the vanilla record. No level is ever written onto an actor
# (rule 1: level and capability are welded together on the tier records), and weighting is literal
# entry duplication (rule 2: the engine has no weight field). Three shapes:
#
#   Cap     keep vanilla's own eligible mix frozen at the reference level of the assigned tier,
#           i.e. entries gated <= N. This is 4.1.2's rule verbatim and it reproduces the doc's
#           rosters exactly for the eight flagged predator lists.
#   Gates   explicit per-gate weights, for the curated ladders in 3.1 / 3.3 / 4.
#   Refs    explicit per-reference weights, where a single gate holds several species (mudcrab).
#   Pin     explicit references that vanilla's list does NOT hold (the warlock level-50 bosses). Each
#           becomes one level-1 entry, shaped like the list's first vanilla entry.
#
# Tier reference levels (tiers.md): T1 4 · T2 8 · T3 14 · T4 21 · T5 30 · T6 40 · T7 50
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$base = 'reference/Base'
$dst  = 'src/Ehlnofey/EhlnofeyESP/LeveledNpcs'
$loadOrder = @('01Skyrim', '02Update', '03Dawnguard', '04HearthFires', '05Dragonborn')

# 3.1 Bandit: Bandit 1 · Outlaw 5 · Thug 9 · Highwayman 14 · Plunderer 19 · Marauder 25
#     roster "Outlaw x3 · Thug x4 · Highwayman x2", band T2-T3.
#     Revised 2026-09-24: the level-1 rung is DROPPED, as Plunderer and Marauder already were. It
#     shares the family name "Bandit" with nothing to tell it apart, and the attempt to rename it
#     "Bandit Runt" never showed in game, so it was reverted (44 extra NPC_ overrides = conflicts
#     for nothing). Chiefs are pinned separately below, at 28.
$banditLadder = @{ 5 = 3; 9 = 4; 14 = 2 }
# 3.1 Bandit boss: the gates map to SubCharBandit02..06Boss at levels 6/10/16/21/28.
#     PINNED to a single rung, NOT the "16 x2 · 21 x2 · 28 x1" band archetype-tiers.md 3.1
#     specifies. Twist 2's authoring rule decides it: every rung of this ladder displays the SAME
#     name. No EncBandit0*Boss* leaf carries a FULL and none templates Traits, so the name always
#     falls through to LvlBanditBoss 03DF17 = "Bandit Chief". A three-level band under one name is
#     a 75% power swing the player cannot read.
#     Contrast the mook ladder above, where 1/5/9/14 really are Bandit/Outlaw/Thug/Highwayman.
#     The rung is gate 29 = level 28, the TOP of the vanilla ladder (~T5), chosen 2026-07-30 over
#     the T4 rung 21: a camp's chief is the one fight in it that should outclass the T2 mooks.
#     Gate 29 appears twice in the *M lists (1H and 2H); weight 1 keeps both, so the pin costs
#     the level spread and nothing else.
$banditBoss = @{ 29 = 1 }

$spec = [ordered]@{}
function Add-Spec($key, $editorId, $rule) { $spec[$key] = @{ Id = $editorId; Rule = $rule } }

# ---- already flat in vanilla: a single gate at 1. No override needed at all (4.1.3).
foreach ($d in @(
    @('04229C:Skyrim.esm',   'LCharAnimalCanyonPrey'),
    @('0422A4:Skyrim.esm',   'LCharAnimalCoastSnowPrey'),
    @('0422A2:Skyrim.esm',   'LCharAnimalMountainSnowPrey'),
    @('0ABEDC:Skyrim.esm',   'LCharDeer'),
    @('0DB2AC:Skyrim.esm',   'LCharElk'),
    @('03DECD:Skyrim.esm',   'LCharBanditMeleeAny'),
    @('02D2D4:Skyrim.esm',   'LCharSkeletonMeleeMixed'),
    @('0B83C2:Skyrim.esm',   'LCharWolf'),
    @('10C452:Skyrim.esm',   'SubCharVigilantOfStendarr01'))) {
    Add-Spec $d[0] $d[1] @{ Drop = $true }
}

# ---- the bandit ladder (3.1). Every melee / missile / wizard leaf shares the same six gates.
foreach ($d in @(
    @('039CFC:Skyrim.esm',    'LCharBanditMelee1H'),
    @('03DEC9:Skyrim.esm',    'LCharBanditMelee1HTank'),
    @('03DEC8:Skyrim.esm',    'LCharBanditMelee2H'),
    @('03DECA:Skyrim.esm',    'LCharBanditMelee2HBerserk'),
    @('01A31E:Skyrim.esm',    'LCharBanditMeleeCommonerF'),
    @('01A319:Skyrim.esm',    'LCharBanditMeleeCommonerM'),
    @('01A322:Skyrim.esm',    'LCharBanditMeleeEvenTonedF'),
    @('01A323:Skyrim.esm',    'LCharBanditMeleeEvenTonedM'),
    @('01A321:Skyrim.esm',    'LCharBanditMeleeNordF'),
    @('01A320:Skyrim.esm',    'LCharBanditMeleeNordM'),
    @('01B0E9:Skyrim.esm',    'LCharBanditMeleeOrcM'),
    @('01E770:Skyrim.esm',    'LCharBanditMissile'),
    @('01A342:Skyrim.esm',    'LCharBanditMissileCommonerF'),
    @('01A343:Skyrim.esm',    'LCharBanditMissileCommonerM'),
    @('01A344:Skyrim.esm',    'LCharBanditMissileEvenTonedF'),
    @('01A345:Skyrim.esm',    'LCharBanditMissileEvenTonedM'),
    @('01A346:Skyrim.esm',    'LCharBanditMissileNordF'),
    @('01A348:Skyrim.esm',    'LCharBanditMissileNordM'),
    @('01E771:Skyrim.esm',    'LCharBanditWizard'),
    @('01B0F0:Skyrim.esm',    'LCharBanditWizardCommonerF'),
    @('01B0F3:Skyrim.esm',    'LCharBanditWizardCommonerM'),
    @('01B0F4:Skyrim.esm',    'LCharBanditWizardEvenTonedF'),
    @('01B0F5:Skyrim.esm',    'LCharBanditWizardEvenTonedM'),
    @('01B0F7:Skyrim.esm',    'LCharBanditWizardNordF'),
    @('01B0FB:Skyrim.esm',    'LCharBanditWizardNordM'),
    @('01E8A8:Dragonborn.esm','DLC2LCharBanditMagic'),
    @('01E8A9:Dragonborn.esm','DLC2LCharBanditMelee1H'),
    @('0374C0:Dragonborn.esm','DLC2LCharBanditMelee1HDarkElfMCommoner'),
    @('0374BE:Dragonborn.esm','DLC2LCharBanditMelee1HDarkElfMCynical'),
    @('01E8AA:Dragonborn.esm','DLC2LCharBanditMissile'),
    # The six the extract left as a naive vanilla flatten - they are the "8 uncovered LVLN"
    # Requiem never overrode, so bucket C flattened all six rungs (1/5/9/14/19/25) and left
    # Plunderer and Marauder reachable in lists 3.1 caps at Highwayman. Same roster as the rest.
    @('037C28:Skyrim.esm',    'LCharBanditOnlyNordM'),
    @('037C29:Skyrim.esm',    'LCharBanditOnlyRedguardF'),
    @('037C2A:Skyrim.esm',    'LCharBanditOnlyOrcM'),
    @('008BF7:Dawnguard.esm', 'LCharBanditMeleeKhajiitM'),
    @('008BF8:Dawnguard.esm', 'LCharBanditMissileKhajiitM'),
    # Gates 1/9/14/19/24 - no gate 5, so the ladder yields Thug x4 · Highwayman x2.
    # Same T1-T3 band as its nine LCharBanditWizard* siblings above.
    @('0EE523:Skyrim.esm',    'LCharBanditWizardOmit01'))) {
    Add-Spec $d[0] $d[1] @{ Gates = $banditLadder }
}

# ---- Hostile Orc camps: Highwayman x3 · Plunderer x4 · Marauder x2 = gates 14/19/25 (user, 2026-09-24).
#      The ordinary bandit roster's 3:4:2 shape, two ranks up. NOT the Orc strongholds (3.1 called it
#      that; wrong): LCharOrcMelee is placed only outside Cracked Tusk Keep and Rift Watchtower. Its two
#      other users, the Largashbur defenders (DA06LvlOrcMelee) and the Old Orc (WE24Orc), are retargeted
#      to LCharBanditMeleeOrcM by author-retargets.ps1 so they keep the ordinary mix.
Add-Spec '01E780:Skyrim.esm' 'LCharOrcMelee' @{ Gates = @{ 14 = 3; 19 = 4; 25 = 2 } }

# 3.1 Forsworn (WD-43, user 2026-09-25): Forsworn 1 · Forager 6 · Looter 14 · Pillager 24 · Ravager 34
#     (Warlord 46 is in no rank-and-file list). Roster Forager x1 · Looter x3 · Pillager x4 · Ravager x1,
#     mean level 19.8, T2-T5 - four tiers, allowed per faction (WD-42). Forsworn gear is weak, so the
#     levels carry the threat. The plain level-1 "Forsworn" is dropped, as the level-1 bandit was.
#     Gate weights multiply every entry at that gate, so each list's M/F mix survives. Requiem had pinned
#     Missile to Pillager/Ravager and Shaman to Ravager; this puts them back on the common roster.
$forswornLadder = @{ 6 = 1; 14 = 3; 24 = 4; 34 = 1 }
foreach ($d in @(
    @('01E792:Skyrim.esm', 'LCharForswornMelee1H'),
    @('0442C8:Skyrim.esm', 'LCharForswornMeleeFemale'),
    @('01E794:Skyrim.esm', 'LCharForswornMissile'),
    @('0442C9:Skyrim.esm', 'LCharForswornMissileFemale'),
    @('01E795:Skyrim.esm', 'LCharForswornShaman'))) {
    Add-Spec $d[0] $d[1] @{ Gates = $forswornLadder }
}
# 3.1 Forsworn boss: every rung is "Forsworn Briarheart" (7/16/27/38/51), so the band is PINNED (WD-42).
#     Gate 46 = SubCharForsworn05Boss* = level 38, T6 (user, WD-43): the camp's capstone above ~T4 mooks.
#     Requiem pinned both lists to rung 06 (51) and pointed the shaman list at the MELEE sublist; the shaman
#     list gets its magic sublist back.
Add-Spec '0442F2:Skyrim.esm' 'LCharForswornBossMelee1H' @{ Gates = @{ 46 = 1 } }
Add-Spec '0442FD:Skyrim.esm' 'LCharForswornBossShaman'  @{ Gates = @{ 46 = 1 } }

# 3.1 Warlock, all five schools (WD-46, user 2026-09-26): Novice 1 · Apprentice 6 · Adept 12 · Mage 19 ·
#     Wizard/Ascendant 27 · Pyromancer/Master 36 · Arch 46. Roster Mage x2 · Wizard x3 · Master x1,
#     mean level 25.5, T4-T6: mages turn up in many kinds of place, so the band is wide (user, revised
#     2026-09-26 from 19x1 · 27x3 · 36x3 · 46x1). The Arch mook is out, so the boss (50) is the only Arch.
#     The Omit01 lists skip the Novice but share the gates, and the 22 race/voice lists (which have no
#     level-46 leaf anyway) roll the same roster. StormElfHaughtyF gates its level-19 rung at 18 (vanilla typo).
$warlockLadder = @{ 19 = 2; 27 = 3; 36 = 1 }
$warlockVoice  = $warlockLadder
foreach ($d in @(
    @('01E7D1:Skyrim.esm', 'LCharWarlockFire'),        @('0CAB99:Skyrim.esm', 'LCharWarlockFireOmit01'),
    @('01E7D2:Skyrim.esm', 'LCharWarlockIce'),         @('0CABA2:Skyrim.esm', 'LCharWarlockIceOmit01'),
    @('01E7D3:Skyrim.esm', 'LCharWarlockStorm'),       @('0D5C47:Skyrim.esm', 'LCharWarlockStormOmit01'),
    @('01E777:Skyrim.esm', 'LCharWarlockNecromancer'), @('0D5C49:Skyrim.esm', 'LCharWarlockNecroOmit01'),
    @('06D269:Skyrim.esm', 'LCharWarlockConjurer'),    @('0D5C48:Skyrim.esm', 'LCharWarlockConjurerOmit01'))) {
    Add-Spec $d[0] $d[1] @{ Gates = $warlockLadder }
}
foreach ($d in @(
    @('081ECF:Skyrim.esm', 'LCharWarlockConjurerCondescendingF'), @('081ED0:Skyrim.esm', 'LCharWarlockConjurerCondescendingM'),
    @('081ED1:Skyrim.esm', 'LCharWarlockConjurerDarkElfF'),       @('081ED2:Skyrim.esm', 'LCharWarlockConjurerDarkElfM'),
    @('081ED4:Skyrim.esm', 'LCharWarlockConjurerElfHaughtyF'),    @('081ED5:Skyrim.esm', 'LCharWarlockConjurerElfHaughtyM'),
    @('081ED8:Skyrim.esm', 'LCharWarlockFireCondescendingM'),     @('081ED9:Skyrim.esm', 'LCharWarlockFireDarkElfF'),
    @('081EDA:Skyrim.esm', 'LCharWarlockFireDarkElfM'),           @('081EDB:Skyrim.esm', 'LCharWarlockFireElfHaughtyF'),
    @('081EDC:Skyrim.esm', 'LCharWarlockFireElfHaughtyM'),        @('081EE9:Skyrim.esm', 'LCharWarlockIceCondescendingM'),
    @('081EEA:Skyrim.esm', 'LCharWarlockIceElfHaughtyF'),         @('081EEB:Skyrim.esm', 'LCharWarlockIceElfHaughtyM'),
    @('081EEC:Skyrim.esm', 'LCharWarlockIceNordF'),               @('081EED:Skyrim.esm', 'LCharWarlockIceNordM'),
    @('081EF0:Skyrim.esm', 'LCharWarlockNecroDarkElfF'),          @('081EF1:Skyrim.esm', 'LCharWarlockNecroDarkElfM'),
    @('081EF2:Skyrim.esm', 'LCharWarlockNecroElfHaughtyF'),       @('081EFB:Skyrim.esm', 'LCharWarlockStormCondescendingM'),
    @('081EFC:Skyrim.esm', 'LCharWarlockStormDarkElfF'),          @('081EFD:Skyrim.esm', 'LCharWarlockStormDarkElfM'),
    @('081EFF:Skyrim.esm', 'LCharWarlockStormElfHaughtyM'))) {
    Add-Spec $d[0] $d[1] @{ Gates = $warlockVoice }
}
Add-Spec '081EFE:Skyrim.esm' 'LCharWarlockStormElfHaughtyF' @{ Gates = @{ 18 = 2; 27 = 3; 36 = 1 } }
# 3.1 Warlock boss: the leaves are nameless and take no Traits, so the band is PINNED (WD-42). The rung is 50,
#     the Arch boss (user, WD-46): a rung and a name no mook has. Vanilla's boss lists stop at
#     rung 06 (40); the level-50 boss sublists LCharWarlock07Boss* exist but are unused (Requiem wired them
#     in), and there is no Necro one, so the Necro lists take its two leaves directly.
#     Voice lists keep their voice: where a level-50 leaf of that race and sex exists it is used; the four
#     that have none are pinned at gate 46 = rung 06 = level 40 instead (user decision).
Add-Spec '0E1018:Skyrim.esm' 'LCharWarlockBossFire'     @{ Pin = @('1091CC:Skyrim.esm') }   # LCharWarlock07BossFire
Add-Spec '0E1032:Skyrim.esm' 'LCharWarlockBossIce'      @{ Pin = @('1091CD:Skyrim.esm') }   # LCharWarlock07BossIce
Add-Spec '0E106A:Skyrim.esm' 'LCharWarlockBossStorm'    @{ Pin = @('1091CE:Skyrim.esm') }   # LCharWarlock07BossStorm
Add-Spec '0E0FFD:Skyrim.esm' 'LCharWarlockBossConjurer' @{ Pin = @('1091CB:Skyrim.esm') }   # LCharWarlock07BossConjurer
Add-Spec '0E104F:Skyrim.esm' 'LCharWarlockBossNecro'    @{ Pin = @('1091C3:Skyrim.esm', '1091C2:Skyrim.esm') }   # Necro07Boss BretonF, HighElfM
Add-Spec '0E2217:Skyrim.esm' 'LCharWarlockBossNecroFemaleCondescending' @{ Pin = @('1091C3:Skyrim.esm') }   # Necro07BossBretonF
Add-Spec '081EF3:Skyrim.esm' 'LCharWarlockNecroBossMaleElfHaughty'      @{ Pin = @('1091C2:Skyrim.esm') }   # Necro07BossHighElfM
Add-Spec '0E106C:Skyrim.esm' 'LCharWarlockBossStormMaleElfHaughy'       @{ Pin = @('1091C4:Skyrim.esm') }   # Storm07BossHighElfM
foreach ($d in @(
    @('0E106D:Skyrim.esm', 'LCharWarlockBossNecroMaleCondescending'),   # Breton M: no level-50 leaf
    @('081ED7:Skyrim.esm', 'LCharWarlockFireBossFemaleElfHaughty'),     # High Elf F: none
    @('081EE8:Skyrim.esm', 'LCharWarlockIceBossFemaleElfHaughty'),
    @('081EFA:Skyrim.esm', 'LCharWarlockStormBossFemaleElfHaughty'))) {
    Add-Spec $d[0] $d[1] @{ Gates = @{ 46 = 1 } }
}

# ---- bandit bosses (3.1)
foreach ($d in @(
    @('03DF16:Skyrim.esm',    'LCharBanditBoss'),
    @('01A32F:Skyrim.esm',    'LCharBanditBossCommonerF'),
    @('01A33A:Skyrim.esm',    'LCharBanditBossCommonerM'),
    @('01A33B:Skyrim.esm',    'LCharBanditBossEvenTonedF'),
    @('01A33F:Skyrim.esm',    'LCharBanditBossEvenTonedM'),
    @('01A340:Skyrim.esm',    'LCharBanditBossNordF'),
    @('01A341:Skyrim.esm',    'LCharBanditBossNordM'),
    @('0E1645:Skyrim.esm',    'LCharBanditBossNordM2HOnly'),
    @('01B0EA:Skyrim.esm',    'LCharBanditBossOrcM'),
    @('01E8B4:Dragonborn.esm','DLC2LCharBanditBoss'))) {
    Add-Spec $d[0] $d[1] @{ Gates = $banditBoss }
}

# ---- Vigilants of Stendarr, T2 (3.1: "5 - single gate"). The parent list is already flat; these two
#      sublists are not. Capping at T2 leaves exactly the level-5 rung, which is what 3.1 describes.
Add-Spec '10C45B:Skyrim.esm' 'SubCharVigilantOfStendarrEvenTonedF01'        @{ Cap = 8 }
Add-Spec '10C45C:Skyrim.esm' 'SubCharVigilantOfStendarrEvenTonedMAccented01' @{ Cap = 8 }

# ---- the biome ambient lists (4.1.2). Cap = the reference level of the biome's tier.
Add-Spec '042293:Skyrim.esm' 'LCharAnimalPlainsPredator'      @{ Cap =  8 }   # T2
Add-Spec '042297:Skyrim.esm' 'LCharAnimalForestPredator'      @{ Cap = 14 }   # T3
Add-Spec '04229B:Skyrim.esm' 'LCharAnimalCanyonPredator'      @{ Cap = 14 }   # T3
Add-Spec '042295:Skyrim.esm' 'LCharAnimalMarshPredator'       @{ Cap = 14 }   # T3
Add-Spec '01E78F:Skyrim.esm' 'LCharAnimalHills'               @{ Cap = 14 }   # T3
Add-Spec '0422A3:Skyrim.esm' 'LCharAnimalCoastSnowPredator'   @{ Cap = 14 }   # T3
Add-Spec '04229D:Skyrim.esm' 'LCharAnimalMountainSnowPredator' @{ Cap = 30 }  # T5 - the only band
                                                                              # holding TrollFrost
# The three unflagged ambient lists hold one entry per species, so a bare cap would give a flat
# 1:1:1 mix. 4.1.2 / 4.1.4 weight them; the cap still decides which species are in.
Add-Spec '01E790:Skyrim.esm' 'LCharAnimalForest'     @{ Gates = @{ 1 = 1; 6 = 2; 12 = 2 } }        # T3 Bear x2 SabreCat x2 Wolf x1
Add-Spec '01E78D:Skyrim.esm' 'LCharAnimalPlains'     @{ Gates = @{ 1 = 3; 6 = 1 } }                # T2 Wolf x3 SabreCat x1
Add-Spec '01E78E:Skyrim.esm' 'LCharAnimalSnowFields' @{ Gates = @{ 1 = 1; 6 = 3; 11 = 2; 20 = 1 } } # T4

# ---- species substitution (4). "Fixes which animals live where", never a level.
Add-Spec '0FE2D5:Skyrim.esm'   'LCharSabrecat' @{ Gates = @{ 1 = 3; 11 = 1 } }        # SabreCat x3 Snowy x1
Add-Spec '01FA27:Skyrim.esm'   'LCharChaurus'  @{ Gates = @{ 1 = 3; 20 = 1 } }        # Chaurus x3 Reaper x1;
                                                                                      # Dawnguard's Hunters are
                                                                                      # reserved (rule 4)
Add-Spec '02183E:Skyrim.esm'   'LCharMudcrab'  @{ Refs = @{     # one gate holds several sizes, so
    '0E4010:Skyrim.esm' = 3      # EncMudcrabMedium             # weight by reference, not by gate
    '0E4011:Skyrim.esm' = 2      # EncMudcrabLarge
    '021875:Skyrim.esm' = 1      # EncMudcrabGiant  (L=3 - a size, not a tier)
} }
Add-Spec '0640BE:Skyrim.esm'   'LCharVampireCompanionFrost' @{ Cap = 21 }             # tracks Vampire, T4
Add-Spec '0029A2:Dawnguard.esm' 'DLC1LCharChaurusHunter' @{ Gates = @{ 1 = 3; 32 = 1 } } # Fledgling x3 Hunter x1

# ---------------------------------------------------------------- run

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$vix = @{}
foreach ($d in $loadOrder) {
    $p = Join-Path $base "$d/LeveledNpcs"
    if (-not (Test-Path -LiteralPath $p)) { continue }
    foreach ($f in Get-ChildItem -LiteralPath $p -Filter '*.yaml') {
        if ($f.Name -match '- ([0-9A-F]+)_(.+)\.yaml$') { $vix["$($Matches[1]):$($Matches[2])"] = $f.FullName }
    }
}

$done = 0; $dropped = 0
foreach ($key in $spec.Keys) {
    $s = $spec[$key]
    $vpath = $vix[$key]
    if (-not $vpath) { throw "no vanilla LeveledNpcs record for $key ($($s.Id))" }
    $leaf = Split-Path $vpath -Leaf
    $out = Join-Path $dst $leaf

    if ($s.Rule.ContainsKey('Drop')) {
        if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
        $dropped++; continue
    }

    # Split the vanilla record into the lines around the entry run plus the '- Data:' blocks.
    # Some LVLN carry a Model: block AFTER Entries:, so the rebuilt entries must be spliced back
    # at their original position, not appended - appending produces invalid YAML.
    $lines = @(Get-Content -LiteralPath $vpath)
    $pre = New-Object System.Collections.ArrayList
    $post = New-Object System.Collections.ArrayList
    $blocks = New-Object System.Collections.ArrayList
    $cur = $null
    $doneEntries = $false
    foreach ($l in $lines) {
        if ($l -eq '- Data:' -and -not $doneEntries) {
            if ($cur) { [void]$blocks.Add($cur) }
            $cur = New-Object System.Collections.ArrayList; [void]$cur.Add($l); continue
        }
        if ($cur -ne $null) {
            if ($l -match '^\S') { [void]$blocks.Add($cur); $cur = $null; $doneEntries = $true }
            else { [void]$cur.Add($l); continue }
        }
        if ($doneEntries) { [void]$post.Add($l) } else { [void]$pre.Add($l) }
    }
    if ($cur) { [void]$blocks.Add($cur) }

    $kept = New-Object System.Collections.ArrayList
    $seenRef = @{}   # Refs mode: the weight is a TOTAL, and vanilla may list a reference more than once
    foreach ($b in $blocks) {
        $gate = -1; $ref = ''
        foreach ($l in $b) {
            if ($l -match '^    Level: (\d+)$')    { $gate = [int]$Matches[1] }
            if ($l -match '^    Reference: (\S+)$') { $ref = $Matches[1] }
        }
        $w = 0
        if     ($s.Rule.ContainsKey('Cap'))   { if ($gate -le $s.Rule.Cap) { $w = 1 } }
        elseif ($s.Rule.ContainsKey('Gates')) { if ($s.Rule.Gates.ContainsKey($gate)) { $w = $s.Rule.Gates[$gate] } }
        elseif ($s.Rule.ContainsKey('Refs'))  {
            if ($s.Rule.Refs.ContainsKey($ref) -and -not $seenRef.ContainsKey($ref)) {
                $w = $s.Rule.Refs[$ref]; $seenRef[$ref] = $true
            }
        }
        if ($w -le 0) { continue }
        # flatten the gate; repeat the entry w times to weight the pool
        $flat = @($b | ForEach-Object { if ($_ -match '^    Level: \d+$') { '    Level: 1' } else { $_ } })
        for ($i = 0; $i -lt $w; $i++) { foreach ($l in $flat) { [void]$kept.Add($l) } }
    }
    if ($s.Rule.ContainsKey('Pin')) {
        foreach ($r in $s.Rule.Pin) {
            foreach ($l in $blocks[0]) {
                if     ($l -match '^    Level: \d+$')    { [void]$kept.Add('    Level: 1') }
                elseif ($l -match '^    Reference: \S+$') { [void]$kept.Add("    Reference: $r") }
                else                                      { [void]$kept.Add($l) }
            }
        }
    }
    if ($kept.Count -eq 0) { throw "roster for $($s.Id) ($key) selected no entries - check the gates" }

    $final = New-Object System.Collections.ArrayList
    foreach ($l in $pre)  { [void]$final.Add($l) }
    foreach ($l in $kept) { [void]$final.Add($l) }
    foreach ($l in $post) { [void]$final.Add($l) }
    [System.IO.File]::WriteAllLines((Join-Path (Get-Location) $out), $final, $utf8NoBom)
    $done++
}

"bucket D: $done rosters authored, $dropped dropped as already-flat ($($spec.Count) specified)"
