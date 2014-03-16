PROGRAM voorbeeld_Point;

VAR color : INTEGER;

BEGIN
  Screen(5);
  Actpage:=0;
  Logopr:=0;
  Atrbyt:=8;
  Pset(100,100);               { zet een pixel zie PSET }
  color:=Point(100,100);
  READLN;
  Screen(0);
  WRITELN('De kleur is:',color);
END.
