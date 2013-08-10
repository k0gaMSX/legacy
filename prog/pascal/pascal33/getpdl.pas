PROGRAM voorbeeld_GetPdl;

VAR poort1,poort2 : BOOLEAN;
    i             : INTEGER;

FUNCTION  Pdl (n : INTEGER) : INTEGER;
VAR getal : INTEGER;
BEGIN
  getal:=GetPdl(n);
  Pdl:=getal-(getal AND 128) SHL 1
END;

BEGIN
  FOR i := 0 TO 100 DO
  BEGIN
    WRITELN( Pdl(1) );
  END;
END.
