WSGFCConfig = WSGFCConfig or {
    hpCallouts = true,
    hpThresholds = {75, 50, 25},
    showFrame = true,
    minimap = true,
    debug = false,
    frameX = 0,
    frameY = -150,
    framePoint = "TOP"
}

WFC = {
    allyCarrier = nil,
    hordeCarrier = nil,
    inWSG = false,
    colors = {
        ["WARRIOR"] = "C79C6E",
        ["PALADIN"] = "F58CBA",
        ["HUNTER"] = "ABD473",
        ["ROGUE"] = "FFF569",
        ["PRIEST"] = "FFFFFF",
        ["SHAMAN"] = "0070DE",
        ["MAGE"] = "69CCF0",
        ["WARLOCK"] = "9482C9",
        ["DRUID"] = "FF7D0A"
    },
    superwow = (SUPERWOW_VERSION ~= nil)
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

function WFC:GetClassColor(classNameToken)
    if classNameToken and WFC.colors[string.upper(classNameToken)] then
        return WFC.colors[string.upper(classNameToken)]
    end
    return "FFFFFF"
end

function WFC:Debug(msg)
    if WSGFCConfig.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[WFC Debug]|r " .. tostring(msg))
    end
end

function WFC:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[WSGFlagCaller]|r " .. tostring(msg))
end

function WFC:Announce(msg)
    SendChatMessage(msg, "BATTLEGROUND")
end

function WFC:CheckZone(force)
    local zone = GetZoneText()
    local realZone = GetRealZoneText and GetRealZoneText() or ""
    
    local isWSG = force or (zone == "Warsong Gulch") or (realZone == "Warsong Gulch") or (string.find(string.lower(zone), "warsong")) or (string.find(string.lower(realZone), "warsong"))

    WFC:Debug("Zone check: zone=" .. tostring(zone) .. " realZone=" .. tostring(realZone) .. " inWSG=" .. tostring(isWSG))

    if isWSG then
        if not WFC.inWSG then
            WFC.inWSG = true
            frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
            frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
            frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            if WFC.Combat and WFC.Combat.Enable then WFC.Combat:Enable() end
            if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
            WFC:Debug("Entered WSG. Events enabled.")
        end
    else
        if WFC.inWSG then
            WFC.inWSG = false
            frame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
            frame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
            frame:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            if WFC.Combat and WFC.Combat.Disable then WFC.Combat:Disable() end
            if WFC.Frame and WFC.Frame.Disable then WFC.Frame:Disable() end
            WFC.allyCarrier = nil
            WFC.hordeCarrier = nil
            WFC:Debug("Left WSG. Events disabled.")
        end
    end
end

frame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if WSGFCConfig.hpCallouts == nil then WSGFCConfig.hpCallouts = true end
        if not WSGFCConfig.hpThresholds then WSGFCConfig.hpThresholds = {75, 50, 25} end
        if WSGFCConfig.showFrame == nil then WSGFCConfig.showFrame = true end
        if WSGFCConfig.minimap == nil then WSGFCConfig.minimap = true end
        if not WSGFCConfig.framePoint then WSGFCConfig.framePoint = "TOP" end
        if not WSGFCConfig.frameX then WSGFCConfig.frameX = 0 end
        if not WSGFCConfig.frameY then WSGFCConfig.frameY = -150 end

        if WFC.Frame.Initialize then
            WFC.Frame:Initialize()
        end
        WFC:Print("Loaded. Type /wfc info for commands.")
        WFC:CheckZone()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        WFC:CheckZone()
    elseif event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or event == "CHAT_MSG_BG_SYSTEM_HORDE" or event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        WFC:ProcessBGMessage(arg1)
    end
end)

function WFC:ProcessBGMessage(msg)
    WFC:Debug("BG Msg: " .. tostring(msg))
    
    local _, _, pickerAlliance = string.find(msg, "([^%s]+) has taken the Alliance Flag!")
    if pickerAlliance then
        WFC.allyCarrier = pickerAlliance
        WFC.Combat:ResetPhases(pickerAlliance)
        WFC.Frame:UpdateVisibility()
        return
    end

    local _, _, pickerHorde = string.find(msg, "([^%s]+) has taken the Horde Flag!")
    if pickerHorde then
        WFC.hordeCarrier = pickerHorde
        WFC.Combat:ResetPhases(pickerHorde)
        WFC.Frame:UpdateVisibility()
        return
    end

    if string.find(msg, "The Alliance Flag was dropped") then
        WFC.allyCarrier = nil
        WFC.Frame:UpdateVisibility()
        return
    end

    if string.find(msg, "The Horde Flag was dropped") then
        WFC.hordeCarrier = nil
        WFC.Frame:UpdateVisibility()
        return
    end

    local _, _, capAlliance = string.find(msg, "([^%s]+) captured the Alliance Flag!")
    if capAlliance then
        WFC.allyCarrier = nil
        WFC.Frame:UpdateVisibility()
        return
    end

    local _, _, capHorde = string.find(msg, "([^%s]+) captured the Horde Flag!")
    if capHorde then
        WFC.hordeCarrier = nil
        WFC.Frame:UpdateVisibility()
        return
    end

    if string.find(msg, "The Alliance Flag was returned") then
        WFC.allyCarrier = nil
        WFC.Frame:UpdateVisibility()
        return
    end

    if string.find(msg, "The Horde Flag was returned") then
        WFC.hordeCarrier = nil
        WFC.Frame:UpdateVisibility()
        return
    end
end
