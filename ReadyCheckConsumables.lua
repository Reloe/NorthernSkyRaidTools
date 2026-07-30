local _, NSI               = ... -- Internal namespace

local issecretvalue        = issecretvalue or function() return false end

-- ============================================================================
--  Ready Check Consumables
--  A box of clickable raid consumables shown on ready check.
--  Click an icon to use the first item you own from that category.
-- ----------------------------------------------------------------------------
--  MAINTENANCE (Midnight and later - keep the tables small, current-content only):
--    A category is a list of `variants`. Each variant ties ONE buff (shared across
--    item qualities) to an ORDERED list of item IDs that grant it:
--        { buffs = { <buffSpellID> }, items = { <best quality>, <next>, ... } }
--    * items -> parsed in order; the first one you own is used on click.
--    * buffs -> aura spellID(s) the variant grants (timer + rebuff glow).
--    * Add a new quality -> add an item ID to that variant's `items`.
--    * Add a new flask/oil TYPE (different buff) -> add another variant.
--    Weapon variants use `enchants = { <enchantID> }` instead of `buffs` (the timer
--    comes from the weapon-enchant API; enchants only identify which oil you used).
--    Simple categories may skip `variants` and just give `items` (+ optional
--    `buffs` / `buffIcons`); they are treated as a single variant.
--    * buffIcons -> { [iconFileID] = true } fallback (e.g. generic "Well Fed" icon).
--    * perWeaponHand -> one icon per equipped weapon.
--    * warlockOnly   -> only shown for Warlocks.
--  "Last used" (per character) remembers which TYPE (variant) you last had active
--  or clicked, and suggests it first next time (using whatever quality you own).
-- ============================================================================
local ConsumableCategories = {
    {
        key       = "food",
        label     = "Food / Feast",
        icon      = 136000, -- always show the generic "Well Fed" icon
        items     = {
            255845, -- Silvermoon Parade (Feast)      -- TODO verify / add a personal food fallback
            242275,
            255847,
            255848,
            242274,
        },
        -- 136000 = generic "Well Fed" icon: detects any food buff without a spellID.
        buffIcons = { [136000] = true },
    },
    {
        key      = "flask",
        label    = "Flask",
        -- One variant per flask TYPE: its buff + its item qualities (best first).
        variants = {
            {
                buffs = { 1235111 },                        -- Flask of the Shattered Sun (Crit)
                items = { 245929, 245928, 241326, 241327 }, -- Max Fleeting, Fleeting, Max Personal, Personal
            },
            {
                buffs = { 1235108 },                        -- Flask of the Magisters (Mastery)
                items = { 245933, 245932, 241322, 241323 }, -- Max Fleeting, Fleeting, Max Personal, Personal
            },
            {
                buffs = { 1235110 },                        -- Flask of the Blood Knights (Haste)
                items = { 245931, 245930, 241324, 241325 }, -- Max Fleeting, Fleeting, Max Personal, Personal
            },
            {
                buffs = { 1235057 },                        -- Flask of the Resistance (Vers)
                items = { 245926, 245927, 241320, 241321 }, -- Max Fleeting, Fleeting, Max Personal, Personal
            },
            -- { buffs = { <otherStatFlaskBuff> }, items = { <items...> } },
        },
    },
    {
        key           = "weapon",
        label         = "Weapon Enhancement",
        perWeaponHand = true, -- one icon per equipped weapon (main hand / off hand)
        -- One variant per oil/stone TYPE: its item qualities (best first) plus the
        -- enchant ID(s) it applies (used only to remember which oil you last had on).
        variants      = {
            {
                enchants = {},                 -- TODO add the weapon-enchant ID(s) for remembering
                items    = { 243734, 243733 }, -- Refulgent Whetstone / Weightstone  -- TODO verify
            },
        },
    },
    {
        key   = "rune",
        label = "Augment Rune",
        items = {
            259085,
        },
        buffs = {
            1264426
        },
    },
    {
        key         = "healthstone",
        label       = "Healthstone",
        warlockOnly = true, -- only Warlocks, who can make their own
        items       = {
            5512,           -- Healthstone
        },
        -- No buffs: a Healthstone is an instant heal, not a buff, so no glow/timer.
    },
}

