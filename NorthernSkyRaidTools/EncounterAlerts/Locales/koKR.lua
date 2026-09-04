-- Credit by Elarfim
local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["koKR"] = L

-- ============================================================================
-- MidnightS1
-- ============================================================================
-- Imperator Averzian (3176)
L[3176] = {
    ["Soaks"] = {name = "스킬 맞기", text = "스킬 맞기"},
}

-- Vorasius (3177)
L[3177] = {
    ["Knock"] = {name = "넉백", text = "넉백"},
    ["Breath"] = {name = "브레스", text = "브레스"},
}

-- Fallen King Salhadaar (3179)
L[3179] = {
    ["Beams"]       = {name = "레이저", text = "레이저"},
    ["Orbs"]        = {name = "구슬", text = "구슬"},
    ["CC Adds"]     = {name = "쫄 메즈", text = "쫄 메즈"},
    ["CC Display"] = {name = "메즈 현황"},
}

-- Vaelgor & Ezzorak (3178)
L[3178] = {
    ["Spread"]      = {name = "산개", text = "산개"},
    ["Tether"]      = {name = "사슬", text = "사슬"},
    ["Breath"]      = {name = "브레스", text = "브레스"},
    ["HealthDisplay"] = {name = "생명력 현황"},
}

-- Lightblinded Vanguard (3180)
L[3180] = {
    ["Sacred Toll"]     = {name = "신성한 종", text = "신성한 종"},
    ["Heal Absorb Ticks"] = {name = "치유 흡수 틱"},
    ["Peace Aura"]      = {group = "성기사 오라", name = "평화의 오라", text = "평화의 오라"},
    ["Devotion Aura"]   = {group = "성기사 오라", name = "헌신의 오라", text = "헌신의 오라"},
    ["Aura of Wrath"]   = {group = "성기사 오라", name = "진노의 오라", text = "진노의 오라"},
    ["TauntAlerts"]     = {name = "도발 알림", text = "도발"},
}

-- Crown of the Cosmos (3181)
L[3181] = {
    ["Stop Cast"]       = {group = "알레리아 1페", name = "시전 중지", text = "시전 중지"},
    ["Ranged Obelisk_P1"] = {group = "알레리아 1페", name = "원거리 방첨탑", text = "방첨탑"},
    ["Ranged Obelisk_P3"] = {group = "알레리아 2페", name = "원거리 방첨탑", text = "방첨탑"},
    ["Ranged Obelisk_P5"] = {group = "알레리아 3페", name = "원거리 방첨탑", text = "방첨탑"},
    ["Melee Obelisk_P1"] = {group = "알레리아 1페", name = "근접 방첨탑", text = "방첨탑"},
    ["Melee Obelisk_P3"] = {group = "알레리아 2페", name = "근접 방첨탑", text = "방첨탑"},
    ["Melee Obelisk_P5"] = {group = "알레리아 3페", name = "근접 방첨탑", text = "방첨탑"},
    ["Bait_P1"]         = {group = "알레리아 1페", name = "유도", text = "유도"},
    ["Bait_P3"]         = {group = "알레리아 2페", name = "유도", text = "유도"},
    ["Bait_P5"]         = {group = "알레리아 3페", name = "유도", text = "유도"},
    ["Arrows"]          = {group = "알레리아 1페", name = "화살", text = "화살"},
    ["Explosion_P1"]    = {group = "알레리아 1페", name = "폭발", text = "폭발"},
    ["Explosion_P3"]    = {group = "알레리아 2페", name = "폭발", text = "폭발"},
    ["Explosion_P5"]    = {group = "알레리아 3페", name = "폭발", text = "폭발"},
    ["Boss-Immune"]     = {name = "보스 무적", text = "무적"},
    ["Tether"]          = {group = "알레리아 3페", name = "사슬", text = "사슬"},
}

