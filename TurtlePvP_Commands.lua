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
        else
            WFC:Print("TurtlePvP Commands:")
            WFC:Print("  /tpvp - Open Config Panel")
            WFC:Print("  /tpvp force wsg - Force-enable WSG mode")
            WFC:Print("  /tpvp force arena - Force-enable Arena mode")
            WFC:Print("  /tpvp reset - Reset HUD positions")
            WFC:Print("  /tpvp status - Show current settings")
            WFC:Print("  /tpvp debug on/off - Toggle debug messages")
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
        end
    elseif cmd == "reset" then
        TurtlePvPConfig.framePoint = "TOP"
        TurtlePvPConfig.frameX = 0
        TurtlePvPConfig.frameY = -150
        TurtlePvPConfig.arenaFramePoint = "CENTER"
        TurtlePvPConfig.arenaFrameX = 0
        TurtlePvPConfig.arenaFrameY = 0
        WFC:Print("Frame positions reset.")
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
    end
end
