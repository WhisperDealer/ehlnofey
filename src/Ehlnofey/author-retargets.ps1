# Small NPC_ edits: retarget a record's Template (which list the spawn draws from) or fix a field.
#
# Each edit copies the WINNING vanilla record verbatim (last in load order, CLAUDE.md "last-wins") and
# changes only the lines it names (guardrail 3): From/To or Swap (whole-line swaps), Level (+ Own; can share a row with the line ops),
# DropItem (one Items entry), DropFlag (one TemplateFlag) and Insert (a new line after a unique one). One row per record - a second row would overwrite it. It replaces any earlier override of that record in the plugin,
# including a bucket-E level graft from extract-requiem.ps1, so the edit's From line is matched against
# vanilla. Any master works: Npc is a full FormKey.
#
# Overriding a vanilla NPC_ collapses its name to English (non-localized plugin; see CLAUDE.md).
# Run AFTER author-injectors.ps1.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$base = Join-Path $root 'reference\Base'
$cc   = Join-Path $root 'reference\mods\CreationClubYaml'
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

    # ---- Vampire thralls: level 25 (WD-47, user 2026-09-26, after play: they came out level 5). A thrall owns no
    # level: it templates (Stats, Traits) straight onto a BANDIT ladder, so it rolled our bandit mook rungs
    # (5/9/14). Those lists are shared with every bandit camp, so the thrall itself is repointed at the ladder's
    # gate-25 entry, the Marauder (level 25): the generic lists go to their SubCharBandit06* sublist, the voice
    # lists to their EncBandit06* leaf. That is exactly what vanilla spawned for a player of level 25+. Class,
    # health, skills, race and voice come with it. Owning the level instead (Stats dropped) is NOT safe here:
    # thralls carry the placeholder class EncClassDremoraMelee and no AutoCalcStats.
    # Every MELEE thrall is two-handed (user, after play): a vampire fights with spells or a blade and a spell, and
    # its thrall is there to close in, deal damage and soak it. So the 1H, MeleeAny, Tank (sword and shield) and
    # Melee2HGuard thralls all take SubCharBandit06Melee2H; the Redguard voice thralls take the Redguard 2H leaves
    # (same voice). There is no Imperial 2H Marauder, so the Commoner-voice (Imperial) thralls take the Nord 2H
    # leaf of the same sex. Missile and wizard thralls keep their role. Four records template onto other thralls and inherit
    # (the Redwater Den dealer and archer, WERJ07Thrall). The Castle Volkihar feast thralls and servant are
    # non-combat and left alone.
    @{ Npc = '014070:Dawnguard.esm'; From = 'Template: 01A323:Skyrim.esm'; To = 'Template: 03DE6D:Skyrim.esm' }   # DLC1LvlRedwaterThrallMeleeCommonerAcMAggro1024: LCharBanditMeleeEvenTonedM -> EncBandit06Melee2HRedguardM
    @{ Npc = '014071:Dawnguard.esm'; From = 'Template: 01A344:Skyrim.esm'; To = 'Template: 039D6F:Skyrim.esm' }   # DLC1LvlRedwaterThrallMissileEvenTonedFAggro1024: LCharBanditMissileEvenTonedF -> EncBandit06MissileWoodElfF
    @{ Npc = '0183A4:Dawnguard.esm'; From = 'Template: 01A323:Skyrim.esm'; To = 'Template: 03DE6D:Skyrim.esm' }   # DLC1LvlVampireThrallMeleeCommonerAcM: LCharBanditMeleeEvenTonedM -> EncBandit06Melee2HRedguardM
    @{ Npc = '02EB0B:Skyrim.esm'; From = 'Template: 039CFC:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMelee1H: LCharBanditMelee1H -> SubCharBandit06Melee2H
    @{ Npc = '02EC1B:Skyrim.esm'; From = 'Template: 039CFC:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMelee1HGuard: LCharBanditMelee1H -> SubCharBandit06Melee2H
    @{ Npc = '02ED6B:Skyrim.esm'; From = 'Template: 03DEC8:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMelee2H: LCharBanditMelee2H -> SubCharBandit06Melee2H
    @{ Npc = '02ED6E:Skyrim.esm'; From = 'Template: 03DECD:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMeleeAny: LCharBanditMeleeAny -> SubCharBandit06Melee2H
    @{ Npc = '02ED86:Skyrim.esm'; From = 'Template: 03DECD:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMeleeAnyGuard: LCharBanditMeleeAny -> SubCharBandit06Melee2H
    @{ Npc = '02EE9D:Skyrim.esm'; From = 'Template: 03DECD:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMeleeAnySitLinkedRef: LCharBanditMeleeAny -> SubCharBandit06Melee2H
    @{ Npc = '02EE9E:Skyrim.esm'; From = 'Template: 03DECA:Skyrim.esm'; To = 'Template: 03DEC7:Skyrim.esm' }   # LvlVampireThrallMeleeBerserker: LCharBanditMelee2HBerserk -> SubCharBandit06Melee2HBerserk
    @{ Npc = '02EED0:Skyrim.esm'; From = 'Template: 01A31E:Skyrim.esm'; To = 'Template: 03DE69:Skyrim.esm' }   # LvlVampireThrallMeleeCommonerF: LCharBanditMeleeCommonerF -> EncBandit06Melee2HNordF (no Imperial 2H)
    @{ Npc = '02EED1:Skyrim.esm'; From = 'Template: 01A319:Skyrim.esm'; To = 'Template: 03DE6A:Skyrim.esm' }   # LvlVampireThrallMeleeCommonerM: LCharBanditMeleeCommonerM -> EncBandit06Melee2HNordM (no Imperial 2H)
    @{ Npc = '02EED2:Skyrim.esm'; From = 'Template: 01A322:Skyrim.esm'; To = 'Template: 03DE6C:Skyrim.esm' }   # LvlVampireThrallMeleeEvenTonedF: LCharBanditMeleeEvenTonedF -> EncBandit06Melee2HRedguardF
    @{ Npc = '02EED3:Skyrim.esm'; From = 'Template: 01A323:Skyrim.esm'; To = 'Template: 03DE6D:Skyrim.esm' }   # LvlVampireThrallMeleeEvenTonedM: LCharBanditMeleeEvenTonedM -> EncBandit06Melee2HRedguardM
    @{ Npc = '02EED5:Skyrim.esm'; From = 'Template: 01A321:Skyrim.esm'; To = 'Template: 03DE69:Skyrim.esm' }   # LvlVampireThrallMeleeNordF: LCharBanditMeleeNordF -> EncBandit06Melee2HNordF
    @{ Npc = '02EED6:Skyrim.esm'; From = 'Template: 01A320:Skyrim.esm'; To = 'Template: 03DE6A:Skyrim.esm' }   # LvlVampireThrallMeleeNordM: LCharBanditMeleeNordM -> EncBandit06Melee2HNordM
    @{ Npc = '02EED7:Skyrim.esm'; From = 'Template: 03DEC9:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMeleeTank: LCharBanditMelee1HTank -> SubCharBandit06Melee2H
    @{ Npc = '02EED8:Skyrim.esm'; From = 'Template: 03DEC9:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMeleeTankGuard: LCharBanditMelee1HTank -> SubCharBandit06Melee2H
    @{ Npc = '02EEDC:Skyrim.esm'; From = 'Template: 01E770:Skyrim.esm'; To = 'Template: 039D76:Skyrim.esm' }   # LvlVampireThrallMissile: LCharBanditMissile -> SubCharBandit06Missile
    @{ Npc = '02EEDD:Skyrim.esm'; From = 'Template: 01A342:Skyrim.esm'; To = 'Template: 037C44:Skyrim.esm' }   # LvlVampireThrallMissileCommonerF: LCharBanditMissileCommonerF -> EncBandit06MissileImperialF
    @{ Npc = '02EEDE:Skyrim.esm'; From = 'Template: 01A343:Skyrim.esm'; To = 'Template: 037C45:Skyrim.esm' }   # LvlVampireThrallMissileCommonerM: LCharBanditMissileCommonerM -> EncBandit06MissileImperialM
    @{ Npc = '02EEDF:Skyrim.esm'; From = 'Template: 01A344:Skyrim.esm'; To = 'Template: 039D6F:Skyrim.esm' }   # LvlVampireThrallMissileEvenTonedF: LCharBanditMissileEvenTonedF -> EncBandit06MissileWoodElfF
    @{ Npc = '02EEE0:Skyrim.esm'; From = 'Template: 01A345:Skyrim.esm'; To = 'Template: 039D70:Skyrim.esm' }   # LvlVampireThrallMissileEvenTonedM: LCharBanditMissileEvenTonedM -> EncBandit06MissileWoodElfM
    @{ Npc = '02EEE1:Skyrim.esm'; From = 'Template: 01E770:Skyrim.esm'; To = 'Template: 039D76:Skyrim.esm' }   # LvlVampireThrallMissileGuard: LCharBanditMissile -> SubCharBandit06Missile
    @{ Npc = '02EEE5:Skyrim.esm'; From = 'Template: 01A346:Skyrim.esm'; To = 'Template: 037C46:Skyrim.esm' }   # LvlVampireThrallMissileNordF: LCharBanditMissileNordF -> EncBandit06MissileNordF
    @{ Npc = '02EEE6:Skyrim.esm'; From = 'Template: 01A348:Skyrim.esm'; To = 'Template: 037C47:Skyrim.esm' }   # LvlVampireThrallMissileNordM: LCharBanditMissileNordM -> EncBandit06MissileNordM
    @{ Npc = '02EEE7:Skyrim.esm'; From = 'Template: 01E771:Skyrim.esm'; To = 'Template: 039D64:Skyrim.esm' }   # LvlVampireThrallWizard: LCharBanditWizard -> SubCharBandit06Magic
    @{ Npc = '02EEE8:Skyrim.esm'; From = 'Template: 01B0F0:Skyrim.esm'; To = 'Template: 039D59:Skyrim.esm' }   # LvlVampireThrallWizardCommonerF: LCharBanditWizardCommonerF -> EncBandit06MagicBretonF
    @{ Npc = '02EEE9:Skyrim.esm'; From = 'Template: 01B0F3:Skyrim.esm'; To = 'Template: 039D5A:Skyrim.esm' }   # LvlVampireThrallWizardCommonerM: LCharBanditWizardCommonerM -> EncBandit06MagicBretonM
    @{ Npc = '02EEEA:Skyrim.esm'; From = 'Template: 01B0F4:Skyrim.esm'; To = 'Template: 039D5B:Skyrim.esm' }   # LvlVampireThrallWizardEvenTonedF: LCharBanditWizardEvenTonedF -> EncBandit06MagicDarkElfF
    @{ Npc = '02EEEB:Skyrim.esm'; From = 'Template: 01B0F5:Skyrim.esm'; To = 'Template: 039D5C:Skyrim.esm' }   # LvlVampireThrallWizardEvenTonedM: LCharBanditWizardEvenTonedM -> EncBandit06MagicDarkElfM
    @{ Npc = '02EEEC:Skyrim.esm'; From = 'Template: 01E771:Skyrim.esm'; To = 'Template: 039D64:Skyrim.esm' }   # LvlVampireThrallWizardGuard: LCharBanditWizard -> SubCharBandit06Magic
    @{ Npc = '02EEED:Skyrim.esm'; From = 'Template: 01B0F7:Skyrim.esm'; To = 'Template: 039D5D:Skyrim.esm' }   # LvlVampireThrallWizardNordF: LCharBanditWizardNordF -> EncBandit06MagicNordF
    @{ Npc = '02EEEE:Skyrim.esm'; From = 'Template: 01B0FB:Skyrim.esm'; To = 'Template: 039D5E:Skyrim.esm' }   # LvlVampireThrallWizardNordM: LCharBanditWizardNordM -> EncBandit06MagicNordM
    @{ Npc = '042267:Skyrim.esm'; From = 'Template: 01E771:Skyrim.esm'; To = 'Template: 039D64:Skyrim.esm' }   # LvlVampireThrallConjurer: LCharBanditWizard -> SubCharBandit06Magic
    @{ Npc = '08E2F7:Skyrim.esm'; From = 'Template: 01E770:Skyrim.esm'; To = 'Template: 039D76:Skyrim.esm' }   # LvlVampireThrallMissileHold: LCharBanditMissile -> SubCharBandit06Missile
    @{ Npc = '02ED6D:Skyrim.esm'; From = 'Template: 01E79C:Skyrim.esm'; To = 'Template: 03DEC5:Skyrim.esm' }   # LvlVampireThrallMelee2HGuard: LvlBanditMeleeAny -> SubCharBandit06Melee2H

    # ---- Thalmor (WD-48, user 2026-09-26). Levels are pinned in author-bucket-d.ps1 (soldiers 36, wizards 44, bosses 50).
    # Archers: LvlThalmorMissile does not inherit Inventory, and its own carried an iron dagger, the BANDIT bow list
    # (hunting/long/Imperial) and iron arrows. It is the archer at the Embassy (4 guards), Northwatch Keep (3) and the
    # Ratway (MQ202), who all inherit its inventory. It now carries the Thalmor bow (Elven bow + Elven arrows) and dagger.
    @{ Npc = '02B361:Skyrim.esm'; Swap = @(@('    Item: 01397E:Skyrim.esm', '    Item: 07D986:Skyrim.esm'),     # IronDagger -> LItemThalmorDagger
                                           @('    Item: 039D2E:Skyrim.esm', '    Item: 07D985:Skyrim.esm'));    # LItemBanditWeaponBow -> LItemThalmorWeaponBow
       DropItem = '039D2F:Skyrim.esm' }                                                                          # LItemBanditWeaponArrows (the bow sublist carries arrows)
    # Justiciars (WE32/33/34, WERoad03 - "Thalmor Justiciar"): Elven with a rare glass weapon and armor. Both own their
    # inventory. The helmeted one moves to the Justiciar-only no-helmet outfit, whose list now rolls both looks
    # (author-injectors.ps1). The shield stays LItemThalmorShield (Elven, shared with every sword-and-board soldier).
    @{ Npc = '10516F:Skyrim.esm'; Swap = @(@('    Item: 07D97D:Skyrim.esm', '    Item: 000800:Ehlnofey.esp'),   # LItemThalmorWeapon1H -> EHL_LVLI_ThalmorJusticiarWeapon1H
                                           @('DefaultOutfit: 02B0FB:Skyrim.esm', 'DefaultOutfit: 07D97E:Skyrim.esm')) }   # WithHelmet -> ThalmorArmorNoHelmetOutfit
    @{ Npc = '10516E:Skyrim.esm'; From = '    Item: 07D97D:Skyrim.esm'; To = '    Item: 000800:Ehlnofey.esp' }   # WEThalmorElvenArmorNoHelmet
    # Boss wizard (the pinned level-50 rung): owns its inventory - identical to what it inherited (robes, dagger,
    # wizard loot) - so its dagger can be its own: Elven, glass 1 in 10.
    @{ Npc = '07D98B:Skyrim.esm'; From = '    Item: 07D986:Skyrim.esm'; To = '    Item: 000801:Ehlnofey.esp'; DropFlag = 'Inventory' }   # EncThalmor06MagicBossM
    # Embassy reception guards (MQ201, Diplomatic Immunity) template straight onto a rung-03 leaf (level 20): moved to
    # the same sex's rung-05 leaf so they match every other Thalmor soldier (36).
    @{ Npc = '033F45:Skyrim.esm'; From = 'Template: 07D961:Skyrim.esm'; To = 'Template: 07D96C:Skyrim.esm' }   # MQ201PartyGuard:  EncThalmor03Melee1HF -> EncThalmor05Melee1HF
    @{ Npc = '03AF2F:Skyrim.esm'; From = 'Template: 07D962:Skyrim.esm'; To = 'Template: 07D96F:Skyrim.esm' }   # MQ201PartyGuard2: EncThalmor03Melee1HM -> EncThalmor05Melee1HM
    # The Creation Club Redguard pack's own Thalmor (user, 2026-09-26): three soldiers that own a fixed level 18
    # (no Stats flag). Raised to 36 like every other Thalmor soldier. Health, gear and spells are left alone
    # (AutoCalcStats, so health follows the level). The pack's other Thalmor already roll our pinned lists.
    @{ Npc = '000E41:ccedhsse003-redguard.esl'; From = '    Level: 18'; To = '    Level: 36' }   # ccEDHSSE003_EncThalmor02MissileM
    @{ Npc = '000E3F:ccedhsse003-redguard.esl'; From = '    Level: 18'; To = '    Level: 36' }   # ccEDHSSE003_EncThalmor03Melee1HF
    @{ Npc = '000E40:ccedhsse003-redguard.esl'; From = '    Level: 18'; To = '    Level: 36' }   # ccEDHSSE003_EncThalmor03Melee1HM

    # ---- Hagravens: 40 (WD-54, user 2026-09-26). Vanilla 20 sat below the Forsworn Briarhearts (38) they command.
    # Every generic hagraven, Moira, Drascua and the Glenmoril Witches take Stats from EncHagraven; the four named
    # hagravens that own their level are raised with it (one name, one level). Every other species keeps vanilla's level.
    @{ Npc = '023AB0:Skyrim.esm';     From = '    Level: 20'; To = '    Level: 40' }   # EncHagraven
    @{ Npc = '039B3E:Skyrim.esm';     From = '    Level: 20'; To = '    Level: 40' }   # dunBlindcliffHagraven (Melka)
    @{ Npc = '0369ED:Dragonborn.esm'; From = '    Level: 20'; To = '    Level: 40' }   # DLC2dunAltarOfThrondEttiene
    @{ Npc = '0369EE:Dragonborn.esm'; From = '    Level: 20'; To = '    Level: 40' }   # DLC2dunAltarOfThrondFallaise
    @{ Npc = '0369EC:Dragonborn.esm'; From = '    Level: 20'; To = '    Level: 40' }   # DLC2dunAltarOfThrondIsobel
    # Giants: 38, on a par with the mammoths they herd (user, 2026-09-26; vanilla 32). EncGiant02/03, Grok (DA14),
    # the Largashbur giant (DA06) and the Karthspire giant take Stats from EncGiant01. Still passive (lore-constraints 4.1).
    @{ Npc = '023AAE:Skyrim.esm';     From = '    Level: 32'; To = '    Level: 38' }   # EncGiant01
    # ---- Daedra (WD-52, user 2026-09-26).
    # Arch conjurer bosses (50) bind Dremora: a conjurer summons a Dremora by persuasion or by beating it into
    # submission, so only the rank that outclasses the level-46 Dremora Lord gets the spell. The boss leaves take
    # SpellList from this template, and it took its own from the arch MOOK template; it now owns its list (identical)
    # with Conjure Dremora Lord in place of the storm atronach. Master conjurers (36) keep storm atronachs.
    @{ Npc = '1091AD:Skyrim.esm'; From = '- 100E78:Skyrim.esm'; To = '- 10DDEC:Skyrim.esm'; DropFlag = 'SpellList' }   # EncWarlock07TemplateBossConjurer
    # Every Dremora carries enchanted Daedric (user; Requiem's pin on the melee and bow lists). The Dremora warlocks
    # carried the bandit weapon list; the two reachable ranks take the Dremora list too.
    @{ Npc = '016FF7:Skyrim.esm'; From = '    Item: 01E60A:Skyrim.esm'; To = '    Item: 017000:Skyrim.esm' }   # EncDremoraWarlock05: LItemBanditWeapon -> LItemEnchWeapon1HDremoraFire
    @{ Npc = '016FFA:Skyrim.esm'; From = '    Item: 01E60A:Skyrim.esm'; To = '    Item: 017000:Skyrim.esm' }   # EncDremoraWarlock06

    # ---- Witches and Hags (user, after play 2026-09-27): in line with the warlocks. The six EncWitch0N templates own
    # Stats and SpellList for every leaf of LCharWitch* (Darklight Tower, the hagraven nests). Vanilla fixed them at 4
    # (Witch) and 8 (Hag). Each takes a warlock rung's level and bonuses: Witch = Mage (19, +75 HP, +100 magicka), Hag =
    # Wizard (27, +100/+100). Spells stay their own (novice), as warlock gear was left alone. A To that is an array
    # inserts lines; Spriggit's field order is restored by the round-trip.
    foreach ($w in @('074F74', '074F75', '074F76')) {   # EncWitch01Template Fire / Ice / Storm - "Witch"
        @{ Npc = "${w}:Skyrim.esm"; Swap = @(@('    Level: 4', '    Level: 19'),
                                             @('  StaminaOffset: -25', @('  MagickaOffset: 100', '  StaminaOffset: -25')),
                                             @('  DispositionBase: 35', @('  DispositionBase: 35', '  HealthOffset: 75'))) }
    }
    foreach ($w in @('074F83', '074F84', '074F85')) {   # EncWitch02Template Fire / Ice / Storm - "Hag"
        @{ Npc = "${w}:Skyrim.esm"; Swap = @(@('    Level: 8', '    Level: 27'),
                                             @('  StaminaOffset: -25', @('  MagickaOffset: 100', '  StaminaOffset: -25')),
                                             @('  DispositionBase: 35', @('  DispositionBase: 35', '  HealthOffset: 100'))) }
    }
    # ---- Creation Club Bone Wolf pack (user, after play 2026-09-27): its hostile Bonewolf scaled x1 [5-30], its
    # quest Necromancer x1.2 [12-70] and his two Thrall Wolves x1 [5-60]. Bonewolves also spawn from the Update.esm undead
    # list (ccBGS_LCharUndeadListMaster) with the Zombies pack. Bonewolf and thralls 12, above wild wolves (5) and below
    # the necromancers they run with; the Necromancer 36, the Master Necromancer rung. The pet (fixed 2) is left alone.
    @{ Npc = '000865:ccbgssse036-petbwolf.esl'; Level = 12 }   # ccBGSSSE036_LvlBonewolf
    @{ Npc = '00080C:ccbgssse036-petbwolf.esl'; Level = 12 }   # ccBGSSSE036_EncNecromancerThrall01
    @{ Npc = '00080D:ccbgssse036-petbwolf.esl'; Level = 12 }   # ccBGSSSE036_EncNecromancerThrall02
    @{ Npc = '00080B:ccbgssse036-petbwolf.esl'; Level = 36 }   # ccBGSSSE036_Necromancer

    # Wolves: 5 (user, after play 2026-09-26: at 2 they died faster than mudcrabs). Red wolves, bandit wolves and the
    # spriggan's wolf take Stats from EncWolf; the two hostile placed wolves that own their level go with it. Ice wolves
    # (6), summoned wolves, the Hunter's spirit guardian and the corpse are left alone.
    @{ Npc = '023ABE:Skyrim.esm';     From = '    Level: 2';  To = '    Level: 5' }    # EncWolf
    @{ Npc = '0E1672:Skyrim.esm';     From = '    Level: 2';  To = '    Level: 5' }    # dunWhiteRiverWatchWolf
    @{ Npc = '0D1684:Skyrim.esm';     From = '    Level: 2';  To = '    Level: 5' }    # dunPOITrappedWolf

    # ---- Draugr (WD-49, user 2026-09-27): the Ebony Death Overlord (45) carries Ebony. LCharDraugrBossNoDragonPriest
    # spawns this template record directly, and it carries LItemDraugr05Weapon1H - Ebony in vanilla, enchanted ancient
    # Nord since Requiem. It now draws from the restored Ebony list instead. The EncDraugr05Boss*Ebony leaves that
    # template on it own their inventory (no Inventory flag), so nothing else changes.
    @{ Npc = '04247F:Skyrim.esm'; From = '    Item: 023C10:Skyrim.esm'; To = '    Item: 02432D:Skyrim.esm' }   # EncDraugr05TemplateBossEbony
    # Rank-and-file draugr +15 (user, 2026-09-27): Restless 21 · Wight 28 · Scourge 36. These nine templates own the level of
    # every leaf in the three ranks (Template2H takes Stats from Template; Missile and Magic own theirs). AutoCalcStats is set
    # on all nine, so health and skills follow the level; perks and spells do not. Hand-placed ambush variants follow too,
    # as do the Castle Volkihar / Labyrinthian / Rannveig skeletons, which take Stats from the draugr lists.
    @{ Npc = '03B548:Skyrim.esm'; From = '    Level: 6';  To = '    Level: 21' }   # EncDraugr02Template        Restless
    @{ Npc = '03BE20:Skyrim.esm'; From = '    Level: 6';  To = '    Level: 21' }   # EncDraugr02TemplateMissile
    @{ Npc = '038A25:Skyrim.esm'; From = '    Level: 6';  To = '    Level: 21' }   # EncDraugr02TemplateMagic
    @{ Npc = '03B549:Skyrim.esm'; From = '    Level: 13'; To = '    Level: 28' }   # EncDraugr03Template        Wight
    @{ Npc = '03BE21:Skyrim.esm'; From = '    Level: 13'; To = '    Level: 28' }   # EncDraugr03TemplateMissile
    @{ Npc = '038A26:Skyrim.esm'; From = '    Level: 13'; To = '    Level: 28' }   # EncDraugr03TemplateMagic
    @{ Npc = '03B54A:Skyrim.esm'; From = '    Level: 21'; To = '    Level: 36' }   # EncDraugr04Template        Scourge
    @{ Npc = '03BE22:Skyrim.esm'; From = '    Level: 21'; To = '    Level: 36' }   # EncDraugr04TemplateMissile
    @{ Npc = '038A27:Skyrim.esm'; From = '    Level: 21'; To = '    Level: 36' }   # EncDraugr04TemplateMagic
    # The generic boss is a Death Overlord at 45 (user): the plain one is raised from 34 to match the Ebony one, so the two
    # differ only in gear. Its EncDraugr05Boss1H/2H leaves take Stats from it.
    @{ Npc = '04247E:Skyrim.esm'; From = '    Level: 34'; To = '    Level: 45' }   # EncDraugr05TemplateBoss

    # ---- Falmer shamans take their rung's level (WD-50, user 2026-09-27): the caster is as strong as the fighter beside
    # it. The shaman leaves own their level (Dawnguard's winning records carry no Stats flag) and AutoCalcStats is set.
    # DLC1_BF_FrozenFalmerShamanTemplate templates on 05 for spells and model only, not Stats.
    @{ Npc = '025D2E:Skyrim.esm'; From = '    Level: 14'; To = '    Level: 22' }   # EncFalmer03Shaman (Gloomlurker rung)
    @{ Npc = '025D30:Skyrim.esm'; From = '    Level: 19'; To = '    Level: 30' }   # EncFalmer04Shaman (Nightprowler rung)
    @{ Npc = '025D32:Skyrim.esm'; From = '    Level: 25'; To = '    Level: 38' }   # EncFalmer05Shaman (Shadowmaster rung)

    # ---- Dwemer automatons (WD-51, user 2026-09-27): "Guardians on every one, average 40-50, they should be deadly".
    # Every automaton list rolls only its Guardian rung, raised in size order. The Guardians own their level and carry
    # AutoCalcStats, so health follows. Rungs 01/03 template on them without Stats and keep their own level.
    @{ Npc = '10EC87:Skyrim.esm';    From = '    Level: 16'; To = '    Level: 40' }   # EncDwarvenSpider03, "Dwarven Spider Guardian"
    @{ Npc = '023A97:Skyrim.esm';    From = '    Level: 24'; To = '    Level: 45' }   # EncDwarvenSphere02, "Dwarven Sphere Guardian"
    @{ Npc = '033251:Dragonborn.esm'; From = '    Level: 28'; To = '    Level: 45' }  # DLC2EncDwarvenBallista02, "Dwarven Ballista Guardian"
    @{ Npc = '10E753:Skyrim.esm';    From = '    Level: 30'; To = '    Level: 50' }   # EncDwarvenCenturion02, "Dwarven Centurion Guardian"
    # The Aetherial Staff's summoned sphere takes Stats from the Sphere Guardian; its own copy is the vanilla 24 with
    # AutoCalcStats and the sphere class, so it keeps 24 and the player's summon is not raised.
    @{ Npc = '00CFBA:Dawnguard.esm'; DropFlag = 'Stats' }   # DLC1LD_EncDwarvenSphereSummon02
    # The Forgemaster (Aetherium Forge boss) was x1 [36-60]; the extract grafted Requiem's 120. Pinned to 60 (user).
    @{ Npc = '015C48:Dawnguard.esm'; Level = 60 }   # DLC1LD_Forgemaster03

    # ---- Dragons (WD-53, user 2026-09-27): "endgame content, level 50 minimum; keep the types". Each type's template owns
    # the level of every variant (fire/frost, NoScript, the Solstheim _MQ06 copies, Vulthuryol, Sahrotaar, Krosulhah,
    # Naaslaarum, Voslaarum, Mirmulnir, the Skuldafn and MQ206/MQ306 dragons), which take Stats from it. All carry
    # AutoCalcStats, so health follows the level on top of each type's HealthOffset. Order and names are vanilla's.
    @{ Npc = '01CA03:Skyrim.esm';     From = '    Level: 10'; To = '    Level: 50' }   # EncDragon01Fire, "Dragon"
    @{ Npc = '0F80FD:Skyrim.esm';     From = '    Level: 20'; To = '    Level: 55' }   # EncDragon02Fire, "Blood Dragon"
    @{ Npc = '0351C3:Skyrim.esm';     From = '    Level: 30'; To = '    Level: 60' }   # EncDragon03Frost, "Frost Dragon"
    @{ Npc = '0F811B:Skyrim.esm';     From = '    Level: 40'; To = '    Level: 65' }   # EncDragon04Fire, "Elder Dragon"
    @{ Npc = '0F811A:Skyrim.esm';     From = '    Level: 40'; To = '    Level: 65' }   # EncDragon04Frost
    @{ Npc = '0F811C:Skyrim.esm';     From = '    Level: 50'; To = '    Level: 70' }   # EncDragon05Fire, "Ancient Dragon"
    @{ Npc = '0F811E:Skyrim.esm';     From = '    Level: 50'; To = '    Level: 70' }   # EncDragon05Frost
    @{ Npc = '03612E:Dragonborn.esm'; From = '    Level: 58'; To = '    Level: 72' }   # DLC2EncDragon06Fire, "Serpentine Dragon"
    @{ Npc = '036134:Dragonborn.esm'; From = '    Level: 58'; To = '    Level: 72' }   # DLC2EncDragon06FireNoScript
    @{ Npc = '02C88A:Dragonborn.esm'; From = '    Level: 58'; To = '    Level: 72' }   # DLC2EncDragon06Frost
    @{ Npc = '036133:Dragonborn.esm'; From = '    Level: 58'; To = '    Level: 72' }   # DLC2EncDragon06FrostNoScript
    @{ Npc = '008431:Dawnguard.esm';  From = '    Level: 62'; To = '    Level: 75' }   # DLC1EncDragon06Fire, "Revered Dragon"
    @{ Npc = '00C5F5:Dawnguard.esm';  From = '    Level: 75'; To = '    Level: 80' }   # DLC1EncDragon07Fire, "Legendary Dragon"
    # Fixed-level dragons that own their stats WITHOUT AutoCalcStats (a flat 721 health), so a level alone would not make
    # them any stronger: they get the flag and follow the Dragon rung.
    @{ Npc = '09192C:Skyrim.esm';     From = '    Level: 20'; To = '    Level: 50'; Insert = @(,@('  Flags:', '  - AutoCalcStats')) }   # dunLabyrinthianUndeadDragon, "Skeletal Dragon"
    @{ Npc = '02BF3B:Dragonborn.esm'; From = '    Level: 20'; To = '    Level: 50'; Insert = @(,@('  Flags:', '  - AutoCalcStats')) }   # DLC2DragonSkeleton
    @{ Npc = '096E48:Skyrim.esm';     From = '    Level: 20'; To = '    Level: 50'; Insert = @(,@('  Flags:', '  - AutoCalcStats')) }   # dunSkuldafnDragonDraugr
    @{ Npc = '0354CA:Skyrim.esm';     From = '    Level: 20'; To = '    Level: 50'; Insert = @(,@('  Flags:', '  - AutoCalcStats')) }   # BleakFallsDragon
    # Paarthurnax 90 (user: Alduin's right hand, "very high"). He took Stats from the Dragon rung; his own copy already has
    # AutoCalcStats and the dragon class. HealthOffset 300 -> 2000, an Ancient's.
    @{ Npc = '03C57C:Skyrim.esm'; Swap = @(@('    Level: 10', '    Level: 90'), @('  HealthOffset: 300', '  HealthOffset: 2000'));
       DropFlag = 'Stats' }   # Paarthurnax
    # Odahviing 85 (user). He took Stats from lvlMQDragon (Elder/Ancient). His own copy has no AutoCalcStats, a level of 1
    # and the placeholder class EncClassDremoraMelee (the thrall trap), so it gets the flag, the dragon class and an
    # Ancient's HealthOffset. MQ303Odahviing (the trapped one in Dragonsreach) takes Stats from him.
    @{ Npc = '045920:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 85'), @('Class: 017008:Skyrim.esm', 'Class: 02F201:Skyrim.esm'));
       Insert = @(@('  - Invulnerable', '  - AutoCalcStats'), @('  - AttackData', '  HealthOffset: 2000')); DropFlag = 'Stats' }   # Odahviing

    # ---- Silver Hand (WD-55, user 2026-09-27: werewolf hunters, "a bit more capable than your average bandit"). They own
    # no level: every LvlSilverhand* took Stats and Traits from a bandit list (Outlaw/Thug/Highwayman, mean 8.8). They now
    # point at three Silver Hand-only lists built from the same bandit rungs, Highwayman x1 / Plunderer x3 / Marauder x1
    # (14/19/25, mean 19.2; author-bucket-d.ps1). The ambush and MeleeAny records lose their race/voice list and draw from
    # the one-handed list. LvlSilverhandBoss (Krev and two others) stays on the bandit chief, 28.
    @{ Npc = '02AB87:Skyrim.esm'; From = 'Template: 03DECB:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverhandMelee1H           <- LvlBanditMelee1H
    @{ Npc = '06466C:Skyrim.esm'; From = 'Template: 03DECB:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverhandMelee1HAggro1024  <- LvlBanditMelee1H
    @{ Npc = '04499F:Skyrim.esm'; From = 'Template: 01E79C:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverHandMeleeAny          <- LvlBanditMeleeAny
    @{ Npc = '108BBC:Skyrim.esm'; From = 'Template: 01AFBD:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverHandAmbush1 (Dustman's) <- LvlBanditMeleeEvenTonedF
    @{ Npc = '108BBE:Skyrim.esm'; From = 'Template: 01B0BC:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverHandAmbush2           <- LvlBanditMeleeNordM
    @{ Npc = '108BBD:Skyrim.esm'; From = 'Template: 01B0EF:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverHandAmbush3           <- LvlBanditMeleeOrcM
    @{ Npc = '108BBB:Skyrim.esm'; From = 'Template: 01AF77:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverHandAmbush4           <- LvlBanditMeleeCommonerM
    @{ Npc = '108BBF:Skyrim.esm'; From = 'Template: 01AF77:Skyrim.esm'; To = 'Template: 000802:Ehlnofey.esp' }   # LvlSilverHandAmbush5           <- LvlBanditMeleeCommonerM
    @{ Npc = '02AB89:Skyrim.esm'; From = 'Template: 01E79D:Skyrim.esm'; To = 'Template: 000803:Ehlnofey.esp' }   # LvlSilverhandMelee2H           <- LvlBanditMelee2H
    @{ Npc = '02AB88:Skyrim.esm'; From = 'Template: 01E770:Skyrim.esm'; To = 'Template: 000804:Ehlnofey.esp' }   # LvlSilverhandMissile (and its 3 copies) <- LCharBanditMissile
    # Werebears 30 (user). The three placed Snowclad Ruins werebears own 17. The DLC2WE07 encounter trio took Stats from
    # bandit berserker leaves (14 / 5 / 9); they own it now, keeping their bandit-melee class and AutoCalcStats. 03D21F had no
    # Level line at all (level 0 by default), so it gains one. DLC2EncWerebear owns Torkild's level and the Beast Stone
    # summon's (25 -> 30).
    @{ Npc = '01E17C:Dragonborn.esm'; From = '    Level: 17'; To = '    Level: 30' }   # DLC2EncTribalWerebearA
    @{ Npc = '03D2D9:Dragonborn.esm'; From = '    Level: 17'; To = '    Level: 30' }   # DLC2EncTribalWerebearB
    @{ Npc = '03D2DA:Dragonborn.esm'; From = '    Level: 17'; To = '    Level: 30' }   # DLC2EncTribalWerebearC
    @{ Npc = '03D21F:Dragonborn.esm'; Swap = @(,@('    MutagenObjectType: NpcLevel', @('    MutagenObjectType: NpcLevel', '    Level: 30'))); DropFlag = 'Stats' }   # DLC2WE07EncTribalWerebearA
    @{ Npc = '03D220:Dragonborn.esm'; From = '    Level: 5'; To = '    Level: 30'; DropFlag = 'Stats' }   # DLC2WE07EncTribalWerebearB
    @{ Npc = '03D221:Dragonborn.esm'; From = '    Level: 9'; To = '    Level: 30'; DropFlag = 'Stats' }   # DLC2WE07EncTribalWerebearC
    @{ Npc = '0322B1:Dragonborn.esm'; From = '    Level: 25'; To = '    Level: 30' }   # DLC2EncWerebear

    # ---- Penitus Oculatus 36, level with the Thalmor soldiers (WD-56, user). Every rung is "Penitus Oculatus Agent", so both
    # lists stay pinned to rung 06 and the rung is raised (vanilla 23; Requiem had 45, deleted by WD-42).
    @{ Npc = '07D995:Skyrim.esm'; From = '    Level: 23'; To = '    Level: 36' }   # EncPenitus06Fire
    @{ Npc = '07D99E:Skyrim.esm'; From = '    Level: 23'; To = '    Level: 36' }   # EncPenitus06Shock
    # The Katariah archers (5 placements) sit on LvlPenitusOculatusMissileAmbush, which templates on the Penitus chain but
    # omits Stats: a vanilla bug that left them level 1, 50 HP, no AutoCalcStats. With the flag they follow the pin.
    @{ Npc = '04C16C:Skyrim.esm'; Insert = @(,@('  - Traits', '  - Stats')) }   # LvlPenitusOculatusMissileAmbush
    # Vigilants of Stendarr 35 (user). One name, five rungs (5/9/14/19/25): every list is pinned to rung 05 in bucket D and
    # its seven leaves, which own their level, are raised 25 -> 35.
    foreach ($v in @('10C48A', '10C484', '10C485', '10C486', '10C487', '10C488', '10C489')) {   # EncVigilantOfStendarr05 DarkElfF, NordF, NordM01-04, RedguardF
        @{ Npc = "${v}:Skyrim.esm"; From = '    Level: 25'; To = '    Level: 35' }
    }
    @{ Npc = '0BFB55:Skyrim.esm';   Level = 45 }   # VigilantCarcette, Keeper of the Hall (bucket-E graft 56)
    @{ Npc = '00352D:Dawnguard.esm'; Level = 35 }   # DLC1VigilantTolan (x1 [15-30]; his corpse takes Stats from him)
    # Alik'r: the quest Alik'r keep their 30/35 grafts. The WERJ03 random encounter takes Stats from MS08AlikrWarrior, a
    # level-1 record with no AutoCalcStats, so it met the player as a level-1 "Alik'r Warrior". Now 30 with AutoCalcStats.
    @{ Npc = '020071:Skyrim.esm'; From = '    Level: 1'; To = '    Level: 30'; Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats')) }   # MS08AlikrWarrior

    # ---- World encounters and assassins (WD-57, user 2026-09-27). All PcLevelMult in vanilla; each row is the record that
    # owns the level. Requiem's grafts on some of them are replaced.
    @{ Npc = '073FBE:Skyrim.esm';     Level = 10 }   # EncHunter00Template: hunters, also farmers, fishermen, pilgrims, trappers (Requiem 20)
    @{ Npc = '039A7C:Dragonborn.esm'; Level = 20 }   # DLC2WE15Hunter, the Solstheim netch hunters (x0.75 [30-50])
    # Adventurers: all 25. Battlemage/Berserker/Brawler/MageShieldStaff/WEAdventurerTemplate carry Requiem's 25 already;
    # the DualPoisoner had 30 and four were never grafted (x1.1 from 6, uncapped).
    @{ Npc = '105549:Skyrim.esm'; Level = 25 }   # WEAdventurerDualPoisoner
    @{ Npc = '10554B:Skyrim.esm'; Level = 25; From = '    Item: 068839:Skyrim.esm'; To = '    Item: 039D2F:Skyrim.esm' }   # WEAdventurerRangedConjurer; LItemArrowsAll (CC magic arrows) -> bandit arrows
    @{ Npc = '105540:Skyrim.esm'; Level = 25 }   # WEAdventurerSpellsword
    @{ Npc = '105541:Skyrim.esm'; Level = 25 }   # WEAdventurerWarrior
    @{ Npc = '105545:Skyrim.esm'; Level = 25 }   # WEAdventurerWarriorDual
    @{ Npc = '103510:Skyrim.esm'; Level = 19 }   # WEThiefTemplate (Requiem 25)
    @{ Npc = '1051FB:Skyrim.esm'; Level = 25 }   # WEAssassinTemplate: the "marked for death" DB assassin, from player level 5 (Requiem 45)
    @{ Npc = '015CFA:Skyrim.esm'; Level = 25 }   # DBInitiate1 (Requiem 35)
    @{ Npc = '015CFE:Skyrim.esm'; Level = 25 }   # DBInitiate2
    @{ Npc = '0B91B0:Skyrim.esm'; Level = 14 }   # WEDL05Thug (x1.15, uncapped)
    @{ Npc = '0BA1E5:Skyrim.esm'; Level = 6 }    # WEDL07Madwoman
    @{ Npc = '0BBDA0:Skyrim.esm'; Level = 12 }   # WEDL08DeepInHisCups (x0.9 [12-12])
    foreach ($v in @('015D02', '015D0E', '037A28', '037A2C')) { @{ Npc = "${v}:Skyrim.esm"; Level = 1 } }   # DBTortureVictim1-4, captives
    # Morag Tong 30 (user). They took Stats from the Solstheim bandit lists (5/9/14). Now they own it: level 30, AutoCalcStats,
    # and a real class in place of the placeholder EncClassDremoraMelee (the thrall trap). Traits still come from the list.
    @{ Npc = '0271C3:Dragonborn.esm'; Swap = @(@('    Level: 1', '    Level: 30'), @('Class: 017008:Skyrim.esm', 'Class: 01317F:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats')); DropFlag = 'Stats' }   # DLC2LvlMoragTongMelee1H, CombatAssassin
    @{ Npc = '0271C4:Dragonborn.esm'; Swap = @(@('    Level: 1', '    Level: 30'), @('Class: 017008:Skyrim.esm', 'Class: 01317D:Skyrim.esm'),
                                               @('    Item: 068839:Skyrim.esm', '    Item: 039D2F:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats')); DropFlag = 'Stats' }   # DLC2LvlMoragTongMissile, CombatScout; bandit arrows

    # ---- Dawnguard DLC (WD-58, user 2026-09-27).
    # The Dawnguard: one name ("Dawnguard"), pinned to rung 06 in bucket D and raised 25 -> 38, just above the Vigilants.
    # DLC1EncHunterTemplate owns Agmaer, Beleval and the Fort's guards (Requiem graft 50); they go to the same 38.
    @{ Npc = '014224:Dawnguard.esm'; From = '    Level: 25'; To = '    Level: 38' }   # EncDawnguard06TemplateMelee
    @{ Npc = '00336F:Dawnguard.esm'; Level = 38 }   # DLC1EncHunterTemplate
    # Armored trolls: Armored Troll 26 / Armored Frost Troll 36, 1:1 (mean 31, user). The frost one took Stats from
    # EncTrollFrost, shared by every frost troll, so it owns its level now. The tamed trolls take Stats from these two.
    @{ Npc = '00D0B8:Dawnguard.esm'; From = '    Level: 14'; To = '    Level: 26' }   # DLC1EncTrollArmored
    @{ Npc = '00D0B9:Dawnguard.esm'; From = '    Level: 22'; To = '    Level: 36'; DropFlag = 'Stats' }   # DLC1EncTrollFrostArmored
    # Soul Cairn: Keepers 50, the Reaper 65 (user; Requiem grafts 80 / 100).
    @{ Npc = '0074F8:Dawnguard.esm'; Level = 50 }   # DLC01SoulCairnKeeper2H
    @{ Npc = '0074F9:Dawnguard.esm'; Level = 50 }   # DLC01SoulCairnKeeperBowArrow
    @{ Npc = '007B0F:Dawnguard.esm'; Level = 50 }   # DLC01SoulCairnKeeperShield
    @{ Npc = '01A73E:Dawnguard.esm'; Level = 65 }   # DLC01SoulCairnReaper
    @{ Npc = '00BF5E:Dawnguard.esm'; From = '    Item: 068839:Skyrim.esm'; To = '    Item: 039D2F:Skyrim.esm' }   # DLC1LvlSoulCairnBonemanMissileAmbush: LItemArrowsAll -> bandit arrows

    # ---- Dragonborn DLC (WD-59, user 2026-09-27).
    @{ Npc = '01A568:Dragonborn.esm'; Level = 30 }   # DLC2RR01AttackingAshSpawn: the Raven Rock attack, on the pinned Ash Spawn rung
    @{ Npc = '024DF8:Dragonborn.esm'; Level = 30 }   # DLC2RRFavor03AshSpawn
    @{ Npc = '01A373:Dragonborn.esm'; Level = 55 }   # DLC2dunHaknir: the committed extract grafted 200
    @{ Npc = '01CAD6:Dragonborn.esm'; From = '    Level: 32'; To = '    Level: 38' }   # DLC2FrostGiant01, on a par with the mainland giants

    # ---- Followers (WD-61, user 2026-09-27): fixed levels by role, set against the finished factions (Requiem left them scaling).
    # Gear is untouched: every outfit and inventory list they draw from is already flat.
    # Housecarls 35: hold-appointed, at the top guard rung (guards 25/30/35). Vanilla x1 [10-50] (Lydia [6-50]).
    @{ Npc = '0A2C8E:Skyrim.esm'; Level = 35 }   # HousecarlWhiterun (Lydia)
    @{ Npc = '0A2C8C:Skyrim.esm'; Level = 35 }   # HousecarlMarkarth (Argis)
    @{ Npc = '0A2C91:Skyrim.esm'; Level = 35 }   # HousecarlRiften (Iona)
    @{ Npc = '0A2C8F:Skyrim.esm'; Level = 35 }   # HousecarlSolitude (Jordis)
    @{ Npc = '0A2C90:Skyrim.esm'; Level = 35 }   # HousecarlWindhelm (Calder)
    @{ Npc = '005215:HearthFires.esm'; Level = 35 }   # BYOHHousecarlFalkreath (Rayya)
    @{ Npc = '00521B:HearthFires.esm'; Level = 35 }   # BYOHHousecarlHjaalmarch (Valdimar)
    @{ Npc = '00521E:HearthFires.esm'; Level = 35 }   # BYOHHousecarlPale (Gregor)
    # Hirelings 25: level with the WE adventurers. Vanilla x1 [10-40].
    @{ Npc = '0B9981:Skyrim.esm'; Level = 25 }   # HirelingBelrand
    @{ Npc = '065657:Skyrim.esm'; Level = 25 }   # HirelingErikTheSlayer
    @{ Npc = '0B9982:Skyrim.esm'; Level = 25 }   # HirelingJenassa
    @{ Npc = '0B9980:Skyrim.esm'; Level = 25 }   # HirelingMarcurio
    @{ Npc = '0B9983:Skyrim.esm'; Level = 25 }   # HirelingStenvar
    @{ Npc = '0B997F:Skyrim.esm'; Level = 25 }   # HirelingVorstag
    # Standard followers 20: villagers and drifters, above the bandit mooks, below a hireling. Vanilla x1 [6|10-30] (Sven x0.75 [6-20]).
    # The followers Requiem already fixed keep their grafts (Uthgerd, Kharjo, Ugor, Onmund, Brelyna, Eola, Aranea 30; Mjoll 40; Roggi 20).
    @{ Npc = '013480:Skyrim.esm'; Level = 20 }   # Faendal
    @{ Npc = '01347F:Skyrim.esm'; Level = 20 }   # Sven
    @{ Npc = '019FE8:Skyrim.esm'; Level = 20 }   # Golldir
    @{ Npc = '013666:Skyrim.esm'; Level = 20 }   # Annekke
    @{ Npc = '0135E8:Skyrim.esm'; Level = 20 }   # Benor
    @{ Npc = '013390:Skyrim.esm'; Level = 20 }   # Cosnach
    @{ Npc = '019959:Skyrim.esm'; Level = 20 }   # Borgakh
    @{ Npc = '013B81:Skyrim.esm'; Level = 20 }   # Ghorbash
    @{ Npc = '019E1E:Skyrim.esm'; Level = 20 }   # Lob
    @{ Npc = '019E22:Skyrim.esm'; Level = 20 }   # Ogol
    @{ Npc = '01C195:Skyrim.esm'; Level = 20 }   # Jzargo
    @{ Npc = '01403E:Skyrim.esm'; Level = 20 }   # Derkeethus
    @{ Npc = '01325F:Skyrim.esm'; Level = 20 }   # Ahtar
    @{ Npc = '048C2F:Skyrim.esm'; Level = 20 }   # dunDarklightIllia
    # Companions: whelps 30, the Circle 45 (level with Erandur and Teldryn). Vanilla x1 [5-25] / [8-50].
    @{ Npc = '01A6D5:Skyrim.esm'; Level = 30 }   # Athis
    @{ Npc = '01A6D9:Skyrim.esm'; Level = 30 }   # NjadaStonearm
    @{ Npc = '01A6D7:Skyrim.esm'; Level = 30 }   # Ria
    @{ Npc = '01A6DB:Skyrim.esm'; Level = 30 }   # Torvar
    @{ Npc = '01A696:Skyrim.esm'; Level = 45 }   # AelaTheHuntress
    @{ Npc = '01A692:Skyrim.esm'; Level = 45 }   # Farkas
    @{ Npc = '01A694:Skyrim.esm'; Level = 45 }   # Vilkas
    # Dawnguard followers 38, the Dawnguard pin (Agmaer and Beleval already take it from DLC1EncHunterTemplate). Celann, Durak and
    # Ingjard were x1 [10-uncapped]; Florentius x1 [10-30]. Serana keeps the extract's 50: above every Volkihar mook, below Harkon.
    @{ Npc = '01541E:Dawnguard.esm'; Level = 38 }   # DLC1Celann
    @{ Npc = '01541D:Dawnguard.esm'; Level = 38 }   # DLC1Durak
    @{ Npc = '01541B:Dawnguard.esm'; Level = 38 }   # DLC1Ingjard
    @{ Npc = '00336D:Dawnguard.esm'; Level = 38 }   # DLC1FlorentiusBaenius

    # ---- Named bosses and the long tail (WD-62, user 2026-09-27).
    # Named bosses that rode a faction list sit at the TOP rung of their type, on Ehlnofey's scale. They carried the
    # placeholder class EncClassDremoraMelee and no AutoCalcStats, so each takes the Morag Tong pattern: its own level, the
    # reference rung's class and offsets, AutoCalcStats, and Stats dropped. Traits, spells, AI and gear still come from the list.
    # Draugr: the Deathlord (vanilla 30, +15 = 45, level with the Death Overlord boss pin). Red Eagle and Curalmil already roll 45.
    @{ Npc = '01BB28:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 45'), @('Class: 017008:Skyrim.esm', 'Class: 023C0E:Skyrim.esm'));
       Insert = @(@('  - IsGhost', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 660'), @('  HealthOffset: 660', '  MagickaOffset: 60'), @('  MagickaOffset: 60', '  StaminaOffset: 350')); DropFlag = 'Stats' }   # JyrikGauldurson: draugr magic, Deathlord offsets (a ghost: his Flags block already holds IsGhost)
    @{ Npc = '0A6842:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 45'), @('Class: 017008:Skyrim.esm', 'Class: 023C0D:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 660'), @('  HealthOffset: 660', '  MagickaOffset: 10'), @('  MagickaOffset: 10', '  StaminaOffset: 350')); DropFlag = 'Stats' }   # dunGeirmundSigdis: draugr missile, EncDraugr05TemplateMissile
    @{ Npc = '1019C6:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 45'), @('Class: 017008:Skyrim.esm', 'Class: 023C0C:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 660'), @('  HealthOffset: 660', '  MagickaOffset: 10'), @('  MagickaOffset: 10', '  StaminaOffset: 350')); DropFlag = 'Stats' }   # DunVolunruudBoss (Kvenel the Tongue): draugr melee, EncDraugr05Template
    # Bandit leaders on a mook list (5/9/14): the bandit chief, EncBandit06Boss2H (28, +150 health).
    @{ Npc = '01E38B:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 28'), @('Class: 017008:Skyrim.esm', 'Class: 01CE17:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 150'), @('  HealthOffset: 150', '  MagickaOffset: -25'), @('  MagickaOffset: -25', '  StaminaOffset: 100')); DropFlag = 'Stats' }   # dunBrokenOarHargar (Captain Hargar)
    @{ Npc = '01C902:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 28'), @('Class: 017008:Skyrim.esm', 'Class: 01CE17:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 150'), @('  HealthOffset: 150', '  MagickaOffset: -25'), @('  MagickaOffset: -25', '  StaminaOffset: 100')); DropFlag = 'Stats' }   # DunLostKnifeBanditBoss
    @{ Npc = '0D823E:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 28'), @('Class: 017008:Skyrim.esm', 'Class: 01CE17:Skyrim.esm'));
       Insert = @(@('  - Respawn', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 150'), @('  HealthOffset: 150', '  MagickaOffset: -25'), @('  MagickaOffset: -25', '  StaminaOffset: 100')); DropFlag = 'Stats' }   # dunCragslaneButcher (Update.esm's copy already has Flags: Respawn)
    # Necromancer bosses: the Arch Necromancer boss, EncWarlock07TemplateBossNecro (50).
    @{ Npc = '0A33EA:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 50'), @('Class: 017008:Skyrim.esm', 'Class: 01CE14:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 200'), @('  HealthOffset: 200', '  MagickaOffset: 200'), @('  MagickaOffset: 200', '  StaminaOffset: 0')); DropFlag = 'Stats' }   # dunSouthfringeBoss: was on the necromancer mook list (19/27/36)
    @{ Npc = '019FE6:Skyrim.esm'; Swap = @(@('    Level: 1', '    Level: 50'), @('Class: 017008:Skyrim.esm', 'Class: 01CE14:Skyrim.esm'));
       Insert = @(@('Configuration:', '  Flags:'), @('  Flags:', '  - AutoCalcStats'), @('  - AutoCalcStats', '  HealthOffset: 200'), @('  HealthOffset: 200', '  MagickaOffset: 200'), @('  MagickaOffset: 200', '  StaminaOffset: 0')); DropFlag = 'Stats' }   # ValsVeran: his voice list had no level-50 leaf (40)
    # Questline finals realigned (user): Mercer, Astrid, Potema 50 · Harkon 55/60 · Ancano, Vyrthur 60 · Miraak 65 · Alduin 100.
    @{ Npc = '01E7D7:Skyrim.esm';    Level = 60 }   # Ancano (Requiem graft 80)
    @{ Npc = '003788:Dawnguard.esm'; Level = 60 }   # DLC1AlthadanVyrthur (Requiem graft 75)
    # Villains and leaders still scaling, set against their type.
    @{ Npc = '10349B:Skyrim.esm'; Level = 50 }   # Potema's Remains = Queen Potema (x1[7-50])
    @{ Npc = '02333A:Skyrim.esm'; Level = 50 }   # Lu'ah Al-Skaven: the warlock boss pin (x1[8-50])
    @{ Npc = '0284F2:Skyrim.esm'; Level = 50 }   # Ritual Master (Wolf Queen Awakened): the warlock boss pin (x1[10-20])
    @{ Npc = '039F1F:Skyrim.esm'; Level = 44 }   # Rulindil: Thalmor wizard (x1[8-40])
    @{ Npc = '034D97:Skyrim.esm'; Level = 44 }   # Estormo: Thalmor wizard (x1[10-50])
    @{ Npc = '003373:Dawnguard.esm'; Level = 53 }   # Volkihar court (Orthjolf, Vingalmo, Malkus, Hestla, Rargal, Feran): Volkihar Master Vampire (x1[0-0])
    @{ Npc = '003372:Dawnguard.esm'; Level = 53 }   # Volkihar court, magic (x1[0-0])
    @{ Npc = '003374:Dawnguard.esm'; Level = 53 }   # Volkihar court, missile (x1[0-0])
    @{ Npc = '003B8B:Dawnguard.esm'; Level = 60 }   # Valerica (x1[10-50])
    @{ Npc = '003368:Dawnguard.esm'; Level = 53 }   # Stalf: Volkihar Master Vampire (x1[0-0])
    @{ Npc = '003369:Dawnguard.esm'; Level = 53 }   # Salonia Caelia: Volkihar Master Vampire (x1[10-0])
    @{ Npc = '011E5E:Dawnguard.esm'; Level = 53 }   # Modhna: Volkihar Master Vampire (x1[0-0])
    @{ Npc = '011E5D:Dawnguard.esm'; Level = 53 }   # Namasur: Volkihar Master Vampire (x1[0-0])
    @{ Npc = '0D0575:Skyrim.esm'; Level = 45 }   # Ulfric Stormcloak (x1.2[10-50])
    @{ Npc = '0D0577:Skyrim.esm'; Level = 45 }   # General Tullius (x1.2[10-50])
    @{ Npc = '0D0570:Skyrim.esm'; Level = 40 }   # Galmar Stone-Fist (x1[10-30])
    @{ Npc = '0D0573:Skyrim.esm'; Level = 40 }   # Legate Rikke (x1[10-30])
    @{ Npc = '01C9F7:Skyrim.esm'; Level = 36 }   # Captain Metilius (x0.8[10-30])
    @{ Npc = '058303:Skyrim.esm'; Level = 42 }   # Kodlak's wolf spirit: the werewolf boss (Vargr) (x1[8-0])
    @{ Npc = '090739:Skyrim.esm'; Level = 28 }   # Mistwatch "Bandit Leader": the bandit chief (x1.1[5-0])
    # The dunCG Imperial soldiers (x1 [5-12]) are soldiers: the fixed-soldier pin.
    @{ Npc = '0F3E77:Skyrim.esm'; Level = 30 }   # dunCGImperialMageC01
    @{ Npc = '0F3E76:Skyrim.esm'; Level = 30 }   # dunCGImperialMageD01
    @{ Npc = '0E491B:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherA01
    @{ Npc = '0E4920:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherA02
    @{ Npc = '0F94AE:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherA03
    @{ Npc = '105EE2:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherA04
    @{ Npc = '0E6D5C:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherC01
    @{ Npc = '0F3E6F:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherC02
    @{ Npc = '0E72BB:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherD01
    @{ Npc = '0F3E6D:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherD02
    @{ Npc = '0F3E6E:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherD03
    @{ Npc = '0F94A9:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierArcherD04
    @{ Npc = '0E77F9:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierFodderC01
    @{ Npc = '0E77FD:Skyrim.esm'; Level = 30 }   # dunCGImperialSoldierFodderD01
    # Everyone else still scaling (non-combatants, quest extras, allies, pets): the level vanilla gives a level-25 player,
    # 25 x the multiplier, clamped to the record's own CalcMin/CalcMax (user). Titus Mede and Kyr own a fixed 1 and are left.
    @{ Npc = '01411D:Skyrim.esm'; Level = 23 }   # Adelaisa x0.9[6-25]
    @{ Npc = '01402E:Skyrim.esm'; Level = 13 }   # Aicantar x0.5[5-50]
    @{ Npc = '0135E6:Skyrim.esm'; Level = 15 }   # Alva x1[5-15]
    @{ Npc = '01334A:Skyrim.esm'; Level = 20 }   # Aringoth x1[8-20]
    @{ Npc = '0622E5:Skyrim.esm'; Level = 25 }   # Atar x1.25[10-25]
    @{ Npc = '018DE0:HearthFires.esm'; Level = 10 }   # BYOHHouse1Bard x0.75[5-10]
    @{ Npc = '019630:HearthFires.esm'; Level = 10 }   # BYOHHouse2Bard x0.75[5-10]
    @{ Npc = '019631:HearthFires.esm'; Level = 10 }   # BYOHHouse3Bard x0.75[5-10]
    @{ Npc = '01338A:Skyrim.esm'; Level = 25 }   # Borkul x1[10-50]
    @{ Npc = '013389:Skyrim.esm'; Level = 25 }   # Braig x1[6-30]
    @{ Npc = '01A6B7:Skyrim.esm'; Level = 25 }   # BrinaMerilis x1[10-25]
    @{ Npc = '0CE085:Skyrim.esm'; Level = 19 }   # DA05Hunter09_03Missile_Viding x0.75[0-0]
    @{ Npc = '089986:Skyrim.esm'; Level = 30 }   # DA13PeryiteMonk x1.2[10-40]
    @{ Npc = '01CB2E:Skyrim.esm'; Level = 22 }   # DA14Cultist x1[12-22]
    @{ Npc = '004D0C:Dawnguard.esm'; Level = 19 }   # DLC1LD_Katria x0.75[10-50]
    @{ Npc = '004D7D:Dawnguard.esm'; Level = 25 }   # DLC1LD_KatriaCorpse x1[10-50]
    @{ Npc = '002B44:Dawnguard.esm'; Level = 25 }   # DLC1Prelate00 x1[0-0]
    @{ Npc = '00A8AC:Dawnguard.esm'; Level = 25 }   # DLC1Prelate01 x1[0-0]
    @{ Npc = '00A8AD:Dawnguard.esm'; Level = 25 }   # DLC1Prelate02 x1[0-0]
    @{ Npc = '00A8AE:Dawnguard.esm'; Level = 25 }   # DLC1Prelate03 x1[0-0]
    @{ Npc = '00A8B0:Dawnguard.esm'; Level = 25 }   # DLC1Prelate04 x1[0-0]
    @{ Npc = '01A5C6:Dawnguard.esm'; Level = 14 }   # DLC1VQ01GiantSpider x1.2[5-14]
    @{ Npc = '008D7A:Dawnguard.esm'; Level = 25 }   # DLC1dunRedwaterDenAddict4 x1[0-0]
    @{ Npc = '01A511:Dragonborn.esm'; Level = 25 }   # DLC2Bujold x1[10-60]
    @{ Npc = '01A51A:Dragonborn.esm'; Level = 25 }   # DLC2Elmus x1[10-60]
    @{ Npc = '02749A:Dragonborn.esm'; Level = 25 }   # DLC2ExpSpiderOilFriend x1[0-0]
    @{ Npc = '027482:Dragonborn.esm'; Level = 30 }   # DLC2ExpSpiderPackmuleCUT x1.2[0-0]
    @{ Npc = '01A51C:Dragonborn.esm'; Level = 25 }   # DLC2Halbarn x1[10-60]
    @{ Npc = '01A515:Dragonborn.esm'; Level = 25 }   # DLC2Hilund x1[10-60]
    @{ Npc = '01A518:Dragonborn.esm'; Level = 25 }   # DLC2Kuvar x1[10-60]
    @{ Npc = '031862:Dragonborn.esm'; Level = 25 }   # DLC2MerchMerchant x1[0-0]
    @{ Npc = '01CAA8:Dragonborn.esm'; Level = 25 }   # DLC2MerilarRendas x1[0-0]
    @{ Npc = '02AD30:Dragonborn.esm'; Level = 25 }   # DLC2RREsmondTyne x1[25-50]
    @{ Npc = '01828E:Dragonborn.esm'; Level = 25 }   # DLC2RRGloverMallory x1[20-40]
    @{ Npc = '013268:Skyrim.esm'; Level = 25 }   # Deeja x1[10-30]
    @{ Npc = '0D673A:Skyrim.esm'; Level = 6 }   # Donnel x1[1-6]
    @{ Npc = '095F7E:Skyrim.esm'; Level = 13 }   # Drahff x0.5[6-25]
    @{ Npc = '0D6711:Skyrim.esm'; Level = 25 }   # Dryston x1[5-25]
    @{ Npc = '013393:Skyrim.esm'; Level = 13 }   # Duach x0.5[1-30]
    @{ Npc = '0936D1:Skyrim.esm'; Level = 25 }   # E3demoGiant01 x1[10-0]
    @{ Npc = '0936D3:Skyrim.esm'; Level = 25 }   # E3demoGiant02 x1[10-0]
    @{ Npc = '013B9E:Skyrim.esm'; Level = 25 }   # Elrindir x1[5-25]
    @{ Npc = '013B6C:Skyrim.esm'; Level = 13 }   # Enmon x0.5[6-15]
    @{ Npc = '0350A7:Skyrim.esm'; Level = 20 }   # Erik x1[5-20]
    @{ Npc = '01335A:Skyrim.esm'; Level = 7 }   # FromDeepestFathoms x1[4-7]
    @{ Npc = '056553:Skyrim.esm'; Level = 7 }   # FromDeepestFathomsVision x1[4-7]
    @{ Npc = '0D6703:Skyrim.esm'; Level = 25 }   # Garvey x1[10-30]
    @{ Npc = '01E765:Skyrim.esm'; Level = 25 }   # Hamal x1[6-25]
    @{ Npc = '095FD5:Skyrim.esm'; Level = 19 }   # Hewnon x0.75[8-30]
    @{ Npc = '035533:Skyrim.esm'; Level = 15 }   # Hilde x0.9[5-15]
    @{ Npc = '01A6B9:Skyrim.esm'; Level = 25 }   # HorikHalfhand x1[10-25]
    @{ Npc = '0133A0:Skyrim.esm'; Level = 25 }   # Ildene x1[5-25]
    @{ Npc = '013618:Skyrim.esm'; Level = 25 }   # Jod x1[10-25]
    @{ Npc = '013291:Skyrim.esm'; Level = 19 }   # KharagGroShurkul x0.75[6-25]
    @{ Npc = '094000:Skyrim.esm'; Level = 13 }   # Knjakr x0.5[5-15]
    @{ Npc = '013368:Skyrim.esm'; Level = 25 }   # LouisLetrush x1[4-30]
    @{ Npc = '0F737C:Skyrim.esm'; Level = 19 }   # MG07LabyrinthianThrall01 x0.75[0-0]
    @{ Npc = '0F7385:Skyrim.esm'; Level = 19 }   # MG07LabyrinthianThrall02 x0.75[0-0]
    @{ Npc = '099F2F:Skyrim.esm'; Level = 28 }   # MGRDremoraSummon x1.1[10-0]
    @{ Npc = '05AE91:Skyrim.esm'; Level = 25 }   # MGRejoinWizard x1[0-0]
    @{ Npc = '09B0AD:Skyrim.esm'; Level = 20 }   # MQ101CorpseSons01 x1.5[3-20]
    @{ Npc = '0B1693:Skyrim.esm'; Level = 20 }   # MQ101CorpseSonsPrisoner01 x1.5[3-20]
    @{ Npc = '0B79BC:Skyrim.esm'; Level = 20 }   # MQ101CorpseSonsPrisoner02 x1.5[3-20]
    @{ Npc = '046EFC:Skyrim.esm'; Level = 20 }   # MQ301ImperialSoldier x1.5[3-20]
    @{ Npc = '046EFD:Skyrim.esm'; Level = 20 }   # MQ301SonsSoldier x1.5[3-20]
    @{ Npc = '091AF2:Skyrim.esm'; Level = 20 }   # MQ304LostSoulImperial x1.5[3-20]
    @{ Npc = '0173C1:Skyrim.esm'; Level = 20 }   # MQ304LostSoulImperial2 x1.5[3-20]
    @{ Npc = '090A47:Skyrim.esm'; Level = 20 }   # MQ304LostSoulSons x1.5[3-20]
    @{ Npc = '0173C0:Skyrim.esm'; Level = 20 }   # MQ304LostSoulSons2 x1.5[3-20]
    @{ Npc = '0173C2:Skyrim.esm'; Level = 20 }   # MQ304LostSoulSons3 x1.5[3-20]
    @{ Npc = '0EA57A:Skyrim.esm'; Level = 10 }   # MQ304Svaknir x1[5-10]
    @{ Npc = '016C87:Skyrim.esm'; Level = 19 }   # MS05_dunDeadMensRespite_Svaknir x0.75[0-0]
    @{ Npc = '036194:Skyrim.esm'; Level = 13 }   # Malborn x0.5[5-15]
    @{ Npc = '0D6719:Skyrim.esm'; Level = 6 }   # Morven x1[1-6]
    @{ Npc = '0133AA:Skyrim.esm'; Level = 25 }   # Nepos x1[5-25]
    @{ Npc = '014123:Skyrim.esm'; Level = 13 }   # Niranye x0.5[10-50]
    @{ Npc = '0133AD:Skyrim.esm'; Level = 25 }   # Ogmund x1[10-25]
    @{ Npc = '034CBA:Skyrim.esm'; Level = 25 }   # ParatusDecimius x1[10-30]
    @{ Npc = '0132A3:Skyrim.esm'; Level = 25 }   # SabineNytte x1[10-50]
    @{ Npc = '013267:Skyrim.esm'; Level = 35 }   # Safia x2[15-35]
    @{ Npc = '0AF524:Skyrim.esm'; Level = 25 }   # SailorDorian x0.1[25-0]
    @{ Npc = '0AF522:Skyrim.esm'; Level = 25 }   # SailorEris x1[10-25]
    @{ Npc = '0AF523:Skyrim.esm'; Level = 25 }   # SailorXander x1[10-25]
    @{ Npc = '094012:Skyrim.esm'; Level = 20 }   # Salvianus x0.8[8-25]
    @{ Npc = '06C868:Skyrim.esm'; Level = 15 }   # Shavari x1[5-15]
    @{ Npc = '029D96:Skyrim.esm'; Level = 20 }   # Sifnar x0.8[10-30]
    @{ Npc = '01C605:Skyrim.esm'; Level = 15 }   # T03Maurice x0.8[6-15]
    @{ Npc = '01C241:Skyrim.esm'; Level = 19 }   # ThoraldGrayMane x0.75[4-50]
    @{ Npc = '0341FF:Skyrim.esm'; Level = 31 }   # Thorek_Ambush x1.25[10-0]
    @{ Npc = '0D6718:Skyrim.esm'; Level = 6 }   # Tynan x1[1-6]
    @{ Npc = '0133BC:Skyrim.esm'; Level = 25 }   # Uaile x1[5-25]
    @{ Npc = '0133BD:Skyrim.esm'; Level = 25 }   # Uraccen x1[6-30]
    @{ Npc = '0133BE:Skyrim.esm'; Level = 30 }   # UrzogaGraShugurz x1.2[20-50]
    @{ Npc = '0E16CD:Skyrim.esm'; Level = 25 }   # Vaermina x1[0-0]
    @{ Npc = '072B04:Skyrim.esm'; Level = 30 }   # Vald x1.2[8-42]
    @{ Npc = '0411BA:Skyrim.esm'; Level = 25 }   # Valdr x1[8-25]
    @{ Npc = '0341FE:Skyrim.esm'; Level = 31 }   # VerenDuleri_Ambush x1.25[10-0]
    @{ Npc = '013381:Skyrim.esm'; Level = 25 }   # Vulwulf x1[10-30]
    @{ Npc = '109487:Skyrim.esm'; Level = 25 }   # WEFollowerDog x1[10-25]
    @{ Npc = '03B0E3:Skyrim.esm'; Level = 25 }   # dunAlftandUmana x1[10-30]
    @{ Npc = '04F4DA:Skyrim.esm'; Level = 25 }   # dunDarklightDeadWitch x1[0-0]
    @{ Npc = '04CEDF:Skyrim.esm'; Level = 19 }   # dunFolgunthurDaynas x0.75[0-25]
    @{ Npc = '0CD640:Skyrim.esm'; Level = 25 }   # dunForelhostLvlGhostWizardMale x1[6-35]
    @{ Npc = '06CD5B:Skyrim.esm'; Level = 30 }   # dunIronbindBeemJa x1.2[5-30]
    @{ Npc = '06CD5A:Skyrim.esm'; Level = 25 }   # dunIronbindSalma x1[3-26]
    @{ Npc = '09CB62:Skyrim.esm'; Level = 25 }   # dunKilkreathGhostImperialMelee x1[0-100]
    @{ Npc = '0E77DA:Skyrim.esm'; Level = 25 }   # dunKilkreathGhostImperialMissile x1[0-100]
    @{ Npc = '09CB63:Skyrim.esm'; Level = 25 }   # dunKilkreathGhostSonsMelee x1[0-100]
    @{ Npc = '0E77DB:Skyrim.esm'; Level = 25 }   # dunKilkreathGhostSonsMissile x1[0-100]
    @{ Npc = '0D95E9:Skyrim.esm'; Level = 25 }   # dunPOITundraMarshDog x1[10-25]
    @{ Npc = '10A062:Skyrim.esm'; Level = 20 }   # dunRatwayGian x0.8[0-30]
)

foreach ($e in $edits) {
    $id, $master = $e.Npc -split ':'
    $src = $null
    foreach ($m in $loadOrder) {
        $hit = @(Get-ChildItem -LiteralPath (Join-Path $base "$m\Npcs") -Filter "* - ${id}_$master.yaml" -ErrorAction SilentlyContinue)
        if ($hit.Count -eq 1) { $src = $hit[0] }
    }
    if ($src -eq $null) {
        # A record defined by a Creation Club plugin: copy it from that plugin's decompile (it must be a master).
        $ccDir = Join-Path $cc ([System.IO.Path]::GetFileNameWithoutExtension($master))
        $hit = @(Get-ChildItem -LiteralPath (Join-Path $ccDir 'Npcs') -Filter "* - ${id}_$master.yaml" -ErrorAction SilentlyContinue)
        if ($hit.Count -eq 1) { $src = $hit[0] }
    }
    if ($src -eq $null) { throw "no NPC_ $($e.Npc) in reference/Base or the CC decompiles" }
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
        $lvDid = "$was -> Level: $($e.Level)"
        # Level can share a row with the line ops below (WD-57: a level and an Items swap on one record).
        if (-not ($e.Contains('From') -or $e.Contains('Swap') -or $e.Contains('DropItem') -or $e.Contains('DropFlag') -or $e.Contains('Insert'))) {
            [System.IO.File]::WriteAllLines((Join-Path $dst $src.Name), $lines, $utf8NoBom)
            "{0,-50} {1}" -f $src.Name, $lvDid
            continue
        }
    }
    # Line swaps: From/To for one, Swap = @(@(from, to), ...) for several.
    $swaps = @()
    if ($e.Contains('From')) { $swaps += ,@($e.From, $e.To) }
    if ($e.Contains('Swap')) { $swaps += $e.Swap }
    $did = @()
    if ($e.Contains('Level')) { $did += $lvDid }
    foreach ($sw in $swaps) {
        $n = @($lines | Where-Object { $_ -eq $sw[0] }).Count
        if ($n -ne 1) { throw "$($src.Name): expected exactly one '$($sw[0])', found $n" }
        $lines = @($lines | ForEach-Object { if ($_ -eq $sw[0]) { $sw[1] } else { $_ } })
        $did += "$($sw[0].Trim()) -> $($sw[1].Trim())"
    }
    # DropItem = '<FormKey>': remove that '- Item:' block (the '- Item:' line plus its indented lines) from Items:.
    if ($e.Contains('DropItem')) {
        $at = [array]::IndexOf($lines, "    Item: $($e.DropItem)")
        if ($at -lt 1 -or $lines[$at - 1] -ne '- Item:') { throw "$($src.Name): no Items entry $($e.DropItem)" }
        $end = $at + 1
        while ($end -lt $lines.Count -and $lines[$end] -match '^    ') { $end++ }
        $lines = @($lines[0..($at - 2)] + $lines[$end..($lines.Count - 1)])
        $did += "Item $($e.DropItem) dropped"
    }
    # DropFlag = '<TemplateFlag>': the record owns that data instead of inheriting it (its own copy must be right).
    if ($e.Contains('DropFlag')) {
        $tf = [array]::IndexOf($lines, '  TemplateFlags:')
        $f = [array]::IndexOf($lines, "  - $($e.DropFlag)", $tf + 1)
        if ($tf -lt 0 -or $f -lt 0 -or ($f -gt $tf + 1 -and @($lines[($tf + 1)..($f - 1)] | Where-Object { $_ -notmatch '^  - ' }).Count -gt 0)) {
            throw "$($src.Name): no $($e.DropFlag) in TemplateFlags"
        }
        $lines = @($lines[0..($f - 1)] + $lines[($f + 1)..($lines.Count - 1)])
        $did += "$($e.DropFlag) flag dropped"
    }
    # Insert = @(@(after, new), ...): add the line 'new' directly below the one line equal to 'after' (a flag the record
    # lacks, a HealthOffset). Spriggit reorders fields on the round-trip, so the position only has to be valid YAML.
    if ($e.Contains('Insert')) {
        foreach ($in in $e.Insert) {
            $n = @($lines | Where-Object { $_ -eq $in[0] }).Count
            if ($n -ne 1) { throw "$($src.Name): expected exactly one '$($in[0])' to insert after, found $n" }
            if ($lines -contains $in[1]) { throw "$($src.Name): already has '$($in[1])'" }
            $at = [array]::IndexOf($lines, $in[0])
            $lines = @($lines[0..$at] + @($in[1]) + $lines[($at + 1)..($lines.Count - 1)])
            $did += "+ $($in[1].Trim())"
        }
    }
    if ($did.Count -eq 0) { throw "$($src.Name): edit does nothing" }
    [System.IO.File]::WriteAllLines((Join-Path $dst $src.Name), $lines, $utf8NoBom)
    "{0,-50} {1}" -f $src.Name, ($did -join '; ')
}
"retargets: $($edits.Count) NPC_ records"