-- Chimaerus (3306)
L[3306] = {
    ["Debuffs_P1"] = {name = "디버프", text = "디버프"},
    ["Debuffs_P2"] = {name = "디버프", text = "디버프"},
}

-- Belo'ren (3182)
L[3182] = {
    ["Feather Color"] = {name = "깃털색"},
    ["Color Swap"]      = {name = "색 교체", text = "색 교체"},
    ["Gateway_P2"]      = {group = "벨로렌 1페", name = "관문", text = "관문"},
    ["Gateway_P3"]      = {group = "벨로렌 2페", name = "관문", text = "관문"},
    ["Next Hit_P2"]     = {group = "벨로렌 1페", name = "다음 바닥", text = "다음 바닥"},
    ["Next Hit_P3"]     = {group = "벨로렌 2페", name = "다음 바닥", text = "다음 바닥"},
    ["Soaks_P1"]        = {group = "벨로렌 1페", name = "스킬 맞기", text = "스킬 맞기"},
    ["Soaks_P2"]        = {group = "벨로렌 2페", name = "스킬 맞기", text = "스킬 맞기"},
    ["Quills_P1"]       = {group = "벨로렌 1페", name = "깃털", text = "깃털"},
    ["Quills_P2"]       = {group = "벨로렌 2페", name = "깃털", text = "깃털"},
}

-- Midnight Falls (3183)
L[3183] = {
    ["MemoryGame"]              = {group = "르우라 1페", name = "메모리 게임", text = "메모리 게임"},
    ["Glaives"]                 = {group = "르우라 1페", name = "글레이브", text = "글레이브"},
    ["Interrupts"]              = {group = "르우라 1페", name = "차단", text = "차단"},
    ["Beams"]                   = {group = "르우라 1페", name = "레이저", text = "레이저"},
    ["Transition Beams"]        = {group = "르우라 1사이페", name = "레이저", text = "레이저"},
    ["Lura Tank-Hits_P1"]       = {group = "르우라 탱커", name = "1페 탱커 공격", text = "탱커 공격"},
    ["Lura Tank-Hits_P3"]       = {group = "르우라 탱커", name = "2페 탱커 공격", text = "탱커 공격"},
    ["Lura Tank-Hits_P4"]       = {group = "르우라 탱커", name = "3페 탱커 공격", text = "탱커 공격"},
    ["Lura Taunts_P1"]          = {group = "르우라 탱커", name = "1페 도발", text = "도발"},
    ["Lura Taunts_P3"]          = {group = "르우라 탱커", name = "2페 도발", text = "도발"},
    ["Full Blaze"]              = {group = "르우라 1사이페", name = "전원 가시", text = "전원 가시"},
    ["Seed-Drop"]               = {group = "르우라 2페", name = "수정 떨구기", text = "수정 떨구기"},
    ["Old-Seed-Drop"]           = {group = "르우라 2페", name = "무조건 수정 떨구기", text = "수정 떨구기"},
    ["Galvanize"]               = {group = "르우라 2페 바닥 맞기", name = "일반 바닥 맞기", text = "바닥 맞기"},
    ["Soak Star"]               = {group = "르우라 2페 바닥 맞기", name = "별 맞기", text = "{rt1} 맞기"},
    ["Soak Orange"]             = {group = "르우라 2페 바닥 맞기", name = "동글 맞기", text = "{rt2} 맞기"},
    ["Soak Skull"]              = {group = "르우라 2페 바닥 맞기", name = "해골 맞기", text = "{rt8} 맞기"},
    ["Soak Cross"]              = {group = "르우라 2페 바닥 맞기", name = "엑스 맞기", text = "{rt7} 맞기"},
    ["Spread"]                  = {group = "르우라 2페", name = "산개", text = "산개"},
    ["Orbs"]                    = {group = "르우라 2페", name = "구슬", text = "구슬"},
    ["HC Soaks"]                = {group = "르우라 3페", name = "바닥 흡수", text = "바닥 흡수"},
    ["Move"]                    = {group = "르우라 3페", name = "이동", text = "이동"},
    ["Left Memory Game"]        = {group = "르우라 3페 왼쪽", name = "왼쪽 메모리 게임", text = "메모리 게임"},
    ["Right Memory Game"]       = {group = "르우라 3페 오른쪽", name = "오른쪽 메모리 게임", text = "메모리 게임"},
    ["Left Soaks"]              = {group = "르우라 3페 왼쪽", name = "왼쪽 바닥 흡수", text = "바닥 흡수"},
    ["Right Soaks"]             = {group = "르우라 3페 오른쪽", name = "오른쪽 바닥 흡수", text = "바닥 흡수"},
    ["Left Soak-Time"]          = {group = "르우라 3페 왼쪽", name = "왼쪽 흡수 남은 시간", text = "흡수 남은 시간"},
    ["Right Soak-Time"]         = {group = "르우라 3페 오른쪽", name = "오른쪽 흡수 남은 시간", text = "흡수 남은 시간"},
    ["Left Stars"]              = {group = "르우라 3페 왼쪽", name = "왼쪽 별자리", text = "별자리"},
    ["Right Stars"]             = {group = "르우라 3페 오른쪽", name = "오른쪽 별자리", text = "별자리"},
    ["Final Slice Stars"]       = {group = "르우라 3페", name = "마지막 별자리", text = "별자리"},
    ["Blazes"]                  = {group = "르우라 4페", name = "별빛파열", text = "좌우좌"},
    ["P4 Move"]                 = {group = "르우라 4페", name = "4페 이동", text = "이동"},
    ["CrystalDropTimer"]        = {name = "수정 줍기 시간", text = "수정 줍기"},
    ["RunesDisplay"]            = {name = "룬 표시"},
    ["InterruptDisplay"]        = {name = "차단 표시"},
}

