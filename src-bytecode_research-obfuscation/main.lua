assert (_VERSION == 'Lua 5.1', 'Use Lua 5.1.')
if package.loaded['metalua.compiler'] then
	_G.METALUA = true
else
	print 'sigh. load the env right, retard.'
	print 'attempting to force load env'
	require 'metalua.loader'
	print 'if you see this, the env may not have died??'
end

do
	-- debug.traceback = require 'stp.StackTracePlus'.stacktrace
end

local FILE_NAME      = "obfuscated.luac.out"
local DEBUG_MODE 	 	 = false
local pcall, assert  = pcall, assert

require 'lat.LAT'

-- local obfuscate      = require 'eye.init'
local ast_to_code    = require 'luaminify.FixLabels'
local create_ast     = require 'luaminify.ParseLua'.ParseLua
local file_slurp 	 = require 'fs.file_slurp'
local file_to_string = require 'util.file_to_string'
local preformat_code = require 'eye.preprocessor'

local default_script = file_to_string 'eye/opt/default.lua'

local code           = nil

math.randomseed(os.time())

if arg and (_G.METALUA and arg[2] or arg[1]) then
	code = file_to_string(_G.METALUA and arg[2] or arg[1])
	assert (code and #code > 0, "Could not read file from argument.")
else
	assert (default_script, "No argument or default script.")
	code = default_script
end

if DEBUG_MODE then
	pcall = function(callback, ...)
		return true, callback (...)
	end
	assert = function(value)
		print (value)
	end
end

do
	local code = code

	if not (code:match "-{ extension %('goto', ...%) }") then
		print "Generating Lua IR"
		local success, _, output = pcall (create_ast, code)
		assert (success, table.concat {"Error generating AST;", tostring(code)} ) -- make ast
		success, code = pcall (ast_to_code, output)
		assert (success, table.concat {"Error generating Lua; ", tostring(code)} ) -- format code
		print 'Formatted'
		code = '-{ extension (\'goto\', ...) }\n' .. code
		print (code)
		print "Generated new IR"
	end

	print 'IR transpile succeeded...'

	code = preformat_code (code)

	-- print (({code:gsub ("-{ extension %('goto', ...%) }", '')})[1])

	local file = io.open (FILE_NAME, 'wb')
	file:write (code)
	file:close()

	print('Build success. Output written to ' .. FILE_NAME)

	-- local success, code = pcall (preformat_code, code)
	-- assert (success, table.concat {"Error formatting AST;", tostring(code)} )

	-- success, code = pcall(obfuscate, code)
	-- assert (success, table.concat {"Error processing AST; ", tostring(code)} )

	-- print(code)
end