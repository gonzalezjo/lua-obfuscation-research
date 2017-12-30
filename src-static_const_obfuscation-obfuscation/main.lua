local file_to_string = require 'util.file_to_string'
local create_ast     = require 'luaminify.ParseLua'.ParseLua
local obfuscate      = require 'hyperopia.init'
local ast_to_code    = require 'luaminify.FormatBeautiful'

local hash_library   = file_to_string 'hyperopia/lib/md5.lua'
local default_script = file_to_string 'hyperopia/opt/default.lua'

local code

math.randomseed (os.time())

if arg and arg[1] then
	code = file_to_string (arg[1])
	assert (code and #code > 0, "Could not read file from argument.")
else
  assert (default_script, "No argument or default script.")
  code = default_script
end

local success, _, code = pcall (create_ast, code)
assert (success, table.concat {"Error generating AST; ", tostring (code)} )

success, code = pcall (obfuscate, code)
assert (success, table.concat {"Error processing AST; ", tostring (code)} )

success, code = pcall (ast_to_code, code)
assert (success, table.concat {"Error generating Lua; ", tostring (code)} )

code = ("%s\n%s"):format (hash_library, code)

print (code)
