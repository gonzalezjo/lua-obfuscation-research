local file_to_string = require 'util.file_to_string'
local create_ast     = require 'luaminify.ParseLua'.ParseLua

ast_to_code    = require 'luaminify.FormatBeautiful'
dispatcher     = file_to_string 'noclooo/lib/dispatcher/dispatcher.lua'
default_script = file_to_string 'noclooo/opt/default.lua'

p = print
c = function() os.execute 'clear' end

to_ast = function (code)
	return select (2, create_ast (code))
end

local function open_terminal(_ast, _code, message)
	if message then print ("MESSAGE: " .. tostring (message) .. "\n\n") end

	ast = _ast or ast
	code = _code or code

	repeat
		local io_in = io.read ()
		io_in = io_in:gsub ("fori", "for i,v in pairs")
		io_in = io_in:gsub ("dpive", "do print(i,v) end")
		io_in = io_in:gsub ("fi", "for i,v in pairs")
		io_in = io_in:gsub ("de", "do print(i,v) end")

		if io_in == 'e' then break end

		if io_in == 'c' then
			c()
		else
			local _function = loadstring (io_in)
			local out = {pcall (_function)}
			if not out[1] then
				print (out[2])
			end
			print ''
		end
	until nil
end

if arg and arg[1] == "-c" then
	code = default_script
	-- ast = to_ast (code)
	ast = to_ast [[local list = {child = function(arg) end}]]
	open_terminal()
end

return open_terminal