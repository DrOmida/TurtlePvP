--[[
TurtlePvP_Minimap.lua
Minimap button, tabbed settings panel, and custom right-click context menu.
Completely rewritten for Vanilla 1.12 compatibility!
--]]

WFC.Minimap = {}

-- ========================
-- Panel style constants
-- ========================
local PANEL_W, PANEL_H = 310, 240
local DARK_BG = { 0, 0, 0, 0.88 }
local BORDER_COLOR = { 0.4, 0.4, 0.4, 1 }
local GOLD = "|cffffd700"

-- ========================
-- Minimap Button
-- ========================
local mmButton = CreateFrame("Button", "TurtlePvPMinimapButton", Minimap)
mmButton:SetWidth(31)
mmButton:SetHeight(31)
mmButton:SetFrameStrata("MEDIUM")
mmButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local mmBg = mmButton:CreateTexture(nil, "BACKGROUND")
mmBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
mmBg:SetWidth(22)
mmBg:SetHeight(22)
mmBg:SetPoint("CENTER")
mmBg:SetVertexColor(0.65, 0.07, 0.07, 1)

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

mmButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:SetText(GOLD.."TurtlePvP|r")
    GameTooltip:AddLine("Left-click to open settings", 1, 1, 1)
    GameTooltip:AddLine("Right-click for quick options", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
mmButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Initial position update happens later in VARIABLES_LOADED

mmButton:RegisterForDrag("LeftButton")
mmButton:SetMovable(true)
mmButton:SetScript("OnDragStart", function() this.dragging = true end)
mmButton:SetScript("OnDragStop",  function() this.dragging = false end)

local dragF = CreateFrame("Frame")
dragF:SetScript("OnUpdate", function()
    if not mmButton.dragging then return end
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local s = mmButton:GetEffectiveScale()
    if not s or s == 0 then s = 1 end
    px, py = px/s, py/s
    if not TurtlePvPConfig then TurtlePvPConfig = {} end
    TurtlePvPConfig.minimapPos = math.deg(math.atan2(py - my, px - mx))
    WFC.Minimap:UpdateMinimapPos()
end)

function WFC.Minimap:UpdateMinimapPos()
    local pos = (TurtlePvPConfig and TurtlePvPConfig.minimapPos) or 45
    local angle = math.rad(pos)
    local r = 80
    mmButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle)*r, math.sin(angle)*r)
end

-- ========================
-- Custom Context Menu
-- ========================
-- Instead of UIDropDownMenu, we use a simple floating frame with buttons
local contextMenu = CreateFrame("Frame", "TurtlePvPContextMenu", UIParent)
contextMenu:SetWidth(180)
contextMenu:SetHeight(120)
contextMenu:SetFrameStrata("TOOLTIP")
contextMenu:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
contextMenu:SetBackdropColor(0, 0, 0, 1)
contextMenu:Hide()

