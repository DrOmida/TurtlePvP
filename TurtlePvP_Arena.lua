-- TurtlePvP_Arena.lua
--
-- Features:
--  - Auto /pull 15 when arena announces "fifteen seconds"
--  - Cast bar with real timer (drains over spell cast time)
--  - Dynamic HUD width based on longest enemy name
--  - Trinket icon: green = available, red = on cooldown

WFC.Arena = { enabled = false }

-- Runtime detection: pfUI's libcast creates global UnitCastingInfo/UnitChannelInfo.
-- When available, we get accurate cast data + spell icons + SuperWoW support.
-- When not available, we fall back to our own CAST_TIMES table + combat log parsing.
-- NOTE: pfUI registers these globals AFTER addon load (inside RegisterModule),
-- so we check lazily on first use rather than at file parse time.
local hasPfCast = nil  -- nil = not yet checked
local function CheckPfCast()
    if hasPfCast == nil then
        hasPfCast = (UnitCastingInfo ~= nil and UnitChannelInfo ~= nil)
        if hasPfCast then
            WFC:Debug("[Arena] pfUI libcast detected — using enhanced cast bars.")
        else
            WFC:Debug("[Arena] pfUI libcast not found — using fallback CAST_TIMES table.")
        end
    end
    return hasPfCast
end
local MAX_ENEMIES   = 8
local TRINKET_CD    = 120
local SCAN_INTERVAL = 0.25
local ROW_HEIGHT    = 34
local ROW_GAP       = 36

-- Fixed column widths that don't change
local DIST_W        = 32   -- distance text
local TRINKET_W     = 16   -- trinket icon
local HPBAR_W       = 90   -- HP bar
local LEFT_PAD      = 6    -- left padding inside row
local RIGHT_PAD     = 6    -- right padding inside row
local COL_GAP       = 3    -- gap between columns
-- Minimum name column width
local MIN_NAME_W    = 55
-- The fixed right-side width (dist + trinket + hpbar + gaps + padding)
local FIXED_RIGHT_W = DIST_W + COL_GAP + TRINKET_W + COL_GAP + HPBAR_W + RIGHT_PAD

local TRINKET_ICON = "Interface\\Icons\\INV_Jewelry_TrinketPVP_02"

local TRINKET_SPELL_NAMES = {
    "Insignia of the Alliance", "Insignia of the Horde",
    "Medallion of the Alliance", "Medallion of the Horde",
    "Will of the Forsaken", "Stoneform", "Escape Artist",
    "Perception", "Berserking", "Blood Fury", "War Stomp",
    "Shadowmeld", "PvP Trinket",
}

local TRINKET_TEXTURES = {
    "inv_jewelry_trinketpvp", "spell_shadow_raisedead",
    "inv_stone_04", "inv_misc_pocketwatch_01", "spell_nature_regeneration",
}

-- Cast times (seconds) for PvP-relevant spells — FALLBACK TABLE.
-- Only used when pfUI's libcast is NOT loaded (hasPfCast == false).
-- When pfUI is present, UnitCastingInfo/UnitChannelInfo provide accurate
-- durations, icons, and SuperWoW support automatically.
-- Channeled spells are listed in CHANNELED_SPELLS below.
local CAST_TIMES = {
    -- ── Mage ──
    ["Fireball"]             = 3.5,
    ["Frostbolt"]            = 3.0,
    ["Polymorph"]            = 1.5,
    ["Pyroblast"]            = 6.0,
    ["Arcane Missiles"]      = 5.0,   -- channeled, see below
    ["Blizzard"]             = 8.0,   -- channeled
    ["Frost Nova"]           = 0,
    ["Cone of Cold"]         = 0,
    ["Fire Blast"]           = 0,
    ["Counterspell"]         = 0,
    ["Blink"]                = 0,
    ["Ice Block"]            = 0,
    ["Cold Snap"]            = 0,
    ["Presence of Mind"]     = 0,
    -- ── Warlock ──
    ["Shadow Bolt"]          = 3.0,
    ["Immolate"]             = 2.0,
    ["Fear"]                 = 1.5,
    ["Searing Pain"]         = 1.5,
    ["Soul Fire"]            = 6.0,
    ["Banish"]               = 1.5,
    ["Death Coil"]           = 0,
    ["Howl of Terror"]       = 2.0,
    ["Shadowburn"]           = 0,
    ["Drain Life"]           = 5.0,   -- channeled
    ["Drain Mana"]           = 5.0,   -- channeled
    ["Drain Soul"]           = 15.0,  -- channeled
    ["Corruption"]           = 2.0,
    ["Curse of Agony"]       = 0,
    ["Curse of Exhaustion"]  = 0,
    ["Unstable Affliction"]  = 1.5,
    -- ── Priest ──
    ["Mind Blast"]           = 1.5,
    ["Smite"]                = 2.5,
    ["Holy Fire"]            = 3.5,
    ["Greater Heal"]         = 3.0,
    ["Flash Heal"]           = 1.5,
    ["Heal"]                 = 2.5,
    ["Renew"]                = 0,
    ["Power Word: Shield"]   = 0,
    ["Mind Flay"]            = 3.0,   -- channeled
    ["Psychic Scream"]       = 0,
    ["Dispel Magic"]         = 0,
    ["Mass Dispel"]          = 1.5,
    ["Shackle Undead"]       = 1.5,
    ["Prayer of Healing"]    = 3.0,
    ["Prayer of Mending"]    = 0,
    -- ── Druid ──
    ["Wrath"]                = 2.0,
    ["Starfire"]             = 3.5,
    ["Healing Touch"]        = 3.5,
    ["Regrowth"]             = 2.0,
    ["Rebirth"]              = 2.0,
    ["Cyclone"]              = 1.5,
    ["Entangling Roots"]     = 1.5,
    ["Hibernate"]            = 1.5,
    ["Tranquility"]          = 8.0,   -- channeled
    ["Hurricane"]            = 10.0,  -- channeled
    -- ── Shaman ──
    ["Lightning Bolt"]       = 2.5,
    ["Chain Lightning"]      = 2.5,
    ["Healing Wave"]         = 3.0,
    ["Lesser Healing Wave"]  = 1.5,
    ["Chain Heal"]           = 2.5,
    ["Earth Shock"]          = 0,
    ["Frost Shock"]          = 0,
    ["Flame Shock"]          = 0,
    ["Hex"]                  = 1.5,
    -- ── Paladin ──
    ["Holy Light"]           = 2.5,
    ["Flash of Light"]       = 1.5,
    ["Holy Shock"]           = 0,
    ["Hammer of Justice"]    = 0,
    ["Repentance"]           = 1.5,
    ["Blessing of Freedom"]  = 0,
    ["Blessing of Protection"]= 0,
    ["Divine Shield"]        = 0,
    ["Consecration"]         = 0,
    -- ── Hunter ──
    ["Aimed Shot"]           = 3.0,
    ["Multi-Shot"]           = 0,
    ["Arcane Shot"]          = 0,
    ["Concussive Shot"]      = 0,
    ["Wing Clip"]            = 0,
    ["Trap Launcher"]        = 0,
    ["Scatter Shot"]         = 0,
    ["Freezing Trap"]        = 0,
    -- ── Warrior ──
    ["Shoot"]                = 0,
    ["Charge"]               = 0,
    ["Intercept"]            = 0,
    ["Intervene"]            = 0,
    ["Hamstring"]            = 0,
    ["Mortal Strike"]        = 0,
    ["Overpower"]            = 0,
    ["Execute"]              = 0,
    -- ── Rogue ──
    ["Ambush"]               = 0,
    ["Cheap Shot"]           = 0,
    ["Kidney Shot"]          = 0,
    ["Gouge"]                = 0,
    ["Blind"]                = 0,
    ["Vanish"]               = 0,
    ["Shadowstep"]           = 0,
    ["Garrote"]              = 0,
}

