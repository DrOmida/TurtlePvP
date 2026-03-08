--[[
TurtlePvP_Minimap.lua  v3.2
Free-floating launcher button (UIParent, pfUI-safe).
All frame creation deferred to VARIABLES_LOADED.
TogglePanel / public API defined at parse-time so it is always available.
--]]

WFC.Minimap = {}

local GOLD  = "|cffffd700"
local WHITE = "|cffffffff"
local GRAY  = "|cffaaaaaa"
local GREEN = "|cff00ff00"
local RED   = "|cffff0000"
local TEAL  = "|cff55ee22"

-- Forward refs populated in Build* functions
local btn, panel, qMenu
local panelBuilt = false
local qMenuBuilt = false
local allChecks  = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API  (defined before any frame creation so /tpvp always finds them)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:TogglePanel()
    if not panelBuilt then WFC.Minimap:BuildPanel() end
    if not panel then return end
    if panel:IsVisible() then panel:Hide() else panel:Show() end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: thin horizontal rule
-- ─────────────────────────────────────────────────────────────────────────────
local function MakeLine(parent, y)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",   8, y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
    t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    t:SetVertexColor(0.3, 0.3, 0.3, 1)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Quick right-click menu
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:BuildQuickMenu()
    if qMenuBuilt then return end
    qMenuBuilt = true

    qMenu = CreateFrame("Frame", "TurtlePvPQuickMenu", UIParent)
    qMenu:SetWidth(196)
    qMenu:SetFrameStrata("TOOLTIP")
    qMenu:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left=3, right=3, top=3, bottom=3 },
    })
    qMenu:SetBackdropColor(0, 0, 0, 0.95)
    qMenu:Hide()

    local titleFs = qMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleFs:SetPoint("TOP", 0, -8)
    titleFs:SetText(TEAL .. "Turtle" .. "|rPvP  " .. GOLD .. "Options|r")

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
        { "Reset All Windows", function()
            WFC.Minimap:ResetAllPositions()
        end },
        { "Open Settings", function() WFC.Minimap:TogglePanel() end },
    }

    local yOff = -24
    for _, item in ipairs(items) do
        local b = CreateFrame("Button", nil, qMenu)
        b:SetWidth(178); b:SetHeight(18)
        b:SetPoint("TOP", qMenu, "TOP", 0, yOff)
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", 6, 0)
        fs:SetText(WHITE .. item[1] .. "|r")
        local fn = item[2]
        b:SetScript("OnClick", function() qMenu:Hide(); if fn then fn() end end)
        yOff = yOff - 20
    end
    qMenu:SetHeight(math.abs(yOff) + 6)

    -- Auto-hide on outside click
    local hider = CreateFrame("Frame")
    hider:SetScript("OnUpdate", function()
        if qMenu:IsVisible() and IsMouseButtonDown("LeftButton") then
            if not MouseIsOver(qMenu) and (not btn or not MouseIsOver(btn)) then
                qMenu:Hide()
            end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Shared: reset all frame positions
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:ResetAllPositions()
    -- WSG HUD: clear saved point and physically move live frame
    TurtlePvPConfig.framePoint = "TOP"
    TurtlePvPConfig.frameX     = 0
    TurtlePvPConfig.frameY     = -150
    if TurtlePvPHUDFrame then
        TurtlePvPHUDFrame:ClearAllPoints()
        TurtlePvPHUDFrame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    elseif WFC.Frame and WFC.Frame.frame then
        WFC.Frame.frame:ClearAllPoints()
        WFC.Frame.frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
    -- Arena HUD: clear saved point and physically move live frame
    TurtlePvPConfig.arenaFramePoint = "CENTER"
    TurtlePvPConfig.arenaFrameX     = 0
    TurtlePvPConfig.arenaFrameY     = 0
    if TurtlePvPArenaFrame then
        TurtlePvPArenaFrame:ClearAllPoints()
        TurtlePvPArenaFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    elseif WFC.Arena and WFC.Arena.frame then
        WFC.Arena.frame:ClearAllPoints()
        WFC.Arena.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    -- EFC Reporter
    TurtlePvPConfig.efcFrameX = 400
    TurtlePvPConfig.efcFrameY = 300
    if TurtlePvPEFCFrame then
        TurtlePvPEFCFrame:ClearAllPoints()
        TurtlePvPEFCFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 400, -300)
    end
    -- Launcher button
    TurtlePvPConfig.btnX = nil
    TurtlePvPConfig.btnY = nil
    if btn then
        btn:ClearAllPoints()
        btn:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -250, -25)
    end
    WFC:Print("All window positions reset.")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Settings panel
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:BuildPanel()
    if panelBuilt then return end
    panelBuilt = true

    panel = CreateFrame("Frame", "TurtlePvPSettingsPanel", UIParent)
    panel:SetWidth(320)
    panel:SetHeight(350)
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

    -- Header
    local titleFs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFs:SetPoint("TOPLEFT", 12, -10)
    titleFs:SetText(TEAL .. "Turtle|rPvP  " .. GRAY .. "v3.2  " .. WHITE .. "by Adimo|r")

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetWidth(26); closeBtn:SetHeight(26)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    -- ── Tab strip ────────────────────────────────────────────────────────────
    MakeLine(panel, -30)

    local tabPages = {}
    local tabBtns  = {}
    local function SelectTab(idx)
        for i, pg in ipairs(tabPages) do
            if i == idx then pg:Show() else pg:Hide() end
        end
        for i, tb in ipairs(tabBtns) do
            if i == idx then tb:LockHighlight() else tb:UnlockHighlight() end
        end
    end

    for i, name in ipairs({ "Settings", "Credits" }) do
        local tb = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        tb:SetWidth(96); tb:SetHeight(20)
        tb:SetPoint("TOPLEFT", panel, "TOPLEFT", 8 + (i-1)*100, -35)
        tb:SetText(name)
        local idx = i
        tb:SetScript("OnClick", function() SelectTab(idx) end)
        table.insert(tabBtns, tb)
    end

    MakeLine(panel, -58)

    local function MakePage()
        local pg = CreateFrame("Frame", nil, panel)
        pg:SetPoint("TOPLEFT",     panel, "TOPLEFT",   0, -62)
        pg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
        pg:Hide()
        table.insert(tabPages, pg)
        return pg
    end

    -- ══════════════════════════════════════════════════════════════════════════
    -- TAB 1: Settings
    -- ══════════════════════════════════════════════════════════════════════════
    local sPage = MakePage()

    local function MakeHeader(parent, text, y)
        local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
        fs:SetText(GOLD .. text .. "|r")
    end

    local function AddCheck(parent, label, ix, y, getF, setF)
        local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        c:SetWidth(24); c:SetHeight(24)
        c:SetPoint("TOPLEFT", parent, "TOPLEFT", ix, y)
        local fs = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", c, "RIGHT", 4, 1)
        fs:SetText(WHITE .. label .. "|r")
        c.getF = getF
        c:SetScript("OnClick", function() setF(this:GetChecked() and true or false) end)
        table.insert(allChecks, c)
        return c
    end

    -- ── WSG ──────────────────────────────────────────────────────────────────
    MakeHeader(sPage, "WSG Flag Caller", -4)
    AddCheck(sPage, "Enable WSG Flag Caller Tracking",     16, -24,
        function() return TurtlePvPConfig.wsgEnabled end,
        function(v) TurtlePvPConfig.wsgEnabled = v; WFC:CheckZone(true) end)
    AddCheck(sPage, "Enemy HP Callouts in /bg chat",       32, -48,
        function() return TurtlePvPConfig.hpCallouts end,
        function(v) TurtlePvPConfig.hpCallouts = v end)
    AddCheck(sPage, "Show Flag Tracker HUD",               32, -72,
        function() return TurtlePvPConfig.showFrame end,
        function(v) TurtlePvPConfig.showFrame = v; if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end end)
    AddCheck(sPage, "Show EFC Map in Warsong Gulch",       32, -96,
        function() return TurtlePvPConfig.efcEnabled end,
        function(v)
            TurtlePvPConfig.efcEnabled = v
            if not v and WFC.EFCReport and WFC.EFCReport.enabled then WFC.EFCReport:Hide() end
        end)

    local thresh = sPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    thresh:SetPoint("TOPLEFT", 44, -120)
    thresh:SetText(GRAY .. "HP callout thresholds: 75% / 50% / 25%|r")

    MakeLine(sPage, -134)

    -- ── Arena ─────────────────────────────────────────────────────────────────
    MakeHeader(sPage, "Arena Enemy HUD", -142)
    AddCheck(sPage, "Enable Arena Enemy Tracker HUD",      16, -162,
        function() return TurtlePvPConfig.arenaEnabled end,
        function(v) TurtlePvPConfig.arenaEnabled = v; WFC:CheckZone(true) end)
    AddCheck(sPage, "Show enemy distance (UnitXP)",        32, -186,
        function() return TurtlePvPConfig.arenaDistance end,
        function(v) TurtlePvPConfig.arenaDistance = v end)
    AddCheck(sPage, "Track trinkets / racials (Nampower)", 32, -210,
        function() return TurtlePvPConfig.arenaTrinkets end,
        function(v) TurtlePvPConfig.arenaTrinkets = v end)

    local arenaTip = sPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arenaTip:SetPoint("TOPLEFT", 44, -234)
    arenaTip:SetText(GRAY .. "Auto-activates in PvP Arena zones.|r")

    MakeLine(sPage, -248)

    -- ── Test / Preview buttons ────────────────────────────────────────────────
    local wsgActive   = false
    local arenaActive = false

    local wsgBtn = CreateFrame("Button", nil, sPage, "UIPanelButtonTemplate")
    wsgBtn:SetWidth(140); wsgBtn:SetHeight(22)
    wsgBtn:SetPoint("TOPLEFT", sPage, "TOPLEFT", 10, -258)
    wsgBtn:SetText("Test WSG HUD")
    wsgBtn:SetScript("OnClick", function()
        wsgActive = not wsgActive
        if wsgActive then
            WFC.inWSG        = true
            WFC.allyCarrier  = UnitName("player")
            WFC.hordeCarrier = "Thrall"
            if WFC.Frame    and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
            if WFC.EFCReport and WFC.EFCReport.Show        then WFC.EFCReport:Show() end
            wsgBtn:SetText("Hide WSG HUD")
        else
            WFC.inWSG        = false
            WFC.allyCarrier  = nil
            WFC.hordeCarrier = nil
            if WFC.Frame    and WFC.Frame.Disable  then WFC.Frame:Disable() end
            if WFC.EFCReport and WFC.EFCReport.Hide then WFC.EFCReport:Hide() end
            wsgBtn:SetText("Test WSG HUD")
        end
    end)

    local arenaBtn = CreateFrame("Button", nil, sPage, "UIPanelButtonTemplate")
    arenaBtn:SetWidth(140); arenaBtn:SetHeight(22)
    arenaBtn:SetPoint("TOPLEFT", sPage, "TOPLEFT", 160, -258)
    arenaBtn:SetText("Test Arena HUD")
    arenaBtn:SetScript("OnClick", function()
        arenaActive = not arenaActive
        if arenaActive then
            WFC.inArena = true
            if WFC.Tracker and WFC.Tracker.Enable then WFC.Tracker:Enable() end
            if WFC.Arena   and WFC.Arena.Enable   then WFC.Arena:Enable() end
            arenaBtn:SetText("Hide Arena HUD")
        else
            WFC.inArena = false
            if WFC.Arena and WFC.Arena.Disable then WFC.Arena:Disable() end
            arenaBtn:SetText("Test Arena HUD")
        end
    end)

    -- ── Bottom utility: reset button sits next to the Credits tab ──────────
    local rstBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    rstBtn:SetWidth(118); rstBtn:SetHeight(20)
    rstBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 210, -35)
    rstBtn:SetText("Reset Positions")
    rstBtn:SetScript("OnClick", function() WFC.Minimap:ResetAllPositions() end)

    -- ══════════════════════════════════════════════════════════════════════════
    -- TAB 2: Credits (scrollable changelog)
    -- ══════════════════════════════════════════════════════════════════════════
    local cPage = MakePage()

    -- Author block (static, above scroll)
    local function StaticLine(parent, text, y, font)
        local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
        fs:SetText(text)
        fs:SetJustifyH("LEFT")
    end

    StaticLine(cPage, GOLD .. "Author|r",                                    -4,  "GameFontNormal")
    StaticLine(cPage, WHITE .. "Adimo|r  " .. GRAY .. "@ Tel'abim|r",       -20)
    StaticLine(cPage, TEAL .. "github.com/DrOmida/WSGFlagCaller|r",         -34)

    StaticLine(cPage, GOLD .. "Contributors|r",                              -54, "GameFontNormal")
    StaticLine(cPage, GRAY .. "EFC concept: Cubenicke (Yrrol@vanillagaming)|r", -70)
    StaticLine(cPage, GRAY .. "Map icons: lanevegame|r",                    -84)
    StaticLine(cPage, GRAY .. "Arena frame concept: zetone / byCFM2|r",     -98)

    StaticLine(cPage, GOLD .. "Changelog|r",                                -118, "GameFontNormal")

    -- Scrollable changelog area (height capped so it never escapes the panel)
    local scrollH = 148
    local scrollFrame = CreateFrame("ScrollFrame", "TurtlePvPCreditsScroll", cPage, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(278)
    scrollFrame:SetHeight(scrollH)
    scrollFrame:SetPoint("TOPLEFT", cPage, "TOPLEFT", 8, -134)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(260)
    scrollFrame:SetScrollChild(content)

    local lineY = -4
    local function CLine(text)
        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, lineY)
        fs:SetWidth(256)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        lineY = lineY - 14
    end

    -- v3.2
    CLine(TEAL .. "v3.2  " .. GOLD .. "(2026-03-08)|r")
    CLine(WHITE .. "- Free-floating launcher btn (pfUI-safe)|r")
    CLine(WHITE .. "- Settings / Credits tab panel|r")
    CLine(WHITE .. "- Scrollable changelog|r")
    CLine(WHITE .. "- EFC auto-show now toggle-able|r")
    CLine(WHITE .. "- Separate Test WSG HUD / Test Arena HUD buttons|r")
    CLine(WHITE .. "- Reset All Positions now covers all 3 windows|r")
    CLine(WHITE .. "- Version bump to 3.2|r")
    CLine("")
    -- v3.1 (prior entries)
    CLine(TEAL .. "v3.1  " .. GOLD .. "(2026-03-04 – 2026-03-08)|r")
    CLine(WHITE .. "- Arena HUD: cast bars, trinket tracker,|r")
    CLine(GRAY  .. "  target indicator, dynamic HUD width|r")
    CLine(WHITE .. "- Pull timer: raid-leader check before /pull 15|r")
    CLine(WHITE .. "- WSG: zero-spam callout sync via AddonMessages|r")
    CLine(WHITE .. "- Adimo hardcoded as priority announcer|r")
    CLine(WHITE .. "- Curse of Tongues: silences local callouts|r")
    CLine(WHITE .. "- Flag scanner: tooltip verification|r")
    CLine(GRAY  .. "  (fixes Battle Standard false-positives)|r")
    CLine(WHITE .. "- Flag faction guard: flag only on enemy players|r")
    CLine(WHITE .. "- Horde compatibility verified|r")
    CLine(WHITE .. "- New commands: /tpvp test wsg, /tpvp force efc|r")
    CLine(WHITE .. "- README styled with tables, green Turtle title|r")

    content:SetHeight(math.abs(lineY) + 10)

    -- ── OnShow: sync checkboxes, start on Settings tab ───────────────────────
    panel:SetScript("OnShow", function()
        for _, c in ipairs(allChecks) do
            if c.getF then c:SetChecked(c.getF() and 1 or 0) end
        end
        SelectTab(1)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Free-floating launcher button  (parent = UIParent, pfUI-safe)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:BuildLauncherButton()
    btn = CreateFrame("Button", "TurtlePvPLauncherBtn", UIParent)
    btn:SetWidth(32)
    btn:SetHeight(32)
    btn:SetFrameStrata("HIGH")  -- HIGH so pfUI bars don't cover it
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function() this:StartMoving() end)
    btn:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        -- Save using GetLeft/GetTop — same approach as WIM
        TurtlePvPConfig.btnX = this:GetLeft()
        TurtlePvPConfig.btnY = this:GetTop() - GetScreenHeight()
    end)

    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bg:SetVertexColor(0.05, 0.05, 0.15, 0.9)

    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Ability_DualWield")
    icon:SetWidth(22); icon:SetHeight(22)
    icon:SetPoint("CENTER")

    -- Thin border
    local edge = btn:CreateTexture(nil, "OVERLAY")
    edge:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    edge:SetWidth(38); edge:SetHeight(38)
    edge:SetPoint("CENTER")

    -- Highlight
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Position: saved (BOTTOMLEFT offset = GetLeft, GetTop-screenH) or default center-top
    btn:ClearAllPoints()
    if TurtlePvPConfig.btnX and TurtlePvPConfig.btnY then
        btn:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
            TurtlePvPConfig.btnX, TurtlePvPConfig.btnY + GetScreenHeight())
    else
        btn:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -250, -25)
    end
    -- Raise above pfUI frames
    btn:Raise()

    -- Tooltip
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText(TEAL .. "Turtle|rPvP")
        GameTooltip:AddLine("Left-click: Settings",  1,1,1)
        GameTooltip:AddLine("Right-click: Quick menu", 0.8,0.8,0.8)
        GameTooltip:AddLine("Drag: Move button",     0.6,0.6,0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Clicks
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetScript("OnClick", function()
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
-- VARIABLES_LOADED: all frames safe to create here
-- ─────────────────────────────────────────────────────────────────────────────
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    if not TurtlePvPConfig then TurtlePvPConfig = {} end
    WFC.Minimap:BuildQuickMenu()
    WFC.Minimap:BuildLauncherButton()
end)
