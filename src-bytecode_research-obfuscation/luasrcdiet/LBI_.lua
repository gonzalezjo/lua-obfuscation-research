local L
local C
local f
local B={"ABC","ABx","ABC","ABC","ABC","ABx","ABC","ABx","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","AsBx","ABC","ABC","ABC","ABC","ABC","ABC","ABC","ABC","AsBx","AsBx","ABC","ABC","ABC","ABx","ABC",}local n={"MOVE","LOADK","LOADBOOL","LOADNIL","GETUPVAL","GETGLOBAL","GETTABLE","SETGLOBAL","SETUPVAL","SETTABLE","NEWTABLE","SELF","ADD","SUB","MUL","DIV","MOD","POW","UNM","NOT","LEN","CONCAT","JMP","EQ","LT","LE","TEST","TESTSET","CALL","TAILCALL","RETURN","FORLOOP","FORPREP","TFORLOOP","SETLIST","CLOSE","CLOSURE","VARARG"};local function c(o,e,a)if a then
local l=0
local n=0
for e=e,a do
l=l+2^n*c(o,e)n=n+1
end
return l
else
local n=2^(e-1)return(o%(n+n)>=n)and 1 or 0
end
end
local function i(e)local n=1
local s=false
local i;local r;local a,f;local l,o,d,u,t;do
function l()local l=e:byte(n,n);n=n+1
return l
end
function o()local e,l,a,o=e:byte(n,n+3);n=n+4;return o*16777216+a*65536+l*256+e
end
function d()local n=o();local l=o();return l*4294967296+n;end
function u()local l=o()local n=o()return(-2*c(n,32)+1)*(2^(c(n,21,31)-1023))*((c(n,1,20)*(2^32)+l)/(2^52)+1)end
function t(l)local o;if l then
o=e:sub(n,n+l-1);n=n+l;else
l=f();if l==0 then return;end
o=e:sub(n,n+l-1);n=n+l;end
return o;end
end
local function A()local n;local f={};local i={};local r={};local d={lines={};};n={instructions=f;constants=i;prototypes=r;debug=d;};local e;n.name=t();n.first_line=a();n.last_line=a();if n.name then n.name=n.name:sub(1,-2);end
n.upvalues=l();n.arguments=l();n.varg=l();n.stack=l();do
e=a();for a=1,e do
local n={};local l=o();local o=c(l,1,6);local e=B[o+1];n.opcode=o;n.type=e;n.A=c(l,7,14);if e=="ABC"then
n.B=c(l,24,32);n.C=c(l,15,23);elseif e=="ABx"then
n.Bx=c(l,15,32);elseif e=="AsBx"then
n.sBx=c(l,15,32)-131071;end
f[a]=n;end
end
do
e=a();for o=1,e do
local n={};local e=l();n.type=e;if e==1 then
n.data=(l()~=0);elseif e==3 then
n.data=u();elseif e==4 then
n.data=t():sub(1,-2);end
i[o-1]=n;end
end
do
e=a();for n=1,e do
r[n-1]=A();end
end
do
local n=d.lines
e=a();for l=1,e do
n[l]=o();end
e=a();for n=1,e do
t():sub(1,-2);o();o();end
e=a();for n=1,e do
t();end
end
return n;end
do
assert(t(4)=="\27Lua","Lua bytecode expected.");assert(l()==81,"Only Lua 5.1 is supported.");l();s=(l()==0);i=l();r=l();if i==4 then
a=o;elseif i==8 then
a=d;else
error("Unsupported bytecode target platform");end
if r==4 then
f=o;elseif r==8 then
f=d;else
error("Unsupported bytecode target platform");end
assert(t(3)=="\4\b\0","Unsupported bytecode target platform");end
return A();end
local function h(...)local l=select("#",...)local n={...}return l,n
end
local function c(a,s)local B=a.instructions;local e=a.constants;local p=a.prototypes;local n,o
local A
local l=1;local u,i
local d={[0]=function(l)n[l.A]=n[l.B];end,[1]=function(l)n[l.A]=e[l.Bx].data;end,[2]=function(e)n[e.A]=e.B~=0
if e.C~=0 then
l=l+1
end
end,[3]=function(l)local n=n
for l=l.A,l.B do
n[l]=nil
end
end,[4]=function(l)n[l.A]=s[l.B]end,[5]=function(l)local e=e[l.Bx].data;n[l.A]=A[e];end,[6]=function(o)local l=o.C
local n=n
l=l>255 and e[l-256].data or n[l]n[o.A]=n[o.B][l];end,[7]=function(l)local e=e[l.Bx].data;A[e]=n[l.A];end,[8]=function(l)s[l.B]=n[l.A]end,[9]=function(a)local o=a.B;local l=a.C;local n,e=n,e;o=o>255 and e[o-256].data or n[o];l=l>255 and e[l-256].data or n[l];n[a.A][o]=l
end,[10]=function(l)n[l.A]={}end,[11]=function(l)local a=l.A
local o=l.B
local l=l.C
local n=n
o=n[o]l=l>255 and e[l-256].data or n[l]n[a+1]=o
n[a]=o[l]end,[12]=function(a)local o=a.B;local l=a.C;local n,e=n,e;o=o>255 and e[o-256].data or n[o];l=l>255 and e[l-256].data or n[l];n[a.A]=o+l;end,[13]=function(a)local o=a.B;local l=a.C;local n,e=n,e;o=o>255 and e[o-256].data or n[o];l=l>255 and e[l-256].data or n[l];n[a.A]=o-l;end,[14]=function(a)local o=a.B;local l=a.C;local n,e=n,e;o=o>255 and e[o-256].data or n[o];l=l>255 and e[l-256].data or n[l];n[a.A]=o*l;end,[15]=function(a)local o=a.B;local l=a.C;local n,e=n,e;o=o>255 and e[o-256].data or n[o];l=l>255 and e[l-256].data or n[l];n[a.A]=o/l;end,[16]=function(a)local l=a.B;local o=a.C;local n,e=n,e;l=l>255 and e[l-256].data or n[l];o=o>255 and e[o-256].data or n[o];n[a.A]=l%o;end,[17]=function(a)local o=a.B;local l=a.C;local n,e=n,e;o=o>255 and e[o-256].data or n[o];l=l>255 and e[l-256].data or n[l];n[a.A]=o^l;end,[18]=function(l)n[l.A]=-n[l.B]end,[19]=function(l)n[l.A]=not n[l.B]end,[20]=function(l)n[l.A]=#n[l.B]end,[21]=function(l)local o=l.B
local e=n[o]for l=o+1,l.C do
e=e..n[l]end
n[l.A]=e
end,[22]=function(n)l=l+n.sBx
end,[23]=function(a)local c=a.A
local o=a.B
local a=a.C
local e,n=n,e
c=c~=0
o=o>255 and n[o-256].data or e[o]a=a>255 and n[a-256].data or e[a]if(o==a)~=c then
l=l+1
end
end,[24]=function(a)local c=a.A
local o=a.B
local a=a.C
local n,e=n,e
c=c~=0
o=o>255 and e[o-256].data or n[o]a=a>255 and e[a-256].data or n[a]if(o<a)~=c then
l=l+1
end
end,[25]=function(a)local c=a.A
local o=a.B
local a=a.C
local e,n=n,e
c=c~=0
o=o>255 and n[o-256].data or e[o]a=a>255 and n[a-256].data or e[a]if(o<=a)~=c then
l=l+1
end
end,[26]=function(e)if(not not n[e.A])==(e.C==0)then
l=l+1
end
end,[27]=function(e)local o=n
local n=o[e.B]if(not not n)==(e.C==0)then
l=l+1
else
o[e.A]=n
end
end,[28]=function(e)local l=e.A;local r=e.B;local d=e.C;local a=n;local c,t;local n,e
c={};if r~=1 then
if r~=0 then
n=l+r-1;else
n=o
end
e=0
for l=l+1,n do
e=e+1
c[e]=a[l];end
n,t=h(a[l](unpack(c,1,n-l)))else
n,t=h(a[l]())end
o=l-1
if d~=1 then
if d~=0 then
n=l+d-2;else
n=n+l
end
e=0;for n=l,n do
e=e+1;a[n]=t[e];end
end
end,[29]=function(e)local l=e.A;local a=e.B;local e=e.C;local c=n;local e,t;local d,n,o=o
e={};if a~=1 then
if a~=0 then
n=l+a-1;else
n=d
end
o=0
for n=l+1,n do
o=o+1
e[#e+1]=c[n];end
t={c[l](unpack(e,1,n-l))};else
t={c[l]()};end
return true,t
end,[30]=function(l)local c=l.A;local a=l.B;local t=n;local e;local n,l;if a==1 then
return true;end
if a==0 then
e=o
else
e=c+a-2;end
l={};local n=0
for e=c,e do
n=n+1
l[n]=t[e];end
return true,l;end,[31]=function(a)local e=a.A
local n=n
local c=n[e+2]local o=n[e]+c
n[e]=o
if c>0 then
if o<=n[e+1]then
l=l+a.sBx
n[e+3]=o
end
else
if o>=n[e+1]then
l=l+a.sBx
n[e+3]=o
end
end
end,[32]=function(o)local e=o.A
local n=n
n[e]=n[e]-n[e+2]l=l+o.sBx
end,[33]=function(o)local e=o.A
local a=o.B
local o=o.C
local n=n
local c=e+2
local a={n[e](n[e+1],n[e+2])}for l=1,o do
n[c+l]=a[l]end
if n[e+3]~=nil then
n[e+2]=n[e+3]else
l=l+1
end
end,[34]=function(l)local a=l.A
local e=l.B
local l=l.C
local n=n
if l==0 then
error("NYI: extended SETLIST")else
local t=(l-1)*50
local c=n[a]if e==0 then
e=o
end
for l=1,e do
c[t+l]=n[a+l]end
end
end,[35]=function(n)end,[36]=function(t)local d=p[t.Bx]local o=B
local a=n
local n={}local r=setmetatable({},{__index=function(e,l)local n=n[l]return n.segment[n.offset]end,__newindex=function(o,e,l)local n=n[e]n.segment[n.offset]=l
end})for c=1,d.upvalues do
local e=o[l]if e.opcode==0 then
n[c-1]={segment=a,offset=e.B}elseif o[l].opcode==4 then
n[c-1]={segment=s,offset=e.B}end
l=l+1
end
local l,n=c(d,r)a[t.A]=n
end,[37]=function(e)local l=e.A
local e=e.B
local a,o=n,u
for n=l,l+(e>0 and e-1 or i)do
a[n]=o[n-l]end
end,}local function c(e)local c=a.name;local l=a.debug.lines[l];local o=(e:match("^.+:(.+)")or e)local n="Error: ";if c then
n=c
end
if l then
n=n.." - Line: "..l
end
if e and type(e)=="string"then
n=n.." - Error: "..o
end
if f then
f(tostring(l)..":"..tostring(o))else
error(tostring(l)..":"..tostring(o),3)end
end
local function t()local t=B
local n,e,a,o
while true do
n=t[l];l=l+1
o,e,a=pcall(function()return d[n.opcode](n);end);if not o then
c(e);break;elseif e then
return a;end
end
end
local d={get_stack=function()return n;end;get_IP=function()return l;end};local function r(...)local e={};local a={};o=-1
n=setmetatable(e,{__index=a;__newindex=function(e,n,l)if n>o and l then
o=n
end
a[n]=l
end;})local o={...};u={}i=select("#",...)-1
for n=0,i do
e[n]=o[n+1];u[n]=o[n+1]end
A=C or getfenv();l=1;local n=coroutine.create(t)local l,n=coroutine.resume(n)if l then
if n then
return unpack(n);end
return;else
if L then
else
c(n)end
end
end
return d,r;end
return{load_bytecode=function(e,l,n)C=l or getfenv(2)f=n
local n=i(e);local l,n=c(n);return n;end;utils={decode_bytecode=i;create_wrapper=c;debug_bytecode=function(n)local n=i(n)return c(n);end;};}