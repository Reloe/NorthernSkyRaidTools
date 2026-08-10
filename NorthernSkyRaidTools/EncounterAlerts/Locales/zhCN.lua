local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["zhCN"] = L

-- ============================================================================
-- MidnightS1
-- ============================================================================
-- Imperator Averzian (3176)
L[3176] = {
    ["Soaks"] = {text = "分摊", name = "幽影坍缩（分摊）"},
}

-- Vorasius (3177)
L[3177] = {
    ["Knock"] = {text = "击退", name = "始源咆哮（击退）"},
    ["Breath"] = {text = "吐息", name = "虚空吐息"},
}

-- Fallen-King Salhadaar (3179)
L[3179] = {
    ["Beams"] = {text = "射线", name = "熵能瓦解"},
    ["Orbs"] = {text = "宝珠刷新", name = "虚空融合（宝珠）"},
    ["CC Adds"] = {text = "控制小怪", name = "破碎投影（控制）"},
    ["CC Display"] = {name = "控制显示（姓名板）"},
}

-- Vaelgor & Ezzorak (3178)
L[3178] = {
    ["Spread"] = {text = "分散", name = "虚空嚎叫（分散）"},
    ["Tether"] = {text = "锁链", name = "虚界（锁链）"},
    ["Breath"] = {text = "恐惧吐息", name = "亡者吐息（恐惧）"},
    ["HealthDisplay"] = {name = "生命值对比"},
}

-- Lightblinded Vanguard (3180)
L[3180] = {
    ["Sacred Toll"] = {text = "全团伤害", name = "神圣鸣罪（AoE）"},
    ["Heal Absorb Ticks"] = {name = "治疗吸收（分段）"},
    ["Peace Aura"] = {text = "平心光环", name = "平心光环", group = "圣骑士光环"},
    ["Devotion Aura"] = {text = "虔诚光环", name = "虔诚光环", group = "圣骑士光环"},
    ["Aura of Wrath"] = {text = "愤怒光环", name = "愤怒光环", group = "圣骑士光环"},
    ["TauntAlerts"] = {text = "嘲讽", name = "嘲讽提示（姓名板）"},
}

-- Crown of the Cosmos (3181)
L[3181] = {
    ["Stop Cast"] = {text = "停止施法", name = "干扰震荡（断条）", group = "奥蕾莉亚 P1"},
    ["Ranged Obelisk"] = {text = "方尖碑", name = "空虚之握（远程）", group = "奥蕾莉亚 P1"},
    ["Ranged Obelisk_P1"] = {text = "方尖碑", name = "空虚之握（远程）", group = "奥蕾莉亚 P1"},
    ["Ranged Obelisk_P3"] = {text = "方尖碑", name = "空虚之握（远程）", group = "奥蕾莉亚 P2"},
    ["Ranged Obelisk_P5"] = {text = "方尖碑", name = "空虚之握（远程）", group = "奥蕾莉亚 P3"},
    ["Melee Obelisk"] = {text = "方尖碑", name = "空虚之握（近战）", group = "奥蕾莉亚 P1"},
    ["Melee Obelisk_P1"] = {text = "方尖碑", name = "空虚之握（近战）", group = "奥蕾莉亚 P1"},
    ["Melee Obelisk_P3"] = {text = "方尖碑", name = "空虚之握（近战）", group = "奥蕾莉亚 P2"},
    ["Melee Obelisk_P5"] = {text = "方尖碑", name = "空虚之握（近战）", group = "奥蕾莉亚 P3"},
    ["Bait"] = {text = "引水", name = "虚空斥力（引诱）", group = "奥蕾莉亚 P1"},
    ["Bait_P1"] = {text = "引水", name = "虚空斥力（引诱）", group = "奥蕾莉亚 P1"},
    ["Bait_P3"] = {text = "引水", name = "虚空斥力（引诱）", group = "奥蕾莉亚 P2"},
    ["Bait_P5"] = {text = "引水", name = "虚空斥力（引诱）", group = "奥蕾莉亚 P3"},
    ["Arrows"] = {text = "银锋箭", name = "银锋箭", group = "奥蕾莉亚 P1"},
    ["Explosion"] = {text = "爆炸", name = "爆炸", group = "奥蕾莉亚 P1"},
    ["Explosion_P1"] = {text = "爆炸", name = "爆炸", group = "奥蕾莉亚 P1"},
    ["Explosion_P3"] = {text = "爆炸", name = "爆炸", group = "奥蕾莉亚 P2"},
    ["Explosion_P5"] = {text = "爆炸", name = "爆炸", group = "奥蕾莉亚 P3"},
    ["Boss-Immune"] = {text = "免疫", name = "首领免疫"},
    ["Tether"] = {text = "锁链", name = "终末守护（锁链）", group = "奥蕾莉亚 P3"},
}

