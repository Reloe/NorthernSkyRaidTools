local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["ruRU"] = L

L[3176] = {
    ["Soaks"] = {text = "Поглощение", name = "Поглощения"},
}

L[3177] = {
    ["Breath"] = {text = "Дыхание", name = "Дыхание"},
    ["Knock"] = {text = "Стук", name = "Стук"},
}

L[3179] = {
    ["CC Display"] = {name = "Отображение контроля"},
    ["Beams"] = {text = "Лучи", name = "Лучи"},
    ["CC Adds"] = {text = "Контроль аддов", name = "Контроль аддов"},
    ["Orbs"] = {text = "Сферы", name = "Сферы"},
}

L[3178] = {
    ["Breath"] = {text = "Дыхание", name = "Дыхание"},
    ["HealthDisplay"] = {name = "Отображение здоровья"},
    ["Spread"] = {text = "Рассредоточение", name = "Рассредоточение"},
    ["Tether"] = {text = "Узы", name = "Узы"},
}

L[3180] = {
    ["Aura of Wrath"] = {text = "Аура гнева", name = "Аура гнева", group = "Ауры паладина"},
    ["TauntAlerts"] = {text = "Провокация", name = "Оповещения о провокации (таунт)"},
    ["Heal Absorb Ticks"] = {name = "Тики поглощения лечения"},
    ["Peace Aura"] = {text = "Аура мира", name = "Аура мира", group = "Ауры паладина"},
    ["Sacred Toll"] = {text = "Священный благовест", name = "Священный благовест"},
    ["Devotion Aura"] = {text = "Аура благочестия", name = "Аура благочестия", group = "Ауры паладина"},
}

L[3181] = {
    ["Tether"] = {text = "Узы", name = "Узы", group = "Аллерия [3-я фаза]"},
    ["Bait_P1"] = {text = "Байт", name = "Байт", group = "Аллерия [1-я фаза]"},
    ["Bait_P3"] = {text = "Байт", name = "Байт", group = "Аллерия [2-я фаза]"},
    ["Bait_P5"] = {text = "Байт", name = "Байт", group = "Аллерия [3-я фаза]"},
    ["Explosion_P1"] = {text = "Взрыв", name = "Взрыв", group = "Аллерия [1-я фаза]"},
    ["Explosion_P3"] = {text = "Взрыв", name = "Взрыв", group = "Аллерия [2-я фаза]"},
    ["Explosion_P5"] = {text = "Взрыв", name = "Взрыв", group = "Аллерия [3-я фаза]"},
    ["Arrows"] = {text = "Стрелки", name = "Стрелки", group = "Аллерия [1-я фаза]"},
    ["Ranged Obelisk_P1"] = {text = "Обелиск", name = "Дальний обелиск", group = "Аллерия [1-я фаза]"},
    ["Ranged Obelisk_P3"] = {text = "Обелиск", name = "Дальний обелиск", group = "Аллерия [2-я фаза]"},
    ["Ranged Obelisk_P5"] = {text = "Обелиск", name = "Дальний обелиск", group = "Аллерия [3-я фаза]"},
    ["Boss-Immune"] = {text = "Иммунитет", name = "Иммунитет босса"},
    ["Melee Obelisk_P1"] = {text = "Обелиск", name = "Ближний обелиск", group = "Аллерия [1-я фаза]"},
    ["Melee Obelisk_P3"] = {text = "Обелиск", name = "Ближний обелиск", group = "Аллерия [2-я фаза]"},
    ["Melee Obelisk_P5"] = {text = "Обелиск", name = "Ближний обелиск", group = "Аллерия [3-я фаза]"},
    ["Stop Cast"] = {text = "Прекратить чтение заклинания", name = "Прекратить чтение заклинания", group = "Аллерия [1-я фаза]"},
}

