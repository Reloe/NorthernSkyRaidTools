local _, NSI = ...
local DF = _G["DetailsFramework"]

-- ============================================================================
-- Encounter Alert Translation System
--
-- Triggered manually by the user via the language dropdown in the options UI.
-- English originals are stored in NSRT.EncounterAlertOriginals on first access.
-- Translations are stored in NSI.EncounterAlertLocales, keyed by locale -> encID -> internalID.
-- Alerts with UserModifiedText = true (manually edited by the user) are skipped.
-- ============================================================================

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}

function NSI:EncounterAlertLoc(key)
    local locale = NSRT.Alerts and NSRT.Alerts.Language
    if not locale or locale == "Auto" then
        locale = self:GetSelectedLanguage()
    end
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

local function StoreEnglishOriginals(encID, alertTable)
    if not NSRT.EncounterAlertOriginals then
        NSRT.EncounterAlertOriginals = {}
    end
    local encOriginals = NSRT.EncounterAlertOriginals[encID]
    if not encOriginals then
        encOriginals = {}
        NSRT.EncounterAlertOriginals[encID] = encOriginals
    end
    for internalID, alert in pairs(alertTable) do
        if type(alert) == "table" and alert.ReloeReminder == true and not encOriginals[internalID] then
            encOriginals[internalID] = {
                text  = alert.text,
                name  = alert.name,
                group = alert.group,
            }
        end
    end
end

local function ApplyTranslation(alert, original, translation)
    if not alert.UserModifiedText and translation.text and original.text then
        alert.text = translation.text
    end
    if translation.name and original.name then
        alert.name = translation.name
    end
    if not alert.UserModifiedGroup and translation.group and original.group then
        alert.group = translation.group
    end
end

local function RestoreToEnglish(alert, original)
    if not original then return end
    if not alert.UserModifiedText and original.text then
        alert.text = original.text
    end
    if original.name then
        alert.name = original.name
    end
    if not alert.UserModifiedGroup and original.group then
        alert.group = original.group
    end
end

-- ============================================================================
-- Public API
-- ============================================================================

function NSI:TranslateAllEncounterAlerts(locale)
    locale = locale or self:GetSelectedLanguage()
    if locale == "enUS" then return end

    local translatedCount = 0
    for encID, diffTable in pairs(NSRT.EncounterAlerts) do
        if type(diffTable) == "table" then
            for _, alertTable in pairs(diffTable) do
                if type(alertTable) == "table" then
                    StoreEnglishOriginals(encID, alertTable)
                    for internalID, alert in pairs(alertTable) do
                        if type(alert) == "table" and alert.ReloeReminder == true then
                            local translations = NSI.EncounterAlertLocales[locale]
                            local encTranslations = translations and translations[encID]
                            local translation = encTranslations and encTranslations[internalID]
                            if translation then
                                local originals = NSRT.EncounterAlertOriginals
                                local original = originals and originals[encID] and originals[encID][internalID]
                                ApplyTranslation(alert, original, translation)
                                translatedCount = translatedCount + 1
                            end
                        end
                    end
                end
            end
        end
    end
    return translatedCount
end

function NSI:RestoreAllEncounterAlerts()
    for encID, diffTable in pairs(NSRT.EncounterAlerts) do
        if type(diffTable) == "table" then
            for _, alertTable in pairs(diffTable) do
                if type(alertTable) == "table" then
                    for internalID, alert in pairs(alertTable) do
                        if type(alert) == "table" and alert.ReloeReminder == true then
                            local originals = NSRT.EncounterAlertOriginals
                            local original = originals and originals[encID] and originals[encID][internalID]
                            RestoreToEnglish(alert, original)
                        end
                    end
                end
            end
        end
    end
end
