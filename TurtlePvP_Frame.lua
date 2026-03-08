WFC.Frame = {}
local hud = nil

function WFC.Frame:Initialize()
    hud = CreateFrame("Frame", "WSGFCHud", UIParent)
    hud:SetWidth(200)
    hud:SetHeight(60)
    hud:SetPoint(TurtlePvPConfig.framePoint, UIParent, TurtlePvPConfig.framePoint, TurtlePvPConfig.frameX, TurtlePvPConfig.frameY)
    hud:SetMovable(true)
    
    local unlockBg = hud:CreateTexture(nil, "BACKGROUND")
    unlockBg:SetAllPoints()
    unlockBg:SetTexture(0, 1, 0, 0.3)
    hud.unlockBg = unlockBg
    
    hud.hordeRow = WFC.Frame:CreateRow(hud, 0, "Horde Flag")
    hud.allyRow = WFC.Frame:CreateRow(hud, -30, "Alliance Flag")
    
    WFC.Frame:UpdateLockState()
    hud:Hide()
end

function WFC.Frame:CreateRow(parent, yOffset, label)
    local row = CreateFrame("Button", nil, parent)
    row:SetWidth(200)
    row:SetHeight(25)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
    
    local tex = row:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture(0, 0, 0, 0.5)
    row.bg = tex
    
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    nameText:SetText("Carrier")
    row.nameText = nameText
    
    local hpBar = CreateFrame("StatusBar", nil, row)
    hpBar:SetWidth(100)
    hpBar:SetHeight(15)
    hpBar:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0, 1, 0)
    hpBar:SetMinMaxValues(0, 100)
    hpBar:SetValue(100)
    row.hpBar = hpBar

    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hpText:SetPoint("CENTER", hpBar, "CENTER", 0, 0)
    hpText:SetText("100%")
    row.hpText = hpText
    
    local distText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    distText:SetPoint("RIGHT", hpBar, "LEFT", -5, 0)
    distText:SetText("--")
    row.distText = distText
    
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            TurtlePvPConfig.locked = not TurtlePvPConfig.locked
            if TurtlePvPConfig.locked then
                WFC:Print("WSG HUD Locked.")
            else
                WFC:Print("WSG HUD Unlocked. Drag to move, right-click to lock.")
            end
            WFC.Frame:UpdateLockState()
            return
        end
        local cName = row.carrierName
        if cName then
            TargetByName(cName, true)
            if FocusUnit then
                FocusUnit("target")
            end
        end
    end)
    
    row:RegisterForDrag("LeftButton")
    row:SetScript("OnDragStart", function() 
        if not TurtlePvPConfig.locked then 
            parent:StartMoving() 
        end 
    end)
    row:SetScript("OnDragStop", function() 
        parent:StopMovingOrSizing() 
        local p, _, rp, x, y = parent:GetPoint()
        TurtlePvPConfig.framePoint = p
        TurtlePvPConfig.frameX = x
        TurtlePvPConfig.frameY = y
    end)
    
    return row
end

function WFC.Frame:UpdateLockState()
    if not hud then return end
    if TurtlePvPConfig.locked then
        hud.unlockBg:Hide()
    else
        hud.unlockBg:Show()
    end
end

function WFC.Frame:Disable()
    if hud then hud:Hide() end
    WFC.Frame:StopTicker()
end

function WFC.Frame:UpdateVisibility()
    if not TurtlePvPConfig.showFrame or not WFC.inWSG then
        WFC.Frame:Disable()
        return
    end
    
    hud:Show()
    WFC.Frame:StartTicker()
    
    if WFC.allyCarrier then
        hud.allyRow.carrierName = WFC.allyCarrier
        hud.allyRow.nameText:SetText(WFC.allyCarrier)
        hud.allyRow:Show()
    else
        hud.allyRow.carrierName = nil
        hud.allyRow.nameText:SetText("|cffaaaaaaNobody|r")
        hud.allyRow.hpBar:SetMinMaxValues(0, 100)
        hud.allyRow.hpBar:SetValue(0)
        hud.allyRow.hpBar:SetStatusBarColor(0.5, 0.5, 0.5)
        hud.allyRow.hpText:SetText("--")
        hud.allyRow.distText:SetText("--")
        hud.allyRow:Show()
    end
    
    if WFC.hordeCarrier then
        hud.hordeRow.carrierName = WFC.hordeCarrier
        hud.hordeRow.nameText:SetText(WFC.hordeCarrier)
        hud.hordeRow:Show()
    else
        hud.hordeRow.carrierName = nil
        hud.hordeRow.nameText:SetText("|cffaaaaaaNobody|r")
        hud.hordeRow.hpBar:SetMinMaxValues(0, 100)
        hud.hordeRow.hpBar:SetValue(0)
        hud.hordeRow.hpBar:SetStatusBarColor(0.5, 0.5, 0.5)
        hud.hordeRow.hpText:SetText("--")
        hud.hordeRow.distText:SetText("--")
        hud.hordeRow:Show()
    end
end

