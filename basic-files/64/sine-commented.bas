9 rem border light blue, background blue
10 poke 53280,14 : poke 53281,6
19 rem reserve memory above $3000 for the bitmap, then clear basic
20 poke 52,48 : poke 56,48 : clr
29 rem turn on bitmap (hi-res) mode
30 poke 53265,peek(53265) or 32
39 rem point the vic-ii at the bitmap data, keep screen ram default
40 poke 53272,(peek(53272) and 240) or 8
49 rem clear the whole 8k bitmap to blank pixels
50 for i=8192 to 16191 : poke i,0 : next i
59 rem set every cell's colors: light blue on blue
60 for i=1024 to 2023 : poke i,230 : next i
69 rem origin pixel: center of the 320x200 hi-res screen
70 ox=160 : oy=100
79 rem draw the horizontal (x) axis through the origin
80 for x=0 to 319 : y=oy : gosub 200 : next x
89 rem draw the vertical (y) axis through the origin
90 for y=0 to 199 : x=ox : gosub 200 : next y
99 rem plot the sine curve, one pixel per column
100 for x=0 to 319 : y=oy-int(80*sin((x-ox)*.0393)) : gosub 200 : next x
109 rem loop forever once the curve is drawn
110 goto 110
199 rem bitmap byte address for pixel (x,y)
200 a=8192+int(y/8)*320+int(x/8)*8+(y and 7)
209 rem set that pixel's bit without disturbing its neighbors
210 poke a,peek(a) or 2^(7-(x and 7))
219 rem back to the caller
220 return