-- Channeled spells: cast bar fills and stays full while channeling.
-- Cleared when ANY other event fires from that player.
local CHANNELED_SPELLS = {
    ["Arcane Missiles"] = true,
    ["Blizzard"]        = true,
    ["Drain Life"]      = true,
    ["Drain Mana"]      = true,
    ["Drain Soul"]      = true,
    ["Mind Flay"]       = true,
    ["Tranquility"]     = true,
    ["Hurricane"]       = true,
}

local DEFAULT_CAST_TIME = 3.0

-- Events that mean the enemy just acted (spell landed / melee swing), clearing cast bar.
-- BUFF/AURASGONE/PERIODIC do NOT clear because a DoT tick doesn't interrupt a new cast.
local CAST_CLEAR_EVENTS = {
    CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE  = true,
    CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS   = true,
    CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES = true,
    CHAT_MSG_SPELL_HOSTILEPLAYER_AFFDMG  = true,
}

local SCAN_TOKENS = {
    "target", "mouseover", "targettarget",
    "party1target", "party2target", "party3target", "party4target",
}

-- ─── Enemy state ─────────────────────────────────────────────────────────────
local enemies  = {}   -- cleanName -> { guid, hp, hpMax, trinketUsedTime, castingSpell, castStartTime, castDuration }
local nameList = {}   -- ordered list of cleanName

-- ─── HUD frame ───────────────────────────────────────────────────────────────

local hud = CreateFrame("Frame", "TurtlePvPArenaHUD", UIParent)
hud:SetWidth(200)   -- will be resized dynamically
hud:SetHeight(30)
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
unlockBg:SetPoint("TOPLEFT",  hud, "TOPLEFT",  2, -2)
unlockBg:SetPoint("TOPRIGHT", hud, "TOPRIGHT", -2, -2)
unlockBg:SetHeight(20)
unlockBg:SetTexture(0, 1, 0, 0.2)
hud.unlockBg = unlockBg

local dragHandle = CreateFrame("Button", nil, hud)
dragHandle:SetPoint("TOPLEFT",  hud, "TOPLEFT",  0, 0)
dragHandle:SetPoint("TOPRIGHT", hud, "TOPRIGHT", 0, 0)
dragHandle:SetHeight(24)
dragHandle:RegisterForDrag("LeftButton")
dragHandle:RegisterForClicks("RightButtonUp")

local titleText = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
titleText:SetPoint("CENTER", dragHandle, "CENTER", 0, 0)
titleText:SetText("|cffffd700Arena Enemies|r")

dragHandle:SetScript("OnDragStart", function()
    if not TurtlePvPConfig.arenaLocked then hud:StartMoving() end
end)
dragHandle:SetScript("OnDragStop", function()
    hud:StopMovingOrSizing()
    local point, _, _, xOfs, yOfs = hud:GetPoint()
    TurtlePvPConfig.arenaFramePoint = point
    TurtlePvPConfig.arenaFrameX     = xOfs
    TurtlePvPConfig.arenaFrameY     = yOfs
end)
dragHandle:SetScript("OnClick", function()
    if arg1 == "RightButton" then
        TurtlePvPConfig.arenaLocked = not TurtlePvPConfig.arenaLocked
        if TurtlePvPConfig.arenaLocked then
            hud.unlockBg:Hide(); WFC:Print("Arena HUD Locked.")
        else
            hud.unlockBg:Show(); WFC:Print("Arena HUD Unlocked. Drag title to move.")
        end
    end
end)

