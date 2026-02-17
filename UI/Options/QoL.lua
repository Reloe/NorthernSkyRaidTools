local _, NSI = ...
local DF = _G["DetailsFramework"]

local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildQoLOptions()
    return {
    }
end

local function BuildQoLCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.QoL = {
    BuildOptions = BuildQoLOptions,
    BuildCallback = BuildQoLCallback,
}