-- Normalize every category to a `variants` list plus a flat `_allItems` list, so
-- the rest of the code only ever deals with one shape.
local function NormalizeCategory(cat)
    if not cat.variants then
        cat.variants = { {
            items     = cat.items,
            buffs     = cat.buffs,
            buffIcons = cat.buffIcons,
            enchants  = cat.enchants,
        } }
    end
    cat._allItems = {}
    for _, v in ipairs(cat.variants) do
        if v.items then
            for _, id in ipairs(v.items) do
                cat._allItems[#cat._allItems + 1] = id
            end
        end
    end
end

for _, cat in ipairs(ConsumableCategories) do
    NormalizeCategory(cat)
end

-- ---------------------------------------------------------------------------
--  Style / layout  (Northern Sky theme, mirrors UI/Components.lua)
-- ---------------------------------------------------------------------------
local COLOR_BG      = { 0.05, 0.05, 0.08, 0.97 }
local COLOR_BORDER  = { 0, 1, 1, 0.7 }
local ICON_SIZE     = 44
local SPACING       = 6
local PADDING       = 8
local QUESTION_MARK = 134400 -- fallback icon when item data isn't cached yet
local LOW_BUFF_SECS = 600    -- glow / warn when a buff has under 10 minutes left

local MAINHAND_SLOT = 16
local OFFHAND_SLOT  = 17
local WEAPON_CLASS  = 2 -- Enum.ItemClass.Weapon
local GLOW_KEY      = "NSIReadyCheckConsumables"

local container
local buttons       = {}
local hideTimer
local updateElapsed = 0

local function IsWarlock()
    local _, class = UnitClass("player")
    return class == "WARLOCK"
end

local function IsWeaponInSlot(slot)
    local itemID = GetInventoryItemID("player", slot)
    if not itemID then return false end
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
    return classID == WEAPON_CLASS
end

-- Whether the local player started this ready check. The initiator gets no
-- ready check popup to answer, so only they get the Close button.
local function IsPlayerTheInitiator(initiator)
    if not initiator then return false end
    if initiator == UnitGUID("player") then return true end
    if UnitIsUnit(initiator, "player") then return true end
    local name = UnitName("player")
    if initiator == name then return true end
    local realm = (GetRealmName() or ""):gsub("%s+", "")
    return initiator == (name .. "-" .. realm)
end

-- ---------------------------------------------------------------------------
--  Class / spec weapon overrides
--  Some specs use self-applied imbues / weapon rites instead of oils, so their
--  weapon slot is replaced by a single spell button that glows when any of the
--  buffs it should maintain is missing or low. Fill the TODO IDs in for Midnight;
--  unfilled tracking simply stays dormant (the button still shows and casts).
-- ---------------------------------------------------------------------------
local RITE_OF_SANCTIFICATION = 433568 -- Paladin (Lightsmith): cast
local RITE_SANCT_BUFF        = 7143   -- Paladin (Lightsmith): buff to track
local LIGHTNING_SHIELD       = 192106 -- Shaman: the click for ALL specs (applies the spec's imbues)
local THUNDERSTRIKE_WARD     = 7587   -- Elemental: off-hand SHIELD enchant ID (needs shield + talent)
local FLAMETONGUE_TALENT     = 318038 -- Flametongue Weapon talent spellID (IsPlayerSpell)
local EARTHLIVING_TALENT     = 382021 -- TODO Earthliving Weapon talent spellID
local THUNDERSTRIKE_TALENT   = 462757 -- TODO Thunderstrike Ward talent spellID
-- Exact imbue enchant IDs (GetWeaponEnchantInfo enchantID). Empty -> falls back to
-- "any temp enchant present" on that hand until you fill them in.
local WINDFURY_ENCH          = { 5401 } -- TODO Windfury Weapon enchant ID(s)
local FLAMETONGUE_ENCH       = { 5400 } -- TODO Flametongue Weapon enchant ID(s)
local EARTHLIVING_ENCH       = { 6498 } -- TODO Earthliving Weapon enchant ID(s)
local RITE_ENCH              = { 7143 } -- TODO Rite of Sanctification enchant ID(s)

local function PlayerClass()
    return select(2, UnitClass("player"))
end

local function PlayerSpec()
    return GetSpecialization() -- Shaman: 1 = Elemental, 2 = Enhancement, 3 = Restoration
end

local function HasShieldOffhand()
    local id = GetInventoryItemID("player", OFFHAND_SLOT)
    if not id then return false end
    local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(id)
    return classID == 4 and subClassID == 6 -- Armor / Shield
end

local function SpellTexture(id)
    if not id then return nil end
    return (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id))
        or (GetSpellTexture and GetSpellTexture(id))
end

local function SpellName(id)
    if not id then return nil end
    return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id))
        or (GetSpellInfo and GetSpellInfo(id))
