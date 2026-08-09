local _, NSI = ...

-- ============================================================================
-- Encounter Alert Locale System
-- Stores English originals on first insert and applies translations when the
-- active locale changes. Supports name, text, group, condition, and preview.
-- ============================================================================

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
NSI.EncounterAlertOriginals = NSI.EncounterAlertOriginals or {}

local OriginalInsertEncounterAlert = NSI.InsertEncounterAlert
local activeLocale = nil

-- Returns the translation table for a given alert, or nil if not found.
local function GetTranslation(encID, internalID, locale)
    local allLocales = NSI.EncounterAlertLocales
    local translations = allLocales[locale]
    if not translations then return nil end
    local encTranslations = translations[encID]
    if not encTranslations then return nil end
    return encTranslations[internalID]
end

-- Returns the stored English original fields for an alert.
local function GetEnglishOriginal(encID, internalID)
    local encOriginals = NSI.EncounterAlertOriginals[encID]
    return encOriginals and encOriginals[internalID]
end

-- Stores the English text/name/group/condition/preview of an alert definition
-- before any translation is applied, so we can revert or compare later.
local function StoreEnglishOriginal(encID, internalID, alertDef)
    local encOriginals = NSI.EncounterAlertOriginals[encID]
    if not encOriginals then
        encOriginals = {}
        NSI.EncounterAlertOriginals[encID] = encOriginals
    end
    if not encOriginals[internalID] then
        encOriginals[internalID] = {
            text = alertDef.text,
            name = alertDef.name,
            group = alertDef.group,
            condition = alertDef.isConditional and alertDef.isConditional.text,
            preview = alertDef.Preview,
        }
    end
end

-- Checks whether a value matches the translation for a specific locale.
local function IsLocaleTranslation(encID, internalID, field, value, locale)
    if not locale then return false end
    local t = GetTranslation(encID, internalID, locale)
    return t and t[field] == value
end

-- Applies translation (or restores English originals) to an already-loaded alert.
-- previousLocale is the locale the alert was in before the switch; used to
-- distinguish user-edited text from known translations of the prior locale.
local function ApplyTranslationToExisting(existing, encID, locale, previousLocale)
    if locale == "enUS" then
        local original = GetEnglishOriginal(encID, existing.internalID)
        if original then
            existing.name = original.name
            if not existing.UserModifiedText and existing.text ~= original.text then
                if IsLocaleTranslation(encID, existing.internalID, "text", existing.text, previousLocale) then
                    existing.text = original.text
                else
                    existing.UserModifiedText = true
                end
            end
            existing.group = original.group
            if original.condition then
                if not existing.isConditional then
                    existing.isConditional = {}
                end
                existing.isConditional.text = original.condition
            end
            existing.Preview = original.preview
        end
        return
    end

    local t = GetTranslation(encID, existing.internalID, locale)
    if not t then return end

    if t.name then
        existing.name = t.name
    end
    if t.text ~= nil then
        if not existing.UserModifiedText then
            local original = GetEnglishOriginal(encID, existing.internalID)
            if original and existing.text ~= original.text and existing.text ~= t.text
                and not IsLocaleTranslation(encID, existing.internalID, "text", existing.text, previousLocale) then
                existing.UserModifiedText = true
            end
        end
        if not existing.UserModifiedText then
            existing.text = t.text
        end
    end
    if t.group ~= nil then
        existing.group = t.group
    end
    if t.condition ~= nil then
        if not existing.isConditional then
            existing.isConditional = {}
        end
        existing.isConditional.text = t.condition
    end
    if t.preview ~= nil then
        existing.Preview = t.preview
    end
end

-- Re-applies locale translations to all currently loaded encounter alerts.
-- Called when the user switches language or on first load.
function NSI:RefreshEncounterAlertLocales()
    local newLocale = self:GetSelectedLanguage()

    for encID, diffTable in pairs(NSRT.EncounterAlerts or {}) do
        if type(diffTable) == "table" then
            for diffID, alertTable in pairs(diffTable) do
                if type(alertTable) == "table" then
                    for internalID, alert in pairs(alertTable) do
                        if type(alert) == "table" and alert.IsAlert then
                            ApplyTranslationToExisting(alert, encID, newLocale, activeLocale)
                        end
                    end
                end
            end
        end
    end
    activeLocale = newLocale
end

