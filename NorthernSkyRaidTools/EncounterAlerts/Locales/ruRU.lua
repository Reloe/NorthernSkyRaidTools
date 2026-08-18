local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["ruRU"] = L

-- ============================================================================
-- MidnightS1
-- ============================================================================
-- Imperator Averzian (3176)
L[3176] = {
    ["Soaks"] = {name = "Поглощения", text = "Поглощение"},
}

-- Vorasius (3177)
L[3177] = {
    ["Breath"] = {name = "Дыхание", text = "Дыхание"},
    ["Knock"] = {name = "Удар", text = "Удар"},
}

-- Fallen King Salhadaar (3179)
L[3179] = {
    ["CC Display"] = {name = "Отображение контроля"},
    ["Beams"] = {name = "Лучи", text = "Лучи"},
    ["CC Adds"] = {name = "Контроль аддов", text = "Контроль аддов"},
    ["Orbs"] = {name = "Сферы", text = "Сферы"},
}

-- Vaelgor & Ezzorak (3178)
L[3178] = {
    ["Breath"] = {name = "Дыхание", text = "Дыхание"},
    ["HealthDisplay"] = {name = "Отображение здоровья"},
    ["Spread"] = {name = "Разойтись", text = "Разойтись"},
    ["Tether"] = {name = "Узы", text = "Узы"},
}

-- Lightblinded Vanguard (3180)
L[3180] = {
    ["Aura of Wrath"] = {group = "Ауры паладина", name = "Аура гнева", text = "Аура гнева"},
    ["TauntAlerts"] = {name = "Оповещения о провокации (таунт)", text = "Провокация"},
    ["Heal Absorb Ticks"] = {name = "Тики поглощения лечения"},
    ["Peace Aura"] = {group = "Ауры паладина", name = "Аура мира", text = "Аура мира"},
    ["Sacred Toll"] = {name = "Священный благовест", text = "Священный благовест"},
    ["Devotion Aura"] = {group = "Ауры паладина", name = "Аура благочестия", text = "Аура благочестия"},
}

-- Crown of the Cosmos (3181)
L[3181] = {
    ["Tether"] = {group = "Аллерия [3-я фаза]", name = "Узы", text = "Узы"},
    ["Bait_P1"] = {group = "Аллерия [1-я фаза]", name = "Байт", text = "Байт"},
    ["Bait_P3"] = {group = "Аллерия [2-я фаза]", name = "Байт", text = "Байт"},
    ["Bait_P5"] = {group = "Аллерия [3-я фаза]", name = "Байт", text = "Байт"},
    ["Explosion_P1"] = {group = "Аллерия [1-я фаза]", name = "Взрыв", text = "Взрыв"},
    ["Explosion_P3"] = {group = "Аллерия [2-я фаза]", name = "Взрыв", text = "Взрыв"},
    ["Explosion_P5"] = {group = "Аллерия [3-я фаза]", name = "Взрыв", text = "Взрыв"},
    ["Arrows"] = {group = "Аллерия [1-я фаза]", name = "Стрелки", text = "Стрелки"},
    ["Ranged Obelisk_P1"] = {group = "Аллерия [1-я фаза]", name = "Дальний обелиск", text = "Обелиск"},
    ["Ranged Obelisk_P3"] = {group = "Аллерия [2-я фаза]", name = "Дальний обелиск", text = "Обелиск"},
    ["Ranged Obelisk_P5"] = {group = "Аллерия [3-я фаза]", name = "Дальний обелиск", text = "Обелиск"},
    ["Boss-Immune"] = {name = "Иммунитет босса", text = "Иммунитет"},
    ["Melee Obelisk_P1"] = {group = "Аллерия [1-я фаза]", name = "Ближний обелиск", text = "Обелиск"},
    ["Melee Obelisk_P3"] = {group = "Аллерия [2-я фаза]", name = "Ближний обелиск", text = "Обелиск"},
    ["Melee Obelisk_P5"] = {group = "Аллерия [3-я фаза]", name = "Ближний обелиск", text = "Обелиск"},
    ["Stop Cast"] = {group = "Аллерия [1-я фаза]", name = "Прекратить чтение заклинаний", text = "Прекратить чтение заклинаний"},
}

-- Chimaerus (3306)
L[3306] = {
    ["Debuffs_P1"] = {name = "Дебаффы", text = "Дебаффы"},
    ["Debuffs_P2"] = {name = "Дебаффы", text = "Дебаффы"},
}

