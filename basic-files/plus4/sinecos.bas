10 scnclr
20 graphic 1,1
30 ox=160 : oy=100
40 draw 1,0,oy to 319,oy
50 draw 1,ox,0 to ox,199
60 px=0 : py=oy-int(80*sin((0-ox)*.0393))
70 qx=0 : qy=oy-int(80*cos((0-ox)*.0393))
80 for x=1 to 319
90 y=oy-int(80*sin((x-ox)*.0393))
100 draw 1,px,py to x,y
110 px=x : py=y
120 z=oy-int(80*cos((x-ox)*.0393))
130 draw 1,qx,qy to x,z
140 qx=x : qy=z
150 next x
160 get a$ : if a$="" then 160
170 graphic 0
