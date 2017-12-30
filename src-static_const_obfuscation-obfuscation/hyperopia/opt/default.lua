local call = function(x) return x end
local t = {[1] = 5}
local a = b == 2 and 'test failed' or 'test passed'
print(a)
local b = 1 == 1 and 'test passed' or 'test failed'
print(b)  
local number = 2
local c = 2 == number and 'test passed' or 'test failed'
print(c)
local d = ((function() return 5 end)()) == 5 and 'test passed' or 'test failed'
print(d)
local e = call(5) == 5 and 'test passed' or 'test failed'
print(e)
local f = t[1] == 5 and 'test passed' or 'test failed'
print(e)
local message = "ass"
local g = "ass" == message and 'test passed' or 'test failed'
print(g) 
