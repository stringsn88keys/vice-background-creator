10 print chr$(147)
20 poke 52,28 : poke 56,28 : clr
30 poke 36869,255
40 for i=7168 to 7679 : poke i,0 : next i
50 nc=0 : cc=-1 : cr=-1
60 for x=0 to 175
70 y=92+int(64*sin(x*.0411))
80 co=int(x/8) : ro=int(y/8)
90 if co=cc and ro=cr then 130
100 if nc<63 then nc=nc+1
110 cc=co : cr=ro : ch=nc
120 poke 7680+ro*22+co,ch : poke 38400+ro*22+co,6
130 a=7168+ch*8+(y-ro*8)
140 poke a,peek(a) or 2^(7-(x-co*8))
150 next x
160 goto 160