L[3306] = {
    ["Debuffs_P1"] = {text = "Дебаффы", name = "Дебаффы"},
    ["Debuffs_P2"] = {text = "Дебаффы", name = "Дебаффы"},
}

L[3182] = {
    ["Feather Color"] = {name = "Цвет пера"},
    ["Soaks_P1"] = {text = "Поглощения", name = "Поглощения", group = "Бело'рен [1-я фаза]"},
    ["Soaks_P2"] = {text = "Поглощения", name = "Поглощения", group = "Бело'рен [2-я фаза]"},
    ["Color Swap"] = {text = "СМЕНА ЦВЕТА", name = "Смена цвета"},
    ["Next Hit_P2"] = {text = "Следующий удар", name = "Следующий удар", group = "Бело'рен [2-я фаза]"},
    ["Next Hit_P3"] = {text = "Следующий удар", name = "Следующий удар", group = "Бело'рен [2-я фаза]"},
    ["Quills_P1"] = {text = "Перья", name = "Перья", group = "Бело'рен [1-я фаза]"},
    ["Quills_P2"] = {text = "Перья", name = "Перья", group = "Бело'рен [2-я фаза]"},
    ["Gateway_P2"] = {text = "Врата", name = "Врата", group = "Бело'рен [1-я фаза]"},
    ["Gateway_P3"] = {text = "Врата", name = "Врата", group = "Бело'рен [2-я фаза]"},
}

L[3183] = {
    ["HC Soaks"] = {text = "Поглощения", name = "Поглощения", group = "Л'ура [3-я фаза]"},
    ["Right Stars"] = {text = "Звёзды", name = "Звёзды (справа)", group = "Л'ура [3-я фаза, справа]"},
    ["Left Memory Game"] = {text = "Игра на запоминание", name = "Игра на запоминание (слева)", group = "Л'ура [3-я фаза, слева]"},
    ["Right Soak-Time"] = {text = "Поглощение", name = "Поглощение (справа)", group = "Л'ура [3-я фаза, справа]"},
    ["Left Stars"] = {text = "Звёзды", name = "Звёзды (слева)", group = "Л'ура [3-я фаза, слева]"},
    ["Lura Tank-Hits_P4"] = {text = "Урон по танку", name = "Урон по танкам (3-я фаза)", group = "Л'ура [Танки]"},
    ["Spread"] = {text = "Рассредоточение", name = "Рассредоточение", group = "Л'ура [2-я фаза]"},
    ["Transition Beams"] = {text = "Лучи", name = "Лучи", group = "Л'ура [1-я фаза, переходка]"},
    ["Orbs"] = {text = "Сферы", name = "Сферы", group = "Л'ура [2-я фаза]"},
    ["Soak Cross"] = {text = "Поглощение {rt7}", name = "Поглощение (крест)", group = "Л'ура [2-я фаза, поглощения]"},
    ["Right Soaks"] = {text = "Поглощения", name = "Поглощения (справа)", group = "Л'ура [3-я фаза, справа]"},
    ["MemoryGame"] = {text = "Игра на запоминание", name = "Игра на запоминание", group = "Л'ура [1-я фаза]"},
    ["InterruptDisplay"] = {name = "Отображение прерываний"},
    ["Glaives"] = {text = "Глефы", name = "Глефы", group = "Л'ура [1-я фаза]"},
    ["Interrupts"] = {text = "Прерывания", name = "Прерывания", group = "Л'ура [1-я фаза]"},
    ["Old-Seed-Drop"] = {text = "Выпадение семян", name = "Безусловное выпадение семян", group = "Л'ура [2-я фаза]"},
    ["Right Memory Game"] = {text = "Игра на запоминание", name = "Игра на запоминание (справа)", group = "Л'ура [3-я фаза, справа]"},
    ["Left Soaks"] = {text = "Поглощения", name = "Поглощения (слева)", group = "Л'ура [3-я фаза, слева]"},
    ["CrystalDropTimer"] = {text = "ПОДОБРАТЬ КРИСТАЛЛ", name = "Подобрать кристаллы"},
    ["Beams"] = {text = "Лучи", name = "Лучи", group = "Л'ура [1-я фаза]"},
    ["Galvanize"] = {text = "Поглощения", name = "Обычное поглощение", group = "Л'ура [2-я фаза, поглощения]"},
    ["Blazes"] = {text = "Пламя", name = "Пламя", group = "Л'ура [4-я фаза]"},
    ["P4 Move"] = {text = "Двигаться", name = "Двигаться", group = "Л'ура [4-я фаза]"},
    ["Move"] = {text = "Двигаться", name = "Двигаться", group = "Л'ура [3-я фаза]"},
    ["RunesDisplay"] = {name = "Отображение рун"},
    ["Soak Skull"] = {text = "Поглощение {rt8}", name = "Поглощение (череп)", group = "Л'ура [2-я фаза, поглощения]"},
    ["Seed-Drop"] = {text = "Выпадение семян", name = "Выпадение семян", group = "Л'ура [2-я фаза]"},
    ["Left Soak-Time"] = {text = "Поглощение", name = "Поглощение (слева)", group = "Л'ура [3-я фаза, слева]"},
    ["Lura Taunts_P1"] = {text = "Провокация", name = "Таунт (1-я фаза)", group = "Л'ура [Танки]"},
    ["Lura Taunts_P3"] = {text = "Провокация", name = "Таунт (2-я фаза)", group = "Л'ура [Танки]"},
    ["Full Blaze"] = {text = "Пламя", name = "Пламя", group = "Л'ура [1-я фаза, переходка]"},
    ["Lura Tank-Hits_P1"] = {text = "Урон по танку", name = "Урон по танку (1-я фаза)", group = "Л'ура [Танки]"},
    ["Lura Tank-Hits_P3"] = {text = "Урон по танку", name = "Урон по танку (2-я фаза)", group = "Л'ура [Танки]"},
    ["Soak Star"] = {text = "Поглощение {rt1}", name = "Поглощение (звезда)", group = "Л'ура [2-я фаза, поглощения]"},
    ["Final Slice Stars"] = {text = "Звёзды", name = "Звезды финального куска", group = "Л'ура [3-я фаза]"},
    ["Soak Orange"] = {text = "Поглощение {rt2}", name = "Поглощение (круг)", group = "Л'ура [2-я фаза, поглощения]"},
}

