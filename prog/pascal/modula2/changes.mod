(*  I - CHING	 Book of Changes
**
**  Programmed in Turbo Modula-2 for the Kaypro by Jeff Cuff, 11/87
**  Modified for MSXDOS (VT-52) by Pierre Gielen, 4/94
*)

MODULE Changes; (* Reads from an editable, textbased, I Ching *)
FROM  Files IMPORT
                    FileSize, SetPos, NextPos,
                    ReadByte, WriteByte, FILE;
FROM  Texts IMPORT  ReadLine,OpenText,CloseText,
                    TextFile, TEXT, input;
FROM SYSTEM IMPORT BYTE;
FROM Strings IMPORT Delete, Pos, Length, Insert;
FROM Terminal IMPORT GotoXY, ReadChar, ClearScreen;
FROM RND IMPORT SRAND, RAND16;
FROM CUTIL IMPORT UserWantsTo, Blank, Copyright,
		  HitAny,Notice,ShowCursor;

TYPE
    BUFFER = ARRAY [0..47] OF CHAR;
    str6 = ARRAY [0..5] OF CHAR;
    lineray = ARRAY [1..64] OF str6;
    matrx = ARRAY [0..9] OF ARRAY [0..9] OF BUFFER;

VAR
   hx,hy: str6;
   g,h,i,j,k,l,x,y: CARDINAL;
   line : BUFFER;
   question : BUFFER;
   c: CHAR;
   LOOPFLAG: BOOLEAN;
   matrix: matrx;
   hex: ARRAY [1..64] OF str6; (*ordered list of hexagram binary equivalents*)
   t: TEXT;
   b: BYTE;

PROCEDURE LOADHEX;
BEGIN
     hex[1]:='111111';
     hex[2]:='000000';
     hex[3]:='100010';
     hex[4]:='010001';
     hex[5]:='111010';
     hex[6]:='010111';
     hex[7]:='010000';
     hex[8]:='000010';
     hex[9]:='111011';
     hex[10]:='110111';
     hex[11]:='111000';
     hex[12]:='000111';
     hex[13]:='101111';
     hex[14]:='111101';
     hex[15]:='001000';
     hex[16]:='000100';
     hex[17]:='100110';
     hex[18]:='011001';
     hex[19]:='110000';
     hex[20]:='000011';
     hex[21]:='100101';
     hex[22]:='101001';
     hex[23]:='000001';
     hex[24]:='100000';
     hex[25]:='100111';
     hex[26]:='111001';
     hex[27]:='100001';
     hex[28]:='011110';
     hex[29]:='010010';
     hex[30]:='101101';
     hex[31]:='001110';
     hex[32]:='011100';
     hex[33]:='001111';
     hex[34]:='111100';
     hex[35]:='000101';
     hex[36]:='101000';
     hex[37]:='101011';
     hex[38]:='110101';
     hex[39]:='001010';
     hex[40]:='010100';
     hex[41]:='110001';
     hex[42]:='100011';
     hex[43]:='111110';
     hex[44]:='011111';
     hex[45]:='000110';
     hex[46]:='011000';
     hex[47]:='010110';
     hex[48]:='011010';
     hex[49]:='101110';
     hex[50]:='011101';
     hex[51]:='100100';
     hex[52]:='001001';
     hex[53]:='001011';
     hex[54]:='110100';
     hex[55]:='101100';
     hex[56]:='001101';
     hex[57]:='011011';
     hex[58]:='110110';
     hex[59]:='010011';
     hex[60]:='110010';
     hex[61]:='110011';
     hex[62]:='001100';
     hex[63]:='101010';
     hex[64]:='010101';
END LOADHEX;

PROCEDURE OpenError;
BEGIN
	ClearScreen;
	WRITELN('Cannot find datafile');
	HALT;
END OpenError;

PROCEDURE Rand4(): CARDINAL;
BEGIN
	RETURN (RAND16() MOD 16);
END Rand4;

PROCEDURE UpdateHeader;
TYPE
    STR5 = ARRAY [0..4] OF CHAR;