-- Row layout (two lines per enemy):
--
--  Line 1: [Name ........] [Dist] [T]  [==== HP bar ====  xx%]
--  Line 2: [▶ Target ......................] (stops at HP bar left edge)
--
-- Cast bar overlays line 2 when active (purple, full width).
-- All left-column widths are set dynamically by ResizeHUD().
for i = 1, MAX_ENEMIES do
    local row = CreateFrame("Button", nil, hud)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", hud, "TOPLEFT", 5, -24 - ((i-1) * ROW_GAP))
    row:RegisterForClicks("LeftButtonUp")

    -- Row background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0.02, 0.02, 0.06, 0.7)

    -- Top 1px separator line
    local sep = row:CreateTexture(nil, "BACKGROUND")
    sep:SetPoint("TOPLEFT",  row, "TOPLEFT",  0, 0)
    sep:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    sep:SetHeight(1)
    sep:SetTexture(0.25, 0.25, 0.35, 0.8)

    -- ── Line 1 ──

    -- Name (width dynamic)
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameText:SetPoint("TOPLEFT", row, "TOPLEFT", LEFT_PAD, -2)
    nameText:SetJustifyH("LEFT")
    row.nameText = nameText

    -- Distance
    local distText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    distText:SetWidth(DIST_W)
    distText:SetJustifyH("RIGHT")
    distText:SetText("--")
    row.distText = distText

    -- Trinket (green = available, red = used)
    local trinketFrame = CreateFrame("Frame", nil, row)
    trinketFrame:SetWidth(TRINKET_W); trinketFrame:SetHeight(TRINKET_W)
    row.trinketFrame = trinketFrame

    local trinketBg = trinketFrame:CreateTexture(nil, "BACKGROUND")
    trinketBg:SetAllPoints()
    trinketBg:SetTexture(0, 0.75, 0, 1)
    row.trinketBg = trinketBg

    local trinketIcon = trinketFrame:CreateTexture(nil, "ARTWORK")
    trinketIcon:SetWidth(TRINKET_W - 2); trinketIcon:SetHeight(TRINKET_W - 2)
    trinketIcon:SetPoint("CENTER", trinketFrame, "CENTER", 0, 0)
    trinketIcon:SetTexture(TRINKET_ICON)
    row.trinketIcon = trinketIcon

    -- HP bar (right-anchored, top half of row)
    local hpBar = CreateFrame("StatusBar", nil, row)
    hpBar:SetWidth(HPBAR_W); hpBar:SetHeight(14)
    hpBar:SetPoint("TOPRIGHT", row, "TOPRIGHT", -RIGHT_PAD, -2)
    hpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    hpBar:SetStatusBarColor(0, 1, 0)
    hpBar:SetMinMaxValues(0, 100); hpBar:SetValue(100)
    row.hpBar = hpBar

    local hpBarBg = hpBar:CreateTexture(nil, "BACKGROUND")
    hpBarBg:SetAllPoints()
    hpBarBg:SetTexture(0.06, 0.06, 0.06, 1)

    local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hpText:SetPoint("CENTER", hpBar, "CENTER", 0, 0)
    hpText:SetText("--")
    row.hpText = hpText

    -- ── Line 2: Target ──
    -- Sits below the name/dist/trinket, stopping at the HP bar's left edge.
    -- Width is calculated in ResizeHUD() as: nameW + dist + trinket + gaps.
    local targetBg = row:CreateTexture(nil, "BACKGROUND")
    targetBg:SetHeight(13)
    targetBg:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", LEFT_PAD - 1, 2)
    targetBg:SetTexture(0.05, 0.05, 0.12, 1)
    row.targetBg = targetBg

    -- Left accent strip for visual polish
    local targetAccent = row:CreateTexture(nil, "ARTWORK")
    targetAccent:SetWidth(2); targetAccent:SetHeight(13)
    targetAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", LEFT_PAD - 1, 2)
    targetAccent:SetTexture(0.3, 0.3, 0.6, 1)
    row.targetAccent = targetAccent

    local targetLine = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    targetLine:SetHeight(13)
    targetLine:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", LEFT_PAD + 3, 2)
    targetLine:SetJustifyH("LEFT")
    targetLine:SetText("")
    row.targetLine = targetLine

    -- ── Cast bar (overlays line 2 when enemy is casting) ──
    local castBar = CreateFrame("StatusBar", nil, row)
    castBar:SetHeight(13)
    castBar:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  LEFT_PAD, 2)
    castBar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -RIGHT_PAD, 2)
    castBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    castBar:SetStatusBarColor(0.5, 0.1, 0.8)
    castBar:SetMinMaxValues(0, 1); castBar:SetValue(0)
    castBar:Hide()
    row.castBar = castBar

    local castBarBg = castBar:CreateTexture(nil, "BACKGROUND")
    castBarBg:SetAllPoints()
    castBarBg:SetTexture(0.08, 0.02, 0.18, 1)

    -- Spell icon (shown when pfUI provides texture)
    local castIcon = castBar:CreateTexture(nil, "ARTWORK")
    castIcon:SetWidth(13); castIcon:SetHeight(13)
    castIcon:SetPoint("LEFT", castBar, "LEFT", 0, 0)
    castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    castIcon:Hide()
    row.castIcon = castIcon

    -- Spell name (left-aligned)
    local castTextLeft = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    castTextLeft:SetPoint("LEFT", castBar, "LEFT", 2, 0)
    castTextLeft:SetJustifyH("LEFT"); castTextLeft:SetText("")
    row.castTextLeft = castTextLeft

    -- Timer (right-aligned)
    local castTextRight = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    castTextRight:SetPoint("RIGHT", castBar, "RIGHT", -2, 0)
    castTextRight:SetJustifyH("RIGHT"); castTextRight:SetText("")
    row.castTextRight = castTextRight

    -- Legacy single centered text (fallback path)
    local castText = castBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    castText:SetAllPoints(); castText:SetJustifyH("CENTER"); castText:SetText("")
    row.castText = castText

    row:SetScript("OnClick", function()
        if arg1 == "LeftButton" and row.targetName then
            TargetByName(row.targetName, true)
        end
    end)

    row:Hide()
    hud.rows[i] = row
