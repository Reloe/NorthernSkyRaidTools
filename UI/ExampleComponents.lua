-- ============================================================
--  NSRT Component System — Usage Reference
--  Not loaded by the addon (.toc excluded).
--
--  All components live at NSI.UI.Components (aliased as C below).
--  Every component returns an object whose :SetPoint / :SetSize
--  delegate to the underlying container frame, so they can be
--  positioned just like normal WoW frames.
-- ============================================================

-- Convenience alias used throughout this file:
local C = NSI.UI.Components


-- ============================================================
--  CreateButton
--
--  Full-size action button with hover glow, optional icon, and
--  select/deselect state (used for tab bars, toggles, etc.).
--
--  C.CreateButton(parent, text, onClick, width, height, name, icon, textSize)
--
--  parent    – WoW frame to parent to
--  text      – display string (required)
--  onClick   – function(buttonObj) | nil
--  width     – number | nil  (nil = auto-fit text + 20px padding)
--  height    – number | nil  (default 26)
--  name      – string | nil  global frame name, e.g. "MyAddonBtn"
--  icon      – LSM statusbar key | nil  shown left of text at 14px
--  textSize  – number | nil  font size override (default STYLE.text_size=14)
--
--  Returned object
--    .frame           WoW Button
--    .label           FontString
--    :SetText(s)
--    :GetText()       → string
--    :SetFont(path, size, flags)
--    :SetTextColor(r, g, b [,a])
--    :SetPoint(...)   delegates to .frame
--    :SetSize(w, h)   delegates to .frame
--    :GetWidth()      delegates to .frame
--    :GetHeight()     delegates to .frame
--    :Select()        activates cyan selected background
--    :Deselect()      clears selected background
--    :IsSelected()    → bool
--    :Enable()
--    :Disable()       dims the label
-- ============================================================

local btn = C.CreateButton(parent, "Save", function(obj)
    print("clicked!", obj:GetText())
end)
btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)

-- With explicit size and icon:
local btn2 = C.CreateButton(parent, "Settings", onClick, 120, 26, nil, "Blizzard Raid")
btn2:SetPoint("LEFT", btn.frame, "RIGHT", 4, 0)

-- As a toggle (tab bar pattern):
local tab = C.CreateButton(parent, "General", nil, 100)
tab:Select()    -- highlights with cyan bg
tab:Deselect()  -- removes highlight


-- ============================================================
--  CreateSubButton
--
--  Lighter variant of CreateButton. Fixed height 18, font 12.
--  Same API, no icon support.
--
--  C.CreateSubButton(parent, text, onClick, width, name)
-- ============================================================

local sub = C.CreateSubButton(parent, "Reset", function() end, 60)
sub:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -4)


-- ============================================================
--  CreateCheckButton
--
--  Full-row toggle. Clicking anywhere on the row fires setValue.
--  The checkbox square turns cyan when checked.
--
--  C.CreateCheckButton(parent, label, getValue, setValue, width, height)
--
--  parent    – WoW frame
--  label     – display string shown right of the box
--  getValue  – function() → bool
--  setValue  – function(bool)
--  width     – number | nil  (default 180)
--  height    – number | nil  (default 22)
--
--  Returned object
--    .frame
--    .label       FontString
--    :SetValue(bool)
--    :GetValue()  → bool
--    :SetPoint(...)
--    :SetSize(w, h)
-- ============================================================

local chk = C.CreateCheckButton(parent, "Show Timer",
    function()    return MySettings.ShowTimer            end,
    function(v)   MySettings.ShowTimer = v               end,
    200, 22)
chk:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -30)


-- ============================================================
--  CreateTextEntry
--
--  Label on the left, 60px EditBox on the right.
--  Commits on Enter or focus-lost; Escape reverts.
--  Numeric mode clamps input to [minVal, maxVal].
--
--  C.CreateTextEntry(parent, label, getValue, setValue, width, height,
--                    numeric, minVal, maxVal)
--
--  parent    – WoW frame
--  label     – display string
--  getValue  – function() → string|number
--  setValue  – function(value)
--  width     – number | nil  (default 220)
--  height    – number | nil  (default 22)
--  numeric   – bool | nil    if true, only accepts numbers
--  minVal    – number | nil  lower clamp (numeric mode only)
--  maxVal    – number | nil  upper clamp (numeric mode only)
--
--  Returned object
--    .frame
--    .label     FontString
--    .editBox   WoW EditBox
--    :SetValue(v)
--    :GetValue()  → string|number
--    :SetPoint(...)
--    :SetSize(w, h)
-- ============================================================

-- Plain text:
local nameEntry = C.CreateTextEntry(parent, "Custom Text",
    function()    return MySettings.CustomText           end,
    function(v)   MySettings.CustomText = v              end)
nameEntry:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -60)

-- Numeric with range:
local sizeEntry = C.CreateTextEntry(parent, "Font Size",
    function()    return MySettings.FontSize             end,
    function(v)   MySettings.FontSize = v                end,
    220, 22, true, 8, 72)
sizeEntry:SetPoint("TOPLEFT", nameEntry.frame, "BOTTOMLEFT", 0, -4)


