local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["enUS"] = L

-- English reference data for encounter alert translators.
-- Keep encounter IDs and internal IDs unchanged when translating.

-- ============================================================================
-- MidnightS1
-- ============================================================================
-- Imperator Averzian (3176)
L[3176] = {
    ["Soaks"] = {name = "Soaks", text = "Soak"},
}

-- Vorasius (3177)
L[3177] = {
    ["Knock"]  = {name = "Knock", text = "Knock"},
    ["Breath"] = {name = "Breath", text = "Breath"},
}

-- Fallen King Salhadaar (3179)
L[3179] = {
    ["Beams"]      = {name = "Beams", text = "Beams"},
    ["Orbs"]       = {name = "Orbs", text = "Orbs"},
    ["CC Adds"]    = {name = "CC Adds", text = "CC Adds"},
    ["CC Display"] = {name = "CC Display"},
}

-- Vaelgor & Ezzorak (3178)
L[3178] = {
    ["Spread"]        = {name = "Spread", text = "Spread"},
    ["Tether"]        = {name = "Tether", text = "Tether"},
    ["Breath"]        = {name = "Breath", text = "Breath"},
    ["HealthDisplay"] = {name = "HealthDisplay"},
}

-- Lightblinded Vanguard (3180)
L[3180] = {
    ["Sacred Toll"]       = {name = "Sacred Toll", text = "Sacred Toll"},
    ["Heal Absorb Ticks"] = {name = "Heal Absorb Ticks"},
    ["Peace Aura"]        = {group = "Paladin Auras", name = "Peace Aura", text = "Peace Aura"},
    ["Devotion Aura"]     = {group = "Paladin Auras", name = "Devotion Aura", text = "Devotion Aura"},
    ["Aura of Wrath"]     = {group = "Paladin Auras", name = "Aura of Wrath", text = "Aura of Wrath"},
    ["TauntAlerts"]       = {name = "TauntAlerts", text = "Taunt"},
}

-- Crown of the Cosmos (3181)
L[3181] = {
    ["Stop Cast"]          = {group = "Alleria P1", name = "Stop Cast", text = "Stop Cast"},
    ["Ranged Obelisk_P1"]  = {group = "Alleria P1", name = "Ranged Obelisk", text = "Obelisk"},
    ["Ranged Obelisk_P3"]  = {group = "Alleria P2", name = "Ranged Obelisk", text = "Obelisk"},
    ["Ranged Obelisk_P5"]  = {group = "Alleria P3", name = "Ranged Obelisk", text = "Obelisk"},
    ["Melee Obelisk_P1"]   = {group = "Alleria P1", name = "Melee Obelisk", text = "Obelisk"},
    ["Melee Obelisk_P3"]   = {group = "Alleria P2", name = "Melee Obelisk", text = "Obelisk"},
    ["Melee Obelisk_P5"]   = {group = "Alleria P3", name = "Melee Obelisk", text = "Obelisk"},
    ["Bait_P1"]            = {group = "Alleria P1", name = "Bait", text = "Bait"},
    ["Bait_P3"]            = {group = "Alleria P2", name = "Bait", text = "Bait"},
    ["Bait_P5"]            = {group = "Alleria P3", name = "Bait", text = "Bait"},
    ["Arrows"]             = {group = "Alleria P1", name = "Arrows", text = "Arrows"},
    ["Explosion_P1"]       = {group = "Alleria P1", name = "Explosion", text = "Explosion"},
    ["Explosion_P3"]       = {group = "Alleria P2", name = "Explosion", text = "Explosion"},
    ["Explosion_P5"]       = {group = "Alleria P3", name = "Explosion", text = "Explosion"},
    ["Boss-Immune"]        = {name = "Boss-Immune", text = "Immune"},
    ["Tether"]             = {group = "Alleria P3", name = "Tether", text = "Tether"},
}

