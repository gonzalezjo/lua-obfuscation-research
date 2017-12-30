-- file_slurp.lua
-- (c) 2011-2012 David Manura.  Licensed under Lua 5.1 terms (MIT license).

local FS = {_TYPE='module', _NAME='file_slurp', _VERSION='0.4.2.20120406'}

local function check_options(options)
  if not options then return {} end
  local bad = options:match'[^tTsap]'
  if bad then error('ASSERT: invalid option '..bad, 3) end
  local t = {}; for v in options:gmatch'.' do t[v] = true end
  if t.T and t.t then error('ASSERT: options t and T mutually exclusive',3) end
  return t
end

local function fail(tops, err, code, filename)
  err = err..' [code '..code..']'
  err = err..' [filename '..filename..']' -- maybe make option
  if tops.s then return nil, err else error(err, 3) end
end

function FS.readfile(filename, options)
  local tops = check_options(options)
  local open = tops.p and io.popen or io.open
  local data, ok
  local fh, err, code = open(filename, 'r'..((tops.t or tops.p) and '' or 'b'))
  if fh then
    data, err, code = fh:read'*a'
    if data then ok, err, code = fh:close() else fh:close() end
  end
  if not ok then return fail(tops, err, code, filename) end
  if tops.T then data = data:gsub('\r', '') end
  return data
end

function FS.writefile(filename, data, options)
  local tops = check_options(options)
  local open = tops.p and io.popen or io.open
  local ok
  local fh, err, code = open(filename,
      (tops.a and 'a' or 'w') .. ((tops.t or tops.p) and '' or 'b'))
  if fh then
    ok, err, code = fh:write(data)
    if ok then ok, err, code = fh:close() else fh:close() end
  end
  if not ok then return fail(tops, err, code, filename) end
  return data
end

function FS.testfile(filename, options)
  local fh, err, code = io.open(filename, options or 'r')
  if fh then fh:close(); return true
  else return false, err .. ' [code '..code..']' end
end
  
return FS

-- Implementation footnotes: The (optional) stack `level` parameter on
-- functions like `error` and lack of automatic finalization (close) on scope
-- exit is less then elegant, but this module hides such details.
