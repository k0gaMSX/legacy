
{ This file contains procedures and functions for Random Access Disc Files:

  For an example of their use see BIRTHDAY.PAS

  READRAND is a function which returns TRUE if a record can not be found
  on the disc. It returns FALSE if the data was read successfully.
  The first parameter is the Text File variable you wish to read. This should
  be opened using RESET (or REWRITE if you use WRITERAND on it first).
  The second parameter is the File Component you wish to read starting from 0.
  The third parameter is the address of the variable you wish to read.
  The fourth parameter is the size (in bytes) of the file components.

  WRITERAND is a procedure with 4 parameters:
  The first parameter is the Text File variable you wish to write to.
  The second parameter is the number of the File Component you wish to read.
  The third parameter is the address of the variable you wish to write.
  The fourth parameter is the size of the components.

  CLOSE which is a procedure with one file parameter which must be called
  to close a file which has been written to using WRITERAND.
 }

FUNCTION READR(VAR F:TEXT;I,B:INTEGER):INTEGER;

VAR DUM:INTEGER;
BEGIN
 POKE(ADDR(F)+40,I);POKE(ADDR(F)+42,CHR(0));
 DUM:=CPM(26,B); { Set DMA address }
 READR:=CPM(33,ADDR(F)+7); { Random read }
END;

FUNCTION WRITER(VAR F:TEXT;I,B:INTEGER):INTEGER;

VAR DUM:INTEGER;
BEGIN
 POKE(ADDR(F)+40,I);POKE(ADDR(F)+42,CHR(0));
 DUM:=CPM(26,B); { Set DMA address }
 READR:=CPM(34,ADDR(F)+7); { Random write }
END;

FUNCTION READRAND(VAR F:TEXT;LOGREC,adr,nbytes:INTEGER):BOOLEAN;
VAR BYTENO:REAL;
    valid,snum,offset,start,i:INTEGER;
    nomore:BOOLEAN;
    b: ARRAY[1..128] OF CHAR;
BEGIN

 BYTENO:=LOGREC * nbytes;
 snum:=ENTIER(BYTENO/128);
 offset:=ROUND(BYTENO-snum*128);
 start:=0;

 nomore:=FALSE;
 REPEAT
   IF READR(F,snum,ADDR(b)) <> 0 THEN nomore:=TRUE
   ELSE

    BEGIN
     IF offset+nbytes-start>128 THEN valid:=128-offset
			  ELSE valid:=nbytes-start;
     FOR i:=0 TO valid-1 DO POKE(adr+start+i,b[offset+1+i]);

     start:=start+valid;
     snum:=snum+1;offset:=0;
    END
 UNTIL (start=nbytes) OR nomore;

 
 READRAND:=nomore;
END;

PROCEDURE WRITERAND(VAR F:TEXT;LOGREC,adr,nbytes:INTEGER);
VAR BYTENO:REAL;
    dum,valid,snum,offset,start,i:INTEGER;
    b: ARRAY[1..128] OF CHAR;
BEGIN

 BYTENO:=LOGREC * nbytes;
 snum:=ENTIER(BYTENO/128);
 offset:=ROUND(BYTENO-snum*128);
 start:=0;
 REPEAT
    dum:= READR(F,snum,ADDR(b));
  
    BEGIN
     IF offset+nbytes-start>128 THEN valid:=128-offset
			  ELSE valid:=nbytes-start;
    FOR i:=0 TO valid-1 DO b[offset+1+i]:=PEEK(adr+start+i,CHAR);
     dum:= WRITER(F,snum,ADDR(b));
     start:=start+valid;
     snum:=snum+1;offset:=0;
    END
 UNTIL (start=nbytes);

 
END;	

PROCEDURE CLOSE(VAR F:TEXT);
VAR dum:INTEGER;
BEGIN
 POKE(ADDR(F)+4,CHR(1)); { fool the run-time system into thinking its a read file}
 dum:=CPM(16,ADDR(F)+7);
END;
R;
BEGIN
 POKE(ADDR(F)+4,CHR(1)); { fool the run-time system into t