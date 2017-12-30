local bytecodes = {}
local BC, run_function = {}
local VARG_CONST = {}
local lujlu_mt_funcs

local lujlu_cache = setmetatable({}, {__mode = "k"})
local lujlu_identifier_mt = {
	__tostring = function(self) 
		return tostring(lujlu_cache[self].data)
	end,
	__index = function(self)
		error("read lujlu_identifier index")
	end,
	__newindex = function(self)
		error("set lujlu_identifier index")
	end,
}

local function pack(...)
	local ret = {...}
	ret.n = select("#", ...)
	return ret
end

local function register_reference(data)
	if (lujlu_cache[data]) then
		return data
	end
	local key = setmetatable({}, lujlu_identifier_mt)
	lujlu_cache[key] = {
		data = data,
		type = "reference"
	}
	return key
end
local function get_reference_or_value_single(data)
	if (data == data and lujlu_cache[data] and lujlu_cache[data].type == "reference") then
		return lujlu_cache[data].data
	end
	return data
end
local function get_reference_or_value(...)
	local args = pack(...)
	for i = 1, args.n do
		args[i] = get_reference_or_value_single(args[i])
	end
	return unpack(args, 1, args.n)
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

function lujlu_mt_funcs:str(index)
	return self.proto.kgc[#self.proto.kgc - index]
end
function lujlu_mt_funcs:tab(index)
	return self.proto.kgc[#self.proto.kgc - index]
end
function lujlu_mt_funcs:func(index)
	return self.proto.kgc[#self.proto.kgc - index].proto
end
function lujlu_mt_funcs:num(index)
	return self.proto.knum[index]
end
local types = {
	[2] = true,
	[1] = false
}
function lujlu_mt_funcs:pri(type)
	return types[type]
end
function lujlu_mt_funcs:uv(idx)
	return get_reference_or_value(self.upvalues[idx + 1])
end
function lujlu_mt_funcs:setuv(idx, val)
	lujlu_cache[self.upvalues[idx + 1]].data = val
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
		if (tmp == tmp and get_reference_or_value(tmp) ~= tmp) then
			lujlu_cache[tmp].data = v
			return
		end
		self.frame[k + 1] = v
	end,
	__index = function(self, k)
		return get_reference_or_value(self.frame[k + 1])
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

	local name = run.fn.id..":"..run.proto.linestart.."-"..(run.proto.linestart + run.proto.numline)

	local i = 0
	while (i < 0xA0000) do

		local bcop = bcins[run.ins]

		--print(name, BC.names[bcop.OP], bcop.A, bcop.B, bcop.C, bcop.D)

		if (not BC[bcop.OP]) then
			error (("not implemented OP: %s (%i)"):format(BC.names[bcop.OP], bcop.OP))
		end

		local returned, returns = BC[bcop.OP](
			run.frame, run.frame1, run.fn,
			run, bcop.A, bcop.B, bcop.C, bcop.D
		)

		if (returned) then
			return unpack(returns, 1, returns.n)
		end

		run.ins = run.ins + 1
		i = i + 1
	end

	error ("too many opcodes!")


end

-- ISLT
BC[INST.ISLT] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] >= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISGE
BC[INST.ISGE] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] < frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISLE
BC[INST.ISLE] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] >= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISGT
BC[INST.ISGT] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] <= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISNEQV
BC[INST.ISEQV] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISNEV
BC[INST.ISNEV] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] == frame[D]) then
		run.ins = run.ins + 1
	end
end

-- ISEQS 
BC[INST.ISEQS] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= fn:str(D)) then
		run.ins = run.ins + 1
	end
end

-- ISNES 
BC[INST.ISNES] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] == fn:str(D)) then
		run.ins = run.ins + 1
	end
end

-- ISEQN
BC[INST.ISEQN] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= fn:num(D)) then
		run.ins = run.ins + 1
	end
end
-- ISNEN
BC[INST.ISNEN] = function(frame, frame1, fn, run, A, B, C, D)

	if (frame[A] == fn:num(D)) then
		run.ins = run.ins + 1
	end

end


--ISTC
BC[INST.ISTC] = function(frame, frame1, fn, run, A, B, C, D)
	if (not frame[D]) then
		run.ins = run.ins + 1
	else
		frame[A] = frame[D]
	end
end

--ISFC
BC[INST.ISFC] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[D]) then
		run.ins = run.ins + 1
	else
		frame[A] = frame[D]
	end
