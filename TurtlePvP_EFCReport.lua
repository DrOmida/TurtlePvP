--[[
TurtlePvP_EFCReport.lua
EFC Location Reporter — WSG only.
Adapted from EFCReport by Cubenicke (Yrrol@vanillagaming).
Icons bundled from EFCReport/Icons/*.blp — original artwork by lanevegame.
HP bar removed: this window is purely a location callout grid.
Right-click anywhere to toggle lock/unlock (drag when unlocked).
--]]

WFC.EFCReport = {
    enabled = false,
    created = false,
}

local iconPath = "Interface\\AddOns\\TurtlePvP\\Icons\\"

-- 23 WSG location buttons (index [1]=Alliance perspective, [2]=Horde perspective)
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


local function GetFactionIdx()
    return (UnitFactionGroup("player") == "Horde") and 2 or 1
end



-- ─────────────────────────────────────────────────────────────────────────────
-- Lock state updater (called after toggling TurtlePvPConfig.efcLocked)
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.EFCReport:UpdateLockState()
    if not self.frame then return end
    if TurtlePvPConfig.efcLocked then
        self.frame.unlockBg:Hide()
    else
        self.frame.unlockBg:Show()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Create the EFC grid frame
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.EFCReport:Create()
    if self.created then return end
    self.created = true

    local fx = TurtlePvPConfig.efcFrameX or 400
    local fy = TurtlePvPConfig.efcFrameY or 300
    local ix = GetFactionIdx()

    local frame = CreateFrame("Frame", "TurtlePvPEFCFrame", UIParent)
    frame:SetWidth(132)
    frame:SetHeight(228)
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

    -- Green tint overlay shown when unlocked (same pattern as WSG HUD and Arena HUD)
    local unlockBg = frame:CreateTexture(nil, "BACKGROUND")
    unlockBg:SetAllPoints(frame)
    unlockBg:SetTexture(0, 1, 0, 0.15)
    frame.unlockBg = unlockBg

    -- Drag: only move when unlocked; right-click toggles lock
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if not TurtlePvPConfig.efcLocked then this:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        TurtlePvPConfig.efcFrameX =  this:GetLeft()
        TurtlePvPConfig.efcFrameY = -this:GetTop() + GetScreenHeight()
    end)
    -- Right-click anywhere on the frame to toggle lock
    -- (Frames don't have RegisterForClicks in 1.12 — use OnMouseUp)
    frame:SetScript("OnMouseUp", function()
        if arg1 == "RightButton" then
            TurtlePvPConfig.efcLocked = not TurtlePvPConfig.efcLocked
            WFC.EFCReport:UpdateLockState()
            if TurtlePvPConfig.efcLocked then
                WFC:Print("EFC Map Locked.")
            else
                WFC:Print("EFC Map Unlocked. Drag to move, right-click to lock.")
            end
        end
    end)

    -- Location buttons (pure callout grid, no HP bar offset)
    for _, def in ipairs(BUTTONS) do
        local b = CreateFrame("Button", nil, frame)
        b:SetPoint("TOPLEFT", frame, "TOPLEFT", def.x[ix], def.y[ix])
        b:SetWidth(def.w)
        b:SetHeight(def.h)
        b:SetBackdrop({ bgFile = iconPath .. def.tex })
        local desc = def.text
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

    -- Apply initial lock state
    WFC.EFCReport:UpdateLockState()

    frame:Hide()
    self.frame = frame
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────────────────────────────────────
function WFC.EFCReport:SendLocation(msg)
    -- BATTLEGROUND chat uses faction language automatically; no language arg needed
    SendChatMessage(msg, "BATTLEGROUND")
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

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto-show in WSG
-- ─────────────────────────────────────────────────────────────────────────────
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
