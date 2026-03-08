--[[
TurtlePvP_Minimap.lua
Minimap button + settings panel.
Fully rewritten for robustness in Vanilla 1.12.
No template tabs/buttons that break silently.
Everything is deferred until VARIABLES_LOADED so SavedVars are ready.
--]]

WFC.Minimap = {}

local GOLD   = "|cffffd700"
local WHITE  = "|cffffffff"
local GRAY   = "|cffaaaaaa"
local GREEN  = "|cff00ff00"
local RED    = "|cffff0000"

-- ─────────────────────────────────────────────────────────────────────────────
-- Minimap Button
-- ─────────────────────────────────────────────────────────────────────────────
local mmButton = CreateFrame("Button", "TurtlePvPMinimapBtn", Minimap)
mmButton:SetWidth(31)
mmButton:SetHeight(31)
mmButton:SetFrameStrata("MEDIUM")
mmButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local mmBg = mmButton:CreateTexture(nil, "BACKGROUND")
mmBg:SetAllPoints(mmButton)
mmBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
mmBg:SetVertexColor(0.07, 0.07, 0.18, 1)

local mmIcon = mmButton:CreateTexture(nil, "ARTWORK")
mmIcon:SetTexture("Interface\\Icons\\Ability_DualWield")
mmIcon:SetWidth(20)
mmIcon:SetHeight(20)
mmIcon:SetPoint("CENTER")

local mmBorder = mmButton:CreateTexture(nil, "OVERLAY")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmBorder:SetWidth(53)
mmBorder:SetHeight(53)
mmBorder:SetPoint("CENTER")

function WFC.Minimap:UpdateMinimapPos()
    local pos   = (TurtlePvPConfig and TurtlePvPConfig.minimapPos) or 45
    local angle = math.rad(pos)
    local r     = 80
    mmButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

-- Drag the button around the minimap ring
mmButton:RegisterForDrag("LeftButton")
mmButton:SetMovable(true)
local dragging = false
mmButton:SetScript("OnDragStart", function() dragging = true end)
mmButton:SetScript("OnDragStop",  function() dragging = false end)

local dragF = CreateFrame("Frame")
dragF:SetScript("OnUpdate", function()
    if not dragging then return end
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local s = UIParent:GetEffectiveScale() or 1
    px, py = px / s, py / s
    if TurtlePvPConfig then
        TurtlePvPConfig.minimapPos = math.deg(math.atan2(py - my, px - mx))
    end
    WFC.Minimap:UpdateMinimapPos()
end)

mmButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText(GOLD .. "TurtlePvP|r")
    GameTooltip:AddLine("Left-click: Settings panel", 1,1,1)
    GameTooltip:AddLine("Right-click: Quick menu",   0.8,0.8,0.8)
    GameTooltip:Show()
end)
mmButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Quick Right-Click Menu  (tiny floating frame with plain buttons)
-- ─────────────────────────────────────────────────────────────────────────────
local qMenu = CreateFrame("Frame", "TurtlePvPQuickMenu", UIParent)
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

local function MakeMenuBtn(label, fn)
    local b = CreateFrame("Button", nil, qMenu)
    b:SetWidth(172)
    b:SetHeight(18)
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", 4, 0)
    fs:SetText(WHITE .. label .. "|r")
    b:SetScript("OnClick", function()
        qMenu:Hide()
        if fn then fn() end
    end)
    return b
end

