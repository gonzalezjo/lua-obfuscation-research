local x = 10

::a::
if x == 10 then
	print 'x is 10'
	if getfenv then getfenv(2).a = 5 end
	x = 9
  goto a
  goto a
  goto a
  goto a
  goto a
else
	print 'x is not 10'
end