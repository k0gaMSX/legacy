PROGRAM voorbeeld_FastBox;

BEGIN
  Screen(5);
  Actpage:=0;
  Atrbyt:=255;            {  (voorgrond * 16)+achtergond }
  FastBox(10,30,250,190);
  READLN;                 { wacht op return }
  Screen(0);
END.
