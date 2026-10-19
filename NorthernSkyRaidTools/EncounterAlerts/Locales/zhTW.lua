local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["zhTW"] = L




-- ============================================================================
-- MidnightS1
-- ============================================================================
-- Imperator Averzian (3176)
L[3176] = {
    ["Soaks"] = {name = "分傷", text = "分傷"},
}

-- Vorasius (3177)
L[3177] = {
    ["Knock"]  = {name = "擊退", text = "擊退"},
    ["Breath"] = {name = "吐息", text = "吐息"},
}

-- Fallen King Salhadaar (3179)
L[3179] = {
    ["Beams"]      = {name = "光束", text = "光束"},
    ["Orbs"]       = {name = "球", text = "球"},
    ["CC Adds"]    = {name = "CC 小怪", text = "CC 小怪"},
    ["CC Display"] = {name = "CC 顯示"},
}

-- Vaelgor & Ezzorak (3178)
L[3178] = {
    ["Spread"]        = {name = "分散", text = "分散"},
    ["Tether"]        = {name = "連線", text = "連線"},
    ["Breath"]        = {name = "吐息", text = "吐息"},
    ["HealthDisplay"] = {name = "血量顯示"},
}

-- Lightblinded Vanguard (3180)
L[3180] = {
    ["Sacred Toll"]       = {name = "神聖代償", text = "神聖代償"},
    ["Heal Absorb Ticks"] = {name = "治療吸收跳數"},
    ["Peace Aura"]        = {group = "聖騎士光環", name = "和平光環", text = "和平光環"},
    ["Devotion Aura"]     = {group = "聖騎士光環", name = "奉獻光環", text = "奉獻光環"},
    ["Aura of Wrath"]     = {group = "聖騎士光環", name = "憤慨光環", text = "憤慨光環"},
    ["TauntAlerts"]       = {name = "嘲諷提醒", text = "嘲諷"},
}

-- Crown of the Cosmos (3181)
L[3181] = {
    ["Stop Cast"]          = {group = "艾蘭里亞 P1", name = "停止唱法", text = "停止唱法"},
    ["Ranged Obelisk_P1"]  = {group = "艾蘭里亞 P1", name = "遠程方尖碑", text = "方尖碑"},
    ["Ranged Obelisk_P3"]  = {group = "艾蘭里亞 P2", name = "遠程方尖碑", text = "方尖碑"},
    ["Ranged Obelisk_P5"]  = {group = "艾蘭里亞 P3", name = "遠程方尖碑", text = "方尖碑"},
    ["Melee Obelisk_P1"]   = {group = "艾蘭里亞 P1", name = "近戰方尖碑", text = "方尖碑"},
    ["Melee Obelisk_P3"]   = {group = "艾蘭里亞 P2", name = "近戰方尖碑", text = "方尖碑"},
    ["Melee Obelisk_P5"]   = {group = "艾蘭里亞 P3", name = "近戰方尖碑", text = "方尖碑"},
    ["Bait_P1"]            = {group = "艾蘭里亞 P1", name = "Bait", text = "Bait"},
    ["Bait_P3"]            = {group = "艾蘭里亞 P2", name = "Bait", text = "Bait"},
    ["Bait_P5"]            = {group = "艾蘭里亞 P3", name = "Bait", text = "Bait"},
    ["Arrows"]             = {group = "艾蘭里亞 P1", name = "箭", text = "箭"},
    ["Explosion_P1"]       = {group = "艾蘭里亞 P1", name = "爆炸", text = "爆炸"},
    ["Explosion_P3"]       = {group = "艾蘭里亞 P2", name = "爆炸", text = "爆炸"},
    ["Explosion_P5"]       = {group = "艾蘭里亞 P3", name = "爆炸", text = "爆炸"},
    ["Boss-Immune"]        = {name = "首領免疫", text = "免疫"},
    ["Tether"]             = {group = "艾蘭里亞 P3", name = "連線", text = "連線"},
}

-- Chimaerus (3306)
L[3306] = {
    ["Debuffs_P1"] = {name = "Debuff", text = "Debuff"},
    ["Debuffs_P2"] = {name = "Debuff", text = "Debuff"},
}

