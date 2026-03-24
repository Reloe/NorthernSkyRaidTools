local _, NSI = ... -- Internal namespace
_G["NSAPI"] = {}
NSI.specs = {}
NSI.LCG = LibStub("LibCustomGlow-1.0")
NSI.LGF = LibStub("LibGetFrame-1.0")
NSI.NSRTFrame = CreateFrame("Frame", nil, UIParent)
NSI.NSRTFrame:SetAllPoints(UIParent)
NSI.NSRTFrame:SetFrameStrata("BACKGROUND")

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

function NSI:InitLDB()
    local L = NSI.L
    if LDB then
        local databroker = LDB:NewDataObject("NSRT", {
            type = "launcher",
            label = L["ADDON_TITLE"],
            icon = [[Interface\AddOns\NorthernSkyRaidTools\Media\NSLogo]],
            showInCompartment = true,
            OnClick = function(self, button)
                if button == "LeftButton" then
                    NSI.NSUI:ToggleOptions()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine(L["MINIMAP_TOOLTIP_TITLE"], 0, 1, 1)
                tooltip:AddLine(L["MINIMAP_TOOLTIP_LEFTCLICK"])
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
NSI.ShowWarningAlert = {}
NSI.ShowBossWhisperAlert = {}
NSI.AddAssignments = {}
NSI.DetectPhaseChange = {}