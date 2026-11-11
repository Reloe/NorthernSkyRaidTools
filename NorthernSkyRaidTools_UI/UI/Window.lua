-- ============================================================
--  NSRT UI Window
--
--  The window shell for the options UI. It replaces DF:CreateSimplePanel for the
--  main window (NSUI). One Window.Create call builds:
--    - the window frame: dark backdrop, drag to move, Escape and right-click close
--    - a title bar: centred title, optionally flanked by two logos
--    - a header button chain on the right of the title bar. The close button is the
--      first link; window:AddHeaderButton(button) adds the next one on its left
--    - window:CreateScaleControl(config): the user scale slider, left of the title bar
--    - a footer: free text (version / author) and a copyable Discord link
--
--  Look and behaviour match the DF panel it replaces; only the header buttons moved.
--  Loads after Components.lua (it uses CreateButton and CreateSlider) and depends on
--  Pixel.lua. Exported as NSI.UI.Window.
--
--  Window.Create(opts)
--    name          global frame name (also the Escape-close key)       required
--    width/height  window size                                         required
--    headerHeight  title bar + gaps, default 36
--    footerHeight  default 20
--    strata        default "HIGH"
--    title         title text (colour codes allowed)
--    titleIcons    { left = {texture, size}, right = {texture, size} }
--    discordUrl    URL shown (and selectable) in the footer
--    userScale     number | function -> user scale; puts the window in pixel space
--
--  Returned frame (a plain WoW Frame plus):
--    .TitleBar .Title .Footer .Close   (.StatusBar and .closeButton are aliases)
--    :SetTitle(text)  :SetFooterText(text)  :SetDiscordUrl(url)
--    :AddHeaderButton(button)  :CreateScaleControl(config)
-- ============================================================

local NSI = _G.NorthernSkyRaidTools
local Pixel      = NSI.UI.Pixel
local Components = NSI.UI.Components
local STYLE      = NSI.UI.Style

local WHITE      = [[Interface\Buttons\WHITE8X8]]
local CLOSE_ICON = [[Interface\AddOns\NorthernSkyRaidTools\Media\Icons\x.png]]

local EDGE_INSET  = 2    -- title bar / footer inset from the window edge, px
local HEADER_BTN  = 26   -- header button size, px
local HEADER_GAP  = 6    -- gap between header buttons
local HEADER_PAD  = 4    -- gap between the last header button and the title bar edge
local SCALE_W     = 160  -- scale slider width

local Window = {}

local function StopMoving(window)
    if window._moving then
        window._moving = false
        window:StopMovingOrSizing()
    end
end

local function MakeTitleIcon(parent, spec)
    if not spec then return nil end
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(spec.size, spec.size)
    local tex = holder:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    tex:SetTexture(spec.texture)
    return holder
end

local function RegisterEscapeClose(name)
    for _, existing in ipairs(UISpecialFrames) do
        if existing == name then return end
    end
    table.insert(UISpecialFrames, name)
end

