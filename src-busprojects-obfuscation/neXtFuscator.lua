-- _G.DEBUG_MODE_ENABLED = true
local DEBUG_MODE_ENABLED = true
local PRINT_RESULT = true
--[=[
TODO MAKE SURE THE CONSTANT POOL IS RANDOMLY SORTED
TODO MAKE SURE THE CONSTANT POOL IS RANDOMLY SORTED
or make multiple constant tables
if i randomly sort it, adding a string for everything ine api dump would be F R E A K I NG hot!
for loop obfuscation would also be F R E A K I NG  hot
why cant i do print "h" and have it get obfuscated what the naenae
TODO: Make sure string mutation handles [[]] fine, even in table accesses
create multiple constant pools; shuffle them; only put globals in them
todo: allow mutating table accesses when doing something like ("ass"):sub(2) NVM THAT SHOULD WORK FINE HA still hookable :( but hey
]=]--

-- print'a'
if _G.DEBUG_MODE_ENABLED then
    local _oldprint = print
    _G.print = function(...)
        debug.traceback()
        return error(tostring(...))
    end
end

-- math.randomseed(os.clock())
require'XFuscator.init'
local minifysourceof = require'luasrcdiet.LuaSrcDiet'.get_minified


-- for i = 1, 10000 do print'' end

os.execute "clear"
-- os.execute "cls"

-- local code = [[
-- local function printhi()
--     local cool_people = {["john"] = 1337}
--     local msg_to_print = 'Hello world' --'hello\"\'[=[asdf]=] world'
--     local a = { "asdf", "qwerty" }
--     local b = [=[ long String [==[asdf]==] bleh]=]
--     print ('Script executed! at ' .. tostring(os.clock()))
--     print(msg_to_print)
-- end

-- printhi()

-- --print(CONSTANT_POOL[0])
-- ]]

-- local code = [[
-- local x=game local e=x.Workspace local o=x.FindFirstChild local d=x.GetFullName local m=x.GetService local i=m(x,"Players").LocalPlayer.HasAppearanceLoaded local p=x.IsA local l=x.IsLoaded local r=pcall local g=setmetatable local t=tick local s=tostring local b=unpack local q=xpcall local c=math.max local a=string.gsub local h=string.lower local f=string.match local a=string.rep local j=m(x,"Players").LocalPlayer local n,u,v,w,k n=false u=g({0,t()},{__metatable=false})v=g({},{__metatable=false})w=function()warn"Nice hacks."end k=function(b,c)local a b=h(s(b))c=h(s(c))q(function()a=f(s(b),c)end,w)return s(a)end m(x,"GuiService").MenuClosed:connect(function()n=false end)m(x,"GuiService").MenuOpened:connect(function()n=true end)e.DescendantAdded:connect(function(a)q(function()if not l(x)then return end if not r(o,a,'')then w()end if p(a,"PVAdornment")then w()end if p(a,"SelectionLasso")then w()end end,w)end)x.DescendantAdded:connect(function(a)if n then return end if not l(x)then return end if not i(j)then return end if r(function()o(a,'')end)then return end r(function()if not k(a,"FriendStatus")and not r(o,a,'')then w()end end)if(t()-u[2])>5 then u[1]=0 u[2]=t()else u[1]=u[1]+1 end if u[1]>15 then u[1]=-9e99 u[2]=9e999 w()end end)j.DescendantAdded:connect(function(a)q(function()if not l(x)then return end if not r(o,a,'')then w()end q(function()if p(a,"PVAdornment")then w()end end,w)q(function()if p(a,"BillboardGui")then w()end end,w)end,w)end)x.ItemChanged:connect(function(e,a)if n then return end if not l(x)then return end if not i(j)then return end r(function()if p(e,"BillboardGui")then if k(d(e),"CoreGui")then w()end end end)if r(o,e,'')then return end if s(a)=="Adornee"then if v[e]then v[e][1][1]=v[e][1][1]+1 else v[e]={{1,0,0},t()}end end if s(a)=="Size"then if v[e]then v[e][1][2]=v[e][1][2]+1 else v[e]={{1,0,0},t()}end end if s(a)=="AbsoluteSize"then if v[e]then v[e][1][3]=v[e][1][3]+1 else v[e]={{0,0,1},t()}end end local a=v[e]if a and c(b(a[1]))>20 then if(t()-a[2])<20 then w()else v[e]=nil end end end)
-- ]]

local z = [[
    print(1337, "Poop", "butt", 69)
    local x = 5+5
    local z = "hiya"
    print(z)
    local z = {a = 5, b = "c"}
    print(z.a)
    for i,v in pairs(z) do print(i,v) end
    b = {}
    function b:p()
    -- assert(self)
    -- print "Working!"
    end
    print()
    b:p()
    print ("Hello" .. tostring(z))
    local b = "The sky is blue."
    local age = 15
    local message = "The man is " .. age .. " years old."
    local secondMessage = "This is a very long and pointless test string lol haha funny!5,4,3,2,1"
    print(message)
    print(z)
    local x = math.random(25, 50)
    print("out " .. tostring(z) .. x)
]]

local b = [[
print(1337, "Poop", "butt", 69)
-- local print = print
print(getfenv().a)
print(1)
local z = "a"
-- print(z)
-- print("A")
print "food"
-- print"a"
-- print("a")
-- local z = "Players"
-- -- print(z)
-- print("Executing list:printcontents(\"Abacuses are cool.\")")
-- -- print(game:GetService(z))
]]

-- local code = [[
--     local a = "ass"
--     print(a)
-- ]]

local as = [[
    c={} ac=function(o) for q,w in pairs(o:children()) do table.insert(c,w) ac(w) end end ac(workspace) parts={} for q,w in pairs(c) do if w:IsA"BasePart"then table.insert(parts,w) end end for q,w in pairs(parts) do w.Anchored = false end
]]

local __code = [[
local recurse
recurse = function(instance)
    for i, child in pairs(instance:GetChildren()) do
        recurse(child)
    end
    if instance:IsA"BasePart" then
        instance.Anchored = false
    end
end
recurse(workspace)
]]

local notnotcode = [[
-- local b = 5
local next = global.Child.NextChild
print(global.Child.NextChild:GetChildren())
do
    local b = 5
    print(b.z)
end
    -- for i = 1, #parent:GetChildren() do
    --     print("On instance: " .. i)
    --     print("Instance count times five is: " .. i * 5)
    --     parent:GetChildren()[i]:Destroy()
    -- end
]]
-- local testcases = {}
-- testcases.numbers = [[
-- ]]

local code = [[
    do end
    local x = string.char(102)
    print(string.char(103))
    -- print(parentGlobal.childObject:getAllChildren())
    -- print(x)
    -- print(1)
    -- print(getfenv)
    -- for i = 1, 10 do
    --     if false then
    --         print(i)
    --     end
    -- end
]]

-- local code = testcases.numbers

local options = {
    fluff = false,
    useLoadstring = false,
    level = 1,
    mxLevel = 1,
    comments =false, -- broken
    step2 = false,
    uglify = false,
    encryptStrings = false,
    encryptNumbers = false,
    tamperDetection = false,
    rename = false,
    identity = true,
    obfuscateNumbers = false,
    extractConstants = false,
    obfuscateBooleans = false,
    mutateStrings = false, -- i need to fix this
    tableAccessToString = false, -- required for poolglobals
    luasrcdiet = false,
    stringstobinary = false,
    namesarebinary = false,
    poolglobals = false,
    globalaccesstotable = false,
    globalcallmapping = false,
}

-- print'a'
local outfn

-- while loop vs for i loop
if arg and arg[1] then
    code = io.open(arg[1], 'rb'):read'*a'
    outfn = "obf_" .. arg[1]:sub(1, -5) .. ".lua"
    local i = 2
else
    -- print("input code")
    code = #code < 10 and io.read'*l' or code
    -- print "thanks\n\n\n"
end

local t1 = os and os.time() or tick()
-- print(get_minified_meme("local memes = 8 print(memes)"))
-- if options.luasrcdiet then print(_G.get_minified(code)) end
local result, msg = XFuscator.XFuscate(
    code, options.level, options.mxLevel,
    options.loadstring, options.fluff, options.comments,
    options.step2, options.uglify, options.encryptStrings,
    options.tamperDetection, options.rename, options.identity,
    options.encryptNumbers, options.obfuscateNumbers, options.extractConstants,
    options.mutateStrings, options.tableAccessToString, options.luasrcdiet,
    options.stringstobinary, options.namesarebinary, options.poolglobals,
    options.globalaccesstotable, options.globalcallmapping)

local t2 = os and os.time() or tick()
-- if not outfn then
--     print(result)
-- end
-- print(result)
if not result then
    print("-- Failed: " .. tostring(msg))
else
    local a, b = loadstring(result)

    if result then
        -- os.execute("echo " .. result:gsub("\n", "") .. " | xsel -b")
    end

    if a then
        print"\n\nObfOut\n\n"
        -- print"-- Successful!"
        -- print(a())
        if not outfn or DEBUG_MODE_ENABLED then
            if PRINT_RESULT then
                print(result)
            end
            print("\n\nOutput\n\n")
            print(a())
        end
    else
        print("-- Failed: " .. b)
    end

    if outfn then
        print (result)
        -- local name = "OBFUSCATED_" .. outfn
        local name = outfn
        name = name:gsub("\\", "")
        -- print("NAME: " .. name)
        local file = io.open(name, 'a')
        file:write(result)
        file:close()
        print("Written to:", name)
    end

end

-- print("-- Time taken:", t2 - t1)