VAR
    line: ARRAY [0..63] OF CHAR;
    S: STR5;
    STRING: ARRAY [0..65] OF STR5;
    INDEX: ARRAY [0..65] OF CARDINAL;
    x,y,z,Offset: CARDINAL;
    l: LONGINT;
    position: CARDINAL;


PROCEDURE Convert(CardInput:CARDINAL; VAR temp: ARRAY OF CHAR );
VAR xx: CARDINAL;
BEGIN

   xx:= CardInput DIV 10000;
   temp[0]:= CHR(48+xx);
   CardInput := CardInput - (xx*10000);

   xx:= CardInput DIV 1000;
   temp[1]:= CHR(48+xx);
   CardInput := CardInput - (xx*1000);

   xx:= CardInput DIV 100;
   temp[2]:= CHR(48+xx);
   CardInput := CardInput - (xx*100);

   xx:= CardInput DIV 10;
   temp[3]:= CHR(48+xx);
   CardInput := CardInput - (xx*10);

   xx:= CardInput;
   temp[4]:= CHR(48+xx);

END Convert;


BEGIN (* UpdateHeader *)

    IF NOT OpenText(t,'I-CHING.') THEN OpenError; END;

    ShowCursor(FALSE);
    FOR x := 0 TO 65 DO INDEX[x]:=0;
                       STRING[x]:='00000';
    END;
    b:=STRING[0,0];

    x:=1; y:=0;
    position:=0;

    REPEAT
        ReadLine(t,line);
        IF line[0]='@' THEN
            INDEX[x]:= position;
            GotoXY(x,10);
            WRITE('*');
            GotoXY(0,14);
            WRITE(position,'===',x);
            x:=x+1;
        END;
        position:= CARD(NextPos(TextFile(t)));
	WRITE(33C,"Y  line ",position:5);
    UNTIL Pos('@@@',line)<>(HIGH(line)+1);

    FOR x := 1 TO 64 DO
        Convert(INDEX[x],STRING[x]);
(*	  WRITE(33C,"Y##string ",x); *)
    END;

        Convert(INDEX[65],STRING[0]);
            INDEX[65] := CARD(FileSize(TextFile(t)));
        Convert(INDEX[65],STRING[65]);

(*    FOR x := 0 TO 65 DO
	WRITELN(x,'==',STRING[x]);
    END;
*)

    SetPos(TextFile(t),129L);
    FOR x:= 0 TO 4 DO
        b:= STRING[0,x];
        WriteByte(TextFile(t),b);
    END;

    Offset:=164-59;
FOR z := 0 TO 7  DO
    Offset:=Offset+(59);
    FOR y := 1 TO 8 DO
        SetPos(TextFile(t),LONG(Offset+(6*y)));
        FOR x:= 0 TO 4 DO
            b:= STRING[y+z*8,x];
            WriteByte(TextFile(t),b);
        END;
    END;
END;

    SetPos(TextFile(t),665L);
    FOR x:= 0 TO 4 DO
        b:= STRING[65,x];
        WriteByte(TextFile(t),b);
    END;
CloseText(t);
ShowCursor(TRUE);
END UpdateHeader;

