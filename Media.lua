local _, NSI = ... -- Internal namespace
NSI.LSM = LibStub("LibSharedMedia-3.0")
NSMedia = {}
--Sounds
NSI.LSM:Register("sound","|cFF4BAAC8Macro|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\macro.mp3]])
NSI.LSM:Register("sound","|cFF4BAAC801|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\1.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC802|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\2.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC803|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\3.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC804|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\4.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC805|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\5.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC806|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\6.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC807|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\7.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC808|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\8.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC809|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\9.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC810|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\10.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Dispel|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Dispel.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Yellow|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Yellow.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Orange|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Orange.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Purple|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Purple.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Green|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Green.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Moon|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Moon.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Blue|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Blue.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Red|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Red.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Skull|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Skull.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Gate|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Gate.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Soak|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Soak.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Fixate|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Fixate.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Next|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Next.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Interrupt|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Interrupt.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Spread|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Spread.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Break|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Break.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Targeted|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Targeted.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Rune|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Rune.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Light|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Light.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Void|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Void.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Debuff|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Debuff.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Clear|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Clear.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Stack|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Stack.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Charge|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Charge.ogg]])
NSI.LSM:Register("sound","|cFF4BAAC8Linked|r", [[Interface\Addons\NorthernSkyRaidTools\Media\Sounds\Linked.ogg]])
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