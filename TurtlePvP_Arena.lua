WFC.Arena = {
    enemies = {},       -- name -> { guid, classToken, hp, hpMax, lastTrinketTime, trinketSpell }
    orderedNames = {},  -- array of names in order of detection
    enabled = false
}

WFC.Arena.TRINKET_SPELLS = {
    [13750] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01",
    [23273] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02",
}

local MAX_ENEMIES = 8
local frame = CreateFrame("Frame")
local hud = CreateFrame("Frame", "TurtlePvPArenaHUD", UIParent)

-- Arena HUD Setup (Restyled to match EFCReport/Config layout)
hud:SetWidth(200)
hud:SetHeight(30 + (MAX_ENEMIES * 25))
hud:EnableMouse(true)
hud:SetMovable(true)
hud:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
hud:Hide()
hud.rows = {}

hud:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
hud:SetBackdropColor(0, 0, 0, 0.88)
hud:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

local title = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
title:SetPoint("TOP", hud, "TOP", 0, -8)
title:SetText("|cffffd700Arena Enemies|r")

local unlockBg = hud:CreateTexture(nil, "BACKGROUND")
unlockBg:SetAllPoints()
unlockBg:SetTexture(0, 1, 0, 0.2)
hud.unlockBg = unlockBg

hud:RegisterForDrag("LeftButton")
hud:SetScript("OnDragStart", function() if not TurtlePvPConfig.arenaLocked then this:StartMoving() end end)
hud:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
    TurtlePvPConfig.arenaFramePoint = point
    TurtlePvPConfig.arenaFrameX = xOfs
    TurtlePvPConfig.arenaFrameY = yOfs
end)

local function UpdateArenaLock()
    if TurtlePvPConfig.arenaLocked then
        hud.unlockBg:Hide()
    else
        hud.unlockBg:Show()
    end
end

for i=1, MAX_ENEMIES do
    local row = CreateFrame("Button", nil, hud)
    row:SetWidth(190)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", hud, "TOPLEFT", 5, -24 - ((i-1)*22))
    
    local tex = row:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture(0, 0, 0, 0.5)
    row.bg = tex
    
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    nameText:SetText("")
    row.nameText = nameText
    
    local hpBar = CreateFrame("StatusBar", nil, row)
    hpBar:SetWidth(90)
    hpBar:SetHeight(12)
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

    local trinketIcon = row:CreateTexture(nil, "OVERLAY")
    trinketIcon:SetWidth(14)
    trinketIcon:SetHeight(14)
    trinketIcon:SetPoint("LEFT", nameText, "RIGHT", 4, 0)
    row.trinketIcon = trinketIcon
    
    row:RegisterForDrag("LeftButton")
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function()
        if arg1 == "LeftButton" and not TurtlePvPConfig.arenaLocked then
            if row.targetName then TargetByName(row.targetName, true) end
        elseif arg1 == "RightButton" then
            TurtlePvPConfig.arenaLocked = not TurtlePvPConfig.arenaLocked
            UpdateArenaLock()
        end
    end)
    
    row:SetScript("OnDragStart", function() if not TurtlePvPConfig.arenaLocked then hud:StartMoving() end end)
    row:SetScript("OnDragStop", function()
        hud:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = hud:GetPoint()
        TurtlePvPConfig.arenaFramePoint = point
        TurtlePvPConfig.arenaFrameX = xOfs
        TurtlePvPConfig.arenaFrameY = yOfs
    end)
    
    row:Hide()
    hud.rows[i] = row
end

function WFC.Arena:Enable()
    if WFC.Arena.enabled then return end
    WFC.Arena.enabled = true
    hud:SetPoint(TurtlePvPConfig.arenaFramePoint or "CENTER", UIParent, TurtlePvPConfig.arenaFramePoint or "CENTER", TurtlePvPConfig.arenaFrameX or 0, TurtlePvPConfig.arenaFrameY or 0)
    UpdateArenaLock()
    hud:Show()
    frame:RegisterEvent("UNIT_DIED")
    frame:RegisterEvent("SPELL_START_OTHER")
    -- Arena Chat Hooks
    frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    frame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
    WFC.Arena:Reset()
    
    -- 0.5s Scanner
    hud.ticker = CreateFrame("Frame")
    hud.ticker:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed > 0.5 then
            this.elapsed = 0
            WFC.Arena:Scan()
            WFC.Arena:UpdateHUD()
        end
    end)