end
-- ─── Dynamic resize ───────────────────────────────────────────────────────────
-- Measures the pixel width of each enemy name, picks the widest,
-- then resizes the HUD and repositions name-dependent column anchors.

-- Scratch FontString used purely for measuring text widths
local measureFS = hud:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
measureFS:SetPoint("LEFT", hud, "LEFT", -9999, 0)  -- off-screen
measureFS:Hide()

local currentNameW = MIN_NAME_W   -- cached name column width

local function ResizeHUD()
    -- Find widest name among current enemies
    local maxW = MIN_NAME_W
    for _, name in ipairs(nameList) do
        measureFS:SetText(name)
        local w = measureFS:GetStringWidth()
        if w and w > maxW then maxW = w end
    end
    -- Round up to nearest 2px for clean pixel alignment
    maxW = math.ceil(maxW / 2) * 2 + 4   -- +4px breathing room

    if maxW == currentNameW then return end
    currentNameW = maxW

    local rowTotalW  = LEFT_PAD + maxW + COL_GAP + DIST_W + COL_GAP + TRINKET_W + COL_GAP + HPBAR_W + RIGHT_PAD
    local hudTotalW  = rowTotalW + 10   -- 5px padding each side for backdrop

    hud:SetWidth(hudTotalW)

    for i = 1, MAX_ENEMIES do
        local row = hud.rows[i]
        row:SetWidth(rowTotalW)

        -- Name width
        row.nameText:SetWidth(maxW)

        -- Re-anchor dist to name right
        row.distText:ClearAllPoints()
        row.distText:SetPoint("TOPLEFT", row.nameText, "TOPRIGHT", COL_GAP, 0)

        -- Re-anchor trinket to dist right
        row.trinketFrame:ClearAllPoints()
        row.trinketFrame:SetPoint("TOPLEFT", row.distText, "TOPRIGHT", COL_GAP, -1)

        -- Target area spans name + dist + trinket (stops at HP bar left edge)
        local leftColW = maxW + COL_GAP + DIST_W + COL_GAP + TRINKET_W
        row.targetBg:SetWidth(leftColW + 2)
        row.targetAccent:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", LEFT_PAD - 1, 2)
        row.targetLine:SetWidth(leftColW - 4)
    end
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function CleanName(name)
    if not name then return nil end
    local s = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
    s = string.gsub(s, "|r", "")
    s = string.gsub(s, "[^%a%d]", "")
    return (s ~= "") and s or nil
end

local function IsAlly(cleanName)
    if not cleanName then return false end
    if CleanName(UnitName("player")) == cleanName then return true end
    -- Check party members
    for j = 1, 4 do
        local token = "party" .. j
        if UnitExists(token) and CleanName(UnitName(token)) == cleanName then return true end
    end
    -- Check raid members (Turtle WoW arenas allow mixed Horde/Alliance teams)
    local numRaid = GetNumRaidMembers() or 0
    for j = 1, numRaid do
        local token = "raid" .. j
        if UnitExists(token) and CleanName(UnitName(token)) == cleanName then return true end
    end
    return false
end

local confirmedPlayers = {}

local NON_PLAYER_PATTERNS = {
    "totem",
    "ghoul", "felguard", "felhunter", "succubus", "voidwalker",
    "infernal", "doomguard", "treant", "elemental", "guardian",
    "snake", "hawk", "wolf", "bear", "boar", "cat", "crab",
    "raptor", "scorpid", "spider", "turtle", "bat", "hyena",
    "gorilla", "silithid", "ravager", "tallstrider", "dragonhawk",
}
local function LooksLikeNPC(cleanName)
    if not cleanName or string.len(cleanName) < 3 then return true end
    local lower = string.lower(cleanName)
    for _, pat in ipairs(NON_PLAYER_PATTERNS) do
        if string.find(lower, pat, 1, true) then return true end
    end
    return false
end

-- ─── Enemy registry ──────────────────────────────────────────────────────────

local function AddEnemy(rawName, guid, fromUnitToken)
    local name = CleanName(rawName)
    if not name or IsAlly(name) then return end
    if LooksLikeNPC(name) then return end  -- blocks totems/pets by name pattern

    if fromUnitToken then
        confirmedPlayers[name] = true
    else
        -- Combat log: only add if already confirmed as real player via unit token
        if not confirmedPlayers[name] then return end
    end
    if enemies[name] then
        if guid and guid ~= "" then enemies[name].guid = guid end
        return
    end
    enemies[name] = {
        guid = guid or "", hp = 0, hpMax = 0,
        trinketUsedTime = 0,
        castingSpell = nil, castStartTime = 0, castDuration = 0,
        targeting = nil,   -- name of who this enemy is targeting (or nil if unknown)
    }
    table.insert(nameList, name)
    WFC:Debug("[Arena] Added: " .. name)
end

local function RemoveEnemy(rawName)
    local name = CleanName(rawName)
    if not name or not enemies[name] then return end
    enemies[name] = nil
    for i = 1, table.getn(nameList) do
        if nameList[i] == name then table.remove(nameList, i); break end
    end
    WFC:Debug("[Arena] Removed: " .. name)
end

-- ─── GUID-based discovery (called by Tracker) ───────────────────────────────
function WFC.Arena:DiscoverFromGUID(name, guid)
    if not WFC.Arena.enabled then return end
    AddEnemy(name, guid, true)
end

-- ─── Scan ────────────────────────────────────────────────────────────────────

