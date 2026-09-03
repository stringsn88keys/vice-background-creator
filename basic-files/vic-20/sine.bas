10 print chr$(147)
20 for x=0 to 21
30 y=10+int(8*sin(x*.5712))
40 poke 7680+y*22+x,42
50 poke 38400+y*22+x,6
60 next x
70 goto 70