-- Rotmire (3159)
L[3159] = {
    ["Adds"]            = {name = "쫄", text = "쫄"},
    ["Shrooms"]         = {name = "버섯", text = "버섯"},
    ["BurstingPustules"] = {name = "광역뎀", text = "광역뎀"},
    ["InterruptDisplay"] = {name = "차단 현황"},
    ["Taunts"]          = {group = "부식수렁 탱커", name = "도발", text = "도발"},
    ["Tankhits"]        = {group = "부식수렁 탱커", name = "탱커 공격", text = "탱커 공격"},
}

-- ============================================================================
-- MidnightS2
-- ============================================================================
-- Nymrissa Wavecaller (3379)
L[3379] = {
    ["Adds"]          = {group = "님리사", name = "쫄 등장", text = "쫄"},
    ["Waves"]         = {group = "님리사", name = "물결", text = "물결"},
    ["Knockback"]     = {group = "님리사", name = "넉백", text = "넉백"},
    ["ChillingFrost"] = {group = "님리사", name = "오싹한 서리", text = "디버프"},
    ["AbyssalRain"]   = {group = "님리사", name = "심연의 비", text = "광역뎀"},
    ["WaterJet"]      = {group = "님리사", name = "물 분출", text = "전방스킬"},
    ["WaterFlurry"]   = {group = "님리사", name = "질풍의 얼음칼날", text = "탱커 공격"},
    ["Taunt"]         = {group = "님리사", name = "도발", text = "도발"},
}

-- Nek'zali the Soulcoiler (3470)
L[3470] = {
    ["Barrage"]             = {group = "네크잘리", name = "포화", text = "전방스킬"},
    ["Debuffs"]             = {group = "네크잘리", name = "정수 분쇄", text = "디버프"},
    ["SoulcoilIgnition"]    = {group = "네크잘리", name = "영혼똬리 점화", text = "광역뎀"},
    ["HungeringPyre"]       = {group = "네크잘리", name = "굶주린 장작더미", text = "스킬 맞기"},
    ["RestlessAmani"]       = {group = "네크잘리", name = "쫄 등장", text = "쫄"},
    ["Invoke"]              = {group = "네크잘리", name = "기원", text = "피하기"},
    ["InvokeMythic"]        = {group = "네크잘리", name = "기원", text = "시전 중지"},
}

