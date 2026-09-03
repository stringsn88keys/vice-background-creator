10 scnclr
20 graphic 1,1
30 px=0 : py=100
40 for x=1 to 319
50 y=100+int(80*sin(x*.0393))
60 draw 1,px,py to x,y
70 px=x : py=y
80 next x
90 get a$ : if a$="" then 90
100 graphic 0