function WFC.Frame:StartTicker()
    if not hud.ticker then
        hud.ticker = CreateFrame("Frame", nil, hud)
        hud.ticker.elapsed = 0
        hud.ticker:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            if this.elapsed > 0.5 then
                this.elapsed = 0
                WFC.Frame:OnTick()
            end
        end)
    end
end

function WFC.Frame:StopTicker()
    if hud and hud.ticker then
        hud.ticker:SetScript("OnUpdate", nil)
        hud.ticker = nil
    end
end

local scanTooltip = CreateFrame("GameTooltip", "WFC_FlagScanTooltip", nil, "GameTooltipTemplate")

local function CheckUnitForFlag(unit)
    if (WFC.allyCarrier and WFC.hordeCarrier) or not UnitExists(unit) or not UnitIsPlayer(unit) then return end
    local name = UnitName(unit)
    if not name or name == "Unknown" then return end
    
    for i = 1, 32 do
        local tex = UnitBuff(unit, i)
        if not tex then break end
        tex = string.lower(tex)
        
        -- If we suspect a flag (texture has 'banner'), we officially verify the spell name
        -- This prevents false positives from Battle Standards which share the identical icon!
        if string.find(tex, "inv_banner") then
            scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            scanTooltip:ClearLines()
            scanTooltip:SetUnitBuff(unit, i)
            local buffName = WFC_FlagScanTooltipTextLeft1 and WFC_FlagScanTooltipTextLeft1:GetText()
            
            if buffName then
                buffName = string.lower(buffName)
                
                -- Alliance Flag (Silverwing Flag, carried by Horde)
                if not WFC.allyCarrier and string.find(buffName, "silverwing flag") then
                    WFC.allyCarrier = name
                    if WFC.Combat and WFC.Combat.ResetPhases then WFC.Combat:ResetPhases(name) end
                    WFC.Frame:UpdateVisibility()
                    WFC:Print("Scanner recovered Alliance Flag tracking on: " .. name)
                end
                
                -- Horde Flag (Warsong Flag, carried by Alliance)
                if not WFC.hordeCarrier and string.find(buffName, "warsong flag") then
                    WFC.hordeCarrier = name
                    if WFC.Combat and WFC.Combat.ResetPhases then WFC.Combat:ResetPhases(name) end
                    WFC.Frame:UpdateVisibility()
                    WFC:Print("Scanner recovered Horde Flag tracking on: " .. name)
                end
            end
        end
    end
end

function WFC.Frame:ScanMissingFlags()
    if WFC.allyCarrier and WFC.hordeCarrier then return end
    
    local tokens = {"player", "target", "mouseover"}
    for _, t in ipairs(tokens) do CheckUnitForFlag(t) end
    
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i=1, numRaid do
            CheckUnitForFlag("raid"..i)
            CheckUnitForFlag("raid"..i.."target")
        end
    else
        for i=1, GetNumPartyMembers() do
            CheckUnitForFlag("party"..i)
            CheckUnitForFlag("party"..i.."target")
        end
    end
end

function WFC.Frame:OnTick()
    -- Recover missing flag targets implicitly from buffs (for late joiners or missed events)
    WFC.Frame:ScanMissingFlags()

    WFC.Frame:UpdateRowHP(hud.allyRow, WFC.allyCarrier)
    WFC.Frame:UpdateRowHP(hud.hordeRow, WFC.hordeCarrier)
end

