local _, NSI = ...
local DF = _G["DetailsFramework"]

-- ============================================================================
-- Encounter Alert Translation System
--
-- Applied on import when translation data changes, and via the language dropdown.
-- Translations are stored in NSI.EncounterAlertLocales, keyed by locale -> encID -> internalID.
-- User-modified text and groups are preserved.
-- ============================================================================

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}
local TranslationFields = { "group", "name", "text" }
local TranslationRevisions = {}

function NSI:GetEncounterAlertLanguage(locale)
    locale = locale or NSRT.Alerts.Language
    if not locale or locale == "Auto" then
        locale = GetLocale()
    end
    return self.EncounterAlertLocales[locale] and locale or "enUS"
end

function NSI:EncounterAlertLoc(key)
    local locale = self:GetEncounterAlertLanguage()
    if locale == "enUS" then return key end

    local languageTable = DF.Language.GetLanguageTable("NorthernSkyRaidTools", locale)
    local text = languageTable and languageTable[key]
    if text == true then return key end
    if text then return text end

    local englishTable = DF.Language.GetLanguageTable("NorthernSkyRaidTools", "enUS")
    text = englishTable and englishTable[key]
    if text == true then return key end
    return text or key
end

-- ============================================================================
-- Internal Helpers
-- ============================================================================

local function GetTranslationRevision(locale)
    if TranslationRevisions[locale] then return TranslationRevisions[locale] end

    local english = NSI.EncounterAlertLocales.enUS or {}
    local translations = NSI.EncounterAlertLocales[locale] or {}
    local encounterIDs = {}
    for encID in pairs(english) do
        encounterIDs[#encounterIDs + 1] = encID
    end
    table.sort(encounterIDs)

    local parts = {}
    for _, encID in ipairs(encounterIDs) do
        parts[#parts + 1] = "E" .. encID .. ":"
        local internalIDs = {}
        for internalID in pairs(english[encID]) do
            internalIDs[#internalIDs + 1] = internalID
        end
        table.sort(internalIDs)
        for _, internalID in ipairs(internalIDs) do
            parts[#parts + 1] = "A" .. #internalID .. ":" .. internalID
            local reference = english[encID][internalID]
            local translation = translations[encID] and translations[encID][internalID]
            for _, field in ipairs(TranslationFields) do
                local value = reference[field] and (translation and translation[field] or reference[field])
                -- Length prefixes distinguish empty fields and strings containing separators.
                parts[#parts + 1] = value and #value .. ":" .. value or "-"
            end
        end
    end

    local revision = locale .. ":" .. NSI:GetHash(table.concat(parts))
    TranslationRevisions[locale] = revision
    return revision
end

-- ============================================================================
-- Public API
-- ============================================================================

function NSI:TranslateEncounterAlert(encID, internalID, alert, locale)
    if alert.ReloeReminder ~= true then return false end
    local english = self.EncounterAlertLocales.enUS
    english = english and english[encID] and english[encID][internalID]
    if not english then return false end

    locale = self:GetEncounterAlertLanguage(locale)
    local translations = self.EncounterAlertLocales[locale]
    local translation = translations and translations[encID] and translations[encID][internalID]
    for _, field in ipairs(TranslationFields) do
        local userModified = (field == "group" and alert.UserModifiedGroup) or (field == "text" and alert.UserModifiedText)
        if not userModified and english[field] then
            local value = translation and translation[field] or english[field]
            if alert[field] ~= value then alert[field] = value end
        end
    end
    return true
end

function NSI:TranslateAllEncounterAlerts(locale)
    locale = self:GetEncounterAlertLanguage(locale)

    local translatedCount = 0
    for encID, diffTable in pairs(NSRT.EncounterAlerts) do
        if type(diffTable) == "table" then
            for _, alertTable in pairs(diffTable) do
                if type(alertTable) == "table" then
                    for internalID, alert in pairs(alertTable) do
                        if type(alert) == "table" and self:TranslateEncounterAlert(encID, internalID, alert, locale) then
                            translatedCount = translatedCount + 1
                        end
                    end
                end
            end
        end
    end
    NSRT.EncounterAlertTranslationRevision = GetTranslationRevision(locale)
    return translatedCount
end

function NSI:UpdateEncounterAlertTranslations()
    local locale = self:GetEncounterAlertLanguage()
    if NSRT.EncounterAlertTranslationRevision == GetTranslationRevision(locale) then return 0 end
    return self:TranslateAllEncounterAlerts(locale)
end