local qMenuItems
local function BuildQuickMenu()
    qMenuItems = {
        MakeMenuBtn("Toggle WSG Caller", function()
            TurtlePvPConfig.wsgEnabled = not TurtlePvPConfig.wsgEnabled
            WFC:CheckZone(true)
            WFC:Print("WSG Caller " .. (TurtlePvPConfig.wsgEnabled and GREEN.."Enabled|r" or RED.."Disabled|r"))
        end),
        MakeMenuBtn("Toggle Arena HUD", function()
            TurtlePvPConfig.arenaEnabled = not TurtlePvPConfig.arenaEnabled
            WFC:CheckZone(true)
            WFC:Print("Arena HUD " .. (TurtlePvPConfig.arenaEnabled and GREEN.."Enabled|r" or RED.."Disabled|r"))
        end),
        MakeMenuBtn("Force WSG Window", function()
            WFC:CheckZone(true)
            WFC:Print("Force WSG enabled.")
        end),
        MakeMenuBtn("Toggle EFC Map", function()
            if WFC.EFCReport and WFC.EFCReport.Toggle then WFC.EFCReport:Toggle() end
        end),
        MakeMenuBtn("Reset Frame Positions", function()
            TurtlePvPConfig.framePoint    = "TOP"
            TurtlePvPConfig.frameX        = 0
            TurtlePvPConfig.frameY        = -150
            TurtlePvPConfig.arenaFramePoint = "CENTER"
            TurtlePvPConfig.arenaFrameX   = 0
            TurtlePvPConfig.arenaFrameY   = 0
            WFC:Print("Frame positions reset.")
        end),
        MakeMenuBtn("Open Settings", function()
            WFC.Minimap:TogglePanel()
        end),
    }
    -- layout items top-to-bottom
    local titleH = 22
    local btnH   = 18
    local pad     = 6
    -- title row
    local title = qMenu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -7)
    title:SetText(GOLD .. "TurtlePvP|r Options")
    local yOff = -(titleH)
    for _, b in ipairs(qMenuItems) do
        b:SetPoint("TOP", qMenu, "TOP", 0, yOff)
        yOff = yOff - btnH - 2
    end
    qMenu:SetHeight(math.abs(yOff) + pad)
end

-- Auto-hide when clicking outside
local qMenuHider = CreateFrame("Frame")
qMenuHider:SetScript("OnUpdate", function()
    if qMenu:IsVisible() and IsMouseButtonDown("LeftButton") then
        if not MouseIsOver(qMenu) and not MouseIsOver(mmButton) then
            qMenu:Hide()
        end
    end
end)

mmButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmButton:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        qMenu:Hide()
        WFC.Minimap:TogglePanel()
    else
        if qMenu:IsVisible() then
            qMenu:Hide()
        else
            local x, y = GetCursorPosition()
            local s = UIParent:GetEffectiveScale() or 1
            x, y = x / s, y / s
            qMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
            qMenu:Show()
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Settings Panel  (built entirely in Lua, deferred to VARIABLES_LOADED)
-- ─────────────────────────────────────────────────────────────────────────────
local panel -- forward reference
local panelBuilt = false