-- Hooks the original InsertEncounterAlert to intercept new alert definitions
-- and apply translations before they are stored in NSRT.EncounterAlerts.
function NSI:InsertEncounterAlert(encID, diffID, alertDef, ReloeReminder)
    local locale = self:GetSelectedLanguage()

    if activeLocale and activeLocale ~= locale then
        self:RefreshEncounterAlertLocales()
    end
    activeLocale = locale

    local existingBefore = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][diffID] and NSRT.EncounterAlerts[encID][diffID][alertDef.internalID]

    StoreEnglishOriginal(encID, alertDef.internalID, alertDef)

    if locale ~= "enUS" then
        local t = GetTranslation(encID, alertDef.internalID, locale)
        if t then
            if t.name then
                alertDef.name = t.name
            end

            if t.text ~= nil and not (existingBefore and existingBefore.UserModifiedText) then
                alertDef.text = t.text
            end

            if t.group ~= nil then
                alertDef.group = t.group
            end

            if t.condition ~= nil then
                if not alertDef.isConditional then
                    alertDef.isConditional = {}
                end
                alertDef.isConditional.text = t.condition
            end
            if t.preview ~= nil then
                alertDef.Preview = t.preview
            end
        end
    end

    if existingBefore and existingBefore.UserModifiedText then
        alertDef.UserModifiedText = true
    end

    OriginalInsertEncounterAlert(self, encID, diffID, alertDef, ReloeReminder)

    local existingAfter = NSRT.EncounterAlerts[encID] and NSRT.EncounterAlerts[encID][diffID] and NSRT.EncounterAlerts[encID][diffID][alertDef.internalID]

    if existingAfter then
        ApplyTranslationToExisting(existingAfter, encID, locale, nil)
    end
end

-- Periodically checks for locale changes. NSRT.Settings.Language has no
-- change event, so polling is the only reliable way to detect switches.
local localeCheckFrame = CreateFrame("Frame")
local localeCheckElapsed = 0
localeCheckFrame:SetScript("OnUpdate", function(_, elapsed)
    localeCheckElapsed = localeCheckElapsed + elapsed
    if localeCheckElapsed < 0.5 then return end
    localeCheckElapsed = 0
    local newLocale = NSI:GetSelectedLanguage()
    if activeLocale and activeLocale ~= newLocale then
        NSI:RefreshEncounterAlertLocales()
    end
    activeLocale = newLocale
end)

-- ============================================================================
-- Assignment / Dynamic Alert Translation
-- Intercepts AddToReminder, AddRemindersFromTable, and DisplayText during
-- assignment processing so that boss-defined dynamic text is translated on the
-- fly. Translation keys are stored per-encounter under assignments in the
-- locale file. Keys ending with a space are treated as prefixes that recurse
-- into the remainder of the text.
-- ============================================================================

-- Recursively translates a piece of dynamic text using the assignments table.
-- Supports exact matches, prefix matches (keys ending with a space), and
-- color-code-preserving matches (e.g. "|cFF00FF00SOAK").
local function translateAssignmentText(text, encID, locale)
    local t = NSI.EncounterAlertLocales[locale]
    if not t or not t[encID] then return text end
    local assignments = t[encID].assignments
    if not assignments then return text end

    local translated = assignments[text]
    if translated then return translated end

    for eng, _ in pairs(assignments) do
        if #eng > 1 and eng:sub(-1) == " " and text:sub(1, #eng) == eng then
            local prefix = assignments[eng] or eng
            return prefix .. translateAssignmentText(text:sub(#eng + 1), encID, locale)
        end
    end
    return text
end

-- Translates the DisplayText format string. The last |cAARRGGBB...|r segment
-- is treated as the dynamic part, which is extracted, translated, and inserted
-- into the locale's display format via string.format.
local function translateAssignmentDisplay(encID, text, locale)
    local t = NSI.EncounterAlertLocales[locale]
    if not t or not t[encID] then return text end
    local assignments = t[encID].assignments
    if not assignments then return text end
    local formatStr = assignments.display
    if not formatStr then return text end

    local dynamic = text:match("|c%x%x%x%x%x%x%x%x([^|]*)|r[^|]*$")
    if not dynamic then return text end
    return formatStr:format(translateAssignmentText(dynamic, encID, locale))
end

-- Translates text and TTS fields on an alert object in-place.
local function translateAlertFields(alert, encID, locale)
    if alert.text then
        alert.text = translateAssignmentText(alert.text, encID, locale)
    end
    if alert.TTS then
        alert.TTS = translateAssignmentText(alert.TTS, encID, locale)
    end
end

-- Creates a proxy table that wraps the real NSI, intercepting three methods
-- used during assignment processing. All other methods and properties are
-- forwarded to the real NSI unchanged.
local function createAssignmentProxy(nsi, encID)
    local proxy = {}
    setmetatable(proxy, {
        __index = function(t, k)
            local v = nsi[k]
            if k == "AddToReminder" or k == "AddRemindersFromTable" then
                return function(_, alert, ...)
                    translateAlertFields(alert, encID, nsi:GetSelectedLanguage())
                    return v(nsi, alert, ...)
                end
            elseif k == "DisplayText" then
                return function(_, text, ...)
                    text = translateAssignmentDisplay(encID, text, nsi:GetSelectedLanguage())
                    return v(nsi, text, ...)
                end
            elseif type(v) == "function" then
                return function(_, ...)
                    return v(nsi, ...)
                end
            end
            return v
        end
    })
    return proxy
end

-- Wrap every registered AddAssignments function so that the boss code receives
-- a proxy instead of the real NSI, enabling on-the-fly translation.
for encID, func in pairs(NSI.AddAssignments) do
    NSI.AddAssignments[encID] = function(self, ...)
        local proxy = createAssignmentProxy(self, encID)
        return func(proxy, ...)
    end
end