-- Belo'ren (3182)
L[3182] = {
    ["Feather Color"] = {name = "羽毛顏色"},
    ["Color Swap"]    = {name = "換色", text = "已交換"},
    ["Gateway_P2"]    = {group = "貝羅倫 P1", name = "傳送門", text = "傳送門"},
    ["Gateway_P3"]    = {group = "貝羅倫 P2", name = "傳送門", text = "傳送門"},
    ["Next Hit_P2"]   = {group = "貝羅倫 P2", name = "下次命中", text = "下次命中"},
    ["Next Hit_P3"]   = {group = "貝羅倫 P2", name = "下次命中", text = "下次命中"},
    ["Soaks_P1"]      = {group = "貝羅倫 P1", name = "分傷", text = "分傷"},
    ["Soaks_P2"]      = {group = "貝羅倫 P2", name = "分傷", text = "分傷"},
    ["Quills_P1"]     = {group = "貝羅倫 P1", name = "注能刺羽", text = "刺羽"},
    ["Quills_P2"]     = {group = "貝羅倫 P2", name = "注能刺羽", text = "刺羽"},
}

-- Midnight Falls (3183)
L[3183] = {
    ["MemoryGame"]            = {group = "路拉 P1", name = "記憶遊戲", text = "記憶遊戲"},
    ["Glaives"]               = {group = "路拉 P1", name = "天堂戰刃", text = "戰刃"},
    ["Interrupts"]            = {group = "路拉 P1", name = "打斷", text = "打斷"},
    ["Beams"]                 = {group = "路拉 P1", name = "光束", text = "光束"},
    ["Transition Beams"]      = {group = "路拉 P1 轉階段", name = "光束", text = "光束"},
    ["Lura Tank-Hits_P1"]     = {group = "路拉 坦克", name = "P1 打坦技", text = "打坦技"},
    ["Lura Tank-Hits_P3"]     = {group = "路拉 坦克", name = "P2 打坦技", text = "打坦技"},
    ["Lura Tank-Hits_P4"]     = {group = "路拉 坦克", name = "P3 打坦技", text = "打坦技"},
    ["Lura Taunts_P1"]        = {group = "路拉 坦克", name = "P1 嘲諷", text = "嘲諷"},
    ["Lura Taunts_P3"]        = {group = "路拉 坦克", name = "P2 嘲諷", text = "嘲諷"},
    ["Full Blaze"]            = {group = "路拉 P1 轉階段", name = "星辰破片（全團）", text = "全團破片"},
    ["Seed-Drop"]             = {group = "路拉 P2", name = "丟下黎明水晶", text = "丟水晶"},
    ["Old-Seed-Drop"]         = {group = "路拉 P2", name = "丟下黎明水晶（無條件）", text = "丟水晶"},
    ["Galvanize"]             = {group = "路拉 P2 分傷", name = "通用分傷", text = "分傷"},
    ["Soak Star"]             = {group = "路拉 P2 分傷", name = "星星分傷", text = "分傷 {rt1}"},
    ["Soak Orange"]           = {group = "路拉 P2 分傷", name = "橘色分傷", text = "分傷 {rt2}"},
    ["Soak Skull"]            = {group = "路拉 P2 分傷", name = "骷髏分傷", text = "分傷 {rt8}"},
    ["Soak Cross"]            = {group = "路拉 P2 分傷", name = "叉分傷", text = "分傷 {rt7}"},
    ["Spread"]                = {group = "路拉 P2", name = "分散", text = "分散"},
    ["Orbs"]                  = {group = "路拉 P2", name = "球", text = "球"},
    ["HC Soaks"]              = {group = "路拉 P3", name = "英雄分傷", text = "分傷"},
    ["Move"]                  = {group = "路拉 P3", name = "移動", text = "移動"},
    ["Left Memory Game"]      = {group = "路拉 P3 左", name = "左側記憶遊戲", text = "記憶遊戲"},
    ["Right Memory Game"]     = {group = "路拉 P3 右", name = "右側記憶遊戲", text = "記憶遊戲"},
    ["Left Soaks"]            = {group = "路拉 P3 左", name = "左側分傷", text = "分傷"},
    ["Right Soaks"]           = {group = "路拉 P3 右", name = "右側分傷", text = "分傷"},
    ["Left Soak-Time"]        = {group = "路拉 P3 左", name = "左側分傷時間", text = "分傷時間"},
    ["Right Soak-Time"]       = {group = "路拉 P3 右", name = "右側分傷時間", text = "分傷時間"},
    ["Left Stars"]            = {group = "路拉 P3 左", name = "左側星星", text = "星星"},
    ["Right Stars"]           = {group = "路拉 P3 右", name = "右側星星", text = "星星"},
    ["Final Slice Stars"]     = {group = "路拉 P3", name = "黑暗星宿（最後）", text = "星星"},
    ["Blazes"]                = {group = "路拉 P4", name = "星辰破片", text = "破片"},
    ["P4 Move"]               = {group = "路拉 P4", name = "移動", text = "移動"},
    ["CrystalDropTimer"]      = {name = "撿水晶時間", text = "撿起"},
    ["RunesDisplay"]          = {name = "符文顯示"},
    ["InterruptDisplay"]      = {name = "打斷提醒"},
}

