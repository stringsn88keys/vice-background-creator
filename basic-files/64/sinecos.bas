10 poke 53280,14 : poke 53281,6
20 poke 52,48 : poke 56,48 : clr
30 poke 53265,peek(53265) or 32
40 poke 53272,(peek(53272) and 240) or 8
50 for i=8192 to 16191 : poke i,0 : next i
60 for i=1024 to 2023 : poke i,230 : next i
70 ox=160 : oy=100
80 for x=0 to 319 : y=oy : gosub 200 : next x
90 for y=0 to 199 : x=ox : gosub 200 : next y
100 for x=0 to 319 : y=oy-int(13*sin((x-ox)*.0393)) : gosub 200 : next x
110 for x=0 to 319 : y=oy-int(13*cos((x-ox)*.0393)) : gosub 200 : next x
120 goto 120
200 a=8192+int(y/8)*320+int(x/8)*8+(y and 7)
210 poke a,peek(a) or 2^(7-(x and 7))
220 return