-- Chimaerus (3306)
L[3306] = {
    ["Debuffs_P1"] = {name = "Debuffs", text = "Debuffs"},
    ["Debuffs_P2"] = {name = "Debuffs", text = "Debuffs"},
}

-- Belo'ren (3182)
L[3182] = {
    ["Feather Color"] = {name = "Feather Color"},
    ["Color Swap"]    = {name = "Color Swap", text = "SWAPPED"},
    ["Gateway_P2"]    = {group = "Beloren P1", name = "Gateway", text = "Gateway"},
    ["Gateway_P3"]    = {group = "Beloren P2", name = "Gateway", text = "Gateway"},
    ["Next Hit_P2"]   = {group = "Beloren P2", name = "Next Hit", text = "Next Hit"},
    ["Next Hit_P3"]   = {group = "Beloren P2", name = "Next Hit", text = "Next Hit"},
    ["Soaks_P1"]      = {group = "Beloren P1", name = "Soaks", text = "Soaks"},
    ["Soaks_P2"]      = {group = "Beloren P2", name = "Soaks", text = "Soaks"},
    ["Quills_P1"]     = {group = "Beloren P1", name = "Quills", text = "Quills"},
    ["Quills_P2"]     = {group = "Beloren P2", name = "Quills", text = "Quills"},
}

-- Midnight Falls (3183)
L[3183] = {
    ["MemoryGame"]            = {group = "Lura P1", name = "MemoryGame", text = "Memory Game"},
    ["Glaives"]               = {group = "Lura P1", name = "Glaives", text = "Glaives"},
    ["Interrupts"]            = {group = "Lura P1", name = "Interrupts", text = "Interrupts"},
    ["Beams"]                 = {group = "Lura P1", name = "Beams", text = "Beams"},
    ["Transition Beams"]      = {group = "Lura P1 Transition", name = "Beams", text = "Beams"},
    ["Lura Tank-Hits_P1"]     = {group = "Lura Tanks", name = "P1 Tank-Hits", text = "Tank-Hit"},
    ["Lura Tank-Hits_P3"]     = {group = "Lura Tanks", name = "P2 Tank-Hits", text = "Tank-Hit"},
    ["Lura Tank-Hits_P4"]     = {group = "Lura Tanks", name = "P3 Tank-Hits", text = "Tank-Hit"},
    ["Lura Taunts_P1"]        = {group = "Lura Tanks", name = "P1 Taunts", text = "Taunt"},
    ["Lura Taunts_P3"]        = {group = "Lura Tanks", name = "P2 Taunts", text = "Taunt"},
    ["Full Blaze"]            = {group = "Lura P1 Transition", name = "Full Blaze", text = "Full Blaze"},
    ["Seed-Drop"]             = {group = "Lura P2", name = "Seed-Drop", text = "Seed-Drop"},
    ["Old-Seed-Drop"]         = {group = "Lura P2", name = "non-conditional Seed-Drop", text = "Seed-Drop"},
    ["Galvanize"]             = {group = "Lura P2 Soaks", name = "Generic Soak", text = "Soaks"},
    ["Soak Star"]             = {group = "Lura P2 Soaks", name = "Star Soak", text = "Soak {rt1}"},
    ["Soak Orange"]           = {group = "Lura P2 Soaks", name = "Orange Soak", text = "Soak {rt2}"},
    ["Soak Skull"]            = {group = "Lura P2 Soaks", name = "Skull Soak", text = "Soak {rt8}"},
    ["Soak Cross"]            = {group = "Lura P2 Soaks", name = "Cross Soak", text = "Soak {rt7}"},
    ["Spread"]                = {group = "Lura P2", name = "Spread", text = "Spread"},
    ["Orbs"]                  = {group = "Lura P2", name = "Orbs", text = "Orbs"},
    ["HC Soaks"]              = {group = "Lura P3", name = "HC Soaks", text = "Soaks"},
    ["Move"]                  = {group = "Lura P3", name = "Move", text = "Move"},
    ["Left Memory Game"]      = {group = "Lura P3 Left", name = "Left Memory Game", text = "Memory Game"},
    ["Right Memory Game"]     = {group = "Lura P3 Right", name = "Right Memory Game", text = "Memory Game"},
    ["Left Soaks"]            = {group = "Lura P3 Left", name = "Left Soaks", text = "Soaks"},
    ["Right Soaks"]           = {group = "Lura P3 Right", name = "Right Soaks", text = "Soaks"},
    ["Left Soak-Time"]        = {group = "Lura P3 Left", name = "Left Soak-Time", text = "Soak-Time"},
    ["Right Soak-Time"]       = {group = "Lura P3 Right", name = "Right Soak-Time", text = "Soak-Time"},
    ["Left Stars"]            = {group = "Lura P3 Left", name = "Left Stars", text = "Stars"},
    ["Right Stars"]           = {group = "Lura P3 Right", name = "Right Stars", text = "Stars"},
    ["Final Slice Stars"]     = {group = "Lura P3", name = "Final Slice Stars", text = "Stars"},
    ["Blazes"]                = {group = "Lura P4", name = "Blazes", text = "Blazes"},
    ["P4 Move"]               = {group = "Lura P4", name = "Move", text = "Move"},
    ["CrystalDropTimer"]      = {name = "Time to Pick Crystal", text = "PICK UP"},
    ["RunesDisplay"]          = {name = "RunesDisplay"},
    ["InterruptDisplay"]      = {name = "Interrupt Display"},
}