end

--IST
BC[INST.IST] = function(frame, frame1, fn, run, A, B, C, D)
	if (not frame[D]) then
		run.ins = run.ins + 1
	end
end
--ISF
BC[INST.ISF] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[D]) then
		run.ins = run.ins + 1
	end
end

BC[INST.ISNEP] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] == fn:pri(D)) then
		run.ins = run.ins + 1
	end
end

BC[INST.ISEQP] = function(frame, frame1, fn, run, A, B, C, D)
	if (frame[A] ~= fn:pri(D)) then
		run.ins = run.ins + 1
	end
end

-- MOV
BC[INST.MOV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[D]
end
-- NOT
BC[INST.NOT] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = not frame[D]
end

-- UNM
BC[INST.UNM] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = -frame[D]
end
-- LEN
BC[INST.LEN] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = #frame[D]
end

-- ADDVN
BC[INST.ADDVN] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] + fn:num(C)
end

-- SUBVN
BC[INST.SUBVN] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] - fn:num(C)
end

-- MULVN
BC[INST.MULVN] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] * fn:num(C)
end

-- DIVVN
BC[INST.DIVVN] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] / fn:num(C)
end
-- MODVN
BC[INST.MODVN] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] % fn:num(C)
end


-- ADDNV
BC[INST.ADDNV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:num(C) + frame[B]
end

-- SUBNV
BC[INST.SUBNV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:num(C) - frame[B]
end

-- MULNV
BC[INST.MULNV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:num(C) * frame[B]
end

-- DIVNV
BC[INST.DIVNV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:num(C) / frame[B]
end
-- MODNV
BC[INST.MODNV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:num(C) % frame[B]
end




-- ADDVV
BC[INST.ADDVV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] + frame[C]
end

-- SUBVV
BC[INST.SUBVV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] - frame[C]
end

-- MULVV
BC[INST.MULVV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] * frame[C]
end

-- DIVVV
BC[INST.DIVVV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] / frame[C]
end
-- MODVV
BC[INST.MODVV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] % frame[C]
end

-- POW

BC[INST.POW] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B] ^ frame[C]
end

-- CAT
BC[INST.CAT] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B]
	for i = B + 1, C do
		frame[A] = frame[A]..frame[i]
	end
end
-- KSTR
BC[INST.KSTR] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:str(D)
end

--KSHORT
BC[INST.KSHORT] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = D
end
-- KNUM
BC[INST.KNUM] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:num(D)
end

-- KPRI
BC[INST.KPRI] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:pri(D)
end

-- KNIL
BC[INST.KNIL] = function(frame, frame1, fn, run, A, B, C, D)
	for i = A, D do
		frame[i] = nil
	end
end


BC[INST.UCLO] = function(frame, frame1, fn, run, A, B, C, D) 
	for i = A, run.framesize do
		local val = frame1[i + 1]
		if (val == val and val ~= get_reference_or_value_single(val)) then
			frame1[i + 1] = get_reference_or_value_single(val)
		end
	end
	BC[INST.JMP](frame, frame1, fn, run, A, B, C, D)
end

-- FNEW
BC[INST.FNEW] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = LujLuClosure(fn:func(D), fn, run)
end

-- TNEW
BC[INST.TNEW] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = {}
end

-- TDUP
BC[INST.TDUP] = function(frame, frame1, fn, run, A, B, C, D)
	local dup = {}
	local target = fn:tab(D)

	for i = 1, target.narray do
		dup[i - 1] = target.array[i]
	end
	for i = 1, target.nhash do
		dup[target.hash[i][1]] = target.hash[i][2]
	end

	frame[A] = dup

end

BC[INST.GGET] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn.fenv[fn:str(D)]
end

BC[INST.GSET] = function(frame, frame1, fn, run, A, B, C, D)
	fn.fenv[fn:str(D)] = frame[A]
end

BC[INST.TGETV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B][frame[C]]
end

BC[INST.TGETS] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B][fn:str(C)]
end

BC[INST.TGETB] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[B][C]
end

BC[INST.TSETV] = function(frame, frame1, fn, run, A, B, C, D)
	frame[B][frame[C]] = frame[A]
end

BC[INST.TSETS] = function(frame, frame1, fn, run, A, B, C, D)
	frame[B][fn:str(C)] = frame[A]
end

BC[INST.TSETB] = function(frame, frame1, fn, run, A, B, C, D)
	frame[B][C] = frame[A]
end

BC[INST.CALLM] = function(frame, frame1, fn, run, A, B, C, D)
	-- if lua 5.3 then use table.pack to avoid table creation
	local args = pack(get_reference_or_value(unpack(frame1, A + 2, (A  + 1) + C + run.MULTRES)))

	local rets = pack(frame[A](unpack(args, 1, args.n)))

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

BC[INST.CALL] = function(frame, frame1, fn, run, A, B, C, D)
	-- if lua 5.3 then use table.pack to avoid table creation

	local rets = pack(frame[A](
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

BC[INST.CALLMT] = function(frame, frame1, fn, run, A, B, C, D)
	-- if lua 5.3 then use table.pack
	local args = pack(get_reference_or_value(unpack(frame1, A + 2, (A + 1) + D + run.MULTRES)))

	return true, pack(frame[A](unpack(args, 1, args.n)))
end

BC[INST.CALLT] = function(frame, frame1, fn, run, A, B, C, D)
	return true, pack(frame[A](get_reference_or_value(unpack(frame1, A + 2, A + D))))
end

BC[INST.ITERC] = function(frame, frame1, fn, run, A, B, C, D)
	--Call iterator: 
	--A, A+1, A+2 = A-3, A-2, A-1; 
	--A, ..., A+B-2 = A(A+1, A+2)

	local f, A = frame, A
	f[A], f[A + 1], f[A + 2] = f[A - 3], f[A - 2], f[A - 1]

	local rets = pack(f[A](f[A + 1], f[A + 2]))

	for i = A, A + B - 2 do
		f[i] = rets[i - A + 1]
	end

end

BC[INST.ITERN] = function(frame, frame1, fn, run, A, B, C, D) return BC[65](frame, frame1, fn, run, A, B, C, D) end

BC[INST.VARG] = function(frame, frame1, fn, run, A, B, C, D)

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

BC[INST.ISNEXT] = function(frame, frame1, fn, run, A, B, C, D) return BC[84](frame, frame1, fn, run, A, B, C, D) end

BC[INST.RETM] = function(frame, frame1, fn, run, A, B, C, D)
	rets = pack(get_reference_or_value(unpack(frame1, A + 1, A + D + run.MULTRES)))
	return true, rets
end

BC[INST.RET] = function(frame, frame1, fn, run, A, B, C, D)
	return true, pack(get_reference_or_value(unpack(frame1, A + 1, A + D - 1)))
end

BC[INST.RET0] = function(frame, frame1, fn, run, A, B, C, D)
	return true, {}
end

BC[INST.RET1] = function(frame, frame1, fn, run, A, B, C, D)
	return true, pack(frame[A])
end

local function check_loop(frame, frame1, fn, run, A, B, C, D)
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

BC[INST.FORI] = function(frame, frame1, fn, run, A, B, C, D)
	if (not check_loop(frame, frame1, fn, run, A, B, C, D)) then
		run.ins = run.ins + D - 0x8000
	end
end

BC[INST.JFORL] = error_not_implemented "JFORI"

BC[INST.FORL] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = frame[A] + frame[A + 2]

	if (check_loop(frame, frame1, fn, run, A, B, C, D)) then
		run.ins = run.ins + D - 0x8000
	end
end

BC[INST.IFORL] = BC[INST.FORL]

BC[INST.JFORL] = error_not_implemented "JFORL"

BC[INST.ITERL] = function(frame, frame1, fn, run, A, B, C, D)
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

BC[INST.JMP] = function(frame, frame1, fn, run, A, B, C, D)
	run.ins = run.ins + D - 0x8000
end

BC[INST.UGET] = function(frame, frame1, fn, run, A, B, C, D)
	frame[A] = fn:uv(D)
end

BC[INST.USETP] = function(frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, fn:pri(D))
end

BC[INST.USETN] = function(frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, fn:num(D))
end

BC[INST.USETS] = function(frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, fn:str(D))
end

BC[INST.USETV] = function(frame, frame1, fn, run, A, B, C, D)
	fn:setuv(A, frame[D])
end


BC[INST.TSETM] = function(frame, frame1, fn, run, A, B, C, D)
	local start = double_to_uint32s(fn:num(D))

	local t = frame[A - 1]

	for i = A, run.MULTRES + A - 1 do
		t[start + i - A] = frame[i]
	end
end

return LujLuFunction