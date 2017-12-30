[H[2J[NoClOoo] Loaded successfully


------------

Success. Code: 

------------


do
    local function a()
        local state = 0.30265189163048
        
        while state ~= 0.75942426641109 do
                        if state == 0.12321179480227 then
            state = 0.069011736202608
            print 'a'
        elseif state == 0.30265189163048 then
            if true then
                state = 0.12321179480227
            else
                state = 0.75942426641109
            end

        elseif state == 0.069011736202608 then
            state = 0.30265189163048
            return 
        end

        end

    end

    local function b()
        local state = 0.33226900734528
        
        while state ~= 0.40008569177131 do
                        if state == 0.81217208926661 then
            state = 0.92571925680088
            print 'b'
        elseif state == 0.33226900734528 then
            if true then
                state = 0.81217208926661
            else
                state = 0.40008569177131
            end

        elseif state == 0.92571925680088 then
            state = 0.33226900734528
            return 5
        end

        end

    end

    local x = 10
    local state = 0.21878551841675
        local z
    while state ~= 0.97857461154933 do
                            if state == 0.51030945025408 then
        state = 0.21878551841675
        print(b())
    elseif state == 0.025429097065096 then
        state = 0.63543261627693
        print 'x less than 5'
    elseif state == 0.68688174418618 then
        state = 0.51030945025408
        print(a())
    elseif state == 0.21878551841675 then
        if x > 5 then
            state = 0.025429097065096
        else
            state = 0.97857461154933
        end

    elseif state == 0.38028404414968 then
        state = 0.68688174418618
        print 'is this ignored? nope'
    elseif state == 0.50739420495276 then
        state = 0.38028404414968
        x = x - 1
    elseif state == 0.63543261627693 then
        state = 0.50739420495276
        z = 0
    end

    end

end



x less than 5
is this ignored? nope
a

b
5
x less than 5
is this ignored? nope
a

b
5
x less than 5
is this ignored? nope
a

b
5
x less than 5
is this ignored? nope
a

b
5
x less than 5
is this ignored? nope
a

b
5
