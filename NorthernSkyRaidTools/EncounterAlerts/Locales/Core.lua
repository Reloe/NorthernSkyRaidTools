local _, NSI = ...

-- ============================================================================
-- Encounter Alert Translation System
--
-- Triggered manually by the user via the language dropdown in the options UI.
-- English originals are stored in NSRT.EncounterAlertOriginals on first access.
-- Translations are stored in NSI.EncounterAlertLocales, keyed by locale -> encID -> internalID.
-- Alerts with UserModifiedText = true (manually edited by the user) are skipped.
-- ============================================================================

NSI.EncounterAlertLocales = NSI.EncounterAlertLocales or {}

-- ============================================================================
-- Internal Helpers
-- ============================================================================

local function GetTranslation(encID, internalID, locale)
    local translations = NSI.EncounterAlertLocales[locale]
    if not translations then return nil end
    local encTranslations = translations[encID]
    if not encTranslations then return nil end
    return encTranslations[internalID]
end

local function GetEnglishOriginal(encID, internalID)
    local originals = NSRT.EncounterAlertOriginals
    return originals and originals[encID] and originals[encID][internalID]
end

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
        if type(alert) == "table" and alert.IsAlert and not encOriginals[internalID] then
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
    if translation.group and original.group then
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
    if original.group then
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
                        if type(alert) == "table" and alert.IsAlert then
                            local translation = GetTranslation(encID, internalID, locale)
                            if translation then
                                local original = GetEnglishOriginal(encID, internalID)
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
                        if type(alert) == "table" and alert.IsAlert then
                            local original = GetEnglishOriginal(encID, internalID)
                            RestoreToEnglish(alert, original)
                        end
                    end
                end
            end
        end
    end
end
