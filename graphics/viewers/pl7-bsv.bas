9 CLEAR 1000
10 MAXFILES=3
20 OPEN"dir"FORINPUTAS#1
40   INPUT #1,X$
50 N$=LEFT$(X$,8)+"."+MID$(X$,10,3)
60 NN$=LEFT$(N$,8)
65  PRINT N$
70 OPEN N$ FOR INPUT AS #2
80 OPEN NN$ FOR OUTPUT AS #3
90  PRINT #3,"1234567";
100 FOR X=1 TO 256
110 A$=INPUT$(128,#2)
120 PRINT #3,A$;
130 ' A$=INPUT$(128,#2)
140 'PRINT #3,A$;
150 CLOSE #2,#3
160 GOTO  40