-- Belo'ren (3182)
L[3182] = {
    ["Feather Color"] = {name = "Цвет пера"},
    ["Soaks_P1"] = {group = "Бело'рен [1-я фаза]", name = "Поглощения", text = "Поглощения"},
    ["Soaks_P2"] = {group = "Бело'рен [2-я фаза]", name = "Поглощения", text = "Поглощения"},
    ["Color Swap"] = {name = "Смена цвета", text = "СМЕНА ЦВЕТА"},
    ["Next Hit_P2"] = {group = "Бело'рен [2-я фаза]", name = "Следующий удар", text = "Следующий удар"},
    ["Next Hit_P3"] = {group = "Бело'рен [2-я фаза]", name = "Следующий удар", text = "Следующий удар"},
    ["Quills_P1"] = {group = "Бело'рен [1-я фаза]", name = "Перья", text = "Перья"},
    ["Quills_P2"] = {group = "Бело'рен [2-я фаза]", name = "Перья", text = "Перья"},
    ["Gateway_P2"] = {group = "Бело'рен [1-я фаза]", name = "Врата", text = "Врата"},
    ["Gateway_P3"] = {group = "Бело'рен [2-я фаза]", name = "Врата", text = "Врата"},
}

-- Midnight Falls (3183)
L[3183] = {
    ["HC Soaks"] = {group = "Л'ура [3-я фаза]", name = "Поглощения", text = "Поглощения"},
    ["Right Stars"] = {group = "Л'ура [3-я фаза, справа]", name = "Звёзды (справа)", text = "Звёзды"},
    ["Left Memory Game"] = {group = "Л'ура [3-я фаза, слева]", name = "Игра на запоминание (слева)", text = "Игра на запоминание"},
    ["Right Soak-Time"] = {group = "Л'ура [3-я фаза, справа]", name = "Поглощение (справа)", text = "Поглощение"},
    ["Left Stars"] = {group = "Л'ура [3-я фаза, слева]", name = "Звёзды (слева)", text = "Звёзды"},
    ["Lura Tank-Hits_P4"] = {group = "Л'ура [Танки]", name = "Урон по танкам (3-я фаза)", text = "Урон по танку"},
    ["Spread"] = {group = "Л'ура [2-я фаза]", name = "Разойтись", text = "Разойтись"},
    ["Transition Beams"] = {group = "Л'ура [1-я фаза, переходка]", name = "Лучи", text = "Лучи"},
    ["Orbs"] = {group = "Л'ура [2-я фаза]", name = "Сферы", text = "Сферы"},
    ["Soak Cross"] = {group = "Л'ура [2-я фаза, поглощения]", name = "Поглощение (крест)", text = "Поглощение {rt7}"},
    ["Right Soaks"] = {group = "Л'ура [3-я фаза, справа]", name = "Поглощения (справа)", text = "Поглощения"},
    ["MemoryGame"] = {group = "Л'ура [1-я фаза]", name = "Игра на запоминание", text = "Игра на запоминание"},
    ["InterruptDisplay"] = {name = "Отображение прерываний"},
    ["Glaives"] = {group = "Л'ура [1-я фаза]", name = "Глефы", text = "Глефы"},
    ["Interrupts"] = {group = "Л'ура [1-я фаза]", name = "Прерывания", text = "Прерывания"},
    ["Old-Seed-Drop"] = {group = "Л'ура [2-я фаза]", name = "Безусловное выпадение семян", text = "Выпадение семян"},
    ["Right Memory Game"] = {group = "Л'ура [3-я фаза, справа]", name = "Игра на запоминание (справа)", text = "Игра на запоминание"},
    ["Left Soaks"] = {group = "Л'ура [3-я фаза, слева]", name = "Поглощения (слева)", text = "Поглощения"},
    ["CrystalDropTimer"] = {name = "Подобрать кристаллы", text = "ПОДОБРАТЬ КРИСТАЛЛ"},
    ["Beams"] = {group = "Л'ура [1-я фаза]", name = "Лучи", text = "Лучи"},
    ["Galvanize"] = {group = "Л'ура [2-я фаза, поглощения]", name = "Обычное поглощение", text = "Поглощения"},
    ["Blazes"] = {group = "Л'ура [4-я фаза]", name = "Пламя", text = "Пламя"},
    ["P4 Move"] = {group = "Л'ура [4-я фаза]", name = "Двигаться", text = "Двигаться"},
    ["Move"] = {group = "Л'ура [3-я фаза]", name = "Двигаться", text = "Двигаться"},
    ["RunesDisplay"] = {name = "Отображение рун"},
    ["Soak Skull"] = {group = "Л'ура [2-я фаза, поглощения]", name = "Поглощение (череп)", text = "Поглощение {rt8}"},
    ["Seed-Drop"] = {group = "Л'ура [2-я фаза]", name = "Выпадение семян", text = "Выпадение семян"},
    ["Left Soak-Time"] = {group = "Л'ура [3-я фаза, слева]", name = "Поглощение (слева)", text = "Поглощение"},
    ["Lura Taunts_P1"] = {group = "Л'ура [Танки]", name = "Таунт (1-я фаза)", text = "Провокация"},
    ["Lura Taunts_P3"] = {group = "Л'ура [Танки]", name = "Таунт (2-я фаза)", text = "Провокация"},
    ["Full Blaze"] = {group = "Л'ура [1-я фаза, переходка]", name = "Пламя", text = "Пламя"},
    ["Lura Tank-Hits_P1"] = {group = "Л'ура [Танки]", name = "Урон по танку (1-я фаза)", text = "Урон по танку"},
    ["Lura Tank-Hits_P3"] = {group = "Л'ура [Танки]", name = "Урон по танку (2-я фаза)", text = "Урон по танку"},
    ["Soak Star"] = {group = "Л'ура [2-я фаза, поглощения]", name = "Поглощение (звезда)", text = "Поглощение {rt1}"},
    ["Final Slice Stars"] = {group = "Л'ура [3-я фаза]", name = "Звезды финального куска", text = "Звёзды"},
    ["Soak Orange"] = {group = "Л'ура [2-я фаза, поглощения]", name = "Поглощение (круг)", text = "Поглощение {rt2}"},
}

