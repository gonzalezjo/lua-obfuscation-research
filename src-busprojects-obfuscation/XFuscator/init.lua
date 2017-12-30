require 'LuaMinify.ParseLua'
require 'LuaMinify.FormatMini'
-- local Format_Identity = require 'LuaMinify.FormatIdentity'
local Format_Beautiful = require 'LuaMinify.FormatBeautiful'
-- Format_Beautiful = Format_Identity
require 'LAT'

XFuscator = { }
XFuscator.ExtractConstants = require'XFuscator.ConstantExtractor'
XFuscator.GlobalsToTable = require'LuaMinify.FormatGlobalsToTable'
XFuscator.MapGlobalCalls = require'XFuscator.LayeredCallObfuscator'
XFuscator.LocalizeGlobals = require'XFuscator.GlobalExtractor'
XFuscator.LocalizeGlobalsAgain = require'XFuscator.GlobalExtractorExtraPasses'
XFuscator.GenerateFluff = require'XFuscator.FluffGenerator'
XFuscator.Uglify = require'XFuscator.Uglifier'
XFuscator.Precompile = require'XFuscator.Precompile'
XFuscator.RandomComments = require'XFuscator.RandomComments'
XFuscator.EncryptStrings = require'XFuscator.StringEncryptor'
XFuscator.MutateStrings = require'LuaMinify.FormatMutatedStrings'
XFuscator.BinaryStrings = require'LuaMinify.FormatBinaryStrings'
XFuscator.ObfuscateStrings = require'LuaMinify.FormatEncryptedStrings'
XFuscator.MutateTableAccesses = require'LuaMinify.FormatTableAccessToStrings'
XFuscator.ObfuscateNumbers = require'LuaMinify.FormatNumberObfuscatorOne'
XFuscator.Step2 = require'XFuscator.Step2'
XFuscator.TamperDetection = require'XFuscator.TamperDetection'
XFuscator.Format_Binary = require'LuaMinify.FormatBinaryNames'

XFuscator.DumpString = function(x, encode)
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
            -- v = v .. "\\" .. ch
            v = v .. ch
        else-- 32 <= v <= 126 (NOT 255)
            v = v .. string.char(ch)
        end
        return v
    end)
end