-- Entombed Sentinels (3445)
L[3445] = {
    ["PoisonHits"]      = {group = "파수꾼", name = "독 탱커 공격", text = "탱커 공격"},
    ["BloodHits"]       = {group = "파수꾼", name = "피 탱커 공격", text = "탱커 공격"},
    ["BloodDropPool"]   = {group = "파수꾼", name = "탱커 바닥 깔림", text = "바닥 깔림"},
    ["BloodSoak"]       = {group = "파수꾼", name = "피 같이맞기", text = "피 같이맞기"},
    ["BloodSoakPool"]   = {group = "파수꾼", name = "같이맞고 바닥 깔림", text = "바닥 깔림"},
    ["BloodDispels"]    = {group = "파수꾼", name = "피 해제", text = "해제"},
    ["PoisonAdd"]       = {group = "파수꾼", name = "독 쫄", text = "독 쫄"},
    ["OrbSpawn"]        = {group = "파수꾼", name = "구슬 나옴", text = "구슬 유도"},
    ["ShiftingProtovenom"] = {group = "파수꾼", name = "변화무쌍한 원시맹독", text = "산개"},
    ["TransitionDebuffs"] = {group = "파수꾼", name = "사이페 디버프", text = "숫자 게임"},
    ["Radar"]            = {group = "파수꾼", name = "레이더", text = ""},
}

-- Vashnik the Malignant (3455)
L[3455] = {
    ["TankHits"]    = {group = "바쉬니크", name = "탱커 공격", text = "탱커 공격"},
    ["Taunts"]      = {group = "바쉬니크", name = "도발", text = "도발"},
    ["Adds"]        = {group = "바쉬니크", name = "쫄", text = "쫄"},
    ["Infection"]   = {group = "바쉬니크", name = "감염", text = "감염"},
    ["AoE"]         = {group = "바쉬니크", name = "광역뎀", text = "광역뎀"},
    ["Soaks"]       = {group = "바쉬니크", name = "바닥 맞기", text = "바닥 맞기"},
    ["Waves"]       = {group = "바쉬니크", name = "물결", text = "물결"},
    ["WaveSpread"] = {group = "바쉬니크", name = "물결 산개", text = "미리 산개"},
    ["WavesLine"] = {group = "바쉬니크", name = "물결 선 표시", text = ""},
}

-- The Lost Explorers (3497)
L[3497] = {
    ["ShreddingShards"]         = {group = "두루마리현자 스킬", name = "탱커 공격", text = "탱커 공격"},
    ["BlinkNova"]               = {group = "두루마리현자 스킬", name = "점멸 회오리", text = "점멸 회오리"},
    ["FrostfireVolley"]         = {group = "두루마리현자 스킬", name = "서리불꽃 연사", text = "서리불꽃 디버프"},
    ["ShellSpinNormal"]         = {group = "일등항해사 스킬", name = "등껍질 회전 일반", text = "유도"},
    ["ShellSpinScroll"]         = {group = "일등항해사 스킬", name = "등껍질 회전 - 두루마리 강화됨", text = "유도"},
    ["ShellSpinTrader"]         = {group = "일등항해사 스킬", name = "등껍질 회전 - 무역상 강화됨", text = "유도"},
    ["MightyThud"]              = {group = "일등항해사 스킬", name = "같이맞기", text = "같이맞기"},
    ["Fish-Spawn"]              = {group = "무역상 스킬", name = "물고기 나옴", text = "물고기 나옴"},
    ["MushroomBait"]            = {group = "무역상 스킬", name = "버섯 유도", text = "유도"},
    ["ExplosiveSurprise"]       = {group = "무역상 스킬", name = "폭탄 디버프", text = "폭탄 걸림"},
    ["MushroomJump"]            = {group = "무역상 스킬", name = "버섯 점프", text = "점프"},
    ["TimeToThrow"]             = {group = "무역상 스킬", name = "물고기 던질 타이밍", text = "던질 타이밍"},
    ["TimeToThrowNonConditional"] = {group = "무역상 스킬", name = "무조건 물고기 던질 타이밍", text = "던질 타이밍"},
}

