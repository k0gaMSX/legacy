PROGRAM voorbeeld_WriteVDP;

VAR teller,data : BYTE;

BEGIN
  FOR teller:=1 TO 20 DO
  WRITELN('Voorbeeld met WRITEVDP');
  data:=0;
  REPEAT
    WriteVDP(23,data);
    data:=(data+1) mod 8;
    DELAY(2)                    { Even pauze }
  UNTIL KEYPRESSED;
  WriteVDP(23,0);
END.
