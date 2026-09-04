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
59 rem sine curve's starting point, at screen x=0
60 px=0 : py=oy-int(13*sin((0-ox)*.0393))
69 rem cosine curve's starting point, at screen x=0
70 qx=0 : qy=oy-int(13*cos((0-ox)*.0393))
79 rem step across every remaining column of the screen
80 for x=1 to 319
89 rem sine value for this column, scaled/shifted to pixels
90 y=oy-int(13*sin((x-ox)*.0393))
99 rem connect the previous sine point to this one
100 draw 1,px,py to x,y
109 rem remember this point as the next sine segment's start
110 px=x : py=y
119 rem cosine value for this column, scaled/shifted to pixels
120 z=oy-int(13*cos((x-ox)*.0393))
129 rem connect the previous cosine point to this one
130 draw 1,qx,qy to x,z
139 rem remember this point as the next cosine segment's start
140 qx=x : qy=z
149 rem loop back for the next column
150 next x
159 rem wait for a keypress before leaving the graphics screen
160 get a$ : if a$="" then 160
169 rem back to the normal text screen
170 graphic 0
