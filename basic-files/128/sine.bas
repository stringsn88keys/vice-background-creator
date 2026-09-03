10 graphic 1,1
20 px=0 : py=100
30 for x=1 to 319
40 y=100+int(80*sin(x*.0393))
50 draw 1,px,py to x,y
60 px=x : py=y
70 next x
80 get a$ : if a$="" then 80
90 graphic 0
