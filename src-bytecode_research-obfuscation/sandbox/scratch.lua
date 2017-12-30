do
    local x = 10
    local state = 1
    while state ~= 0 do
        local z
        if state == 5 then
            state = 6
            x = x - 1
        elseif state == 2 then
            state = 3
            print 'x less than 5'
        elseif state == 3 then
            state = 4
            z = 0
        elseif state == 4 then
            state = 1
            print 'is this ignored? nope'
        elseif state == 1 then
            if x > 5 then
                state = 2
            else
                state = 0
            end
        end
    end
end
