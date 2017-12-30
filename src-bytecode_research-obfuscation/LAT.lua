-- LAT = Lua Assembly Tools

-- this file and the LAT_src dir
-- are taken from the LuaAssemblyTools
-- project at https://github.com/mlnlover11/LuaAssemblyTools
-- Used for obfuscating local variable names in precompiled chunks

package.path = "./?/init.lua;./lat_src/?.lua;" .. package.path
require'lat_src'
