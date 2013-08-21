PROGRAM voorbeeld_PSet;

VAR x,y : BYTE;

BEGIN
  Screen(8);
  Actpage:=0;
  Logopr:=0;
  FOR y:=0 TO 211 DO
    FOR x:=0 TO 255 DO
    BEGIN
      Atrbyt:=RANDOM(255);
      PSet(x,y)
    END;
  Screen(0);
END.
