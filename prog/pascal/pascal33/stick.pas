PROGRAM voorbeeld_Stick;

BEGIN
  CLRSCR;
  WRITELN('Cursor       Joystick poort 1         Joystick poort 2');
  REPEAT
    GOTOXY(3,3);
    WRITE(Stick(0));
    GOTOXY(22,3);
    WRITE(Stick(1));
    GOTOXY(47,3);
    WRITE(Stick(2))
  UNTIL KEYPRESSED;
END.