-- Checkbox helper
local function MakeCheck(parent, label, x, y, getVal, setVal)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(24)
    cb:SetHeight(24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    fs:SetText(WHITE .. label .. "|r")
    -- Sync check state from config on show
    cb.syncFn = function() cb:SetChecked(getVal() and 1 or 0) end
    cb:SetScript("OnClick", function()
        setVal(cb:GetChecked() and true or false)
    end)
    return cb
end

-- Section header helper
local function MakeHeader(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(GOLD .. text .. "|r")
    return fs
end

-- Thin separator line
local function MakeLine(parent, y)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  8, y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
    t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    t:SetVertexColor(0.3, 0.3, 0.3, 1)
    return t
end

local allChecks = {} -- collect for OnShow refresh

local function BuildPanel()
    if panelBuilt then return end
    panelBuilt = true

    -- ── Main frame ──
    panel = CreateFrame("Frame", "TurtlePvPSettingsPanel", UIParent)
    panel:SetWidth(300)
    panel:SetHeight(310)
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

    -- Version
    local ver = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ver:SetPoint("TOPRIGHT", -36, -12)
    ver:SetText(GRAY .. "v3.1|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetWidth(26)
    closeBtn:SetHeight(26)
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    MakeLine(panel, -30)

    -- ── WSG Caller section ──
    MakeHeader(panel, "🏴 WSG Flag Caller", 10, -38)

    local function addCheck(label, x, y, getF, setF)
        local c = MakeCheck(panel, label, x, y, getF, setF)
        table.insert(allChecks, c)
        return c
    end

    addCheck("Enable WSG Flag Caller Tracking",  16, -58,
        function() return TurtlePvPConfig.wsgEnabled end,
        function(v)
            TurtlePvPConfig.wsgEnabled = v
            WFC:CheckZone(true)
        end)

    addCheck("Enemy HP Callouts (/bg chat)",  32, -82,
        function() return TurtlePvPConfig.hpCallouts end,
        function(v) TurtlePvPConfig.hpCallouts = v end)

    addCheck("Show Flag Carrier HUD window",  32, -106,
        function() return TurtlePvPConfig.showFrame end,
        function(v)
            TurtlePvPConfig.showFrame = v
            if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
        end)

    local thresh = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    thresh:SetPoint("TOPLEFT", 44, -130)
    thresh:SetText(GRAY .. "HP callout thresholds: 75% / 50% / 25%|r")

    -- Force WSG button
    local forceWSG = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    forceWSG:SetWidth(130)
    forceWSG:SetHeight(20)
    forceWSG:SetPoint("TOPLEFT", 16, -150)
    forceWSG:SetText("Force WSG Window")
    forceWSG:SetScript("OnClick", function()
        WFC.inWSG = true
        WFC.allyCarrier = UnitName("player")
        WFC.hordeCarrier = "Thrall"
        if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
        if WFC.EFCReport and WFC.EFCReport.Show then WFC.EFCReport:Show() end
        WFC:Print("WSG window forced open with test data.")
    end)

    MakeLine(panel, -176)

    -- ── Arena HUD section ──
    MakeHeader(panel, "⚔️ Arena Enemy HUD", 10, -184)

    addCheck("Enable Arena Enemy HUD",       16, -204,
        function() return TurtlePvPConfig.arenaEnabled end,
        function(v)
            TurtlePvPConfig.arenaEnabled = v
            WFC:CheckZone(true)
        end)

    addCheck("Show enemy distance (UnitXP)", 32, -228,
        function() return TurtlePvPConfig.arenaDistance end,
        function(v) TurtlePvPConfig.arenaDistance = v end)

    addCheck("Track trinkets/racials (Nampower)", 32, -252,
        function() return TurtlePvPConfig.arenaTrinkets end,
        function(v) TurtlePvPConfig.arenaTrinkets = v end)

    local arenaTip = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arenaTip:SetPoint("TOPLEFT", 44, -275)
    arenaTip:SetText(GRAY .. "Auto-activates in PvP Arena zones.|r")

    -- ── Bottom: EFC / Reset ──
    MakeLine(panel, -288)

    local efcBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    efcBtn:SetWidth(100)
    efcBtn:SetHeight(20)
    efcBtn:SetPoint("BOTTOMLEFT", 10, 8)
    efcBtn:SetText("EFC Map")
    efcBtn:SetScript("OnClick", function()
        if WFC.EFCReport and WFC.EFCReport.Toggle then WFC.EFCReport:Toggle() end
    end)

    local rstBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    rstBtn:SetWidth(100)
    rstBtn:SetHeight(20)
    rstBtn:SetPoint("BOTTOMRIGHT", -10, 8)
    rstBtn:SetText("Reset Positions")
    rstBtn:SetScript("OnClick", function()
        TurtlePvPConfig.framePoint    = "TOP"
        TurtlePvPConfig.frameX        = 0
        TurtlePvPConfig.frameY        = -150
        TurtlePvPConfig.arenaFramePoint = "CENTER"
        TurtlePvPConfig.arenaFrameX   = 0
        TurtlePvPConfig.arenaFrameY   = 0
        WFC:Print("Frame positions reset.")
    end)

    -- Refresh all checkboxes every time the panel opens
    panel:SetScript("OnShow", function()
        for _, c in ipairs(allChecks) do
            if c.syncFn then c.syncFn() end
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.Minimap:TogglePanel()
    BuildPanel()
    if panel:IsVisible() then
        panel:Hide()
    else
        panel:Show()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Init on VARIABLES_LOADED (ensures SavedVars exist before doing anything)
-- ─────────────────────────────────────────────────────────────────────────────
local loadF = CreateFrame("Frame")
loadF:RegisterEvent("VARIABLES_LOADED")
loadF:SetScript("OnEvent", function()
    if not TurtlePvPConfig then TurtlePvPConfig = {} end
    WFC.Minimap:UpdateMinimapPos()
    BuildQuickMenu()
end)
