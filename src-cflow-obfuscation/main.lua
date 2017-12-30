math.randomseed (os.time())

-- Gonzalez, J
-- Created 3-29-2017
-- control flow obfuscator for lua
-- credits: imnota4 (idea), stravant (parselua)

-- os.execute 'cls & clear'

local file_to_string = require 'util.file_to_string'
local create_ast     = require 'luaminify.ParseLua'.ParseLua
local obfuscate      = require 'noclooo.init'
local ast_to_code    = require 'luaminify.FormatBeautiful'

local default_script = file_to_string 'sandbox/whiletest.lua'

local code

if arg and arg[1] then
	code = file_to_string(arg[1])
	assert (code and #code > 0, "Could not read file from argument.")
else
  assert (default_script, "No argument or default script.")
code = default_script
end

local success, _, code = pcall (create_ast, code)
assert (success, table.concat {"Error generating AST; ", tostring(code)} )

success, code = pcall(obfuscate, code, {name = 'functions'})
assert (success, table.concat {"Error processing AST; ", tostring(code)} )

success, code, _ = pcall(ast_to_code, code)
assert (success, table.concat {"Error generating Lua; ", tostring(code)} )

print (code)