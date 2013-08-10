PROGRAM voorbeeld_Paint;

BEGIN
  Screen(5);
  Actpage:=0;
  Logopr:=0;
  Atrbyt:=17;
  FastBox(50,50,150,150);
  Atrbyt:=6;
  Circle(130,100,40);
  Logopr:=3;
  Atrbyt:=5;
  Paint(100,100,6);
  READLN;
  Screen(0);
END.