-- Chimaerus (3306)
L[3306] = {
    ["Debuffs_P1"] = {text = "点名救人", name = "裂隙疯狂（点名）"},
    ["Debuffs_P2"] = {text = "点名救人", name = "裂隙疯狂（点名）"},
}

-- Belo'ren (3182)
L[3182] = {
    ["Gateway_P2"] = {text = "传送门", name = "传送门", group = "贝洛朗 P1"},
    ["Gateway_P3"] = {text = "传送门", name = "传送门", group = "贝洛朗 P2"},
    ["Next Hit_P2"] = {text = "下次爆发", name = "爆发倒计时", group = "贝洛朗 P1"},
    ["Next Hit_P3"] = {text = "下次爆发", name = "爆发倒计时", group = "贝洛朗 P2"},
    ["Soaks_P1"] = {text = "分摊", name = "俯冲（分摊）", group = "贝洛朗 P1"},
    ["Soaks_P2"] = {text = "分摊", name = "俯冲（分摊）", group = "贝洛朗 P2"},
    ["Quills_P1"] = {text = "挡线", name = "注能飞羽（挡线）", group = "贝洛朗 P1"},
    ["Quills_P2"] = {text = "挡线", name = "注能飞羽（挡线）", group = "贝洛朗 P2"},
    ["Feather Color"] = {name = "羽毛颜色"},
    ["Color Swap"] = {text = "颜色交换", name = "虚光汇流（换色）"},
}