local function Scan()
    for _, token in ipairs(SCAN_TOKENS) do
        if UnitExists(token) and UnitIsPlayer(token) and UnitIsEnemy("player", token) then
            local rawName = UnitName(token)
            local guid    = (GetUnitGUID and GetUnitGUID(token)) or ""
            if rawName and rawName ~= "Unknown" then
                AddEnemy(rawName, guid, true)

                -- Capture who this enemy is targeting.
                -- "targettarget" works in 1.12 when token=="target".
                -- "mouseovertarget" does NOT exist in 1.12, so we only get it for "target".
                local cleanEnemy = CleanName(rawName)
                if cleanEnemy and enemies[cleanEnemy] then
                    local ttToken = token .. "target"
                    if UnitExists(ttToken) then
                        local ttName = UnitName(ttToken)
                        if ttName and ttName ~= "Unknown" then
                            enemies[cleanEnemy].targeting = ttName
                        end
                    end
                    -- Note: we intentionally keep last known target if ttToken
                    -- doesn't exist right now (e.g. enemy has no target momentarily)
                end
            end
        end
    end

    -- Nameplate GUID harvesting (Nampower) — discovers enemies with visible
    -- nameplates without needing to target or mouseover them.
    if GetUnitGUID and WorldFrame and WorldFrame.GetChildren then
        local ok, children = pcall(function() return { WorldFrame:GetChildren() } end)
        if ok and children then
            for _, child in ipairs(children) do
                if child and child.GetName then
                    local okG, g = pcall(function() return child:GetName(1) end)
                    if okG and type(g) == "string" and string.len(g) > 2 and string.sub(g, 1, 2) == "0x" then
                        local n = UnitName(g)
                        if n and n ~= "Unknown" and UnitIsPlayer(g) and UnitIsEnemy("player", g) then
                            AddEnemy(n, g, true)
                        end
                    end
                end
            end
        end
    end
end

-- ─── HP ──────────────────────────────────────────────────────────────────────

local function GetHP(eData)
    if WFC.hasNampower and GetUnitField and eData.guid and eData.guid ~= "" then
        local hp    = GetUnitField(eData.guid, "health")
        local hpMax = GetUnitField(eData.guid, "maxHealth")
        if hp and hpMax and hpMax > 0 then return hp, hpMax end
    end
    for _, token in ipairs(SCAN_TOKENS) do
        if UnitExists(token) then
            local tGuid = GetUnitGUID and GetUnitGUID(token)
            local match = (tGuid and tGuid ~= "" and tGuid == eData.guid)
                       or (CleanName(UnitName(token)) == eData.cleanName)
            if match then
                local hp    = UnitHealth(token)
                local hpMax = UnitHealthMax(token)
                if hp and hpMax and hpMax > 0 then return hp, hpMax end
            end
        end
    end
    return eData.hp, eData.hpMax
end

-- ─── Distance ────────────────────────────────────────────────────────────────

local function GetDistance(guid)
    if not WFC.hasUnitXP or not guid or guid == "" then return nil end
    local ok, dist = pcall(function() return UnitXP("distanceBetween", "player", guid) end)
    return (ok and dist and dist > 0) and dist or nil
end

-- ─── Trinket ─────────────────────────────────────────────────────────────────

local function MarkTrinketUsed(rawName, spellName)
    local name = CleanName(rawName)
    if not name or not enemies[name] then return end
    local e = enemies[name]
    if e.trinketUsedTime > 0 and (GetTime() - e.trinketUsedTime) < 5 then return end
    e.trinketUsedTime = GetTime()
    WFC:Print("|cffff4400[Arena]|r " .. name .. " used |cffffd700" .. (spellName or "trinket") .. "|r!")
end

local function ScanBuffsForTrinket(token, name)
    if not UnitExists(token) then return end
    for i = 1, 32 do
        local tex = UnitBuff(token, i)
        if not tex then break end
        local tl = string.lower(tex)
        for _, pat in ipairs(TRINKET_TEXTURES) do
            if string.find(tl, pat, 1, true) then
                MarkTrinketUsed(name, nil); break
            end
        end
    end
end

-- ─── Cast parsing ────────────────────────────────────────────────────────────
-- 1.12 GlobalStrings message formats for HOSTILEPLAYER events:
--   "Name begins casting Spell."       -> SPELLCASTSTART_OTHER
--   "Name begins to cast Spell."       -> alternate wording
--   "Name's Spell hits you for X."     -> possessive damage
--   "Name gains Buff."                 -> buff gained
--   "Name attacks you."                -> melee hit
--   "Name's Spell drains X Mana..."    -> drain (mana/life channeled)
-- We use gsub with capture groups, same approach as enemyFrames spellCastingCore.

-- Pre-compiled patterns (stored as strings, compiled by gsub at call time)
local PAT_CAST_START1 = "^(.+) begins casting (.+)%.$"       -- "Name begins casting Spell."
local PAT_CAST_START2 = "^(.+) begins to cast (.+)%.$"       -- "Name begins to cast Spell."
local PAT_POSSESSIVE  = "^(.+)'s .+"                          -- "Name's Spell ..."
local PAT_VERB        = "^([^ ]+) .+"                         -- "Name verb ..."

local function ParseMsg(msg)
    if not msg then return nil, nil end

    -- Try cast-start first (most specific)
    local caster, spell = string.match and string.match(msg, PAT_CAST_START1)
    if caster then return caster, spell end
    caster, spell = string.match and string.match(msg, PAT_CAST_START2)
    if caster then return caster, spell end

    -- Fallback: extract just the caster name
    -- Possessive: "Name's ..."
    local _, _, name = string.find(msg, "^([^ ']+)'s ")
    if name then return name, nil end

    -- Verb: "Name verb ..."  (e.g. "Name attacks you.", "Name gains Buff.")
    -- Take everything before the first space
    _, _, name = string.find(msg, "^([^ ]+) ")
    return name, nil
