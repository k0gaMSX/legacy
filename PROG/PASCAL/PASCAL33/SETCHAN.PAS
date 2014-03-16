PROGRAM voorbeeld_SetChannel;

BEGIN
  ClearMem;
  WRITELN(SetMem(2));
  SetChannel(1,0);
  READLN;                       { wacht op return }
  ClearMem;
END.
