local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["ruRU"] = L

L[3176] = {
    ["Soaks"] = {text = "Поглощение", name = "Поглощения"},
}

L[3177] = {
    ["Breath"] = {text = "Дыхание", name = "Дыхание"},
    ["Knock"] = {text = "Удар", name = "Удар"},
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
    ["Taunts"] = {text = "Провокация", name = "Таунт", group = "Вашник"},
    ["Adds"] = {text = "Адды", name = "Адды", group = "Вашник"},
    ["TankHits"] = {text = "Урон по танку", name = "Урон по танку", group = "Вашник"},
    ["Infection"] = {text = "Заражение", name = "Заражение", group = "Вашник"},
    ["WaveSpread"] = {text = "Предварительное рассредоточение", name = "Разойтись от волны", group = "Вашник"},
    ["Waves"] = {text = "Волны", name = "Волны", group = "Вашник"},
    ["Soaks"] = {text = "Поглощения", name = "Поглощения", group = "Вашник"},
    ["AoE"] = {text = "АоЕ", name = "АоЕ", group = "Вашник"},
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
    ["DamageAmp"] = {text = "Усиление урона", name = "Усиление урона", group = "Ссзорак"},
    ["Debuffs"] = {text = "Дебаффы", name = "Дебаффы", group = "Ссзорак"},
    ["WindDebuffs"] = {text = "Дебаффы ветра", name = "Дебаффы ветра", group = "Ссзорак"},
    ["TankCombo"] = {text = "Танковое комбо", name = "Танковое комбо", group = "Ссзорак"},
    ["Bait"] = {text = "Байт", name = "Байт", group = "Ссзорак"},
    ["WindsHelper"] = {name = "Помощник ветров", group = "Ссзорак"},
    ["SerpentsFury"] = {text = "Собраться", name = "Змеиное неистовство", group = "Ссзорак"},
}

L[3421] = {
    ["Adds"] = {text = "Адды", name = "Адды", group = "Два Клыка"},
    ["Soak"] = {text = "Поглощение", name = "Поглощение", group = "Два Клыка"},
    ["TankSoak"] = {text = "Поглощение", name = "Поглощение танка", group = "Два Клыка"},
    ["PreSpread"] = {text = "Предварительное рассредоточение", name = "Предварительное рассредоточение", group = "Два Клыка"},
    ["WatchSide"] = {text = "Смотреть по сторонам", name = "Смотреть по сторонам", group = "Два Клыка"},
    ["Orbs"] = {text = "Сферы", name = "Сферы", group = "Два Клыка"},
    ["WatchSpawns"] = {text = "Следить за появлением", name = "Следить за появлением", group = "Два Клыка"},
    ["Defensives"] = {text = "Защитные способности", name = "Защитные способности", group = "Два Клыка"},
    ["Knock"] = {text = "Удар", name = "Удар", group = "Два Клыка"},
}

L[3429] = {
    ["InterruptAdds"] = {text = "Призраки", name = "Прерывание аддов (2-я фаза)", group = "Спиральный алтарь [2-я фаза]"},
    ["P2Taunt"] = {text = "Провокация", name = "Таунт (2-я фаза)", group = "Спиральный алтарь [Танки]"},
    ["P2Frontal"] = {text = "Фронтальный удар", name = "Фронтальный удар (2-я фаза)", group = "Спиральный алтарь [2-я фаза]"},
    ["P1Soak"] = {text = "Поглощение", name = "Поглощение (1-я фаза)", group = "Спиральный алтарь [1-я фаза]"},
    ["P2Shield"] = {text = "Щит", name = "Щит (2-я фаза)", group = "Спиральный алтарь [2-я фаза]"},
    ["MindControls"] = {text = "Контроль над разумом", name = "Контроль над разумом", group = "Спиральный алтарь [2-я фаза]"},
    ["P2Debuffs"] = {text = "Дебаффы", name = "Дебаффы (2-я фаза)", group = "Спиральный алтарь [2-я фаза]"},
    ["P1Taunt"] = {text = "Провокация", name = "Таунт (1-я фаза)", group = "Спиральный алтарь [Танки]"},
    ["P1Frontal"] = {text = "Фронтальный удар", name = "Фронтальный удар (1-я фаза)", group = "Спиральный алтарь [1-я фаза]"},
}

L[3492] = {
    -- ["HitKnock"] = {text = "Урон + удар", name = "Урон + удар (1-я фаза)", group = "Ула'тек [Танки]"},
    -- ["Taunt"] = {text = "Провокация", name = "Таунт (1-я фаза)", group = "Ула'тек [Танки]"},
    -- ["Waves"] = {text = "Волны", name = "Волны", group = "Ула'тек [1-я фаза]"},
    -- ["Adds"] = {text = "Адды", name = "Адды", group = "Ула'тек [1-я фаза]"},
    -- ["DamageAmpIn"] = {text = "Усиление урона через", name = "Усиление урона", group = "Ула'тек [1-я фаза]"},
    -- ["DamageAmp"] = {text = "Усиление урона", name = "Полоса усиления урона", group = "Ула'тек [1-я фаза]"},
    -- ["PlatformBreak"] = {text = "Разрушение платформы + удар", name = "Разрушение платформы", group = "Ула'тек [3-я фаза]"},
    -- ["Debuffs"] = {text = "Дебаффы", name = "Дебаффы", group = "Ула'тек [3-я фаза]"},
}