-- Rotmire (3159)
L[3159] = {
    ["Adds"]             = {name = "小怪", text = "小怪"},
    ["Shrooms"]          = {name = "蘑菇", text = "蘑菇"},
    ["BurstingPustules"] = {name = "AE", text = "AE"},
    ["InterruptDisplay"] = {name = "打斷提醒"},
    ["Taunts"]           = {group = "腐沼 坦克", name = "嘲諷", text = "嘲諷"},
    ["Tankhits"]         = {group = "腐沼 坦克", name = "打坦技", text = "打坦技"},
}

-- ============================================================================
-- MidnightS2
-- ============================================================================
-- Nymrissa Wavecaller (3379)
L[3379] = {
    ["Adds"]          = {group = "妮莉莎", name = "出小怪", text = "小怪"},
    ["Waves"]         = {group = "妮莉莎", name = "波浪", text = "波浪"},
    ["Knockback"]     = {group = "妮莉莎", name = "擊退", text = "擊退"},
    ["ChillingFrost"] = {group = "妮莉莎", name = "刺骨冰霜", text = "Debuff"},
    ["AbyssalRain"]   = {group = "妮莉莎", name = "深淵之雨", text = "AE"},
    ["WaterJet"]      = {group = "妮莉莎", name = "水流噴射", text = "射線"},
    ["WaterFlurry"]   = {group = "妮莉莎", name = "脈動浪潮", text = "打坦技"},
    ["Taunt"]         = {group = "妮莉莎", name = "嘲諷", text = "嘲諷"},
}

-- Nek'zali the Soulcoiler (3470)
L[3470] = {
    ["Barrage"]          = {group = "尼札利", name = "彈幕", text = "頭前"},
    ["Debuffs"]          = {group = "尼札利", name = "精華撕裂", text = "Debuff"},
    ["SoulcoilIgnition"] = {group = "尼札利", name = "纏魂點燃", text = "AE"},
    ["HungeringPyre"]    = {group = "尼札利", name = "飢饞蛇火", text = "分傷"},
    ["RestlessAmani"]    = {group = "尼札利", name = "出小怪", text = "小怪"},
    ["Invoke"]           = {group = "尼札利", name = "祈求", text = "躲地板"},
    ["InvokeMythic"]     = {group = "尼札利", name = "祈求", text = "停止唱法"},
}

