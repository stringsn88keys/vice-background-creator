9 rem clear the screen
10 print chr$(147)
19 rem reserve memory above $1c00 for custom characters, then clear basic
20 poke 52,28 : poke 56,28 : clr
29 rem point the vic chip at screen ram $1e00 and char ram $1c00
30 poke 36869,255
39 rem blank out all 64 custom character definitions
40 for i=7168 to 7679 : poke i,0 : next i
49 rem origin pixel and its character row/column
50 ox=88 : oy=92 : rh=int(oy/8) : cv=int(ox/8)
59 rem draw the origin's horizontal axis row into char 0
60 poke 7168+(oy and 7),255
69 rem draw the origin's vertical axis column into char 1
70 for j=0 to 7 : poke 7176+j,2^(7-(ox and 7)) : next j
79 rem copy that same vertical line into char 2 (the origin cell)
80 for j=0 to 7 : poke 7184+j,2^(7-(ox and 7)) : next j
89 rem add the horizontal line into char 2 as well
90 poke 7184+(oy and 7),255
99 rem fill the x-axis row with char 0, colored blue
100 for co=0 to 21 : poke 7680+rh*22+co,0 : poke 38400+rh*22+co,6 : next co
109 rem fill the y-axis column with char 1, colored blue
110 for ro=0 to 22 : poke 7680+ro*22+cv,1 : poke 38400+ro*22+cv,6 : next ro
119 rem place the origin's crosshair character
120 poke 7680+rh*22+cv,2 : poke 38400+rh*22+cv,6
129 rem arrays remembering which cell each custom character was drawn in
130 dim cch(63), rch(63)
139 rem next free custom char, and no cell touched yet
140 nc=2 : cc=-1 : cr=-1
149 rem step across every column of the screen, drawing sine first
150 for x=0 to 175
159 rem sine value for this column, scaled/shifted to pixels
160 y=oy-int(12*sin((x-ox)*.0714))
169 rem which character cell this pixel falls in
170 co=int(x/8) : ro=int(y/8)
179 rem same cell as last time - reuse its character, skip allocating
180 if co=cc and ro=cr then 260
189 rem otherwise claim the next free custom character (max 63)
190 if nc<63 then nc=nc+1
199 rem remember which cell this new character belongs to
200 cc=co : cr=ro : ch=nc : cch(ch)=co : rch(ch)=ro
209 rem place this new character in the cell, colored blue
210 poke 7680+ro*22+co,ch : poke 38400+ro*22+co,6
219 rem if on the axis row, carry its line into the new character
220 if ro=rh then poke 7168+ch*8+(oy and 7),255
229 rem skip the axis-column check unless we're in that column
230 if co<>cv then 260
239 rem carry the axis column's line into the new character
240 for j=0 to 7 : poke 7168+ch*8+j,peek(7168+ch*8+j) or 2^(7-(ox and 7)) : next j
259 rem this character's byte for the pixel's row within the cell
260 a=7168+ch*8+(y-ro*8)
269 rem set that pixel's bit without disturbing its neighbors
270 poke a,peek(a) or 2^(7-(x-co*8))
279 rem loop back for the next column of the sine curve
280 next x
289 rem no cosine cell touched yet
290 cc=-1 : cr=-1
299 rem step across every column again, this time for cosine
300 for x=0 to 175
309 rem cosine value for this column, scaled/shifted to pixels
310 y=oy-int(12*cos((x-ox)*.0714))
319 rem which character cell this pixel falls in
320 co=int(x/8) : ro=int(y/8)
329 rem same cell as last time - reuse its character, skip the search
330 if co=cc and ro=cr then 470
339 rem assume no character is assigned to this cell yet
340 ch=0
349 rem search every character allocated so far (by sin or cos)
350 for k=3 to nc
359 rem found one already placed in this cell - reuse it
360 if cch(k)=co and rch(k)=ro then ch=k : k=nc
369 rem keep searching until found or out of characters
370 next k
379 rem a character was found - go straight to plotting the pixel
380 if ch>0 then 470
389 rem no free characters left - fall back to a plain glyph
390 if nc>=63 then 460
399 rem claim a new character and remember its cell
400 nc=nc+1 : ch=nc : cch(ch)=co : rch(ch)=ro
409 rem if on the axis row, carry its line into the new character
410 if ro=rh then poke 7168+ch*8+(oy and 7),255
419 rem skip the axis-column check unless we're in that column
420 if co<>cv then 440
429 rem carry the axis column's line into the new character
430 for j=0 to 7 : poke 7168+ch*8+j,peek(7168+ch*8+j) or 2^(7-(ox and 7)) : next j
439 rem place the new character in the cell, colored red
440 poke 7680+ro*22+co,ch : poke 38400+ro*22+co,2
449 rem done allocating, go plot the pixel
450 goto 470
459 rem out of characters - drop in a plain asterisk instead
460 poke 7680+ro*22+co,42 : poke 38400+ro*22+co,2 : ch=0
469 rem remember this cell for the same-cell shortcut above
470 cc=co : cr=ro
479 rem set the pixel's bit, unless this cell used the fallback glyph
480 if ch>0 then a=7168+ch*8+(y-ro*8) : poke a,peek(a) or 2^(7-(x-co*8))
489 rem loop back for the next column of the cosine curve
490 next x
499 rem loop forever once both curves are drawn
500 goto 500
