10 '------------------------------
20 'UNLIMITED LIVES LOADER
30 'SEX BOMB BUNNY
40 'Jose Angel Morente
50 'November, 2nd 1999
60 '------------------------------
70 '
80 CLS
90 L=3:U=&H3D
100 INPUT"Number of lives";L
110 IF L>5 THEN L=5
120 PRINT"Unlimited lives (S/N)":U$=INPUT$(1)
130 IF U$="S" OR U$="s" THEN U=&HA7
140 PRINT:PRINT"Insert the SEX BOMB BUNNY disk"
150 PRINT"and strike any key"
160 K$=INPUT$(1)
170 POKE &HF351,0:POKE &HF352,&HC0
180 A$=DSKI$(0,0)
190 P=&HC000
200 IF NOT (PEEK(P+3)=83 AND PEEK(P+4)=69 AND PEEK(P+5)=88) THEN GOTO 290
210 A$=DSKI$(0,27)
220 POKE P+23,L
230 DSKO$ 0,27
240 A$=DSKI$(0,29)
250 POKE P+188,U
260 DSKO$ 0,29
270 PRINT:PRINT"Done."
280 END
290 PRINT "Wrong disk!!"
300 END