-- Entombed Sentinels (3445)
L[3445] = {
    ["PoisonHits"]         = {group = "衛哨", name = "毒 打坦技", text = "打坦技"},
    ["BloodHits"]          = {group = "衛哨", name = "血 打坦技", text = "打坦技"},
    ["BloodDropPool"]      = {group = "衛哨", name = "坦克放水", text = "放水"},
    ["BloodSoak"]          = {group = "衛哨", name = "血 分傷", text = "血 分傷"},
    ["BloodSoakPool"]      = {group = "衛哨", name = "血 分傷放水", text = "放水"},
    ["BloodDispels"]       = {group = "衛哨", name = "血 驅散", text = "驅散"},
    ["PoisonAdd"]          = {group = "衛哨", name = "毒 小怪", text = "毒軟泥"},
    ["OrbSpawn"]           = {group = "衛哨", name = "出球", text = "Bait球"},
    ["ShiftingProtovenom"] = {group = "衛哨", name = "移轉原型毒液", text = "分散"},
    ["TransitionDebuffs"]  = {group = "衛哨", name = "轉階 Debuff", text = "數字遊戲"},
    ["Radar"]              = {group = "衛哨", name = "距離雷達", text = ""},
}

-- Vashnik the Malignant (3455)
L[3455] = {
    ["TankHits"]   = {group = "伐許尼克", name = "打坦技", text = "打坦技"},
    ["Taunts"]     = {group = "伐許尼克", name = "嘲諷", text = "嘲諷"},
    ["Adds"]       = {group = "伐許尼克", name = "小怪", text = "小怪"},
    ["Infection"]  = {group = "伐許尼克", name = "感染", text = "吸收盾"},
    ["AoE"]        = {group = "伐許尼克", name = "AE", text = "AE"},
    ["Soaks"]      = {group = "伐許尼克", name = "分傷", text = "踩圈"},
    ["Waves"]      = {group = "伐許尼克", name = "波", text = "波"},
    ["WaveSpread"] = {group = "伐許尼克", name = "波 分散", text = "分散"},
}

-- The Lost Explorers (3497)
L[3497] = {
    ["ShreddingShards"]           = {group = "卷軸先知 技能", name = "打坦技", text = "打坦技"},
    ["BlinkNova"]                 = {group = "卷軸先知 技能", name = "閃現新星", text = "閃現新星"},
    ["FrostfireVolley"]           = {group = "卷軸先知 技能", name = "冰縛烈焰", text = "冰焰 Debuff"},
    ["ShellSpinNormal"]           = {group = "大副 技能", name = "旋殼擊 正常", text = "Bait"},
    ["ShellSpinScroll"]           = {group = "大副 技能", name = "旋殼擊 - 卷軸增強", text = "Bait"},
    ["ShellSpinTrader"]           = {group = "大副 技能", name = "旋殼擊 - 商人增強", text = "Bait"},
    ["MightyThud"]                = {group = "大副 技能", name = "分傷", text = "分傷"},
    ["Fish-Spawn"]                = {group = "商人 技能", name = "出魚", text = "出魚"},
    ["MushroomBait"]              = {group = "商人 技能", name = "蘑菇 Bait", text = "Bait"},
    ["ExplosiveSurprise"]         = {group = "商人 技能", name = "炸彈 Debuff", text = "炸彈"},
    ["MushroomJump"]              = {group = "商人 技能", name = "蘑菇彈跳", text = "跳"},
    ["TimeToThrow"]               = {group = "商人 技能", name = "丟魚時間", text = "丟魚"},
    ["TimeToThrowNonConditional"] = {group = "商人 技能", name = "無條件 丟魚時間", text = "丟魚"},
}

-- Sszorak (3420)
L[3420] = {
    ["TankCombo"]    = {group = "司佐拉", name = "坦克連擊", text = "坦克連擊"},
    ["SetMarkers"]   = {group = "司佐拉", name = "標記提醒", text = "標記"},
    ["DamageAmp"]    = {group = "司佐拉", name = "增傷", text = "增傷"},
    ["Bait"]         = {group = "司佐拉", name = "Bait", text = "Bait"},
    ["WindDebuffs"]  = {group = "司佐拉", name = "風 擊飛", text = "點擊飛"},
    ["Debuffs"]      = {group = "司佐拉", name = "放球", text = "放球"},
    ["SerpentsFury"] = {group = "司佐拉", name = "毒蛇之怒", text = "集中"},
    ["WindsHelper"]  = {group = "司佐拉", name = "吹風方向"},
    ["VenomousSurgeTargets"] = {group = "司佐拉", name = "點球名單"},
}

