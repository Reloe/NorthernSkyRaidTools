local _, NSI = ... -- Internal namespace

function NSI:AddEncounterAlert(encId, key, alert, timers, durOverrides, enabled, reloeCreated)
    local enc = NSRT.EncounterAlerts[encId]

    if not enc then return end

    if enc[key] and enc[key].reloeCreated then
        enc[key].timers = timers
        return
    end

    enc[key] = { alert = alert, timers = timers, durOverrides = durOverrides, reloeCreated = (reloeCreated == nil or reloeCreated), enabled = (enabled == nil or enabled)}
end

function NSI:RemoveEncounterAlert(encId, key)
    local enc = NSRT.EncounterAlerts[encId]

    if not enc then return end

    enc[key] = nil
end
