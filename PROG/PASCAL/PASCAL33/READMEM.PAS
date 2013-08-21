PROGRAM Voorbeeld_ReadMem;

VAR reeks : ARRAY [1..5] OF RECORD
                              x : ARRAY[0..49] OF INTEGER;
                              y : BYTE;
                              z : STRING[40]
                            END;

BEGIN
  ClearMem;
  WriteLN(Setmem(5));            {-defineer 5 blokken van 16 Kbytes-}
  SetChannel(1,17384);
  ReadMem(1,ADDR(reeks[1]),142);
  READLN;                        {-wacht op return-}
  ClearMem;
END.