-- Rotmire (3159)
L[3159] = {
    ["BurstingPustules"] = {name = "АоЕ", text = "АоЕ"},
    ["Shrooms"] = {name = "Грибы", text = "Грибы"},
    ["InterruptDisplay"] = {name = "Отображение прерываний"},
    ["Taunts"] = {group = "Гнилотоп [Танки]", name = "Таунт", text = "Провокация"},
    ["Tankhits"] = {group = "Гнилотоп [Танки]", name = "Урон по танкам", text = "Урон по танку"},
    ["Adds"] = {name = "Адды", text = "Адды"},
}

-- ============================================================================
-- MidnightS2
-- ============================================================================
-- Nymrissa Wavecaller (3379)
L[3379] = {
    ["Adds"]          = {group = "Нимрисса", name = "Появление аддов", text = "Адды"},
    ["Waves"]         = {group = "Нимрисса", name = "Волны", text = "Волны"},
    ["Knockback"]     = {group = "Нимрисса", name = "Отбрасывание", text = "Удар"},
    ["ChillingFrost"] = {group = "Нимрисса", name = "Леденящий холод", text = "Дебаффы"},
    ["AbyssalRain"]   = {group = "Нимрисса", name = "Глубинный дождь", text = "АоЕ"},
    ["WaterJet"]      = {group = "Нимрисса", name = "Сильная струя воды", text = "Фронтальный удар"},
    ["WaterFlurry"]   = {group = "Нимрисса", name = "Шквал ледяных клинков", text = "Урон по танку"},
    ["Taunt"]         = {group = "Нимрисса", name = "Таунт", text = "Таунт"},
}

-- Nek'zali the Soulcoiler (3470)
L[3470] = {
    ["RestlessAmani"] = {group = "Нек'зали", name = "Появление аддов", text = "Адды"},
    ["Barrage"] = {group = "Нек'зали", name = "Шквал", text = "Фронтальный удар"},
    ["HungeringPyre"] = {group = "Нек'зали", name = "Алчущий костер", text = "Поглощение"},
    ["Debuffs"] = {group = "Нек'зали", name = "Раздирание сущности", text = "Дебаффы"},
    ["SoulcoilIgnition"] = {group = "Нек'зали", name = "Поджигание плененных душ", text = "АоЕ"},
    ["InvokeMythic"] = {group = "Нек'зали", name = "Воззвание", text = "Прекратить чтение заклинаний"},
    ["Invoke"] = {group = "Нек'зали", name = "Воззвание", text = "Уклонение"},
}

