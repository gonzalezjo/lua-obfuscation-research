-- http://lua-users.org/wiki/DetectingUndefinedVariables
-- luac -p -l myprogram.lua | grep ETGLOBAL 
-- 5.2: luac -p -l myprogram.lua | grep ETGLOBAL 

-- print(game) 
string.len()
-- local _string = string
-- local string_gsub = string.gsub
-- local _string_gsub = _string.gsub
-- do 
	-- z = game.x
-- end