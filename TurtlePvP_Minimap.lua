--[[
TurtlePvP_Minimap.lua
Minimap button + tabbed settings panel for TurtlePvP
Styled after TurtleHonorSpyEnhanced overlay.lua (dark tooltip backdrop, gold title)
--]]

WFC.Minimap = {}

-- ========================
-- Panel style constants
-- ========================
local PANEL_W, PANEL_H = 310, 220
local DARK_BG = { 0, 0, 0, 0.88 }
local BORDER_COLOR = { 0.4, 0.4, 0.4, 1 }
local GOLD = "|cffffd700"
local TAB_ACTIVE_COLOR = { 1, 0.82, 0, 1 }    -- gold
local TAB_INACTIVE_COLOR = { 0.6, 0.6, 0.6, 1 } -- grey

-- ========================
-- Minimap Button
-- ========================
local mmButton = CreateFrame("Button", "TurtlePvPMinimapButton", Minimap)
mmButton:SetWidth(31)
mmButton:SetHeight(31)
mmButton:SetFrameStrata("MEDIUM")
mmButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Red circle backdrop
local mmBg = mmButton:CreateTexture(nil, "BACKGROUND")
mmBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
mmBg:SetWidth(22)
mmBg:SetHeight(22)
mmBg:SetPoint("CENTER")
mmBg:SetVertexColor(0.65, 0.07, 0.07, 1)

-- Swords icon on top
local mmIcon = mmButton:CreateTexture(nil, "ARTWORK")
mmIcon:SetTexture("Interface\\Icons\\Ability_DualWield")
mmIcon:SetWidth(20)
mmIcon:SetHeight(20)
mmIcon:SetPoint("CENTER")

-- Circular border
local mmBorder = mmButton:CreateTexture(nil, "OVERLAY")
mmBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mmBorder:SetWidth(53)
mmBorder:SetHeight(53)
mmBorder:SetPoint("CENTER")

-- Tooltip
mmButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText(GOLD.."TurtlePvP|r")
    GameTooltip:AddLine("Left-click to open settings", 1, 1, 1)
    GameTooltip:AddLine("Right-click for quick options", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
mmButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Right-click context menu
local menuItems = {
    { text = GOLD.."TurtlePvP|r",                notCheckable = 1, isTitle = 1 },
    { text = "Toggle WSG Caller",     notCheckable = 1,
        func = function()
            TurtlePvPConfig.wsgEnabled = not TurtlePvPConfig.wsgEnabled
            WFC:CheckZone(true)
            WFC:Print("WSG Caller " .. (TurtlePvPConfig.wsgEnabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
        end },
    { text = "Toggle Arena HUD",      notCheckable = 1,
        func = function()
            TurtlePvPConfig.arenaEnabled = not TurtlePvPConfig.arenaEnabled
            WFC:CheckZone(true)
            WFC:Print("Arena HUD " .. (TurtlePvPConfig.arenaEnabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
        end },
    { text = "Reset Frame Positions", notCheckable = 1,
        func = function()
            TurtlePvPConfig.framePoint = "TOP"
            TurtlePvPConfig.frameX = 0
            TurtlePvPConfig.frameY = -150
            TurtlePvPConfig.arenaFramePoint = "CENTER"
            TurtlePvPConfig.arenaFrameX = 0
            TurtlePvPConfig.arenaFrameY = 0
            WFC:Print("Frame positions reset.")
        end },
    { text = "Open Settings",         notCheckable = 1,
        func = function() WFC.Minimap:TogglePanel() end },
}
local contextMenu = CreateFrame("Frame", "TurtlePvPContextMenu", UIParent, "UIDropDownMenuTemplate")
local menuInitialized = false
local function ShowContextMenu()
    if not menuInitialized then
        UIDropDownMenu_Initialize(contextMenu, function()
            for _, item in ipairs(menuItems) do
                local info = {}
                info.text = item.text
                info.notCheckable = item.notCheckable
                info.isTitle = item.isTitle
                info.func = item.func
                UIDropDownMenu_AddButton(info)
            end
        end, "MENU")
        menuInitialized = true
    end
    ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 0)
end

mmButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmButton:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        WFC.Minimap:TogglePanel()
    else
        ShowContextMenu()
    end
end)

-- Draggable position around minimap
local function UpdateMinimapPos()
    local pos = (TurtlePvPConfig and TurtlePvPConfig.minimapPos) or 45
    local angle = math.rad(pos)
    local r = 80
    mmButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle)*r, math.sin(angle)*r)
end
UpdateMinimapPos()

mmButton:RegisterForDrag("LeftButton")
mmButton:SetMovable(true)
mmButton:SetScript("OnDragStart", function() this.dragging = true end)
mmButton:SetScript("OnDragStop",  function() this.dragging = false end)

local dragF = CreateFrame("Frame")
dragF:SetScript("OnUpdate", function()
    if not mmButton.dragging then return end
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    if not s or s == 0 then s = 1 end
    px, py = px/s, py/s
    if not TurtlePvPConfig then TurtlePvPConfig = {} end
    TurtlePvPConfig.minimapPos = math.deg(math.atan2(py - my, px - mx))
    UpdateMinimapPos()
end)

-- ========================
-- Helper: Create styled backdrop Frame
-- ========================
local function MakePanel(name, parent, w, h)
    local f = CreateFrame("Frame", name, parent)
    f:SetWidth(w)
    f:SetHeight(h)
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(DARK_BG[1], DARK_BG[2], DARK_BG[3], DARK_BG[4])
    f:SetBackdropBorderColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
    return f
end

-- ========================
-- Helper: Styled Checkbox
-- ========================
local function MakeCheck(parent, label, x, y, onClickFn)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(20)
    cb:SetHeight(20)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local txt = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    txt:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    txt:SetText(label)
    cb:SetScript("OnClick", onClickFn)
    return cb
end

-- ========================
-- Main Config Panel
-- ========================
local panel = MakePanel("TurtlePvPConfigPanel", UIParent, PANEL_W, PANEL_H)
panel:SetPoint("CENTER", 0, 50)
panel:SetFrameStrata("HIGH")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:SetClampedToScreen(true)
panel:RegisterForDrag("LeftButton")
panel:SetScript("OnDragStart", function() this:StartMoving() end)
panel:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
panel:Hide()

-- Gold title
local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 14, -10)
titleText:SetText(GOLD.."TurtlePvP|r Settings")