-- Sszorak (3420)
L[3420] = {
    ["TankCombo"]   = {group = "스조라크", name = "탱커 연속 공격", text = "탱커 연속 공격"},
    ["SetMarkers"]  = {group = "스조라크", name = "바닥징 찍기 알림", text = "바닥징 찍기"},
    ["DamageAmp"]   = {group = "스조라크", name = "약화됨", text = "약화됨"},
    ["Bait"]        = {group = "스조라크", name = "유도", text = "유도"},
    ["WindDebuffs"] = {group = "스조라크", name = "바람 디버프", text = "바람 디버프"},
    ["Debuffs"]     = {group = "스조라크", name = "디버프", text = "디버프"},
    ["SerpentsFury"] = {group = "스조라크", name = "뱀의 격노", text = "뭉치기"},
    ["WindsHelper"] = {group = "스조라크", name = "바람 기믹 헬퍼"},
    ["VenomousSurgeTargets"] = {group = "스조라크", name = "디버프 대상"},
    ["MarkerMap"] = {group = "스조라크", name = "징표 맵"},
}

-- The Twin Fangs (3421)
L[3421] = {
    ["Defensives"] = {group = "쌍둥이 송곳니", name = "생존기", text = "생존기"},
    ["Soak"]        = {group = "쌍둥이 송곳니", name = "스킬 맞기", text = "스킬 맞기"},
    ["Soak1"]       = {group = "쌍둥이 송곳니", name = "스킬 맞기", text = "스킬 맞기"},
    ["Soak2"]       = {group = "쌍둥이 송곳니", name = "스킬 맞기", text = "스킬 맞기"},
    ["Soak3"]       = {group = "쌍둥이 송곳니", name = "스킬 맞기", text = "스킬 맞기"},
    ["PreSpread"]   = {group = "쌍둥이 송곳니", name = "미리 산개", text = "미리 산개"},
    ["WatchSide"]   = {group = "쌍둥이 송곳니", name = "브레스 방향", text = "브레스 방향"},
    ["Adds"]        = {group = "쌍둥이 송곳니", name = "쫄", text = "쫄"},
    ["Orbs"]        = {group = "쌍둥이 송곳니", name = "구슬", text = "구슬"},
    ["TankSoak"]    = {group = "쌍둥이 송곳니", name = "탱커 바닥 맞기", text = "바닥 맞기"},
    ["WatchSpawns"] = {group = "쌍둥이 송곳니", name = "밀려남", text = "밀려남"},
    ["Knock"]       = {group = "쌍둥이 송곳니", name = "넉백", text = "넉백"},
    ["DebuffOverview"] = {group = "쌍둥이 송곳니", name = "영원의 맹독 현황", text = "영원의 맹독 현황"},
}

