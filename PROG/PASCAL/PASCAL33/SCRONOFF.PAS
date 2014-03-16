PROGRAM voorbeeld_ScreenOn_Off;

VAR teller  : BYTE;

BEGIN
  Screen(7);
  ScreenOff;
  Actpage:=0;
  FOR teller:=1 TO 100 DO
    BEGIN
      Atrbyt:=random(255);
      FastBox(random(512),random(212),random(512),random(212))
    END;
  ScreenOn;
  READLN;                         { wacht op return }
  Screen(0);
END.