end

-- string.match may not exist in Lua 5.0 (WoW 1.12 uses Lua 5.0).
-- Provide fallback using string.find with captures.
if not string.match then
    ParseMsg = function(msg)
        if not msg then return nil, nil end
        local _, _, c, s = string.find(msg, "^(.+) begins casting (.+)%.$")
        if c then return c, s end
        _, _, c, s = string.find(msg, "^(.+) begins to cast (.+)%.$")
        if c then return c, s end
        _, _, c = string.find(msg, "^([^ ']+)'s ")
        if c then return c, nil end
        _, _, c = string.find(msg, "^([^ ]+) ")
        return c, nil
    end
end

-- ─── Events ──────────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame")

local function TriggerPullTimer()
    -- Only trigger pull if we are Raid Leader/Officer or Party Leader, or Solo
    local isLeader = true
    if GetNumRaidMembers() > 0 then
        isLeader = IsRaidLeader() or IsRaidOfficer()
    elseif GetNumPartyMembers() > 0 then
        isLeader = IsPartyLeader()
    end
    
    if not isLeader then return end

    if SlashCmdList then
        for name, func in pairs(SlashCmdList) do
            local i = 1
            local cmd = getglobal("SLASH_" .. name .. i)
            while cmd do
                if string.upper(cmd) == "/PULL" then
                    func("15")
                    WFC:Print("|cffffff00[Arena]|r Triggered /pull 15.")
                    return
                end
                i = i + 1
                cmd = getglobal("SLASH_" .. name .. i)
            end
        end
    end
    WFC:Print("|cffff0000[Arena]|r Note: No /pull handler found! Install DBM or BigWigs.")
end

eventFrame:SetScript("OnEvent", function()
    if not WFC.Arena.enabled then return end

    if event == "UNIT_DIED" then
        local deadName = nil
        if arg1 then
            if UnitExists(arg1) then deadName = UnitName(arg1) end
            if not deadName or deadName == "Unknown" then
                for name, eData in pairs(enemies) do
                    if eData.guid ~= "" and eData.guid == arg1 then deadName = name; break end
                end
            end
        end
        if deadName then RemoveEnemy(deadName) end
        WFC.Arena:UpdateHUD()

    elseif event == "CHAT_MSG_BG_SYSTEM_NEUTRAL" then
        -- Arena countdowns arrive as BG system messages in TurtleWoW 1.12:
        -- "Fifteen seconds until the Arena battle begins!"
        -- "The Arena battle has begun!"
        if not arg1 then return end
        local lower = string.lower(arg1)
        if string.find(lower, "fifteen seconds") then
            TriggerPullTimer()
        end
        if string.find(lower, "battle has begun") then
            WFC.Arena:Reset(); WFC:Print("|cffffff00Arena Match Started!|r")
        elseif string.find(lower, "team wins") then
            WFC:Print("|cffffff00Arena Match Ended!|r"); WFC.Arena:Reset()
        end

    elseif event == "CHAT_MSG_MONSTER_YELL" or event == "CHAT_MSG_MONSTER_EMOTE" then
        if not arg1 then return end
        local lower = string.lower(arg1)
        if string.find(lower, "fifteen seconds") then
            TriggerPullTimer()
        end
        if string.find(lower, "battle has begun") then
            WFC.Arena:Reset(); WFC:Print("|cffffff00Arena Match Started!|r")
        elseif string.find(lower, "team wins") then
            WFC:Print("|cffffff00Arena Match Ended!|r"); WFC.Arena:Reset()
        end

    else
        if not arg1 then return end

        local casterName, spellName = ParseMsg(arg1)
        if not casterName then return end

        local clean = CleanName(casterName)
        if not clean or string.len(clean) < 2 then return end

        AddEnemy(casterName, "", false)

        if enemies[clean] and not CheckPfCast() then
            -- Fallback path: write cast state from our own CAST_TIMES table.
            -- When pfUI is active, UnitCastingInfo handles this automatically.
            if spellName then
                -- New cast started: record it
                local cd = CAST_TIMES[spellName]
                if cd == nil then cd = DEFAULT_CAST_TIME end
                local isChanneled = CHANNELED_SPELLS[spellName]
                enemies[clean].castingSpell  = spellName
                enemies[clean].castStartTime = GetTime()
                enemies[clean].castDuration  = isChanneled and -1 or cd  -- -1 = channeled
                enemies[clean].isChanneled   = isChanneled
            else
                -- Only clear cast bar on events that indicate the cast resolved
                if CAST_CLEAR_EVENTS[event] then
                    enemies[clean].castingSpell  = nil
                    enemies[clean].castStartTime = 0
                    enemies[clean].castDuration  = 0
                    enemies[clean].isChanneled   = false
                end
            end
        end

        if TurtlePvPConfig.arenaTrinkets then
            for _, spellKw in ipairs(TRINKET_SPELL_NAMES) do
                if string.find(arg1, spellKw, 1, true) then
                    MarkTrinketUsed(casterName, spellKw); break
                end
            end
        end
    end
end)

-- ─── Enable / Disable / Reset ────────────────────────────────────────────────

