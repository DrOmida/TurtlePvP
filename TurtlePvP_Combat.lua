WFC.Combat = {}
WFC.Combat.phases = {}
WFC.Combat.lastCalloutTime = 0

local combatFrame = CreateFrame("Frame")

function WFC.Combat:Enable()
    combatFrame:RegisterEvent("UNIT_HEALTH")
    combatFrame:RegisterEvent("UNIT_DIED")
end

function WFC.Combat:Disable()
    combatFrame:UnregisterEvent("UNIT_HEALTH")
    combatFrame:UnregisterEvent("UNIT_DIED")
end

function WFC.Combat:ResetPhases(carrierName)
    if not carrierName then return end
    WFC.Combat.phases[carrierName] = {}
    for _, t in ipairs(TurtlePvPConfig.hpThresholds) do
        WFC.Combat.phases[carrierName][t] = false
    end
end

combatFrame:SetScript("OnEvent", function()
    if event == "UNIT_HEALTH" then
        local uName = UnitName(arg1)
        if uName == WFC.hordeCarrier or uName == WFC.allyCarrier then
            local hp = UnitHealth(arg1)
            local maxHp = UnitHealthMax(arg1)
            WFC.Combat:CheckHP(uName, hp, maxHp, arg1)
        end
    elseif event == "UNIT_DIED" then
        if WFC.Tracker and arg1 then
            local deadName = WFC.Tracker.guidToName[arg1] or UnitName(arg1)
            if deadName then
                if deadName == WFC.hordeCarrier then
                    WFC.hordeCarrier = nil
                    WFC.Frame:UpdateVisibility()
                elseif deadName == WFC.allyCarrier then
                    WFC.allyCarrier = nil
                    WFC.Frame:UpdateVisibility()
                end
            end
        end
    end
end)

function WFC.Combat:CheckHP(carrierName, hp, maxHp, unitId)
    if not TurtlePvPConfig.hpCallouts then return end
    if not hp or not maxHp or maxHp == 0 then return end
    
    local myFaction = UnitFactionGroup("player")
    -- Only call out ENEMY FC
    -- If I am Alliance, my team's carrier holds the Horde flag (WFC.hordeCarrier)
    -- If I am Horde, my team's carrier holds the Alliance flag (WFC.allyCarrier)
    if myFaction == "Alliance" and carrierName == WFC.hordeCarrier then return end
    if myFaction == "Horde" and carrierName == WFC.allyCarrier then return end

    local pct = (hp / maxHp) * 100
    local now = GetTime()

    if not WFC.Combat.phases[carrierName] then
        WFC.Combat:ResetPhases(carrierName)
    end

    local thresholds = {}
    for _, v in ipairs(TurtlePvPConfig.hpThresholds) do table.insert(thresholds, v) end
    table.sort(thresholds, function(a, b) return a > b end)

    for _, t in ipairs(thresholds) do
        local isLocked = WFC.Combat.phases[carrierName][t]
        
        -- Hysteresis: unlock if healed above threshold + 10%
        if isLocked and pct > (t + 10) then
            WFC.Combat.phases[carrierName][t] = false
            WFC:Debug(carrierName .. " healed above " .. tostring(t + 10) .. "%, unlocked phase " .. tostring(t))
        end

        local currentlyLocked = WFC.Combat.phases[carrierName][t]
        if not currentlyLocked and pct <= t then
            if (now - WFC.Combat.lastCalloutTime) > 2 then
                WFC.Combat.phases[carrierName][t] = true
                WFC.Combat.lastCalloutTime = now
                
                local classToken = nil
                if unitId and UnitClass then
                    local _, eClass = UnitClass(unitId)
                    classToken = eClass
                end
                
                local nameStr = carrierName
                if classToken then
                    local color = WFC:GetClassColor(classToken)
                    nameStr = "|cff" .. color .. carrierName .. "|r"
                end
                
                WFC:Announce("Enemy FC " .. nameStr .. " is at ~" .. tostring(t) .. "% HP")
            end
        end
    end
end
