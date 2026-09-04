10 print chr$(147)
20 poke 52,28 : poke 56,28 : clr
30 poke 36869,255
40 for i=7168 to 7679 : poke i,0 : next i
50 ox=88 : oy=92 : rh=int(oy/8) : cv=int(ox/8)
60 poke 7168+(oy and 7),255
70 for j=0 to 7 : poke 7176+j,2^(7-(ox and 7)) : next j
80 for j=0 to 7 : poke 7184+j,2^(7-(ox and 7)) : next j
90 poke 7184+(oy and 7),255
100 for co=0 to 21 : poke 7680+rh*22+co,0 : poke 38400+rh*22+co,6 : next co
110 for ro=0 to 22 : poke 7680+ro*22+cv,1 : poke 38400+ro*22+cv,6 : next ro
120 poke 7680+rh*22+cv,2 : poke 38400+rh*22+cv,6
130 dim cch(63), rch(63)
140 nc=2 : cc=-1 : cr=-1
150 for x=0 to 175
160 y=oy-int(44*sin((x-ox)*.0714))
170 co=int(x/8) : ro=int(y/8)
180 if co=cc and ro=cr then 260
190 if nc<63 then nc=nc+1
200 cc=co : cr=ro : ch=nc : cch(ch)=co : rch(ch)=ro
210 poke 7680+ro*22+co,ch : poke 38400+ro*22+co,6
220 if ro=rh then poke 7168+ch*8+(oy and 7),255
230 if co<>cv then 260
240 for j=0 to 7 : poke 7168+ch*8+j,peek(7168+ch*8+j) or 2^(7-(ox and 7)) : next j
260 a=7168+ch*8+(y-ro*8)
270 poke a,peek(a) or 2^(7-(x-co*8))
280 next x
290 cc=-1 : cr=-1
300 for x=0 to 175
310 y=oy-int(44*cos((x-ox)*.0714))
320 co=int(x/8) : ro=int(y/8)
330 if co=cc and ro=cr then 470
340 ch=0
350 for k=3 to nc
360 if cch(k)=co and rch(k)=ro then ch=k : k=nc
370 next k
380 if ch>0 then 470
390 if nc>=63 then 460
400 nc=nc+1 : ch=nc : cch(ch)=co : rch(ch)=ro
410 if ro=rh then poke 7168+ch*8+(oy and 7),255
420 if co<>cv then 440
430 for j=0 to 7 : poke 7168+ch*8+j,peek(7168+ch*8+j) or 2^(7-(ox and 7)) : next j
440 poke 7680+ro*22+co,ch : poke 38400+ro*22+co,2
450 goto 470
460 poke 7680+ro*22+co,42 : poke 38400+ro*22+co,2 : ch=0
470 cc=co : cr=ro
480 if ch>0 then a=7168+ch*8+(y-ro*8) : poke a,peek(a) or 2^(7-(x-co*8))
490 next x
500 goto 500
