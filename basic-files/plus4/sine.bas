10 scnclr
20 graphic 1,1
30 ox=160 : oy=100
40 draw 1,0,oy to 319,oy
50 draw 1,ox,0 to ox,199
60 px=0 : py=oy-int(80*sin((0-ox)*.0393))
70 for x=1 to 319
80 y=oy-int(80*sin((x-ox)*.0393))
90 draw 1,px,py to x,y
100 px=x : py=y
110 next x
120 get a$ : if a$="" then 120
130 graphic 0