-- Entombed Sentinels (3445)
L[3445] = {
    ["BloodSoakPool"] = {group = "Стражи", name = "Поглощение лужи", text = "Оставить лужу"},
    ["BloodHits"] = {group = "Стражи", name = "Урон по танку (кровь)", text = "Урон по танку"},
    ["BloodDispels"] = {group = "Стражи", name = "Рассеивания (кровь)", text = "Рассеивания"},
    ["TransitionDebuffs"] = {group = "Стражи", name = "Дебаффы (переходная фаза)", text = "Игра чисел"},
    ["PoisonHits"] = {group = "Стражи", name = "Урон по танку (яд)", text = "Урон по танку"},
    ["ShiftingProtovenom"] = {group = "Стражи", name = "Изменчивый протояд", text = "Разойтись"},
    ["OrbSpawn"] = {group = "Стражи", name = "Появление сферы", text = "Байт сферы"},
    ["BloodDropPool"] = {group = "Стражи", name = "Оставить лужу (танк)", text = "Оставить лужу"},
    ["PoisonAdd"] = {group = "Стражи", name = "Ядовитый адд", text = "Ядовитый адд"},
    ["BloodSoak"] = {group = "Стражи", name = "Поглощение (кровь)", text = "Поглощение (кровь)"},
}

-- Vashnik the Malignant (3455)
L[3455] = {
    ["Taunts"] = {group = "Вашник", name = "Таунт", text = "Провокация"},
    ["Adds"] = {group = "Вашник", name = "Адды", text = "Адды"},
    ["TankHits"] = {group = "Вашник", name = "Урон по танку", text = "Урон по танку"},
    ["Infection"] = {group = "Вашник", name = "Заражение", text = "Заражение"},
    ["WaveSpread"] = {group = "Вашник", name = "Разойтись от волны", text = "Заранее разойтись"},
    ["Waves"] = {group = "Вашник", name = "Волны", text = "Волны"},
    ["Soaks"] = {group = "Вашник", name = "Поглощения", text = "Поглощения"},
    ["AoE"] = {group = "Вашник", name = "АоЕ", text = "АоЕ"},
}

-- The Lost Explorers (3497)
L[3497] = {
    -- ["MushroomJump"] = {group = "Trader Abilities", name = "Прыжок на грибе", text = "Прыжок"},
    -- ["ShreddingShards"] = {group = "Scrollsage Abilities", name = "Урон по танку", text = "Урон по танку"},
    -- ["Fish-Spawn"] = {group = "Trader Abilities", name = "Появление рыбы", text = "Появление рыбы"},
    -- ["FrostfireVolley"] = {group = "Scrollsage Abilities", name = "Залп ледяного огня", text = "Дебаффы (залп ледяного огня)"},
    -- ["ShellSpinScroll"] = {group = "First Mate Abilities", name = "Крутящийся панцирь - Scroll Empowered", text = "Байт"},
    -- ["MushroomBait"] = {group = "Trader Abilities", name = "Байт гриба", text = "Байт"},
    -- ["BlinkNova"] = {group = "Scrollsage Abilities", name = "Скачок-вспышка", text = "Скачок-вспышка"},
    -- ["ShellSpinTrader"] = {group = "First Mate Abilities", name = "Крутящийся панцирь - Trader Empowered", text = "Байт"},
    -- ["TimeToThrowNonConditional"] = {group = "Trader Abilities", name = "Пора бросать рыбу (безусловно)", text = "Время для броска"},
    -- ["TimeToThrow"] = {group = "Trader Abilities", name = "Пора бросать рыбу", text = "Время для броска"},
    -- ["ShellSpinNormal"] = {group = "First Mate Abilities", name = "Крутящийся панцирь (обычный режим)", text = "Байт"},
    -- ["ExplosiveSurprise"] = {group = "Trader Abilities", name = "Дебафф бомбы", text = "Бомба"},
    -- ["MightyThud"] = {group = "First Mate Abilities", name = "Поглощения", text = "Поглощения"},
}

-- Sszorak (3420)
L[3420] = {
    ["DamageAmp"] = {group = "Ссзорак", name = "Усиление урона", text = "Усиление урона"},
    ["Debuffs"] = {group = "Ссзорак", name = "Дебаффы", text = "Дебаффы"},
    ["WindDebuffs"] = {group = "Ссзорак", name = "Дебаффы ветра", text = "Дебаффы ветра"},
    ["TankCombo"] = {group = "Ссзорак", name = "Танковое комбо", text = "Танковое комбо"},
    ["Bait"] = {group = "Ссзорак", name = "Байт", text = "Байт"},
    ["WindsHelper"] = {group = "Ссзорак", name = "Помощник ветров"},
    ["SerpentsFury"] = {group = "Ссзорак", name = "Змеиное неистовство", text = "Собраться"},
}

