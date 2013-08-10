PROGRAM voorbeeld_LoadPicture;

BEGIN
  Screen(5);
  LoadPicture(0,0,0,'GIOSDEMO.SC5');
  READLN;                            { wacht op return }
  Screen(0);
END.
