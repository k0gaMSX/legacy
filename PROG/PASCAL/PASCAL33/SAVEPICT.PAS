PROGRAM voorbeeld_SavePicture;

BEGIN
  Screen(5);
  Atrbyt:=255;
  Logopr:=0;
  Actpage:=0;
  FastBox(0,0,255,1023);
  Atrbyt:=8;
  Circle(160,140,50);
  SavePicture(0,0,255,1023,0,'PLAATJE.SC5');
  Screen(0);
END.