end

function WFC.Arena:Disable()
    WFC.Arena.enabled = false
    hud:Hide()
    frame:UnregisterAllEvents()
    if hud.ticker then hud.ticker:SetScript("OnUpdate", nil) end
    WFC.Arena:Reset()
end

function WFC.Arena:Reset()
    WFC.Arena.enemies = {}
    WFC.Arena.orderedNames = {}
    
    for i=1, MAX_ENEMIES do
        hud.rows[i]:Hide()
    end
    hud:SetHeight(30)
end

function WFC.Arena:AddEnemy(guid, name)
    if not guid or not name or name == "Unknown" then return end
    
    -- Deduplication logic fix: check correctly by indexing and array enforce
    if not WFC.Arena.enemies[name] then
        WFC.Arena.enemies[name] = { guid = guid }
        -- Bulletproof array check to explicitly stop screenshot ghost clones
        local found = false
        for _, n in ipairs(WFC.Arena.orderedNames) do
            if n == name then found = true; break; end
        end
        if not found then
            table.insert(WFC.Arena.orderedNames, name)
        end
    else
        -- If they already exist, just forcefully update their GUID in case it was bad previously
        WFC.Arena.enemies[name].guid = guid
    end
    
    -- Sync GUID to tracker engine
    if WFC.Tracker and WFC.Tracker.ProcessGUID then
        WFC.Tracker:ProcessGUID(guid)
    end
end

function WFC.Arena:Scan()
    local myFaction = UnitFactionGroup("player")
    
    -- Active Scanner via GetUnitGUID
    local tokens = {"target", "mouseover", "targettarget"}
    for _, t in ipairs(tokens) do
        if UnitExists(t) and UnitIsPlayer(t) and UnitIsEnemy("player", t) then
            local pName = UnitName(t)
            local pGuid = GetUnitGUID and GetUnitGUID(t)
            if pName and pGuid then WFC.Arena:AddEnemy(pGuid, pName) end
        end
    end
    
    -- Nameplate Scanner
    local children = { WorldFrame:GetChildren() }
    for _, child in ipairs(children) do
        if child.GetName and child:GetName(1) then
            local guid = child:GetName(1)
            -- Only Nampower extends GetName(1) to return GUID
            if type(guid) == "string" and string.sub(guid, 1, 2) == "0x" then
                local pName = UnitName(guid)
                local isEnemy = UnitCanAttack("player", guid) or (UnitFactionGroup(guid) and UnitFactionGroup(guid) ~= myFaction)
                if pName and isEnemy then
                    WFC.Arena:AddEnemy(guid, pName)
                end
            end
        end
    end
end

frame:SetScript("OnEvent", function(...)
    if not WFC.Arena.enabled then return end
    
    if event == "UNIT_DIED" then
        if arg1 and WFC.Tracker then
            local deadName = WFC.Tracker.guidToName[arg1] or UnitName(arg1)
            if deadName and WFC.Arena.enemies[deadName] then
                WFC.Arena.enemies[deadName] = nil
                -- Remove from order
                for i, n in ipairs(WFC.Arena.orderedNames) do
                    if n == deadName then
                        table.remove(WFC.Arena.orderedNames, i)
                        break
                    end
                end
                WFC.Arena:UpdateHUD()
            end
        end
    elseif event == "CHAT_MSG_MONSTER_YELL" or event == "CHAT_MSG_MONSTER_EMOTE" then
        local msg = arg1
        if not msg then return end
        if string.find(msg, "The Arena battle has begun!") then
            WFC.Arena:Reset()
            WFC:Print("|cffffff00Arena Match Started! Tracking logic reset.|r")
        elseif string.find(msg, "team wins!") then
            WFC:Print("|cffffff00Arena Match Ended! Cleared board.|r")
            WFC.Arena:Reset()
        end
    elseif event == "SPELL_START_OTHER" then
        local spellId = arg2
        local casterGuid = arg3
        if casterGuid and spellId then
            local casterName = UnitName(casterGuid)
            if casterName then
                -- Add to enemies if not there
                local myFaction = UnitFactionGroup("player")
                local isEnemy = UnitCanAttack("player", casterGuid) or (UnitFactionGroup(casterGuid) and UnitFactionGroup(casterGuid) ~= myFaction)
                if isEnemy then
                    WFC.Arena:AddEnemy(casterGuid, casterName)
                end
                
                -- Detect PvP Trinkets specifically
                if TurtlePvPConfig.arenaTrinkets and WFC.Arena.TRINKET_SPELLS[spellId] and WFC.Arena.enemies[casterName] then
                    local texPath = WFC.Arena.TRINKET_SPELLS[spellId]
                    WFC.Arena.enemies[casterName].lastTrinketTime = GetTime()
                    WFC.Arena.enemies[casterName].trinketSpell = texPath
                    WFC:Print("|cffff0000[Arena]|r " .. casterName .. " used their PvP Trinket!")
                end
            end
        end
    end
end)

