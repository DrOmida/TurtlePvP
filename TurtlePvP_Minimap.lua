--[[
TurtlePvP_Minimap.lua  v3.2
Minimap button parents to Minimap frame, uses LibDBIcon-style angle positioning.
All frame creation deferred to VARIABLES_LOADED / PLAYER_LOGIN.
TogglePanel / public API defined at parse-time so it is always available.
--]]

WFC.Minimap = {}

local GOLD  = "|cffffd700"
local WHITE = "|cffffffff"
local GRAY  = "|cffaaaaaa"
local TEAL  = "|cff55ee22"

-- Forward refs populated in Build* functions
local btn, panel
local panelBuilt = false
local allChecks  = {}

-- Angle-based minimap positioning (exactly as LibDBIcon-1.0 does it)
local function updateMinimapPos(button, angle)
    local rad = math.rad(angle or 225)
    local cos, sin = math.cos(rad), math.sin(rad)
    local w = (Minimap:GetWidth()  / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", cos * w, sin * h)
end

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
-- Shared: reset all frame positions
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:ResetAllPositions()
    -- WSG HUD (global frame name registered in TurtlePvP_Frame.lua is WSGFCHud)
    TurtlePvPConfig.framePoint = "TOP"
    TurtlePvPConfig.frameX     = 0
    TurtlePvPConfig.frameY     = -150
    local wsgHud = getglobal("WSGFCHud")
    if wsgHud then
        wsgHud:ClearAllPoints()
        wsgHud:SetPoint("TOP", UIParent, "TOP", 0, -150)
    end
    -- Arena HUD (local var; disable+re-enable repositions from saved config)
    TurtlePvPConfig.arenaFramePoint = "CENTER"
    TurtlePvPConfig.arenaFrameX     = 0
    TurtlePvPConfig.arenaFrameY     = 0
    if WFC.Arena and WFC.Arena.enabled then
        WFC.Arena:Disable()
        WFC.Arena:Enable()
    end
    -- EFC Reporter
    TurtlePvPConfig.efcFrameX = 400
    TurtlePvPConfig.efcFrameY = 300
    local efcF = getglobal("TurtlePvPEFCFrame")
    if efcF then
        efcF:ClearAllPoints()
        efcF:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 400, -300)
    end
    -- Minimap button: reset angle to default
    TurtlePvPConfig.minimapPos = 225
    if btn then updateMinimapPos(btn, 225) end
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
    panel:SetHeight(400)
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
    titleFs:SetText(TEAL .. "Turtle|rPvP  " .. GRAY .. "v3.2  " .. WHITE .. "by Adimo " .. GRAY .. "[Tel'abim]|r")

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
    thresh:SetPoint("TOPLEFT", 44, -118)
    thresh:SetText(GRAY .. "HP callout thresholds: 75% / 50% / 25%|r")

    MakeLine(sPage, -132)

    -- ── Arena ─────────────────────────────────────────────────────────────────
    MakeHeader(sPage, "Arena Enemy HUD", -156)
    AddCheck(sPage, "Enable Arena Enemy Tracker HUD",      16, -176,
        function() return TurtlePvPConfig.arenaEnabled end,
        function(v) TurtlePvPConfig.arenaEnabled = v; WFC:CheckZone(true) end)
    AddCheck(sPage, "Show enemy distance (UnitXP)",        32, -200,
        function() return TurtlePvPConfig.arenaDistance end,
        function(v) TurtlePvPConfig.arenaDistance = v end)
    AddCheck(sPage, "Track trinkets / racials (Nampower)", 32, -224,
        function() return TurtlePvPConfig.arenaTrinkets end,
        function(v) TurtlePvPConfig.arenaTrinkets = v end)

    local arenaTip = sPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arenaTip:SetPoint("TOPLEFT", 44, -248)
    arenaTip:SetText(GRAY .. "Auto-activates in PvP Arena zones.|r")

    MakeLine(sPage, -262)

    -- ── Test / Preview buttons ────────────────────────────────────────────────
    local lockTip = sPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lockTip:SetPoint("TOPLEFT", sPage, "TOPLEFT", 10, -268)
    lockTip:SetText(GRAY .. "▸ Right-click any HUD to lock / unlock it|r")

    local wsgActive   = false
    local arenaActive = false

    local wsgBtn = CreateFrame("Button", nil, sPage, "UIPanelButtonTemplate")
    wsgBtn:SetWidth(140); wsgBtn:SetHeight(22)
    wsgBtn:SetPoint("TOPLEFT", sPage, "TOPLEFT", 10, -282)
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
    arenaBtn:SetPoint("TOPLEFT", sPage, "TOPLEFT", 160, -282)
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

    -- Reset button: sits next to the Credits tab (100px wide, fits inside 320px panel)
    local rstBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    rstBtn:SetWidth(100); rstBtn:SetHeight(20)
    rstBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 212, -35)
    rstBtn:SetText("Reset Positions")
    rstBtn:SetScript("OnClick", function() WFC.Minimap:ResetAllPositions() end)

    -- ══════════════════════════════════════════════════════════════════════════
    -- TAB 2: Credits (scrollable changelog)
    -- ══════════════════════════════════════════════════════════════════════════
    local cPage = MakePage()

    -- Author block (static, above scroll)
    local function AddLine(parent, text, y, font)
        local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
        fs:SetText(text)
        fs:SetJustifyH("LEFT")
    end

    AddLine(cPage, GOLD .. "Author|r",                                    -4,  "GameFontNormal")
    AddLine(cPage, WHITE .. "Adimo|r  " .. GRAY .. "@ Tel'abim|r",       -20)

    -- Copyable GitHub URL via EditBox (click to focus, Ctrl+A to select all)
    local urlBox = CreateFrame("EditBox", nil, cPage)
    urlBox:SetWidth(286)
    urlBox:SetHeight(16)
    urlBox:SetPoint("TOPLEFT", cPage, "TOPLEFT", 10, -36)
    urlBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
    urlBox:SetTextColor(0.33, 0.93, 0.53, 1)
    urlBox:SetText("github.com/DrOmida/TurtlePvP")
    urlBox:SetAutoFocus(false)
    urlBox:SetMultiLine(false)
    urlBox:EnableMouse(true)
    urlBox:SetBackdrop(nil)
    urlBox:SetScript("OnEditFocusGained", function() this:HighlightText() end)
    urlBox:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click, then Ctrl+A to select & copy", 1,1,1)
        GameTooltip:Show()
    end)
    urlBox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    AddLine(cPage, GOLD .. "Contributors|r",                              -58, "GameFontNormal")
    AddLine(cPage, GRAY .. "EFC concept: Cubenicke (Yrrol@vanillagaming)|r", -74)
    AddLine(cPage, GRAY .. "Map icons: lanevegame|r",                    -88)
    AddLine(cPage, GRAY .. "Arena frame concept: zetone / byCFM2|r",     -102)

    AddLine(cPage, GOLD .. "Changelog|r",                                -122, "GameFontNormal")

    -- Scrollable changelog (height capped so it never overflows the panel bottom)
    local scrollH = 140
    local scrollFrame = CreateFrame("ScrollFrame", "TurtlePvPCreditsScroll", cPage, "UIPanelScrollFrameTemplate")
    scrollFrame:SetWidth(278)
    scrollFrame:SetHeight(scrollH)
    scrollFrame:SetPoint("TOPLEFT", cPage, "TOPLEFT", 8, -138)

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
    CLine(WHITE .. "- Minimap button: LibDBIcon-style angle math,|r")
    CLine(GRAY  .. "  parents to Minimap, shows on PLAYER_LOGIN|r")
    CLine(WHITE .. "- Faction-aware icon (Alliance/Horde banner)|r")
    CLine(WHITE .. "- Both clicks open Settings panel|r")
    CLine(WHITE .. "- EFC map: HP bar removed, pure callout grid|r")
    CLine(WHITE .. "- EFC map: right-click to lock/unlock position|r")
    CLine(WHITE .. "- Settings / Credits tabbed panel|r")
    CLine(WHITE .. "- Scrollable changelog|r")
    CLine(WHITE .. "- EFC auto-show now toggle-able|r")
    CLine(WHITE .. "- Lock/unlock info line above test buttons|r")
    CLine(WHITE .. "- Separate Test WSG HUD / Test Arena HUD buttons|r")
    CLine(WHITE .. "- Reset All Positions covers all 3 windows|r")
    CLine(WHITE .. "- GitHub URL copyable in Credits tab|r")
    CLine(WHITE .. "- Version 3.2.0|r")
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
-- Minimap launcher button  (parent = Minimap, LibDBIcon-style angle math)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:BuildLauncherButton()
    btn = CreateFrame("Button", "TurtlePvPMinimapBtn", Minimap)
    btn:SetWidth(31)
    btn:SetHeight(31)
    btn:SetFrameStrata("HIGH")
    btn:SetFrameLevel(7)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- TrackingBorder round ring overlay (same as LibDBIcon)
    local overlay = btn:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53); overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", 0, 0)

    -- Circular background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetWidth(20); bg:SetHeight(20)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", 7, -5)

    -- Addon icon: faction-aware PvP banner
    -- INV_BannerPVP_01 = Horde (red), INV_BannerPVP_02 = Alliance (blue)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(17); icon:SetHeight(17)
    local iconTex
    if UnitFactionGroup and UnitFactionGroup("player") == "Horde" then
        iconTex = "Interface\\Icons\\INV_BannerPVP_01"
    else
        iconTex = "Interface\\Icons\\INV_BannerPVP_02"
    end
    icon:SetTexture(iconTex)
    icon:SetPoint("TOPLEFT", 7, -6)

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Drag: track mouse angle around Minimap center (same as LibDBIcon onUpdate)
    btn:SetScript("OnDragStart", function()
        this:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale  = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale
            local angle = math.deg(math.atan2(py - my, px - mx))
            -- Keep angle in [0, 360)
            angle = angle - math.floor(angle / 360) * 360
            TurtlePvPConfig.minimapPos = angle
            updateMinimapPos(this, angle)
        end)
    end)
    btn:SetScript("OnDragStop", function()
        this:SetScript("OnUpdate", nil)
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText(TEAL .. "Turtle|rPvP")
        GameTooltip:AddLine("Click: Open Settings", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move button",    0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Both left and right click open the settings panel
    btn:SetScript("OnClick", function()
        WFC.Minimap:TogglePanel()
    end)

    -- Hidden until PLAYER_LOGIN (pfUI and MinimapShape addons are loaded by then)
    btn:Hide()

    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function()
        updateMinimapPos(btn, TurtlePvPConfig.minimapPos or 225)
        btn:Show()
        this:SetScript("OnEvent", nil)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- VARIABLES_LOADED: all frames safe to create here
-- ─────────────────────────────────────────────────────────────────────────────
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    if not TurtlePvPConfig then TurtlePvPConfig = {} end
    WFC.Minimap:BuildLauncherButton()
end)
