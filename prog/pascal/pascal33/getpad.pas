VAR poort1, poort2: BOOLEAN;
    x, y: INTEGER;

PROCEDURE Aangesloten(VAR een,twee : BOOLEAN);
VAR teller : BYTE;
BEGIN
  een :=FALSE;
  twee:=FALSE;
  FOR teller:=0 TO 9 DO
  BEGIN
    IF (GetPad(12)=-1) AND ((GetPad(13)<>GetPad(14)) OR (GetPad(13)=0) OR
       (GetPad(14)=0)) THEN een:=TRUE;
    IF (GetPad(16)=-1) AND ((GetPad(17)<>GetPad(18)) OR (GetPad(17)=0) OR
       (GetPad(18)=0)) THEN twee:=TRUE
   END
 END;

BEGIN
  Aangesloten(poort1,poort2);
  x:=0;
  y:=0;
  CLRSCR;
  IF poort1 THEN WRITELN('In poort 1 is een muis aangesloten.');
  IF poort2 THEN WRITELN('In poort 2 is een muis aangesloten.');
  REPEAT
    GOTOXY(1,5);
    IF (poort1) AND (GetPad(12)=-1) THEN
    BEGIN
      x:=x+GetPad(13);
      y:=y+GetPad(14)
    END;
    IF (poort2) AND (GetPad(16)=-1) THEN
    BEGIN
      x:=x+GetPad(17);
      y:=y+GetPad(18)
    END;
    WRITELN(x:6,':',y:6)
  UNTIL KEYPRESSED;
END.
