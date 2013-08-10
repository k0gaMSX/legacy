PROGRAM voorbeeld_Strig;

CONST knop : ARRAY[0..4] OF STRING[15] = ('knop 0 (spatie)',
                         'knop 1 poort 1','knop 1 poort 2',
                         'knop 2 poort 1','knop 2 poort 2');

VAR teller : BYTE;
         k : CHAR;

BEGIN
  CLRSCR;
  REPEAT
    k:=' ';
    GOTOXY(1,1);
    FOR teller:=0 TO 4 DO
      WRITELN(knop[teller],'=',Strig(teller));
    IF KEYPRESSED THEN READ(KBD,k)
  UNTIL k=#13;
END.
