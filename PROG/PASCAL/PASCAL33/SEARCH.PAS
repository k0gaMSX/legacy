PROGRAM voorbeeld_search;

VAR x : INTEGER;

BEGIN
  Screen(5);
  Actpage:=0;
  Logopr:=0;
  Atrbyt:=12;
  Line(10,10,100,200);           { teken een lijn in kleur 12 }
  x:=Search(100,100,12,2);       { zoek naar links tot kleur 12 }
  READLN;
  Screen(0);
  WRITELN('Op y-waarde 100 passert de lijn op x=',x);
END.
