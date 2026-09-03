10 graphic 1,1
20 ox=160 : oy=100
30 draw 1,0,oy to 319,oy
40 draw 1,ox,0 to ox,199
50 px=0 : py=oy-int(80*sin((0-ox)*.0393))
60 for x=1 to 319
70 y=oy-int(80*sin((x-ox)*.0393))
80 draw 1,px,py to x,y
90 px=x : py=y
100 next x
110 get a$ : if a$="" then 110
120 graphic 0
