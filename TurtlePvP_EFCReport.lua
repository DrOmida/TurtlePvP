--[[
TurtlePvP_EFCReport.lua
EFC Location Reporter — WSG only
Adapted from EFCReport by Cubenicke (Yrrol@vanillagaming)
Integrated into TurtlePvP with Nampower HP bar & restyled frame.
Icons bundled from EFCReport/Icons/*.blp — original artwork by lanevegame.
--]]

WFC.EFCReport = {
    enabled = false,
    created = false,
}

local iconPath = "Interface\\AddOns\\TurtlePvP\\Icons\\"

-- 23 WSG location buttons (original EFCReport layout, index [1]=Alliance, [2]=Horde)
local BUTTONS = {
    { x={2,2},   y={-2,-2},   w=32, h=32, tex="repic28.tga", text="Get ready to repick!" },
    { x={34,34}, y={-2,-194}, w=64, h=32, tex="aroof.blp",   text="EFC Alliance roof!" },
    { x={98,98}, y={-2,-2},   w=32, h=32, tex="cap28.tga",   text="Get ready to cap!" },
    { x={2,98},  y={-34,-162},w=32, h=32, tex="agy.blp",     text="EFC Alliance graveyard!" },
    { x={34,66}, y={-34,-162},w=32, h=32, tex="afr.blp",     text="EFC Alliance flag room!" },
    { x={66,34}, y={-34,-162},w=32, h=32, tex="abalc.blp",   text="EFC Alliance balcony!" },
    { x={98,2},  y={-34,-162},w=32, h=32, tex="aramp.blp",   text="EFC Alliance ramp!" },
    { x={2,98},  y={-66,-130},w=32, h=32, tex="aresto.blp",  text="EFC Alliance resto hut!" },
    { x={34,66}, y={-66,-130},w=32, h=32, tex="afence.blp",  text="EFC Alliance fence!" },
    { x={66,34}, y={-66,-130},w=32, h=32, tex="atun.blp",    text="EFC Alliance tunnel!" },
    { x={98,2},  y={-66,-130},w=32, h=32, tex="azerk.blp",   text="EFC Alliance zerker hut!" },
    { x={18,18}, y={-98,-98}, w=32, h=32, tex="west.blp",    text="EFC west!" },
    { x={50,50}, y={-98,-98}, w=32, h=32, tex="mid.blp",     text="EFC midfield!" },
    { x={82,82}, y={-98,-98}, w=32, h=32, tex="east.blp",    text="EFC east!" },
    { x={2,98},  y={-130,-66},w=32, h=32, tex="hzerk.blp",   text="EFC Horde zerker hut!" },
    { x={34,66}, y={-130,-66},w=32, h=32, tex="htun.blp",    text="EFC Horde tunnel!" },
    { x={66,34}, y={-130,-66},w=32, h=32, tex="hfence.blp",  text="EFC Horde fence!" },
    { x={98,2},  y={-130,-66},w=32, h=32, tex="hresto.blp",  text="EFC Horde resto hut!" },
    { x={2,98},  y={-162,-34},w=32, h=32, tex="hramp.blp",   text="EFC Horde ramp!" },
    { x={34,66}, y={-162,-34},w=32, h=32, tex="hbalc.blp",   text="EFC Horde balcony!" },
    { x={66,34}, y={-162,-34},w=32, h=32, tex="hfr.blp",     text="EFC Horde flag room!" },
    { x={98,2},  y={-162,-34},w=32, h=32, tex="hgy.blp",     text="EFC Horde graveyard!" },
    { x={34,34}, y={-194,-2}, w=64, h=32, tex="hroof.blp",   text="EFC Horde roof!" },
}

-- Saved position in TurtlePvPConfig.efcFrameX/Y
if not TurtlePvPConfig then TurtlePvPConfig = {} end

local function GetLanguage()
    local f = UnitFactionGroup("player")
    return (f == "Horde") and "Orcish" or "Common"
end

local function GetFactionIdx()
    return (UnitFactionGroup("player") == "Horde") and 2 or 1
end

function WFC.EFCReport:Create()
    if self.created then return end
    self.created = true

    local fx = TurtlePvPConfig.efcFrameX or 400
    local fy = TurtlePvPConfig.efcFrameY or 300
    local ix = GetFactionIdx()

    local frame = CreateFrame("Frame", "TurtlePvPEFCFrame", UIParent)
    frame:SetWidth(132)
    frame:SetHeight(228 + 22)   -- extra 22px for HP bar at top
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", fx, -fy)
    frame:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.88)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)

    -- Drag save
    frame:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then this:StartMoving() end
    end)
    frame:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then
            this:StopMovingOrSizing()
            local _, _, _, x, y = this:GetPoint()
            TurtlePvPConfig.efcFrameX = x
            TurtlePvPConfig.efcFrameY = -y
        end
    end)

    -- EFC HP bar at top (Nampower-powered) ─────────────────────────────────
    local barLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    barLabel:SetPoint("TOPLEFT", 4, -4)
    barLabel:SetText("|cffffff00EFC HP|r")

    local hpBar = CreateFrame("StatusBar", nil, frame)
    hpBar:SetWidth(118)
    hpBar:SetHeight(12)
    hpBar:SetPoint("TOPLEFT", 4, -16)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0, 0.85, 0)
    hpBar:SetMinMaxValues(0, 100)
    hpBar:SetValue(100)
    hpBar.bg = hpBar:CreateTexture(nil, "BACKGROUND")
    hpBar.bg:SetAllPoints()
    hpBar.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    hpBar.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    frame.hpBar = hpBar
    frame.barLabel = barLabel

    -- EFC HP ticker
    local ticker = CreateFrame("Frame")
    ticker:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed < 0.5 then return end
        this.elapsed = 0

        -- Figure out which carrier is the enemy FC
        local myFaction = UnitFactionGroup("player")
        local efcName = nil
        -- If I am Alliance, the enemy FC is holding the Alliance flag (WFC.allyCarrier)
        if myFaction == "Alliance" then
            efcName = WFC.allyCarrier
        else
            efcName = WFC.hordeCarrier
        end

        if not efcName then
            frame.hpBar:SetValue(0)
            frame.hpBar:SetStatusBarColor(0.4, 0.4, 0.4)
            frame.barLabel:SetText("|cff888888EFC: none|r")
            return
        end

        local hp, hpMax = nil, nil
        local guid = WFC.Tracker and WFC.Tracker:GetGUID(efcName) or nil
        if guid and GetUnitField then
            hp = GetUnitField(guid, "health")
            hpMax = GetUnitField(guid, "maxHealth")
        elseif UnitName("target") == efcName then
            hp = UnitHealth("target")
            hpMax = UnitHealthMax("target")
        end

        if hp and hpMax and hpMax > 0 then
            local pct = hp / hpMax
            frame.hpBar:SetMinMaxValues(0, hpMax)
            frame.hpBar:SetValue(hp)
            if pct > 0.5 then frame.hpBar:SetStatusBarColor(0, 0.85, 0)
            elseif pct > 0.25 then frame.hpBar:SetStatusBarColor(1, 0.75, 0)
            else frame.hpBar:SetStatusBarColor(1, 0.1, 0.1) end
            frame.barLabel:SetText(string.format("|cffffff00EFC|r %s |cff%s%d%%|r",
                efcName,
                pct > 0.5 and "00ff00" or pct > 0.25 and "ffcc00" or "ff3333",
                math.floor(pct * 100)))
        else
            frame.hpBar:SetValue(0)
            frame.hpBar:SetStatusBarColor(0.4, 0.4, 0.4)
            frame.barLabel:SetText("|cffffff00EFC|r " .. efcName)
        end
    end)
    frame.ticker = ticker

    -- Location buttons ──────────────────────────────────────────────────────
    for _, btn in ipairs(BUTTONS) do
        local b = CreateFrame("Button", nil, frame)
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", btn.x[ix], btn.y[ix] - 22)  -- -22 for HP bar
        b:SetWidth(btn.w)
        b:SetHeight(btn.h)
        b:SetBackdrop({ bgFile = iconPath .. btn.tex })
        local desc = btn.text
        b:SetScript("OnClick", function()
            WFC.EFCReport:SendLocation(desc)
        end)
        b:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(desc)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    frame:Hide()
    self.frame = frame
end

function WFC.EFCReport:SendLocation(msg)
    -- Respect language; also print locally so you see what was sent
    local lang = GetLanguage()
    SendChatMessage(msg, "Battleground", lang)
end

function WFC.EFCReport:Show()
    if not self.created then self:Create() end
    if self.frame then self.frame:Show() end
    self.enabled = true
end

function WFC.EFCReport:Hide()
    if self.frame then self.frame:Hide() end
    self.enabled = false
end

function WFC.EFCReport:Toggle()
    if self.enabled then self:Hide() else self:Show() end
end

-- Auto-show in WSG via zone event (hooked into Core's event flow)
local efcZoneFrame = CreateFrame("Frame")
efcZoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
efcZoneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
efcZoneFrame:SetScript("OnEvent", function()
    local zone = GetRealZoneText and GetRealZoneText() or GetZoneText()
    if zone == "Warsong Gulch" then
        if not WFC.EFCReport.enabled and TurtlePvPConfig.efcEnabled ~= false then
            WFC.EFCReport:Show()
        end
    else
        if WFC.EFCReport.enabled then
            WFC.EFCReport:Hide()
        end
    end
end)