-- Midnight Falls (3183)
L[3183] = {
    ["MemoryGame"] = {text = "记忆游戏", name = "记忆游戏", group = "鲁拉 P1"},
    ["Glaives"] = {text = "战刃", name = "天穹战刃", group = "鲁拉 P1"},
    ["Interrupts"] = {text = "打断", name = "终结棱柱（打断）", group = "鲁拉 P1"},
    ["Beams"] = {text = "射线", name = "黑暗类星体", group = "鲁拉 P1"},
    ["Transition Beams"] = {text = "射线", name = "黑暗类星体", group = "鲁拉 P1 阶段转换"},
    ["Lura Tank-Hits_P1"] = {text = "坦克打击", name = "P1 天穹之枪（坦克）", group = "鲁拉 坦克"},
    ["Lura Tank-Hits_P3"] = {text = "坦克打击", name = "P2 天穹之枪（坦克）", group = "鲁拉 坦克"},
    ["Lura Tank-Hits_P4"] = {text = "坦克打击", name = "P3 天穹之枪（坦克）", group = "鲁拉 坦克"},
    ["Lura Taunts_P1"] = {text = "嘲讽", name = "P1 嘲讽", group = "鲁拉 坦克"},
    ["Lura Taunts_P3"] = {text = "嘲讽", name = "P3 嘲讽", group = "鲁拉 坦克"},
    ["Full Blaze"] = {text = "全团裂片", name = "星辰裂片（全团）", group = "鲁拉 P1 阶段转换"},
    ["Seed-Drop"] = {text = "丢下水晶", name = "丢下水晶", group = "鲁拉 P2"},
    ["Old-Seed-Drop"] = {text = "丢下水晶", name = "丢下水晶（无条件）", group = "鲁拉 P2"},
    ["Galvanize"] = {text = "分摊", name = "充电（通用分摊）", group = "鲁拉 P2 分摊"},
    ["Soak Star"] = {text = "分摊 {rt1}", name = "充电（星星分摊）", group = "鲁拉 P2 分摊"},
    ["Soak Orange"] = {text = "分摊 {rt2}", name = "充电（橙圈分摊）", group = "鲁拉 P2 分摊"},
    ["Soak Skull"] = {text = "分摊 {rt8}", name = "充电（骷髅分摊）", group = "鲁拉 P2 分摊"},
    ["Soak Cross"] = {text = "分摊 {rt7}", name = "充电（红叉分摊）", group = "鲁拉 P2 分摊"},
    ["Spread"] = {text = "分散", name = "临界状态（分散）", group = "鲁拉 P2"},
    ["Orbs"] = {text = "核心收割", name = "核心收割", group = "鲁拉 P2"},
    ["HC Soaks"] = {text = "吸圈", name = "圣光虹吸（吸圈）", group = "鲁拉 P3"},
    ["Move"] = {text = "移动", name = "移动", group = "鲁拉 P3"},
    ["Left Memory Game"] = {text = "记忆游戏", name = "记忆游戏（左侧）", group = "鲁拉 P3 左侧"},
    ["Right Memory Game"] = {text = "记忆游戏", name = "记忆游戏（右侧）", group = "鲁拉 P3 右侧"},
    ["Left Soaks"] = {text = "吸圈", name = "圣光虹吸（左侧吸圈）", group = "鲁拉 P3 左侧"},
    ["Right Soaks"] = {text = "吸圈", name = "圣光虹吸（右侧吸圈）", group = "鲁拉 P3 右侧"},
    ["Left Soak-Time"] = {text = "吸圈倒计时", name = "吸圈倒计时（左侧）", group = "鲁拉 P3 左侧"},
    ["Right Soak-Time"] = {text = "吸圈倒计时", name = "吸圈倒计时（右侧）", group = "鲁拉 P3 右侧"},
    ["Left Stars"] = {text = "星座", name = "黑暗符文（左侧星座）", group = "鲁拉 P3 左侧"},
    ["Right Stars"] = {text = "星座", name = "黑暗符文（右侧星座）", group = "鲁拉 P3 右侧"},
    ["Final Slice Stars"] = {text = "星座", name = "黑暗符文（最后星座）", group = "鲁拉 P3"},
    ["Blazes"] = {text = "裂片", name = "星辰裂片", group = "鲁拉 P4"},
    ["P4 Move"] = {text = "移动", name = "P4 移动", group = "鲁拉 P4"},
    ["CrystalDropTimer"] = {text = "拾取水晶", name = "拾取水晶倒计时"},
    ["RunesDisplay"] = {name = "符文显示"},
    ["InterruptDisplay"] = {name = "打断显示"},
}

-- Rotmire (3159)
L[3159] = {
    ["Adds"] = {text = "小怪刷新", name = "唤醒真菌（小怪）"},
    ["Shrooms"] = {text = "蘑菇刷新", name = "真菌绽放（蘑菇）"},
    ["BurstingPustules"] = {text = "全团伤害", name = "脓包破裂（AoE）"},
    ["InterruptDisplay"] = {name = "打断显示"},
    ["Taunts"] = {text = "嘲讽", name = "嘲讽", group = "腐沼 坦克"},
    ["Tankhits"] = {text = "坦克打击", name = "腐烂之拳（坦克）", group = "腐沼 坦克"},
}

-- ============================================================================
-- MidnightS2
-- ============================================================================
-- Nymrissa Wavecaller (3379)
L[3379] = {
}

-- Nek'zali the Soulcoiler (3470)
L[3470] = {
    ["Barrage"] = {text = "正面弹幕", name = "附身弹幕", group = "内克扎莉"},
    ["Debuffs"] = {text = "点名驱散", name = "精华撕裂（点名）", group = "内克扎莉"},
    ["SoulcoilIgnition"] = {text = "全团伤害", name = "盘魂点燃（AoE）", group = "内克扎莉"},
    ["HungeringPyre"] = {text = "分摊", name = "噬灭烈焰（分摊）", group = "内克扎莉"},
    ["RestlessAmani"] = {text = "小怪刷新", name = "无眠的阿曼尼（小怪）", group = "内克扎莉"},
    ["Invoke"] = {text = "躲避", name = "祈求", group = "内克扎莉"},
    ["InvokeMythic"] = {text = "停止施法", name = "祈求（断条）", group = "内克扎莉"},
}

