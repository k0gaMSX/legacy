PROGRAM voorbeeld_SpritesOff;

VAR teller : BYTE;

BEGIN
  Screen(5);
  SpritesOff;
  FOR Atrbyt:=0 TO 255 DO
    FastBox(0,0,255,1023);
  SpritesOn;
  Screen(0);
END.