-- The Twin Fangs (3421)
L[3421] = {
    ["Defensives"]  = {group = "雙生毒牙", name = "個減", text = "個減"},
    ["Soak"]        = {group = "雙生毒牙", name = "分傷", text = "分傷"},
    ["Soak1"]       = {group = "雙生毒牙", name = "分傷1", text = "分傷1"},
    ["Soak2"]       = {group = "雙生毒牙", name = "分傷2", text = "分傷2"},
    ["Soak3"]       = {group = "雙生毒牙", name = "分傷3", text = "分傷3"},
    ["PreSpread"]   = {group = "雙生毒牙", name = "分散", text = "分散"},
    ["WatchSide"]   = {group = "雙生毒牙", name = "看左右邊", text = "看左右邊"},
    ["Adds"]        = {group = "雙生毒牙", name = "小怪", text = "小怪"},
    ["Orbs"]        = {group = "雙生毒牙", name = "球", text = "球"},
    ["TankSoak"]    = {group = "雙生毒牙", name = "坦克吃圈", text = "吃圈"},
    ["WatchSpawns"] = {group = "雙生毒牙", name = "碎石擊", text = "碎石擊"},
    ["Knock"]       = {group = "雙生毒牙", name = "擊退", text = "擊退"},
    ["DebuffOverview"] = {group = "雙生毒牙", name = "永恆毒液層數", text = "永恆毒液層數"},
    ["InterruptWhisperAlert"] = {group = "雙生毒牙", name = "打斷密語提醒", text = "打斷"},
}

-- The Coiled Altar (3429)
L[3429] = {
    ["P1Frontal"]     = {group = "盤蛇祭壇", name = "P1 劈刀", text = "劈刀"},
    ["P1OrbDeadline"] = {group = "盤蛇祭壇", name = "停止搬球", text = "停止搬球"},
    ["P1Taunt"]       = {group = "盤蛇祭壇", name = "P1 嘲諷", text = "嘲諷"},
    ["P1Soak"]        = {group = "盤蛇祭壇", name = "P1 分傷", text = "分傷"},
    ["MindControls"]  = {group = "盤蛇祭壇", name = "P2 心控", text = "心控"},
    ["P2Frontal"]     = {group = "盤蛇祭壇", name = "P2 劈刀", text = "劈刀"},
    ["P2Taunt"]       = {group = "盤蛇祭壇", name = "P2 嘲諷", text = "嘲諷"},
    ["P2Debuffs"]     = {group = "盤蛇祭壇", name = "P2 炸彈", text = "炸彈"},
    ["P2Shield"]      = {group = "盤蛇祭壇", name = "P2 盾", text = "P2 盾"},
    ["DebuffCircle"] = {group = "盤蛇祭壇", name = "放球", text = ""},
    ["EternalNightfallAbsorb"] = {group = "盤蛇祭壇", name = "吸收盾", text = ""},
    ["InterruptAdds"] = {group = "盤蛇祭壇", name = "P2 出小怪", text = "小怪"},
    ["InterruptAssignments"] = {group = "盤蛇祭壇", name = "打斷分配", text = "打斷"},
    ["P3OrbDeadline"] = {group = "盤蛇祭壇", name = "P3 停止搬球", text = "停止搬球"},
    ["P2_5WrongTarget"] = {group = "盤蛇祭壇", name = "打錯目標", text = "打錯目標"},
    ["P3Frontal"] = {group = "盤蛇祭壇", name = "P3 劈刀", text = "劈刀"},
    ["P3Soak"] = {group = "盤蛇祭壇", name = "P3 分傷", text = "分傷"},
    ["P3Shield"] = {group = "盤蛇祭壇", name = "P3 盾", text = "盾"},
    ["P3Debuffs"] = {group = "盤蛇祭壇", name = "P3 炸彈", text = "炸彈"},
    ["P3InterruptAdds"] = {group = "盤蛇祭壇", name = "P3 出小怪", text = "小怪"},
    ["P3MindControls"] = {group = "盤蛇祭壇", name = "P3 心控", text = "心控"},
    ["P3Taunt"] = {group = "盤蛇祭壇", name = "P3 嘲諷", text = "嘲諷"},
}

