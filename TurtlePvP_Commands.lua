SLASH_TURTLEPVP1 = "/tpvp"
SLASH_TURTLEPVP2 = "/wfc"
SLASH_TURTLEPVP3 = "/turtlepvp"

SlashCmdList["TURTLEPVP"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "[^%s]+") do
        table.insert(args, string.lower(word))
    end
    
    local cmd = args[1]
    
    if cmd == "info" or not cmd then
        if WFC.Minimap and WFC.Minimap.TogglePanel then
            WFC.Minimap:TogglePanel()
        end
    elseif cmd == "debug" then
        if args[2] == "on" then
            TurtlePvPConfig.debug = true
            WFC:Print("Debug mode enabled.")
        else
            TurtlePvPConfig.debug = false
            WFC:Print("Debug mode disabled.")
        end
    elseif cmd == "force" then
        if args[2] == "wsg" then
            WFC:CheckZone(true)
            WFC:Print("Force-enabled WSG mode.")
        elseif args[2] == "arena" then
            local z = GetZoneText()
            -- spoof zone just for triggering check
            WFC.inWSG = false
            WFC.inArena = false
            -- Since CheckZone forces WSG when force=true, we handle this manually:
            WFC.inArena = true
            if WFC.Tracker and WFC.Tracker.Enable then WFC.Tracker:Enable() end
            if WFC.Arena and WFC.Arena.Enable then WFC.Arena:Enable() end
            WFC:Debug("Force-entered Arena. Events enabled.")
            WFC:Print("Force-enabled Arena mode.")
        elseif args[2] == "efc" then
            if WFC.EFCReport and WFC.EFCReport.Toggle then
                WFC.EFCReport:Toggle()
                WFC:Print("Toggled EFC Reporter Grid.")
            end
        end
    elseif cmd == "test" then
        if args[2] == "wsg" then
            WFC.inWSG = true
            WFC.allyCarrier = UnitName("player")
            WFC.hordeCarrier = "Thrall"
            if WFC.Frame and WFC.Frame.UpdateVisibility then WFC.Frame:UpdateVisibility() end
            if WFC.EFCReport and WFC.EFCReport.Show then WFC.EFCReport:Show() end
            WFC:Print("Populated WSG tracking HUD with test data. (Type '/tpvp force efc' to toggle the minimap grid.)")
        end
    elseif cmd == "reset" then
        if WFC.Minimap and WFC.Minimap.ResetAllPositions then
            WFC.Minimap:ResetAllPositions()
        end
    elseif cmd == "status" then
        local onOffStr = function(b) return b and "|cff00ff00[ON]|r" or "|cffff0000[OFF]|r" end
        WFC:Print("=== TurtlePvP Status ===")
        local npStr = GetNampowerVersion and "|cff00ff00Yes|r" or "|cffff0000No|r"
        local unitXPStr = UnitXP and "|cff00ff00Yes|r" or "|cffff0000No|r"
        WFC:Print("Nampower (Guids/HP): " .. npStr)
        WFC:Print("UnitXP (Distance): " .. unitXPStr)
        WFC:Print("WSG Caller: " .. onOffStr(TurtlePvPConfig.wsgEnabled))
        WFC:Print("Arena HUD: " .. onOffStr(TurtlePvPConfig.arenaEnabled))
        WFC:Print("Debug: " .. onOffStr(TurtlePvPConfig.debug))
    elseif cmd == "arenalog" then
        if args[2] == "on" then
            TurtlePvPConfig.arenaLogEnabled = true
            WFC:Print("|cffffff00Arena diagnostic logging ENABLED.|r Log will save to SavedVariables.")
        elseif args[2] == "off" then
            TurtlePvPConfig.arenaLogEnabled = false
            WFC:Print("Arena diagnostic logging disabled.")
        elseif args[2] == "clear" then
            TurtlePvPArenaLog = {}
            WFC:Print("Arena log cleared.")
        elseif args[2] == "dump" then
            -- Print last 20 entries to chat
            local total = TurtlePvPArenaLog and table.getn(TurtlePvPArenaLog) or 0
            WFC:Print("|cffffff00Arena Log: " .. total .. " entries total. Last 20:|r")
            local start = total > 20 and (total - 19) or 1
            for i = start, total do
                WFC:Print(TurtlePvPArenaLog[i])
            end
        else
            local count = TurtlePvPArenaLog and table.getn(TurtlePvPArenaLog) or 0
            local on = TurtlePvPConfig.arenaLogEnabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"
            WFC:Print("Arena log: " .. on .. " | " .. count .. " entries saved")
            WFC:Print("  /tpvp arenalog on    — start logging")
            WFC:Print("  /tpvp arenalog off   — stop logging")
            WFC:Print("  /tpvp arenalog dump  — show last 20 entries")
            WFC:Print("  /tpvp arenalog clear — clear all entries")
            WFC:Print("  Log saves to: WTF/.../SavedVariables/TurtlePvP.lua (TurtlePvPArenaLog)")
        end
    end
end
