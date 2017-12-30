print(_VERSION)
local long_message    = "This is a long string."
local short_message   = "short"
local numeric_message =  1

local records = {}
local function record(tag)
	local time = records[tag]
	if not time then
		records[tag] = os.clock()
	else
		local delta = os.clock() - time
		print (("Time for %s: %f"):format (tag, delta))
		records[tag] = nil
		return delta
	end
end

local md5_table  = require 'hash.md5stripped'

local md5sum 	 = md5_table.sum
local md5sum_hex = md5_table.sumhexa

record 'total length'

record 'short message'
for i = 1, 5 do
	md5sum_hex (short_message, 0xdeaddead)
end
record 'short message'

record 'long message'
for i = 1, 5 do
	md5sum_hex (short_message)
end
record 'long message'

record 'numeric message'
for i = 1, 5 do
	md5sum_hex (tostring(numeric_message))
end
record 'numeric message'

record 'random message'
for i = 1, 5 do
	md5sum_hex(tostring(math.random()))
end
record 'random message'

local time = record 'total length'
local hashes_per_second = 20 / time

print (("Total time: %f.\nHash rate: %f hashes per second."):format(time, hashes_per_second))
print ("Total hashes: 40000")