-- The Coiled Altar (3429)
L[3429] = {
    ["P1Frontal"]       = {group = "똬리의 제단", name = "1페 전방스킬", text = "전방스킬"},
    ["P1OrbDeadline"] = {group = "똬리의 제단", name = "구슬 운반 마감", text = "구슬 운반 마감"},
    ["P1Taunt"]         = {group = "똬리의 제단", name = "1페 도발", text = "도발"},
    ["P1Soak"]          = {group = "똬리의 제단", name = "1페 같이맞기", text = "같이맞기"},
    ["MindControls"] = {group = "똬리의 제단", name = "2페 정신 지배", text = "정신 지배"},
    ["P2Frontal"]       = {group = "똬리의 제단", name = "2페 전방스킬", text = "전방스킬"},
    ["P2Taunt"]         = {group = "똬리의 제단", name = "2페 도발", text = "도발"},
    ["P2Debuffs"]       = {group = "똬리의 제단", name = "2페 디버프", text = "디버프"},
    ["P2Shield"]        = {group = "똬리의 제단", name = "2페 보호막", text = "보호막"},
    ["DebuffCircle"] = {group = "똬리의 제단", name = "구슬/폭탄 원 도형", text = ""},
    ["EternalNightfallAbsorb"] = {group = "똬리의 제단", name = "영원한 일몰 보호막", text = ""},
    ["InterruptAdds"] = {group = "똬리의 제단", name = "2페 쫄 차단", text = "유령"},
    ["InterruptAssignments"] = {group = "똬리의 제단", name = "차단 배정", text = "차단"},
    ["P3OrbDeadline"] = {group = "똬리의 제단", name = "3페 구슬 운반 마감", text = "구슬 운반 마감"},
    ["P2_5WrongTarget"] = {group = "똬리의 제단", name = "타겟 잘못 잡음", text = "타겟 잘못 잡음"},
    ["P3Frontal"] = {group = "똬리의 제단", name = "3페 전방스킬", text = "전방스킬"},
    ["P3Soak"] = {group = "똬리의 제단", name = "3페 같이맞기", text = "같이맞기"},
    ["P3Shield"] = {group = "똬리의 제단", name = "3페 보호막", text = "보호막"},
    ["P3Debuffs"] = {group = "똬리의 제단", name = "3페 디버프", text = "디버프"},
    ["P3InterruptAdds"] = {group = "똬리의 제단", name = "3페 쫄 차단", text = "유령"},
    ["P3MindControls"] = {group = "똬리의 제단", name = "3페 정신 지배", text = "정신 지배"},
    ["P3Taunt"] = {group = "똬리의 제단", name = "3페 도발", text = "도발"},
}

-- Ula'tek (3492)
L[3492] = {
    ["HitKnock"]            = {group = "울라텍", name = "어미의 분노", text = "공격+넉백"},
    ["Waves"]               = {group = "울라텍", name = "부식의 파도", text = "파도"},
    ["DamageAmpIn"]         = {group = "울라텍", name = "맹독의 심장", text = "곧 약화"},
    ["DamageAmp"]           = {group = "울라텍", name = "맹독의 심장", text = "약화됨"},
    ["PlatformBreak"]       = {group = "울라텍", name = "사냥감 포위", text = "바닥 꺼짐"},
    ["Debuffs"]             = {group = "울라텍", name = "뱀의 물어뜯기", text = "디버프"},
    ["Eggs"]                = {group = "울라텍", name = "알", text = "알"},
    ["Adds"]                = {group = "울라텍", name = "3페 쫄", text = "쫄"},
    ["Sweep"]               = {group = "울라텍", name = "휩쓸기", text = "휩쓸기"},
    ["Soak"]                = {group = "울라텍", name = "같이맞기", text = "같이맞기"},
    ["TransitionSoakFirst"] = {group = "울라텍", name = "1조 맞기", text = "1조 맞기"},
    ["TransitionSoakSecond"] = {group = "울라텍", name = "2조 맞기", text = "2조 맞기"},
    ["GraspingFangsOverview"] = {group = "울라텍", name = "움켜쥐는 송곳니 현황", text = ""},
    ["WrongTarget"] = {group = "울라텍", name = "타겟 잘못 잡음", text = "타겟 잘못 잡음"},
    ["WaveDirection"] = {group = "울라텍", name = "파도 방향 입력", text = ""},
    ["InterruptAssignments"] = {group = "울라텍", name = "차단 배정", text = "차단"},
}
