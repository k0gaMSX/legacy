PROGRAM voorbeeld_FillShape;

BEGIN
  Screen(5);
  Atrbyt:=255;
  Logopr:=0;
  Actpage:=0;
  FastBox(50,50,180,200);
  Atrbyt:=8;
  Circle(160,140,50);
  Logopr:=3;
  FillShape(140,140,1);
  FillShape(200,140,15);
  READLN;                       { wacht op return }
  Screen(0);
END.
