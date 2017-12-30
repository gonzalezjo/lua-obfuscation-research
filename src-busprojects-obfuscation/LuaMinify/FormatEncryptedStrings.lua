_G.FormatEncryptedStrings = {}
_G.FormatEncryptedStrings.append = [[ local decode local sub, floor, char, byte, gsub, concat, tonumber, unpack = string.sub, math.floor, string.char, string.byte, string.gsub, table.concat, tonumber, unpack;decode = function(...) local password = {unpack({...}, #{{}}, #{...}/#({{},{}}))} local inputstring = {unpack({...}, #{...}/#{{},{}} + #{{}})} local length = #inputstring for i=#{{}}, length do if #{...} == #{{}} then return sub(char(#{{}}), #{{},{}},#{{},{}}) end inputstring[i]= char(floor(password[i] - byte(inputstring[i]))) end return concat(inputstring) end]]

_G.FormatEncryptedStrings._append = [[
local decode
local sub, floor, char, byte, gsub, concat, tonumber, unpack = string.sub, math.floor, string.char, string.byte, string.gsub, table.concat, tonumber, unpack  decode = function(...)
    local password = {unpack({...}, #{{}}, #{...}/#({{},{}}))}
    local inputstring = {unpack({...}, #{...}/#{{},{}} + #{{}})}
    local length = #inputstring for i=#{{}}, length do if #{...} == #{{}} then
        return sub(char(#{{}}), #{{},{}},#{{},{}}) end inputstring[i]= char(floor(password[i] - byte(inputstring[i]))) end return concat(inputstring) end]]


--
-- Beautifier
--
-- Returns a beautified version of the code, including comments
--

local parser = require"LuaMinify.New.ParseLua"
local ParseLua = parser.ParseLua
local util = require'LuaMinify.New.Util'
local lookupify = util.lookupify

local LowerChars = lookupify{'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i',
    'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r',
    's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
local UpperChars = lookupify{'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
local Digits = lookupify{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}


local function Format_Beautify(ast)
    local formatStatlist, formatExpr
    local indent = 0
    local EOL = "\n"

    local function getIndentation()
        return string.rep("    ", indent)
    end

    local function joinStatementsSafe(a, b, sep)
        sep = sep or ''
        local aa, bb = a:sub(-1,-1), b:sub(1,1)
        if UpperChars[aa] or LowerChars[aa] or aa == '_' then
            if not (UpperChars[bb] or LowerChars[bb] or bb == '_' or Digits[bb]) then
                --bb is a symbol, can join without sep
                return a .. b
            elseif bb == '(' then
                --prevent ambiguous syntax
                return a..sep..b
            else
                return a..sep..b
            end
        elseif Digits[aa] then
            if bb == '(' then
                --can join statements directly
                return a..b
            else
                return a..sep..b
            end
        elseif aa == '' then
            return a..b
        else
            if bb == '(' then
                --don't want to accidentally call last statement, can't join directly
                return a..sep..b
            else
                return a..b
            end
        end
    end

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
    formatExpr = function(expr)
        local out = string.rep('(', expr.ParenCount or 0)
        if expr.AstType == 'VarExpr' then
            if expr.Variable then
                out = out .. expr.Variable.Name
            else
                out = out .. expr.Name
            end

        elseif expr.AstType == 'NumberExpr' then
            out = out..expr.Value.Data

        elseif expr.AstType == 'StringExpr' then

            local str = expr.Value.Constant
            local t = { }

            local newstr = {}
            local passes = {}
            if (str == nil) or (str:len() == 0) or str:sub(1,1) == nil then
                local password = math.random(200,255)
                local char = math.random(password - 200)
                local addition = {password, string.char(password - math.random(5))}
                newstr[#newstr + 1] = addition[2]
            else
                for i = 1, str:len() do
                    local minnumber = str:sub(i,i):byte()
                    if minnumber < 200 then minnumber = 200 end
                    local password = math.random(minnumber, 248)

                    local addition = {password, "\\" .. string.char(password - str:sub(i, i):byte()):byte()}
                    if addition[2] == "]" then
                        addition[2] = "^"
                        password = password + 1
                    end


                    if not (str:sub(i,i) == "\\") then
                        -- print("\n\n\n\n\n\n\n" .. str)
                        passes[#passes + 1] = password
                        newstr[#newstr + 1] = addition[2]
                    end
                end
            end

            local replacement = "concat ({ "
            replacement = replacement .. ("decode("..("%s,'%s')"):format(table.concat(passes, ","), table.concat(newstr, "','")))
            replacement = replacement:gsub("%(,", "%(")
            replacement = replacement:gsub("%(%,'", "('")
            replacement = replacement .. " })"

            out = out..replacement

        elseif expr.AstType == 'BooleanExpr' then
            out = out..tostring(expr.Value)

        elseif expr.AstType == 'NilExpr' then
            out = joinStatementsSafe(out, "nil")

        elseif expr.AstType == 'BinopExpr' then
            out = joinStatementsSafe(out, formatExpr(expr.Lhs)) .. " "
            out = joinStatementsSafe(out, expr.Op) .. " "
            out = joinStatementsSafe(out, formatExpr(expr.Rhs))

        elseif expr.AstType == 'UnopExpr' then
            out = joinStatementsSafe(out, expr.Op) .. (#expr.Op ~= 1 and " " or "")
            out = joinStatementsSafe(out, formatExpr(expr.Rhs))

        elseif expr.AstType == 'DotsExpr' then
            out = out.."..."

        elseif expr.AstType == 'CallExpr' then
            out = out..formatExpr(expr.Base)
            out = out.."("
            for i = 1, #expr.Arguments do
                local l_argument = expr.Arguments[i]
                if l_argument.AstType == "StringExpr" then
                    local str = l_argument.Value.Constant -- oh FRICK yes
                    -- local str = expr.Value.Constant
                    local t = { }

                    local newstr = {}
                    local passes = {}

                    if (str == nil) or (str:len() == 0) or str:sub(1,1) == nil then
                        local password = math.random(200,255)
                        local char = math.random(password - 200)
                        local addition = {password, string.char(password - math.random(5))}
                        newstr[#newstr + 1] = addition[2]
                    else
                        for i = 1, str:len() do
                            local minnumber = str:sub(i,i):byte()
                            if minnumber < 200 then minnumber = 200 end
                            local password = math.random(minnumber, 248)

                            local addition = {password, string.char(password - str:sub(i, i):byte())}
                            if addition[2] == "]" then
                                addition[2] = "^"
                                password = password + 1
                            end


                            if not (str:sub(i,i) == "\\") then
                                -- print("\n\n\n\n\n\n\n" .. str)
                                passes[#passes + 1] = password
                                newstr[#newstr + 1] = addition[2]
                            end
                        end
                    end

                    local replacement = "concat ({ "
                    replacement = replacement .. ("decode("..("%s,[[%s]])"):format(table.concat(passes, ","), table.concat(newstr, "]],[[")))
                    replacement = replacement:gsub("%(,", "%(")
                    replacement = replacement:gsub("%(%,'", "('")
                    replacement = replacement .. " })"

                    out = out..replacement
                else
                    out = out..formatExpr(expr.Arguments[i])
                end
                -- print("debug from fms. type of call: \t\t"..tostring(expr.Arguments[i]).."\t"..type(expr.Arguments[i]))
                if i ~= #expr.Arguments then
                    out = out..", "
                end
            end
            out = out..")"

        elseif expr.AstType == 'TableCallExpr' then
            out = out..formatExpr(expr.Base) .. " "
            out = out..formatExpr(expr.Arguments[1])

        elseif expr.AstType == 'StringCallExpr' then
            out = out..formatExpr(expr.Base) .. " "
            local str = expr.Arguments[1].Constant
            -- local str = expr.Value.Data:sub(2, #expr.Value.Data - 1)
            -- str = str:gsub('\\', '\\92')
            -- str = dumpstring(str)
            local t = { }
            -- print("STRING:" .. str)

            local newstr = {}
            local passes = {}
            if (str == nil) or (str:len() == 0) or str:sub(1,1) == nil then
                -- print "Empty sterrr"
                local password = math.random(200,255)
                local char = math.random(password - 200)
                local addition = {password, string.char(password - math.random(5))}
                newstr[#newstr + 1] = addition[2]
            else
                for i = 1, str:len() do
                    local minnumber = str:sub(i,i):byte()
                    if minnumber < 200 then minnumber = 200 end
                    local password = math.random(minnumber, 248) -- always greater than bytesize
                    -- print("Offset: " .. password - str:sub(i,i):byte())
                    -- print("Password: " .. password)
                    -- print("Bytesize: " .. str:sub(i,i):byte())
                    -- local password = 100 -- what if i could do 100 + i
                    -- print(str:sub(1,1))
                    local addition = {password, string.char(password - str:sub(i, i):byte())}
                    if addition[2] == "]" then
                        addition[2] = "^"
                        password = password + 1
                    end
                    -- print ("Added byte: "..addition[2]:byte())
                    -- newstr = newstr .. addition[2]
                    -- print("Add: " .. addition[1] .. "  \t/\t" .. addition[2] .. "  \t/\t" .. addition[2]:byte())
                    -- if addition[2]:match"\\" then addition[2] = [[\\]] end
                    if not (str:sub(i,i) == "\\") then
                        -- print("\n\n\n\n\n\n\n" .. str)
                        passes[#passes + 1] = password
                        newstr[#newstr + 1] = addition[2]
                    end
                    -- print("T1: " .. tostring(t[#t]))
                end
            end

            local replacement = "concat ({ "
            replacement = replacement .. ("decode("..("%s,[[%s]])"):format(table.concat(passes, ","), table.concat(newstr, "]],[[")))
            replacement = replacement:gsub("%(,", "%(")
            replacement = replacement:gsub("%(%,'", "('")
            replacement = replacement .. " })"
            out = out.."("..replacement..")"
            -- out = out.."("..newString(expr.Arguments[1].Constant)..")"
            -- out = out..expr.Arguments[1].Data

        elseif expr.AstType == 'IndexExpr' then
            out = out..formatExpr(expr.Base).."["..formatExpr(expr.Index).."]"

        elseif expr.AstType == 'MemberExpr' then
            out = out..formatExpr(expr.Base)..expr.Indexer..expr.Ident.Data

        elseif expr.AstType == 'Function' then
            -- anonymous function
            out = out.."function("
            if #expr.Arguments > 0 then
                for i = 1, #expr.Arguments do
                    out = out..expr.Arguments[i].Name
                    if i ~= #expr.Arguments then
                        out = out..", "
                    elseif expr.VarArg then
                        out = out..", ..."
                    end
                end
            elseif expr.VarArg then
                out = out.."..."
            end
            out = out..")" .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(expr.Body))
            indent = indent - 1
            out = joinStatementsSafe(out, getIndentation() .. "end")
        elseif expr.AstType == 'ConstructorExpr' then
            out = out.."{ "
            for i = 1, #expr.EntryList do
                local entry = expr.EntryList[i]
                if entry.Type == 'Key' then
                    out = out.."["..formatExpr(entry.Key).."] = "..formatExpr(entry.Value)
                elseif entry.Type == 'Value' then
                    out = out..formatExpr(entry.Value)
                elseif entry.Type == 'KeyString' then
                    out = out..entry.Key.." = "..formatExpr(entry.Value)
                end
                if i ~= #expr.EntryList then
                    out = out..", "
                end
            end
            out = out.." }"

        elseif expr.AstType == 'Parentheses' then
            out = out.."("..formatExpr(expr.Inner)..")"

        end
        out = out..string.rep(')', expr.ParenCount or 0)
        return out
    end

    local formatStatement = function(statement)
        local out = ""
        if statement.AstType == 'AssignmentStatement' then
            out = getIndentation()
            for i = 1, #statement.Lhs do
                out = out..formatExpr(statement.Lhs[i])
                if i ~= #statement.Lhs then
                    out = out..", "
                end
            end
            if #statement.Rhs > 0 then
                out = out.." = "
                for i = 1, #statement.Rhs do
                    out = out..formatExpr(statement.Rhs[i])
                    if i ~= #statement.Rhs then
                        out = out..", "
                    end
                end
            end
        elseif statement.AstType == 'CallStatement' then
            out = getIndentation() .. formatExpr(statement.Expression)
        elseif statement.AstType == 'LocalStatement' then
            out = getIndentation() .. out.."local "
            for i = 1, #statement.LocalList do
                out = out..statement.LocalList[i].Name
                if i ~= #statement.LocalList then
                    out = out..", "
                end
            end
            if #statement.InitList > 0 then
                out = out.." = "
                for i = 1, #statement.InitList do
                    out = out..formatExpr(statement.InitList[i])
                    if i ~= #statement.InitList then
                        out = out..", "
                    end
                end
            end
        elseif statement.AstType == 'IfStatement' then
            out = getIndentation() .. joinStatementsSafe("if ", formatExpr(statement.Clauses[1].Condition))
            out = joinStatementsSafe(out, " then") .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(statement.Clauses[1].Body))
            indent = indent - 1
            for i = 2, #statement.Clauses do
                local st = statement.Clauses[i]
                if st.Condition then
                    out = getIndentation() .. joinStatementsSafe(out, getIndentation() .. "elseif ")
                    out = joinStatementsSafe(out, formatExpr(st.Condition))
                    out = joinStatementsSafe(out, " then") .. EOL
                else
                    out = joinStatementsSafe(out, getIndentation() .. "else") .. EOL
                end
                indent = indent + 1
                out = joinStatementsSafe(out, formatStatlist(st.Body))
                indent = indent - 1
            end
            out = joinStatementsSafe(out, getIndentation() .. "end") .. EOL
        elseif statement.AstType == 'WhileStatement' then
            out = getIndentation() .. joinStatementsSafe("while ", formatExpr(statement.Condition))
            out = joinStatementsSafe(out, " do") .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(statement.Body))
            indent = indent - 1
            out = joinStatementsSafe(out, getIndentation() .. "end") .. EOL
        elseif statement.AstType == 'DoStatement' then
            out = getIndentation() .. joinStatementsSafe(out, "do") .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(statement.Body))
            indent = indent - 1
            out = joinStatementsSafe(out, getIndentation() .. "end") .. EOL
        elseif statement.AstType == 'ReturnStatement' then
            out = getIndentation() .. "return "
            for i = 1, #statement.Arguments do
                out = joinStatementsSafe(out, formatExpr(statement.Arguments[i]))
                if i ~= #statement.Arguments then
                    out = out..", "
                end
            end
        elseif statement.AstType == 'BreakStatement' then
            out = getIndentation() .. "break"
        elseif statement.AstType == 'RepeatStatement' then
            out = getIndentation() .. "repeat" .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(statement.Body))
            indent = indent - 1
            out = joinStatementsSafe(out, getIndentation() .. "until ")
            out = joinStatementsSafe(out, formatExpr(statement.Condition)) .. EOL
        elseif statement.AstType == 'Function' then
            if statement.IsLocal then
                out = "local "
            end
            out = joinStatementsSafe(out, "function ")
            out = getIndentation() .. out
            if statement.IsLocal then
                out = out..statement.Name.Name
            else
                out = out..formatExpr(statement.Name)
            end
            out = out.."("
            if #statement.Arguments > 0 then
                for i = 1, #statement.Arguments do
                    out = out..statement.Arguments[i].Name
                    if i ~= #statement.Arguments then
                        out = out..", "
                    elseif statement.VarArg then
                        out = out..",..."
                    end
                end
            elseif statement.VarArg then
                out = out.."..."
            end
            out = out..")" .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(statement.Body))
            indent = indent - 1
            out = joinStatementsSafe(out, getIndentation() .. "end") .. EOL
        elseif statement.AstType == 'GenericForStatement' then
            out = getIndentation() .. "for "
            for i = 1, #statement.VariableList do
                out = out..statement.VariableList[i].Name
                if i ~= #statement.VariableList then
                    out = out..", "
                end
            end
            out = out.." in "
            for i = 1, #statement.Generators do
                out = joinStatementsSafe(out, formatExpr(statement.Generators[i]))
                if i ~= #statement.Generators then
                    out = joinStatementsSafe(out, ', ')
                end
            end
            out = joinStatementsSafe(out, " do") .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(statement.Body))
            indent = indent - 1
            out = joinStatementsSafe(out, getIndentation() .. "end") .. EOL
        elseif statement.AstType == 'NumericForStatement' then
            out = getIndentation() .. "for "
            out = out..statement.Variable.Name.." = "
            out = out..formatExpr(statement.Start)..", "..formatExpr(statement.End)
            if statement.Step then
                out = out..", "..formatExpr(statement.Step)
            end
            out = joinStatementsSafe(out, " do") .. EOL
            indent = indent + 1
            out = joinStatementsSafe(out, formatStatlist(statement.Body))
            indent = indent - 1
            out = joinStatementsSafe(out, getIndentation() .. "end") .. EOL
        elseif statement.AstType == 'LabelStatement' then
            out = getIndentation() .. "::" .. statement.Label .. "::" .. EOL
        elseif statement.AstType == 'GotoStatement' then
            out = getIndentation() .. "goto " .. statement.Label .. EOL
        elseif statement.AstType == 'Comment' then
            if statement.CommentType == 'Shebang' then
                out = getIndentation() .. statement.Data
                --out = out .. EOL
            elseif statement.CommentType == 'Comment' then
                out = getIndentation() .. statement.Data
                --out = out .. EOL
            elseif statement.CommentType == 'LongComment' then
                out = getIndentation() .. statement.Data
                --out = out .. EOL
            end
        elseif statement.AstType == 'Eof' then
        -- Ignore
        else
            print("Unknown AST Type: ", statement.AstType)
        end
        return out
    end

    formatStatlist = function(statList)
        local out = ''
        for _, stat in pairs(statList.Body) do
            out = joinStatementsSafe(out, formatStatement(stat) .. EOL)
        end
        return out
    end

    return formatStatlist(ast)
end

return Format_Beautify
