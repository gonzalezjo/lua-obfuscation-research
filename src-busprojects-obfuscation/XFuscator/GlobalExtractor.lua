return function(code, ast)
    math.randomseed(os.time() + os.clock())
    local largestPossibleRandomNumber = 9e300
    -- largestPossibleRandomNumber = 50
    largestPossibleRandomNumber = 500

    local dumpString = XFuscator.DumpString
    -- for i,v in pairs(ast.Scope.LocalMap) do if type(v) == 'table' then print("I: " .. i) table.foreach(v, print) end print(i,v) end
    -- print(ast.Scope.Print())
    -- error""

    local CONSTANT_POOL_NAME
    base = 'constants'
    local chars = "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuioplkjhgfdsazxcvbnm_1234567890"
    while code:find(base, 1, true) do
        local n = math.random(1, #chars)
        base = base .. chars:sub(n, n)
    end
    CONSTANT_POOL_NAME = base

    -- Rip constant strings out
    local indices = {1}
    local function makeNode(index)
        return {
            AstType = 'IndexExpr',
            ParentCount = 1,
            Base = { AstType = 'VarExpr', Name = CONSTANT_POOL_NAME },
            Index = { AstType = 'NumberExpr', Value = { Data = (index < 1e14 and tostring(index) or ("%f"):format(index):gsub("%D.+", "")) } }
        } -- Ast Node
    end

    table.insert(ast.Body, 1, {
        AstType = 'LocalStatement',
        Scope = ast.Scope,
        LocalList = {
            --ast.Scope:CreateLocal('CONSTANT_POOL'),
            { Scope = ast.Scope, Name = CONSTANT_POOL_NAME, CanRename = true },
        },
        InitList = {
            { EntryList = { }, AstType = 'ConstructorExpr' },
        },
    })
    local constantPoolAstNode = ast.Body[1].InitList[1]

    local CONSTANT_POOL = { }
    local nilIndex
    local index = 1
    local function insertConstant(v, index, type)
        table.insert(constantPoolAstNode.EntryList, {
            Type = 'Key',
            Value = { AstType = type or 'StringExpr', Value = v },
            Key = { AstType = 'NumberExpr', Value = { Data = (index < 1e14) and tostring(index) or ("%f"):format(index):gsub("%D.+", "") } }
        })
    end

    local function addConstant(const)
        if CONSTANT_POOL[const] then return CONSTANT_POOL[const] end
        if const == nil and nilIndex then return nilIndex end

        -- assert(global)
        -- if not global then return end
        -- print "isGlobal"
        -- print(type(const))
        -- if type

        local newIndex = math.random(largestPossibleRandomNumber)
        while indices[newIndex] do
            print "wow an index collision"
            newIndex = math.random(largestPossibleRandomNumber)
        end
        index = newIndex

        if type(const) == 'string' then
            const = dumpString(const)
            insertConstant({ Data = '"' .. const .. '"', Constant = const }, index, 'StringExpr')
            CONSTANT_POOL[const] = index
            indices[index] = true
            return CONSTANT_POOL[const]
        elseif type(const) == 'number' then
            insertConstant({ Data = const }, index, 'NumberExpr')
            CONSTANT_POOL[const] = index
            index = index + 1
            indices[index] = index
            return CONSTANT_POOL[const]
        elseif type(const) == 'nil' then
            insertConstant(const, index, 'NilExpr')
            nilIndex = index
            index = index + 1
            indices[index] = index
            return nilIndex
        elseif type(const) == 'boolean' then
            insertConstant(const, index, 'BooleanExpr')
            CONSTANT_POOL[const] = index
            index = index + 1
            indices[index] = index
            return CONSTANT_POOL[const]
        elseif const.AstType == 'VarExpr' then
            table.insert(constantPoolAstNode.EntryList, {
                Type = 'Key',
                Value = const,
                Key = { AstType = 'NumberExpr', Value = { Data = tostring(index) } }
            })
            CONSTANT_POOL[const] = index
            index = index + 1
            indices[index] = index
            return CONSTANT_POOL[const]
        elseif const.AstType == 'MemberExpr' then
            error"meme"
        else
            -- print(debug.traceback())
            return error("Unable to process constant of type '" .. type(const) .. "'")
        end
    end

    local fixExpr, fixStatList
    local envName = _G.FormatGlobalsToTable.environmentName
    assert(envName)

    fixExpr = function(expr, foldstrings)
        if expr.AstType == 'VarExpr' or _G.noExtract then
            if expr.Local then
                return expr
            else
                -- local i = addConstant(expr)
                -- return makeNode(i)
            end
        elseif expr.AstType == 'NumberExpr' and foldstrings then
            local i = addConstant(tonumber(expr.Value.Data))
            return makeNode(i)
        elseif expr.AstType == 'StringExpr' and foldstrings then
            local newIndex = math.random(largestPossibleRandomNumber)
            while indices[newIndex] do
                print "wow an index collision"
                newIndex = math.random(largestPossibleRandomNumber)
            end
            indices[newIndex] = true
            index = newIndex
            local i = addConstant(expr.Value.Constant)
            return makeNode(i)
        elseif expr.AstType == 'BooleanExpr' then
            local i = addConstant(expr.Value)
            return makeNode(i)
        elseif expr.AstType == 'NilExpr' then
            local i = addConstant(nil)
            return makeNode(i)
        elseif expr.AstType == 'BinopExpr' then
            expr.Lhs = fixExpr(expr.Lhs)
            expr.Rhs = fixExpr(expr.Rhs)
        elseif expr.AstType == 'UnopExpr' then
            expr.Rhs = fixExpr(expr.Rhs)
        elseif expr.AstType == 'DotsExpr' then
        elseif expr.AstType == 'CallExpr' then
            expr.Base = fixExpr(expr.Base)
            for i = 1, #expr.Arguments do
                expr.Arguments[i] = fixExpr(expr.Arguments[i])
            end
        elseif expr.AstType == 'TableCallExpr' then
            expr.Base = fixExpr(expr.Base)
            expr.Arguments[1] = fixExpr(expr.Arguments[1])
        elseif expr.AstType == 'StringCallExpr' then
            expr.Base = fixExpr(expr.Base)
            expr.Arguments[1] = fixExpr(expr.Arguments[1])
        elseif expr.AstType == 'IndexExpr' then
            -- for i,v in pairs(expr.Base.Base.Base) do print(i,v) end
            local bases = {expr.Base}
            while bases[1].Base do
                table.insert(bases, 1, bases[1].Base)
                if bases[1].Base and bases[1].Base.Name then
                    if bases[1].Base.Name == envName then
                        break
                    end
                end
                if #bases > 10 then
                    bases = {}
                    break
                end
            end
            if #bases >= 2 then -- stack level 1: "global". level 2: "Child"
                for i = 1, #bases - 1 do
                    -- print("Stack level", i, "AstType", bases[i].AstType)
                    -- for i,v in pairs(bases[i].Index) do
                    --     print(i,v.Value,"\n")
                    -- end
                    -- for i,v in pairs(bases[i].Index) do
                    --     print(i,v)
                    --     if type(v) == 'table' then
                    --         for i,v in pairs(v) do
                    --             print(i,v)
                    --         end
                    --     end
                    --     print(i == "Value" and v.Data or "")
                    -- end
                    -- print"\n"
                -- for i,v in pairs(bases[2].Index) do
                --     print(i,v)
                end
                -- error'ass'
                -- base = fixExpr(base)
            end

            if #bases > 0 then
                local constant = expr.Base
                if CONSTANT_POOL[constant] then return CONSTANT_POOL[constant] end
                if constant == nil and nilIndex then return nilIndex end

                CONSTANT_POOL[constant] = index
                local newIndex = math.random(largestPossibleRandomNumber)
                while indices[newIndex] do
                    print "wow an index collision"
                    newIndex = math.random(largestPossibleRandomNumber)
                end
                indices[newIndex] = true
                index = newIndex

                table.insert(constantPoolAstNode.EntryList, {
                    Type = 'Key',
                    Value = constant,
                    Key = { AstType = 'NumberExpr', Value = { Data = ("%f"):format(index):gsub("%D.+", "") } }
                })
            end


            -- table.foreachi(expr, print)
            -- print("Count: " .. #bases)
            expr.Base = fixExpr(expr.Base, true)
            expr.Index = fixExpr(expr.Index, true)
        elseif expr.AstType == 'MemberExpr' then
            expr.Base = fixExpr(expr.Base)
        elseif expr.AstType == 'Function' then
            fixStatList(expr.Body)
        elseif expr.AstType == 'ConstructorExpr' then
            for i = 1, #expr.EntryList do
                local entry = expr.EntryList[i]
                if entry.Type == 'Key' then
                    entry.Key = fixExpr(entry.Key)
                    entry.Value = fixExpr(entry.Value)
                elseif entry.Type == 'Value' then
                    entry.Value = fixExpr(entry.Value)
                elseif entry.Type == 'KeyString' then
                    entry.Value = fixExpr(entry.Value)
                end
            end
        end
        return expr
    end

    local fixStmt = function(statement)
        if statement.AstType == 'AssignmentStatement' then
            for i = 1, #statement.Lhs do
                statement.Lhs[i] = fixExpr(statement.Lhs[i])
            end
            for i = 1, #statement.Rhs do
                statement.Rhs[i] = fixExpr(statement.Rhs[i])
            end
        elseif statement.AstType == 'CallStatement' then
            statement.Expression = fixExpr(statement.Expression)
        elseif statement.AstType == 'LocalStatement' then
            for i = 1, #statement.InitList do
                statement.InitList[i] = fixExpr(statement.InitList[i])
            end
        elseif statement.AstType == 'IfStatement' then
            statement.Clauses[1].Condition = fixExpr(statement.Clauses[1].Condition)
            fixStatList(statement.Clauses[1].Body)
            for i = 2, #statement.Clauses do
                local st = statement.Clauses[i]
                if st.Condition then
                    st.Condition = fixExpr(st.Condition)
                end
                fixStatList(st.Body)
            end
        elseif statement.AstType == 'WhileStatement' then
            statement.Condition = fixExpr(statement.Condition)
            fixStatList(statement.Body)
        elseif statement.AstType == 'DoStatement' then
            fixStatList(statement.Body)
        elseif statement.AstType == 'ReturnStatement' then
            for i = 1, #statement.Arguments do
                statement.Arguments[i] = fixExpr(statement.Arguments[i])
            end
        elseif statement.AstType == 'BreakStatement' then
        elseif statement.AstType == 'RepeatStatement' then
            fixStatList(statement.Body)
            statement.Condition = fixExpr(statement.Condition)
        elseif statement.AstType == 'Function' then
            if statement.IsLocal then
            else
                statement.Name = fixExpr(statement.Name)
            end
            fixStatList(statement.Body)
        elseif statement.AstType == 'GenericForStatement' then
            for i = 1, #statement.Generators do
                statement.Generators[i] = fixExpr(statement.Generators[i])
            end
            fixStatList(statement.Body)
        elseif statement.AstType == 'NumericForStatement' then
            statement.Start = fixExpr(statement.Start)
            statement.End = fixExpr(statement.End)
            if statement.Step then
                statement.Step = fixExpr(statement.Step)
            end
            fixStatList(statement.Body)
        elseif statement.AstType == 'LabelStatement' then
        elseif statement.AstType == 'GotoStatement' then
        else
            print("Unknown AST Type: " .. statement.AstType)
        end
    end

    fixStatList = function(statList)
        for _, stat in pairs(statList.Body) do
            fixStmt(stat)
        end
    end
    fixStatList(ast)

    -- addConstant("die", index)

    local entryListClone = {}
    local keys = {}
    local values = {}
    table.remove(ast.Body[1].InitList[1].EntryList, 1)
    for i,v in pairs(ast.Body[1].InitList[1].EntryList) do
        keys[#keys + 1] = i
    end

    -- for i,v in ipairs(keys) do print(i,v) end
    for past = #keys, 2, -1 do
        local future = math.random(past)
        keys[past], keys[future] = keys[future], keys[past] -- god i love this syntax
    end
    -- for i,v in ipairs(keys) do print(i,v) end
    for i = 1, #keys do
        entryListClone[i] = ast.Body[1].InitList[1].EntryList[keys[i]]
    end
    ast.Body[1].InitList[1].EntryList = entryListClone

end
