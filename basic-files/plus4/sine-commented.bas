9 rem clear the text screen
10 scnclr
19 rem switch to 320x200 hi-res bitmap graphics screen
20 graphic 1,1
29 rem origin pixel: center of the 320x200 hi-res screen
30 ox=160 : oy=100
39 rem draw the horizontal (x) axis through the origin
40 draw 1,0,oy to 319,oy
49 rem draw the vertical (y) axis through the origin
50 draw 1,ox,0 to ox,199
59 rem starting point of the curve, at screen x=0
60 px=0 : py=oy-int(80*sin((0-ox)*.0393))
69 rem step across every remaining column of the screen
70 for x=1 to 319
79 rem sine value for this column, scaled/shifted to pixels
80 y=oy-int(80*sin((x-ox)*.0393))
89 rem connect the previous point to this one with a line
90 draw 1,px,py to x,y
99 rem remember this point as the start of the next segment
100 px=x : py=y
109 rem loop back for the next column
110 next x
119 rem wait for a keypress before leaving the graphics screen
120 get a$ : if a$="" then 120
129 rem back to the normal text screen
130 graphic 0
