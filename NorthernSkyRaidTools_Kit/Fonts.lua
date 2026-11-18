-- ============================================================
--  Fonts.lua - window font helpers (kit)
--
--  Owns: NSI:GetWindowFontFlags, NSI:SetUIFont, NSI:RefreshUIFonts and the
--  registry that lets a language/font change re-apply to every registered
--  FontString. Moved out of NorthernSkyRaidTools_UI/UI/Core.lua so modules that
--  only need the kit (not the options UI) get the same text rules.
--  Loads after Pixel.lua and Tooltip.lua, before Components.lua.
-- ============================================================
local NSI = _G.NorthernSkyRaidTools

NSI.UIFontRegistry = NSI.UIFontRegistry or {}

-- Text inside windows is never outlined: outline is for text drawn over the game
-- world. The user's GlobalFontFlags still drive in-world displays untouched; windows
-- keep its other flags (SLUG, MONOCHROME) and drop OUTLINE / THICKOUTLINE.
function NSI:GetWindowFontFlags()
    local flags = NSRT and NSRT.Settings and NSRT.Settings.GlobalFontFlags or ""
    if flags == "" then return "" end
    local kept = {}
    for flag in flags:gmatch("[^,%s]+") do
        if flag ~= "OUTLINE" and flag ~= "THICKOUTLINE" then
            kept[#kept + 1] = flag
        end
    end
    return table.concat(kept, ", ")
end

-- size is a number or a type-scale name from STYLE.type ("title", "body", "label",
-- "small", "tiny"). flags: nil follows GetWindowFontFlags(); "" forces plain text.
function NSI:SetUIFont(object, size, flags)
    if not object or not object.SetFont then return end
    local explicitFlags = flags
    flags = flags or self:GetWindowFontFlags()
    local style = self.UI and self.UI.Style
    if type(size) == "string" then
        size = style and style.FontSize(size)
    end
    if not size and object.GetFont then
        local ok, _, currentSize = pcall(object.GetFont, object)
        if ok then size = currentSize end
    end
    size = size or 12
    local ok = pcall(object.SetFont, object, self:GetUIFontPath(), size, flags)
    if not ok then
        pcall(object.SetFont, object, self:GetFallbackUIFontPath(), size, flags)
    end
    -- Remember what the caller asked for (not the resolved default) so a later change
    -- of the global flags is followed on the next RefreshUIFonts.
    self.UIFontRegistry[object] = {size = size, flags = explicitFlags}
end

function NSI:RefreshUIFonts()
    for object, info in pairs(self.UIFontRegistry) do
        if object and object.SetFont then
            local flags = info.flags or self:GetWindowFontFlags()
            local ok = pcall(object.SetFont, object, self:GetUIFontPath(), info.size, flags)
            if not ok then
                pcall(object.SetFont, object, self:GetFallbackUIFontPath(), info.size, flags)
            end
        else
            self.UIFontRegistry[object] = nil
        end
    end
end
