return function(ast)
    local astNodeArray = ast.Body[1]
    local byte = string.byte
    local char = string.char
    local gsub = string.gsub
    local concat = table.concat
    local _, node = ParseLua(([[
        local log = math.log
    ]]))


    -- table.insert(ast.Body, 1, node.Body[1])
    -- require"LuaMinify.Util"
    -- local printer = require"Helper.helper".recursivelyPrintTable

    -- printer(ast)

    -- print"AST"
    for i, v in pairs(astNodeArray) do
        -- for i,v in pairs(ast.LocalList[1]) do print(i,v) end
        for k, v in pairs(astNodeArray.LocalList) do -- should do some trig shit for number encryption
            if v.Value then
                print("VALUE: " .. v)
                if v.Value.AstType == 'NumberExpr' then
                    local str = v.Value.Value.Constant
                    local t = { }
                    print("STRING:" .. str)

                    local newstr = {}
                    local passes = {}
                    for i = 1, str:len() do
                        local password = math.random(200, 255) -- always greater than bytesize
                        passes[#passes + 1] = password
                        -- print("Offset: " .. password - str:sub(i,i):byte())
                        -- print("Password: " .. password)
                        -- print("Bytesize: " .. str:sub(i,i):byte())
                        -- local password = 100 -- what if i could do 100 + i
                        local addition = {password, string.char(password - str:sub(i, i):byte())}
                        -- print ("Added byte: "..addition[2]:byte())
                        -- newstr = newstr .. addition[2]
                        -- print("Add: " .. addition[1] .. "  \t/\t" .. addition[2] .. "  \t/\t" .. addition[2]:byte())
                        newstr[#newstr + 1] = addition[2]
                        -- print("T1: " .. tostring(t[#t]))
                    end

                    local newNode = "local _ = table.concat { "
                    -- for k, v in pairs(t) do
                        -- print("V1: " .. v[1])
                        -- print("V2: " .. v[2])
                        -- local z = pcall(function()
                        newNode = newNode .. ("decryptstringtuple("..("%s,'%s')"):format(table.concat(passes, ","), table.concat(newstr, "','")))
                        -- end)
                        -- assert(z)
                    -- end

                    newNode = newNode .. " }"
                    local _, node = ParseLua(dumpstring(newNode))
                    -- print(newNode)
                    if not _ then for i= 1, 1000 do print"" end print("ERROR")print(newNode) error(node) end
                    astNodeArray.EntryList[k].Value = node.Body[1].InitList[1]
                end
            end
        end
    end
end -- must make it I n L i N e all the freaking way