function WFC.Arena:UpdateHUD()
    if not TurtlePvPConfig.showFrame then 
        hud:Hide()
        return
    else
        hud:Show()
    end

    local rowIdx = 1
    for _, name in ipairs(WFC.Arena.orderedNames) do
        if rowIdx > MAX_ENEMIES then break end
        local eData = WFC.Arena.enemies[name]
        
        -- Incase it hit a nil bug condition during removal
        if eData then
            local row = hud.rows[rowIdx]
            row.targetName = name
            
            -- HP and Distance
            local hp, hpMax = 0, 100
            
            if GetUnitField then
                hp = GetUnitField(eData.guid, "health") or 0
                hpMax = GetUnitField(eData.guid, "maxHealth") or 100
            elseif UnitName("target") == name then
                hp = UnitHealth("target")
                hpMax = UnitHealthMax("target")
            end
            eData.hp = hp
            eData.hpMax = hpMax
            
            if hpMax and hpMax > 0 then
                row.hpBar:SetMinMaxValues(0, hpMax)
                row.hpBar:SetValue(hp)
                local pct = hp / hpMax
                row.hpText:SetText(math.floor(pct * 100) .. "%")
                
                if pct > 0.5 then row.hpBar:SetStatusBarColor(0, 1, 0)
                elseif pct > 0.25 then row.hpBar:SetStatusBarColor(1, 1, 0)
                else row.hpBar:SetStatusBarColor(1, 0, 0) end
            else
                row.hpBar:SetMinMaxValues(0, 100)
                row.hpBar:SetValue(0)
                row.hpBar:SetStatusBarColor(0.5, 0.5, 0.5)
                row.hpText:SetText("--")
            end
            
            -- Distance
            row.distText:SetText("--")
            if TurtlePvPConfig.arenaDistance and UnitXP then
                local success, dist = pcall(function() return UnitXP("distanceBetween", "player", eData.guid) end)
                if success and dist then
                    if dist <= 20 then row.distText:SetText(string.format("|cffff0000%d yd|r", dist))
                    elseif dist <= 40 then row.distText:SetText(string.format("|cffffff00%d yd|r", dist))
                    else row.distText:SetText(string.format("|cffffffff%d yd|r", dist)) end
                end
            end

            local classToken = nil
            if UnitClass then _, classToken = UnitClass(eData.guid) end
            local cColor = classToken and WFC:GetClassColor(classToken) or "FFFFFF"
            row.nameText:SetText("|cff" .. cColor .. name .. "|r")
            
            -- Trinket CD (Assuming 2 min CD for standard PvP trinket, keep icon for 120s)
            if eData.lastTrinketTime and (GetTime() - eData.lastTrinketTime) < 120 then
                row.trinketIcon:SetTexture(eData.trinketSpell)
                row.trinketIcon:Show()
            else
                row.trinketIcon:Hide()
            end

            row:Show()
            rowIdx = rowIdx + 1
        end
    end
    
    -- Hide unused
    for i=rowIdx, MAX_ENEMIES do
        hud.rows[i]:Hide()
    end
    
    if rowIdx > 1 then
        hud:SetHeight(30 + ((rowIdx - 1) * 22))
    else
        hud:SetHeight(30) -- just title
    end
end
