local _, NSI = ... -- Internal namespace
NSI.LSM = LibStub("LibSharedMedia-3.0")
NSMedia = {}
--Icons
NSI.LSM:Register("statusbar", "play_icon", [[Interface\Addons\NorthernSkyRaidTools\Media\Icons\play_icon]])
NSI.LSM:Register("statusbar", "stop_icon", [[Interface\Addons\NorthernSkyRaidTools\Media\Icons\stop_icon]])
NSI.LSM:Register("statusbar", "user_icon", [[Interface\Addons\NorthernSkyRaidTools\Media\Icons\user-round]])
NSI.LSM:Register("statusbar", "users_icon", [[Interface\Addons\NorthernSkyRaidTools\Media\Icons\users-round]])
--Sounds
local color = "|cFF4BAAC8"
NSI.LSM:Register("sound", color .. "Macro|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\macro.mp3]])
NSI.LSM:Register("sound", color .. "01|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\1.ogg]])
NSI.LSM:Register("sound", color .. "02|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\2.ogg]])
NSI.LSM:Register("sound", color .. "03|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\3.ogg]])
NSI.LSM:Register("sound", color .. "04|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\4.ogg]])
NSI.LSM:Register("sound", color .. "05|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\5.ogg]])
NSI.LSM:Register("sound", color .. "06|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\6.ogg]])
NSI.LSM:Register("sound", color .. "07|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\7.ogg]])
NSI.LSM:Register("sound", color .. "08|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\8.ogg]])
NSI.LSM:Register("sound", color .. "09|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\9.ogg]])
NSI.LSM:Register("sound", color .. "10|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\10.ogg]])
NSI.LSM:Register("sound", color .. "Dispel|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Dispel.ogg]])
NSI.LSM:Register("sound", color .. "Yellow|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Yellow.ogg]])
NSI.LSM:Register("sound", color .. "Orange|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Orange.ogg]])
NSI.LSM:Register("sound", color .. "Purple|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Purple.ogg]])
NSI.LSM:Register("sound", color .. "Green|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Green.ogg]])
NSI.LSM:Register("sound", color .. "Moon|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Moon.ogg]])
NSI.LSM:Register("sound", color .. "Blue|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Blue.ogg]])
NSI.LSM:Register("sound", color .. "Red|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Red.ogg]])
NSI.LSM:Register("sound", color .. "Skull|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Skull.ogg]])
NSI.LSM:Register("sound", color .. "Gate|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Gate.ogg]])
NSI.LSM:Register("sound", color .. "Soak|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Soak.ogg]])
NSI.LSM:Register("sound", color .. "Fixate|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Fixate.ogg]])
NSI.LSM:Register("sound", color .. "Next|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Next.ogg]])
NSI.LSM:Register("sound", color .. "Interrupt|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Interrupt.ogg]])
NSI.LSM:Register("sound", color .. "Spread|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Spread.ogg]])
NSI.LSM:Register("sound", color .. "Break|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Break.ogg]])
NSI.LSM:Register("sound", color .. "Targeted|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Targeted.ogg]])
NSI.LSM:Register("sound", color .. "Rune|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Rune.ogg]])
NSI.LSM:Register("sound", color .. "Light|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Light.ogg]])
NSI.LSM:Register("sound", color .. "Void|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Void.ogg]])
NSI.LSM:Register("sound", color .. "Debuff|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Debuff.ogg]])
NSI.LSM:Register("sound", color .. "Clear|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Clear.ogg]])
NSI.LSM:Register("sound", color .. "Stack|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Stack.ogg]])
NSI.LSM:Register("sound", color .. "Charge|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Charge.ogg]])
NSI.LSM:Register("sound", color .. "Linked|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Linked.ogg]])
NSI.LSM:Register("sound", color .. "DropPool|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\DropPool.ogg]])
NSI.LSM:Register("sound", color .. "Obelisk|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Obelisk.ogg]])
NSI.LSM:Register("sound", color .. "HealAbsorb|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\HealAbsorb.ogg]])
NSI.LSM:Register("sound", color .. "Feather|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Feather.ogg]])
NSI.LSM:Register("sound", color .. "Shroom|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Shroom.ogg]])
NSI.LSM:Register("sound", color .. "Fung|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Fung.ogg]])
NSI.LSM:Register("sound", color .. "Right|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Right.ogg]])
NSI.LSM:Register("sound", color .. "Left|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Left.ogg]])
NSI.LSM:Register("sound", color .. "Ranged|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Ranged.ogg]])
NSI.LSM:Register("sound", color .. "Boss|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Boss.ogg]])
NSI.LSM:Register("sound", color .. "Suck|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Suck.ogg]])
NSI.LSM:Register("sound", color .. "RunOut|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\RunOut.ogg]])
NSI.LSM:Register("sound", color .. "Fire|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Fire.ogg]])
NSI.LSM:Register("sound", color .. "Frost|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Frost.ogg]])
NSI.LSM:Register("sound", color .. "North|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\North.ogg]])
NSI.LSM:Register("sound", color .. "South|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\South.ogg]])
NSI.LSM:Register("sound", color .. "West|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\West.ogg]])
NSI.LSM:Register("sound", color .. "East|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\East.ogg]])
NSI.LSM:Register("sound", color .. "Bomb|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Bomb.ogg]])
NSI.LSM:Register("sound", color .. "MindControl|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\MindControl.ogg]])
--Fonts
NSI.LSM:Register("font","Expressway", [[Interface\Addons\NorthernSkyRaidTools\Media\Fonts\Expressway.TTF]])
--StatusBars
NSI.LSM:Register("statusbar","Atrocity", [[Interface\Addons\NorthernSkyRaidTools\Media\StatusBars\Atrocity]])

-- Memes for Break-Timer
NSMedia.BreakMemes = {
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\ZarugarPeace.blp]], 256, 256},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\ZarugarChad.blp]], 256, 147},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\Overtime.blp]], 256, 256},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\TherzBayern.blp]], 256, 24},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\senfisaur.blp]], 256, 256},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\schinky.blp]], 256, 256},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\TizaxHose.blp]], 202, 256},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\ponkyBanane.blp]], 256, 174},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\ponkyDespair.blp]], 256, 166},
    {[[Interface\AddOns\NorthernSkyRaidTools\Media\Memes\docPog.blp]], 195, 211},
}