-- Rotmire (3159)
L[3159] = {
    ["Adds"]             = {name = "Adds", text = "Adds"},
    ["Shrooms"]          = {name = "Shrooms", text = "Shrooms"},
    ["BurstingPustules"] = {name = "AoE", text = "AoE"},
    ["InterruptDisplay"] = {name = "Interrupt Display"},
    ["Taunts"]           = {group = "Rotmire Tanks", name = "Taunts", text = "Taunt"},
    ["Tankhits"]         = {group = "Rotmire Tanks", name = "Tankhits", text = "Tank-Hit"},
}

-- ============================================================================
-- MidnightS2
-- ============================================================================
-- Nymrissa Wavecaller (3379)
L[3379] = {
    ["Adds"]          = {group = "Nymrissa", name = "Add-Spawn", text = "Adds"},
    ["Waves"]         = {group = "Nymrissa", name = "Waves", text = "Waves"},
    ["Knockback"]     = {group = "Nymrissa", name = "Knockback", text = "Knock"},
    ["ChillingFrost"] = {group = "Nymrissa", name = "Chilling Frost", text = "Debuffs"},
    ["AbyssalRain"]   = {group = "Nymrissa", name = "Abyssal Rain", text = "AoE"},
    ["WaterJet"]      = {group = "Nymrissa", name = "Water Jet", text = "Frontal"},
    ["WaterFlurry"]   = {group = "Nymrissa", name = "Iceblade Flurry", text = "Tank-Hit"},
    ["Taunt"]         = {group = "Nymrissa", name = "Taunt", text = "Taunt"},
}

-- Nek'zali the Soulcoiler (3470)
L[3470] = {
    ["Barrage"]          = {group = "Nek'zali", name = "Barrage", text = "Frontal"},
    ["Debuffs"]          = {group = "Nek'zali", name = "Essence Rend", text = "Debuffs"},
    ["SoulcoilIgnition"] = {group = "Nek'zali", name = "Soulcoil Ignition", text = "AoE"},
    ["HungeringPyre"]    = {group = "Nek'zali", name = "Hungering Pyre", text = "Soak"},
    ["RestlessAmani"]    = {group = "Nek'zali", name = "Add-Spawn", text = "Adds"},
    ["Invoke"]           = {group = "Nek'zali", name = "Invoke", text = "Dodge"},
    ["InvokeMythic"]     = {group = "Nek'zali", name = "Invoke", text = "Stop Cast"},
}

