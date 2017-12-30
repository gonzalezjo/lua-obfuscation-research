-- based on the example implementations from https://en.wikipedia.org/wiki/MurmurHash
-- bit = require('bit')
-- struct = require('struct')
local bit = require 'numberlua.numberlua'

c1 = 0xcc9e2d51
c2 = 0x1b873593
r1 = 15
r2 = 13
m = 5
n = 0xe6546b64

function multiply(x, y)
    -- this is required to emulate uint32 overflow correctly. otherwise, higher
    -- order bits are simply truncated and discarded
    return (bit.band(x, 0xffff) * y) + bit.lshift(bit.band(bit.rshift(x, 16) * y,  0xffff), 16)
end

function mmh3(key, seed)
    hash = bit.tobit(seed)
    remainder = #key % 4

    -- hash four-byte chunks
    for i = 1, #key - remainder, 4 do
        k = struct.unpack('<I4', key, i)
        k = multiply(k, c1)
        k = bit.rol(k, r1)
        k = multiply(k, c2)
        hash = bit.bxor(hash, k)
        hash = bit.rol(hash, r2)
        hash = multiply(hash, m) + n
    end

    -- process the remaining bytes
    if remainder ~= 0 then
        k1 = struct.unpack('<I' .. remainder, key, #key - remainder + 1)
        k1 = multiply(k1, c1)
        k1 = bit.rol(k1, r1)
        k1 = multiply(k1, c2)
        hash = bit.bxor(hash, k1)
    end

    -- finalize hash
    hash = bit.bxor(hash, #key)
    hash = bit.bxor(hash, bit.rshift(hash, 16))
    hash = multiply(hash, 0x85ebca6b)
    hash = bit.bxor(hash, bit.rshift(hash, 13))
    hash = multiply(hash, 0xc2b2ae35)
    hash = bit.bxor(hash, bit.rshift(hash, 16))

    -- convert the signed value to unsigned
    return tonumber(bit.tohex(hash), 16)
end

for i = 1, #arg do
    result = mmh3(arg[i], 0)
    print(arg[i], result, bit.tohex(result))
end

return mmh3