end

-- Each override: `cast`/`icon` = the spell shown/cast, `requires` = the set that
-- must stay up (else glow). Add `applyToSlot = MAINHAND_SLOT/OFFHAND_SLOT` when the
-- spell creates a pending weapon enchant that should auto-apply to that hand (oil-style).
-- A requirement is one of:
--   { aura = spellID }                                        -- a self-buff (character aura)
--   { enchant = MAINHAND_SLOT|OFFHAND_SLOT, ids = { enchIDs } } -- a temporary weapon enchant
--       (read from GetWeaponEnchantInfo; add needsShield = true when the enchant
--        sits on an off-hand SHIELD, e.g. Thunderstrike Ward, so the weapon check is bypassed)
-- optional gates: needsShield, and talentGated + talent = <spellID>.
local WEAPON_OVERRIDES = {
    { -- Paladin: Lightsmith hero talent -> Rite of Sanctification (replaces oils)
        condition    = function()
            return PlayerClass() == "PALADIN" and IsPlayerSpell(RITE_OF_SANCTIFICATION)
        end,
        replacesOils = true,
        cast         = RITE_OF_SANCTIFICATION,
        icon         = RITE_OF_SANCTIFICATION,
        applyToSlot  = MAINHAND_SLOT, -- oil-style: apply the pending enchant to the main hand
        requires     = {
            { enchant = MAINHAND_SLOT, ids = RITE_ENCH },
        },
    },
    { -- Enhancement shaman: Windfury (MH) + Flametongue (OH) + Lightning Shield (replaces oils)
        condition    = function()
            return PlayerClass() == "SHAMAN" and PlayerSpec() == 2
        end,
        replacesOils = true,
        cast         = LIGHTNING_SHIELD,
        icon         = LIGHTNING_SHIELD,
        requires     = {
            { aura = LIGHTNING_SHIELD },
            { enchant = MAINHAND_SLOT, ids = WINDFURY_ENCH },
            { enchant = OFFHAND_SLOT,  ids = FLAMETONGUE_ENCH },
        },
    },
    { -- Elemental shaman WITH Flametongue Weapon talented: single Lightning Shield
        --   button (replaces oils); glows to reapply Flametongue if it drops off the weapon.
        condition    = function()
            return PlayerClass() == "SHAMAN" and PlayerSpec() == 1 and IsPlayerSpell(FLAMETONGUE_TALENT)
        end,
        replacesOils = true,
        cast         = LIGHTNING_SHIELD,
        icon         = LIGHTNING_SHIELD,
        requires     = {
            { aura = LIGHTNING_SHIELD },
            { enchant = MAINHAND_SLOT, ids = FLAMETONGUE_ENCH },
            { enchant = OFFHAND_SLOT,  ids = { THUNDERSTRIKE_WARD }, needsShield = true, talentGated = true, talent = THUNDERSTRIKE_TALENT },
        },
    },
    { -- Elemental shaman WITHOUT Flametongue Weapon: keep the oil buttons AND add a
        --   separate Lightning Shield button (additive, does not replace the oils).
        condition = function()
            return PlayerClass() == "SHAMAN" and PlayerSpec() == 1 and not IsPlayerSpell(FLAMETONGUE_TALENT)
        end,
        cast      = LIGHTNING_SHIELD,
        icon      = LIGHTNING_SHIELD,
        requires  = {
            { aura = LIGHTNING_SHIELD },
            { enchant = OFFHAND_SLOT, ids = { THUNDERSTRIKE_WARD }, needsShield = true, talentGated = true, talent = THUNDERSTRIKE_TALENT },
        },
    },
    { -- Restoration shaman: Lightning Shield + Earthliving (if talented) (replaces oils)
        condition    = function()
            return PlayerClass() == "SHAMAN" and PlayerSpec() == 3
        end,
        replacesOils = true,
        cast         = LIGHTNING_SHIELD,
        icon         = LIGHTNING_SHIELD,
        requires     = {
            { aura = LIGHTNING_SHIELD },
            { enchant = MAINHAND_SLOT, ids = EARTHLIVING_ENCH, talentGated = true, talent = EARTHLIVING_TALENT },
        },
    },
}