-- Entombed Sentinels (3445)
L[3445] = {
    ["PoisonHits"]         = {group = "Sentinels", name = "Poison Tank-Hit", text = "Tank-Hit"},
    ["BloodHits"]          = {group = "Sentinels", name = "Blood Tank-Hit", text = "Tank-Hit"},
    ["BloodDropPool"]      = {group = "Sentinels", name = "Tank Drop Pool", text = "Drop-Pool"},
    ["BloodSoak"]          = {group = "Sentinels", name = "Blood Soak", text = "Blood-Soak"},
    ["BloodSoakPool"]      = {group = "Sentinels", name = "Soak-Pool", text = "Drop Pool"},
    ["BloodDispels"]       = {group = "Sentinels", name = "Blood Dispels", text = "Dispels"},
    ["PoisonAdd"]          = {group = "Sentinels", name = "Poison Add", text = "Poison Add"},
    ["OrbSpawn"]           = {group = "Sentinels", name = "Orb Spawn", text = "Bait Orbs"},
    ["ShiftingProtovenom"] = {group = "Sentinels", name = "Shifting Protovenom", text = "Spread"},
    ["TransitionDebuffs"]  = {group = "Sentinels", name = "Transition Debuffs", text = "Number Game"},
    ["Radar"]              = {group = "Sentinels", name = "Radar", text = ""},
}

-- Vashnik the Malignant (3455)
L[3455] = {
    ["TankHits"]   = {group = "Vashnik", name = "Tank-Hits", text = "Tank-Hit"},
    ["Taunts"]     = {group = "Vashnik", name = "Taunt", text = "Taunt"},
    ["Adds"]       = {group = "Vashnik", name = "Adds", text = "Adds"},
    ["Infection"]  = {group = "Vashnik", name = "Infection", text = "Infection"},
    ["AoE"]        = {group = "Vashnik", name = "AoE", text = "AoE"},
    ["Soaks"]      = {group = "Vashnik", name = "Soaks", text = "Soaks"},
    ["Waves"]      = {group = "Vashnik", name = "Waves", text = "Waves"},
    ["WaveSpread"] = {group = "Vashnik", name = "Wave-Spread", text = "Pre-Spread"},
    ["WavesLine"] = {group = "Vashnik", name = "Waves Line", text = ""},
}

-- The Lost Explorers (3497)
L[3497] = {
    ["ShreddingShards"]           = {group = "Scrollsage Abilities", name = "Tank-Hit", text = "Tank-Hit"},
    ["BlinkNova"]                 = {group = "Scrollsage Abilities", name = "Blink Nova", text = "Blink Nova"},
    ["FrostfireVolley"]           = {group = "Scrollsage Abilities", name = "Frostfire Volley", text = "Frostfire Debuffs"},
    ["ShellSpinNormal"]           = {group = "First Mate Abilities", name = "Shell Spin Normal", text = "Bait"},
    ["ShellSpinScroll"]           = {group = "First Mate Abilities", name = "Shell Spin - Scroll Empowered", text = "Bait"},
    ["ShellSpinTrader"]           = {group = "First Mate Abilities", name = "Shell Spin - Trader Empowered", text = "Bait"},
    ["MightyThud"]                = {group = "First Mate Abilities", name = "Soaks", text = "Soaks"},
    ["Fish-Spawn"]                = {group = "Trader Abilities", name = "Fish Spawn", text = "Fish Spawn"},
    ["MushroomBait"]              = {group = "Trader Abilities", name = "Mushroom Bait", text = "Bait"},
    ["ExplosiveSurprise"]         = {group = "Trader Abilities", name = "Bomb Debuff", text = "Bomb inc"},
    ["MushroomJump"]              = {group = "Trader Abilities", name = "Mushroom Jump", text = "Jump"},
    ["TimeToThrow"]               = {group = "Trader Abilities", name = "Time to throw Fish", text = "Time to Throw"},
    ["TimeToThrowNonConditional"] = {group = "Trader Abilities", name = "non-conditional Time to throw Fish", text = "Time to Throw"},
}