-- Version
local verText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
verText:SetPoint("TOPRIGHT", -36, -12)
verText:SetText("|cff888888v3.1|r")

-- Close button
local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetWidth(22)
closeBtn:SetHeight(22)
closeBtn:SetPoint("TOPRIGHT", -2, -2)

-- Divider line under title
local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
divider:SetHeight(1)
divider:SetPoint("TOPLEFT", 8, -28)
divider:SetPoint("TOPRIGHT", -8, -28)
divider:SetVertexColor(0.4, 0.4, 0.4, 0.8)

-- ========================
-- Tab buttons (custom styled)
-- ========================
local tabs = {}
local tabPages = {}
local function SelectTab(idx)
    for i, t in ipairs(tabs) do
        if i == idx then
            t:SetNormalFontObject(GameFontHighlight)
            local f = t:GetFontString()
            if f then f:SetTextColor(TAB_ACTIVE_COLOR[1], TAB_ACTIVE_COLOR[2], TAB_ACTIVE_COLOR[3]) end
            t.underline:Show()
            if tabPages[i] then tabPages[i]:Show() end
        else
            t:SetNormalFontObject(GameFontNormal)
            local f = t:GetFontString()
            if f then f:SetTextColor(TAB_INACTIVE_COLOR[1], TAB_INACTIVE_COLOR[2], TAB_INACTIVE_COLOR[3]) end
            t.underline:Hide()
            if tabPages[i] then tabPages[i]:Hide() end
        end
    end
end

local TAB_LABELS = { "WSG Caller", "Arena HUD", "EFC Report" }
local tabStart = 12
for i, label in ipairs(TAB_LABELS) do
    local tb = CreateFrame("Button", nil, panel)
    tb:SetHeight(18)
    tb:SetWidth(80)
    tb:SetPoint("TOPLEFT", panel, "TOPLEFT", tabStart + (i-1)*86, -32)
    local fs = tb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetAllPoints()
    fs:SetText(label)
    fs:SetJustifyH("CENTER")
    -- underline indicator
    local ul = tb:CreateTexture(nil, "ARTWORK")
    ul:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    ul:SetHeight(2)
    ul:SetPoint("BOTTOMLEFT", tb, "BOTTOMLEFT", 2, 0)
    ul:SetPoint("BOTTOMRIGHT", tb, "BOTTOMRIGHT", -2, 0)
    ul:SetVertexColor(TAB_ACTIVE_COLOR[1], TAB_ACTIVE_COLOR[2], TAB_ACTIVE_COLOR[3], 1)
    ul:Hide()
    tb.underline = ul
    local idx = i
    tb:SetScript("OnClick", function() SelectTab(idx) end)
    table.insert(tabs, tb)
end

