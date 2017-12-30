-- heavily inspired by mlnlover11's constant extractor --

return function(ast, configuration)
    if type (ast) ~= 'table' then
        return error ('\'table\' required, but received type \'' .. type(ast) .. '\'')
    else
        print '[NoClOoo] Loaded successfully'
    end

    -- commercial bytecode obfuscators are fucking sorcery --

    local name = configuration.name

    -- block belongs to mlnlover
    -- table.insert(ast.Body, 1, {
    -- 	AstType = 'LocalStatement',
    -- 	Scope = ast.Scope,
    --        LocalList = {
    --        	Scope = ast.Scope,
    --        	-- Name = configuration.name,
    --        	Name = "boo",
    --        	CanRename = true
    --        },
    --        InitList = {
    --            {
    --            	EntryList = { },
    --            	AstType = 'ConstructorExpr'
    --            },
    --        },
    -- })

    -- local functions_pool = {} -- this is a really neat design. ty mlnlover11
    -- local guid_map 		 = {}
    -- local functions_node = ast.Body[1].InitList[1]
    local START = -1
    local STOP  = -2
    local index = 1

    local function getReturnNode(body, locals)
        local new_node = {
            AstType = 'ReturnStatement',
            ParentCount = 1,
            Arguments = {locals}
        }
        return {node = new_node, index = index}
    end

    local function addFunction(body)
        if functions_pool[body] then return functions_pool[body] end

        if not body then
            return error 'Expected body, received nil.'
        end

        if body.AstType ~= 'Function' then
            table.insert (functions_node.EntryList, {
                type = 'Key',
                Value = const,
                Key = {
                    AstType = 'NumberExpr',
                    Value = {
                        Data = tostring(index)
                    }
                }
            })
            -- functions_pool[body]
            functions_pool[body] = index
            index = index + 1
            return functions_pool[body] -- cant i just return body?
        end

    end

    local fix_expression, fix_statement, fix_tree

    fix_expression = function(expression) -- stub
        return expression
    end

    fix_statement = function(statement)
        if statement.AstType == 'AssignmentStatement' then
            for i = 1, #statement.Lhs do
                statement.Lhs[i] = fix_expression(statement.Lhs[i])
            end
            for i = 1, #statement.Rhs do
                statement.Rhs[i] = fix_expression(statement.Rhs[i])
            end
        elseif statement.AstType == 'CallStatement' then
            if statement.Expression.Base.Variable.IsGlobal then
            -- print 'Unsupported'
            else
            -- require 'debugast' (statement)
            -- print 'food'
            end
            statement.Expression = fix_expression(statement.Expression)
        elseif statement.AstType == 'LocalStatement' then
            for i = 1, #statement.InitList do
                statement.InitList[i] = fix_expression(statement.InitList[i])
            end
        elseif statement.AstType == 'IfStatement' then
        -- statement.Clauses[1].Body.Scope
        -- statement.Clauses[1].Condition
        -- for i,v in pairs(statement.Clauses[1].Body.Tokens) do
        -- 	print(i,v)
        -- end
        -- error "Breakpoint"
        -- statement.Clauses[1].Condition = fix_expression(statement.Clauses[1].Condition)
        -- fix_tree(statement.Clauses[1].Body)
        -- for i = 2, #statement.Clauses do
        -- 	local st = statement.Clauses[i]
        -- 	if st.Condition then
        -- 		st.Condition = fix_expression(st.Condition)
        -- 	end
        -- 	fix_tree(st.Body)
        -- end
        elseif statement.AstType == 'WhileStatement' then
            require 'debugast' (statement)
            local number_map = {}
            for i = -2, 100 do
                -- number_map[i] = i
                number_map[i] = math.random()
            end
            -- table.foreachi(number_map, print)
            local body_index  = index
            index = index + 1

            local break_index = index
            index = index + 1

            local check_index = index
            index = index + 1

            local loop_index  = 1

            local condition, body = statement.Condition, statement.Body
            -- local loop_variable   = '_a' .. math.random(9e9)
            local loop_variable 	= 'state'
            statement.CREATE_STATE = {
                name = "state",
                value = number_map[1],
                locals = {}
            }

            -- require 'debugast'

            table.insert (statement.Body.Scope.Parent.Locals, 1, {
                Scope 	   = statement.Body.Scope.Parent,
                CanRename  = true,
                References = 1,
                Name 	   = loop_variable,
                IsGlobal   = false,
            })

            local loop_variable_table = statement.Body.Scope.Parent.Locals[1]

            -- statement.Prefix = string.format("local %s = %d", loop_variable, loop_index)

            -- local Rhs = statement.Condition.Rhs

            statement.Condition = {
                AstType = 'BinopExpr',
                Op 		= '~=',
                Lhs 	= {
                    AstType  = 'VarExpr',
                    Name 	 = loop_variable,
                    Variable = loop_variable_table,
                    Tokens 	 = {},
                },
                Rhs		= {
                    AstType = 'NumberExpr',
                    Value   = {
                        -- Line = Rhs.Line,
                        Data = number_map[0],
                        Type = 'Number',
                    -- LeadingWhite = Rhs.LeadingWhite,
                    }
                }
            }

            local body = statement.Body.Body
            assert (body and #body ~= 0)

            -- require 'debugast' (statement)

            local locals, removables = {}, {}

            for i = #body, 1, -1 do
                local sub_expression = body[i]
                if sub_expression.AstType == 'LocalStatement' then -- handle local function a() somehow. autoconvert to local a = function?
                    sub_expression.AstType = 'AssignmentStatement'
                    sub_expression.Rhs 	   = sub_expression.InitList
                    sub_expression.Lhs 	   = {}

                    local assignment_index = 1
                    for _, local_variable in ipairs (sub_expression.LocalList) do
                        table.insert (locals, 1, local_variable)
                        sub_expression.Lhs[assignment_index] = {
                            AstType  = 'VarExpr',
                            Name 	 = local_variable.Name,
                            Variable = local_variable,
                        }
                        assignment_index = assignment_index + 1
                    end

                    if #sub_expression.InitList == 0 then
                        removables[#removables] = i
                    end

                    sub_expression.InitList  = nil
                    sub_expression.LocalList = nil

                end
            end
            -- require 'debugast' (statement, nil, "After change")

            -- for i = #removables, 1, -1 do
            -- 	table.remove (body, removables[i])
            -- end



            local true_start = 1

            if locals ~= 0 then
                statement.CREATE_STATE.locals = {
                    AstType 	= 'LocalStatement',
                    InitList 	= {},
                    LocalList 	= locals,
                    Artificial  = true,
                }
                -- error "my ass"
            end
            -- require 'debugast' (statement, nil, "After adding locals")


            table.insert (body, true_start, {
                AstType = 'IfStatement',
                Clauses = {}
            })


            local if_statement = body[true_start]

            true_start = true_start + 1
            local bodies, _bodies = {}, {}

            local _tmp_position = 1
            for i = true_start, #body do
                local offset = true_start - 1
                assert(body[i])
                bodies[i - offset] = body[i]
                bodies[i - offset].true_position = _tmp_position
                _tmp_position = _tmp_position + 1
                -- require 'debugast' (bodies[i], nil, "Debug: " .. tostring(bodies[i].AstType))
                if bodies[i - offset] and bodies[i - offset].Expression and bodies[i - offset].Expression.Arguments and bodies[i - offset].Expression.Arguments[1] and bodies[i - offset].Expression.Arguments[1].Data and bodies[i - offset].Expression.Arguments[1].Data:match'less than' then
                -- error('\n' .. tostring(bodies[i].Expression.Arguments[1].Data))
                end
                -- assert(bodies[i])
            end

            _G.body = body or 5
            local picked_end = false
            bodies[#bodies].End = true
            -- for i,v in pairs(bodies[#bodies].Expression.Arguments[1]) do print(i,v) end
            -- error''

            for i,v in pairs(bodies) do
                if not (bodies[i]) then
                    print(bodies[i], i)
                    error''
                end
            end
            while #bodies > 0 do
                -- print(#bodies)
                table.insert (_bodies, table.remove (bodies, math.random (#bodies)))
            end
            -- error''

            bodies = _bodies
            -- require 'debugast' (statement, nil, "check for first print call")

            -- why am i not creating original index:random map
            local real_index_to_fake = {}
            for i = 1, #bodies do
                real_index_to_fake[bodies[i].true_position] = i
            end

            local fake_index_to_real = {}
            for i = 1, #bodies do
                fake_index_to_real[i] = bodies[i].true_position
            end

            local last_index
            for i = 1, #bodies do
                local random_position = math.random (#if_statement.Clauses + 1)
                table.insert(if_statement.Clauses, random_position, {})
                -- if_statement.Clauses[i] = {}
                local clause = if_statement.Clauses[random_position]

                clause.Body = {
                    AstType = 'StatList',
                    Body 	= {},
                    Tokens 	= {}
                }

                -- local in_body_index = bodies[i].End and 0 or math.random (9e9)
                local in_body_index = bodies[i].End and -1 or number_map[bodies[i].true_position + 1]

                assert(in_body_index)

                clause.Condition = {
                    AstType = "BinopExpr",
                    Op 			= "==",
                    Lhs  		= {
                        AstType  = 'VarExpr',
                        Name 	 = loop_variable,
                        Variable = loop_variable_table,
                    },
                    Rhs			= {
                        AstType = 'NumberExpr',
                        Value   = {
                            -- Line 		= Rhs.Line,
                            Data 		= number_map[bodies[i].true_position + 1],
                            Type 		= 'Number',
                        }
                    }
                }

                table.insert (clause.Body.Body, bodies[i])

                table.insert (clause.Body.Body, 1, {
                    AstType	= 'AssignmentStatement',
                    Rhs	= {
                        [1] = {
                            AstType = 'NumberExpr',
                            Tokens  = {},
                            Value 	= {
                                Data = in_body_index <= 0 and number_map[1] or number_map[bodies[i].true_position + 2], -- in_body_index == 1 and #bodies + 1 or
                                Type = 'Number',
                            }
                        }
                    },
                    Lhs = {
                        [1] = {
                            AstType  = 'VarExpr',
                            Name     = loop_variable,
                            Variable = loop_variable_table,
                        }
                    },
                    Tokens = {}
                })

                -- require 'debugast' (statement)

            end

            for i = true_start, #body do
                body[i] = nil
            end

            -- require 'debugast' (statement.Body)

            table.insert (if_statement.Clauses, math.random(#if_statement.Clauses + 1), { -- Clauses[3]
                Body = { -- Clauses[3].Body
                    AstType = 'StatList',
                    Tokens  = {},
                    Body = { -- -- Clauses[3].Body.Body
                        [1] = {  -- Clauses[3].Body.Body[1]
                            AstType = 'IfStatement',
                            Clauses = { --  Clauses
                                [2] = { --  Clauses[1]
                                    Body = { --  Clauses[1].Body
                                        Body = { -- Clauses[1].Body.Body fuck i dont want to align this
                                            [1] = { -- Clauses[1].Body.Body[1]
                                                AstType = 'AssignmentStatement',
                                                Rhs = {
                                                    [1] = {
                                                        AstType = 'NumberExpr',
                                                        Tokens = {},
                                                        Value = {
                                                            Data = number_map[0],
                                                            Type = 'Number',
                                                        }
                                                    }
                                                },
                                                Lhs = {
                                                    [1] = {
                                                        AstType  = 'VarExpr',
                                                        Name  	 = loop_variable,
                                                        Variable = loop_variable_table,
                                                    }
                                                },
                                                Tokens 		= {},
                                            }
                                        }
                                    },
                                },
                                [1] = { --  Clauses[1]
                                    Body = { --  Clauses[1].Body
                                        Body = { -- Clauses[1].Body.Body fuck i dont want to align this
                                            [1] = { -- Clauses[1].Body.Body[1]
                                                AstType = 'AssignmentStatement',
                                                Rhs = {
                                                    [1] = {
                                                        AstType = 'NumberExpr',
                                                        Tokens = {},
                                                        Value = {
                                                            Data = number_map[2],
                                                            Type = 'Number',
                                                        }
                                                    }
                                                },
                                                Lhs = {
                                                    [1] = {
                                                        AstType  = 'VarExpr',
                                                        Name 	 = loop_variable,
                                                        Variable = loop_variable_table,
                                                    }
                                                },
                                                Tokens 		= {},
                                            }
                                        }
                                    },
                                    Condition = condition,
                                }
                            }
                        }
                    }
                },
                Condition = {
                    AstType = "BinopExpr",
                    Op 			= "==",
                    Lhs  		= {
                        AstType  = 'VarExpr',
                        Name 	 = loop_variable,
                        Variable = loop_variable_table,
                    },
                    Rhs			= {
                        AstType = 'NumberExpr',
                        Value   = {
                            -- Line 		= Rhs.Line,
                            Data 		= number_map[1],
                            Type 		= 'Number',
                        }
                    }
                }
            })

            -- require 'debugast' (statement)

            -- local clause = clause.

            statement.Condition = fix_expression(statement.Condition)
            fix_tree(statement.Body)
        elseif statement.AstType == 'DoStatement' then
            fix_tree(statement.Body)
        elseif statement.AstType == 'ReturnStatement' then
            for i = 1, #statement.Arguments do
                statement.Arguments[i] = fix_expression(statement.Arguments[i])
            end
        elseif statement.AstType == 'BreakStatement' then
        elseif statement.AstType == 'RepeatStatement' then
            error ('Unsupported AstType \'' .. statement.AstType .. '\'')
            -- fix_tree(statement.Body)
            -- statement.Condition = fix_expression(statement.Condition)
        elseif statement.AstType == 'Function' and statement.IsLocal and #statement.Body.Body ~= 0 then
            local body = statement.Body.Body
            if body[#body].AstType ~= 'ReturnStatement' then
                table.insert (body, #body + 1, {
                    AstType 	= 'ReturnStatement',
                    Arguments 	= {},
                    Tokens 		= {},
                })
            end

            statement.Body.Body = {
                [1] = {
                    AstType   = 'WhileStatement',
                    Condition = {
                        AstType = 'BooleanExpr',
                        Tokens  = {},
                        Value 	= true,
                    },
                    Tokens = {},
                    Body = {
                        AstType = 'StatList',
                        Tokens  = {},
                        Scope 	= statement.Body.Scope,
                        Body 	= body,
                    }

                },
            }
            fix_tree(statement.Body)
        elseif statement.AstType == 'GenericForStatement' then
            for i = 1, #statement.Generators do
                statement.Generators[i] = fix_expression(statement.Generators[i])
            end
            fix_tree(statement.Body)
        elseif statement.AstType == 'NumericForStatement' then
            statement.Start = fix_expression(statement.Start)
            if statement.Step then
                statement.Step = fix_expression(statement.Step)
            end
            fix_tree(statement.Body)
        elseif statement.AstType == 'LabelStatement' then
        elseif statement.AstType == 'GotoStatement' then
        elseif statement.AstType == 'Eof' then
        else
            print("Unknown AST Type: " .. statement.AstType)
        end
    end

    fix_tree = function(tree)
        for _, body in pairs(tree.Body) do
            fix_statement(body)
        end
        return tree
    end

    return fix_tree(ast)

end


-- local f,m,bor=table.foreachi bor=function(a,b) m={} f(a,function(i,v) m[i]=v==1 and 1 or b[i]==1 and 1 or 0 end) return m end
-- print(unpack(bor({1,0,1,0},{1,1,1,0})))
