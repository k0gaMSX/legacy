PROGRAM voorbeeld_WaitVDP;

BEGIN
  Screen(5);
  Actpage:=0;
  Logopr:=0;
  Atrbyt:=15;
  FillBox(0,0,255,200);
  WaitVDP;
  DELAY(50);
  Screen(0);
END.
