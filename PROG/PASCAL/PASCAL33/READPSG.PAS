PROGRAM voorbeeld_ReadPSG;

VAR teller : BYTE;

BEGIN
  FOR teller:=0 TO 13 DO
    WRITELN('Register ',teller,' bevat de waarde ',ReadPSG(teller));
END.