PROCEDURE makepattern;
VAR LL: ARRAY [0..5] OF CARDINAL;
BEGIN
    LL[0]:= Rand4();
    HitAny;

    LL[1]:= Rand4();
    ClearScreen;
  LOOP;
          GotoXY(20,2); WRITE('[0] - to EXIT The Book of Changes');
          GotoXY(20,5); WRITE('[1] - to Cast a Hexagram');
          GotoXY(20,7); WRITE('[2] - to Retreive a manual casting');
          GotoXY(20,19);WRITE('[*] - to reset Header after editing');
        WRITELN;
        ReadChar(c);
    IF (c='0') THEN ClearScreen; HALT END;
    IF ( (c='1') OR (c='2') ) THEN EXIT; END;
    IF (c='*') AND (UserWantsTo('Are you sure'))
        THEN UpdateHeader;
	     ClearScreen;
	END;
    END;

    LL[2]:= Rand4();

        WRITELN;
        WRITE('Enter your question >');
        ReadLine(input,question);

        IF c='2' THEN
            WRITELN();
          LOOP;
          LOOPFLAG:=TRUE;
	    WRITE('Input cast pattern, 6 figures of {6789} >');
            READLN(line);

            FOR j := 0 TO 5 DO
                 l:=ORD(line[j]);

                 IF ( (l<54) OR (l>57) ) THEN LOOPFLAG:=FALSE; END;
                 (*tests for incorrect input*)

                 IF l = 54 THEN hx[j] := '0'; hy[j] := '1'; END;
                 IF l = 55 THEN hx[j] := '1'; hy[j] := '1'; END;
                 IF l = 56 THEN hx[j] := '0'; hy[j] := '0'; END;
                 IF l = 57 THEN hx[j] := '1'; hy[j] := '0'; END;
            END;
            IF LOOPFLAG THEN EXIT; END;
          END; (*loop*)
        ELSE
            ClearScreen;

	    LL[3]:= Rand4();
	    LL[4]:= Rand4();
	    LL[5]:= Rand4();

           FOR j := 0 TO 5 DO
             IF LL[j] = 0 THEN
                 hx[j] := '0';
                 hy[j] := '1';
             ELSIF ( (LL[j]=11) OR (LL[j]=13) OR (LL[j]=15) ) THEN
                 hx[j] := '1';
                 hy[j] := '0';
             ELSIF ( (LL[j]=2) OR (LL[j]=4) OR (LL[j]=6) OR (LL[j]=8)
                       OR (LL[j]=10) OR (LL[j]=12) OR (LL[j]=14) ) THEN
                 hx[j] := '0';
                 hy[j] := '0';
             ELSIF ( (LL[j]=1) OR (LL[j]=3) OR (LL[j]=5) OR (LL[j]=7)
                       OR (LL[j]=9) ) THEN
                 hx[j] := '1';
                 hy[j] := '1';
             END;
          END;
        END;
END makepattern;


PROCEDURE findslot;
BEGIN
    FOR j := 1 TO 64 DO
         IF hx = hex[j] THEN x := j;END;
         IF hy = hex[j] THEN y := j;END;
    END;
END findslot;

PROCEDURE prepscreen;
VAR yinbit,yangbit: ARRAY [0..11] OF  CHAR;
	count: CARDINAL;
BEGIN
    ClearScreen;
    c:=CHR(240);
    FOR count := 0 TO 11 DO
        yangbit[count]:=c;
    END;
    yinbit:=yangbit;
    FOR count := 4 TO 7 DO
        yinbit[count]:=' ';
    END;

(*{DISPLAY LINES - GRAPHICS}*)
    ShowCursor(FALSE);
    FOR j := 0 TO 5 DO
        GotoXY(1,6-j);
        IF hex[x,j]='1' THEN WRITE(yangbit) ELSE WRITE(yinbit);END;
        GotoXY(68,6-j);
        IF hex[y,j]='1' THEN WRITE(yangbit) ELSE WRITE(yinbit);END;
    END;

(* DISPLAY QUESTION *)
    GotoXY(16,3); WRITE(question);
    Blank(48-Length(question));

(* ONSCREEN HELP *)
    Notice
    (' Use UP & DOWN arrows to read lines, <ESC> to EXIT, <CR> for another');
    GotoXY(1,8);
    Blank(79);
    GotoXY(0,8); WRITE(x);
    GotoXY(71,8);WRITE(y);

END prepscreen;

PROCEDURE EXP(base,exp:CARDINAL):CARDINAL;
VAR ret,cnt	: CARDINAL;
BEGIN
   ret := 1;
   FOR cnt := 1 TO exp DO
       ret := ret * base;
   END;
   IF exp=0 THEN ret:=1;END;
   RETURN ret;
END EXP;


