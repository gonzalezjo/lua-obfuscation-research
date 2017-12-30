local increment

local amount = 100
do
    local unused_upvalue = 200
    function increment()
        amount = amount + 10
        return amount
    end
end

print(amount)
print(increment())
print(amount)
print(increment())
print(amount)

--[[code output

-- Command line was: luac.out

do
  local amount = nil
  do
    local unused_upvalue = 100
  end
   -- DECOMPILER ERROR: Overwrote pending register.

   -- DECOMPILER ERROR: Confused about usage of registers!

  200(unused_upvalue)
  amount = function()
  amount = amount + 10
  return amount
end

  print(amount())
   -- DECOMPILER ERROR: Confused about usage of registers!
local increment

local amount = 100
do
    local unused_upvalue = 200
    function increment()
        amount = amount + 10
        return amount
    end
end

print(amount)
print(increment())
print(amount)
print(increment())
print(amount)
  print(unused_upvalue)
  print(amount())
   -- DECOMPILER ERROR: Confused about usage of registers!

  print(unused_upvalue)
end
 -- DECOMPILER ERROR: Confused about usage of registers for local variables.
 ]]--
