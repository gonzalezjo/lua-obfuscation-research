local x = 10

label 'fat'
if x == 10 then
	print 'x is 10'
	if getfenv then getfenv(2).a = 5 end
	x = 9
	goto 'fat'
else
	print 'x is not 10'
end
