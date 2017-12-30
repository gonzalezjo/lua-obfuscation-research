return function(path)
	local message

	local result = pcall(function()
		assert (path)
		local file = io.open (path, 'r')
		assert (file)
		message = file:read '*a'
	end)

	return message or nil
end