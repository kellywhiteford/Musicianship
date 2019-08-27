%findnextpow2(x) - finds next power of 2 eq or higher than x
function nextpow2 = findnextpow2(x)

i = 0;
comparison = 2^i;

while (x > comparison)
  comparison = 2^i;
  i = i + 1;
end

nextpow2 = comparison;
