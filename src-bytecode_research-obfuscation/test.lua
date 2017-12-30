
local function open_terminal(_ast, _code, message)
    local state = 0.51494657126214
    
    while state ~= 0.31050968775097 do
                            if state == 0.53290770760595 then
        state = 0.51494657126214
        return 
    elseif state == 0.99474118198545 then
        state = 0.42382258982317
        if true then
            return 
        end

    elseif state == 0.42382258982317 then
        state = 0.61718308099172
        if message then
            print("MESSAGE: " .. tostring(message) .. "\n\n")
        end

    elseif state == 0.61718308099172 then
        state = 0.77183466938438
        ast = _ast or ast
    elseif state == 0.51494657126214 then
        if true then
            state = 0.99474118198545
        else
            state = 0.31050968775097
        end

    elseif state == 0.77538295025639 then
        state = 0.53290770760595
        repeat
            local io_in = io.read()
            io_in = io_in:gsub("fori", "for i,v in pairs")
            io_in = io_in:gsub("dpive", "do print(i,v) end")
            if io_in == 'e' then
                break
            end

            if io_in == 'c' then
                c()
            else
                local _function = loadstring(io_in)
                local out = { pcall(_function) }
                if not out[1] then
                    print(out[2])
                end

                print ''
            end

        until nil

    elseif state == 0.77183466938438 then
        state = 0.77538295025639
        code = _code or code
    end

    end

end
