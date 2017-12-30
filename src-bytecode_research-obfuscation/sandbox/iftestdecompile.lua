local x = 10
while true do
  if x == 10 then
    print("x is 10")
    if getfenv then
      getfenv(2).a = 5
    end
    x = 9
end
else
  print("x is not 10")
end