PROCEDURE getfile;
VAR xx,yy,zz: CARDINAL;

    PROCEDURE Inset(x:CARDINAL): CARDINAL;
    VAR Offset,temp,xxx,yyy,zzz: CARDINAL;
        tt: TEXT;
    BEGIN
    IF NOT OpenText(tt,'I-CHING.') THEN OpenError; END;
       temp:= 0;
       zzz:= (x-1) DIV 8;
       yyy:= ((x-1) MOD 8);
       Offset:= 164 + (59*zzz);
       SetPos(TextFile(tt),LONG(Offset+(6*yyy)+6));
       FOR xxx := 0 TO 4 DO
           ReadByte(TextFile(tt),b);
           temp:= temp + ((ORD(b)-48)*(EXP(10,4-xxx)));
       END;
    CloseText(tt);
       RETURN temp;
    END Inset;

BEGIN
    IF NOT OpenText(t,'I-CHING.') THEN HALT; END;
    SetPos(TextFile(t),LONG(Inset(x)));
    ReadLine(t,line);
    GotoXY(10,8);

    Delete(line,0,3);
    WRITE(line);

    ReadLine(t,line);
    FOR xx := 0 TO 7 DO
        yy := 0;
        REPEAT
            matrix [xx,yy] := line;
            yy := yy + 1;
            ReadLine(t,line);
        UNTIL (line[0]='[') OR (line[0]='@');
        IF yy<9 THEN
            FOR zz := yy TO 9 DO
                matrix [xx,zz] := '';
            END;
        END;
    END;

    SetPos(TextFile(t),LONG(Inset(y)));
    ReadLine(t,line);
    Delete(line,0,3);
    GotoXY(70-Length(line),8);
    WRITE(line);

    ReadLine(t,line);
    FOR xx := 8 TO 9 DO
        yy := 0;
        REPEAT
            matrix [xx,yy] := line;
            yy := yy + 1;
            ReadLine(t,line);
        UNTIL (line[0]='[') OR (line[0]='@');
        IF yy<9 THEN
            FOR zz := yy TO 9 DO
                matrix [xx,zz] := '';
            END;
        END;
    END;
    CloseText(t);
END getfile;



PROCEDURE display;
VAR sequence: ARRAY [0..10] OF CHAR;
    c1: ARRAY [0..0] OF CHAR;
    el: CARDINAL;
BEGIN
    IF NOT OpenText(t,'I-CHING.') THEN OpenError; END;
    c1:='';
    IF x=y THEN sequence:='01'
    ELSE
        sequence:='0189';
        FOR j := 5 TO 0 BY -1  DO
            c1[0]:=CHR(48+j+2);
            IF (hex[x,j] <> hex[y,j])
            THEN Insert(c1,sequence,2);
            END;
        END;
    END;
        k:= Length(sequence)-1;
        j:= 0;
        g:=0;
    LOOP;
        FOR el := 0 TO 9 DO
            GotoXY(16,10+el);
             WRITE('                                                   ');
            GotoXY(16,10+el);
             WRITE(matrix[j,el]);
        END;
      LOOP;
        ReadChar(c);
        IF    (c=12C) OR (c=37C) THEN g:= g+1; EXIT; (* DOWN *)
          ELSIF ((c=13C) OR (c=36C))
                AND (g>0) THEN g:= g-1; c:='*'; EXIT;  (* UP *)
          ELSIF (c=33C) THEN g:= 999; EXIT;            (* ESC *)
          ELSIF (c=11C) OR (c=15C) THEN g:= 777; EXIT;            (* TAB *)
        END;
      END;(*LOOP*)
        IF    g=999 THEN EXIT;
          ELSIF g=777 THEN EXIT;
          ELSIF (g=0) AND (c=13C) OR (c=5C) THEN g:=k;
          ELSIF g>k THEN g:=0;
        END;

        IF g<777 THEN j:= (ORD(sequence[g])-48);
        END;
    END; (*LOOP*)
    CloseText(t);
END display;


BEGIN
    SRAND();
    ShowCursor(FALSE);
    Copyright('THE BOOK OF CHANGES','1.11 modula','1987-94',FALSE);
    LOADHEX;
  LOOP;
	ShowCursor(TRUE);
    	makepattern;
	ShowCursor(FALSE);

    findslot;
    prepscreen;
    getfile;
    display;
                                                          (* journal; *)
    IF g=999 THEN EXIT;END;
  END;
    ShowCursor(TRUE);
    ClearScreen;
END Changes.
                                 