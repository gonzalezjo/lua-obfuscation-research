-- easily deobfuscated with :gsub('#{', '1'):gsub('{},', '+1'), followed by luac, followed by .
-- there's GOT to be a way to create opaque predicates efficiently
print(#{{},{}}) 