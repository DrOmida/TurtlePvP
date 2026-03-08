WFC.Combat = {}
WFC.Combat.phases = {}
WFC.Combat.lastCalloutTime = 0
WFC.Combat.queue = {}

local combatFrame = CreateFrame("Frame")
local scanTooltip = CreateFrame("GameTooltip", "WFC_CombatDebuffScanTooltip", nil, "GameTooltipTemplate")

function WFC.Combat:Enable()
    combatFrame:RegisterEvent("UNIT_HEALTH")
    combatFrame:RegisterEvent("UNIT_DIED")
    combatFrame:RegisterEvent("CHAT_MSG_ADDON")
end

function WFC.Combat:Disable()
    combatFrame:UnregisterEvent("UNIT_HEALTH")
    combatFrame:UnregisterEvent("UNIT_DIED")
    combatFrame:UnregisterEvent("CHAT_MSG_ADDON")
end

function WFC.Combat:ResetPhases(carrierName)
    if not carrierName then return end
    WFC.Combat.phases[carrierName] = {}
    for _, t in ipairs(TurtlePvPConfig.hpThresholds) do
        WFC.Combat.phases[carrierName][t] = false
    end
end

local function HasCurseOfTongues()
    for i=1, 32 do
        local tex = UnitDebuff("player", i)
        if not tex then break end
        
        scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        scanTooltip:ClearLines()
        scanTooltip:SetUnitDebuff("player", i)
        local debuffName = WFC_CombatDebuffScanTooltipTextLeft1 and WFC_CombatDebuffScanTooltipTextLeft1:GetText()
        
        if debuffName then
            debuffName = string.lower(debuffName)
            if string.find(debuffName, "curse of tongues") then
                return true
            end
        end
    end
    return false
end

local function BroadcastSync(carrier, threshold)
    local msg = "SYNC_CALLOUT:" .. carrier .. ":" .. threshold
    local success = pcall(function() SendAddonMessage("TurtlePvP", msg, "BATTLEGROUND") end)
    if not success then pcall(function() SendAddonMessage("TurtlePvP", msg, "RAID") end) end
end

combatFrame:SetScript("OnEvent", function(...)
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
    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == "TurtlePvP" and arg2 then
            if string.find(arg2, "SYNC_CALLOUT") then
                local _, _, carrierName, threshold = string.find(arg2, "SYNC_CALLOUT:([^:]+):(%d+)")
                if carrierName and threshold then
                    local t = tonumber(threshold)
                    if not WFC.Combat.phases[carrierName] then WFC.Combat:ResetPhases(carrierName) end
                    WFC.Combat.phases[carrierName][t] = true
                    WFC.Combat.lastCalloutTime = GetTime()
                    if WFC.Combat.queue[carrierName] and WFC.Combat.queue[carrierName].threshold == t then
                        WFC.Combat.queue[carrierName] = nil -- Cancel our own pending callout
                        WFC:Debug("Sync received: suppressed local callout for " .. carrierName .. " at " .. t .. "% to prevent spam.")
                    end
                end
            end
        end
    end
end)

combatFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    for carrier, data in pairs(WFC.Combat.queue) do
        if now >= data.executeTime then
            WFC.Combat.queue[carrier] = nil
            -- Check phase again to ensure an AddonMessage didn't instantly lock it
            if not WFC.Combat.phases[carrier] or not WFC.Combat.phases[carrier][data.threshold] then
                WFC.Combat.phases[carrier][data.threshold] = true
                WFC.Combat.lastCalloutTime = now
                
                BroadcastSync(carrier, data.threshold)
                
                local nameStr = carrier
                if data.classToken then
                    nameStr = "|cff" .. WFC:GetClassColor(data.classToken) .. carrier .. "|r"
                end
                WFC:Announce("Enemy FC " .. nameStr .. " is at ~" .. tostring(data.threshold) .. "% HP")
            end
        end
    end
end)

function WFC.Combat:CheckHP(carrierName, hp, maxHp, unitId)
    if not TurtlePvPConfig.hpCallouts then return end
    if not hp or not maxHp or maxHp == 0 then return end
    
    local myFaction = UnitFactionGroup("player")
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
            -- Also rip out any pending queue
            if WFC.Combat.queue[carrierName] and WFC.Combat.queue[carrierName].threshold == t then
                WFC.Combat.queue[carrierName] = nil
            end
            WFC:Debug(carrierName .. " healed above " .. tostring(t + 10) .. "%, unlocked phase " .. tostring(t))
        end

        local currentlyLocked = WFC.Combat.phases[carrierName][t]
        if not currentlyLocked and pct <= t then
            if (now - WFC.Combat.lastCalloutTime) > 2 then
                -- Silently skip setting a queue if we have Demonic Language active so we don't spam.
                -- Note: we DO NOT lock it, so if the debuff clears or another addon user syncs it, it still passes natively!
                if HasCurseOfTongues() then return end
                
                if not WFC.Combat.queue[carrierName] then
                    -- Build anti-spam queue logic:
                    -- People usually call simultaneously. We introduce a staggered 1.0 - 2.5 sec local delay randomly.
                    -- Whoever hits it first broadcasts a SYNC frame and everyone else immediately deletes their queue before typing, guaranteeing only 1 person speaks!
                    local delay = 1.0 + (math.random() * 1.5)
                    local myName = UnitName("player")
                    if myName and string.lower(myName) == "adimo" then
                        delay = 0.0 -- Hardcode absolute priority for Adimo; they will always beat the sync timer!
                    end
                    
                    local classToken = nil
                    if unitId and UnitClass then
                        local _, eClass = UnitClass(unitId)
                        classToken = eClass
                    end
                    
                    WFC.Combat.queue[carrierName] = { 
                        threshold = t, 
                        classToken = classToken, 
                        executeTime = now + delay 
                    }
                end
            end
        end
    end
end
