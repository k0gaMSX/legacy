PROGRAM voorbeeld_ChangeColor;

BEGIN
  Screen(5);
  Actpage:=0;
  Logopr:=0;
  Atrbyt:=8;
  Fillbox (40,40,200,150);
  ChangeColor (8,3,3,3);   { donker grijs }
  READLN;
  ChangeColor (8,0,0,7);   { donker blauw }
  READLN;
  ChangeColor (8,7,7,7);   { wit }
  READLN;
  ChangeColor (8,5,0,0);   { rood }
  READLN;
  Screen(0);
END.
