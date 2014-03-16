PROGRAM voorbeeld_FWrite;

TYPE str255 = STRING[255];

PROCEDURE FastWrite(zin : str255);     { Kleine hulp procedure }
VAR tekst : str255;
BEGIN
  tekst:=zin;
  FWrite(tekst)
END;

BEGIN
  REPEAT
    FastWrite('Deze zin wordt voortdurend op het scherm gezet.')
  UNTIL KEYPRESSED;
END.
