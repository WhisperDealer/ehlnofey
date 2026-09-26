# Small NPC_ edits: retarget a record's Template (which list the spawn draws from) or fix a field.
#
# Each edit copies the WINNING vanilla record verbatim (last in load order, CLAUDE.md "last-wins") and
# changes only the lines it names (guardrail 3): From/To or Swap (whole-line swaps), Level (+ Own),
# DropItem (one Items entry) and DropFlag (one TemplateFlag). One row per record - a second row would overwrite it. It replaces any earlier override of that record in the plugin,
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
        [System.IO.File]::WriteAllLines((Join-Path $dst $src.Name), $lines, $utf8NoBom)
        "{0,-50} {1} -> Level: {2}" -f $src.Name, $was, $e.Level
        continue
    }
    # Line swaps: From/To for one, Swap = @(@(from, to), ...) for several.
    $swaps = @()
    if ($e.Contains('From')) { $swaps += ,@($e.From, $e.To) }
    if ($e.Contains('Swap')) { $swaps += $e.Swap }
    $did = @()
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
    if ($did.Count -eq 0) { throw "$($src.Name): edit does nothing" }
    [System.IO.File]::WriteAllLines((Join-Path $dst $src.Name), $lines, $utf8NoBom)
    "{0,-50} {1}" -f $src.Name, ($did -join '; ')
}
"retargets: $($edits.Count) NPC_ records"
