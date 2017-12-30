-- LAT = Lua Assembly Tools
package.path = "./?/init.lua;./src/?.lua;" .. package.path
package.path = "./lat/?/init.lua;./lat/src/?.lua;" .. package.path
require'src'
