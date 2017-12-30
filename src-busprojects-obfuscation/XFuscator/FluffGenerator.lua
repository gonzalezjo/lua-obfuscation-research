local function GenerateSomeFluff()
    local dumpString = XFuscator.DumpString
    
    local randomTable = { 
        "100", 
        "baited", 
        "game", 
        "60", 
        "wait", 
        "Lighting", 
        "key=math.floor(9e9/math.random())", 
        "error", 
        "____",  
        "string", 
        "table", 
        "string", 
        "os", 
    }

    --for i = 1, 100 do print(math.random(1, #randomTable)) end
    local x = math.random(1, #randomTable)
    if x > (#randomTable / 2) then
        local randomName = randomTable[x]
        return table.concat{ "local ", string.rep("_", math.random(5, 10)), " = ", "____[#____ - 9](", "'" .. dumpString("loadstring(\"return " .. randomName .. "\")()") .. "'", ")\n" }
    elseif x > 3 then
        return table.concat{ "local ", string.rep("_", math.random(5, 10)), " = ____[", math.random(1, 31), "]\n" }
    else -- x == 3, 2, or 1
        return table.concat{ "local ", ("_"):rep(100), " = ", '"' .. dumpString("die", true) .. '"', "\n" }
    end
end
local function GenerateFluff()
    --local x = { } for i = 1, math.random(2, 10) do table.insert(x, GenerateSomeFluff()) end return table.concat(x) 
    return GenerateSomeFluff()
end

return GenerateSomeFluff
