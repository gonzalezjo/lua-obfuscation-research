--note: inling will be impossible with varargs

-- require 'metalua.walk.id'
-- require 'metalua.ast_to_string'
os.exit()
local names = {}


local binary_name = function(length)
    local name = ""

    repeat
        for i = 1, length or 16 do
            name = name ..(math.random() < 0.5 and "l" or "I")
        end
    until not names[name]

    return name
end


local compile = function(code)
    print 'hello'

    return code
end

return function(code)
    if type (code) ~= 'string' then
        return error ('\'string\' required, but received type \'' .. type(code) .. '\'')
    else
        return compile (code)
    end
end