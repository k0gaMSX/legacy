PROGRAM voorbeeld_SetTime;

VAR uur,min,sec : BYTE;
    mogelijk    : BOOLEAN;

BEGIN
  REPEAT
    CLRSCR;
    WRITE('uur (0..23):');
    READLN(uur);
    WRITE('minuten (0..59):');
    READLN(min);
    WRITE('seconden (0..59):');
    READLN(sec);
    mogelijk:=SetTime(uur,min,sec);
  UNTIL mogelijk;
END.
