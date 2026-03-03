SLASH_WSGFLAGCALLER1 = "/wsgflagcaller"
SLASH_WSGFLAGCALLER2 = "/wfc"

SlashCmdList["WSGFLAGCALLER"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "[^%s]+") do
        table.insert(args, string.lower(word))
    end
    
    local cmd = args[1]
    
    if cmd == "info" or not cmd then
        WFC:Print("WSGFlagCaller Commands:")
        WFC:Print("/wfc hp on|off")
        WFC:Print("/wfc thresholds 75 50 25")
        WFC:Print("/wfc frame on|off")
        WFC:Print("/wfc minimap on|off")
        WFC:Print("/wfc debug on|off")
        WFC:Print("/wfc force")
        WFC:Print("/wfc reset")
        WFC:Print("/wfc status")
    elseif cmd == "hp" then
        WSGFCConfig.hpCallouts = (args[2] == "on")
        WFC:Print("HP Callouts set to " .. tostring(args[2]))
    elseif cmd == "frame" then
        WSGFCConfig.showFrame = (args[2] == "on")
        WFC:Print("Frame visibility set to " .. tostring(args[2]))
        WFC.Frame:UpdateVisibility()
    elseif cmd == "debug" then
        WSGFCConfig.debug = (args[2] == "on")
        WFC:Print("Debug mode set to " .. tostring(args[2]))
    elseif cmd == "force" then
        WFC:CheckZone(true)
        WFC:Print("Force-enabled WSG mode.")
    elseif cmd == "reset" then
        WSGFCConfig.framePoint = "TOP"
        WSGFCConfig.frameX = 0
        WSGFCConfig.frameY = -150
        if WSGFCHud then
            WSGFCHud:SetPoint(WSGFCConfig.framePoint, UIParent, WSGFCConfig.framePoint, WSGFCConfig.frameX, WSGFCConfig.frameY)
        end
        WFC:Print("Frame position reset.")
    elseif cmd == "thresholds" then
        WSGFCConfig.hpThresholds = {}
        for i=2, table.getn(args) do
            local num = tonumber(args[i])
            if num then
                table.insert(WSGFCConfig.hpThresholds, num)
            end
        end
        WFC:Print("HP Thresholds updated.")
    elseif cmd == "status" then
        WFC:Print("HP Callouts="..tostring(WSGFCConfig.hpCallouts).." Frame="..tostring(WSGFCConfig.showFrame).." Debug="..tostring(WSGFCConfig.debug))
    end
end
