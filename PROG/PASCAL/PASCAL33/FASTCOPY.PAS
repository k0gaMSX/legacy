PROGRAM voorbeeld_FastCopy;

BEGIN
  Screen(7);
  Actpage:=0;
  Atrbyt:=6;
  Logopr:=0;
  Line(0,2,55,15);
  FastCopy(0,0,60,20,100,100,0);
  READLN;                            { wacht op return }
  Screen(0);
END.
