PROGRAM Voorbeeld_SetMem;

VAR aantal_blokken : BYTE;

BEGIN
  ClearMem;
  aantal_blokken:=SetMem(10);
  READLN;                       { wacht op return }
  ClearMem;
END.
