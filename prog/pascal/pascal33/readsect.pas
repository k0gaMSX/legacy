PROGRAM voorbeeld_ReadSector;

VAR buffer : ARRAY[0..512] OF BYTE;
    teller : BYTE;

BEGIN
  ReadSector(0,0,ADDR(buffer[0]),1);
  FOR teller:=0 TO 511 DO
    WRITE(CHR(buffer[teller]),' ');
END.