-- ============================================================
--  CreateDropdown
--
--  Label on the left, styled button on the right. Clicking opens
--  a scrollable popup list. Scrolls via mouse wheel; a scrollbar
--  appears when the list exceeds 10 rows. Right-clicking the
--  arrow area closes any open popup.
--
--  C.CreateDropdown(parent, label, getItems, getSelected, width, height)
--
--  parent      – WoW frame
--  label       – string | nil  (pass nil/"" for a full-width button)
--  getItems    – function() → array of { label=s, value=any, onclick=fn }
--               (BuildWidgets constructs getItems automatically; see below)
--  getSelected – function() → display string for the current value
--  width       – number | nil  (default 220)
--  height      – number | nil  (default 22)
--
--  Returned object
--    .frame
--    .label     FontString (nil if no label)
--    .dropBtn   WoW Button
--    :Refresh()           re-reads getSelected and updates text
--    :Close()             hides the popup
--    :SetPoint(...)
--    :SetSize(w, h)
--    :GetWidth()
-- ============================================================

local function makeItems()
    return {
        { label = "Alpha", value = "alpha", onclick = function(_, _, v) MySettings.Mode = v end },
        { label = "Beta",  value = "beta",  onclick = function(_, _, v) MySettings.Mode = v end },
    }
end
local function getSelected()
    return MySettings.Mode or "alpha"
end

local dd = C.CreateDropdown(parent, "Mode", makeItems, getSelected, 220)
dd:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -90)


-- ============================================================
--  CreateSlider
--
--  Label on the left, thin track + thumb in the middle, live
--  value readout on the right. setValue fires only on mouse
--  release (not during drag). Keyboard arrow keys fire
--  immediately. Right-click the value to type a number manually.
--
--  C.CreateSlider(parent, label, getValue, setValue,
--                 width, height, minVal, maxVal, step)
--
--  parent    – WoW frame
--  label     – display string
--  getValue  – function() → number
--  setValue  – function(number)   fires on mouse release / keyboard / typed entry
--  width     – number | nil  (default 220)
--  height    – number | nil  (default 22)
--  minVal    – number | nil  (default 0)
--  maxVal    – number | nil  (default 100)
--  step      – number | nil  (nil = smooth / float; e.g. 1 for integers)
--
--  Returned object
--    .frame
--    .label    FontString
--    .slider   native WoW Slider widget
--    :SetValue(n)   programmatic set (does not fire setValue)
--    :GetValue()    → number
--    :SetPoint(...)
--    :SetSize(w, h)
--    :GetWidth()
-- ============================================================

-- Integer slider 0–100:
local alphaSlider = C.CreateSlider(parent, "Opacity",
    function()    return MySettings.Alpha                end,
    function(v)   MySettings.Alpha = v                   end,
    220, 22, 0, 100, 1)
alphaSlider:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -120)

-- Float slider (step < 1 → shows 2 decimal places):
local scaleSlider = C.CreateSlider(parent, "Scale",
    function()    return MySettings.Scale                end,
    function(v)   MySettings.Scale = v                   end,
    220, 22, 0.5, 2.0, 0.05)
scaleSlider:SetPoint("TOPLEFT", alphaSlider.frame, "BOTTOMLEFT", 0, -4)

-- Smooth float (no step):
local smoothSlider = C.CreateSlider(parent, "Blend",
    function()    return MySettings.Blend                end,
    function(v)   MySettings.Blend = v                   end,
    220, 22, 0, 1)
smoothSlider:SetPoint("TOPLEFT", scaleSlider.frame, "BOTTOMLEFT", 0, -4)


-- ============================================================
--  CreateColorPicker
--
--  Label on the left, color swatch on the right. Clicking opens
--  WoW's native ColorPickerFrame with alpha/opacity support.
--  The swatch previews live as the picker moves and restores
--  on cancel. Works with both the modern (10.x+) and legacy APIs.
--
--  C.CreateColorPicker(parent, label, getValue, setValue, width, height)
--
--  parent    – WoW frame
--  label     – display string
--  getValue  – function() → r, g, b, a   (all 0–1)
--  setValue  – function(r, g, b, a)
--  width     – number | nil  (default 220)
--  height    – number | nil  (default 22)
--
--  Returned object
--    .frame
--    .label      FontString
--    .colorTex   Texture (the swatch fill)
--    :Refresh()  re-reads getValue and repaints the swatch
--    :SetPoint(...)
--    :SetSize(w, h)
--    :GetWidth()
-- ============================================================

local colorPicker = C.CreateColorPicker(parent, "Bar Color",
    function()
        local c = MySettings.Color
        return c[1], c[2], c[3], c[4]
    end,
    function(r, g, b, a)
        MySettings.Color = { r, g, b, a }
    end)
colorPicker:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -150)


-- ============================================================
--  CreateLabel
--
--  Read-only dimmed text row. Useful as a section header above
--  a group of controls.
--
--  C.CreateLabel(parent, text, width, height)
--
--  parent  – WoW frame
--  text    – display string
--  width   – number | nil  (default 220)
--  height  – number | nil  (default 16)
--
--  Returned object
--    .frame
--    .label   FontString
--    :SetText(s)
--    :SetPoint(...)
--    :SetSize(w, h)
--    :GetWidth()
-- ============================================================

