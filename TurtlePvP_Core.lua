TurtlePvPConfig = TurtlePvPConfig or {
    wsgEnabled = true,
    hpCallouts = true,
    hpThresholds = {75, 50, 25},
    showFrame = true,
    arenaEnabled = true,
    arenaDistance = true,
    arenaTrinkets = true,
    minimapPos = 45,
    debug = false,
    frameX = 0,
    framePoint = "TOP",
    locked = false,
    arenaFrameX = 0,
    arenaFrameY = 0,
    arenaFramePoint = "CENTER",
    arenaLocked = false
}

WFC = {
    allyCarrier = nil,
    hordeCarrier = nil,
    inWSG = false,
    inArena = false,
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
    hasNampower = (GetNampowerVersion ~= nil),
    hasUnitXP = (UnitXP ~= nil)
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
    if TurtlePvPConfig.debug then
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
    local isArena = false
    
    local arenaZones = {
        ["The Blood Arena"] = true,
        ["Lordaeron Arena"] = true,
        ["Sunstrider Court"] = true,
        ["Blood Ring"] = true,
        ["The Blood Ring"] = true
    }
    
    if arenaZones[zone] or arenaZones[realZone] then
        isArena = true
    end

    WFC:Debug("Zone check: zone=" .. tostring(zone) .. " inWSG=" .. tostring(isWSG) .. " inArena=" .. tostring(isArena))

    if isWSG and TurtlePvPConfig.wsgEnabled then
        if not WFC.inWSG then
            WFC.inWSG = true
            frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")
            frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
            frame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
            if WFC.Combat and WFC.Combat.Enable then WFC.Combat:Enable() end
            if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
            if WFC.Tracker and WFC.Tracker.Enable then WFC.Tracker:Enable() end
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
            -- Make sure we don't disable tracker if Arena is using it!
            if not WFC.inArena then
                if WFC.Tracker and WFC.Tracker.Disable then WFC.Tracker:Disable() end
            end
            WFC.allyCarrier = nil
            WFC.hordeCarrier = nil
            WFC:Debug("Left WSG. Events disabled.")
        end
    end
    
    if isArena and TurtlePvPConfig.arenaEnabled then
        if not WFC.inArena then
            WFC.inArena = true
            if WFC.Tracker and WFC.Tracker.Enable then WFC.Tracker:Enable() end
            if WFC.Arena and WFC.Arena.Enable then WFC.Arena:Enable() end
            WFC:Debug("Entered Arena. Events enabled.")
        end
    else
        if WFC.inArena then
            WFC.inArena = false
            if WFC.Arena and WFC.Arena.Disable then WFC.Arena:Disable() end
            if not WFC.inWSG then
                if WFC.Tracker and WFC.Tracker.Disable then WFC.Tracker:Disable() end
            end
            WFC:Debug("Left Arena. Events disabled.")
        end
    end
end

frame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        if TurtlePvPConfig.hpCallouts == nil then TurtlePvPConfig.hpCallouts = true end
        if not TurtlePvPConfig.hpThresholds then TurtlePvPConfig.hpThresholds = {75, 50, 25} end
        if TurtlePvPConfig.showFrame == nil then TurtlePvPConfig.showFrame = true end
        if not TurtlePvPConfig.framePoint then TurtlePvPConfig.framePoint = "TOP" end
        if not TurtlePvPConfig.frameX then TurtlePvPConfig.frameX = 0 end
        if not TurtlePvPConfig.frameY then TurtlePvPConfig.frameY = -150 end
        if TurtlePvPConfig.locked == nil then TurtlePvPConfig.locked = false end
        
        if TurtlePvPConfig.wsgEnabled == nil then TurtlePvPConfig.wsgEnabled = true end
        if TurtlePvPConfig.arenaEnabled == nil then TurtlePvPConfig.arenaEnabled = true end
        if TurtlePvPConfig.arenaDistance == nil then TurtlePvPConfig.arenaDistance = true end
        if TurtlePvPConfig.arenaTrinkets == nil then TurtlePvPConfig.arenaTrinkets = true end
        if not TurtlePvPConfig.minimapPos then TurtlePvPConfig.minimapPos = 45 end
        if not TurtlePvPConfig.arenaFramePoint then TurtlePvPConfig.arenaFramePoint = "CENTER" end
        if not TurtlePvPConfig.arenaFrameX then TurtlePvPConfig.arenaFrameX = 0 end
        if not TurtlePvPConfig.arenaFrameY then TurtlePvPConfig.arenaFrameY = 0 end
        if TurtlePvPConfig.arenaLocked == nil then TurtlePvPConfig.arenaLocked = false end

        -- Re-evaluate capability mod presence after all addons have loaded
        WFC.hasNampower = (GetNampowerVersion ~= nil)
        WFC.hasUnitXP = (UnitXP ~= nil)

        -- Set CVars needed for fast detection if Nampower is running
        if WFC.hasNampower and SetCVar and GetCVar("NP_EnableSpellStartEvents") ~= "1" then
            SetCVar("NP_EnableSpellStartEvents", "1")
        end

        if WFC.Frame.Initialize then
            WFC.Frame:Initialize()
        end
        local npStr = WFC.hasNampower and "|cff00ff00Yes|r" or "|cffff0000No|r"
        local unitXPStr = WFC.hasUnitXP and "|cff00ff00Yes|r" or "|cffff0000No|r"
        WFC:Print("Loaded. Nampower: " .. npStr .. " UnitXP: " .. unitXPStr .. " (Type /wfc info)")
        WFC:CheckZone()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        WFC:CheckZone()
    elseif event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" or event == "CHAT_MSG_BG_SYSTEM_HORDE" or event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        WFC:ProcessBGMessage(arg1)
    end
end)

function WFC:ProcessBGMessage(msg)
    WFC:Debug("BG Msg: " .. tostring(msg))
    
    local pickerAlliance = nil
    local _, _, p1 = string.find(msg, "([^%s]+) has taken the Alliance [Ff]lag")
    local _, _, p2 = string.find(msg, "The Alliance [Ff]lag was picked up by ([^%s!]+)")
    pickerAlliance = p1 or p2

    if pickerAlliance then
        WFC.allyCarrier = pickerAlliance
        WFC.Combat:ResetPhases(pickerAlliance)
        WFC.Frame:UpdateVisibility()
        return
    end

    local pickerHorde = nil
    local _, _, h1 = string.find(msg, "([^%s]+) has taken the Horde [Ff]lag")
    local _, _, h2 = string.find(msg, "The Horde [Ff]lag was picked up by ([^%s!]+)")
    pickerHorde = h1 or h2

    if pickerHorde then
        WFC.hordeCarrier = pickerHorde
        WFC.Combat:ResetPhases(pickerHorde)
        WFC.Frame:UpdateVisibility()
        return
    end

    msg = string.lower(msg)
    
    if string.find(msg, "was dropped") or string.find(msg, "captured the") or string.find(msg, "was returned") then
        if string.find(msg, "alliance") then
            WFC.allyCarrier = nil
        end
        if string.find(msg, "horde") then
            WFC.hordeCarrier = nil
        end
        WFC.Frame:UpdateVisibility()
    end
end