function WFC.Arena:Enable()
    if WFC.Arena.enabled then return end
    WFC.Arena.enabled = true

    hud:ClearAllPoints()
    hud:SetPoint(
        TurtlePvPConfig.arenaFramePoint or "CENTER", UIParent,
        TurtlePvPConfig.arenaFramePoint or "CENTER",
        TurtlePvPConfig.arenaFrameX or 0,
        TurtlePvPConfig.arenaFrameY or 0
    )
    if TurtlePvPConfig.arenaLocked then hud.unlockBg:Hide() else hud.unlockBg:Show() end
    hud:Show()

    eventFrame:RegisterEvent("UNIT_DIED")
    eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")
    eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES")
    eventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
    eventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
    eventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_CASTING")
    eventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_AFFDMG")
    eventFrame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_AURASGONE")
    eventFrame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
    eventFrame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    eventFrame:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
    eventFrame:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")

    WFC.Arena:Reset()

    if not hud.ticker then
        hud.ticker = CreateFrame("Frame")
        hud.ticker:SetScript("OnUpdate", function()
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed >= SCAN_INTERVAL then
                this.elapsed = 0
                if WFC.Arena.enabled then Scan(); WFC.Arena:UpdateHUD() end
            end
        end)
    end
    WFC:Debug("Arena enabled.")
end

function WFC.Arena:Disable()
    WFC.Arena.enabled = false
    hud:Hide()
    eventFrame:UnregisterAllEvents()
    if hud.ticker then hud.ticker:SetScript("OnUpdate", nil); hud.ticker = nil end
    WFC.Arena:Reset()
end

function WFC.Arena:Reset()
    enemies          = {}
    nameList         = {}
    confirmedPlayers = {}
    currentNameW     = MIN_NAME_W
    for i = 1, MAX_ENEMIES do hud.rows[i]:Hide() end
    hud:SetHeight(30)
end

-- ─── HUD update ──────────────────────────────────────────────────────────────