-- Entombed Sentinels (3445)
L[3445] = {
    ["PoisonHits"] = {text = "坦克打击", name = "强化猛击（坦克）", group = "哨兵"},
    ["BloodHits"] = {text = "坦克打击", name = "鲜血毒液注射（坦克）", group = "哨兵"},
    ["BloodDropPool"] = {text = "鲜血放水", name = "鲜血毒液（放水）", group = "哨兵"},
    ["BloodSoak"] = {text = "鲜血分摊", name = "不稳定的瘴气（分摊）", group = "哨兵"},
    ["BloodDispels"] = {text = "鲜血驱散", name = "凋零之血（驱散）", group = "哨兵"},
    ["PoisonAdd"] = {text = "毒液小怪刷新", name = "毒液凝块（小怪）", group = "哨兵"},
    ["OrbSpawn"] = {text = "引水滴", name = "剧毒水滴（引诱）", group = "哨兵"},
    ["ShiftingProtovenom"] = {text = "分散", name = "变幻的原型毒液（分散）", group = "哨兵"},
    ["TransitionDebuffs"] = {text = "数字星座", name = "螺旋毒素（星座）", group = "哨兵"},
}

-- Vashnik the Malignant (3455)
L[3455] = {
    ["TankHits"] = {text = "坦克打击", name = "滴毒之牙（坦克）", group = "瓦什尼克"},
    ["Taunts"] = {text = "嘲讽", name = "嘲讽", group = "瓦什尼克"},
    ["Adds"] = {text = "小怪刷新", name = "痛饮（小怪）", group = "瓦什尼克"},
    ["Infection"] = {text = "点名感染", name = "适应性感染（点名）", group = "瓦什尼克"},
    ["AoE"] = {text = "全团伤害", name = "恶性催化剂（AOE）", group = "瓦什尼克"},
    ["Soaks"] = {text = "踩圈", name = "催化胆汁（踩圈）", group = "瓦什尼克"},
    ["WaveSpread"] = {text = "预分散", name = "瘟疫泡沫（分散）", group = "瓦什尼克"},
    ["Waves"] = {text = "波浪", name = "瘟疫浪潮", group = "瓦什尼克"},
}

-- The Lost Explorers (3497)
L[3497] = {
    ["ShreddingShards"] = {text = "坦克打击", name = "撕裂碎片（坦克）", group = "书卷贤者技能"},
    ["BlinkNova"] = {text = "点名远离", name = "闪现新星（点名）", group = "书卷贤者技能"},
    ["FrostfireVolley"] = {text = "点名放圈", name = "霜火连射（点名）", group = "书卷贤者技能"},
    ["ShellSpinNormal"] = {text = "引龟壳", name = "旋壳（引诱）", group = "大副技能"},
    ["ShellSpinScroll"] = {text = "引龟壳", name = "旋壳（书卷强化）", group = "大副技能"},
    ["ShellSpinTrader"] = {text = "引龟壳", name = "旋壳（商人强化）", group = "大副技能"},
    ["MightyThud"] = {text = "分摊", name = "巨力重击（分摊）", group = "大副技能"},
    ["Fish-Spawn"] = {text = "鱼刷新", name = "投掷垃圾（鱼）", group = "商人技能"},
    ["MushroomBait"] = {text = "引蘑菇", name = "蘑菇投掷（引诱）", group = "商人技能"},
    ["ExplosiveSurprise"] = {text = "点名炸弹", name = "爆炸惊喜（点名）", group = "商人技能"},
    ["MushroomJump"] = {text = "踩蘑菇", name = "弹跳蘑菇", group = "商人技能"},
    ["TimeToThrow"] = {text = "扔鱼", name = "扔鱼倒计时", group = "商人技能"},
    ["TimeToThrowNonConditional"] = {text = "扔鱼", name = "扔鱼倒计时（无条件）", group = "商人技能"},
}