L[3159] = {
    ["BurstingPustules"] = {text = "АоЕ", name = "АоЕ"},
    ["Shrooms"] = {text = "Грибы", name = "Грибы"},
    ["InterruptDisplay"] = {name = "Отображение прерываний"},
    ["Taunts"] = {text = "Провокация", name = "Провокация (таунт)", group = "Гнилотоп [Танки]"},
    ["Tankhits"] = {text = "Урон по танку", name = "Урон по танкам", group = "Гнилотоп [Танки]"},
    ["Adds"] = {text = "Адды", name = "Адды"},
}

L[3379] = {
}

L[3470] = {
    ["RestlessAmani"] = {text = "Адды", name = "Появление аддов", group = "Нек'зали"},
    ["Barrage"] = {text = "Фронтальный удар", name = "Шквал", group = "Нек'зали"},
    ["HungeringPyre"] = {text = "Поглощение", name = "Алчущий костер", group = "Нек'зали"},
    ["Debuffs"] = {text = "Дебаффы", name = "Essence Rend", group = "Нек'зали"},
    ["SoulcoilIgnition"] = {text = "АоЕ", name = "Soulcoil Ignition", group = "Нек'зали"},
    ["InvokeMythic"] = {text = "Прекратить чтение заклинаний", name = "Invoke", group = "Нек'зали"},
    ["Invoke"] = {text = "Уклонение", name = "Invoke", group = "Нек'зали"},
}

