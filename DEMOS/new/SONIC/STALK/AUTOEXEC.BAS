1 ' Smiley Talk - 2005
2 '
3 ' original idea/program by Wolf_
4 ' one-lined by Sonic_aka_T
5 '
6 KEYOFF:K$="bcdfghjklmnpqrstvwxzaeiouyaeiouyaeiouyye":S$(0)="(^_^( '":S$(1)=")o_O) '":FORT=0TO9^9:G$="":FORW=0TO1+RND(1)*6:FORC=0TO2+RND(1)*6:G$=G$+MID$(K$,1+((C AND1)*20)+(RND(1)*20),1):NEXT:G$=G$+" ":NEXT:PRINTS$(T AND1)+LEFT$(G$,LEN(G$)-1)+"'":NEXT