function Window.Create(opts)
    local name         = opts.name
    local headerHeight = opts.headerHeight or 36
    local footerHeight = opts.footerHeight or 20

    -- ---- frame ----------------------------------------------------------
    local window = Pixel.CreateBoxFrame("Frame", name, UIParent)
    window:SetSize(opts.width, opts.height)
    window:SetPoint("CENTER")
    window:SetFrameStrata(opts.strata or "HIGH")
    window:SetFrameLevel(1)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    window:SetBackdropColor(0, 0, 0, 0.9)
    window:SetBackdropBorderColor(0, 0, 0, 1)

    -- Left-drag anywhere on the window itself moves it; right-click closes it.
    -- (Child widgets take their own clicks, so this only sees empty space.)
    window:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            StopMoving(self)
            self:Hide()
            return
        end
        if not self._moving then
            self._moving = true
            self:StartMoving()
        end
    end)
    window:SetScript("OnMouseUp", StopMoving)
    window:HookScript("OnHide", StopMoving)

    if opts.closeOnEscape ~= false then
        RegisterEscapeClose(name)
    end

    -- ---- title bar ------------------------------------------------------
    local titleBar = Pixel.CreateBoxFrame("Frame", name .. "TitleBar", window)
    titleBar:SetPoint("TOPLEFT", window, "TOPLEFT", EDGE_INSET, -EDGE_INSET)
    titleBar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -EDGE_INSET, -EDGE_INSET)
    titleBar:SetHeight(headerHeight - EDGE_INSET * 2)
    titleBar:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    titleBar:SetBackdropColor(0.2, 0.2, 0.2, 1)
    titleBar:SetBackdropBorderColor(0, 0, 0, 1)

    local title = titleBar:CreateFontString(name .. "Title", "OVERLAY")
    NSI:SetUIFont(title, "title")
    title:SetTextColor(unpack(STYLE.text_soft))
    title:SetPoint("CENTER", titleBar, "CENTER")
    title:SetText(opts.title or "")
    STYLE.TrackAccentText(title)   -- follows the accent colour

    local icons = opts.titleIcons
    local iconLeft = MakeTitleIcon(titleBar, icons and icons.left)
    if iconLeft then iconLeft:SetPoint("RIGHT", title, "LEFT", -4, 0) end
    local iconRight = MakeTitleIcon(titleBar, icons and icons.right)
    if iconRight then iconRight:SetPoint("LEFT", title, "RIGHT", 4, 0) end

    window.TitleBar = titleBar
    window.Title    = title

    function window:SetTitle(text)
        title:SetText(text or "")
    end

    -- ---- header button chain (right side) -------------------------------
    local headerButtons = {}
    window.headerButtons = headerButtons

    -- button: a Components button object (or a plain frame). Add buttons in the order
    -- they should appear from the right edge: the first one added sits at the edge.
    function window:AddHeaderButton(button)
        local frame = button.frame or button
        if frame:GetParent() ~= titleBar then frame:SetParent(titleBar) end
        local previous = headerButtons[#headerButtons]
        frame:ClearAllPoints()
        if previous then
            frame:SetPoint("RIGHT", previous, "LEFT", -HEADER_GAP, 0)
        else
            frame:SetPoint("RIGHT", titleBar, "RIGHT", -HEADER_PAD, 0)
        end
        headerButtons[#headerButtons + 1] = frame
        return button
    end

    local close = Components.CreateButton(titleBar, "", function() window:Hide() end,
        HEADER_BTN, HEADER_BTN, name .. "CloseButton", CLOSE_ICON)
    Components.StyleBareIconButton(close, 16)
    window:AddHeaderButton(close)
    window.Close = close.frame
    window.closeButton = close.frame

    -- ---- scale control (left side) --------------------------------------
    -- config.scale is the saved user scale. The slider applies on release (the
    -- window resizing under the cursor mid-drag would fight the drag).
    function window:CreateScaleControl(config)
        if self.ScaleControl then return self.ScaleControl end
        local slider = Components.CreateSlider(titleBar, NSI:Loc("Scale"),
            function() return tonumber(config.scale) or 1 end,
            function(_, value)
                config.scale = value
                self:SetScale(value)
            end,
            SCALE_W, 22, 0.6, 1.6, 0.05, name .. "ScaleSlider", nil, false, nil, nil, 44)
        slider:SetLocaleKey("Scale")
        slider.frame:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
        self.ScaleControl = slider
        return slider
    end

    -- ---- footer ---------------------------------------------------------
    local footer = Pixel.CreateBoxFrame("Frame", name .. "Footer", window)
    -- Flush with the window edge, like the DF status bar: the sidebar and tab frames
    -- end exactly where the footer begins.
    footer:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT")
    footer:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT")
    footer:SetHeight(footerHeight)
    footer:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    footer:SetBackdropColor(0.1215, 0.1176, 0.1294, 0.7)   -- DF's default panel colour, as before
    footer:SetBackdropBorderColor(0, 0, 0, 0.95)

    local info = footer:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(info, "small")
    info:SetTextColor(unpack(STYLE.text_muted))
    info:SetJustifyH("LEFT")
    info:SetPoint("LEFT", footer, "LEFT", 8, 0)
    footer.authorName = info   -- the name the DF status bar used

    local discordLabel = footer:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(discordLabel, "small")
    discordLabel:SetTextColor(unpack(STYLE.text_muted))
    discordLabel:SetText("Discord:")
    discordLabel:SetPoint("LEFT", info, "RIGHT", 20, 0)

    -- A read-only edit box: clicking selects the whole URL so Ctrl+C copies it, and any
    -- typing puts the URL back.
    local discordUrl = ""
    local discord = Pixel.CreateBoxFrame("EditBox", nil, footer)
    discord:SetSize(200, footerHeight - 2)
    discord:SetPoint("LEFT", discordLabel, "RIGHT", 4, 0)
    discord:SetFrameLevel(footer:GetFrameLevel() + 2)
    discord:SetAutoFocus(false)
    discord:SetTextInsets(4, 4, 0, 0)
    NSI:SetUIFont(discord, "small")
    discord:SetTextColor(unpack(STYLE.text_muted))
    discord:SetBackdrop({ bgFile = WHITE })
    discord:SetBackdropColor(0, 0, 0, 0.25)
    discord:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    discord:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
    discord:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(discordUrl)
            self:HighlightText()
        end
    end)
    discord:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discord:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    footer.discordLabel = discordLabel
    footer.discordTextEntry = discord   -- the name the DF status bar used

    window.Footer    = footer
    window.StatusBar = footer

    function window:SetFooterText(text)
        info:SetText(text or "")
    end

    function window:SetDiscordUrl(url)
        discordUrl = url or ""
        discord:SetText(discordUrl)
        discord:SetCursorPosition(0)
    end
    window:SetDiscordUrl(opts.discordUrl)

    -- ---- combat banner (right end of the footer) ------------------------
    -- The window stays usable in combat; controls that change protected or restricted
    -- state are disabled by their `nocombat` flag. This says why. Combat flips on
    -- PLAYER_REGEN_*, and the truth is re-read every time the window opens, so a missed
    -- event while it was closed cannot leave it stale. Events are registered only while
    -- the window is shown.
    local banner = footer:CreateFontString(nil, "OVERLAY")
    NSI:SetUIFont(banner, "small")
    banner:SetTextColor(1, 0.75, 0.25, 1)
    banner:SetPoint("RIGHT", footer, "RIGHT", -26, 0)   -- clear of the resize grip
    banner:Hide()
    window.CombatBanner = banner
    local combatWatcher = CreateFrame("Frame", nil, window)
    local function RefreshBanner()
        if InCombatLockdown() then
            banner:SetText(NSI:Loc("In combat: some settings are locked until combat ends"))
            banner:Show()
        else
            banner:Hide()
        end
    end
    combatWatcher:SetScript("OnEvent", RefreshBanner)
    window:HookScript("OnShow", function()
        combatWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
        combatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
        RefreshBanner()
    end)
    window:HookScript("OnHide", function() combatWatcher:UnregisterAllEvents() end)

    -- ---- resizing ---------------------------------------------------------
    -- A grip in the bottom right corner. The window never gets smaller than the size the
    -- screens were designed for (minWidth / minHeight, default the creation size) nor
    -- larger than the screen. Tab frames are anchored to the window's corners, so they
    -- follow the drag live; the heavier relayout (menu columns...) runs once on release
    -- through the OnResizeDone callbacks. The size is saved in config.width / config.height.
    local minW = opts.minWidth or opts.width
    local minH = opts.minHeight or opts.height
    local sizeConfig
    local resizeCallbacks = {}
    window:SetResizable(true)

    local function SizeBounds()
        local ratio = UIParent:GetEffectiveScale() / window:GetEffectiveScale()
        local maxW = math.max(minW, math.floor(UIParent:GetWidth() * ratio) - 20)
        local maxH = math.max(minH, math.floor(UIParent:GetHeight() * ratio) - 20)
        return maxW, maxH
    end

    local function ClampSize(width, height)
        local maxW, maxH = SizeBounds()
        return math.max(minW, math.min(maxW, width)), math.max(minH, math.min(maxH, height))
    end

    -- Registers fn(width, height), called after the user lets go of the grip and after a
    -- saved size is applied.
    function window:OnResizeDone(fn) resizeCallbacks[#resizeCallbacks + 1] = fn end

    local function Finish()
        local width, height = ClampSize(window:GetWidth(), window:GetHeight())
        window:SetSize(width, height)
        if sizeConfig then
            sizeConfig.width, sizeConfig.height = math.floor(width + 0.5), math.floor(height + 0.5)
        end
        for _, fn in ipairs(resizeCallbacks) do fn(width, height) end
    end

    -- Applies the saved size (config.width / config.height) and keeps writing back to it.
    function window:BindSize(config)
        sizeConfig = config
        local width, height = tonumber(config.width), tonumber(config.height)
        if width and height then
            width, height = ClampSize(width, height)
            window:SetSize(width, height)
        end
    end

    local grip = CreateFrame("Button", nil, window)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -1, 1)
    grip:SetFrameLevel(window:GetFrameLevel() + 50)
    grip:SetNormalTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
    grip:SetPushedTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
    grip:SetHighlightTexture([[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
    grip:GetNormalTexture():SetVertexColor(1, 1, 1, 0.7)
    STYLE.PaintAccent(grip:GetHighlightTexture(), "SetVertexColor", 1)
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" then return end
        local maxW, maxH = SizeBounds()
        window:SetResizeBounds(minW, minH, maxW, maxH)
        window._sizing = true
        window:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        if not window._sizing then return end
        window._sizing = false
        window:StopMovingOrSizing()
        Finish()
    end)
    window:HookScript("OnHide", function()
        if window._sizing then
            window._sizing = false
            window:StopMovingOrSizing()
            Finish()
        end
    end)
    window.resizeGrip = grip

    -- ---- pixel space ----------------------------------------------------
    if opts.userScale ~= nil then
        Pixel.PixelSpace(window, opts.userScale)
    end

    return window
end

NSI.UI = NSI.UI or {}
NSI.UI.Window = { Create = Window.Create }