for _, cat in ipairs(ConsumableCategories) do
    if cat.key == "weapon" then cat.specialButtons = WEAPON_OVERRIDES end
end

local function AuraRemaining(aura)
    if aura.expirationTime and aura.expirationTime > 0 then
        return aura.expirationTime - GetTime()
    end
    return math.huge -- active but has no timer
end

local function RequirementActive(req)
    if req.needsShield then
        -- Off-hand SHIELD enchant (e.g. Thunderstrike Ward): needs a shield, not a weapon.
        if not HasShieldOffhand() then return false end
    elseif req.enchant and not IsWeaponInSlot(req.enchant) then
        -- Weapon imbue: only relevant when that hand actually holds a weapon.
        return false
    end
    if req.talentGated and not (req.talent and IsPlayerSpell(req.talent)) then return false end
    return true
end

local function RequirementRemaining(req)
    if req.aura then
        local a = C_UnitAuras.GetPlayerAuraBySpellID(req.aura)
        return a and AuraRemaining(a) or nil
    elseif req.enchant then
        local hasMH, mhExp, _, mhID, hasOH, ohExp, _, ohID = GetWeaponEnchantInfo()
        local has, exp, eid
        if req.enchant == MAINHAND_SLOT then
            has, exp, eid = hasMH, mhExp, mhID
        else
            has, exp, eid = hasOH, ohExp, ohID
        end
        if not has then return nil end
        if req.ids and #req.ids > 0 then -- exact match; empty list = any enchant counts
            local match = false
            for _, id in ipairs(req.ids) do
                if id == eid then
                    match = true
                    break
                end
            end
            if not match then return nil end
        end
        return exp and (exp / 1000) or math.huge
    end
    return nil
end

-- Shortest remaining among active requirements, plus whether any is missing.
local function EvaluateOverride(ov)
    local minRem, anyMissing = nil, false
    for _, req in ipairs(ov.requires) do
        if RequirementActive(req) then
            local rem = RequirementRemaining(req)
            if not rem then
                anyMissing = true
            elseif rem ~= math.huge and (not minRem or rem < minRem) then
                minRem = rem
            end
        end
    end
    return minRem, anyMissing
end

