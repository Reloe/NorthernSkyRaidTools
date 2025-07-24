local _, NSI = ... -- Internal namespace
_G["NSAPI"] = {}
NSI.specs = {}
local NSAPI2 = NSAPI

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")
-- storing NSAPI in NSAPI2 so I can overwrite it again if user still has the old database WA installed
-- this is needed because the database WA will overwrite the global NSAPI which would cause newer functions to be nil
hooksecurefunc("setglobal", function(name, _)
    if name == "NSAPI" then
        print("Please uninstall the |cFF00FFFFNorthern Sky Functions & Database Weakaura|r to prevent conflicts with the Northern Sky Raid Tools Addon. Reload UI afterwards.")
        NSAPI = NSAPI2
    end
end)
function NSI:InitLDB()
    if LDB then
        local databroker = LDB:NewDataObject("NSRT", {
            type = "launcher",
            label = "Northern Sky Raid Tools",
            icon = [[Interface\AddOns\NorthernSkyRaidTools\Media\NSLogo]],
            showInCompartment = true,
            OnClick = function(self, button)
                if button == "LeftButton" then
                    NSI.NSUI:ToggleOptions()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Northern Sky Raid Tools", 0, 1, 1)
                tooltip:AddLine("|cFFCFCFCFLeft click|r: Show/Hide Options Window")
            end
        })

        if (databroker and not LDBIcon:IsRegistered("NSRT")) then
            LDBIcon:Register("NSRT", databroker, NSRT.Settings["Minimap"])
            LDBIcon:AddButtonToCompartment("NSRT")
        end

        NSI.databroker = databroker
    end
end
