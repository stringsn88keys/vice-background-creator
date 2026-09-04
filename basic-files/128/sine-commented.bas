9 rem switch to 320x200 hi-res bitmap graphics screen
10 graphic 1,1
19 rem origin pixel: center of the 320x200 hi-res screen
20 ox=160 : oy=100
29 rem draw the horizontal (x) axis through the origin
30 draw 1,0,oy to 319,oy
39 rem draw the vertical (y) axis through the origin
40 draw 1,ox,0 to ox,199
49 rem starting point of the curve, at screen x=0
50 px=0 : py=oy-int(80*sin((0-ox)*.0393))
59 rem step across every remaining column of the screen
60 for x=1 to 319
69 rem sine value for this column, scaled/shifted to pixels
70 y=oy-int(80*sin((x-ox)*.0393))
79 rem connect the previous point to this one with a line
80 draw 1,px,py to x,y
89 rem remember this point as the start of the next segment
90 px=x : py=y
99 rem loop back for the next column
100 next x
109 rem wait for a keypress before leaving the graphics screen
110 get a$ : if a$="" then 110
119 rem back to the normal text screen
120 graphic 0
