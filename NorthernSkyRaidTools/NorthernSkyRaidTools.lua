local _, NSI = ... -- Internal namespace
_G.NorthernSkyRaidTools = NSI
_G["NSAPI"] = {}
NSI.UIAddonName = "NorthernSkyRaidTools_UI"
NSI.specs = {}
NSI.LCG = LibStub("LibCustomGlow-1.0")
NSI.LGF = LibStub("LibGetFrame-1.0")
NSI.NSRTFrame = CreateFrame("Frame", nil, UIParent)
NSI.NSRTFrame:SetAllPoints(UIParent)
NSI.NSRTFrame:SetFrameStrata("BACKGROUND")

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")
local DF = _G["DetailsFramework"]

local supportedLanguages = {
    enUS = true,
    deDE = true,
    koKR = true,
    ruRU = true,
    zhCN = true,
    zhTW = true,
}

function NSI:GetSelectedLanguage()
    local languageId = NSRT and NSRT.Settings and NSRT.Settings.Language
    if not languageId or languageId == "Auto" then
        languageId = GetLocale()
    end
    if languageId == "enGB" then
        languageId = "enUS"
    end
    if not supportedLanguages[languageId] then
        languageId = "enUS"
    end
    return languageId
end

function NSI:GetFallbackUIFontPath()
    local gameFont = GameFontNormal and select(1, GameFontNormal:GetFont())
    return gameFont or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

function NSI:ValidateFontPath(path)
    local fallback = self:GetFallbackUIFontPath()
    if not path or path == "" then return fallback end

    self.fontTestString = self.fontTestString or UIParent:CreateFontString(nil, "ARTWORK")
    local ok, success = pcall(self.fontTestString.SetFont, self.fontTestString, path, 12, "")
    self.fontTestString:Hide()
    if ok and success then return path end
    return fallback
end

function NSI:GetUIFontPath()
    local languageId = self:GetSelectedLanguage()
    local fontPath
    if languageId == "enUS" then
        fontPath = NSRT.Settings.GlobalFont
    elseif languageId and DF.Language.GetFontForLanguageID then
        fontPath = DF.Language.GetFontForLanguageID(languageId, "NorthernSkyRaidTools")
    else
        fontPath = DF:GetBestFontForLanguage()
    end

    if self.LSM then
        local lsmFont = self.LSM:Fetch("font", fontPath, true)
        if lsmFont then
            return self:ValidateFontPath(lsmFont)
        end
    end
    return self:ValidateFontPath(fontPath)
end

function NSI:GetUIFontFlags()
    return NSRT.Settings.GlobalFontFlags or ""
end

function NSI:GetGlobalFontPath()
    return self:GetUIFontPath()
end

function NSI:Loc(key)
    local languageId = self:GetSelectedLanguage()
    local ok, languageTable = pcall(DF.Language.GetLanguageTable, "NorthernSkyRaidTools", languageId)
    local text = ok and languageTable and languageTable[key]
    if text == true then return key end
    if text then return text end
    return DF.Language.GetText("NorthernSkyRaidTools", key, true) or key
end

function NSI:LoadUI()
    if self.UILoading then
        return false
    end

    if not self.NSUI then
        self.UILoading = true
        local loaded = C_AddOns.LoadAddOn(self.UIAddonName)
        self.UILoading = nil
        if not self.NSUI and self.UIBootstrap then
            self.NSUI = self.UIBootstrap.NSUI
        end
        if not loaded and not self.NSUI then
            return false
        end
    end

    if self.NSUI and not self.NSUI.Initialized then
        self.NSUI:Init()
    end
    return self.NSUI and self.NSUI.Initialized == true
end

function NSI:InitLDB()
    if LDB then
        local databroker = LDB:NewDataObject("NSRT", {
            type = "launcher",
            label = "Northern Sky Raid Tools",
            icon = [[Interface\AddOns\NorthernSkyRaidTools\Media\NSLogo]],
            showInCompartment = true,
            OnClick = function(self, button)
                if button == "LeftButton" then
                    if NSI:LoadUI() then
                        NSI.NSUI:ToggleOptions()
                    end
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Northern Sky Raid Tools", 0, 1, 1)
                tooltip:AddLine(NSI:Loc("|cFFCFCFCFLeft click|r: Show/Hide Options Window"))
            end
        })

        if (databroker and not LDBIcon:IsRegistered("NSRT")) then
            LDBIcon:Register("NSRT", databroker, NSRT.Settings["Minimap"])
            LDBIcon:AddButtonToCompartment("NSRT")
        end

        self.databroker = databroker
    end
end


NSI.EncounterAlertStart = {}
NSI.EncounterAlertStop = {}
NSI.EncounterAlertSpecialDisplay = {}
NSI.ShowWarningAlert = {}
NSI.ShowBossWhisperAlert = {}
NSI.AddAssignments = {}
NSI.DetectPhaseChange = {}
NSI.InitializeAlerts = {}
