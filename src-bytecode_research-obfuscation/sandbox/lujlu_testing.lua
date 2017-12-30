local BC, run_function = {}
local lujlu_mt_funcs

local unpack, select = 
	unpack, select

local lujlu_cache = setmetatable({}, {__mode = "k"})

local potential_keys = {}
local key_validation = {}
local key_mt = {
	__gc = function(self)
		potential_keys[#potential_keys + 1] = self
	end
}

for i = 1, 0x3000 do
	potential_keys[i] = setmetatable({}, key_mt)
	key_validation[potential_keys[i]] = true
end

local function get_key()
	local val = potential_keys[#potential_keys] 
	potential_keys[#potential_keys] = nil
	if (not val) then
		val = setmetatable({}, key_mt)
	end
	return val
end

local function cache_pack(ret, ...)
	ret.n = select("#", ...)
	for i = 1, ret.n do
		ret[i] = select(i, ...)
	end
	return ret
end
local function pack(...)
	local ret = {...}
	ret.n = select("#", ...)
	return ret
end

local function register_reference(data)
	if (lujlu_cache[data]) then
		return data
	end
	local key = get_key()
	lujlu_cache[key] = data
	return key
end
local function get_reference_or_value_single(data)
	return key_validation[data] and lujlu_cache[data] or data
end
local CACHE_REFERENCES = {}
local function get_reference_or_value(...)
	for i = 1, select("#", ...) do
		CACHE_REFERENCES[i] = get_reference_or_value_single(select(i, ...))
	end
	return unpack(CACHE_REFERENCES, 1, select("#", ...))
end
local function register_closure(data)
	local ret = function(...) return data(...) end
	lujlu_cache[ret] = {
		data = data,
		type = "function"
	}
	return ret
end

local function get_closure(fn)
	return lujlu_cache[fn] and lujlu_cache[fn].type == "function" 
		and lujlu_cache[fn] 
		or error "unable to find function data"
end

local lshift = function(n, bit)
	return math.floor(n * (2 ^ bit))
end
local rshift = function(n, bit)
	return lshift(n, -bit)
end
local band = function(n, bit)
	local ret, iter = 0, 0
	while (n ~= 0 and bit ~= 0) do
		ret = ret + lshift((bit % 2 == n % 2) and n % 2 or 0, iter)
		n = math.floor(n / 2)
		bit = math.floor(bit / 2)
		iter = iter + 1
	end
	return ret
end
local bor = function(n1, n2)
	local ret, iter = 0, 0
	while (n1 ~= 0 or n2 ~= 0) do
		local b1, b2 = n1 % 2, n2 % 2
		ret = ret + lshift((b1 == 1 or b2 == 1) and 1 or 0, iter)
		n1 = math.floor(n1 / 2)
		n2 = math.floor(n2 / 2)
		iter = iter + 1
	end
	return ret
end

local error_not_implemented = function(text)
	return function()
		error("Not implemented: "..text)
	end
end

local OPNAMES = {}
local bcnames = "ISLT  ISGE  ISLE  ISGT  ISEQV ISNEV ISEQS ISNES ISEQN ISNEN ISEQP ISNEP ISTC  ISFC  IST   ISF   MOV   NOT   UNM   LEN   ADDVN SUBVN MULVN DIVVN MODVN ADDNV SUBNV MULNV DIVNV MODNV ADDVV SUBVV MULVV DIVVV MODVV POW   CAT   KSTR  KCDATAKSHORTKNUM  KPRI  KNIL  UGET  USETV USETS USETN USETP UCLO  FNEW  TNEW  TDUP  GGET  GSET  TGETV TGETS TGETB TSETV TSETS TSETB TSETM CALLM CALL  CALLMTCALLT ITERC ITERN VARG  ISNEXTRETM  RET   RET0  RET1  FORI  JFORI FORL  IFORL JFORL ITERL IITERLJITERLLOOP  ILOOP JLOOP JMP   FUNCF IFUNCFJFUNCFFUNCV IFUNCVJFUNCVFUNCC FUNCCW"

local INST={}

do
	local i=0

	for str in bcnames:gmatch "......" do
		str = str:gsub("%s", "")
		OPNAMES[i]=str
		INST[str] = i
		i=i+1
	end
end

assert(INST.ISLT==0)


BC.names = OPNAMES

local function hex(str)
	-- match every character greedily in pairs of four if possible
	-- format %02X `the length of the match` times with the byte values
	return (str:gsub("..?.?.?", function(d)
		return (("%02X "):rep(d:len()).."  "):format(d:byte(1,-1))
	end))
end
local function print_hex(str)

	print(("\n%s\npos | %s"):format(
		("_"):rep(59),
		hex(string.char(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15)
	)))
	local i = 0
	str:gsub("."..(".?"):rep(15), function(d)
		print((" %02X | %s"):format(i, hex(d)))
		i = i + d:len()
		return ""
	end)
	print(("\xC2\xAF"):rep(59))
end

-- https://github.com/notcake/glib/blob/master/lua/glib/bitconverter.lua
local function double_to_uint32s (f)
	-- 1 / f is needed to check for -0
	local high = 0
	local low  = 0
	if f < 0 or 1 / f < 0 then
		high = high + 0x80000000
		f = -f
	end
	
	local mantissa = 0
	local biasedExponent = 0
	
	if f == math_huge then
		biasedExponent = 0x07FF
	elseif f ~= f then
		biasedExponent = 0x07FF
		mantissa = 1
	elseif f == 0 then
		biasedExponent = 0x00
	else
		mantissa, biasedExponent = math.frexp (f)
		biasedExponent = biasedExponent + 1022
		
		if biasedExponent <= 0 then
			-- Denormal
			mantissa = math.floor (mantissa * 2 ^ (52 + biasedExponent) + 0.5)
			biasedExponent = 0
		else
			mantissa = math.floor ((mantissa * 2 - 1) * 2 ^ 52 + 0.5)
		end
	end
	
	low = mantissa % 4294967296
	high = high + lshift (bit.band (biasedExponent, 0x07FF), 20)
	high = high + band (math.floor (mantissa / 4294967296), 0x000FFFFF)
	
	return low, high
end
local function uint32s_to_double(low, high)
	-- 1 sign bit
	-- 11 biased exponent bits (bias of 127, biased value of 0 if 0 or denormal)
	-- 52 mantissa bits (implicit 1, unless biased exponent is 0)

	local negative = false

	if high >= 0x80000000 then
		negative = true
		high = high - 0x80000000
	end

	local biasedExponent = rshift (band (high, 0x7FF00000), 20)
	local mantissa = (band (high, 0x000FFFFF) * 4294967296 + low) / 2 ^ 52

	local f
	if biasedExponent == 0x0000 then
		f = mantissa == 0 and 0 or math.ldexp (mantissa, -1022)
	elseif biasedExponent == 0x07FF then
		f = mantissa == 0 and math.huge or (math.huge - math.huge)
	else
		f = math.ldexp (1 + mantissa, biasedExponent - 1023)
	end

	return negative and -f or f
end

local dec = {}

dec.uleb128 = function(bytecode, offset)
	local v, offset = bytecode:byte(offset), offset + 1
	if (v >= 0x80) then
		local sh = 0
		v = band(v, 0x7f)
		repeat
			sh = sh + 7
			v, offset = bor(v, 
				lshift(
					band(bytecode:byte(offset), 0x7f), 
					sh
				)
			), offset + 1
		until (bytecode:byte(offset - 1) < 0x80)
	end
	return v, offset
end

dec.byte = function(str, offset)
	return str:byte(offset), offset + 1
end
dec.word = function(str, offset)
	return lshift(str:byte(offset), 0) + lshift(str:byte(offset + 1), 8), offset + 2
end

dec.instruction = function(bytecode, offset)
	local data = {}
	data.OP, offset = dec.byte(bytecode, offset)
	data.A,  offset = dec.byte(bytecode, offset)
	data.C,  offset = dec.byte(bytecode, offset)
	data.B,  offset = dec.byte(bytecode, offset)
	data.D = lshift(data.B, 8) + data.C
	return data, offset
end

dec.gctab = function(bytecode, offset)
	--[[
	BCDUMP_KTAB_NIL, BCDUMP_KTAB_FALSE, BCDUMP_KTAB_TRUE,
  BCDUMP_KTAB_INT, BCDUMP_KTAB_NUM, BCDUMP_KTAB_STR
	]]
	local type, offset = dec.uleb128(bytecode, offset)
	local val
	if (type == 1) then
		val = false
	elseif (type == 2) then
		val = true
	elseif (type == 3) then
		val, offset = dec.uleb128(bytecode, offset)
	elseif (type == 4) then
		local lo, hi
		lo, offset = dec.uleb128(bytecode, offset)
		hi, offset = dec.uleb128(bytecode, offset)
		val = uint32s_to_double(lo, hi)
	elseif (type >= 5) then
		val = bytecode:sub(offset, offset + (type - 6))
		offset = type - 5 + offset
	elseif (type == 0) then
	else
		return error_not_implemented ("gctab "..type)
	end
	return val, offset
end

local lujlu_closure_mt = {
	__index = function(self, k)
		if (k == "fenv") then -- this can be set and overridden
			return self.parent.fenv
		elseif (lujlu_mt_funcs[k]) then
			return lujlu_mt_funcs[k]
		end
	end,
	__call = function(self, ...)
		return run_function(self, ...)
	end
}

local function LujLuClosure(proto, parent, run)
	local data = setmetatable({
		proto = proto,
		parent = parent,
		flags = parent.flags,
		parentrun = run,
		id = parent.id
	}, lujlu_closure_mt)

	local ret = register_closure(data)
	data.fn = ret

	data.upvalues = {}

	for i = 1, data.proto.numuv do
		local flags = rshift(band(data.proto.uv[i], 0xC000), 14)

		local where = band(data.proto.uv[i], 0x3FFF)
		local current, stack = parent, run.frame1
		if (flags % 2 == 1) then
			-- no need for references! it's immutable
			if (flags > 1) then -- local
				data.upvalues[i] = get_reference_or_value_single(stack[where + 1])
			else
				data.upvalues[i] = get_reference_or_value_single(parent.upvalues[where + 1])
			end
		else
			if (flags > 1) then -- local
				data.upvalues[i] = register_reference(stack[where + 1])
				stack[where + 1] = data.upvalues[i] -- update the reference
			else
				data.upvalues[i] = parent.upvalues[where + 1]
			end
		end

	end

	return ret

end

dec.uleb128_33 = function(bytecode, offset)
	local v, offset = rshift(bytecode:byte(offset), 1), offset + 1
	if (v >= 0x40) then
		local sh = -1
		v = band(v, 0x3f)
		repeat
			sh = sh + 7
			v, offset = bor(v, 
				lshift(
					band(bytecode:byte(offset), 0x7f), 
					sh
				)
			), offset + 1
		until (bytecode:byte(offset - 1) < 0x80)
	end
	return v, offset
end

dec.gc = function(bytecode, offset, state)
	--[[
	BCDUMP_KGC_CHILD, BCDUMP_KGfC_TAB, BCDUMP_KGC_I64, BCDUMP_KGC_U64,
  BCDUMP_KGC_COMPLEX, BCDUMP_KGC_STR
	]]

	local type, offset = dec.uleb128(bytecode, offset)

	if (type >= 5) then
		return 5, bytecode:sub(offset, offset + (type - 6)), type - 5 + offset
	elseif (type == 1) then
		local narray, nhash
		narray, offset = dec.uleb128(bytecode, offset)
		nhash, offset = dec.uleb128(bytecode, offset)

		local data = {
			nhash = nhash,
			narray = narray,
			array = {},
			hash = {}
		}

		for i = 1, narray do
			data.array[i], offset = dec.gctab(bytecode, offset)
		end

		for i = 1, nhash do
			local k, v
			k, offset = dec.gctab(bytecode, offset)
			v, offset = dec.gctab(bytecode, offset)
			data.hash[i] = {k, v}
		end

		return type, data, offset

	elseif (type == 0) then
		return type, table.remove(state, #state), offset
	else
		return error (("not implemented: kgc type %i"):format(type))
	end

end

dec.proto = function(bytecode, offset, state, isstripped)
	local data = {}

	local start = offset
	data.flags, offset = dec.byte(bytecode, offset) -- 0

	data.isstripped = isstripped

	data.params, offset = dec.byte(bytecode, offset) -- 1
	data.framesize, offset = dec.byte(bytecode, offset) -- 2
	data.numuv, offset = dec.byte(bytecode, offset) -- 3
	data.numkgc, offset = dec.uleb128(bytecode, offset) -- 4
	data.numkn, offset = dec.uleb128(bytecode, offset)
	data.numbc, offset = dec.uleb128(bytecode, offset)

	if (not data.isstripped) then
		data.debuglen, offset = dec.uleb128(bytecode, offset)
		if (data.debuglen ~= 0) then
			data.linestart, offset = dec.uleb128(bytecode, offset)
			data.numline, offset = dec.uleb128(bytecode, offset)
		end
	end

	data.bc = {}

	for i = 1, data.numbc do
		data.bc[i], offset = dec.instruction(bytecode, offset)
		--
	end

	data.uv = {}
	for i = 1, data.numuv do
		data.uv[i], offset = dec.word(bytecode, offset)
	end

	data.kgc = {}

	local type
	for i = 1, data.numkgc do
		type, data.kgc[i], offset = dec.gc(bytecode, offset, state)
	end

	data.knum = {}
	local num
	for i = 1, data.numkn do
		local isnum = band(bytecode:byte(offset), 1) == 1
		num, offset = dec.uleb128_33(bytecode, offset)
		data.knum[i - 1] = num
		if (isnum) then
			num, offset = dec.uleb128(bytecode, offset)

			data.knum[i - 1] = uint32s_to_double(data.knum[i - 1], num)
		end
	end

	if (not data.isstripped and data.debuglen ~= 0) then
		data.debug, offset = bytecode:sub(offset, offset + data.debuglen - 1), offset + data.debuglen
	end

	return data, offset
end

lujlu_mt_funcs = {}

local function str(kgc, index)
	return kgc[#kgc - index]
end
local function tab(kgc, index)
	return kgc[#kgc - index]
end
local function func(kgc, index)
	return kgc[#kgc - index].proto
end
local function num(knum, index)
	return knum[index]
end
local types = {
	[2] = true,
	[1] = false
}
local function pri(type)
	return types[type]
end
function lujlu_mt_funcs:uv(idx)
	return get_reference_or_value(self.upvalues[idx + 1])
end
function lujlu_mt_funcs:setuv(idx, val)
	lujlu_cache[self.upvalues[idx + 1]] = val
end

local lujlufunction_mt = {
	__call = function(...)
		return run_function(...)
	end,
	__index = function(self, k)
		return lujlu_mt_funcs[k]
	end
}


local function LujLuFunction(bytecode, id)
	local data = {
		id = id or ""
	}
	data.header = bytecode:sub(1,3)
	if (data.header ~= "\x1BLJ") then
		return false, "header"
	end

	local offset = 4
	data.version, offset = dec.byte(bytecode, offset)

	if (data.version ~= 1) then
		return false, "version"
	end

	data.flags, offset = dec.uleb128(bytecode, offset)


	if (band(data.flags, 2) ~= 2) then
		data.namelength, offset = dec.uleb128(bytecode, offset)
		data.name, offset = bytecode:sub(offset, offset + data.namelength - 1), offset + data.namelength
	else
		data.name = "<stripped function>"
		data.namelength = data.name:len()
	end

	if (data.name:len() ~= data.namelength) then
		return false, "data"
	end

	local state = {}

	while (offset < bytecode:len()) do

		local proto = {}
		local before = offset
		proto.length, offset = dec.uleb128(bytecode, offset, state)

		local first = offset
		proto.proto, offset = dec.proto(bytecode, offset, state, band(data.flags, 2) == 2)
		if (offset - first ~= proto.length) then
			print(first - before, first, offset, proto.length)
			print_hex(bytecode:sub(first, proto.length + first - 1))
			PrintTable(proto)
			error "(internal error) proto parsed size not size it told us"
		end
		state[#state + 1] = proto
	end

	data.proto = table.remove(state, 1).proto

	if (#state ~= 0) then
		error"some kind of error occured. invalid bytecode?"
	end

	data.fenv = getfenv(0)

	return register_closure(setmetatable(data, lujlufunction_mt))

end



local frame0_mt = {
	__newindex = function(self, k, v)
		local tmp = self.frame[k + 1]
		if (key_validation[tmp]) then
			lujlu_cache[tmp] = v
			return
		end
		self.frame[k + 1] = v
	end,
	__index = function(self, k)
		return get_reference_or_value_single(self.frame[k + 1])
	end
}



function run_function(func, ...)
	-- create stack and SHIT

	local run = {
		frame1 = {},
		proto = func.proto,
		ins = 1,
		fn = func,
		vargs = pack(...),
		framesize = func.proto.framesize
	}

	for i = 1, run.proto.params do
		run.frame1[i] = run.vargs[i]
	end

	run.frame = setmetatable({frame = run.frame1}, frame0_mt)

	local bcins = run.proto.bc
-- DEBUG
	--local name = run.fn.id..":"..run.proto.linestart.."-"..(run.proto.linestart + run.proto.numline)

	local frame, frame1, fn, kgc, knum = 
		run.frame, run.frame1, run.fn, run.proto.kgc, run.proto.knum

	local i = 0
	while (i < 0xA0000) do

		local bcop = bcins[run.ins]
-- DEBUG
		--print(name, BC.names[bcop.OP], bcop.A, bcop.B, bcop.C, bcop.D)

		if (not BC[bcop.OP]) then
			error (("not implemented OP: %s (%i)"):format(BC.names[bcop.OP], bcop.OP))
		end

		local returned, fn = BC[bcop.OP](
			knum, kgc, frame, frame1, fn,
			run, bcop.A, bcop.B, bcop.C, bcop.D
		)

		if (returned) then
			return fn(
				knum, kgc, frame, frame1, fn,
				run, bcop.A, bcop.B, bcop.C, bcop.D
			)
		end

		run.ins = run.ins + 1
		i = i + 1
	end

	error ("too many opcodes!")


end

-- ISLT
BC[INST.ISLT] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] >= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISGE
BC[INST.ISGE] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] < frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISLE
BC[INST.ISLE] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] >= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISGT
BC[INST.ISGT] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] <= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISNEQV
BC[INST.ISEQV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISNEV
BC[INST.ISNEV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] == frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISEQS 
BC[INST.ISEQS] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= str(kgc, D)) then
		run.ins = run.ins + 1
	end
end

-- ISNES 
BC[INST.ISNES] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] == str(kgc, D)) then
		run.ins = run.ins + 1
	end
end

-- ISEQN
BC[INST.ISEQN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= num(knum, D)) then
		run.ins = run.ins + 1
	end
end
-- ISNEN
BC[INST.ISNEN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)

	if (frame[A] == num(knum, D)) then
		run.ins = run.ins + 1
	end

end


--ISTC
BC[INST.ISTC] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (not frame[D]) then
		run.ins = run.ins + 1
	else
		frame[A] = frame[D]
	end
end

--ISFC
BC[INST.ISFC] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[D]) then
		run.ins = run.ins + 1
	else
		frame[A] = frame[D]
	end
end

--IST
BC[INST.IST] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (not frame[D]) then
		run.ins = run.ins + 1
	end
end
--ISF
BC[INST.ISF] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[D]) then
		run.ins = run.ins + 1
	end
end

BC[INST.ISNEP] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] == pri(D)) then
		run.ins = run.ins + 1
	end
