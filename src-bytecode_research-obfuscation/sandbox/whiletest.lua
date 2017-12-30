--[[

fori(ast.Body.Body) do if v and v.Expression and v.Expression.Arguments and v.Expression.Arguments[1] and v.Expression.Arguments[1].Data and v.Expression.Arguments[1].Data:match'less than' then print('\n' .. tostring(v.Expression.Arguments[1].Data)) end end

]]--


-- this needs to be recursive
-- can i force locals into a table that i obfuscate

-- before

do
    local function a()
        print 'a'
    end

    local function b()
        print 'b'
        return 5
    end

    local x = 10

    while x > 5 do
        if x == 5 then
            if x ~= 6 then
                print 'x is 5'
            end
        end
        print 'x less than 5'
        local z = 0
        x = x - 1
        print 'is this ignored? nope'
        print(a())
        print(b())
    end

end