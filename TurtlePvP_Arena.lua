WFC.Arena = {
    enemies = {},       -- name -> { guid, hp, hpMax, lastTrinketTime, trinketSpell }
    enabled = false
}

WFC.Arena.TRINKET_SPELLS = {
    [13750] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_01",
    [23273] = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02",
}

local MAX_ENEMIES = 8
local frame = CreateFrame("Frame")
-- HUD is natively a Button so it handles drag/click safely without child desync memory crash!
local hud = CreateFrame("Button", "TurtlePvPArenaHUD", UIParent)

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

local unlockBg = hud:CreateTexture(nil, "BACKGROUND")
unlockBg:SetPoint("TOPLEFT", hud, "TOPLEFT", 2, -2)
unlockBg:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -2, -2)
unlockBg:SetHeight(20)
unlockBg:SetTexture(0, 1, 0, 0.2)
hud.unlockBg = unlockBg

local title = hud:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
title:SetPoint("TOP", hud, "TOP", 0, -8)
title:SetText("|cffffd700Arena Enemies|r")

hud:RegisterForDrag("LeftButton")
hud:RegisterForClicks("RightButtonUp")

hud:SetScript("OnDragStart", function() 
    if not TurtlePvPConfig.arenaLocked then 
        this:StartMoving() 
    end 
end)

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

hud:SetScript("OnClick", function()
    if arg1 == "RightButton" then
        TurtlePvPConfig.arenaLocked = not TurtlePvPConfig.arenaLocked
        UpdateArenaLock()
        if TurtlePvPConfig.arenaLocked then
            WFC:Print("Arena HUD Locked.")
        else
            WFC:Print("Arena HUD Unlocked. You can now drag the title bar.")
        end
    end
end)

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
    
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            if row.targetName then TargetByName(row.targetName, true) end
        end
    end)
    
    row:Hide()
    hud.rows[i] = row
end

function WFC.Arena:Enable()
    if WFC.Arena.enabled then return end
    WFC.Arena.enabled = true
    
    local pt = TurtlePvPConfig.arenaFramePoint or "CENTER"
    local x = TurtlePvPConfig.arenaFrameX or 0
    local y = TurtlePvPConfig.arenaFrameY or 0
    hud:ClearAllPoints()
    hud:SetPoint(pt, UIParent, pt, x, y)
    
    UpdateArenaLock()
    hud:Show()
    frame:RegisterEvent("UNIT_DIED")
    frame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
    frame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
    frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
    -- Arena Chat Hooks
    frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    frame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
    WFC.Arena:Reset()
    
    -- 0.5s Scanner
    if not hud.ticker then
        hud.ticker = CreateFrame("Frame")
        hud.ticker:SetScript("OnUpdate", function()
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed > 0.5 then
                this.elapsed = 0
                if WFC.Arena.enabled then
                    WFC.Arena:Scan()
                    WFC.Arena:UpdateHUD()
                end
            end
        end)
    end
end

function WFC.Arena:Disable()
    WFC.Arena.enabled = false
    hud:Hide()
    frame:UnregisterAllEvents()
    WFC.Arena:Reset()
end

function WFC.Arena:Reset()
    WFC.Arena.enemies = {}
    
    for i=1, MAX_ENEMIES do
        hud.rows[i]:Hide()
    end
    hud:SetHeight(30)
end

function WFC.Arena:AddEnemy(guid, name)
    if not guid or not name or name == "Unknown" then return end
    
    if not WFC.Arena.enemies[name] then
        WFC.Arena.enemies[name] = { guid = guid, lastTrinketTime = 0 }
    else
        WFC.Arena.enemies[name].guid = guid
    end
    
    -- Sync GUID to tracker engine
    if WFC.Tracker and WFC.Tracker.ProcessGUID then
        WFC.Tracker:ProcessGUID(guid)
    end
end

function WFC.Arena:Scan()
    -- Active Scanner via GetUnitGUID
    local tokens = {"target", "mouseover", "targettarget"}
    for _, t in ipairs(tokens) do
        if UnitExists(t) and UnitIsPlayer(t) and UnitIsEnemy("player", t) then
            local pName = UnitName(t)
            local pGuid = GetUnitGUID and GetUnitGUID(t)
            if pName and pGuid then WFC.Arena:AddEnemy(pGuid, pName) end
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
    elseif event == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF" or event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE" or event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS" then
        if TurtlePvPConfig.arenaTrinkets and arg1 then
            if string.find(arg1, "Will of the Forsaken") or string.find(arg1, "PvP Trinket") or string.find(arg1, "Stoneform") or string.find(arg1, "Escape Artist") or string.find(arg1, "Perception") then
                for casterName in string.gfind(arg1, "^([^%s]+)") do
                    -- Strip trailing apostrophe S if the log says "Dadger's PvP Trinket"
                    casterName = string.gsub(casterName, "'s$", "")
                    if WFC.Arena.enemies[casterName] then
                        WFC.Arena.enemies[casterName].lastTrinketTime = GetTime()
                        WFC.Arena.enemies[casterName].trinketSpell = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"
                        WFC:Print("|cffff0000[Arena]|r " .. casterName .. " used their PvP Trinket!")
                    end
                end
            end
        end
    end
end)

function WFC.Arena:UpdateHUD()
    if not TurtlePvPConfig.arenaEnabled then 
        hud:Hide()
        return
    else
        hud:Show()
    end

    local rowIdx = 1
    local cleanNames = {}
    for n, _ in pairs(WFC.Arena.enemies) do
        table.insert(cleanNames, n)
    end
    table.sort(cleanNames)

    for _, name in ipairs(cleanNames) do
        if rowIdx > MAX_ENEMIES then break end
        local eData = WFC.Arena.enemies[name]
        if eData then
            local row = hud.rows[rowIdx]
            row.targetName = name
            
            -- Detect active PvP Trinket buff directly from Unit buffs if targeted
            if TurtlePvPConfig.arenaTrinkets and UnitName("target") == name then
                for i = 1, 32 do
                    local tex = UnitBuff("target", i)
                    if not tex then break end
                    if string.find(string.lower(tex), "inv_jewelry_trinketpvp") then
                        eData.lastTrinketTime = GetTime()
                        eData.trinketSpell = tex
                    end
                end
            end
            
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
            if eData.lastTrinketTime and eData.lastTrinketTime > 0 and (GetTime() - eData.lastTrinketTime) < 120 then
                row.trinketIcon:SetTexture(eData.trinketSpell or "Interface\\Icons\\INV_Jewelry_TrinketPVP_02")
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
