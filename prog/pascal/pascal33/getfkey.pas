PROGRAM voorbeeld_GetFkey;

VAR welke : INTEGER;

BEGIN
  CLRSCR;
  REPEAT
    welke:=GetFkey;
    GOTOXY(1,4);
    IF welke<>0 THEN
      WRITELN('U heeft funktietoets ',welke,' ingedrukt.   ')
  UNTIL KEYPRESSED;
END.
