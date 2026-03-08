--[[
TurtlePvP_Minimap.lua
All frame creation deferred to VARIABLES_LOADED.
Zero code runs at file-parse time except storing references.
This prevents any silent abort from crashing TogglePanel registration.
--]]

WFC.Minimap = {}

local GOLD  = "|cffffd700"
local WHITE = "|cffffffff"
local GRAY  = "|cffaaaaaa"
local GREEN = "|cff00ff00"
local RED   = "|cffff0000"

-- Forward refs set in Init()
local mmButton, panel, qMenu
local panelBuilt  = false
local qMenuBuilt  = false
local dragging    = false
local allChecks   = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Minimap position helper (safe to call before button exists - returns early)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:UpdateMinimapPos()
    if not mmButton then return end
    local pos   = (TurtlePvPConfig and TurtlePvPConfig.minimapPos) or 45
    local angle = math.rad(pos)
    local r     = 80
    mmButton:ClearAllPoints()
    mmButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public: toggle settings panel
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:TogglePanel()
    if not panelBuilt then WFC.Minimap:BuildPanel() end
    if not panel then return end
    if panel:IsVisible() then panel:Hide() else panel:Show() end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Build the right-click quick menu (called once from Init)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:BuildQuickMenu()
    if qMenuBuilt then return end
    qMenuBuilt = true

    qMenu = CreateFrame("Frame", "TurtlePvPQuickMenu", UIParent)
    qMenu:SetWidth(190)
    qMenu:SetFrameStrata("TOOLTIP")
    qMenu:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left=3, right=3, top=3, bottom=3 },
    })
    qMenu:SetBackdropColor(0, 0, 0, 0.95)
    qMenu:Hide()

    -- Title
    local ttl = qMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ttl:SetPoint("TOP", 0, -8)
    ttl:SetText(GOLD .. "TurtlePvP|r  Options")

    local items = {
        { "Toggle WSG Caller", function()
            TurtlePvPConfig.wsgEnabled = not TurtlePvPConfig.wsgEnabled
            WFC:CheckZone(true)
            WFC:Print("WSG Caller " .. (TurtlePvPConfig.wsgEnabled and GREEN.."ON|r" or RED.."OFF|r"))
        end },
        { "Toggle Arena HUD", function()
            TurtlePvPConfig.arenaEnabled = not TurtlePvPConfig.arenaEnabled
            WFC:CheckZone(true)
            WFC:Print("Arena HUD " .. (TurtlePvPConfig.arenaEnabled and GREEN.."ON|r" or RED.."OFF|r"))
        end },
        { "Toggle EFC Map", function()
            if WFC.EFCReport and WFC.EFCReport.Toggle then WFC.EFCReport:Toggle() end
        end },
        { "Force WSG Window", function()
            WFC.inWSG = true
            WFC.allyCarrier = UnitName("player")
            WFC.hordeCarrier = "Thrall"
            if WFC.Frame  and WFC.Frame.UpdateVisibility  then WFC.Frame:UpdateVisibility() end
            if WFC.EFCReport and WFC.EFCReport.Show       then WFC.EFCReport:Show() end
            WFC:Print("WSG window forced open with test data.")
        end },
        { "Reset Positions", function()
            TurtlePvPConfig.framePoint = "TOP"; TurtlePvPConfig.frameX = 0; TurtlePvPConfig.frameY = -150
            TurtlePvPConfig.arenaFramePoint = "CENTER"; TurtlePvPConfig.arenaFrameX = 0; TurtlePvPConfig.arenaFrameY = 0
            WFC:Print("Frame positions reset.")
        end },
        { "Open Settings", function() WFC.Minimap:TogglePanel() end },
    }

    local yOff = -24
    for _, item in ipairs(items) do
        local b = CreateFrame("Button", nil, qMenu)
        b:SetWidth(172); b:SetHeight(18)
        b:SetPoint("TOP", qMenu, "TOP", 0, yOff)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", 4, 0)
        fs:SetText(WHITE .. item[1] .. "|r")
        local fn = item[2]
        b:SetScript("OnClick", function() qMenu:Hide(); if fn then fn() end end)
        yOff = yOff - 20
    end
    qMenu:SetHeight(math.abs(yOff) + 6)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Build the settings panel (called lazily on first TogglePanel)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:BuildPanel()
    if panelBuilt then return end
    panelBuilt = true

    panel = CreateFrame("Frame", "TurtlePvPSettingsPanel", UIParent)
    panel:SetWidth(300)
    panel:SetHeight(320)
    panel:SetPoint("CENTER", 0, 60)
    panel:SetFrameStrata("HIGH")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() this:StartMoving() end)
    panel:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
    panel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left=4, right=4, top=4, bottom=4 },
    })
    panel:SetBackdropColor(0, 0, 0.04, 0.95)
    panel:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    panel:Hide()

    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("|cff55ee22Turtle|rPvP  " .. GRAY .. "Settings|r")

    local ver = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ver:SetPoint("TOPRIGHT", -36, -12)
    ver:SetText(GRAY .. "v3.1|r")

    -- Close
    local cb = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    cb:SetWidth(26); cb:SetHeight(26)
    cb:SetPoint("TOPRIGHT", -4, -4)

    -- divider
    local function MakeLine(y)
        local t = panel:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        t:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, y)
        t:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, y)
        t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        t:SetVertexColor(0.3, 0.3, 0.3, 1)
    end

    local function MakeSectionHeader(text, y)
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, y)
        fs:SetText(GOLD .. text .. "|r")
    end

    local function AddCheck(label, indentX, y, getF, setF)
        local c = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        c:SetWidth(24); c:SetHeight(24)
        c:SetPoint("TOPLEFT", panel, "TOPLEFT", indentX, y)
        local fs = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", c, "RIGHT", 4, 1)
        fs:SetText(WHITE .. label .. "|r")
        c.getF = getF
        c:SetScript("OnClick", function() setF(this:GetChecked() and true or false) end)
        table.insert(allChecks, c)
        return c
    end

    MakeLine(-30)

    -- WSG section
    MakeSectionHeader("WSG Flag Caller", -38)
    AddCheck("Enable WSG Flag Caller Tracking", 16, -58,
        function() return TurtlePvPConfig.wsgEnabled end,
        function(v) TurtlePvPConfig.wsgEnabled = v; WFC:CheckZone(true) end)
    AddCheck("Enemy HP Callouts in /bg chat", 32, -82,
        function() return TurtlePvPConfig.hpCallouts end,
        function(v) TurtlePvPConfig.hpCallouts = v end)
    AddCheck("Show Flag Tracker HUD window", 32, -106,
        function() return TurtlePvPConfig.showFrame end,
        function(v) TurtlePvPConfig.showFrame = v; if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end end)

    local thresh = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    thresh:SetPoint("TOPLEFT", 44, -130)
    thresh:SetText(GRAY .. "HP callout thresholds: 75% / 50% / 25%|r")

    local forceWsg = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    forceWsg:SetWidth(140); forceWsg:SetHeight(22)
    forceWsg:SetPoint("TOPLEFT", 16, -150)
    forceWsg:SetText("Force WSG Window")
    forceWsg:SetScript("OnClick", function()
        WFC.inWSG = true
        WFC.allyCarrier = UnitName("player"); WFC.hordeCarrier = "Thrall"
        if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
        if WFC.EFCReport and WFC.EFCReport.Show then WFC.EFCReport:Show() end
        WFC:Print("WSG window forced with test data.")
    end)

    MakeLine(-180)

    -- Arena section
    MakeSectionHeader("Arena Enemy HUD", -188)
    AddCheck("Enable Arena Enemy Tracker HUD", 16, -208,
        function() return TurtlePvPConfig.arenaEnabled end,
        function(v) TurtlePvPConfig.arenaEnabled = v; WFC:CheckZone(true) end)
    AddCheck("Show enemy distance  (UnitXP)", 32, -232,
        function() return TurtlePvPConfig.arenaDistance end,
        function(v) TurtlePvPConfig.arenaDistance = v end)
    AddCheck("Track trinkets / racials  (Nampower)", 32, -256,
        function() return TurtlePvPConfig.arenaTrinkets end,
        function(v) TurtlePvPConfig.arenaTrinkets = v end)

    local tip = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tip:SetPoint("TOPLEFT", 44, -280)
    tip:SetText(GRAY .. "Auto-activates in Arena zones.|r")

    MakeLine(-294)

    -- Bottom buttons
    local efcBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    efcBtn:SetWidth(100); efcBtn:SetHeight(22)
    efcBtn:SetPoint("BOTTOMLEFT", 10, 8)
    efcBtn:SetText("EFC Map")
    efcBtn:SetScript("OnClick", function()
        if WFC.EFCReport and WFC.EFCReport.Toggle then WFC.EFCReport:Toggle() end
    end)

    local rstBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    rstBtn:SetWidth(110); rstBtn:SetHeight(22)
    rstBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    rstBtn:SetText("Reset Positions")
    rstBtn:SetScript("OnClick", function()
        TurtlePvPConfig.framePoint = "TOP"; TurtlePvPConfig.frameX = 0; TurtlePvPConfig.frameY = -150
        TurtlePvPConfig.arenaFramePoint = "CENTER"; TurtlePvPConfig.arenaFrameX = 0; TurtlePvPConfig.arenaFrameY = 0
        WFC:Print("Frame positions reset.")
    end)

    -- Sync checkboxes on every open
    panel:SetScript("OnShow", function()
        for _, c in ipairs(allChecks) do
            if c.getF then c:SetChecked(c.getF() and 1 or 0) end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Build the minimap button (called from VARIABLES_LOADED)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:BuildMinimapButton()
    mmButton = CreateFrame("Button", "TurtlePvPMinimapBtn", Minimap)
    mmButton:SetWidth(31)
    mmButton:SetHeight(31)
    mmButton:SetFrameStrata("MEDIUM")
    mmButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = mmButton:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(mmButton)
    bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bg:SetVertexColor(0.07, 0.07, 0.18, 1)

    local icon = mmButton:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Ability_DualWield")
    icon:SetWidth(20); icon:SetHeight(20)
    icon:SetPoint("CENTER")

    local border = mmButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(53); border:SetHeight(53)
    border:SetPoint("CENTER")

    -- Position
    WFC.Minimap:UpdateMinimapPos()

    -- Drag
    mmButton:RegisterForDrag("LeftButton")
    mmButton:SetMovable(true)
    mmButton:SetScript("OnDragStart", function() dragging = true end)
    mmButton:SetScript("OnDragStop",  function() dragging = false end)

    local dragF = CreateFrame("Frame")
    dragF:SetScript("OnUpdate", function()
        if not dragging then return end
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local s = UIParent:GetEffectiveScale() or 1
        px, py = px / s, py / s
        TurtlePvPConfig.minimapPos = math.deg(math.atan2(py - my, px - mx))
        WFC.Minimap:UpdateMinimapPos()
    end)

    -- Tooltip
    mmButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText(GOLD .. "TurtlePvP|r")
        GameTooltip:AddLine("Left-click: Settings panel", 1,1,1)
        GameTooltip:AddLine("Right-click: Quick menu",    0.8,0.8,0.8)
        GameTooltip:Show()
    end)
    mmButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Auto-hide qMenu on outside click
    local hider = CreateFrame("Frame")
    hider:SetScript("OnUpdate", function()
        if qMenu and qMenu:IsVisible() and IsMouseButtonDown("LeftButton") then
            if not MouseIsOver(qMenu) and not MouseIsOver(mmButton) then
                qMenu:Hide()
            end
        end
    end)

    -- Clicks
    mmButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mmButton:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            if qMenu then qMenu:Hide() end
            WFC.Minimap:TogglePanel()
        else
            if qMenu then
                if qMenu:IsVisible() then
                    qMenu:Hide()
                else
                    local x, y = GetCursorPosition()
                    local s = UIParent:GetEffectiveScale() or 1
                    x, y = x / s, y / s
                    qMenu:ClearAllPoints()
                    qMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
                    qMenu:Show()
                end
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- VARIABLES_LOADED: everything safe to create now
-- ─────────────────────────────────────────────────────────────────────────────
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    if not TurtlePvPConfig then TurtlePvPConfig = {} end
    WFC.Minimap:BuildQuickMenu()
    WFC.Minimap:BuildMinimapButton()
end)