-- Sszorak (3420)
L[3420] = {
    ["TankCombo"] = {text = "坦克连击", name = "顶级掠食者（坦克）", group = "斯索拉克"},
    ["DamageAmp"] = {text = "易伤", name = "掘地固守（易伤）", group = "斯索拉克"},
    ["Bait"] = {text = "引水", name = "剧毒涌动（引诱）", group = "斯索拉克"},
    ["WindDebuffs"] = {text = "点名狂风", name = "狂怒侧风（点名）", group = "斯索拉克"},
    ["Debuffs"] = {text = "点名囊肿", name = "剧毒涌动（点名）", group = "斯索拉克"},
    ["SerpentsFury"] = {text = "集合", name = "毒蛇之怒（集合）", group = "斯索拉克"},
    ["WindsHelper"] = {name = "狂风助手", group = "斯索拉克"},
}

-- The Twin Fangs (3421)
L[3421] = {
    ["Defensives"] = {text = "减伤", name = "搅动深渊（减伤）", group = "双子毒牙"},
    ["Soak"] = {text = "分摊", name = "贪婪盛宴（分摊）", group = "双子毒牙"},
    ["PreSpread"] = {text = "预分散", name = "盘卷脓液（分散）", group = "双子毒牙"},
    ["WatchSide"] = {text = "观察方向", name = "邪恶洪流（观察）", group = "双子毒牙"},
    ["Adds"] = {text = "小怪刷新", name = "剧毒涌现（小怪）", group = "双子毒牙"},
    ["Orbs"] = {text = "吃球", name = "腐蚀洪流（吃球）", group = "双子毒牙"},
    ["TankSoak"] = {text = "踩圈", name = "碎石击（坦克踩圈）", group = "双子毒牙"},
    ["WatchSpawns"] = {text = "观察顺序", name = "碎石击（观察）", group = "双子毒牙"},
    ["Knock"] = {text = "击退", name = "腐蚀洪流（击退）", group = "双子毒牙"},
}

-- The Coiled Altar (3429)
L[3429] = {
    ["P1Frontal"] = {text = "正面顺劈", name = "撕裂", group = "盘卷祭坛 P1"},
    ["P1Taunt"] = {text = "嘲讽", name = "P1 嘲讽", group = "盘卷祭坛 坦克"},
    ["P1Soak"] = {text = "分摊", name = "处斩（分摊）", group = "盘卷祭坛 P1"},
    ["MindControls"] = {text = "心控", name = "恐惧行军（心控）", group = "盘卷祭坛 P2"},
    ["P2Frontal"] = {text = "正面顺劈", name = "灵魂撕裂", group = "盘卷祭坛 P2"},
    ["P2Taunt"] = {text = "嘲讽", name = "P2 嘲讽", group = "盘卷祭坛 坦克"},
    ["P2Debuffs"] = {text = "点名炸弹", name = "幽暗炸弹（点名）", group = "盘卷祭坛 P2"},
    ["P2Shield"] = {text = "破盾", name = "永恒夜幕（破盾）", group = "盘卷祭坛 P2"},
    ["InterruptAdds"] = {text = "精魂", name = "恐惧哀嚎（打断）", group = "盘卷祭坛 P2"},
}

-- Ula'tek (3492)
L[3492] = {
    --[[
    ["TankHits"] = {text = "坦克打击", name = "蛇母之怒（坦克）", group = "乌拉特克 坦克"},
    ["Taunt"] = {text = "嘲讽", name = "嘲讽", group = "乌拉特克 坦克"},
    ["Waves"] = {text = "波浪", name = "腐蚀浪潮", group = "乌拉特克"},
    ["Adds"] = {text = "小怪刷新", name = "腐蚀浪潮（小怪）", group = "乌拉特克"},
    ["DamageAmpIn"] = {text = "准备易伤", name = "被缚之怒（易伤）", group = "乌拉特克"},
    ["DamageAmp"] = {text = "易伤", name = "易伤倒计时", group = "乌拉特克"},
    ["PlatformBreak"] = {text = "摧毁平台+击退", name = "盘绕猎物（平台）", group = "乌拉特克 P3"},
    ["Debuffs"] = {text = "点名毒液", name = "毒蛇之咬（点名）", group = "乌拉特克 P3"},
    ]]
}
