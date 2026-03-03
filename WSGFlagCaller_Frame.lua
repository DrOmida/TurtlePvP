WFC.Frame = {}
local hud = nil

function WFC.Frame:Initialize()
    hud = CreateFrame("Frame", "WSGFCHud", UIParent)
    hud:SetWidth(200)
    hud:SetHeight(60)
    hud:SetPoint(WSGFCConfig.framePoint, UIParent, WSGFCConfig.framePoint, WSGFCConfig.frameX, WSGFCConfig.frameY)
    hud:SetMovable(true)
    hud:SetMovable(true)
    
    local unlockBg = hud:CreateTexture(nil, "BACKGROUND")
    unlockBg:SetAllPoints()
    unlockBg:SetTexture(0, 1, 0, 0.3)
    hud.unlockBg = unlockBg
    
    hud.allyRow = WFC.Frame:CreateRow(hud, 0, "Alliance Flag")
    hud.hordeRow = WFC.Frame:CreateRow(hud, -30, "Horde Flag")
    
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
    
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
    if string.find(label, "Alliance") then
        icon:SetTexture("Interface\\Icons\\INV_Banner_02") 
    else
        icon:SetTexture("Interface\\Icons\\INV_Banner_03")
    end
    
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", icon, "RIGHT", 5, 0)
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
    
    local distText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    distText:SetPoint("RIGHT", hpBar, "LEFT", -5, 0)
    distText:SetText("--")
    row.distText = distText
    
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            WSGFCConfig.locked = not WSGFCConfig.locked
            if WSGFCConfig.locked then
                WFC:Print("HUD Locked.")
            else
                WFC:Print("HUD Unlocked. You can now drag the HUD.")
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
        if not WSGFCConfig.locked then 
            parent:StartMoving() 
        end 
    end)
    row:SetScript("OnDragStop", function() 
        parent:StopMovingOrSizing() 
        local p, _, rp, x, y = parent:GetPoint()
        WSGFCConfig.framePoint = p
        WSGFCConfig.frameX = x
        WSGFCConfig.frameY = y
    end)
    
    return row
end

function WFC.Frame:UpdateLockState()
    if not hud then return end
    if WSGFCConfig.locked then
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
    if not WSGFCConfig.showFrame or not WFC.inWSG then
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

function WFC.Frame:OnTick()
    WFC.Frame:UpdateRowHP(hud.allyRow, WFC.allyCarrier)
    WFC.Frame:UpdateRowHP(hud.hordeRow, WFC.hordeCarrier)
end

function WFC.Frame:UpdateRowHP(row, carrierName)
    if not carrierName then return end
    
    local hp = 0
    local hpMax = 100
    local found = false
    local classColor = nil
    local targetId = nil
    local guid = WFC.Tracker and WFC.Tracker:GetGUID(carrierName) or nil

    -- 1. Try resolving distance via Nampower/UnitXP if we have GUID
    if guid and WFC.hasUnitXP then
        local success, distance = pcall(function()
            return UnitXP("distanceBetween", "player", guid)
        end)
        if success and distance then
            if distance <= 20 then
                row.distText:SetText(string.format("|cffff0000%d yd|r", distance))
            elseif distance <= 40 then
                row.distText:SetText(string.format("|cffffff00%d yd|r", distance))
            else
                row.distText:SetText(string.format("|cffffffff%d yd|r", distance))
            end
        else
            row.distText:SetText("--")
        end
    else
        row.distText:SetText("--")
    end

    -- 2. Try getting absolute Health and MaxHealth securely via Nampower GUID
    if guid and WFC.hasNampower and GetUnitField then
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
        end
    end

    -- 4. Calculate aesthetics & dispatch bounds tracking
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