local menuItems = {
    { text = GOLD.."TurtlePvP Options|r", isTitle = true },
    { text = "Toggle WSG Caller", func = function()
        TurtlePvPConfig.wsgEnabled = not TurtlePvPConfig.wsgEnabled
        WFC:CheckZone(true)
        WFC:Print("WSG Caller " .. (TurtlePvPConfig.wsgEnabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
    end },
    { text = "Toggle Arena HUD", func = function()
        TurtlePvPConfig.arenaEnabled = not TurtlePvPConfig.arenaEnabled
        WFC:CheckZone(true)
        WFC:Print("Arena HUD " .. (TurtlePvPConfig.arenaEnabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
    end },
    { text = "Reset Frame Positions", func = function()
        TurtlePvPConfig.framePoint = "TOP"
        TurtlePvPConfig.frameX = 0
        TurtlePvPConfig.frameY = -150
        TurtlePvPConfig.arenaFramePoint = "CENTER"
        TurtlePvPConfig.arenaFrameX = 0
        TurtlePvPConfig.arenaFrameY = 0
        WFC:Print("Frame positions reset.")
    end },
    { text = "Open Settings Panel", func = function() WFC.Minimap:TogglePanel() end },
    { text = "Close Menu", func = function() end }
}

contextMenu.buttons = {}
local btnY = -8
for i, item in ipairs(menuItems) do
    local b = CreateFrame("Button", nil, contextMenu)
    b:SetWidth(160)
    b:SetHeight(16)
    b:SetPoint("TOP", 0, btnY)
    
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("LEFT", 4, 0)
    if item.isTitle then
        t:SetText(item.text)
    else
        t:SetText("|cffffffff" .. item.text .. "|r")
        b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        b:SetScript("OnClick", function()
            if item.func then item.func() end
            contextMenu:Hide()
        end)
    end
    btnY = btnY - 18
    table.insert(contextMenu.buttons, b)
end
contextMenu:SetHeight(math.abs(btnY) + 8)

-- Auto-hide context menu when you click outside it
local function ProcessClickOutside()
    if contextMenu:IsVisible() and not MouseIsOver(contextMenu) and not MouseIsOver(mmButton) then
        contextMenu:Hide()
    end
end
-- Easiest way in 1.12 to hide a custom floating menu when clicking away
local worldClickSync = CreateFrame("Frame")
worldClickSync:SetScript("OnUpdate", function()
    if contextMenu:IsVisible() and IsMouseButtonDown("LeftButton") then
        ProcessClickOutside()
    end
end)

mmButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mmButton:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        contextMenu:Hide()
        WFC.Minimap:TogglePanel()
    else
        if contextMenu:IsVisible() then
            contextMenu:Hide()
        else
            -- Show context menu next to mouse
            local x, y = GetCursorPosition()
            local s = UIParent:GetEffectiveScale()
            x, y = x/s, y/s
            contextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
            contextMenu:Show()
        end
    end
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
    cb:SetWidth(24)
    cb:SetHeight(24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    local txt = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    txt:SetText("|cffffffff" .. label .. "|r")
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

local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 14, -12)
titleText:SetText(GOLD.."TurtlePvP|r Settings")

local verText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
verText:SetPoint("TOPRIGHT", -36, -14)
verText:SetText("|cff888888v3.1|r")

local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetWidth(24)
closeBtn:SetHeight(24)
closeBtn:SetPoint("TOPRIGHT", -4, -4)

local divider = panel:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
divider:SetHeight(1)
divider:SetPoint("TOPLEFT", 8, -32)
divider:SetPoint("TOPRIGHT", -8, -32)
divider:SetVertexColor(0.4, 0.4, 0.4, 0.8)

-- ========================
-- Tab Logic using Standard Panel Buttons
-- ========================
local tabs = {}
local tabPages = {}

local function SelectTab(idx)
    for i, t in ipairs(tabs) do
        if i == idx then
            t:LockHighlight()
            if tabPages[i] then tabPages[i]:Show() end
        else
            t:UnlockHighlight()
            if tabPages[i] then tabPages[i]:Hide() end
        end
    end
end

local TAB_LABELS = { "WSG Caller", "Arena HUD", "EFC Report" }
local tabStart = 12
for i, label in ipairs(TAB_LABELS) do
    local tb = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    tb:SetHeight(22)
    tb:SetWidth(86)
    tb:SetPoint("TOPLEFT", panel, "TOPLEFT", tabStart + (i-1)*90, -40)
    tb:SetText(label)
    local idx = i
    tb:SetScript("OnClick", function() SelectTab(idx) end)
    table.insert(tabs, tb)
end

local tabDiv = panel:CreateTexture(nil, "ARTWORK")
tabDiv:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
tabDiv:SetHeight(1)
tabDiv:SetPoint("TOPLEFT", 10, -66)
tabDiv:SetPoint("TOPRIGHT", -10, -66)
tabDiv:SetVertexColor(0.35, 0.35, 0.35, 1)

-- ========================
-- TAB 1: WSG Caller
-- ========================
local wsgPage = CreateFrame("Frame", nil, panel)
wsgPage:SetPoint("TOPLEFT", 10, -70)
wsgPage:SetPoint("BOTTOMRIGHT", -10, 10)
wsgPage:Hide()
table.insert(tabPages, wsgPage)

local chkWSG = MakeCheck(wsgPage, "Enable WSG Flag Caller Tracking", 4, -4, function()
    TurtlePvPConfig.wsgEnabled = this:GetChecked() and true or false
    WFC:CheckZone(true)
end)

local chkHP = MakeCheck(wsgPage, "Enemy Phase HP Callouts in /bg", 20, -32, function()
    TurtlePvPConfig.hpCallouts = this:GetChecked() and true or false
end)

local chkFrame = MakeCheck(wsgPage, "Show Flag Tracking HUD", 20, -60, function()
    TurtlePvPConfig.showFrame = this:GetChecked() and true or false
    if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
end)

local threshLabel = wsgPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
threshLabel:SetPoint("TOPLEFT", 28, -88)
threshLabel:SetText("|cffaaaaaa HP Thresholds:|r 75% / 50% / 25%")

-- ========================
-- TAB 2: Arena HUD
-- ========================
local arenaPage = CreateFrame("Frame", nil, panel)
arenaPage:SetPoint("TOPLEFT", 10, -70)
arenaPage:SetPoint("BOTTOMRIGHT", -10, 10)
arenaPage:Hide()
table.insert(tabPages, arenaPage)

local chkArena = MakeCheck(arenaPage, "Enable Arena Enemy Tracker HUD", 4, -4, function()
    TurtlePvPConfig.arenaEnabled = this:GetChecked() and true or false
    WFC:CheckZone(true)
end)

local chkDist = MakeCheck(arenaPage, "Engine: Show HUD Distance (UnitXP)", 20, -32, function()
    TurtlePvPConfig.arenaDistance = this:GetChecked() and true or false
end)

local chkTrinkets = MakeCheck(arenaPage, "Engine: Track Trinkets/Racials (Nampower)", 20, -60, function()
    TurtlePvPConfig.arenaTrinkets = this:GetChecked() and true or false
end)

local arenaNote = arenaPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
arenaNote:SetPoint("TOPLEFT", 26, -92)
arenaNote:SetText("|cffaaaaaaAuto-activates in PvP Arena zones.\nTest anywhere via:  /tpvp force arena|r")

-- ========================
-- TAB 3: EFC Report (Populated by EFCReport module)
-- ========================
local efcPage = CreateFrame("Frame", nil, panel)
efcPage:SetPoint("TOPLEFT", 10, -70)
efcPage:SetPoint("BOTTOMRIGHT", -10, 10)
efcPage:Hide()
table.insert(tabPages, efcPage)

local efcNote = efcPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
efcNote:SetPoint("TOPLEFT", 4, -8)
efcNote:SetText(GOLD.."EFC Map Reporter Panel|r\n|cffaaaaaaOnly functions inside Warsong Gulch.\nClick a location button to announce the Enemy\nFlag Carrier's position to your team in /bg.|r")

local efcOpenBtn = CreateFrame("Button", nil, efcPage, "UIPanelButtonTemplate")
efcOpenBtn:SetWidth(140)
efcOpenBtn:SetHeight(24)
efcOpenBtn:SetPoint("TOPLEFT", 4, -80)
efcOpenBtn:SetText("Toggle Map Window")
efcOpenBtn:SetScript("OnClick", function()
    if WFC.EFCReport and WFC.EFCReport.Toggle then
        WFC.EFCReport:Toggle()
    end
end)

WFC.Minimap.efcPage = efcPage

-- ========================
-- Event Handlers
-- ========================
panel:SetScript("OnShow", function()
    if not TurtlePvPConfig then return end
    chkWSG:SetChecked(TurtlePvPConfig.wsgEnabled)
    chkHP:SetChecked(TurtlePvPConfig.hpCallouts)
    chkFrame:SetChecked(TurtlePvPConfig.showFrame)
    chkArena:SetChecked(TurtlePvPConfig.arenaEnabled)
    chkDist:SetChecked(TurtlePvPConfig.arenaDistance)
    chkTrinkets:SetChecked(TurtlePvPConfig.arenaTrinkets)
    -- Initialize to first tab if none selected visually yet
    SelectTab(1)
end)

function WFC.Minimap:TogglePanel()
    if panel:IsVisible() then 
        panel:Hide() 
    else 
        panel:Show() 
    end
end

-- Safely trigger setup logic only once variables are fully loaded
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("VARIABLES_LOADED")
loadFrame:SetScript("OnEvent", function()
    if not TurtlePvPConfig then TurtlePvPConfig = {} end
    WFC.Minimap:UpdateMinimapPos()
end)
