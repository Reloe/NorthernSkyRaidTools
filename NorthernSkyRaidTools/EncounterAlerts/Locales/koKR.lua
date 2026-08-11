-- Credit by Elarfim
local _, NSI = ...

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local L = {}
NSI.EncounterAlertLocales["koKR"] = L

L[3176] = {
    ["Soaks"] = {text = "스킬 맞기", name = "스킬 맞기", group = ""},
}

L[3177] = {
    ["Breath"] = {text = "브레스", name = "브레스", group = ""},
    ["Knock"] = {text = "넉백", name = "넉백", group = ""},
}

L[3179] = {
    ["CC Display"] = {text = "", name = "메즈 현황", group = ""},
    ["Orbs"] = {text = "구슬", name = "구슬", group = ""},
    ["CC Adds"] = {text = "쫄 메즈", name = "쫄 메즈", group = ""},
    ["Beams"] = {text = "레이저", name = "레이저", group = ""},
}

L[3178] = {
    ["Breath"] = {text = "브레스", name = "브레스", group = ""},
    ["HealthDisplay"] = {text = "", name = "생명력 현황", group = ""},
    ["Spread"] = {text = "산개", name = "산개", group = ""},
    ["Tether"] = {text = "사슬", name = "사슬", group = ""},
}

L[3180] = {
    ["Aura of Wrath"] = {text = "진노의 오라", name = "진노의 오라", group = "성기사 오라"},
    ["TauntAlerts"] = {text = "도발", name = "도발 알림", group = ""},
    ["Heal Absorb Ticks"] = {text = "", name = "치유 흡수 틱", group = ""},
    ["Peace Aura"] = {text = "평화의 오라", name = "평화의 오라", group = "성기사 오라"},
    ["Sacred Toll"] = {text = "신성한 종", name = "신성한 종", group = ""},
    ["Devotion Aura"] = {text = "헌신의 오라", name = "헌신의 오라", group = "성기사 오라"},
}

L[3181] = {
    ["Tether"] = {text = "사슬", name = "사슬", group = "알레리아 3페"},
    ["Bait_P1"] = {text = "유도", name = "유도", group = "알레리아 1페"},
    ["Bait_P3"] = {text = "유도", name = "유도", group = "알레리아 2페"},
    ["Bait_P5"] = {text = "유도", name = "유도", group = "알레리아 3페"},
    ["Explosion_P1"] = {text = "폭발", name = "폭발", group = "알레리아 1페"},
    ["Explosion_P3"] = {text = "폭발", name = "폭발", group = "알레리아 2페"},
    ["Explosion_P5"] = {text = "폭발", name = "폭발", group = "알레리아 3페"},
    ["Arrows"] = {text = "화살", name = "화살", group = "알레리아 1페"},
    ["Ranged Obelisk_P1"] = {text = "방첨탑", name = "원거리 방첨탑", group = "알레리아 1페"},
    ["Ranged Obelisk_P3"] = {text = "방첨탑", name = "원거리 방첨탑", group = "알레리아 2페"},
    ["Ranged Obelisk_P5"] = {text = "방첨탑", name = "원거리 방첨탑", group = "알레리아 3페"},
    ["Boss-Immune"] = {text = "무적", name = "보스 무적", group = ""},
    ["Melee Obelisk_P1"] = {text = "방첨탑", name = "근접 방첨탑", group = "알레리아 1페"},
    ["Melee Obelisk_P3"] = {text = "방첨탑", name = "근접 방첨탑", group = "알레리아 2페"},
    ["Melee Obelisk_P5"] = {text = "방첨탑", name = "근접 방첨탑", group = "알레리아 3페"},
    ["Stop Cast"] = {text = "시전 중지", name = "시전 중지", group = "알레리아 1페"},
}

L[3306] = {
    ["Debuffs_P1"] = {text = "디버프", name = "디버프", group = ""},
    ["Debuffs_P2"] = {text = "디버프", name = "디버프", group = ""},
}

L[3182] = {
    ["Feather Color"] = {text = "", name = "깃털색", group = ""},
    ["Soaks_P1"] = {text = "스킬 맞기", name = "스킬 맞기", group = "벨로렌 1페"},
    ["Soaks_P2"] = {text = "스킬 맞기", name = "스킬 맞기", group = "벨로렌 2페"},
    ["Color Swap"] = {text = "색 교체", name = "색 교체", group = ""},
    ["Next Hit_P2"] = {text = "다음 바닥", name = "다음 바닥", group = "벨로렌 1페"},
    ["Next Hit_P3"] = {text = "다음 바닥", name = "다음 바닥", group = "벨로렌 2페"},
    ["Quills_P1"] = {text = "깃털", name = "깃털", group = "벨로렌 1페"},
    ["Quills_P2"] = {text = "깃털", name = "깃털", group = "벨로렌 2페"},
    ["Gateway_P2"] = {text = "관문", name = "관문", group = "벨로렌 1페"},
    ["Gateway_P3"] = {text = "관문", name = "관문", group = "벨로렌 2페"},
}

