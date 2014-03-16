PROGRAM voorbeeld_VPeek;

VAR teller : INTEGER;

BEGIN
  FOR teller:=0 TO 239 DO
    WRITE (CHR(VPeek(teller)));
END.