-- Sszorak (3420)
L[3420] = {
    ["TankCombo"]    = {group = "Sszorak", name = "Tank Combo", text = "Tank Combo"},
    ["SetMarkers"]   = {group = "Sszorak", name = "Mark Reminder", text = "Set Markers"},
    ["DamageAmp"]    = {group = "Sszorak", name = "Damage Amp", text = "Damage Amp"},
    ["Bait"]         = {group = "Sszorak", name = "Bait", text = "Bait"},
    ["WindDebuffs"]  = {group = "Sszorak", name = "WindDebuffs", text = "Wind-Debuffs"},
    ["Debuffs"]      = {group = "Sszorak", name = "Debuffs", text = "Debuffs"},
    ["SerpentsFury"] = {group = "Sszorak", name = "Serpent's Fury", text = "Stack Up"},
    ["WindsHelper"]  = {group = "Sszorak", name = "Winds Helper"},
    ["VenomousSurgeTargets"] = {group = "Sszorak", name = "Debuff Targets"},
    ["MarkerMap"] = {group = "Sszorak", name = "Marker Map"},
}

-- The Twin Fangs (3421)
L[3421] = {
    ["Defensives"]  = {group = "Twin Fangs", name = "Defensives", text = "Defensives"},
    ["Soak"]        = {group = "Twin Fangs", name = "Soak", text = "Soak"},
    ["Soak1"]       = {group = "Twin Fangs", name = "Soak", text = "Soak"},
    ["Soak2"]       = {group = "Twin Fangs", name = "Soak", text = "Soak"},
    ["Soak3"]       = {group = "Twin Fangs", name = "Soak", text = "Soak"},
    ["PreSpread"]   = {group = "Twin Fangs", name = "Pre-Spread", text = "Pre-Spread"},
    ["WatchSide"]   = {group = "Twin Fangs", name = "Watch Side", text = "Watch Side"},
    ["Adds"]        = {group = "Twin Fangs", name = "Adds", text = "Adds"},
    ["Orbs"]        = {group = "Twin Fangs", name = "Orbs", text = "Orbs"},
    ["TankSoak"]    = {group = "Twin Fangs", name = "Tank Soak", text = "Soak"},
    ["WatchSpawns"] = {group = "Twin Fangs", name = "Push", text = "Push"},
    ["Knock"]       = {group = "Twin Fangs", name = "Knock", text = "Knock"},
    ["DebuffOverview"] = {group = "Twin Fangs", name = "Eternal Venom Overview", text = "Eternal Venom Overview"},
}