L[3445] = {
    -- ["BloodSoakPool"] = {text = "Drop Pool", name = "Soak-Pool", group = "Стражи"},
    -- ["BloodHits"] = {text = "Tank-Hit", name = "Blood Tank-Hit", group = "Стражи"},
    -- ["BloodDispels"] = {text = "Dispels", name = "Blood Dispels", group = "Стражи"},
    -- ["TransitionDebuffs"] = {text = "Number Game", name = "Transition Debuffs", group = "Стражи"},
    -- ["PoisonHits"] = {text = "Tank-Hit", name = "Poison Tank-Hit", group = "Стражи"},
    -- ["ShiftingProtovenom"] = {text = "Spread", name = "Shifting Protovenom", group = "Стражи"},
    -- ["OrbSpawn"] = {text = "Bait Orbs", name = "Orb Spawn", group = "Стражи"},
    -- ["BloodDropPool"] = {text = "Drop-Pool", name = "Tank Drop Pool", group = "Стражи"},
    -- ["PoisonAdd"] = {text = "Poison Add", name = "Poison Add", group = "Стражи"},
    -- ["BloodSoak"] = {text = "Blood-Soak", name = "Blood Soak", group = "Стражи"},
}

L[3455] = {
    -- ["Taunts"] = {text = "Taunt", name = "Taunt", group = "Вашник"},
    -- ["Adds"] = {text = "Adds", name = "Adds", group = "Вашник"},
    -- ["TankHits"] = {text = "Tank-Hit", name = "Tank-Hits", group = "Вашник"},
    -- ["Infection"] = {text = "Infection", name = "Infection", group = "Вашник"},
    -- ["WaveSpread"] = {text = "Pre-Spread", name = "Wave-Spread", group = "Вашник"},
    -- ["Waves"] = {text = "Waves", name = "Waves", group = "Вашник"},
    -- ["Soaks"] = {text = "Soaks", name = "Soaks", group = "Вашник"},
    -- ["AoE"] = {text = "AoE", name = "AoE", group = "Вашник"},
}

L[3497] = {
    -- ["MushroomJump"] = {text = "Jump", name = "Mushroom Jump", group = "Trader Abilities"},
    -- ["ShreddingShards"] = {text = "Tank-Hit", name = "Tank-Hit", group = "Scrollsage Abilities"},
    -- ["Fish-Spawn"] = {text = "Fish Spawn", name = "Fish Spawn", group = "Trader Abilities"},
    -- ["FrostfireVolley"] = {text = "Frostfire Debuffs", name = "Frostfire Volley", group = "Scrollsage Abilities"},
    -- ["ShellSpinScroll"] = {text = "Bait", name = "Shell Spin - Scroll Empowered", group = "First Mate Abilities"},
    -- ["MushroomBait"] = {text = "Bait", name = "Mushroom Bait", group = "Trader Abilities"},
    -- ["BlinkNova"] = {text = "Blink Nova", name = "Blink Nova", group = "Scrollsage Abilities"},
    -- ["ShellSpinTrader"] = {text = "Bait", name = "Shell Spin - Trader Empowered", group = "First Mate Abilities"},
    -- ["TimeToThrowNonConditional"] = {text = "Time to Throw", name = "non-conditional Time to throw Fish", group = "Trader Abilities"},
    -- ["TimeToThrow"] = {text = "Time to Throw", name = "Time to throw Fish", group = "Trader Abilities"},
    -- ["ShellSpinNormal"] = {text = "Bait", name = "Shell Spin Normal", group = "First Mate Abilities"},
    -- ["ExplosiveSurprise"] = {text = "Bomb inc", name = "Bomb Debuff", group = "Trader Abilities"},
    -- ["MightyThud"] = {text = "Soaks", name = "Soaks", group = "First Mate Abilities"},
}