local function obfuscate(code, level, mxLevel, useLoadstring,
                         makeFluff, randomComments, step2, useUglifier,
                         EncryptStrings, useTD, rename, identity,
                         encryptNumbers, obfuscateNumbers, extractConstants, mutateStrings,
                         tableAccessToString, luasrcdiet, stringstobinary, namestobinary,
                         localizeglobals, globalaccesstotable, globalcallmapping)

    -- if useLoadstring == nil then useLoadstring = true end
    rawset(_G, "renameVariables", rename)

    level = level or 1
    mxLevel = mxLevel or 2
    if makeFluff == nil then makeFluff = true end
    if randomComments == nil then randomComments = true end
    if step2 == nil then step2 = true end
    if useUglifier == nil then useUglifier = false end
    if EncryptStrings == nil then EncryptStrings = false end
    if useTD == nil then useTD = true end

    local str = ""
    local success, ast
    local function setAst(code)
        success, ast = ParseLua(code)
        if not success then
            print("\n\n\n\nERROR\nCODE DUMP:\n"..tostring(code))
            print(debug.traceback())
            error("Failed to parse code: " .. ast)
        end
    end

    local function GenerateFluff()
        if makeFluff then
            return XFuscator.GenerateFluff()
        end
    end

    setAst(code)

    if EncryptStrings then
        code = _G.FormatEncryptedStrings.append .. "\n\n" .. code
        setAst(code)
    end

    if stringstobinary then
        code = " " .. FormatBinaryStringStorage.append .. " " .. code
        setAst(code)
    end


    if tableAccessToString then
        setAst(code)
        code = XFuscator.MutateTableAccesses(ast)
        setAst(code)
    else
        -- print "Not table access obfuscating."
    end

    -- if localizeglobals then
        -- print(code)
        -- XFuscator.LocalizeGlobals(code, ast)
        -- code = Format_Beautiful(ast)
        -- XFuscator.LocalizeGlobalsAgain(code, ast, true)
        -- code = Format_Beautiful(ast)
        -- for i = 1, 3 do
        -- XFuscator.LocalizeGlobalsAgain(code, ast, true)
        -- code = Format_Beautiful(ast)
        -- XFuscator.LocalizeGlobalsAgain(code, ast, false)
        -- code = Format_Beautiful(ast)
        -- end
        -- print(code)
        -- error "Done."
    -- end



    if globalaccesstotable then -- the formatter
        code = _G.FormatGlobalsToTable.append .. code
        setAst(code)
        code = XFuscator.GlobalsToTable(code)
        setAst(code)
        if globalcallmapping then
            setAst(code)
            ast = XFuscator.MapGlobalCalls(code)
            code = Format_Beautiful(ast)
            -- error(code)
        end
        code = _G.FormatGlobalsToTable.append .. code
        setAst(code)
        if localizeglobals then
            -- XFuscator.LocalizeGlobals(code, ast)
            -- code = Format_Beautiful(ast)
        end
        code = _G.FormatGlobalsToTable.append .. code
        setAst(code)
        -- error(code)
        -- error()
    end
   if stringstobinary then
        -- code = " " .. FormatBinaryStringStorage.append .. " " .. code
        setAst(code)
        code = XFuscator.BinaryStrings(ast)
        setAst(code)
    else
        -- print "Not strings to binary D:"
    end
    local dumpString = XFuscator.DumpString
    local concat = function(...) return table.concat({...}, "") end

    math.randomseed(os and os.time() or tick())

    -- print("Inital parsing ...")

    setAst(code)

    if mutateStrings then
        -- print "\n\nMUTATINGSTRS\n\n"
        code = XFuscator.MutateStrings(ast)
        setAst(code)
    else
        -- print "\n\nNot mutating strings.\n\n"
    end

    if encryptNumbers then
        code = " local tonumber = tonumber " .. code
        code = XFuscator.ObfuscateNumbers(ast)
        setAst(code)
        -- print("Code: " .. code)
    end

    -- print(code)
    -- error"a"

    if EncryptStrings then
        -- print "Encrypting the Stringinators... "
        -- code = _G.FormatEncryptedStrings.append .. "\n" .. code
        -- print(code)
        setAst(code)
        assert(not (code:match"%)function"), "WTF")
        code = XFuscator.ObfuscateStrings(ast)
        -- print(code)
        -- code = XFuscator.ObfuscateNumbers(ast)
        assert(not (code:match"%)function"), "WTF")
        -- error "ASS"
        -- print(code)
        setAst(code)
    end

    -- print "FREAK1"

    if obfuscateNumbers then
        code = "local tonumber = tonumber \n" .. code
        code = XFuscator.ObfuscateNumbers(ast)
        setAst(code)
        -- print("Code: " .. code)
    end

    if luasrcdiet then
        code = _G.get_minified(code)
        -- print(_G.get_minified(code))
        setAst(code)
    end

    -- print "FREAK2"


    if luasrcdiet then
        -- print "DIE T IN G"
        code = _G.get_minified(code)
        print 'srcidet'
        setAst(code)
        -- print(code)
    end

    -- print "FREAK3"
    collectgarbage()

    -- error(Format_Beautiful)
    local a = Format_Beautiful(ast)
    -- local a = identity and Format_Beautiful(ast) or Format_Beautiful(ast) or (stringstobinary and XFuscator.Format_Binary or Format_Mini(ast))
    -- if useUglifier then
    --     print("Uglifying ...")
    --     a = XFuscator.Uglify(a)
    -- end

    --if useTD then
    --    a = XFuscator.TamperDetection(a)
    --end

    -- print "FREAK4"

    success, ast = ParseLua(a)
    if not success then
        -- If it got this far, and then fails, there is a problem with XFuscator
        error("Failed to parse code (internal XFuscator error, please report along with stack trace and problematic code): " .. ast)
    end

    a = identity and Format_Beautiful(ast) or (namestobinary and XFuscator.Format_Binary(ast) or Format_Mini(ast))
    -- print(XFuscator.Format_Binary(ast))

    if useLoadstring then
        -- print("Precompiling ...")
        a = XFuscator.Precompile(a)
    end


    local a2
    if step2 == true then
        -- print("Step 2 ...")
        -- print'a'
        -- print(GenerateFluff())
        -- print'b'
        -- Convert to char/table/loadstring thing
        a2 = XFuscator.Step2(a, GenerateFluff, useTD)
    else
        -- a2 = a-- dumpString(a, true)
        -- a2 = identity and a or dumpString(a)
        a2 = a
    end

    -- print "FREAK6"

    if randomComments then
        -- print("Inserting unreadable and pointless comments ...")
        a2 = XFuscator.RandomComments(a2)
    end


    a2 = a2:gsub("\r+", " ")
    -- a2 = a2:gsub("\n+", " ")
    a2 = a2:gsub("\t+", " ")
    a2 = a2:gsub("[ ]+", " ")

    -- print(a2)

    --a2 = a2 .. GenerateFluff() TODO
    if level < mxLevel then
        -- print(concat("OBFUSCATED AT LEVEL ", level, " OUT OF ", mxLevel, " (" .. a:len() .. " Obfuscated characters)"))
        return obfuscate(a2, level + 1, mxLevel)
    else
        -- print(concat("OBFUSCATED AT LEVEL ", level, " OUT OF ", mxLevel, " (", a:len(), " Obfuscated Characters) [Done]"))
        return a2
    end
end

function XFuscator.XFuscate(...)
    local s, code = pcall(obfuscate, ...)
    -- local s, code = obfuscate(...)
    -- print(code)
    if not s then
        return nil, code
    else
        return code
    end
end
