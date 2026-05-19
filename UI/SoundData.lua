local _, NSI = ...

-- Returns getItems and getSelected functions for direct use with CreateDropdown.
-- getValue  – function() → sound name string
-- setValue  – function(soundName)  called when a row is clicked
-- Clicking a row also previews the sound via PlaySoundFile.
function NSI:BuildSoundDropdown(getValue, setValue)
    local function getItems()
        local t = {
            {
                label   = "None",
                value   = nil,
                onclick = function()
                    if setValue then setValue(nil) end
                end,
            },
        }
        for _, sound in ipairs(NSI.LSM:List("sound")) do
            t[#t + 1] = {
                label   = sound,
                value   = sound,
                onclick = function(_, _, val)
                    PlaySoundFile(NSI.LSM:Fetch("sound", sound), "Master")
                    if setValue then setValue(val) end
                end,
            }
        end
        return t
    end

    local function getSelected()
        local v = getValue and getValue()
        return v or "None"
    end

    return getItems, getSelected
end
