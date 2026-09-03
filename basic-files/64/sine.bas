10 poke 53280,14 : poke 53281,6
20 poke 52,48 : poke 56,48 : clr
30 poke 53265,peek(53265) or 32
40 poke 53272,(peek(53272) and 240) or 8
50 for i=8192 to 16191 : poke i,0 : next i
60 for i=1024 to 2023 : poke i,230 : next i
70 for x=0 to 319
80 y=100+int(80*sin(x*.0393))
90 a=8192+int(y/8)*320+int(x/8)*8+(y and 7)
100 b=2^(7-(x and 7))
110 poke a,peek(a) or b
120 next x
130 goto 130