-- The Coiled Altar (3429)
L[3429] = {
    ["P1Frontal"]     = {group = "Coiled Altar", name = "P1 Frontal", text = "Frontal"},
    ["P1OrbDeadline"] = {group = "Coiled Altar", name = "Orb deadline", text = "Orb deadline"},
    ["P1Taunt"]       = {group = "Coiled Altar", name = "P1 Taunt", text = "Taunt"},
    ["P1Soak"]        = {group = "Coiled Altar", name = "P1 Soak", text = "Soak"},
    ["MindControls"]  = {group = "Coiled Altar", name = "P2 Mind Controls", text = "Mind Controls"},
    ["P2Frontal"]     = {group = "Coiled Altar", name = "P2 Frontal", text = "Frontal"},
    ["P2Taunt"]       = {group = "Coiled Altar", name = "P2 Taunt", text = "Taunt"},
    ["P2Debuffs"]     = {group = "Coiled Altar", name = "P2 Debuffs", text = "Debuffs"},
    ["P2Shield"]      = {group = "Coiled Altar", name = "P2 Shield", text = "Shield"},
    ["DebuffCircle"]   = {group = "Coiled Altar", name = "Orb/Bomb Circle", text = ""},
    ["EternalNightfallAbsorb"] = {group = "Coiled Altar", name = "Eternal Nightfall Absorb", text = ""},
    ["InterruptAdds"] = {group = "Coiled Altar", name = "P2 Interrupt Adds", text = "Ghosts"},
    ["InterruptAssignments"] = {group = "Coiled Altar", name = "Interrupt Assignments", text = "Interrupts"},
    ["P3OrbDeadline"] = {group = "Coiled Altar", name = "P3 Orb deadline", text = "Orb deadline"},
    ["P2_5WrongTarget"] = {group = "Coiled Altar", name = "Wrong Target", text = "WRONG TARGET"},
    ["P3Frontal"] = {group = "Coiled Altar", name = "P3 Frontal", text = "Frontal"},
    ["P3Soak"] = {group = "Coiled Altar", name = "P3 Soak", text = "Soak"},
    ["P3Shield"] = {group = "Coiled Altar", name = "P3 Shield", text = "Shield"},
    ["P3Debuffs"] = {group = "Coiled Altar", name = "P3 Debuffs", text = "Debuffs"},
    ["P3InterruptAdds"] = {group = "Coiled Altar", name = "P3 Interrupt Adds", text = "Ghosts"},
    ["P3MindControls"] = {group = "Coiled Altar", name = "P3 Mind Controls", text = "Mind Controls"},
    ["P3Taunt"] = {group = "Coiled Altar", name = "P3 Taunt", text = "Taunt"},
}

-- Ula'tek (3492)
L[3492] = {
    ["HitKnock"]            = {group = "Ula'tek", name = "Mother's Wrath", text = "Hit+Knock"},
    ["Waves"]               = {group = "Ula'tek", name = "Caustic Wave", text = "Waves"},
    ["DamageAmpIn"]         = {group = "Ula'tek", name = "Dmg amp in", text = "Dmg amp in"},
    ["DamageAmp"]           = {group = "Ula'tek", name = "Dmg amp Timer", text = "Dmg amp"},
    ["PlatformBreak"]       = {group = "Ula'tek", name = "Circling Prey", text = "Platform Break"},
    ["Debuffs"]             = {group = "Ula'tek", name = "Serpent's Bite", text = "Debuffs"},
    ["Eggs"]                = {group = "Ula'tek", name = "Eggs", text = "Eggs"},
    ["EggDeadline"]         = {group = "Ula'tek", name = "Egg Deadline", text = "Egg Deadline"},
    ["AddSoak"]             = {group = "Ula'tek", name = "Add Soak", text = "Add Soak"},
    ["Adds"]                = {group = "Ula'tek", name = "P3 Adds", text = "Adds"},
    ["BossSpawn"]           = {group = "Ula'tek", name = "Boss Spawn", text = "Boss Spawn"},
    ["Sweep"]               = {group = "Ula'tek", name = "Sweep", text = "Sweep"},
    ["Soak"]                = {group = "Ula'tek", name = "Soak", text = "Soak"},
    ["TransitionSoakFirst"] = {group = "Ula'tek", name = "First Soak", text = "First Soak"},
    ["TransitionSoakSecond"] = {group = "Ula'tek", name = "Second Soak", text = "Second Soak"},
    ["GraspingFangsOverview"] = {group = "Ula'tek", name = "Grasping Fangs Overview", text = ""},
    ["WrongTarget"] = {group = "Ula'tek", name = "Wrong Target", text = "WRONG TARGET"},
    ["WaveDirection"] = {group = "Ula'tek", name = "Wave Direction Input", text = ""},
    ["WaveLines"] = {group = "Ula'tek", name = "P3 Wave lines", text = ""},
    ["InterruptAssignments"] = {group = "Ula'tek", name = "Interrupt Assignments", text = "Interrupts"},
    ["TransitionPatternSoaks"] = {group = "Ula'tek", name = "Transition Soaks", text = "Soak"},
    ["TransitionPatternArrow"] = {group = "Ula'tek", name = "Transition Arrow", text = ""},
}