function WFC.Arena:UpdateHUD()
    if not TurtlePvPConfig.arenaEnabled then hud:Hide(); return end
    hud:Show()

    -- Buff scan for trinket detection
    if TurtlePvPConfig.arenaTrinkets then
        for _, token in ipairs(SCAN_TOKENS) do
            if UnitExists(token) and UnitIsPlayer(token) and UnitIsEnemy("player", token) then
                local n = CleanName(UnitName(token))
                if n and enemies[n] then ScanBuffsForTrinket(token, n) end
            end
        end
    end

    -- Resize HUD to fit widest name
    ResizeHUD()

    local now    = GetTime()
    local rowIdx = 1

    for i = 1, table.getn(nameList) do
        if rowIdx > MAX_ENEMIES then break end
        local name  = nameList[i]
        local eData = enemies[name]
        if eData then
            eData.cleanName = name
            local row = hud.rows[rowIdx]
            row.targetName = name

            -- HP
            local hp, hpMax = GetHP(eData)
            hp = hp or 0; hpMax = hpMax or 0
            eData.hp = hp; eData.hpMax = hpMax

            if hpMax > 0 then
                row.hpBar:SetMinMaxValues(0, hpMax)
                row.hpBar:SetValue(hp)
                local pct = hp / hpMax
                row.hpText:SetText(math.floor(pct * 100) .. "%")
                if pct > 0.5 then row.hpBar:SetStatusBarColor(0, 1, 0)
                elseif pct > 0.25 then row.hpBar:SetStatusBarColor(1, 1, 0)
                else row.hpBar:SetStatusBarColor(1, 0, 0) end
            else
                row.hpBar:SetMinMaxValues(0, 100); row.hpBar:SetValue(0)
                row.hpBar:SetStatusBarColor(0.5, 0.5, 0.5)
                row.hpText:SetText("--")
            end

            -- Distance  (green=close, yellow=medium, white=far)
            row.distText:SetText("--")
            if TurtlePvPConfig.arenaDistance then
                local dist = GetDistance(eData.guid)
                if dist then
                    if dist <= 20 then row.distText:SetText(string.format("|cff00ff00%dy|r", dist))
                    elseif dist <= 40 then row.distText:SetText(string.format("|cffffff00%dy|r", dist))
                    else row.distText:SetText(string.format("%dy", dist)) end
                end
            end

            -- Name
            local classToken = nil
            if WFC.hasNampower and UnitClass and eData.guid ~= "" then
                _, classToken = UnitClass(eData.guid)
            end
            local cColor = (classToken and WFC:GetClassColor(classToken)) or "FFFFFF"
            row.nameText:SetText("|cff" .. cColor .. name .. "|r")

            -- Trinket: reset if CD expired
            if eData.trinketUsedTime > 0 and (now - eData.trinketUsedTime) >= TRINKET_CD then
                eData.trinketUsedTime = 0
            end
            if eData.trinketUsedTime == 0 then
                row.trinketBg:SetTexture(0, 0.75, 0, 1)
                row.trinketIcon:SetVertexColor(1, 1, 1)
            else
                row.trinketBg:SetTexture(0.8, 0, 0, 1)
                row.trinketIcon:SetVertexColor(0.35, 0.35, 0.35)
            end

            -- Cast bar rendering (dual path: pfUI enhanced vs. fallback)
            local castShown = false

            -- Helper: hide all cast bar elements
            local function HideCastBar()
                row.castBar:Hide()
                row.castIcon:Hide()
                row.castTextLeft:SetText("")
                row.castTextRight:SetText("")
                row.castText:SetText("")
            end

            if CheckPfCast() then
                -- ── pfUI path: query UnitCastingInfo / UnitChannelInfo ──
                local castSpell, _, _, castTex, castStart, castEnd = UnitCastingInfo(name)
                local chanSpell, _, _, chanTex, chanStart, chanEnd = UnitChannelInfo(name)

                if castSpell and castStart and castEnd then
                    -- Regular cast
                    local duration = (castEnd - castStart) / 1000
                    local cur = now - castStart / 1000

                    if duration > 0 and cur >= 0 and cur <= duration then
                        row.castBar:SetMinMaxValues(0, duration)
                        row.castBar:SetValue(cur)
                        row.castBar:SetStatusBarColor(0.5, 0.1, 0.8)
                        row.castTextLeft:SetText("|cffff9900" .. castSpell .. "|r")
                        row.castTextRight:SetText(string.format("|cffcccccc%.1f / %.1f|r", cur, duration))
                        row.castText:SetText("")  -- hide legacy centered text
                        if castTex then
                            row.castIcon:SetTexture(castTex)
                            row.castIcon:Show()
                            row.castTextLeft:SetPoint("LEFT", row.castIcon, "RIGHT", 2, 0)
                        else
                            row.castIcon:Hide()
                            row.castTextLeft:SetPoint("LEFT", row.castBar, "LEFT", 2, 0)
                        end
                        row.castBar:Show()
                        castShown = true
                    end
                elseif chanSpell and chanStart and chanEnd then
                    -- Channeled
                    local duration = (chanEnd - chanStart) / 1000
                    local cur = duration + chanStart / 1000 - now
                    cur = (cur > duration) and duration or cur
                    cur = (cur < 0) and 0 or cur

                    row.castBar:SetMinMaxValues(0, duration)
                    row.castBar:SetValue(cur)
                    row.castBar:SetStatusBarColor(0.9, 0.5, 0.0)
                    row.castTextLeft:SetText("|cffffff00~ " .. chanSpell .. " ~|r")
                    row.castTextRight:SetText(string.format("|cffcccccc%.1f|r", cur))
                    row.castText:SetText("")
                    if chanTex then
                        row.castIcon:SetTexture(chanTex)
                        row.castIcon:Show()
                        row.castTextLeft:SetPoint("LEFT", row.castIcon, "RIGHT", 2, 0)
                    else
                        row.castIcon:Hide()
                        row.castTextLeft:SetPoint("LEFT", row.castBar, "LEFT", 2, 0)
                    end
                    row.castBar:Show()
                    castShown = true
                end

                if not castShown then HideCastBar() end
            else
                -- ── Fallback path: own CAST_TIMES table + combat log parsing ──
                row.castIcon:Hide()
                row.castTextLeft:SetText("")
                row.castTextRight:SetText("")

                if eData.castingSpell then
                    if eData.castDuration == -1 then
                        -- Channeled: full bar, orange tint
                        row.castBar:SetMinMaxValues(0, 1)
                        row.castBar:SetValue(1)
                        row.castBar:SetStatusBarColor(0.9, 0.5, 0.0)
                        row.castText:SetText("|cffffff00~ " .. eData.castingSpell .. " ~|r")
                        row.castBar:Show()
                        castShown = true
                    elseif eData.castDuration > 0 then
                        local elapsed = now - eData.castStartTime
                        if elapsed >= eData.castDuration then
                            eData.castingSpell  = nil
                            eData.castStartTime = 0
                            eData.castDuration  = 0
                            HideCastBar()
                        else
                            local pct = elapsed / eData.castDuration
                            local remaining = eData.castDuration - elapsed
                            row.castBar:SetMinMaxValues(0, 1)
                            row.castBar:SetValue(pct)
                            row.castBar:SetStatusBarColor(0.5, 0.1, 0.8)
                            row.castText:SetText(string.format("|cffff9900%s|r |cffcccccc%.1fs|r", eData.castingSpell, remaining))
                            row.castBar:Show()
                            castShown = true
                        end
                    else
                        -- Instant: flash briefly
                        local elapsed = now - eData.castStartTime
                        if elapsed < 0.6 then
                            row.castBar:SetMinMaxValues(0, 1)
                            row.castBar:SetValue(1)
                            row.castBar:SetStatusBarColor(1, 0.8, 0)
                            row.castText:SetText("|cffff9900" .. eData.castingSpell .. "|r")
                            row.castBar:Show()
                            castShown = true
                        else
                            eData.castingSpell = nil
                            HideCastBar()
                        end
                    end
                else
                    HideCastBar()
                end
            end

            -- Target line (line 2, under name — stops at HP bar left edge)
            local tgt = eData.targeting
            if tgt then
                local isYou  = (UnitName("player") == tgt)
                local isAlly = false
                if not isYou then
                    for j = 1, 4 do
                        if UnitExists("party"..j) and UnitName("party"..j) == tgt then
                            isAlly = true; break
                        end
                    end
                end

                if isYou then
                    -- Targeting you: red bg, bright red accent
                    row.targetBg:SetTexture(0.28, 0.03, 0.03, 1)
                    row.targetAccent:SetTexture(0.9, 0.1, 0.1, 1)
                elseif isAlly then
                    -- Targeting teammate: orange bg, orange accent
                    row.targetBg:SetTexture(0.22, 0.11, 0.01, 1)
                    row.targetAccent:SetTexture(0.9, 0.5, 0.05, 1)
                else
                    -- Targeting other / unknown
                    row.targetBg:SetTexture(0.05, 0.05, 0.12, 1)
                    row.targetAccent:SetTexture(0.25, 0.25, 0.55, 1)
                end

                local nameColor = isYou and "ff5555" or (isAlly and "ffaa33" or "8899bb")
                local displayTgt = tgt
                if string.len(displayTgt) > 15 then
                    displayTgt = string.sub(displayTgt, 1, 14) .. ".."
                end
                row.targetLine:SetText("|cff" .. nameColor .. displayTgt .. "|r")
            else
                row.targetBg:SetTexture(0.05, 0.05, 0.12, 1)
                row.targetAccent:SetTexture(0.2, 0.2, 0.4, 1)
                row.targetLine:SetText("|cff333344...|r")
            end

            row:Show()
            rowIdx = rowIdx + 1
        end
    end

    for i = rowIdx, MAX_ENEMIES do hud.rows[i]:Hide() end
    hud:SetHeight(rowIdx > 1 and (30 + (rowIdx - 1) * ROW_GAP) or 30)
end