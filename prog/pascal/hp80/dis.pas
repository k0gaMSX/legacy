PROGRAM disassembler;
{$O- is used so that e.g. #7F80+#99 does not give overflow}

{ (C) Copyright David Nutkins 1984.
  This program lets you disassemble a .COM and interactively
  set up data areas which may be saved to disc (in a .DIS file)
  so they do not have to be re-entered on subsequent sessions.
  Disassembly may be of all or part of the program and sent to
  disc (as a .GEN file) or screen.

  When compiled use
  DIS filename.COM

  to disassemble filename.COM


  There are 4 sorts of data areas that may be specified:
  1. Messages. Disassmbled as DEFM and DEFB
  2. Byte Data. Disassembled as DEFB
  3. Word data. Disassembled as DEFW - useful for jump tables etc
  4. Space. Disassembled as DEFS - avoids disassembling junk.

  Commands are entered in the form of a single letter normally
  followed by two hexadecimal numbers. For details of the commands
  use the H (for Help) command and see the procedures in this file.

  Only exit using E or X do not use CTRL C.

  Some of the techniques used in this program are very machine
  specific and it is not an example of how to program in Pascal
  in general but it does show how to use the Hisoft Pascal extentions
  to provide a systems programming tool of pratical use.

  If there is a feature that you dislike or think should be added,
  then feel free to improve it. }

LABEL 99;

{ In the following X is the maximum file size that can be disaasembled}
CONST tablesize=31; {  X*4-1}
      fsize=64;     {  X*8 }
      gsize=1;
      datasize=30;

TYPE flag=(B,W,S,M); {Byte, Word, Space, Message }
     filename=ARRAY [1..14] OF CHAR;
     datarec=RECORD
                 sta,fin:INTEGER;
                 type:flag
             END;

VAR runstart,codestart,finish,size:INTEGER;
    i,ch,oldcx,cx,dnext,olddx,dx:INTEGER;
    com:CHAR;
    Xreg:(HL,IX,IY);
    firstdone,indexed:BOOLEAN;
    opc:0..63;
    typ,top2:0..3;
    top,bot:0..7;
    legal,meslegal,mesilleg,allchars: SET OF CHAR;
    data:ARRAY[1..datasize] OF datarec;
    table:ARRAY[0..tablesize] OF SET OF 0..255;
    dfile:TEXT;
    infile:TEXT[fsize];
    gfile: TEXT[gsize];
    fname:filename;

{$F HEX }

PROCEDURE getfname;
VAR i:1..11;
    ch:CHAR;
BEGIN
 ch:=PEEK(#5C,CHAR);
 IF ch=CHR(0) THEN ch:=' ' ELSE ch:=CHR(64+ORD(ch));
 fname[1]:=ch;
 FOR i:=1 TO  8 DO fname[i+2]:=PEEK(#5C+i,CHAR);
 FOR i:=9 TO 11 DO fname[i+3]:=PEEK(#5C+i,CHAR)
END;

PROCEDURE DataEnter(lo,hi:INTEGER;f:flag);
VAR i,j:INTEGER;cur:datarec;
BEGIN
  WITH cur DO
    BEGIN
     sta:=lo-runstart;fin:=hi-runstart;type:=f
    END;
  data[dnext]:=cur;
  i:=1;
  WHILE cur.sta>data[i].sta DO i:=i+1;
  FOR j:=dnext DOWNTO i DO data[j+1]:=data[j];
  dnext:=dnext+1;
  data[i]:=cur
END;

PROCEDURE EnterCommand(f:flag);
BEGIN
 DataEnter(READHEX(INPUT),READHEX(INPUT),f)
END;

{ K command - removes data area i where i is as given by the D command }
PROCEDURE KillData;
VAR i,j:INTEGER;
BEGIN
 READ(i);
 dnext:=dnext-1;
 FOR j:=i TO dnext DO data[j]:=data[j+1]
END;

{ D command - displays the current data  areas }
PROCEDURE ListData(VAR f:TEXT);
VAR i:INTEGER;
BEGIN
  FOR i:=1 TO dnext-1 DO
       WITH data[i] DO
           BEGIN
               WRITE(f,i,sta+runstart:6:H,fin+runstart:6:H);
               CASE type OF
               B: WRITE(f,'  Byte');
               M: WRITE(f,'  Mess');
               S: WRITE(f,'  Space');
               W: WRITE(f,'  Word')
               END;
               WRITELN(f)
          END
END;

PROCEDURE extdis;
BEGIN
 fname[12]:='D';fname[13]:='I';fname[14]:='S';
END;

{ P command saves the address and data information to .DIS file }
PROCEDURE Put;
BEGIN
 extdis;
 REWRITE(dfile,fname);
 WRITELN(dfile,runstart:4:H,finish:6:H);
 ListData(dfile)
END;

{ R command retrives the info from a .DIS file - useful if
  you have made a lot of mistakes }
PROCEDURE Get;
VAR lo,hi,junk:INTEGER; f:flag;
BEGIN
 extdis;
 RESET(dfile,fname);
 dnext:=1;
 runstart:=READHEX(dfile);
 finish:=READHEX(dfile);
 WHILE NOT EOF(dfile) DO
       BEGIN
          READ(dfile,junk);
          lo:=READHEX(dfile);
          hi:=READHEX(dfile);
          WHILE dfile^=' ' DO GET(dfile);
          CASE dfile^ OF
          'B': f:=B;
          'M': f:=M;
          'S': f:=S;
          'W': f:=W
          END;
          DataEnter(lo,hi,f);
          READLN(dfile)
       END
END;


PROCEDURE getch;
BEGIN
 ch:=ORD(PEEK(cx+codestart,CHAR));
 cx:=cx+1;
END;

FUNCTION getaddr:INTEGER;
VAR lo,hi:INTEGER;
BEGIN
 getch;lo:=ch;
 getch;hi:=ch;
 IF hi>127 THEN  hi:=hi-256;
 IF hi=-128 THEN getaddr:=#8000+lo
            ELSE getaddr:=256*hi+lo
END;

FUNCTION inrange(i:INTEGER):BOOLEAN;
BEGIN
  i:=i-runstart;
  inrange:=(i>=0) AND (i<=finish)
END;

PROCEDURE enter(adr:INTEGER);
BEGIN
 IF inrange(adr) THEN
     BEGIN
       adr:=adr-runstart;
       table[adr DIV 256]:=table[adr DIV 256] +[adr MOD 256]
     END;
END;


PROCEDURE getbits;
BEGIN
 getch;
 typ:=ch DIV 64; opc:=ch MOD 64;
 top:=opc DIV  8; bot:=opc MOD  8;
 top2:=top DIV 2;
END;

FUNCTION eaddr:INTEGER;
VAR off:INTEGER;
BEGIN
 getch;
 IF ch>127 THEN off:=-256 ELSE off:=0;
 eaddr:=off+ch+cx+runstart
END;

PROCEDURE defmod;
VAR maxcx,end:INTEGER;
BEGIN
 WITH data[dx] DO
   BEGIN
       CASE type OF
       M: IF PEEK(cx+codestart,CHAR) IN meslegal THEN
                BEGIN legal:=meslegal;maxcx:=MAXINT END
           ELSE BEGIN legal:=mesilleg;maxcx:=cx+4   END;
       S:       BEGIN legal:=allchars;maxcx:=MAXINT END
       ELSE     BEGIN legal:=allchars;maxcx:=cx+4   END;
       cx:=cx+1;
       end:=data[dx].fin+1;
       WHILE (cx<maxcx) AND NOT (cx MOD 256 IN table[cx DIV 256])
                AND (cx<end) AND (PEEK(cx+codestart,CHAR) IN legal)
                        DO cx:=cx+1;
   END;
 IF cx=end THEN dx:=dx+1
END;

PROCEDURE nn1;
BEGIN
 enter(getaddr)
END;

PROCEDURE pass1byte;
PROCEDURE r1;
BEGIN
 IF indexed THEN cx:=cx+1;
END;

BEGIN
 IF cx>=data[dx].sta THEN defmod
 ELSE
BEGIN
 getbits;
 CASE typ OF
       0:CASE bot OF
               0: IF top>1 THEN enter(eaddr);
               1: IF NOT ODD(top) THEN nn1;
               2: IF top>3 THEN nn1;
               4,5: r1;
               6: BEGIN r1;getch END
         END;
       1,2:r1;
       3:CASE bot OF
               2:nn1;
               3:CASE top OF
                       0:nn1;
                       1:BEGIN getbits;r1  END;
                       2,3:getch
                 END;
               4:nn1;
               5:IF ODD(top) THEN
                  CASE top2 OF
                       0:nn1;
                       1,3:BEGIN indexed:=TRUE;pass1byte END;
                       2:BEGIN
                               getbits;
                               IF (typ=1) AND (bot=3) THEN nn1;
                         END
                 END;
               6:getch
        END
  END
 END
END;

PROCEDURE FirstPass;
LABEL 99;
VAR i:INTEGER;
BEGIN
 IF firstdone THEN GOTO 99;
 WRITELN('Performing first pass');
 firstdone:=TRUE;
 data[dnext].sta:=MAXINT;
 FOR i:=0 TO tablesize DO table[i]:=[];
 cx:=0;
 dx:=1;
 REPEAT
       Xreg:=HL;
       indexed:=FALSE;
       IF cx>=data[dx].sta THEN
            WITH data[dx] DO
               BEGIN
                  IF type=W THEN WHILE cx<=fin DO nn1;
                  cx:=fin+1;
                  dx:=dx+1
               END
       ELSE pass1byte
 UNTIL cx>finish;
99:
END;


PROCEDURE SecondPass(VAR gfile:TEXT;prn:BOOLEAN);
VAR i,secondfin:INTEGER;

PROCEDURE gX;
BEGIN
 CASE Xreg OF
  HL:WRITE(gfile,'HL');
  IX:WRITE(gfile,'IX');
  IY:WRITE(gfile,'IY')
 END
END;

PROCEDURE n;
BEGIN
 getch;
 WRITE(gfile,'#',ch:2:H)
END;

PROCEDURE nn;
VAR i:INTEGER;
BEGIN
 i:=getaddr;
 IF inrange(i) THEN WRITE(gfile,'L') ELSE WRITE(gfile,'#');
 WRITE(gfile,i:4:H)
END;

PROCEDURE bnn;
BEGIN
 WRITE(gfile,'(');
 nn;
 WRITE(gfile,')')
END;

PROCEDURE oneDEFW;
BEGIN
    WRITE(gfile,'DEFW ');
    cx:=oldcx;
    nn
END;

PROCEDURE e;
VAR i:INTEGER;
BEGIN
 i:=eaddr;
 IF inrange(i) THEN WRITE(gfile,'L') ELSE WRITE(gfile,'#');
 WRITE(gfile,i:4:H)
END;

PROCEDURE Xb;
BEGIN
 WRITE(gfile,'(');
 gX;
 ch:=ORD(PEEK(codestart+oldcx+2,CHAR));
 cx:=cx+1;
 IF ch>127 THEN WRITE(gfile,ch-256:0) ELSE WRITE(gfile,'+',ch:0);
 WRITE(gfile,')')
END;

PROCEDURE reg(no:INTEGER);
BEGIN
 CASE no OF
       4:WRITE(gfile,'H');
       5:WRITE(gfile,'L');
       6:IF indexed THEN Xb ELSE WRITE(gfile,'(HL)');
       7:WRITE(gfile,'A')
 ELSE  WRITE(gfile,CHR(no+ORD('B')));
END;

PROCEDURE cc(i:INTEGER);
BEGIN
 CASE i OF
       0:WRITE(gfile,'NZ');
       1:WRITE(gfile,'Z');
       2:WRITE(gfile,'NC');
       3:WRITE(gfile,'C');
       4:WRITE(gfile,'PO');
       5:WRITE(gfile,'PE');
       6:WRITE(gfile,'P');
       7:WRITE(gfile,'M')
 END
END;

PROCEDURE dd(i:INTEGER);
BEGIN
 CASE i OF
       0:WRITE(gfile,'BC');
       1:WRITE(gfile,'DE');
       2:gX;
       3:WRITE(gfile,'SP')
 END
END;

PROCEDURE qq(i:INTEGER);
BEGIN
 CASE i OF
       0:WRITE(gfile,'BC');
       1:WRITE(gfile,'DE');
       2:gX;
       3:WRITE(gfile,'AF')
 END
END;

PROCEDURE addop(a:INTEGER);
BEGIN
 CASE a OF
       0:WRITE(gfile,'ADD A,');
       1:WRITE(gfile,'ADC A,');
       2:WRITE(gfile,'SUB ');
       3:WRITE(gfile,'SBC A,');
       4:WRITE(gfile,'AND ');
       5:WRITE(gfile,'XOR ');
       6:WRITE(gfile,'OR ');
       7:WRITE(gfile,'CP ')
 END
END;

PROCEDURE byte;
VAR i:INTEGER;

PROCEDURE cb;
BEGIN
 IF indexed THEN cx:=cx+1;
 getbits;
 IF indexed THEN cx:=cx-1;
 CASE typ OF
       0: CASE top OF
               0:WRITE(gfile,'RLC ');
               1:WRITE(gfile,'RRC ');
               2:WRITE(gfile,'RL ');
               3:WRITE(gfile,'RR ');
               4:WRITE(gfile,'SLA ');
               5:WRITE(gfile,'SRA ');
               6:WRITE(gfile,'SLO ');
               7:WRITE(gfile,'SRL ')
          END;
       1:WRITE(gfile,'BIT ');
       2:WRITE(gfile,'RES ');
       3:WRITE(gfile,'SET ')
 END;
 IF typ>0 THEN WRITE(gfile,top:0,',');
 reg(bot)
END;

PROCEDURE ed;
  PROCEDURE idr;
   BEGIN
       CASE top OF
               4:WRITE(gfile,'I');
               5:WRITE(gfile,'D');
               6:WRITE(gfile,'IR');
               7:WRITE(gfile,'DR')
       END;
   END;
BEGIN
 getbits;
 CASE typ OF
       1:CASE bot OF
               0:BEGIN
                  WRITE(gfile,'IN ');reg(top);WRITE(gfile,',(C)')
                 END;
               1:BEGIN
                  WRITE(gfile,'OUT (C),');reg(top)
                 END;
               2:BEGIN
                  IF ODD(top) THEN WRITE(gfile,'ADC HL,')
                              ELSE WRITE(gfile,'SBC HL,');
                  dd(top2)
                 END;
               3:BEGIN
                  WRITE(gfile,'LD ');
                  IF ODD(top) THEN BEGIN dd(top2);WRITE(gfile,',');bnn END
                              ELSE BEGIN bnn;WRITE(gfile,',');dd(top2) END
                 END;
               4: CASE top OF
                       0:WRITE(gfile,'NEG')
                  END;
               5:CASE top OF
                       0:WRITE(gfile,'RETN');
                       1:WRITE(gfile,'RETI')
                 END;
               6:CASE top OF
                       0:WRITE(gfile,'IM 0');
                       2:WRITE(gfile,'IM 1');
                       3:WRITE(gfile,'IM 2')
                 END;
               7: CASE top OF
                       0:WRITE(gfile,'LD I,A');
                       1:WRITE(gfile,'LD R,A');
                       2:WRITE(gfile,'LD A,I');
                       3:WRITE(gfile,'LD A,R');
                       4:WRITE(gfile,'RRD');
                       5:WRITE(gfile,'RLD')
                  END
        END;
       2:CASE bot OF
               0:BEGIN WRITE(gfile,'LD');idr END;
               1:BEGIN WRITE(gfile,'CP');idr END;
               2:BEGIN WRITE(gfile,'IN');idr END;
               3:CASE top OF
                       4:WRITE(gfile,'OUTI');
                       5:WRITE(gfile,'OUTD');
                       6:WRITE(gfile,'OTIR');
                       7:WRITE(gfile,'OTDR')
                 END
         END
  END
END;

PROCEDURE typ0;
BEGIN
 CASE bot OF
       0:CASE top OF
               0: WRITE(gfile,'NOP');
               1: WRITE(gfile,'EX AF,AF''');
               2: BEGIN WRITE(gfile,'DJNZ ');e END;
               3: BEGIN WRITE(gfile,'JR ');e END;
               4: BEGIN WRITE(gfile,'JR NZ,');e END;
               5: BEGIN WRITE(gfile,'JR Z,');e END;
               6: BEGIN WRITE(gfile,'JR NC,');e END;
               7: BEGIN WRITE(gfile,'JR C,');e END
         END;
       1:IF ODD(top) THEN
               BEGIN
                WRITE(gfile,'ADD ');
                gX;
                WRITE(gfile,',');
                dd(top2)
               END
         ELSE
               BEGIN
                WRITE(gfile,'LD ');dd(top2);WRITE(gfile,',');nn
               END;
       2:BEGIN
               WRITE(gfile,'LD ');
               CASE top OF
                0: WRITE(gfile,'(BC),A');
                1: WRITE(gfile,'A,(BC)');
                2: WRITE(gfile,'(DE),A');
                3: WRITE(gfile,'A,(DE)');
                4: BEGIN bnn;WRITE(gfile,',');gX; END;
                5: BEGIN gX;WRITE(gfile,',');bnn END;
                6: BEGIN bnn;WRITE(gfile,',A') END;
                7: BEGIN WRITE(gfile,'A,');bnn END
               END
         END;
       3:IF ODD(top) THEN
               BEGIN
                WRITE(gfile,'DEC ');dd(top2)
               END
         ELSE
               BEGIN
                WRITE(gfile,'INC ');dd(top2)
               END;
       4:BEGIN
               WRITE(gfile,'INC ');
               reg(top)
         END;
       5:BEGIN
               WRITE(gfile,'DEC ');
               reg(top)
         END;
       6:BEGIN
               WRITE(gfile,'LD ');
               reg(top);
               WRITE(gfile,',');
               n
         END;
       7:CASE top OF
               0: WRITE(gfile,'RLCA');
               1: WRITE(gfile,'RRCA');
               2: WRITE(gfile,'RLA');
               3: WRITE(gfile,'RRA');
               4: WRITE(gfile,'DAA');
               5: WRITE(gfile,'CPL');
               6: WRITE(gfile,'SCF');
               7: WRITE(gfile,'CCF')
         END
  END

END;

PROCEDURE typ1;
BEGIN
  IF opc=#36 THEN WRITE(gfile,'HALT') ELSE
        BEGIN
          WRITE(gfile,'LD ');
          reg(top);
          WRITE(gfile,',');
          reg(bot)
        END
END;

PROCEDURE typ2;
BEGIN
  addop(top);
  reg(bot)
END;

PROCEDURE typ3;
BEGIN
 CASE bot OF
       0: BEGIN
               WRITE(gfile,'RET ');
               cc(top)
          END;
       1:IF ODD(top) THEN
               CASE top2 OF
                0:WRITE(gfile,'RET');
                1:WRITE(gfile,'EXX');
                2:BEGIN WRITE(gfile,'JP (');gX;WRITE(gfile,')') END;
                3:BEGIN WRITE(gfile,'LD SP,'); gX END
               END
         ELSE
           BEGIN
               WRITE(gfile,'POP '); qq(top2)
           END;
       2: BEGIN
               WRITE(gfile,'JP ');
               cc(top);
               WRITE(gfile,',');
               nn
          END;
       3: CASE top OF
               0:BEGIN WRITE(gfile,'JP ');nn END;
               1:cb;
               2:BEGIN WRITE(gfile,'OUT (');n;WRITE(gfile,'),A') END;
               3:BEGIN WRITE(gfile,'IN A,(');n;WRITE(gfile,')') END;
               4:BEGIN WRITE(gfile,'EX (SP),');gX END;
               5:WRITE(gfile,'EX DE,HL');
               6:WRITE(gfile,'DI');
               7:WRITE(gfile,'EI')
         END;
       4:BEGIN
               WRITE(gfile,'CALL ');
               cc(top);
               WRITE(gfile,',');
               nn
          END;
       5:IF ODD(top) THEN
               CASE top2 OF
                0: BEGIN WRITE(gfile,'CALL ');nn END;
                1: BEGIN indexed:=TRUE;Xreg:=IX;byte END;
                2: ed;
                3: BEGIN indexed:=TRUE;Xreg:=IY;byte END
               END
          ELSE
               BEGIN
                WRITE(gfile,'PUSH ');qq(top2)
               END;
       6:BEGIN
               addop(top);
               n
         END;
       7: WRITE(gfile,'RST #',top*8:2:H)
    END
END;

PROCEDURE dodata;
VAR i:INTEGER;
       PROCEDURE dodefb;
       VAR i:INTEGER;
       BEGIN
           WRITE(gfile,'DEFB ');
           FOR i:=oldcx TO cx-1 DO
               BEGIN
                       IF i>oldcx THEN WRITE(gfile,',');
                       WRITE(gfile,'#',ORD(PEEK(i+codestart,CHAR)):2:H)
               END
        END;
 BEGIN
   defmod;
   CASE data[olddx].type OF
         B: dodefb;
         M: IF PEEK(codestart+oldcx,CHAR) IN mesilleg THEN dodefb ELSE
               BEGIN
                  WRITE(gfile,'DEFM "');
                  FOR i:=oldcx TO cx-1 DO
                       WRITE(gfile,PEEK(i+codestart,CHAR));
                  WRITE(gfile,'"')
               END;
         S: WRITE(gfile,'DEFS ',cx-oldcx:0);
         W: CASE cx-oldcx OF
               1,3: BEGIN WRITE('Error in DEFW');READLN END;
               2: oneDEFW;
               4: BEGIN   oneDEFW; WRITE(gfile,','); nn END
            END
   END
END;

BEGIN {Byte}
 IF cx>=data[dx].sta THEN dodata
  ELSE
    BEGIN
       getbits;
       CASE typ OF
          0: typ0;
          1: typ1;
          2: typ2;
          3: typ3
       END
   END
END;


BEGIN  {SecondPass}
 FirstPass;
 IF EOLN THEN BEGIN  cx:=0;secondfin:=finish END
         ELSE BEGIN  cx:=READHEX(INPUT)-runstart;
                     secondfin:=READHEX(INPUT)-runstart
              END;
 dx:=1;
 WHILE cx>data[dx].sta DO dx:=dx+1;
 IF dx>1 THEN IF data[dx-1].fin>=cx THEN dx:=dx-1;

 REPEAT
   Xreg:=HL;
   indexed:=FALSE;
   oldcx:=cx;olddx:=dx;
   pass1byte;
   IF prn THEN
       BEGIN
          WRITE(gfile,oldcx+runstart:4:H,' ');
          IF cx-oldcx>4 THEN WRITE(gfile,CHR(9)) ELSE
               FOR i:=oldcx TO cx-1 DO WRITE(gfile,ORD(PEEK(codestart+i,CHAR)):2:H);
          WRITE(gfile,' ':2,CHR(9))
       END;
   cx:=oldcx;dx:=olddx;
   IF cx MOD 256 IN table[cx DIV 256] THEN WRITE(gfile,'L',runstart+cx:4:H);
   IF prn THEN WRITE(gfile,CHR(9)) ELSE WRITE(gfile,' ');
   byte;
   IF prn AND (cx-oldcx<=4) THEN
     BEGIN
       WRITE(gfile,';');
       FOR i:=oldcx TO cx-1 DO
           BEGIN
               ch:=ORD(PEEK(codestart+i,CHAR));
               IF ch>127 THEN ch:=ch-128;
               IF ch<32 THEN ch:=ORD('.');
               WRITE(gfile,CHR(ch))
           END
     END;
   WRITELN(gfile);
UNTIL cx>secondfin
END;

{ G command - Generates a .GEN file of disaassembly }
PROCEDURE Generate;
BEGIN
 fname[12]:='G';fname[13]:='E';fname[14]:='N';
 REWRITE(gfile,fname);
 FirstPass;
 WRITELN('Performing second pass');
 SecondPass(gfile,FALSE)
END;

PROCEDURE Help;
BEGIN
 WRITELN('B     Byte Data');
 WRITELN('D     Display data areas');
 WRITELN('E,X   Exit to CP/M');
 WRITELN('G     Generate dissassembly to disc');
 WRITELN('H     Help');
 WRITELN('K     Kill data area');
 WRITELN('L     List disassembly');
 WRITELN('M     Message Data');
 WRITELN('P     Put .DIS file to disc');
 WRITELN('R     Get .DIS file from disc');
 WRITELN('S     Space data');
 WRITELN('W     Word data');
 WRITELN

END;

BEGIN
 getfname;
 RESET(infile,fname);
 IF EOF(infile) THEN
    BEGIN
       WRITELN('No file');
       GOTO 99;
    END;

 extdis;
 RESET(dfile,fname);
 IF EOF(dfile) THEN
    BEGIN
       WRITE('Run Address ?');runstart:=READHEX(INPUT);
       WRITE('End Address ?');READLN;finish:=READHEX(INPUT)-runstart;
       dnext:=1
    END
  ELSE Get;

 codestart:=ADDR(infile)+40;
 meslegal:=[' '..'~'];
 allchars:=[CHR(0)..CHR(255)];
 mesilleg:=allchars-meslegal;
 firstdone:=FALSE;
 REPEAT
       READLN;
       READ(com);
       com:=upper(com);
       IF com IN ['B','K','R','S','W'] THEN firstdone:=FALSE;
       CASE com OF
       'B': EnterCommand(B);
       'D': ListData(OUTPUT);
       'G': Generate;
       'K': KillData;
       'H','?': Help;
       'L': SecondPass(OUTPUT,TRUE);
       'M': EnterCommand(M);
       'P': Put;
       'R': Get;
       'S': EnterCommand(S);
       'W': EnterCommand(W)
       END;
 UNTIL (com='E') OR (com='X');
99:
END.
 'R': Get;
       'S': EnterCommand(S);
     êa!¼xå*®x+ Íg@ ÍÑå!H{å!èzå*®x+ Íg ÍÑ^#Vë ÍgÑå!¬zå*®x+ Íg)]T)Ñå! + Íg)Ñ^#VëÍæ!°xå*®x+ Íg)Ñå!¼xå*®x+ Íg@ ÍÑå! @ ÍgÑn& å!¼xå*®x+ Íg@ ÍÑå!  @ ÍgÑn& Ñë·íRå! Ñë·íRëás#rÃwb!°xå*®x+ Íg)Ñå!  ëás#r*®x#ÑÃó_!<zå! n&  ÍgÑn&    Íq}2ÅvÍ¢Í×Got parameters.ÍæÍT 7pÃ= !+pÍ#*½v& å!<zå! n&  ÍgÑn& å!  ÑÍšÑ}£oËEÊGcÍ¢Í×Not saved. Default drive (! n& å!A ÑÍHÍ×) is off-line.ÍæÍTÃÍf*¨xå!ý Ñå*Äv&    Íqëás*¨xå! Ñë·íRå!<zå! åÍã*½v& ËEÊ“c*¨xå! Ñ"-pÃ¢c*ªxå! Ñë·íR"-p*-på! Ñ"+p! å! ÑÍz³ÊºfÕ"®x!µvå*®x ÍgÑn& ËEÊve!èzå*®x+ Íg ÍÑ"/p!Lzå*®x+ Íg ÍÑ"1p!°xå*®x+ Íg)Ñ^#Vëå!  ÑÍ­ËEÊe*-pë*/ps#r*-på!¬zå*®x+ Íg)]T)Ñå! + Íg)Ñ^#VëÑ"-p*½v& ËEÊ¾d*/p^#Vëå!¼xå*®x+ Íg@ ÍÑå!¬zå*®x+ Íg)]T)Ñå! + Íg)Ñ^#VëåÍãÃe!H{å*/p^#Vë ÍgÑå!¼xå*®x+ Íg@ ÍÑå!¬zå*®x+ Íg)]T)Ñå! + Íg)Ñ^#VëÍæÃ e!  ë*/ps#r*/p å*-pëás#r*-på*1p ^#VëÑ"-p*/p å*-pëás#r*-på*1p ^#Vëå! ÑÍ*Ñå! Ñ"-p*-på*+pÑÍçËEÊ¼eÍ¢Í×)Warning : Buffer and check area conflict.ÍæÍT*¨xå!* å*®xå! Ñë·íRÑÍÑå!èzå*®x+ Íg ÍÑå! åÍã*¨xå!* å*®xå! Ñë·íRÑÍÑå! Ñå!Ðzå*®x+ Íg ÍÑå! åÍã*¨xå!* å*®xå! Ñë·íRÑÍÑå! Ñå!¬zå*®x+ Íg)]T)Ñå! åÍã*¨xå!* å*®xå! Ñë·íRÑÍÑå! Ñå!Lzå*®x+ Íg ÍÑå! åÍã*®x#ÑÃ¹cÍ¢Í×Saved.ÍæÍT +pÃ=!
åÍMå! ÑÍ["³v!
åÍMå! ÑÍ*"±v!  å!  åÍöÍh4AllDisc Configure utility [1.2] : F(ile or M(emory? !  å!  åÍœ!F Í¬!M Í¬ÍL   Íq}2ÈvÍ¢ÍæÍT!     Íq}2¾v!     Íq}2½v*Èv& F ·íRÂÆgÍ¶\*¾v& ËEÊÃg!H{å*ªxå! Ñë·íR ÍgÑ"¨xÃbhM ·íRÂbh! åÍMå! Ñë·íRå! åÍMå! ÑåÍMå! Ñë·íRÑë·íRå! ÑÍš   Íq}2½v*½v& }îoËEÊEhÍ¢Í×AllDisc not in place.ÍæÍT! åÍMå! ÑåÍMå!Ñë·íR"¨x*¾v& å*½v& Ñ}³oËEÊ›jÍ¡VÍ®_!  å! ÑÍz³Ê¸hÕ"¦x!µvå*¦x ÍgÑå!     Íqëás*¦x#ÑÃ‡h!  å! ÑÍz³ÊiÕ"¦x!µvå!<zå*¦x ÍgÑn&  ÍgÑå!    Íqëás*¦x#ÑÃÃhÍh*G(et params, S(ave params, E(dit, Q(uit ? !  å!  åÍœ!G Í¬!S Í¬!E Í¬!Q Í¬ÍL   Íq}2Çv*Çv& å*Æv& ÑÍ­ËEÊi!  å!  åÍö!  å! Íü*Çv& G ·íRÂ¡iÍ®_Ã¾iS ·íRÂ±iÍÇbÃ¾iE ·íRÂ¾iÍà$*Çv& å!Q ÑÍšËEÊ|h*½v& }îoËEÊäiÍŒ^Ã›j! å! ÑÍz³Ê›jÕ"®x!µvå*®x ÍgÑn& ËEÊ’j!Ðzå*®x+ Íg ÍÑ"x*xn& å!  ÑÍ[å!  ÑÍšËEÊ’j*xn& å! Ñå*x n& Áíi*xn& å*x n& å! ÑÍ[Áíi*xn& Míhå!  åÍD#ËEÊ’jÃyj*®x#ÑÃïiÃÁ ÍÑ"x*xn& å!  ÑÍ[å!  ÑÍšËEÊš*xn& å! Ñå*x n& Áíi*xn& å*x n& å! ÑÍ[Áíi*xn& M
 FirstPass;
 WRITELN('Performing second pass');
 SecondPass(gfile,FALSE)
END;

PROCEDURE Help;
BEGIN
 WRITELN('B     Byte Data');
 WRITELN('D     Display d  ÿÿÿÿÿÿÿÿÿ  ÿÿÿÿÿÿÿÿÿÿ                                                             ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ                                                                                                       ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ  ÿÿÿÿÿÿÿÿÿÿ                                                             ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ                                                                                                    ÿÿÿÿÿ       
       WRITE('End Address ?');READLN;finish:=READHEX(INPUT)-runstart;
       dnext:=1
    END
  ELSE Get;

 codestart:=ADDR(infile)+40;
 meslegal:=[' '..'~'];
 allchars:=[CHR(0)..CHR(255)];
 mesilleg:=allchars-meslegal;
 firstdone:=FALSE;
 REPEAT
       READLN;
       READ(com);
       com:=upper(com);
       IF com IN ['B','K','R','S','W'] THEN firstdone:=FALSE;
       CASE com OF
       'B': EntCCuUCuU`CuU`       6Ï                        