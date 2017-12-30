-- 'As expected Lua 5.2 ABI and bytecode is incompatible with 5.1.'
	-- http://lua-users.org/wiki/LuaFiveTwo
	-- f
	-- http://files.catwell.info/misc/mirror/lua-5.2-bytecode-vm-dirk-laurie/lua52vm.html

local usedNames = {}

local names = {'and', 'break', 'do', 'else', 'elseif',
    'end', 'false', 'for', 'function', 'goto', 'if',
    'in', 'local', 'nil', 'not', 'or', 'repeat',
    'return', 'then', 'true', 'until', 'while', '+', '-', '*', '/', '^', '%', ',', '{', '}', '[', ']', '(', ')', ';', '#', ' ', '\n', '\t', '\r', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '\\a', "[[", "]]", "--", "--[["}
-- names = {" "}


local compiler = require "metalua.compiler".new()

local process = function(code)
  local _function, message = pcall (loadstring, code)
  local ast = compiler:src_to_ast (code)
  local bytecode = compiler:ast_to_bytecode (ast)
  -- print (bytecode)
  -- loadstring (bytecode)()
  local disassembly = LAT.Lua51.Disassemble (bytecode)
  -- local disassembly = LAT.Disassemble (bytecode)
  -- table.foreach(disassembly.Main.Locals, print)
  disassembly = disassembly
  -- table.foreach(disassembly, print)
  local main = disassembly.Main
  -- table.foreach(main.Constants[1], print)
  -- main.Constants[1].Value = "Hi\0\"end"
  -- table.foreach(main.Instructions[1], print)
  for i = 0, main.Protos.Count - 1 do
  	main.Protos[i].ArgumentCount = 0
    main.Protos[i].LastLine = 0
    main.Protos[i].FirstLine = 0
    main.Protos[i].Name = 'z'
  end
  table.foreach(main.Protos[1], print)
  -- main.Protos[1].ArgumentCount = 0
  -- for i = 0, main.Constants.Count - 1 do -- numbers
  -- 	for i,v in pairs(main.Constants[i]) do
  -- 		print(i,v)
  -- 	end
  -- end
  for i = 0, main.Locals.Count - 1 do
    local variable = main.Locals[i]
    -- table.foreach(variable, print)
    local name = names[math.random(#names)]
    if usedNames[name] then 
      repeat 
        name = name .. " " .. names[math.random(#names)]
      until not usedNames[name]
    end
    usedNames[name] = true
    -- variable.Name = "<local$" .. --[[tostring(i) .. ]] ">_"
    -- variable.Name = tostring(i) .. math.random()
    variable.Name = name
  end
  -- os.exit()

	bytecode = disassembly:Compile (false) -- Don't verify chunk

  -- print (compiler:ast_to_bytecode (ast))
  -- loadstring (bytecode)()

  return bytecode
  -- return ' '
end

return process

-- assert (_function, 'Error compiling: ' .. tostring (message) )