function WFC.Frame:UpdateRowHP(row, carrierName)
    if not carrierName then return end
    
    local hp = 0
    local hpMax = 100
    local found = false
    local targetId = nil
    local guid = WFC.Tracker and WFC.Tracker:GetGUID(carrierName) or nil
    
    -- ── Step 0: Actively try to find / seed the carrier GUID this tick ──
    -- Even if Tracker already has it, we try every tick to keep it warm.
    local function TrySeekCarrier()
        local checkTokens = {"target", "mouseover", "targettarget"}
        for _, t in ipairs(checkTokens) do
            if UnitExists(t) and UnitName(t) == carrierName then
                if GetUnitGUID then
                    local g = GetUnitGUID(t)
                    if g then
                        if WFC.Tracker then WFC.Tracker:ProcessGUID(g) end
                        if not guid then guid = g end
                    end
                end
                if not targetId then targetId = t end
            end
        end
        
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            for i = 1, numRaid do
                for _, suffix in ipairs({"", "target"}) do
                    local t = "raid"..i..suffix
                    if UnitExists(t) and UnitName(t) == carrierName then
                        if GetUnitGUID then
                            local g = GetUnitGUID(t)
                            if g then
                                if WFC.Tracker then WFC.Tracker:ProcessGUID(g) end
                                if not guid then guid = g end
                            end
                        end
                        if not targetId then targetId = t end
                    end
                end
            end
        else
            for i = 1, GetNumPartyMembers() do
                for _, suffix in ipairs({"", "target"}) do
                    local t = "party"..i..suffix
                    if UnitExists(t) and UnitName(t) == carrierName then
                        if GetUnitGUID then
                            local g = GetUnitGUID(t)
                            if g then
                                if WFC.Tracker then WFC.Tracker:ProcessGUID(g) end
                                if not guid then guid = g end
                            end
                        end
                        if not targetId then targetId = t end
                    end
                end
            end
        end
        
        -- Nameplate GUID harvest (Nampower extension: frame:GetName(1) returns GUID)
        if not guid and GetUnitGUID then
            local children = { WorldFrame:GetChildren() }
            for _, child in ipairs(children) do
                if child.GetName then
                    local g = child:GetName(1)
                    if type(g) == "string" and string.sub(g, 1, 2) == "0x" then
                        local n = UnitName(g)
                        if n == carrierName then
                            if WFC.Tracker then WFC.Tracker:ProcessGUID(g) end
                            guid = g
                        end
                    end
                end
            end
        end
    end
    TrySeekCarrier()

    -- ── Step 1: Distance via GUID first, token second ──
    if UnitXP then
        local distTarget = guid or targetId
        if distTarget then
            local success, distance = pcall(function()
                return UnitXP("distanceBetween", "player", distTarget)
            end)
            if success and type(distance) == "number" then
                if distance <= 20 then
                    row.distText:SetText(string.format("|cff00ff00%d yd|r", distance))
                elseif distance <= 40 then
                    row.distText:SetText(string.format("|cffffff00%d yd|r", distance))
                else
                    row.distText:SetText(string.format("|cffffffff%d yd|r", distance))
                end
            else
                row.distText:SetText("|cff888888? yd|r")
            end
        else
            row.distText:SetText("--")
        end
    else
        row.distText:SetText("--")
    end

    -- 2. Try getting absolute Health and MaxHealth securely via Nampower GUID
    if guid and GetUnitField then
        hp = GetUnitField(guid, "health")
        hpMax = GetUnitField(guid, "maxHealth")
        if hp and hpMax then
            found = true
            targetId = guid -- Nampower APIs support GUID tokens natively
        end
    end

    -- 3. Fallback: Rapidly scan 40-man raid/party targets for the carrier (Vanilla standard)
    if not found then
        if UnitName("target") == carrierName then
            targetId = "target"
        elseif UnitName("mouseover") == carrierName then
            targetId = "mouseover"
        end
        
        if not targetId then
            local numRaid = GetNumRaidMembers()
            if numRaid > 0 then
                for i=1, numRaid do
                    if UnitName("raid"..i) == carrierName then
                        targetId = "raid"..i
                        break
                    elseif UnitName("raid"..i.."target") == carrierName then
                        targetId = "raid"..i.."target"
                        break
                    end
                end
            else
                for i=1, GetNumPartyMembers() do
                    if UnitName("party"..i) == carrierName then
                        targetId = "party"..i
                        break
                    elseif UnitName("party"..i.."target") == carrierName then
                        targetId = "party"..i.."target"
                        break
                    end
                end
            end
        end

        if targetId then
            hp = UnitHealth(targetId)
            hpMax = UnitHealthMax(targetId)
            found = true
            
            -- If we naturally found them as a token, explicitly feed their GUID to our Tracker
            -- so that the distance calculation Engine starts working for them!
            if GetUnitGUID then
                local foundGuid = GetUnitGUID(targetId)
                if foundGuid and WFC.Tracker and WFC.Tracker.ProcessGUID then
                    WFC.Tracker:ProcessGUID(foundGuid)
                end
            end
        end
    end

    -- 4. Calculate aesthetics & dispatch bounds tracking
    local classColor = nil   -- local: prevents bleed between carrier ticks
    if targetId and found then
        if UnitClass then
            local _, eClass = UnitClass(targetId)
            if eClass then
                classColor = WFC:GetClassColor(eClass)
            end
        end
    end

    if classColor then
        row.nameText:SetText("|cff"..classColor..carrierName.."|r")
    end
    
    if found and hpMax and hpMax > 0 then
        row.hpBar:SetMinMaxValues(0, hpMax)
        row.hpBar:SetValue(hp)
        local pct = hp / hpMax
        row.hpText:SetText(math.floor(pct * 100) .. "%")

        if pct > 0.5 then
            row.hpBar:SetStatusBarColor(0, 1, 0)
        elseif pct > 0.25 then
            row.hpBar:SetStatusBarColor(1, 1, 0)
        else
            row.hpBar:SetStatusBarColor(1, 0, 0)
        end
        
        local myFaction = UnitFactionGroup("player")
        local isEnemyFC = (myFaction == "Alliance" and carrierName == WFC.allyCarrier) or (myFaction == "Horde" and carrierName == WFC.hordeCarrier)
        
        if hp <= 0 then
            -- Note: We REMOVED UnitIsDead(targetId) check here because UnitIsDead triggers heavily on Feign Death!
            -- Nampower API correctly returns hp=0 for Feign. If it's a real death, Nampower's UNIT_DIED catches it separately.
            if carrierName == WFC.allyCarrier then
                WFC.allyCarrier = nil
            end
            if carrierName == WFC.hordeCarrier then
                WFC.hordeCarrier = nil
            end
            WFC.Frame:UpdateVisibility()
        else
            if isEnemyFC then
                if WFC.Combat and WFC.Combat.CheckHP then
                    WFC.Combat:CheckHP(carrierName, hp, hpMax, targetId)
                end
            end
        end
    end
end
