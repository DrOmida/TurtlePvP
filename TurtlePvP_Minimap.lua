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
    panel:SetWidth(310)
    panel:SetHeight(340)
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

    -- ── Header ──────────────────────────────────────────────
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("|cff55ee22Turtle|rPvP  " .. GRAY .. "v3.1|r")

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetWidth(26); closeBtn:SetHeight(26)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    -- ── Tab strip ────────────────────────────────────────────
    local function MakeLine(parent, y)
        local t = parent:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        t:SetPoint("TOPLEFT",  parent, "TOPLEFT",   8, y)
        t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
        t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        t:SetVertexColor(0.3, 0.3, 0.3, 1)
    end
    MakeLine(panel, -30)

    local tabPages = {}
    local tabBtns  = {}
    local function SelectTab(idx)
        for i, pg in ipairs(tabPages) do
            if i == idx then pg:Show() else pg:Hide() end
        end
        for i, tb in ipairs(tabBtns) do
            if i == idx then
                tb:LockHighlight()
                tb:SetBackdropBorderColor(1, 0.82, 0, 1)
            else
                tb:UnlockHighlight()
                tb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            end
        end
    end

    local TAB_NAMES = { "Settings", "Credits" }
    for i, name in ipairs(TAB_NAMES) do
        local tb = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        tb:SetWidth(90); tb:SetHeight(20)
        tb:SetPoint("TOPLEFT", panel, "TOPLEFT", 8 + (i-1)*96, -35)
        tb:SetText(name)
        local idx = i
        tb:SetScript("OnClick", function() SelectTab(idx) end)
        table.insert(tabBtns, tb)
    end

    MakeLine(panel, -58)

    -- ── Page container helper ────────────────────────────────
    local function MakePage()
        local pg = CreateFrame("Frame", nil, panel)
        pg:SetPoint("TOPLEFT",     panel, "TOPLEFT",   0, -62)
        pg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
        pg:Hide()
        table.insert(tabPages, pg)
        return pg
    end

    -- ════════════════════════════════════════════
    -- TAB 1: Settings
    -- ════════════════════════════════════════════
    local settingsPage = MakePage()

    local function MakeHeader(parent, text, y)
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
        fs:SetText(GOLD .. text .. "|r")
    end

    local function AddCheck(parent, label, indentX, y, getF, setF)
        local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        c:SetWidth(24); c:SetHeight(24)
        c:SetPoint("TOPLEFT", parent, "TOPLEFT", indentX, y)
        local fs = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", c, "RIGHT", 4, 1)
        fs:SetText(WHITE .. label .. "|r")
        c.getF = getF
        c:SetScript("OnClick", function() setF(this:GetChecked() and true or false) end)
        table.insert(allChecks, c)
        return c
    end

    -- WSG
    MakeHeader(settingsPage, "WSG Flag Caller", -4)
    AddCheck(settingsPage, "Enable WSG Flag Caller Tracking", 16, -24,
        function() return TurtlePvPConfig.wsgEnabled end,
        function(v) TurtlePvPConfig.wsgEnabled = v; WFC:CheckZone(true) end)
    AddCheck(settingsPage, "Enemy HP Callouts in /bg chat", 32, -48,
        function() return TurtlePvPConfig.hpCallouts end,
        function(v) TurtlePvPConfig.hpCallouts = v end)
    AddCheck(settingsPage, "Show Flag Tracker HUD", 32, -72,
        function() return TurtlePvPConfig.showFrame end,
        function(v)
            TurtlePvPConfig.showFrame = v
            if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
        end)

    local thresh = settingsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    thresh:SetPoint("TOPLEFT", 44, -96)
    thresh:SetText(GRAY .. "HP callout thresholds: 75% / 50% / 25%|r")

    MakeLine(settingsPage, -110)

    -- Arena
    MakeHeader(settingsPage, "Arena Enemy HUD", -118)
    AddCheck(settingsPage, "Enable Arena Enemy Tracker HUD", 16, -138,
        function() return TurtlePvPConfig.arenaEnabled end,
        function(v) TurtlePvPConfig.arenaEnabled = v; WFC:CheckZone(true) end)
    AddCheck(settingsPage, "Show enemy distance (UnitXP)", 32, -162,
        function() return TurtlePvPConfig.arenaDistance end,
        function(v) TurtlePvPConfig.arenaDistance = v end)
    AddCheck(settingsPage, "Track trinkets / racials (Nampower)", 32, -186,
        function() return TurtlePvPConfig.arenaTrinkets end,
        function(v) TurtlePvPConfig.arenaTrinkets = v end)

    local arenaTip = settingsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arenaTip:SetPoint("TOPLEFT", 44, -210)
    arenaTip:SetText(GRAY .. "Auto-activates in PvP Arena zones.|r")

    MakeLine(settingsPage, -224)

    -- ── Combined WSG preview toggle button ────────────────────
    local wsgPreviewActive = false
    local previewBtn = CreateFrame("Button", nil, settingsPage, "UIPanelButtonTemplate")
    previewBtn:SetWidth(170); previewBtn:SetHeight(22)
    previewBtn:SetPoint("TOPLEFT", settingsPage, "TOPLEFT", 10, -234)
    previewBtn:SetText("Preview WSG + EFC Windows")
    previewBtn:SetScript("OnClick", function()
        wsgPreviewActive = not wsgPreviewActive
        if wsgPreviewActive then
            WFC.inWSG      = true
            WFC.allyCarrier  = UnitName("player")
            WFC.hordeCarrier = "Thrall"
            if WFC.Frame    and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
            if WFC.EFCReport and WFC.EFCReport.Show        then WFC.EFCReport:Show() end
            previewBtn:SetText("Hide WSG + EFC Windows")
            WFC:Print("WSG preview active — both windows shown.")
        else
            WFC.inWSG      = false
            WFC.allyCarrier  = nil
            WFC.hordeCarrier = nil
            if WFC.Frame    and WFC.Frame.Disable           then WFC.Frame:Disable() end
            if WFC.EFCReport and WFC.EFCReport.Hide         then WFC.EFCReport:Hide() end
            previewBtn:SetText("Preview WSG + EFC Windows")
            WFC:Print("WSG preview hidden.")
        end
    end)

    -- Reset button bottom-right
    local rstBtn = CreateFrame("Button", nil, settingsPage, "UIPanelButtonTemplate")
    rstBtn:SetWidth(110); rstBtn:SetHeight(22)
    rstBtn:SetPoint("BOTTOMRIGHT", settingsPage, "BOTTOMRIGHT", -10, 10)
    rstBtn:SetText("Reset Positions")
    rstBtn:SetScript("OnClick", function()
        TurtlePvPConfig.framePoint = "TOP"; TurtlePvPConfig.frameX = 0; TurtlePvPConfig.frameY = -150
        TurtlePvPConfig.arenaFramePoint = "CENTER"; TurtlePvPConfig.arenaFrameX = 0; TurtlePvPConfig.arenaFrameY = 0
        WFC:Print("Frame positions reset.")
    end)

    -- ════════════════════════════════════════════
    -- TAB 2: Credits
    -- ════════════════════════════════════════════
    local creditsPage = MakePage()

    local function AddLine(parent, text, y, font)
        local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
        fs:SetText(text)
        fs:SetJustifyH("LEFT")
        return fs
    end

    AddLine(creditsPage, GOLD .. "Author|r",                    -6,  "GameFontNormal")
    AddLine(creditsPage, WHITE .. "Adimo|r  " .. GRAY .. "@ Tel'abim|r",  -22)
    AddLine(creditsPage, GRAY .. "github.com/DrOmida/WSGFlagCaller|r", -36)

    AddLine(creditsPage, GOLD .. "Contributors / Inspiration|r", -56, "GameFontNormal")
    AddLine(creditsPage, GRAY .. "EFC Reporter concept: Cubenicke (Yrrol@vanillagaming)|r", -72)
    AddLine(creditsPage, GRAY .. "Map icons: lanevegame|r",          -86)
    AddLine(creditsPage, GRAY .. "Arena frame concept: zetone/byCFM2|r", -100)

    AddLine(creditsPage, GOLD .. "Changelog|r", -120, "GameFontNormal")

    local changes = {
        "|cff55ee22v3.1|r  Arena HUD: cast bars, trinket tracker,",
        "       target indicator, dynamic width",
        "|cff55ee22v3.1|r  Pull timer: leader check, /pull 15 via DBM",
        "|cff55ee22v3.1|r  WSG: anti-spam sync (Adimo priority)",
        "|cff55ee22v3.1|r  Curse of Tongues silences callouts",
        "|cff55ee22v3.1|r  Flag scanner: tooltip name verification",
        "       (fixes Battle Standard false-positives)",
        "|cff55ee22v3.1|r  Faction lock: flags only on enemy players",
        "|cff55ee22v3.1|r  New commands: /tpvp test wsg, force efc",
        "|cff55ee22v3.1|r  Minimap button + settings panel rewrite",
    }
    local cy = -136
    for _, line in ipairs(changes) do
        AddLine(creditsPage, GRAY .. line .. "|r", cy)
        cy = cy - 14
    end

    -- ── OnShow: sync checkboxes & reset tab to Settings ──────
    panel:SetScript("OnShow", function()
        for _, c in ipairs(allChecks) do
            if c.getF then c:SetChecked(c.getF() and 1 or 0) end
        end
        SelectTab(1)
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