L[3183] = {
    ["HC Soaks"] = {text = "바닥 흡수", name = "바닥 흡수", group = "르우라 3페"},
    ["Right Stars"] = {text = "별자리", name = "오른쪽 별자리", group = "르우라 3페 오른쪽"},
    ["Left Memory Game"] = {text = "메모리 게임", name = "왼쪽 메모리 게임", group = "르우라 3페 왼쪽"},
    ["Right Soak-Time"] = {text = "흡수 남은 시간", name = "오른쪽 흡수 남은 시간", group = "르우라 3페 오른쪽"},
    ["Left Stars"] = {text = "별자리", name = "왼쪽 별자리", group = "르우라 3페 왼쪽"},
    ["Lura Tank-Hits_P4"] = {text = "탱커 공격", name = "3페 탱커 공격", group = "르우라 탱커"},
    ["Spread"] = {text = "산개", name = "산개", group = "르우라 2페"},
    ["Transition Beams"] = {text = "레이저", name = "레이저", group = "르우라 1사이페"},
    ["Orbs"] = {text = "구슬", name = "구슬", group = "르우라 2페"},
    ["Soak Cross"] = {text = "{rt7} 맞기", name = "엑스 맞기", group = "르우라 2페 바닥 맞기"},
    ["Right Soaks"] = {text = "바닥 흡수", name = "오른쪽 바닥 흡수", group = "르우라 3페 오른쪽"},
    ["MemoryGame"] = {text = "메모리 게임", name = "메모리 게임", group = "르우라 1페"},
    ["InterruptDisplay"] = {text = "", name = "차단 표시", group = ""},
    ["Glaives"] = {text = "글레이브", name = "글레이브", group = "르우라 1페"},
    ["Interrupts"] = {text = "차단", name = "차단", group = "르우라 1페"},
    ["Old-Seed-Drop"] = {text = "수정 떨구기", name = "무조건 수정 떨구기", group = "르우라 2페"},
    ["Right Memory Game"] = {text = "메모리 게임", name = "오른쪽 메모리 게임", group = "르우라 3페 오른쪽"},
    ["Left Soaks"] = {text = "바닥 흡수", name = "왼쪽 바닥 흡수", group = "르우라 3페 왼쪽"},
    ["CrystalDropTimer"] = {text = "수정 줍기", name = "수정 줍기 시간", group = ""},
    ["Beams"] = {text = "레이저", name = "레이저", group = "르우라 1페"},
    ["Galvanize"] = {text = "바닥 맞기", name = "일반 바닥 맞기", group = "르우라 2페 바닥 맞기"},
    ["Blazes"] = {text = "좌우좌", name = "별빛파열", group = "르우라 4페"},
    ["P4 Move"] = {text = "이동", name = "4페 이동", group = "르우라 4페"},
    ["Move"] = {text = "이동", name = "이동", group = "르우라 3페"},
    ["RunesDisplay"] = {text = "", name = "룬 표시", group = ""},
    ["Soak Skull"] = {text = "{rt8} 맞기", name = "해골 맞기", group = "르우라 2페 바닥 맞기"},
    ["Seed-Drop"] = {text = "수정 떨구기", name = "수정 떨구기", group = "르우라 2페"},
    ["Left Soak-Time"] = {text = "흡수 남은 시간", name = "왼쪽 흡수 남은 시간", group = "르우라 3페 왼쪽"},
    ["Lura Taunts_P1"] = {text = "도발", name = "1페 도발", group = "르우라 탱커"},
    ["Lura Taunts_P3"] = {text = "도발", name = "2페 도발", group = "르우라 탱커"},
    ["Full Blaze"] = {text = "전원 가시", name = "전원 가시", group = "르우라 1사이페"},
    ["Lura Tank-Hits_P1"] = {text = "탱커 공격", name = "1페 탱커 공격", group = "르우라 탱커"},
    ["Lura Tank-Hits_P3"] = {text = "탱커 공격", name = "2페 탱커 공격", group = "르우라 탱커"},
    ["Soak Star"] = {text = "{rt1} 맞기", name = "별 맞기", group = "르우라 2페 바닥 맞기"},
    ["Final Slice Stars"] = {text = "별자리", name = "마지막 별자리", group = "르우라 3페"},
    ["Soak Orange"] = {text = "{rt2} 맞기", name = "동글 맞기", group = "르우라 2페 바닥 맞기"},
}