-- Ula'tek (3492)
L[3492] = {
    ["HitKnock"]            = {group = "烏拉特克", name = "蛇母之怒", text = "擊退"},
    ["Waves"]               = {group = "烏拉特克", name = "腐蝕波", text = "波"},
    ["DragOut"]             = {group = "烏拉特克", name = "Drag out", text = "Drag out"},
    ["DamageAmpIn"]         = {group = "烏拉特克", name = "劇毒心臟", text = "準備增傷"},
    ["DamageAmp"]           = {group = "烏拉特克", name = "劇毒心臟", text = "增傷"},
    ["PlatformBreak"]       = {group = "烏拉特克", name = "包圍獵物", text = "平台裂開"},
    ["Debuffs"]             = {group = "烏拉特克", name = "毒蛇之咬", text = "Debuff"},
    ["Eggs"]                = {group = "烏拉特克", name = "蛋", text = "蛋"},
    ["EggDeadline"]         = {group = "烏拉特克", name = "Egg Deadline", text = "Egg Deadline"},
    ["AddSoak"]             = {group = "烏拉特克", name = "Add Soak", text = "Add Soak"},
    ["Adds"]                = {group = "烏拉特克", name = "P3 小怪", text = "小怪"},
    ["BossSpawn"]           = {group = "烏拉特克", name = "王出現", text = "王出現"},
    ["FirstBreak"]          = {group = "烏拉特克", name = "拉斷1", text = "拉斷1"},
    ["SecondBreak"]         = {group = "烏拉特克", name = "拉斷2", text = "拉斷2"},
    ["FirstGate"]           = {group = "烏拉特克", name = "點門1", text = "點門"},
    ["SecondGate"]          = {group = "烏拉特克", name = "點門2", text = "點門"},
    ["Sweep"]               = {group = "烏拉特克", name = "大圈", text = "大圈"},
    ["Soak"]                = {group = "烏拉特克", name = "分傷", text = "分傷"},
    ["TransitionSoakFirst"] = {group = "烏拉特克", name = "分傷1", text = "分傷1"},
    ["TransitionSoakSecond"] = {group = "烏拉特克", name = "分傷2", text = "分傷2"},
    ["GraspingFangsOverview"] = {group = "烏拉特克", name = "攫取毒牙總覽", text = ""},
    ["WrongTarget"] = {group = "烏拉特克", name = "打錯目標", text = "打錯目標"},
    ["WaveDirection"] = {group = "烏拉特克", name = "波左右方向", text = ""},
    ["InterruptAssignments"] = {group = "烏拉特克", name = "打斷分配", text = "打斷"},
    ["WaveDirection"] = {group = "烏拉特克", name = "波浪方向顯示", text = ""},
    ["WaveDirectionPrompt"] = {group = "烏拉特克", name = "波浪方向輸入", text = "方向巨集"},
    ["InterruptAssignments"] = {group = "烏拉特克", name = "打斷分配", text = "打斷"},
    ["TransitionPatternSoaks"] = {group = "烏拉特克", name = "轉階分傷", text = "分傷"},
    ["PrePot"] = {group = "烏拉特克", name = "喝爆發", text = "喝爆發"},
    ["AutoRelease"] = {group = "烏拉特克", name = "自動放魂", text = "自動放魂"},
}

-- Kith'ix (3513)
L[3513] = {
    ["DarkDevastation"] = {group = "克希斯", name = "打坦技", text = "打坦技"},
    ["Taunt"]           = {group = "克希斯", name = "嘲諷", text = "嘲諷"},
    ["AoE"]             = {group = "克希斯", name = "AoE", text = "撿球"},
    ["Darkness"]        = {group = "克希斯", name = "黑暗", text = "黑暗"},
    ["Adds"]            = {group = "克希斯", name = "小怪", text = "小怪"},
}
