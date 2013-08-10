PROGRAM voorbeeld_WriteMem;

VAR reeks : ARRAY [1..5] OF RECORD
                              x : ARRAY[0..49] OF INTEGER;
                              y : BYTE;
                              z : STRING[40]
                            END;

BEGIN
  ClearMem;
  WRITELN(Setmem(5));            { defineer 5 blokken van 16 KBytes }
  SetChannel(1,17384);
  WriteMem(1,ADDR(reeks[1]),142);
  READLN;                        { wacht op return }
  ClearMem;
END.
