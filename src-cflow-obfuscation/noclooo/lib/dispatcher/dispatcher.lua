local file_to_string = require 'util.file_to_string'

local dispatcher = setmetatable ({}, {
	__newindex = function()
		return error 'This table is read only.'
	end,
	__metatable = nil,
})

dispatcher.prologue = file_to_string 'noclooo/lib/dispatcher/prologue.lua'
dispatcher.epilogue = file_to_string 'noclooo/lib/dispatcher/epilogue.lua'

for name, contents in pairs (dispatcher) do
	if (not contents) or (#contents <= 1) then
		return ('Could not load \'' .. name .. '\'')
	end
end

return dispatcher