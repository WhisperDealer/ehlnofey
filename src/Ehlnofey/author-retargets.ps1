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

    # ---- Guards and civil-war soldiers: fixed level 25 (WD-44/45, user 2026-09-26). Strong enough for bandits
    # and Forsworn; one level for every uniform. These are the records that OWN the level: every hold guard,
    # patrol, fort garrison, field commander and courier takes Stats from one of them. The EncGuardImperialM0x
    # leaves the extract grafted at 25 take Stats from their template, so their own level is inert.
    # Level = N swaps the PcLevelMult block for NpcLevel N (the bucket-E graft shape; CalcMin/Max stay, unused).
    @{ Npc = '0F6F37:Skyrim.esm';     Level = 25 }   # EncGuardImperialTemplate - Imperial-held hold guards, x1 [20-50]
    @{ Npc = '0F6F38:Skyrim.esm';     Level = 25 }   # EncGuardSonsTemplate     - Stormcloak-held hold guards, x1 [20-50]
    @{ Npc = '01FC5D:Skyrim.esm';     Level = 25 }   # EncSoldierImperialTemplate - BOTH factions' soldiers (Requiem 35)
    @{ Npc = '027498:Skyrim.esm';     Level = 25 }   # EncSoldierSonsTemplate   - takes Stats from 01FC5D; set to match
    # Siege soldiers, siege archers, Redoran and MQ104 guards: single fixed records, so no 25/30/35 spread - 30,
    # the spread's average (user, 2026-09-26). The siege soldier templates took Stats from 01FC5D/027498; they own it now.
    @{ Npc = '041B30:Skyrim.esm';     Level = 30; Own = $true }   # EncSiegeImperialSoldierTemplate
    @{ Npc = '045BE5:Skyrim.esm';     Level = 30; Own = $true }   # EncSiegeSonsSoldierTemplate
    @{ Npc = '045BE0:Skyrim.esm';     Level = 30 }   # EncSiegeImperialArcherTemplate (Requiem 35)
    @{ Npc = '045BE4:Skyrim.esm';     Level = 30 }   # EncSiegeSonsArcherTemplate     (Requiem 35)
    @{ Npc = '0195AF:Dragonborn.esm'; Level = 30 }   # DLC2RRGuardTemplate - Raven Rock's Redoran guards, x1 [20-50]
    @{ Npc = '0A27CC:Skyrim.esm';     Level = 30 }   # MQ104Soldier01 - Whiterun guards at the Western Watchtower, x0.5 [2-25]
    @{ Npc = '0A4A3B:Skyrim.esm';     Level = 30 }   # MQ104Soldier02
    @{ Npc = '101996:Skyrim.esm';     Level = 30 }   # MQ104Soldier03
    @{ Npc = '101997:Skyrim.esm';     Level = 30 }   # MQ104Soldier04

    # ---- Hold guards: a 25 / 30 / 35 spread (user, after play 2026-09-26: 25 lost to bandits). Every hold
    # guard record templates (Stats) through LvlGuardImperial/Sons onto one of these nine leaves per side,
    # rolled flat from LCharGuardImperial 0E7B2C / LCharGuardSons 0E7B2D. Own = drop Stats from the leaf's
    # TemplateFlags so it owns its level; its class, HealthOffset (+50) and auto-calc match the template's,
    # so only the level changes. Each voice-type sublist (0EA640/43/44/45/46) holds every rank.
    # Imperial: 25 x3 / 30 x3 / 35 x3.
    @{ Npc = '0AA8D4:Skyrim.esm'; Level = 25; Own = $true }   # EncGuardImperialM01MaleNordCommander
    @{ Npc = '0AA8D5:Skyrim.esm'; Level = 30; Own = $true }   # EncGuardImperialM02MaleNordCommander
    @{ Npc = '0AA8D6:Skyrim.esm'; Level = 35; Own = $true }   # EncGuardImperialM03MaleNordCommander
    @{ Npc = '0AA8D7:Skyrim.esm'; Level = 35; Own = $true }   # EncGuardImperialM04MaleNordCommander
    @{ Npc = '0AA8FC:Skyrim.esm'; Level = 25; Own = $true }   # EncGuardImperialM05MaleGuard
    @{ Npc = '0AA8FD:Skyrim.esm'; Level = 25; Own = $true }   # EncGuardImperialM06MaleGuard
    @{ Npc = '0AA901:Skyrim.esm'; Level = 30; Own = $true }   # EncGuardImperialM07MaleGuard
    @{ Npc = '0AA913:Skyrim.esm'; Level = 30; Own = $true }   # EncGuardImperialM08MaleGuard
    @{ Npc = '0AA8D8:Skyrim.esm'; Level = 35; Own = $true }   # EncGuardImperialM09MaleGuard
    # Stormcloak: one of each rank per voice type.
    @{ Npc = '0AA922:Skyrim.esm'; Level = 25; Own = $true }   # EncGuardSonsF01FemaleNord
    @{ Npc = '0AA924:Skyrim.esm'; Level = 30; Own = $true }   # EncGuardSonsF02FemaleNord
    @{ Npc = '0AA931:Skyrim.esm'; Level = 35; Own = $true }   # EncGuardSonsF03FemaleNord
    @{ Npc = '0AA932:Skyrim.esm'; Level = 25; Own = $true }   # EncGuardSonsM01MaleNordCommander
    @{ Npc = '0AA933:Skyrim.esm'; Level = 30; Own = $true }   # EncGuardSonsM02MaleNordCommander
    @{ Npc = '0AA935:Skyrim.esm'; Level = 35; Own = $true }   # EncGuardSonsM03MaleNordCommander
    @{ Npc = '0AA936:Skyrim.esm'; Level = 25; Own = $true }   # EncGuardSonsM04MaleGuard
    @{ Npc = '0AA942:Skyrim.esm'; Level = 30; Own = $true }   # EncGuardSonsM05MaleGuard
    @{ Npc = '0AA943:Skyrim.esm'; Level = 35; Own = $true }   # EncGuardSonsM06MaleGuard

    # ---- Civil-war soldiers: the same 25 / 30 / 35 spread (user, 2026-09-26). The leaves of LCharSoldierImperial
    # 01FC5B / LCharSoldierSons 01FC5C, which every patrol, fort garrison and battle soldier rolls from. The two
    # siege templates (041B30, 045BE5) and the siege archers keep a flat 25 from their templates.
    # Imperial: MaleSoldier voice 25/25/30/30/35, YoungEager voice 25/30/35/35.
    @{ Npc = '017145:Skyrim.esm'; Level = 25; Own = $true }   # EncSoldierImperialBretonM01MaleSoldier
    @{ Npc = '017140:Skyrim.esm'; Level = 25; Own = $true }   # EncSoldierImperialImperialM01MaleSoldier
    @{ Npc = '01713E:Skyrim.esm'; Level = 30; Own = $true }   # EncSoldierImperialNordM01MaleSoldier
    @{ Npc = '017143:Skyrim.esm'; Level = 30; Own = $true }   # EncSoldierImperialRedguardM01MaleSoldier
    @{ Npc = '01713F:Skyrim.esm'; Level = 35; Own = $true }   # EncSoldierImperialNordM02MaleSoldier
    @{ Npc = '017146:Skyrim.esm'; Level = 25; Own = $true }   # EncSoldierImperialBretonM02MaleYoungEager
    @{ Npc = '017142:Skyrim.esm'; Level = 30; Own = $true }   # EncSoldierImperialImperialM02MaleYoungEager
    @{ Npc = '017141:Skyrim.esm'; Level = 35; Own = $true }   # EncSoldierImperialNordM03MaleYoungEager
    @{ Npc = '017144:Skyrim.esm'; Level = 35; Own = $true }   # EncSoldierImperialRedguardM02MaleYoungEager
    # Stormcloak: FemaleNord 25/30/35, MaleNord 25/30/35 x2.
    @{ Npc = '017167:Skyrim.esm'; Level = 25; Own = $true }   # EncSoldierSonsNordF01FemaleNord
    @{ Npc = '017168:Skyrim.esm'; Level = 30; Own = $true }   # EncSoldierSonsNordF02FemaleNord
    @{ Npc = '017169:Skyrim.esm'; Level = 35; Own = $true }   # EncSoldierSonsNordF03FemaleNord
    @{ Npc = '01716A:Skyrim.esm'; Level = 25; Own = $true }   # EncSoldierSonsNordM01MaleNord
    @{ Npc = '01716B:Skyrim.esm'; Level = 30; Own = $true }   # EncSoldierSonsNordM02MaleNord
    @{ Npc = '01716C:Skyrim.esm'; Level = 35; Own = $true }   # EncSoldierSonsNordM03MaleNord
    @{ Npc = '0770AF:Skyrim.esm'; Level = 25; Own = $true }   # EncSoldierSonsNordM04MaleNord
    @{ Npc = '0770B0:Skyrim.esm'; Level = 30; Own = $true }   # EncSoldierSonsNordM05MaleNord
    @{ Npc = '0770B1:Skyrim.esm'; Level = 35; Own = $true }   # EncSoldierSonsNordM06MaleNord
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
    if ($e.Contains('Level')) {
        $i = [array]::IndexOf($lines, '    MutagenObjectType: PcLevelMult')
        if ($i -lt 1 -or $lines[$i - 1] -ne '  Level:' -or $lines[$i + 1] -notmatch '^    LevelMult: ') { throw "$($src.Name): no PcLevelMult level block" }
        $was = $lines[$i + 1].Trim()
        $lines[$i] = '    MutagenObjectType: NpcLevel'
        $lines[$i + 1] = "    Level: $($e.Level)"
        if ($e.Contains('Own')) {
            $tf = [array]::IndexOf($lines, '  TemplateFlags:')
            $s = [array]::IndexOf($lines, '  - Stats', $tf + 1)
            # every line between TemplateFlags: and '- Stats' must be another flag (PowerShell ranges run backwards, so guard s = tf+1)
            if ($tf -lt 0 -or $s -lt 0 -or ($s -gt $tf + 1 -and @($lines[($tf + 1)..($s - 1)] | Where-Object { $_ -notmatch '^  - ' }).Count -gt 0)) {
                throw "$($src.Name): no Stats in TemplateFlags"
            }
            $lines = @($lines[0..($s - 1)] + $lines[($s + 1)..($lines.Count - 1)])
            $was = "$was, Stats flag dropped"
        }
        [System.IO.File]::WriteAllLines((Join-Path $dst $src.Name), $lines, $utf8NoBom)
        "{0,-50} {1} -> Level: {2}" -f $src.Name, $was, $e.Level
        continue
    }
    $n = @($lines | Where-Object { $_ -eq $e.From }).Count
    if ($n -ne 1) { throw "$($src.Name): expected exactly one '$($e.From)', found $n" }
    $out = @($lines | ForEach-Object { if ($_ -eq $e.From) { $e.To } else { $_ } })
    [System.IO.File]::WriteAllLines((Join-Path $dst $src.Name), $out, $utf8NoBom)
    "{0,-50} {1} -> {2}" -f $src.Name, $e.From.Trim(), $e.To.Trim()
}
"retargets: $($edits.Count) NPC_ records"