-- Thin horizontal separator under tabs
local tabDiv = panel:CreateTexture(nil, "ARTWORK")
tabDiv:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
tabDiv:SetHeight(1)
tabDiv:SetPoint("TOPLEFT", 8, -52)
tabDiv:SetPoint("TOPRIGHT", -8, -52)
tabDiv:SetVertexColor(0.35, 0.35, 0.35, 1)

-- ========================
-- TAB 1: WSG Caller
-- ========================
local wsgPage = CreateFrame("Frame", nil, panel)
wsgPage:SetPoint("TOPLEFT", 8, -56)
wsgPage:SetPoint("BOTTOMRIGHT", -8, 8)
table.insert(tabPages, wsgPage)

local chkWSG = MakeCheck(wsgPage, "Enable WSG Flag Caller", 8, -8, function()
    TurtlePvPConfig.wsgEnabled = this:GetChecked()
    WFC:CheckZone(true)
end)

local chkHP = MakeCheck(wsgPage, "Enemy HP Callouts in /bg", 24, -36, function()
    TurtlePvPConfig.hpCallouts = this:GetChecked()
end)

local chkFrame = MakeCheck(wsgPage, "Show Flag Carrier HUD", 24, -60, function()
    TurtlePvPConfig.showFrame = this:GetChecked()
    if WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
end)

local threshLabel = wsgPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
threshLabel:SetPoint("TOPLEFT", 24, -88)
threshLabel:SetText("|cffaaaaaa HP Threshold callouts:|r  75 / 50 / 25 %")

-- ========================
-- TAB 2: Arena HUD
-- ========================
local arenaPage = CreateFrame("Frame", nil, panel)
arenaPage:SetPoint("TOPLEFT", 8, -56)
arenaPage:SetPoint("BOTTOMRIGHT", -8, 8)
table.insert(tabPages, arenaPage)

local chkArena = MakeCheck(arenaPage, "Enable Arena Enemy HUD", 8, -8, function()
    TurtlePvPConfig.arenaEnabled = this:GetChecked()
    WFC:CheckZone(true)
end)

local chkDist = MakeCheck(arenaPage, "Show Distance  (requires UnitXP)", 24, -36, function()
    TurtlePvPConfig.arenaDistance = this:GetChecked()
end)

local chkTrinkets = MakeCheck(arenaPage, "Track Trinkets / Racials  (requires Nampower)", 24, -60, function()
    TurtlePvPConfig.arenaTrinkets = this:GetChecked()
end)

local arenaNote = arenaPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
arenaNote:SetPoint("TOPLEFT", 24, -88)
arenaNote:SetText("|cff888888Auto-activates in TurtleWoW arena zones.\nUse /tpvp force arena to test.|r")

-- ========================
-- TAB 3: EFC Report (placeholder — populated by TurtlePvP_EFCReport.lua)
-- ========================
local efcPage = CreateFrame("Frame", nil, panel)
efcPage:SetPoint("TOPLEFT", 8, -56)
efcPage:SetPoint("BOTTOMRIGHT", -8, 8)
table.insert(tabPages, efcPage)

local efcNote = efcPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
efcNote:SetPoint("TOPLEFT", 8, -8)
efcNote:SetText(GOLD.."EFC Location Reporter|r\n|cffaaaaaaOnly active in Warsong Gulch.\nClick a location button to announce\nthe enemy flag carrier's position in /bg.|r")

local efcOpenBtn = CreateFrame("Button", nil, efcPage, "UIPanelButtonTemplate")
efcOpenBtn:SetWidth(130)
efcOpenBtn:SetHeight(22)
efcOpenBtn:SetPoint("TOPLEFT", 8, -80)
efcOpenBtn:SetText("Open EFC Panel")
efcOpenBtn:SetScript("OnClick", function()
    if WFC.EFCReport and WFC.EFCReport.Toggle then
        WFC.EFCReport:Toggle()
    end
end)

WFC.Minimap.efcPage = efcPage  -- let EFCReport module inject more controls here

-- ========================
-- Sync checkboxes on open
-- ========================
panel:SetScript("OnShow", function()
    chkWSG:SetChecked(TurtlePvPConfig.wsgEnabled)
    chkHP:SetChecked(TurtlePvPConfig.hpCallouts)
    chkFrame:SetChecked(TurtlePvPConfig.showFrame)
    chkArena:SetChecked(TurtlePvPConfig.arenaEnabled)
    chkDist:SetChecked(TurtlePvPConfig.arenaDistance)
    chkTrinkets:SetChecked(TurtlePvPConfig.arenaTrinkets)
    SelectTab(1)
end)

function WFC.Minimap:TogglePanel()
    if panel:IsVisible() then panel:Hide() else panel:Show() end
end
