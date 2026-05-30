local addonId, NSI = ...
local DF = _G["DetailsFramework"]
local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function ApplyUIFont(object, size, flags)
    if not object then return end
    if object.GetFontString then
        object = object:GetFontString()
    end
    NSI:SetUIFont(object, size or 12, flags or "")
end

local function BuildNicknamesOptions()
    local nickname_share_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_share_options = function()
        local t = {}
        for i = 1, #nickname_share_options do
            tinsert(t, {
                label = NSI:Loc(nickname_share_options[i]),
                phraseId = nickname_share_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["ShareNickNames"] = value
                end
            })
        end
        return t
    end

    local nickname_accept_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_accept_options = function()
        local t = {}
        for i = 1, #nickname_accept_options do
            tinsert(t, {
                label = NSI:Loc(nickname_accept_options[i]),
                phraseId = nickname_accept_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["AcceptNickNames"] = value
                end
            })
        end
        return t
    end

    local nickname_syncaccept_options = { "Raid", "Guild", "Both", "None" }
    local build_nickname_syncaccept_options = function()
        local t = {}
        for i = 1, #nickname_syncaccept_options do
            tinsert(t, {
                label = NSI:Loc(nickname_syncaccept_options[i]),
                phraseId = nickname_syncaccept_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["NickNamesSyncAccept"] = value
                end
            })
        end
        return t
    end

    local nickname_syncsend_options = { "Raid", "Guild", "None"}
    local build_nickname_syncsend_options = function()
        local t = {}
        for i = 1, #nickname_syncsend_options do
            tinsert(t, {
                label = NSI:Loc(nickname_syncsend_options[i]),
                phraseId = nickname_syncsend_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["NickNamesSyncSend"] = value
                end
            })
        end
        return t
    end

    local function WipeNickNames()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, NSI:Loc("Confirm Wipe Nicknames"), "NSRTWipeNicknamesPopup")
        ApplyUIFont(popup.Title, 12)
        popup:SetFrameStrata("DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup,
            NSI:Loc("Are you sure you want to wipe all nicknames?"), 12, "orange")
        ApplyUIFont(text, 12)
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            NSI:WipeNickNames()
            NSUI.nickname_frame.scrollbox:MasterRefresh()
            popup:Hide()
        end, 100, 30, NSI:Loc("Confirm"))
        ApplyUIFont(confirmButton, 12)
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, NSI:Loc("Cancel"))
        ApplyUIFont(cancelButton, 12)
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end

    return {
        { type = "label", get = function() return "Nicknames Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "textentry",
            name = "Nickname",
            desc = "Set your nickname to be seen by others and used in assignments",
            get = function() return NSRT.Settings["MyNickName"] or "" end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["NICKNAME"] = true
                NSRT.Settings["MyNickName"] = NSI:Utf8Sub(value, 1, 12)
            end,
            hooks = {
                OnEditFocusLost = function(self)
                    self:SetText(NSRT.Settings["MyNickName"])
                end,
                OnEnterPressed = function(self) return end
            },
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Nicknames",
            desc = "Globaly enable nicknames.",
            get = function() return NSRT.Settings["GlobalNickNames"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] = true
                NSRT.Settings["GlobalNickNames"] = value
            end,
            nocombat = true
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Translit Names",
            desc = "Translit Russian Names",
            get = function() return NSRT.Settings["Translit"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["TRANSLIT"] = true
                NSRT.Settings["Translit"] = value
            end,
            nocombat = true
        },

        { type = "label", get = function() return "Automated Nickname Share Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "select",
            get = function() return NSRT.Settings["ShareNickNames"] end,
            values = function() return build_nickname_share_options() end,
            name = "Nickname Sharing",
            desc = "Choose who you share your nickname with.",
            nocombat = true
        },
        {
            type = "select",
            get = function() return NSRT.Settings["AcceptNickNames"] end,
            values = function() return build_nickname_accept_options() end,
            name = "Nickname Accept",
            desc = "Choose who you are accepting Nicknames from",
            nocombat = true
        },

        { type = "label", get = function() return "Manual Nickname Sync Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type = "select",
            get = function() return NSRT.Settings["NickNamesSyncSend"] end,
            values = function() return build_nickname_syncsend_options() end,
            name = "Nickname Sync Send",
            desc = "Choose who you are synching nicknames to when pressing on the sync button",
            nocombat = true
        },

        {
            type = "select",
            get = function() return NSRT.Settings["NickNamesSyncAccept"] end,
            values = function() return build_nickname_syncaccept_options() end,
            name = "Nickname Sync Accept",
            desc = "Choose who you are accepting Nicknames sync requests to come from",
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Unit Frame compatibility" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Blizzard"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] = true
                NSRT.Settings["Blizzard"] = value
            end,
            name = "Enable Blizzard/Reskin Addons Nicknames",
            desc = "Enable Nicknames to be used with Blizzard unit frames. This should automatically work for any Addon that reskins Blizzard Frames instead of creating their own frames. This for example includes RaidFrameSettings.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Cell"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["CELL_NICKNAMES"] = true
                NSRT.Settings["Cell"] = value
            end,
            name = "Enable Cell Nicknames",
            desc = "Enable Nicknames to be used with Cell unit frames. This requires enabling nicknames within Cell.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Grid2"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] = true
                NSRT.Settings["Grid2"] = value
            end,
            name = "Enable Grid2 Nicknames",
            desc = "Enable Nicknames to be used with Grid2 unit frames. This requires selecting the 'NSNickName' indicator within Grid2.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["DandersFrames"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] = true
                NSRT.Settings["DandersFrames"] = value
            end,
            name = "Enable DandersFrames Nicknames",
            desc = "Enable Nicknames to be used with DandersFrames unit frames.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["ElvUI"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] = true
                NSRT.Settings["ElvUI"] = value
            end,
            name = "Enable ElvUI Nicknames",
            desc = "Enable Nicknames to be used with ElvUI unit frames. This requires editing your Tags. Available options are [NSNickName] and [NSNickName:1-12]",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["VuhDo"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] = true
                NSRT.Settings["VuhDo"] = value
            end,
            name = "Enable VuhDo Nicknames",
            desc = "Enable Nicknames to be used with VuhDo unit frames.",
            nocombat = true
        },
        {
            type = "toggle",
            boxfirst = true,
            get = function() return NSRT.Settings["Unhalted"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] = true
                NSRT.Settings["Unhalted"] = value
            end,
            name = "Enable Unhalted UF Nicknames",
            desc = "Enable Nicknames to be used with Unhalted Unit Frames. You can choose 'NSNickName' as a tag within UUF.",
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "button",
            name = "Wipe Nicknames",
            desc = "Wipe all nicknames from the database.",
            func = function(self)
                WipeNickNames()
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Edit Nicknames",
            desc = "Edit the nicknames database stored locally.",
            func = function(self)
                if not NSUI.nickname_frame:IsShown() then
                    NSUI.nickname_frame:Show()
                end
            end,
            nocombat = true
        }
    }