-- Returns the special button that REPLACES the oils (if any) plus a list of
-- additive special buttons that appear alongside the oils.
local function GetWeaponSpecials(cat)
    local replacer, extras = nil, {}
    if cat.specialButtons then
        for _, ov in ipairs(cat.specialButtons) do
            if ov.condition() then
                if ov.replacesOils then
                    replacer = replacer or ov
                else
                    extras[#extras + 1] = ov
                end
            end
        end
    end
    return replacer, extras
end
-- A variant is identified by its first (best) item, used as the "last used" key.
local function VariantKey(v)
    return v.items and v.items[1]
end

local function FirstOwnedItem(v)
    if not v.items then return nil end
    for _, id in ipairs(v.items) do
        if C_Item.GetItemCount(id) > 0 then return id end
    end
end

local function FindVariantByKey(cat, key)
    if not key then return nil end
    for _, v in ipairs(cat.variants) do
        if VariantKey(v) == key then return v end
    end
end

-- ---------------------------------------------------------------------------
--  "Last used" memory, stored per character in saved variables.
-- ---------------------------------------------------------------------------
local function GetRememberTable()
    NSRT.LastUsedConsumables = NSRT.LastUsedConsumables or {}
    local key = (NSI.GetProfileKey and NSI:GetProfileKey()) or "default"
    NSRT.LastUsedConsumables[key] = NSRT.LastUsedConsumables[key] or {}
    return NSRT.LastUsedConsumables[key]
end

local function GetRemembered(catKey)
    return GetRememberTable()[catKey]
end

local function SetRemembered(catKey, key)
    if key then GetRememberTable()[catKey] = key end
end

-- Returns: chosenID (item to use, or nil), displayID (icon), variant (chosen).
-- Prefers the remembered TYPE, then declared order; within a variant the items are
-- parsed in order and the first one you own is used.
local function ResolveCategory(cat)
    local preferred = FindVariantByKey(cat, GetRemembered(cat.key))
    if preferred then
        local owned = FirstOwnedItem(preferred)
        if owned then return owned, owned, preferred end
    end
    for _, v in ipairs(cat.variants) do
        local owned = FirstOwnedItem(v)
        if owned then return owned, owned, v end
    end
    local fallback = preferred or cat.variants[1]
    return nil, fallback and VariantKey(fallback), fallback
end

-- Build the ordered list of slots to render. Most categories map to one slot;
-- a perWeaponHand category maps to one slot per equipped weapon.
local function BuildSlotList()
    local slots   = {}
    local warlock = IsWarlock()
    for _, cat in ipairs(ConsumableCategories) do
        if cat.warlockOnly and not warlock then
            -- skipped: wrong class
        elseif cat.perWeaponHand then
            local replacer, extras = GetWeaponSpecials(cat)
            if replacer then
                -- Class/spec ability replaces the oil buttons with one spell button.
                slots[#slots + 1] = { cat = cat, override = replacer }
            elseif #cat._allItems > 0 then
                if IsWeaponInSlot(MAINHAND_SLOT) then
                    slots[#slots + 1] = { cat = cat, weaponSlot = MAINHAND_SLOT, handLabel = "MH" }
                end
                if IsWeaponInSlot(OFFHAND_SLOT) then
                    slots[#slots + 1] = { cat = cat, weaponSlot = OFFHAND_SLOT, handLabel = "OH" }
                end
            end
            -- Additive class buttons shown alongside the oils (e.g. Lightning Shield).
            for _, ex in ipairs(extras) do
                slots[#slots + 1] = { cat = cat, override = ex }
            end
        elseif #cat._allItems > 0 then
            slots[#slots + 1] = { cat = cat }
        end
    end
    return slots
end

-- Remaining seconds of a slot's buff. Weapon slots use the weapon-enchant API;
-- everything else checks the variants' auras (by spellID, then by icon fallback).
-- math.huge = permanent, nil = no buff active / no tracking configured.
local function GetSlotBuffRemaining(slot)
    if slot.weaponSlot then
        local hasMH, mhExp, _, _, hasOH, ohExp = GetWeaponEnchantInfo()
        if slot.weaponSlot == MAINHAND_SLOT then
            return hasMH and (mhExp / 1000) or nil
        else
            return hasOH and (ohExp / 1000) or nil
        end
    end

    local cat = slot.cat
    for _, v in ipairs(cat.variants) do
        if v.buffs then
            for _, spellID in ipairs(v.buffs) do
                local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
                if aura then return AuraRemaining(aura) end
            end
        end
    end

    -- Icon fallback: a single aura scan matched against any variant's buffIcons.
    local scanIcons
    for _, v in ipairs(cat.variants) do
        if v.buffIcons and next(v.buffIcons) then
            scanIcons = true
            break
        end
    end
    if scanIcons then
        for i = 1, 60 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then break end
            if not issecretvalue(aura.spellId) then
                for _, v in ipairs(cat.variants) do
                    if v.buffIcons and v.buffIcons[aura.icon] then
                        return AuraRemaining(aura)
                    end
                end
            end
        end
    end
    return nil
end

local function SlotHasBuffTracking(slot)
    if slot.weaponSlot then return true end
    for _, v in ipairs(slot.cat.variants) do
        if (v.buffs and #v.buffs > 0) or (v.buffIcons and next(v.buffIcons) ~= nil) then
            return true
        end
    end
    return false
end

-- Learn which flask / oil TYPE you currently have active, so it can be suggested
-- next time even if you applied it outside this bar.
local function DetectExternalUsage()
    for _, cat in ipairs(ConsumableCategories) do
        for _, v in ipairs(cat.variants) do
            if v.buffs then
                for _, spellID in ipairs(v.buffs) do
                    if C_UnitAuras.GetPlayerAuraBySpellID(spellID) then
                        SetRemembered(cat.key, VariantKey(v))
                        break
                    end
                end
            end
        end
        if cat.perWeaponHand then
            local _, _, _, mhID, _, _, _, ohID = GetWeaponEnchantInfo()
            if mhID or ohID then
                for _, v in ipairs(cat.variants) do
                    if v.enchants then
                        for _, eid in ipairs(v.enchants) do
                            if eid == mhID or eid == ohID then
                                SetRemembered(cat.key, VariantKey(v))
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

local function FormatDuration(sec)
    if sec >= 60 then
        return math.floor(sec / 60) .. "m"
    end
    return math.max(0, math.ceil(sec)) .. "s"
end

-- Refresh the buff timer text + glow for one visible button.
local function ApplyGlow(btn, needsRebuff)
    if needsRebuff and not btn.glowing then
        NSI.LCG.PixelGlow_Start(btn)
        btn.glowing = true
    elseif not needsRebuff and btn.glowing then
        NSI.LCG.PixelGlow_Stop(btn)
        btn.glowing = false
    end
end
local function UpdateButtonBuff(btn)
    local slot = btn.slot
    if not slot then return end

    if btn.override then
        local minRem, anyMissing = EvaluateOverride(btn.override)
        if minRem and minRem ~= math.huge then
            btn.duration:SetText(FormatDuration(minRem))
            btn.duration:SetTextColor(minRem < LOW_BUFF_SECS and 1 or 1,
                minRem < LOW_BUFF_SECS and 0.3 or 1, minRem < LOW_BUFF_SECS and 0.3 or 1, 1)
            btn.duration:Show()
        else
            btn.duration:SetText("")
            btn.duration:Hide()
        end
        -- Glow if the player can cast it and any tracked buff is missing / low.
        ApplyGlow(btn, btn.hasItem and (anyMissing or (minRem and minRem < LOW_BUFF_SECS)))
        return
    end
    local tracked   = SlotHasBuffTracking(slot)
    local remaining = tracked and GetSlotBuffRemaining(slot) or nil

    if remaining and remaining ~= math.huge then
        btn.duration:SetText(FormatDuration(remaining))
        if remaining < LOW_BUFF_SECS then
            btn.duration:SetTextColor(1, 0.3, 0.3, 1)
        else
            btn.duration:SetTextColor(1, 1, 1, 1)
        end
        btn.duration:Show()
    else
        btn.duration:SetText("")
        btn.duration:Hide()
    end

    -- Glow when the player owns the item but the buff is missing or running low.
    ApplyGlow(btn, btn.hasItem and tracked and (not remaining or remaining < LOW_BUFF_SECS))
end

-- Refresh the bag stack count (bag counts change as consumables are used).
local function UpdateButtonCount(btn)
    if not btn.chosenID then return end
    local count = C_Item.GetItemCount(btn.chosenID)
    btn.count:SetText(count and count > 1 and count or "")
end

local function StopGlow(btn)
    if btn.glowing then
        NSI.LCG.PixelGlow_Stop(btn)
        btn.glowing = false
    end
end

local function StopAllGlows()
    for _, btn in ipairs(buttons) do
        StopGlow(btn)
    end
end

local function Button_OnEnter(self)
    if self.currentSpell then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.currentSpell)
        GameTooltip:Show()
    elseif self.currentItem then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.currentItem)
        GameTooltip:Show()
    end
end

local function Button_OnLeave()
    GameTooltip:Hide()
end

-- Record which TYPE (variant) the player just used, as their "last used".
-- Also prints a diagnostic so we can see whether the click even reaches here.
local function Button_PostClick(self)
    if self.chosenVariant and self.slot then
        SetRemembered(self.slot.cat.key, VariantKey(self.chosenVariant))
    end
    if NSRTConsumablesDebug then -- toggle with: /run NSRTConsumablesDebug = true
        local name = self.chosenID and (C_Item.GetItemInfo(self.chosenID) or ("item:" .. self.chosenID))
        print(("|cFF00FFFFNSRT|r click: slot=%s type=%s chosenID=%s name=%s owned=%s macro=%q item=%s"):format(
            tostring(self.slot and self.slot.cat.key), tostring(self:GetAttribute("type")),
            tostring(self.chosenID), tostring(name),
            tostring(self.chosenID and C_Item.GetItemCount(self.chosenID)),
            tostring(self:GetAttribute("macrotext")), tostring(self:GetAttribute("item"))))
    end
end

-- Lazily grow the secure-button pool (only ever called out of combat).
local function AcquireButton(i)
    if buttons[i] then return buttons[i] end

    local btn = CreateFrame("Button", "NSIReadyCheckConsumable" .. i, container, "SecureActionButtonTemplate")
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetFrameLevel(container:GetFrameLevel() + 5)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints(btn)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Hand indicator (MH / OH) for weapon slots, top-left.
    btn.handLabel = btn:CreateFontString(nil, "OVERLAY")
    btn.handLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    btn.handLabel:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    btn.handLabel:SetTextColor(0, 1, 1, 1)
    btn.handLabel:Hide()

    -- Bag stack count, bottom-right corner.
    btn.count = btn:CreateFontString(nil, "OVERLAY")
    btn.count:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)

    -- Remaining buff time, centered inside the icon.
    btn.duration = btn:CreateFontString(nil, "OVERLAY")
    btn.duration:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    btn.duration:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.duration:Hide()

    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    btn:SetScript("OnEnter", Button_OnEnter)
    btn:SetScript("OnLeave", Button_OnLeave)
    btn:SetScript("PostClick", Button_PostClick)

    buttons[i] = btn
    return btn
end

-- Point a pooled button at a slot and lay it out at position `index`.
local function ConfigureButton(btn, slot, index)
    local cat    = slot.cat

    btn.slot     = slot
    btn.override = slot.override

    -- Reset stale action attributes (pooled buttons switch slot types).
    btn:SetAttribute("type", nil)
    btn:SetAttribute("macrotext", nil)
    btn:SetAttribute("item", nil)
    btn:SetAttribute("target-slot", nil)
    btn:SetAttribute("spell", nil)

    if slot.override then
        -- Class/spec ability: a single button that casts a self-buff / weapon rite
        -- (optionally applying a pending weapon enchant to a hand, oil-style).
        local ov          = slot.override
        btn.chosenID      = nil
        btn.chosenVariant = nil
        btn.currentItem   = nil
        btn.currentSpell  = ov.cast
        btn.hasItem       = IsPlayerSpell(ov.cast) and true or false -- can they cast it
        btn.icon:SetTexture(SpellTexture(ov.icon) or QUESTION_MARK)
        btn.icon:SetDesaturated(false)
        btn.count:SetText("")
        btn.handLabel:Hide()
        local spellName = SpellName(ov.cast) or tostring(ov.cast)
        if ov.applyToSlot then
            -- Spell creates a pending weapon enchant (like an oil): cast it, then
            -- apply it to the given weapon slot so it lands without a target cursor.
            btn:SetAttribute("type", "macro")
            btn:SetAttribute("macrotext",
                "/stopmacro [combat]\n/cast " .. spellName .. "\n/use " .. ov.applyToSlot)
        else
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("spell", spellName)
        end
    else
        local chosenID, displayID, variant = ResolveCategory(cat)
        -- cat.icon forces a fixed icon (e.g. food always shows the Well Fed icon);
        -- otherwise use the icon of the item that would be used / shown.
        local iconID                       = cat.icon or (displayID and C_Item.GetItemIconByID(displayID)) or
            QUESTION_MARK
        btn.chosenID                       = chosenID
        btn.chosenVariant                  = variant
        btn.currentSpell                   = nil
        -- Tooltip reflects only the item that will actually be used; none = no tooltip.
        btn.currentItem                    = chosenID
        btn.hasItem                        = chosenID ~= nil
        btn.icon:SetTexture(iconID)

        if chosenID then
            -- /use resolves items by name; the "item:ID" macro form does not work,
            -- so use the name (falling back to the item link for the secure item type).
            local itemName = C_Item.GetItemInfo(chosenID)
            if slot.weaponSlot then
                -- Apply the oil to that specific weapon via the secure target-slot.
                btn:SetAttribute("type", "item")
                btn:SetAttribute("item", itemName or ("item:" .. chosenID))
                btn:SetAttribute("target-slot", tostring(slot.weaponSlot))
            elseif itemName then
                btn:SetAttribute("type", "macro")
                btn:SetAttribute("macrotext", "/stopmacro [combat]\n/use " .. itemName)
            else
                btn:SetAttribute("type", "item")
                btn:SetAttribute("item", "item:" .. chosenID)
            end
            btn.icon:SetDesaturated(false)
            local count = C_Item.GetItemCount(chosenID)
            btn.count:SetText(count > 1 and count or "")
        else
            btn:SetAttribute("type", "macro")
            btn:SetAttribute("macrotext", "") -- greyed-out: clicking does nothing
            btn.icon:SetDesaturated(true)
            btn.count:SetText("")
        end

        if slot.handLabel then
            btn.handLabel:SetText(slot.handLabel)
            btn.handLabel:Show()
        else
            btn.handLabel:Hide()
        end
    end

    btn:ClearAllPoints()
    btn:SetPoint("LEFT", container, "LEFT", PADDING + (index - 1) * (ICON_SIZE + SPACING), 0)
    btn:Show()
    UpdateButtonBuff(btn)
end

local function CreateContainer()
    if container then return end

    container = CreateFrame("Frame", "NSIReadyCheckConsumables", UIParent, "BackdropTemplate")
    container:SetFrameStrata("DIALOG")
    container:SetToplevel(true)
    container:Hide()
    container:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
        tile = true,
        tileSize = 64,
    })
    container:SetBackdropColor(unpack(COLOR_BG))
    container:SetBackdropBorderColor(unpack(COLOR_BORDER))

    -- Draggable by its background. Position is never saved, so each ready check
    -- (which re-anchors the frame) resets it to the code-defined location.
    container:SetMovable(true)
    container:EnableMouse(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", function(self) self:StartMoving() end)
    container:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Themed Close button (shared component), full width, matching the container.
    container.closeButton = NSI.UI.Components.CreateButton(container, CLOSE, function()
        if hideTimer then
            hideTimer:Cancel()
            hideTimer = nil
        end
        container:Hide()
    end, 90, 24)
    container.closeButton:SetPoint("TOP", container, "BOTTOM", 0, -6)
    container.closeButton.frame:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
        tile = true,
        tileSize = 64,
    })
    container.closeButton.frame:SetBackdropColor(unpack(COLOR_BG))
    container.closeButton.frame:SetBackdropBorderColor(unpack(COLOR_BORDER))

    -- Tick the buff timers / glow while the box is visible.
    container:SetScript("OnUpdate", function(_, dt)
        updateElapsed = updateElapsed + dt
        if updateElapsed < 0.5 then return end
        updateElapsed = 0
        DetectExternalUsage()
        for _, btn in ipairs(buttons) do
            if btn:IsShown() then
                UpdateButtonBuff(btn)
                UpdateButtonCount(btn)
            end
        end
    end)

    -- Clean up glows whenever the box hides (answered / expired / closed).
    container:SetScript("OnHide", StopAllGlows)

    -- Hide our box when the ready check UI closes. ReadyCheckListenerFrame is
    -- shown for everyone including the initiator, so it's the anchor we use too.
    if ReadyCheckListenerFrame then
        ReadyCheckListenerFrame:HookScript("OnHide", function()
            if hideTimer then
                hideTimer:Cancel()
                hideTimer = nil
            end
            if container then container:Hide() end
        end)
    end
end

function NSI:ShowReadyCheckConsumables(initiator)
    if self:Restricted() then return end  -- auras are secret, do nothing
    if not NSRT.ReadyCheckSettings.ConsumablesDisplay then return end
    if InCombatLockdown() then return end -- can't configure secure buttons in combat

    CreateContainer()
    DetectExternalUsage()

    local slots = BuildSlotList()
    local shown = #slots

    for i, slot in ipairs(slots) do
        ConfigureButton(AcquireButton(i), slot, i)
    end
    -- Hide any pooled buttons not used this time.
    for i = shown + 1, #buttons do
        StopGlow(buttons[i])
        buttons[i]:Hide()
    end

    if shown == 0 then
        container:Hide()
        return
    end

    local width = PADDING * 2 + shown * ICON_SIZE + (shown - 1) * SPACING
    container:SetSize(width, ICON_SIZE + PADDING * 2)
    container.closeButton:SetSize(width, 24)
    -- Only the initiator (who gets no ready check popup to answer) needs Close.
    if IsPlayerTheInitiator(initiator) then
        container.closeButton.frame:Show()
    else
        container.closeButton.frame:Hide()
    end
    container:ClearAllPoints()
    if ReadyCheckListenerFrame then
        container:SetPoint("BOTTOM", ReadyCheckListenerFrame, "TOP", 0, 12)
    else
        container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    container:Show()

    -- Fallback hide in case the ready check UI's OnHide doesn't fire.
    if hideTimer then hideTimer:Cancel() end
    hideTimer = C_Timer.NewTimer(READY_CHECK_TIMEOUT or 35, function()
        if container then container:Hide() end
    end)
end

-- Warm the item cache so icons/tooltips are ready on the first ready check.
for _, cat in ipairs(ConsumableCategories) do
    for _, itemID in ipairs(cat._allItems) do
        C_Item.RequestLoadItemDataByID(itemID)
    end
end
