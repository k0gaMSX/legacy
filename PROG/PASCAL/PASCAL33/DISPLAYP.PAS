PROGRAM voorbeeld_DisplayPage;

BEGIN
  Screen(5);
  DisplayPage(0);     { Dit is standaard zo ingesteld!! }
  READLN;             { wacht op return }
  DisplayPage(2);
  READLN;             { wacht op return }
  Screen(0);
END.