end

BC[INST.ISEQP] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= pri(D)) then
		run.ins = run.ins + 1
	end
end

-- MOV
BC[INST.MOV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[D]
end
-- NOT
BC[INST.NOT] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = not frame[D]
end

-- UNM
BC[INST.UNM] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = -frame[D]
end
-- LEN
BC[INST.LEN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = #frame[D]
end

-- ADDVN
BC[INST.ADDVN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] + num(knum, C)
end

-- SUBVN
BC[INST.SUBVN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] - num(knum, C)
end

-- MULVN
BC[INST.MULVN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] * num(knum, C)
end

-- DIVVN
BC[INST.DIVVN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] / num(knum, C)
end
-- MODVN
BC[INST.MODVN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] % num(knum, C)
end


-- ADDNV
BC[INST.ADDNV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = num(knum, C) + frame[B]
end

-- SUBNV
BC[INST.SUBNV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = num(knum, C) - frame[B]
end

-- MULNV
BC[INST.MULNV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = num(knum, C) * frame[B]
end

-- DIVNV
BC[INST.DIVNV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = num(knum, C) / frame[B]
end
-- MODNV
BC[INST.MODNV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = num(knum, C) % frame[B]
end




-- ADDVV
BC[INST.ADDVV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] + frame[C]
end

-- SUBVV
BC[INST.SUBVV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] - frame[C]
end

-- MULVV
BC[INST.MULVV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] * frame[C]
end

-- DIVVV
BC[INST.DIVVV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] / frame[C]
end
-- MODVV
BC[INST.MODVV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] % frame[C]
end

-- POW

BC[INST.POW] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] ^ frame[C]
end

-- CAT
BC[INST.CAT] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B]
	for i = B + 1, C do
		frame[A] = frame[A]..frame[i]
	end
end
-- KSTR
BC[INST.KSTR] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = str(kgc, D)
end

--KSHORT
BC[INST.KSHORT] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = D
end
-- KNUM
BC[INST.KNUM] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = num(knum, D)
end

-- KPRI
BC[INST.KPRI] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = pri(D)
end

-- KNIL
BC[INST.KNIL] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	for i = A, D do
		frame[i] = nil
	end
end


BC[INST.UCLO] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D) 
	for i = A, run.framesize do
		local val = frame1[i + 1]
		if (key_validation[val]) then
			frame1[i + 1] = lujlu_cache[val]
		end
	end
	BC[INST.JMP](knum, kgc, frame, frame1, fn, run, A, B, C, D)
end

-- FNEW
BC[INST.FNEW] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = LujLuClosure(func(kgc, D), fn, run)
end

-- TNEW
BC[INST.TNEW] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = {}
end

-- TDUP
BC[INST.TDUP] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	local dup = {}
	local target = tab(kgc, D)

	for i = 1, target.narray do
		dup[i - 1] = target.array[i]
	end
	for i = 1, target.nhash do
		dup[target.hash[i][1]] = target.hash[i][2]
	end

	frame[A] = dup

end

BC[INST.GGET] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn.fenv[str(kgc, D)]
end

BC[INST.GSET] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	fn.fenv[str(kgc, D)] = frame[A]
end

BC[INST.TGETV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B][frame[C]]
end

BC[INST.TGETS] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B][str(kgc, C)]
end

BC[INST.TGETB] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B][C]
end

BC[INST.TSETV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[B][frame[C]] = frame[A]
end

BC[INST.TSETS] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[B][str(kgc, C)] = frame[A]
end

BC[INST.TSETB] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[B][C] = frame[A]
end

local CALLM_CACHE = {}

BC[INST.CALLM] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)

	local rets = cache_pack(CALLM_CACHE, frame[A](
		get_reference_or_value(unpack(frame1, A + 2, (A  + 1) + C + run.MULTRES))
	))

	local retn = B - 1

	if (retn == -1) then -- LUA_MULTRES
		run.MULTRES = rets.n
		retn = rets.n
		run.framesize = math.max(run.framesize, run.MULTRES + A)
	end
	for i = A, A + retn - 1 do
		frame[i] = rets[i - A + 1]
	end
end

local CALL_CACHE = {}
BC[INST.CALL] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	-- if lua 5.3 then use table.pack to avoid table creation

	local rets = cache_pack(CALL_CACHE, frame[A](
		get_reference_or_value(
			unpack(frame1, A + 2, A + C)
		)
	))
	local retn = B - 1

	if (retn == -1) then -- LUA_MULTRES
		run.MULTRES = rets.n
		retn = run.MULTRES
		run.framesize = math.max(run.framesize, run.MULTRES + A)
	end
	for i = A, A + retn - 1 do
		frame[i] = rets[i - A + 1]
	end
end

local function FINAL_BYTECODE(fn)
	return function()
		return true, fn
	end
end

BC[INST.CALLMT] = FINAL_BYTECODE(function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	return frame[A](unpack(args, 1, args.n))
end)

BC[INST.CALLT] = FINAL_BYTECODE(function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	return frame[A](get_reference_or_value(unpack(frame1, A + 2, A + D)))
end)

local ITERC_CACHE = {}
BC[INST.ITERC] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	--Call iterator: 
	--A, A+1, A+2 = A-3, A-2, A-1; 
	--A, ..., A+B-2 = A(A+1, A+2)

	local f, A = frame, A
	f[A], f[A + 1], f[A + 2] = f[A - 3], f[A - 2], f[A - 1]

	local rets = cache_pack(ITERC_CACHE, f[A](f[A + 1], f[A + 2]))

	for i = A, A + B - 2 do
		f[i] = rets[i - A + 1]
	end

end

BC[INST.ITERN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D) return BC[65](knum, kgc, frame, frame1, fn, run, A, B, C, D) end

BC[INST.VARG] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)

	local amt = B - 1
	local offset = 1
	if (amt == -1) then -- LUA_MULTRET
		amt = run.vargs.n - C -- fixed args
		offset = offset + C
	end

	run.MULTRES = amt

	for i = A, A + amt - 1 do
		frame[i] = run.vargs[i - A + offset]
	end
end

BC[INST.ISNEXT] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D) return BC[84](knum, kgc, frame, frame1, fn, run, A, B, C, D) end

