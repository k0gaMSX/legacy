
PROGRAM birthday;
{ This program is a small example of the use of the random access facilities
  in the file RANDREC.PAS.  In fact this simple program could be written more
  efficiently using several ordinary sequential files. }

CONST
     rsize=38; {the record size : calculated below }

TYPE
  name= ARRAY[1..32] OF CHAR;
  rec=  RECORD
		n:name;				{32 bytes }
		day,month,year:INTEGER		{ 6 bytes }
	END;

VAR f:	TEXT;
    r:	rec;
    com: CHAR;

{$F RANDREC  }


FUNCTION upper(c:CHAR):CHAR;
BEGIN
 IF c IN ['a'..'z'] THEN c:=CHR(ORD(c)-ORD('a')+ORD('A'));
 upper:=c
END;

PROCEDURE NewFile;
BEGIN
  REWRITE(f,'  BIRTHDAY.DAT');
  r.n:='}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}';
  WRITERAND(f,0,ADDR(r),rsize);
END;

PROCEDURE GetRec(VAR r:rec);
BEGIN
 WITH r DO
  BEGIN
	WRITE('Enter the person''s name '); READLN; READ(n);
	WRITE('Enter their data of birth dd/mm/yy ');
	READLN;
	READ(day); GET(INPUT);
	READ(month); GET(INPUT);
	READ(year);
   END
END;

PROCEDURE PrintRec(VAR r:rec);
VAR i:INTEGER;
BEGIN
 WITH r DO
   BEGIN
    FOR i:=1 TO 32 DO
     IF n[i]<>CHR(0) THEN WRITE(n[i]);
    WRITELN(day:10,'/',month:2,'/',year:2);
   END;
END;

{Finds the number of the last record in the file starting
 at i }

FUNCTION FindEnd(VAR r1:rec;i:INTEGER):INTEGER;
VAR dum:BOOLEAN;
BEGIN
   WHILE r1.n[1]<>'}' DO
   BEGIN i:=i+1; dum:=READRAND(f,i,ADDR(r1),rsize);
   END;
 FindEnd:=i;
END;

PROCEDURE InsertRec(VAR r:rec);
VAR r1:rec; i,j:INTEGER; dum:BOOLEAN;
BEGIN
 i:=0;
 WHILE READRAND(f,i,ADDR(r1),rsize) DO NewFile;

 WHILE r.n>r1.n DO
   BEGIN i:=i+1; dum:=READRAND(f,i,ADDR(r1),rsize);
   END;
 IF r.n=r1.n THEN WRITERAND(f,i,ADDR(r),rsize)
 ELSE
  BEGIN
   {Insert record in file}
   FOR j:=FindEnd(r1,i) DOWNTO i DO
     BEGIN
	dum:=READRAND(f,j,ADDR(r1),rsize);
	WRITERAND(f,j+1,ADDR(r1),rsize)
     END;
   WRITERAND(f,i,ADDR(r),rsize);
  END
END;

FUNCTION DeleteRec(VAR r:rec):BOOLEAN;
VAR r1:rec; i,j:INTEGER; dum:BOOLEAN;
BEGIN
 i:=0;
 IF READRAND(f,i,ADDR(r1),rsize) THEN NewFile;
 WHILE r1.n<r.n DO
   BEGIN
     i:=i+1; dum:=READRAND(f,i,ADDR(r1),rsize);
   END;
 IF r.n=r1.n THEN
   BEGIN
  {Delete record from file}
   FOR j:=i+1 TO FindEnd(r1,i) DO
     BEGIN
	dum:=READRAND(f,j,ADDR(r1),rsize);
        WRITERAND(f,j-1,ADDR(r1),rsize)
     END;
   DeleteRec:=FALSE;
   END ELSE DeleteRec:=TRUE
END;

PROCEDURE Delete;
VAR r1:rec; s:name;i:INTEGER; dum:BOOLEAN;
BEGIN
 WRITE('Which name to delete ?  ');
 READLN; READ(r1.n);
 IF DeleteRec(r1) THEN WRITE(r1.n,' not found');
END;


PROCEDURE Print;
VAR i:INTEGER; dum:BOOLEAN;
    r:rec;
BEGIN
 i:=0;
 REPEAT
  dum:=READRAND(f,i,ADDR(r),rsize);
  IF r.n[1] <>'}' THEN PrintRec(r);
  i:=i+1;
 UNTIL r.n[1]='}';
END;

BEGIN
 RESET(f,'  BIRTHDAY.DAT');
 IF EOF(f) THEN NewFile;
 REPEAT
  WRITELN;
  WRITELN('Type one of ');
  WRITELN('(I)nsert ');
  WRITELN('(D)elete ');
  WRITELN('(E)xit ');
  WRITELN('(P)rint ');

   READLN; READ(com);
   CASE upper(com) OF
	'I': BEGIN GetRec(r);InsertRec(r) END;
	'D': Delete;
	'E': CLOSE(f);
	'P': Print
	END;
UNTIL upper(com)='E'
END.
