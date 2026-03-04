WFC.Tracker = {
    nameToGuid = {},
    guidToName = {},
    enabled = false
}

local frame = CreateFrame("Frame")

function WFC.Tracker:Enable()
    if not GetNampowerVersion then return end
    
    WFC.Tracker.enabled = true
    frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_HEALTH_GUID")
    frame:RegisterEvent("UNIT_AURA_GUID")
    frame:RegisterEvent("SPELL_START_OTHER")
end

function WFC.Tracker:Disable()
    WFC.Tracker.enabled = false
    frame:UnregisterAllEvents()
    WFC.Tracker.nameToGuid = {}
    WFC.Tracker.guidToName = {}
end

function WFC.Tracker:GetGUID(name)
    if not name then return nil end
    local guid = WFC.Tracker.nameToGuid[name]
    if not guid and SpySW and SpySW.nameToGuid then
        guid = SpySW.nameToGuid[name]
        if guid then WFC.Tracker:ProcessGUID(guid) end
    elseif not guid and SpyNP and SpyNP.nameToGuid then
        guid = SpyNP.nameToGuid[name]
        if guid then WFC.Tracker:ProcessGUID(guid) end
    end
    return guid
end

function WFC.Tracker:ProcessGUID(guid)
    if not guid then return end
    -- Only Nampower allows resolving GUID string via UnitName natively
    local name = UnitName(guid)
    if name and name ~= "Unknown" and name ~= "" then
        WFC.Tracker.nameToGuid[name] = guid
        WFC.Tracker.guidToName[guid] = name
    end
end

frame:SetScript("OnEvent", function()
    if not WFC.Tracker.enabled then return end

    if event == "UPDATE_MOUSEOVER_UNIT" then
        if GetUnitGUID then
            WFC.Tracker:ProcessGUID(GetUnitGUID("mouseover"))
        end
    elseif event == "PLAYER_TARGET_CHANGED" then
        if GetUnitGUID then
            WFC.Tracker:ProcessGUID(GetUnitGUID("target"))
            WFC.Tracker:ProcessGUID(GetUnitGUID("targettarget"))
        end
    elseif event == "UNIT_HEALTH_GUID" or event == "UNIT_AURA_GUID" then
        -- arg1 = guid
        WFC.Tracker:ProcessGUID(arg1)
    elseif event == "SPELL_START_OTHER" then
        -- arg3 = casterGuid
        WFC.Tracker:ProcessGUID(arg3)
    end
end)