L[3159] = {
    ["BurstingPustules"] = {text = "광역뎀", name = "광역뎀", group = ""},
    ["Shrooms"] = {text = "버섯", name = "버섯", group = ""},
    ["InterruptDisplay"] = {text = "", name = "차단 현황", group = ""},
    ["Taunts"] = {text = "도발", name = "도발", group = "부식수렁 탱커"},
    ["Tankhits"] = {text = "탱커 공격", name = "탱커 공격", group = "부식수렁 탱커"},
    ["Adds"] = {text = "쫄", name = "쫄", group = ""},
}

L[3379] = {
}

L[3470] = {
    ["RestlessAmani"] = {text = "쫄", name = "쫄 등장", group = "네크잘리"},
    ["Barrage"] = {text = "전방스킬", name = "포화", group = "네크잘리"},
    ["HungeringPyre"] = {text = "스킬 맞기", name = "굶주린 장작더미", group = "네크잘리"},
    ["Debuffs"] = {text = "디버프", name = "정수 분쇄", group = "네크잘리"},
    ["SoulcoilIgnition"] = {text = "광역뎀", name = "영혼똬리 점화", group = "네크잘리"},
    ["InvokeMythic"] = {text = "시전 중지", name = "기원", group = "네크잘리"},
    ["Invoke"] = {text = "피하기", name = "기원", group = "네크잘리"},
}

L[3445] = {
    ["BloodSoakPool"] = {text = "바닥 깔림", name = "스킬 맞고 바닥 깔림", group = "파수꾼"},
    ["BloodHits"] = {text = "탱커 공격", name = "피 탱커 공격", group = "파수꾼"},
    ["BloodDispels"] = {text = "해제", name = "피 해제", group = "파수꾼"},
    ["TransitionDebuffs"] = {text = "숫자 게임", name = "사이페 디버프", group = "파수꾼"},
    ["PoisonHits"] = {text = "탱커 공격", name = "독 탱커 공격", group = "파수꾼"},
    ["ShiftingProtovenom"] = {text = "산개", name = "변화무쌍한 원시맹독", group = "파수꾼"},
    ["OrbSpawn"] = {text = "구슬 유도", name = "구슬 등장", group = "파수꾼"},
    ["BloodDropPool"] = {text = "바닥 깔림", name = "탱커 바닥 깔림", group = "파수꾼"},
    ["PoisonAdd"] = {text = "독 쫄", name = "독 쫄", group = "파수꾼"},
    ["BloodSoak"] = {text = "피 스킬 맞기", name = "피 스킬 맞기", group = "파수꾼"},
}

L[3455] = {
    ["Taunts"] = {text = "도발", name = "Taunt", group = "바쉬니크"},
    ["Adds"] = {text = "쫄", name = "쫄", group = "바쉬니크"},
    ["TankHits"] = {text = "탱커 공격", name = "탱커 공격", group = "바쉬니크"},
    ["Infection"] = {text = "감염", name = "감염", group = "바쉬니크"},
    ["WaveSpread"] = {text = "미리 산개", name = "파도 산개", group = "바쉬니크"},
    ["Waves"] = {text = "파도", name = "파도", group = "바쉬니크"},
    ["Soaks"] = {text = "스킬 맞기", name = "스킬 맞기", group = "바쉬니크"},
    ["AoE"] = {text = "광역뎀", name = "광역뎀", group = "바쉬니크"},
}

L[3497] = {
    ["MushroomJump"] = {text = "점프", name = "버섯 점프", group = "무역상 스킬"},
    ["ShreddingShards"] = {text = "탱커 공격", name = "탱커 공격", group = "두루마리현자 스킬"},
    ["Fish-Spawn"] = {text = "물고기 생성", name = "물고기 생성", group = "무역상 스킬"},
    ["FrostfireVolley"] = {text = "서리불꽃 디버프", name = "서리불꽃 연사", group = "두루마리현자 스킬"},
    ["ShellSpinScroll"] = {text = "유도", name = "등껍질 회전 - 두루마리 강화됨", group = "일등항해사 스킬"},
    ["MushroomBait"] = {text = "유도", name = "버섯 유도", group = "무역상 스킬"},
    ["BlinkNova"] = {text = "점멸 회오리", name = "점멸 회오리", group = "두루마리현자 스킬"},
    ["ShellSpinTrader"] = {text = "유도", name = "등껍질 회전 - 무역상 강화됨", group = "일등항해사 스킬"},
    ["TimeToThrowNonConditional"] = {text = "던지기 시간", name = "무조건 물고기 던지기 시간", group = "무역상 스킬"},
    ["TimeToThrow"] = {text = "던지기 시간", name = "물고기 던지기 시간", group = "무역상 스킬"},
    ["ShellSpinNormal"] = {text = "유도", name = "등껍질 회전 일반", group = "일등항해사 스킬"},
    ["ExplosiveSurprise"] = {text = "폭탄 걸림", name = "폭탄 디버프", group = "무역상 스킬"},
    ["MightyThud"] = {text = "스킬 맞기", name = "스킬 맞기", group = "일등항해사 스킬"},
}

