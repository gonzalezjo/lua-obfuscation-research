local file_to_string = function(path)
	local message

	local result = pcall(function()
		assert (path)
		local file = io.open (path, 'r')
		assert (file)
		message = file:read '*a'
	end)

	return message or nil
end

if arg and arg[1] then 
	local code = file_to_string(arg[1])
	local obf = require "lujlu"
	-- local obf = require "lujlu_testing"
	print(unpack({obf(code)}))
end

