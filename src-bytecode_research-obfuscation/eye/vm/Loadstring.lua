--[[
	Credit to einsteinK.
	Credit to Stravant for LBI.
	
	Credit to the creators of all the other modules used in this.
	
	Sceleratis was here and decided modify some things.
	
	einsteinK was here again to fix a bug in LBI for if-statements
--]]

local waitDeps = {
	'LBI';
	'LuaK';
	'LuaP';
	'LuaU';
	'LuaX';
	'LuaY';
	'LuaZ';
}

for i,v in pairs(waitDeps) do script:WaitForChild(v) end

local luaX = require(script.LuaX)
local luaY = require(script.LuaY)
local luaZ = require(script.LuaZ)
local luaU = require(script.LuaU)
local lbi = require(script.LBI)

luaX:init()
local LuaState = {}

getfenv().script = nil

return function(str,env)
	local f,writer,buff,name
	local env = getfenv(2) --Ignoring env changes for now
	local name = (env.script and env.script:GetFullName())
	local ran,error = pcall(function()
		local zio = luaZ:init(luaZ:make_getS(str), nil)
		if not zio then return error() end
		local func = luaY:parser(LuaState, zio, nil, name or "::Adonis::Loadstring::")
		writer, buff = luaU:make_setS()
		luaU:dump(LuaState, func, writer, buff)
		f = lbi.load_bytecode(buff.data,env)
		setfenv(f,env) -- setfenving the returned function tends to not work correctly, will look into in future
	end)
	
	if ran then
		return f,buff.data
	else
		return nil,error
	end
end