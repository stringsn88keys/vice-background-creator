9 rem switch to 320x200 hi-res bitmap graphics screen
10 graphic 1,1
19 rem origin pixel: center of the 320x200 hi-res screen
20 ox=160 : oy=100
29 rem draw the horizontal (x) axis through the origin
30 draw 1,0,oy to 319,oy
39 rem draw the vertical (y) axis through the origin
40 draw 1,ox,0 to ox,199
49 rem sine curve's starting point, at screen x=0
50 px=0 : py=oy-int(13*sin((0-ox)*.0393))
59 rem cosine curve's starting point, at screen x=0
60 qx=0 : qy=oy-int(13*cos((0-ox)*.0393))
69 rem step across every remaining column of the screen
70 for x=1 to 319
79 rem sine value for this column, scaled/shifted to pixels
80 y=oy-int(13*sin((x-ox)*.0393))
89 rem connect the previous sine point to this one
90 draw 1,px,py to x,y
99 rem remember this point as the next sine segment's start
100 px=x : py=y
109 rem cosine value for this column, scaled/shifted to pixels
110 z=oy-int(13*cos((x-ox)*.0393))
119 rem connect the previous cosine point to this one
120 draw 1,qx,qy to x,z
129 rem remember this point as the next cosine segment's start
130 qx=x : qy=z
139 rem loop back for the next column
140 next x
149 rem wait for a keypress before leaving the graphics screen
150 get a$ : if a$="" then 150
159 rem back to the normal text screen
160 graphic 0
