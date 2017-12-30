local md5 = require 'hyperopia.lib.hash.md5'
local md5_name = 'md5.sumhexa'

local obfuscate_ast = function(ast)
    local fix_expression, fix_statement_list

    fix_expression = function(expr)
        if expr.AstType == 'VarExpr' then
            if expr.Local then
                return expr
            else
                --local i = addConstant(expr)
                --return makeNode(i)
            end
        elseif expr.AstType == 'NumberExpr' then
            -- local i = addConstant(tonumber(expr.Value.Data))
            -- return makeNode(i)
        elseif expr.AstType == 'StringExpr' then
            -- local i = addConstant(expr.Value.Constant)
            -- return makeNode(i)
        elseif expr.AstType == 'BooleanExpr' then
            -- local i = addConstant(expr.Value)
            -- return makeNode(i)
        elseif expr.AstType == 'NilExpr' then
            -- local i = addConstant(nil)
            -- return makeNode(i)
        elseif expr.AstType == 'Parentheses' then 
            fix_expression(expr.Inner)
        elseif expr.AstType == 'BinopExpr' then
            -- require 'debugast' (expr)
            if (expr.Op == '==' or expr.Op == '~=') and ((expr.Lhs.AstType == 'NumberExpr' or expr.Rhs.AstType == 'NumberExpr') or (expr.Lhs.AstType == 'StringExpr' or expr.Rhs.AstType == 'StringExpr')) then 
                if expr.Lhs.AstType == 'NumberExpr' or expr.Lhs.AstType == 'StringExpr' then 
                    -- require 'debugast' (expr)
                    local string = expr.Lhs.AstType == 'StringExpr'
                    expr.Lhs.AstType = 'StringExpr'
                    expr.Lhs.Value.Type = 'String'                 
                    -- error ''
                    expr.Lhs.Value.Data = ("[=[%s]=]"):format(md5.sumhexa(tostring(string and expr.Lhs.Value.Constant or expr.Lhs.Value.Data)))
                -- end
                elseif expr.Lhs.AstType == 'VarExpr' then
                    expr.Lhs.Variable = {
                        Scope      = {}, 
                        CanRename  = true, 
                        References = 0, 
                        Name       = ("(%s(tostring(%s)))"):format(md5_name, expr.Lhs.Name), 
                        IsGlobal   = false,  
                    }  
                else 
                    expr.Lhs.Replacement = "(" .. md5_name .. "(tostring(%s)))"
                end
                if expr.Rhs.AstType == 'NumberExpr' or expr.Rhs.AstType == 'StringExpr' then 
                    local string = expr.Rhs.AstType == 'StringExpr'
                    expr.Rhs.AstType = 'StringExpr'
                    expr.Rhs.Value.Type = 'String'                 
                    expr.Rhs.Value.Data = ("[=[%s]=]"):format(md5.sumhexa(tostring(string and expr.Rhs.Value.Constant or expr.Rhs.Value.Data)))
                elseif expr.Rhs.AstType == 'VarExpr' then
                    expr.Rhs.Variable = {
                        Scope      = {}, 
                        CanRename  = true, 
                        References = 0, 
                        Name       = ("(%s(tostring(%s)))"):format(md5_name, expr.Rhs.Name), 
                        IsGlobal   = false,  
                    } 
                else 
                    expr.Rhs.Replacement = "(" .. md5_name .. "(tostring(%s)))"
                end
            -- else
            end -- was else expr.Lhs = fixexpr, expr.Rhs = fixexpr, end. 
            expr.Lhs = fix_expression(expr.Lhs)
            expr.Rhs = fix_expression(expr.Rhs)
            -- end
        elseif expr.AstType == 'UnopExpr' then
            expr.Rhs = fix_expression(expr.Rhs)
        elseif expr.AstType == 'DotsExpr' then
        elseif expr.AstType == 'CallExpr' then
            expr.Base = fix_expression(expr.Base)
            for i = 1, #expr.Arguments do
                expr.Arguments[i] = fix_expression(expr.Arguments[i])
            end
        elseif expr.AstType == 'TableCallExpr' then
            expr.Base = fix_expression(expr.Base)
            expr.Arguments[1] = fix_expression(expr.Arguments[1])
        elseif expr.AstType == 'StringCallExpr' then
            expr.Base = fix_expression(expr.Base)
            expr.Arguments[1] = fix_expression(expr.Arguments[1])
        elseif expr.AstType == 'IndexExpr' then
            expr.Base = fix_expression(expr.Base)
            expr.Index = fix_expression(expr.Index)
        elseif expr.AstType == 'MemberExpr' then
            expr.Base = fix_expression(expr.Base)
        elseif expr.AstType == 'Function' then
            fix_statement_list(expr.Body)
        elseif expr.AstType == 'ConstructorExpr' then
            for i = 1, #expr.EntryList do
                local entry = expr.EntryList[i]
                if entry.Type == 'Key' then
                    entry.Key = fix_expression(entry.Key)
                    entry.Value = fix_expression(entry.Value)
                elseif entry.Type == 'Value' then
                    entry.Value = fix_expression(entry.Value)
                elseif entry.Type == 'KeyString' then
                    entry.Value = fix_expression(entry.Value)
                end
            end
        end
        return expr
    end

    local fix_statement = function(statement)
        if statement.AstType == 'AssignmentStatement' then
            for i = 1, #statement.Lhs do
                statement.Lhs[i] = fix_expression(statement.Lhs[i])
            end
            for i = 1, #statement.Rhs do
                statement.Rhs[i] = fix_expression(statement.Rhs[i])
            end
        elseif statement.AstType == 'CallStatement' then
            statement.Expression = fix_expression(statement.Expression)
        elseif statement.AstType == 'LocalStatement' then
            for i = 1, #statement.InitList do
                statement.InitList[i] = fix_expression(statement.InitList[i])
            end
        elseif statement.AstType == 'IfStatement' then
            statement.Clauses[1].Condition = fix_expression(statement.Clauses[1].Condition)
            fix_statement_list(statement.Clauses[1].Body)
            for i = 2, #statement.Clauses do
                local st = statement.Clauses[i]
                if st.Condition then
                    st.Condition = fix_expression(st.Condition)
                end
                fix_statement_list(st.Body)
            end
        elseif statement.AstType == 'WhileStatement' then
            statement.Condition = fix_expression(statement.Condition)
            fix_statement_list(statement.Body)
        elseif statement.AstType == 'DoStatement' then
            fix_statement_list(statement.Body)
        elseif statement.AstType == 'ReturnStatement' then
            for i = 1, #statement.Arguments do
                statement.Arguments[i] = fix_expression(statement.Arguments[i])
            end
        elseif statement.AstType == 'BreakStatement' then
        elseif statement.AstType == 'RepeatStatement' then
            fix_statement_list(statement.Body)
            statement.Condition = fix_expression(statement.Condition)
        elseif statement.AstType == 'Function' then
            if statement.IsLocal then
            else
                statement.Name = fix_expression(statement.Name)
            end
            fix_statement_list(statement.Body)
        elseif statement.AstType == 'GenericForStatement' then
            for i = 1, #statement.Generators do
                statement.Generators[i] = fix_expression(statement.Generators[i])
            end
            fix_statement_list(statement.Body)
        elseif statement.AstType == 'NumericForStatement' then
            statement.Start = fix_expression(statement.Start)
            statement.End = fix_expression(statement.End)
            if statement.Step then
                statement.Step = fix_expression(statement.Step)
            end
            fix_statement_list(statement.Body)
        elseif statement.AstType == 'LabelStatement' then
        elseif statement.AstType == 'GotoStatement' then
        elseif statement.AstType == 'Eof' then
        else
            print("Unknown AST Type: " .. statement.AstType)
        end
    end

    fix_statement_list = function(statList)
        for _, stat in pairs(statList.Body) do
            fix_statement(stat)
        end
    end

    fix_statement_list(ast)

    return ast
end

return function(ast)
    if type (ast) ~= 'table' then
        return error ('\'table\' required, but received type \'' .. type(ast) .. '\'')
    else
        print '[Hyperopia] Loaded successfully'
        return obfuscate_ast(ast)
    end
end