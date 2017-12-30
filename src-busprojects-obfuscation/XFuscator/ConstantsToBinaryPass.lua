return function(ast)
    local function dumpstring(x, encode)
    --return concat("\"", x:gsub(".", function(d) return "\\" .. string.byte(d) end), "\"")
        return x:gsub(".", function(d)
            -- return not encode and "\\" .. d:byte() or d
            -- return d
            local v = ""
            local ch = string.byte(d)
            -- other chars with values > 31 are '"' (34), '\' (92) and > 126
            if ch < 32 or ch == 34 or ch == 92 or ch > 126 then
                if ch >= 7 and ch <= 13 then
                    ch = string.sub("abtnvfr", ch - 6, ch - 6)
                elseif ch == 34 or ch == 92 then
                    ch = string.char(ch)
                end
                v = v .. "\\" .. ch
                -- v = v .. ch
            else-- 32 <= v <= 126 (NOT 255)
                v = v .. string.char(ch)
            end
            return v
        end)
    end

    local constantPoolAstNode = ast.Body[1].InitList[1]
    local byte = string.byte
    local char = string.char
    local gsub = string.gsub
    local concat = table.concat
    local _, node = ParseLua(([[
        local gsub, byte, char, len, assert, tonumber, unpack, fmod, sub = string.gsub, string.byte, string.char, string.len, assert, tonumber, unpack, math.fmod, string.sub
        local decryptstringtuple = function(...)
            local password = {unpack({...}, 1, #{...}/2)}
            local inputstring = {unpack({...}, #{...}/2 + 1)}
            -- print("password: " .. password[#password])
            -- print("inputstr: " .. inputstring[1])
            local length = #inputstring
            -- local const=password*0.5
            -- local z=const % password+1
            -- local b=const*2 - 1
            -- b=(b<1) and(10 *z)^-1 or((z+.5))^-1
            -- if not (b > 1) then b = ((z-1)*2)^-1 end
            for i=1, length do
                -- print(b)
                -- print("DEBUG: " .. floor(tonumber(inputstring[i])*b))
                -- print("BYTESIZE: " .. inputstring[i]:byte())
                -- print("PASSWORD: " .. password[i])
                -- print("Offset: " .. password[i] - inputstring[i]:byte())
                -- local int = floor(b^-1 - byte(inputstring[i])
                local int = floor(password[i] - byte(inputstring[i]))
                -- print"D1"
                -- print("INT!: " .. int)
                inputstring[i]= char(floor(int))
            end
            return concat(inputstring)
        end
    ]]))


    table.insert(ast.Body, 1, node.Body[1])
    table.insert(ast.Body, 2, node.Body[2])

    for k, v in pairs(constantPoolAstNode.EntryList) do -- should do some trig shit for number encryption
        if v.Value then
            if v.Value.AstType == 'StringExpr' then
                local str = v.Value.Value.Constant
                local t = { }
                -- print("STRING:" .. str)

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
                constantPoolAstNode.EntryList[k].Value = node.Body[1].InitList[1]
            end
        end
    end
end -- must make it I n L i N e all the freaking way
-- replace divisions with 1 * (1/n)