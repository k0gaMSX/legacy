PROGRAM voorbeeld_WriteSector;

VAR inhoud : ARRAY[0..511] OF BYTE;

BEGIN
  ReadSector(0,0,ADDR(inhoud[0]),1);     { lees sector 0 in }
  READLN;                                { wacht op return }
  WriteSector(0,0,ADDR(inhoud[0]),1);    { schrijf sector 0 terug }
END.