end

local function BuildNicknamesCallback()
    return function()
        if NSUI.OptionsChanged.nicknames["NICKNAME"] then
            NSI:NickNameUpdated(NSRT.Settings["MyNickName"])
        end

        if NSUI.OptionsChanged.nicknames["GLOBAL_NICKNAMES"] then
            NSI:GlobalNickNameUpdate()
        end

        if NSUI.OptionsChanged.nicknames["TRANSLIT"] then
            NSI:UpdateNickNameDisplay(true)
        end

        if NSUI.OptionsChanged.nicknames["BLIZZARD_NICKNAMES"] then
            NSI:BlizzardNickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["CELL_NICKNAMES"] then
            NSI:CellNickNameUpdated(true)
        end

        if NSUI.OptionsChanged.nicknames["ELVUI_NICKNAMES"] then
            NSI:ElvUINickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["VUHDO_NICKNAMES"] then
            NSI:VuhDoNickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["GRID2_NICKNAMES"] then
            NSI:Grid2NickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["DANDERS_FRAMES_NICKNAMES"] then
            NSI:DandersFramesNickNameUpdated(true)
        end

        if NSUI.OptionsChanged.nicknames["UNHALTED_NICKNAMES"] then
            NSI:UnhaltedNickNameUpdated()
        end

        if NSUI.OptionsChanged.nicknames["MRT_NICKNAMES"] then
            NSI:MRTNickNameUpdated(true)
        end

        wipe(NSUI.OptionsChanged["nicknames"])
    end
end

-- Export to namespace
NSI.UI = NSI.UI or {}
NSI.UI.Options = NSI.UI.Options or {}
NSI.UI.Options.Nicknames = {
    BuildOptions = BuildNicknamesOptions,
    BuildCallback = BuildNicknamesCallback,
}