L[3420] = {
    -- ["DamageAmp"] = {text = "Damage Amp", name = "Damage Amp", group = "Ссзорак"},
    -- ["Debuffs"] = {text = "Debuffs", name = "Debuffs", group = "Ссзорак"},
    -- ["WindDebuffs"] = {text = "Wind-Debuffs", name = "WindDebuffs", group = "Ссзорак"},
    -- ["TankCombo"] = {text = "Tank Combo", name = "Tank Combo", group = "Ссзорак"},
    -- ["Bait"] = {text = "Bait", name = "Bait", group = "Ссзорак"},
    -- ["WindsHelper"] = {text = "", name = "Winds Helper", group = "Ссзорак"},
    -- ["SerpentsFury"] = {text = "Stack Up", name = "Serpent's Fury", group = "Ссзорак"},
}

L[3421] = {
    -- ["Adds"] = {text = "Adds", name = "Adds", group = "Два Клыка"},
    -- ["Soak"] = {text = "Soak", name = "Soak", group = "Два Клыка"},
    -- ["TankSoak"] = {text = "Soak", name = "Tank Soak", group = "Два Клыка"},
    -- ["PreSpread"] = {text = "Pre-Spread", name = "Pre-Spread", group = "Два Клыка"},
    -- ["WatchSide"] = {text = "Watch Side", name = "Watch Side", group = "Два Клыка"},
    -- ["Orbs"] = {text = "Orbs", name = "Orbs", group = "Два Клыка"},
    -- ["WatchSpawns"] = {text = "Watch Spawns", name = "Watch Spawns", group = "Два Клыка"},
    -- ["Defensives"] = {text = "Defensives", name = "Defensives", group = "Два Клыка"},
    -- ["Knock"] = {text = "Knock", name = "Knock", group = "Два Клыка"},
}

L[3429] = {
    -- ["InterruptAdds"] = {text = "Ghosts", name = "P2 Interrupt Adds", group = "Coiled Altar P2"},
    -- ["P2Taunt"] = {text = "Taunt", name = "P2 Taunt", group = "Coiled Altar Tanks"},
    -- ["P2Frontal"] = {text = "Frontal", name = "P2 Frontal", group = "Coiled Altar P2"},
    -- ["P1Soak"] = {text = "Soak", name = "P1 Soak", group = "Coiled Altar P1"},
    -- ["P2Shield"] = {text = "Shield", name = "P2 Shield", group = "Coiled Altar P2"},
    -- ["MindControls"] = {text = "Mind Controls", name = "Mind Controls", group = "Coiled Altar P2"},
    -- ["P2Debuffs"] = {text = "Debuffs", name = "P2 Debuffs", group = "Coiled Altar P2"},
    -- ["P1Taunt"] = {text = "Taunt", name = "P1 Taunt", group = "Coiled Altar Tanks"},
    -- ["P1Frontal"] = {text = "Frontal", name = "P1 Frontal", group = "Coiled Altar P1"},
}

L[3492] = {
    -- ["HitKnock"] = {text = "Hit+Knock", name = "P1 Hit+Knock", group = "Ula'tek Tanks"},
    -- ["Taunt"] = {text = "Taunt", name = "P1 Taunt", group = "Ula'tek Tanks"},
    -- ["Waves"] = {text = "Waves", name = "Waves", group = "Ula'tek P1"},
    -- ["Adds"] = {text = "Adds", name = "Adds", group = "Ula'tek P1"},
    -- ["DamageAmpIn"] = {text = "Dmg amp in", name = "Dmg amp", group = "Ula'tek P1"},
    -- ["DamageAmp"] = {text = "Dmg amp", name = "Dmg amp Bar", group = "Ula'tek P1"},
    -- ["PlatformBreak"] = {text = "Platform Break + Knock", name = "Platform Break", group = "Ula'tek P3"},
    -- ["Debuffs"] = {text = "Debuffs", name = "Debuffs", group = "Ula'tek P3"},
}