L[3420] = {
    ["DamageAmp"] = {text = "피해 증가", name = "피해 증가", group = "스조라크"},
    ["Debuffs"] = {text = "디버프", name = "디버프", group = "스조라크"},
    ["WindDebuffs"] = {text = "바람 디버프", name = "바람 디버프", group = "스조라크"},
    ["TankCombo"] = {text = "탱커 연속 공격", name = "탱커 연속 공격", group = "스조라크"},
    ["Bait"] = {text = "유도", name = "유도", group = "스조라크"},
    ["WindsHelper"] = {text = "", name = "바람 기믹 헬퍼", group = "스조라크"},
    ["SerpentsFury"] = {text = "뭉치기", name = "뱀의 격노", group = "스조라크"},
}

L[3421] = {
    ["Adds"] = {text = "쫄", name = "쫄", group = "쌍둥이 송곳니"},
    ["Soak"] = {text = "스킬 맞기", name = "스킬 맞기", group = "쌍둥이 송곳니"},
    ["TankSoak"] = {text = "스킬 맞기", name = "탱커와 같이 맞기", group = "쌍둥이 송곳니"},
    ["PreSpread"] = {text = "미리 산개", name = "미리 산개", group = "쌍둥이 송곳니"},
    ["WatchSide"] = {text = "머리 방향", name = "머리 방향", group = "쌍둥이 송곳니"},
    ["Orbs"] = {text = "구슬", name = "구슬", group = "쌍둥이 송곳니"},
    ["WatchSpawns"] = {text = "브레스 머리 나옴", name = "브레스 머리 나옴", group = "쌍둥이 송곳니"},
    ["Defensives"] = {text = "생존기", name = "생존기", group = "쌍둥이 송곳니"},
    ["Knock"] = {text = "넉백", name = "넉백", group = "쌍둥이 송곳니"},
}

L[3429] = {
    ["InterruptAdds"] = {text = "유령", name = "2페 쫄 차단", group = "똬리의 제단 2페"},
    ["P2Taunt"] = {text = "도발", name = "2페 도발", group = "똬리의 제단 탱커"},
    ["P2Frontal"] = {text = "전방스킬", name = "2페 전방스킬", group = "똬리의 제단 2페"},
    ["P1Soak"] = {text = "스킬 맞기", name = "1페 스킬 맞기", group = "똬리의 제단 1페"},
    ["P2Shield"] = {text = "보호막", name = "2페 보호막", group = "똬리의 제단 2페"},
    ["MindControls"] = {text = "정신 지배", name = "정신 지배", group = "똬리의 제단 2페"},
    ["P2Debuffs"] = {text = "디버프", name = "2페 디버프", group = "똬리의 제단 2페"},
    ["P1Taunt"] = {text = "도발", name = "1페 도발", group = "똬리의 제단 탱커"},
    ["P1Frontal"] = {text = "전방스킬", name = "1페 전방스킬", group = "똬리의 제단 1페"},
}

L[3492] = {
   -- ["HitKnock"] = {text = "공격+넉백", name = "1페 공격+넉백", group = "울라텍 탱커"},
   -- ["Taunt"] = {text = "도발", name = "1페 도발", group = "울라텍 탱커"},
   -- ["Waves"] = {text = "파도", name = "파도", group = "울라텍 1페"},
   -- ["Adds"] = {text = "쫄", name = "쫄", group = "울라텍 1페"},
   -- ["DamageAmpIn"] = {text = "피해 증가", name = "피해 증가", group = "울라텍 1페"},
   -- ["DamageAmp"] = {text = "피해 증가", name = "피해 증가 바", group = "울라텍 1페"},
   -- ["PlatformBreak"] = {text = "바닥 파괴 + 넉백", name = "바닥 파괴", group = "울라텍 3페"},
   -- ["Debuffs"] = {text = "디버프", name = "디버프", group = "울라텍 3페"},
}
