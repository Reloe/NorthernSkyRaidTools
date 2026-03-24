local _, NSI = ...
local DF = _G["DetailsFramework"]
local L = NSI.L

local Core = NSI.UI.Core
local NSUI = Core.NSUI

local function BuildNicknamesOptions()
    local nickname_share_options = { L["OPT_NICK_SCOPE_RAID"], L["OPT_NICK_SCOPE_GUILD"], L["OPT_NICK_SCOPE_BOTH"], L["COMMON_NONE"] }
    local build_nickname_share_options = function()
        local t = {}
        for i = 1, #nickname_share_options do
            tinsert(t, {
                label = nickname_share_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["ShareNickNames"] = value
                end
            })
        end
        return t
    end

    local nickname_accept_options = { L["OPT_NICK_SCOPE_RAID"], L["OPT_NICK_SCOPE_GUILD"], L["OPT_NICK_SCOPE_BOTH"], L["COMMON_NONE"] }
    local build_nickname_accept_options = function()
        local t = {}
        for i = 1, #nickname_accept_options do
            tinsert(t, {
                label = nickname_accept_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["AcceptNickNames"] = value
                end
            })
        end
        return t
    end

    local nickname_syncaccept_options = { L["OPT_NICK_SCOPE_RAID"], L["OPT_NICK_SCOPE_GUILD"], L["OPT_NICK_SCOPE_BOTH"], L["COMMON_NONE"] }
    local build_nickname_syncaccept_options = function()
        local t = {}
        for i = 1, #nickname_syncaccept_options do
            tinsert(t, {
                label = nickname_syncaccept_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["NickNamesSyncAccept"] = value
                end
            })
        end
        return t
    end

    local nickname_syncsend_options = { L["OPT_NICK_SCOPE_RAID"], L["OPT_NICK_SCOPE_GUILD"], L["COMMON_NONE"]}
    local build_nickname_syncsend_options = function()
        local t = {}
        for i = 1, #nickname_syncsend_options do
            tinsert(t, {
                label = nickname_syncsend_options[i],
                value = i,
                onclick = function(_, _, value)
                    NSRT.Settings["NickNamesSyncSend"] = value
                end
            })
        end
        return t
    end

    local function WipeNickNames()
        local popup = DF:CreateSimplePanel(UIParent, 300, 150, L["OPT_NICK_WIPE_TITLE"], "NSRTWipeNicknamesPopup")
        popup:SetFrameStrata("DIALOG")
        popup:SetPoint("CENTER", UIParent, "CENTER")

        local text = DF:CreateLabel(popup,
            L["OPT_NICK_WIPE_TEXT"], 12, "orange")
        text:SetPoint("TOP", popup, "TOP", 0, -30)
        text:SetJustifyH("CENTER")

        local confirmButton = DF:CreateButton(popup, function()
            NSI:WipeNickNames()
            NSUI.nickname_frame.scrollbox:MasterRefresh()
            popup:Hide()
        end, 100, 30, L["COMMON_CONFIRM"])
        confirmButton:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 5, 10)
        confirmButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))

        local cancelButton = DF:CreateButton(popup, function()
            popup:Hide()
        end, 100, 30, L["COMMON_CANCEL"])
        cancelButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -5, 10)
        cancelButton:SetTemplate(DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        popup:Show()
    end

    return {
        { type = "label", get = function() return L["OPT_NICK_TITLE"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "textentry",
            name = L["OPT_NICK_NICKNAME"],
            desc = L["OPT_NICK_NICKNAME_DESC"],
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
            name = L["OPT_NICK_ENABLE"],
            desc = L["OPT_NICK_ENABLE_DESC"],
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
            name = L["OPT_NICK_TRANSLIT"],
            desc = L["OPT_NICK_TRANSLIT_DESC"],
            get = function() return NSRT.Settings["Translit"] end,
            set = function(self, fixedparam, value)
                NSUI.OptionsChanged.nicknames["TRANSLIT"] = true
                NSRT.Settings["Translit"] = value
            end,
            nocombat = true
        },

        { type = "label", get = function() return L["OPT_NICK_AUTO_SHARE_TITLE"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "select",
            get = function() return NSRT.Settings["ShareNickNames"] end,
            values = function() return build_nickname_share_options() end,
            name = L["OPT_NICK_SHARING"],
            desc = L["OPT_NICK_SHARING_DESC"],
            nocombat = true
        },
        {
            type = "select",
            get = function() return NSRT.Settings["AcceptNickNames"] end,
            values = function() return build_nickname_accept_options() end,
            name = L["OPT_NICK_ACCEPT"],
            desc = L["OPT_NICK_ACCEPT_DESC"],
            nocombat = true
        },

        { type = "label", get = function() return L["OPT_NICK_MANUAL_SYNC_TITLE"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type = "select",
            get = function() return NSRT.Settings["NickNamesSyncSend"] end,
            values = function() return build_nickname_syncsend_options() end,
            name = L["OPT_NICK_SYNC_SEND"],
            desc = L["OPT_NICK_SYNC_SEND_DESC"],
            nocombat = true
        },

        {
            type = "select",
            get = function() return NSRT.Settings["NickNamesSyncAccept"] end,
            values = function() return build_nickname_syncaccept_options() end,
            name = L["OPT_NICK_SYNC_ACCEPT"],
            desc = L["OPT_NICK_SYNC_ACCEPT_DESC"],
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return L["OPT_NICK_UNITFRAME_COMPAT"] end,
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
            name = L["OPT_NICK_ENABLE_BLIZZARD"],
            desc = L["OPT_NICK_ENABLE_BLIZZARD_DESC"],
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
            name = L["OPT_NICK_ENABLE_CELL"],
            desc = L["OPT_NICK_ENABLE_CELL_DESC"],
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
            name = L["OPT_NICK_ENABLE_GRID2"],
            desc = L["OPT_NICK_ENABLE_GRID2_DESC"],
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
            name = L["OPT_NICK_ENABLE_DANDERS"],
            desc = L["OPT_NICK_ENABLE_DANDERS_DESC"],
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
            name = L["OPT_NICK_ENABLE_ELVUI"],
            desc = L["OPT_NICK_ENABLE_ELVUI_DESC"],
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
            name = L["OPT_NICK_ENABLE_VUHDO"],
            desc = L["OPT_NICK_ENABLE_VUHDO_DESC"],
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
            name = L["OPT_NICK_ENABLE_UNHALTED"],
            desc = L["OPT_NICK_ENABLE_UNHALTED_DESC"],
            nocombat = true
        },

        {
            type = "breakline"
        },
        {
            type = "button",
            name = L["OPT_NICK_WIPE"],
            desc = L["OPT_NICK_WIPE_DESC"],
            func = function(self)
                WipeNickNames()
            end,
            nocombat = true
        },
        {
            type = "button",
            name = L["OPT_NICK_EDIT"],
            desc = L["OPT_NICK_EDIT_DESC"],
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