-- The Twin Fangs (3421)
L[3421] = {
    ["Adds"] = {group = "Два Клыка", name = "Адды", text = "Адды"},
    ["Soak"] = {group = "Два Клыка", name = "Поглощение", text = "Поглощение"},
    ["TankSoak"] = {group = "Два Клыка", name = "Поглощение танка", text = "Поглощение"},
    ["PreSpread"] = {group = "Два Клыка", name = "Заранее разойтись", text = "Заранее разойтись"},
    ["WatchSide"] = {group = "Два Клыка", name = "Смотреть по сторонам", text = "Смотреть по сторонам"},
    ["Orbs"] = {group = "Два Клыка", name = "Сферы", text = "Сферы"},
    ["WatchSpawns"] = {group = "Два Клыка", name = "Следить за появлением", text = "Следить за появлением"},
    ["Defensives"] = {group = "Два Клыка", name = "Защитные способности", text = "Защитные способности"},
    ["Knock"] = {group = "Два Клыка", name = "Удар", text = "Удар"},
}

-- The Coiled Altar (3429)
L[3429] = {
    ["InterruptAdds"] = {group = "Спиральный алтарь [2-я фаза]", name = "Прерывание аддов (2-я фаза)", text = "Призраки"},
    ["P2Taunt"] = {group = "Спиральный алтарь [Танки]", name = "Таунт (2-я фаза)", text = "Провокация"},
    ["P2Frontal"] = {group = "Спиральный алтарь [2-я фаза]", name = "Фронтальный удар (2-я фаза)", text = "Фронтальный удар"},
    ["P1Soak"] = {group = "Спиральный алтарь [1-я фаза]", name = "Поглощение (1-я фаза)", text = "Поглощение"},
    ["P2Shield"] = {group = "Спиральный алтарь [2-я фаза]", name = "Щит (2-я фаза)", text = "Щит"},
    ["MindControls"] = {group = "Спиральный алтарь [2-я фаза]", name = "Контроль над разумом", text = "Контроль над разумом"},
    ["P2Debuffs"] = {group = "Спиральный алтарь [2-я фаза]", name = "Дебаффы (2-я фаза)", text = "Дебаффы"},
    ["P1Taunt"] = {group = "Спиральный алтарь [Танки]", name = "Таунт (1-я фаза)", text = "Провокация"},
    ["P1Frontal"] = {group = "Спиральный алтарь [1-я фаза]", name = "Фронтальный удар (1-я фаза)", text = "Фронтальный удар"},
    ["P3Frontal"] = {group = "Спиральный алтарь [3-я фаза]", name = "Фронтальный удар (3-я фаза)", text = "Фронтальный удар"},
    ["P3Soak"] = {group = "Спиральный алтарь [3-я фаза]", name = "Поглощение (3-я фаза)", text = "Поглощение"},
    ["P3Shield"] = {group = "Спиральный алтарь [3-я фаза]", name = "Щит (3-я фаза)", text = "Щит"},
    ["P3Debuffs"] = {group = "Спиральный алтарь [3-я фаза]", name = "Дебаффы (3-я фаза)", text = "Дебаффы"},
    ["P3InterruptAdds"] = {group = "Спиральный алтарь [3-я фаза]", name = "Прерывания у аддов (3-я фаза)", text = "Призраки"},
    ["P3MindControls"] = {group = "Спиральный алтарь [3-я фаза]", name = "Контроль над разумом (3-я фаза)", text = "Контроль над разумом"},
    ["P3Taunt"] = {group = "Спиральный алтарь [Танки]", name = "Таунт (3-я фаза)", text = "Провокация"},
}

-- Ula'tek (3492)
L[3492] = {
    --[[
    ["HitKnock"]      = {group = "Ула'тек [Танки]", name = "Урон + удар (1-я фаза)", text = "Урон + удар"},
    ["Taunt"]         = {group = "Ула'тек [Танки]", name = "Таунт (1-я фаза)", text = "Провокация"},
    ["Waves"]         = {group = "Ула'тек [1-я фаза]", name = "Волны", text = "Волны"},
    ["Adds"]          = {group = "Ула'тек [1-я фаза]", name = "Адды", text = "Адды"},
    ["DamageAmpIn"]   = {group = "Ула'тек [1-я фаза]", name = "Усиление урона", text = "Усиление урона через"},
    ["DamageAmp"]     = {group = "Ула'тек [1-я фаза]", name = "Полоса усиления урона", text = "Усиление урона"},
    ["PlatformBreak"] = {group = "Ула'тек [3-я фаза]", name = "Разрушение платформы", text = "Разрушение платформы + удар"},
    ["Debuffs"]       = {group = "Ула'тек [3-я фаза]", name = "Дебаффы", text = "Дебаффы"},
    ]]
}
