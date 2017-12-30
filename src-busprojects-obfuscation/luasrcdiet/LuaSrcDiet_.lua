#!/usr/bin/env lua
local i=string
local e=math
local k=table
local u=require
local c=print
local d=i.sub
local r=i.gmatch
local t=u"llex"local m=u"lparser"local f=u"optlex"local y=u"optparser"local o
local L=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.11.2 (20080608)  Copyright (c) 2005-2008 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]local E=[[
usage: LuaSrcDiet [options] [filenames]

example:
  >LuaSrcDiet myscript.lua -o myscript_.lua

options:
  -v, --version       prints version information
  -h, --help          prints usage information
  -o <file>           specify file name to write output
  -s <suffix>         suffix for output files (default '_')
  --keep <msg>        keep block comment with <msg> inside
  --plugin <module>   run <module> in plugin/ directory
  -                   stop handling arguments

  (optimization levels)
  --none              all optimizations off (normalizes EOLs only)
  --basic             lexer-based optimizations only
  --maximum           maximize reduction of source

  (informational)
  --quiet             process files quietly
  --read-only         read file and print token stats only
  --dump-lexer        dump raw tokens from lexer to stdout
  --dump-parser       dump variable tracking tables from parser
  --details           extra info (strings, numbers, locals)

features (to disable, insert 'no' prefix like --noopt-comments):
%s
default settings:
%s]]local h=[[
--opt-comments,'remove comments and block comments'
--opt-whitespace,'remove whitespace excluding EOLs'
--opt-emptylines,'remove empty lines'
--opt-eols,'all above, plus remove unnecessary EOLs'
--opt-strings,'optimize strings and long strings'
--opt-numbers,'optimize numbers'
--opt-locals,'optimize local variable names'
--opt-entropy,'tries to reduce symbol entropy of locals'
]]local b=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
]]local S=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local K=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
]]local P=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local a="_"local w="plugin/"local function l(e)c("LuaSrcDiet: "..e);os.exit()end
if not i.match(_VERSION,"5.1",1,1)then
l("requires Lua 5.1 to run")end
local n=""do
local a=24
local o={}for t,l in r(h,"%s*([^,]+),'([^']+)'")do
local e="  "..t
e=e..i.rep(" ",a-#e)..l.."\n"n=n..e
o[t]=true
o["--no"..d(t,3)]=true
end
h=o
end
E=i.format(E,n,b)local x=a
local e={}local a,s
local function p(n)for n in r(n,"(%-%-%S+)")do
if d(n,3,4)=="no"and
h["--"..d(n,5)]then
e[d(n,5)]=false
else
e[d(n,3)]=true
end
end
end
local r={"TK_KEYWORD","TK_NAME","TK_NUMBER","TK_STRING","TK_LSTRING","TK_OP","TK_EOS","TK_COMMENT","TK_LCOMMENT","TK_EOL","TK_SPACE",}local A=7
local I={["\n"]="LF",["\r"]="CR",["\n\r"]="LFCR",["\r\n"]="CRLF",}local function T(o)local n=io.open(o,"rb")if not n then l('cannot open "'..o..'" for reading')end
local e=n:read("*a")c(#e)if not e then l('cannot read from "'..o..'"')end
n:close()return e
end
local function R(e,o)local n=io.open(e,"wb")if not n then l('cannot open "'..e..'" for writing')end
local o=n:write(o)if not o then l('cannot write to "'..e..'"')end
n:close()end
local function O()a,s={},{}for e=1,#r do
local e=r[e]a[e],s[e]=0,0
end
end
local function g(e,n)a[e]=a[e]+1
s[e]=s[e]+#n
end
local function _()local function l(e,n)if e==0 then return 0 end
return n/e
end
local t={}local e,n=0,0
for o=1,A do
local o=r[o]e=e+a[o];n=n+s[o]end
a.TOTAL_TOK,s.TOTAL_TOK=e,n
t.TOTAL_TOK=l(e,n)e,n=0,0
for o=1,#r do
local o=r[o]e=e+a[o];n=n+s[o]t[o]=l(a[o],s[o])end
a.TOTAL_ALL,s.TOTAL_ALL=e,n
t.TOTAL_ALL=l(e,n)return t
end
local function v(e)local e=T(e)t.init(e)t.llex()local e,o=t.tok,t.seminfo
for n=1,#e do
local n,e=e[n],o[n]if n=="TK_OP"and i.byte(e)<32 then
e="("..i.byte(e)..")"elseif n=="TK_EOL"then
e=I[e]else
e="'"..e.."'"end
c(n.." "..e)end
end
local function A(e)local n=c
local e=T(e)t.init(e)t.llex()local e,t,o=t.tok,t.seminfo,t.tokln
m.init(e,t,o)local e,l=m.parser()local t=i.rep("-",72)n("*** Local/Global Variable Tracker Tables ***")n(t.."\n GLOBALS\n"..t)for t=1,#e do
local o=e[t]local e="("..t..") '"..o.name.."' -> "local o=o.xref
for t=1,#o do e=e..o[t].." "end
n(e)end
n(t.."\n LOCALS (decl=declared act=activated rem=removed)\n"..t)for e=1,#l do
local o=l[e]local e="("..e..") '"..o.name.."' decl:"..o.decl.." act:"..o.act.." rem:"..o.rem
if o.isself then
e=e.." isself"end
e=e.." -> "local o=o.xref
for t=1,#o do e=e..o[t].." "end
n(e)end
n(t.."\n")end
local function I(o)local e=c
local n=T(o)t.init(n)t.llex()local n,t=t.tok,t.seminfo
e(L)e("Statistics for: "..o.."\n")O()for e=1,#n do
local n,e=n[e],t[e]g(n,e)end
local n=_()local o=i.format
local function l(e)return a[e],s[e],n[e]end
local t,a="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"local n=i.rep("-",42)e(o(t,"Lexical","Input","Input","Input"))e(o(t,"Elements","Count","Bytes","Average"))e(n)for t=1,#r do
local t=r[t]e(o(a,t,l(t)))if t=="TK_EOS"then e(n)end
end
e(n)e(o(a,"Total Elements",l("TOTAL_ALL")))e(n)e(o(a,"Total Tokens",l("TOTAL_TOK")))e(n.."\n")end
local function N(d,p)local function n(...)if e.QUIET then return end
_G.print(...)end
if o and o.init then
e.EXIT=false
o.init(e,d,p)if e.EXIT then return end
end
n(L)local l=T(d)if o and o.post_load then
l=o.post_load(l)or l
if e.EXIT then return end
end
t.init(l)t.llex()local t,l,c=t.tok,t.seminfo,t.tokln
if o and o.post_lex then
o.post_lex(t,l,c)if e.EXIT then return end
end
O()for e=1,#t do
local e,n=t[e],l[e]g(e,n)end
local u=_()local h,T=a,s
if e["opt-locals"]then
y.print=n
m.init(t,l,c)local i,n=m.parser()if o and o.post_parse then
o.post_parse(i,n)if e.EXIT then return end
end
y.optimize(e,t,l,i,n)if o and o.post_optparse then
o.post_optparse()if e.EXIT then return end
end
end
f.print=n
t,l,c=f.optimize(e,t,l,c)if o and o.post_optlex then
o.post_optlex(t,l,c)if e.EXIT then return end
end
local e=k.concat(l)if i.find(e,"\r\n",1,1)or
i.find(e,"\n\r",1,1)then
f.warn.mixedeol=true
end
R(p,e)O()for e=1,#t do
local n,e=t[e],l[e]g(n,e)end
local t=_()n("Statistics for: "..d.." -> "..p.."\n")local o=i.format
local function c(e)return h[e],T[e],u[e],a[e],s[e],t[e]end
local l,t="%-16s%8s%8s%10s%8s%8s%10s","%-16s%8d%8d%10.2f%8d%8d%10.2f"local e=i.rep("-",68)n("*** lexer-based optimizations summary ***\n"..e)n(o(l,"Lexical","Input","Input","Input","Output","Output","Output"))n(o(l,"Elements","Count","Bytes","Average","Count","Bytes","Average"))n(e)for l=1,#r do
local l=r[l]n(o(t,l,c(l)))if l=="TK_EOS"then n(e)end
end
n(e)n(o(t,"Total Elements",c("TOTAL_ALL")))n(e)n(o(t,"Total Tokens",c("TOTAL_TOK")))n(e)if f.warn.lstring then
n("* WARNING: "..f.warn.lstring)elseif f.warn.mixedeol then
n("* WARNING: ".."output still contains some CRLF or LFCR line endings")end
n()end
local a={...}local s={}p(b)local function f(a)for o,n in ipairs(a)do
local o
local t,r=i.find(n,"%.[^%.%\\%/]*$")local s,i=n,""if t and t>1 then
s=d(n,1,t-1)i=d(n,t,r)end
o=s..x..i
if#a==1 and e.OUTPUT_FILE then
o=e.OUTPUT_FILE
end
if n==o then
l("output filename identical to input filename")end
if e.DUMP_LEXER then
v(n)elseif e.DUMP_PARSER then
A(n)elseif e.READ_ONLY then
I(n)else
N(n,o)end
end
end
local function r()local n,t=#a,1
if n==0 then
e.HELP=true
end
while t<=n do
local n,a=a[t],a[t+1]local i=i.match(n,"^%-%-?")if i=="-"then
if n=="-h"then
e.HELP=true;break
elseif n=="-v"then
e.VERSION=true;break
elseif n=="-s"then
if not a then l("-s option needs suffix specification")end
x=a
t=t+1
elseif n=="-o"then
if not a then l("-o option needs a file name")end
e.OUTPUT_FILE=a
t=t+1
elseif n=="-"then
break
else
l("unrecognized option "..n)end
elseif i=="--"then
if n=="--help"then
e.HELP=true;break
elseif n=="--version"then
e.VERSION=true;break
elseif n=="--keep"then
if not a then l("--keep option needs a string to match for")end
e.KEEP=a
t=t+1
elseif n=="--plugin"then
if not a then l("--plugin option needs a module name")end
if e.PLUGIN then l("only one plugin can be specified")end
e.PLUGIN=a
o=u(w..a)t=t+1
elseif n=="--quiet"then
e.QUIET=true
elseif n=="--read-only"then
e.READ_ONLY=true
elseif n=="--basic"then
p(S)elseif n=="--maximum"then
p(K)elseif n=="--none"then
p(P)elseif n=="--dump-lexer"then
e.DUMP_LEXER=true
elseif n=="--dump-parser"then
e.DUMP_PARSER=true
elseif n=="--details"then
e.DETAILS=true
elseif h[n]then
p(n)else
l("unrecognized option "..n)end
else
s[#s+1]=n
end
t=t+1
end
if e.HELP then
c(L..E);return true
elseif e.VERSION then
c(L);return true
end
if#s>0 then
if#s>1 and e.OUTPUT_FILE then
l("with -o, only one source file can be specified")end
f(s)return true
else
l("nothing to do!")end
end
if not r()then
l("Please run with option -h or --help for usage information")end