local lbl = C.CreateLabel(parent, "Icon Settings")
lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -180)


-- ============================================================
--  CreateBreakline
--
--  Thin horizontal rule for separating sections. Renders as a
--  1px cyan line centred vertically in its container.
--
--  C.CreateBreakline(parent, width, height)
--
--  parent  – WoW frame
--  width   – number | nil  (default 220)
--  height  – number | nil  (default 10)  the rule sits at vertical centre
--
--  Returned object
--    .frame
--    :SetPoint(...)
--    :SetSize(w, h)
--    :GetWidth()
-- ============================================================

local rule = C.CreateBreakline(parent, 220)
rule:SetPoint("TOPLEFT", lbl.frame, "BOTTOMLEFT", 0, -2)


-- ============================================================
--  BuildWidgets
--
--  The preferred way to build a settings panel. Accepts an
--  ordered array of descriptor tables and stacks them top-to-
--  bottom with a 4px gap. Returns the total height consumed so
--  the parent can be resized to fit.
--
--  C.BuildWidgets(parent, definitions, width) → totalHeight
--
--  parent      – WoW frame (TOPLEFT = origin)
--  definitions – ordered array of descriptor tables (see types below)
--  width       – number  pixel width available; passed to every widget
--
--  Each descriptor must have a Type field. All other fields are
--  optional unless marked required (*).
--
--  ── Descriptor types ──────────────────────────────────────────
--
--  Slider / Scale   ("Scale" is a legacy alias for "Slider")
--    { Type="Slider", label*=s, get*=fn, set*=fn,
--      min=n, max=n, step=n, height=n }
--
--  Dropdown
--    { Type="Dropdown", label=s, get*=fn, set*=fn,
--      values*=tbl|fn, height=n }
--
--    values can be a static table or a function that returns one:
--      values = { {label="Option A", value="a"}, {label="Option B", value="b"} }
--      values = function() return NSI.LSM:List("font") ... end
--
--    get() should return the currently stored raw value.
--    BuildWidgets handles the value→label lookup automatically.
--
--  Color
--    { Type="Color", label*=s, get*=fn, set*=fn, height=n }
--    get() → r, g, b, a  (0–1 each)
--    set(r, g, b, a)
--
--  Checkbox
--    { Type="Checkbox", label*=s, get*=fn, set*=fn, height=n }
--
--  TextEntry
--    { Type="TextEntry", label*=s, get*=fn, set*=fn,
--      numeric=bool, min=n, max=n, height=n }
--
--  Label
--    { Type="Label", text*=s, height=n }
--
--  Breakline
--    { Type="Breakline", height=n }
--
--  Default row heights (overridable per-descriptor with height=n):
--    Slider / Scale / Dropdown / Color / Checkbox / TextEntry → 22
--    Label → 16
--    Breakline → 10
-- ============================================================

-- Example: a full settings panel built from a descriptor table.
local defs = {
    { Type = "Label",    text  = "Display" },
    { Type = "Breakline" },
    { Type = "Slider",   label = "Width",       get = function() return S.Width   end,
                                                 set = function(v) S.Width = v    end,
                                                 min = 20,  max = 300, step = 1 },
    { Type = "Slider",   label = "Height",      get = function() return S.Height  end,
                                                 set = function(v) S.Height = v   end,
                                                 min = 10,  max = 100, step = 1 },
    { Type = "Slider",   label = "Spacing",     get = function() return S.Spacing end,
                                                 set = function(v) S.Spacing = v  end,
                                                 min = -5,  max = 20,  step = 1 },
    { Type = "Label",    text  = "Text" },
    { Type = "Breakline" },
    { Type = "Dropdown", label = "Font",        get = function() return S.Font    end,
                                                 set = function(v) S.Font = v     end,
                                                 values = function()
                                                     local list = NSI.LSM:List("font")
                                                     local t = {}
                                                     for _, name in ipairs(list) do
                                                         t[#t+1] = { label = name, value = name }
                                                     end
                                                     return t
                                                 end },
    { Type = "Slider",   label = "Font Size",   get = function() return S.FontSize end,
                                                 set = function(v) S.FontSize = v  end,
                                                 min = 8,   max = 72,  step = 1 },
    { Type = "Color",    label = "Text Color",  get = function()
                                                         local c = S.colors
                                                         return c[1], c[2], c[3], c[4]
                                                     end,
                                                 set = function(r,g,b,a)
                                                         S.colors = {r,g,b,a}
                                                     end },
    { Type = "Label",    text  = "Options" },
    { Type = "Breakline" },
    { Type = "Checkbox", label = "Center Aligned",
                         get = function() return S.CenterAligned end,
                         set = function(v) S.CenterAligned = v   end },
}

local content = CreateFrame("Frame", nil, parent)
content:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
content:SetWidth(220)

local totalH = C.BuildWidgets(content, defs, 220)
content:SetHeight(totalH)