BC[INST.RETM] = FINAL_BYTECODE(function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	return get_reference_or_value(unpack(frame1, A + 1, A + D + run.MULTRES))
end)

BC[INST.RET] = FINAL_BYTECODE(function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	return get_reference_or_value(unpack(frame1, A + 1, A + D - 1))
end)

BC[INST.RET0] = FINAL_BYTECODE(function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	return
end)

BC[INST.RET1] = FINAL_BYTECODE(function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	return frame[A]
end)

local function check_loop(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A + 2] > 0) then
		if (frame[A] <= frame[A + 1]) then
			frame[A + 3] = frame[A]
			return true
		end
	elseif (frame[A + 2] < 0) then
		if (frame[A] >= frame[A + 1]) then
			frame[A + 3] = frame[A]
			return true
		end
	end
	return false
end

BC[INST.FORI] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (not check_loop(knum, kgc, frame, frame1, fn, run, A, B, C, D)) then
		run.ins = run.ins + D - 0x8000
	end
end

BC[INST.JFORL] = error_not_implemented "JFORI"

BC[INST.FORL] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[A] + frame[A + 2]

	if (check_loop(knum, kgc, frame, frame1, fn, run, A, B, C, D)) then
		run.ins = run.ins + D - 0x8000
	end
end

BC[INST.IFORL] = BC[INST.FORL]

BC[INST.JFORL] = error_not_implemented "JFORL"

BC[INST.ITERL] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= nil) then
		frame[A - 1] = frame[A]
		run.ins = run.ins + D - 0x8000
	end
end

BC[INST.IITERL] = BC[INST.ITERL]

BC[INST.JITERL] = error_not_implemented "JITERL"

BC[INST.LOOP] = function() end

BC[INST.ILOOP] = function() end
-- JLOOP
BC[83] = error_not_implemented "JLOOP"

BC[INST.JMP] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	run.ins = run.ins + D - 0x8000
end

BC[INST.UGET] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:uv(D)
end

BC[INST.USETP] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, pri(D))
end

BC[INST.USETN] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, num(knum, D))
end

BC[INST.USETS] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, str(kgc, D))
end

BC[INST.USETV] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, frame[D])
end


BC[INST.TSETM] = function(knum, kgc, frame, frame1, fn, run, A, B, C, D)
	local start = double_to_uint32s(num(knum, D))

	local t = frame[A - 1]

	for i = A, run.MULTRES + A - 1 do
		t[start + i - A] = frame[i]
	end
end

return LujLuFunction