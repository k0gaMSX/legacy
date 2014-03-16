PROGRAM voorbeeld_VPoke;

VAR teller : BYTE;

BEGIN;
  FOR teller:= 1 TO 255 DO
    VPoke(teller*2,teller);
END.
