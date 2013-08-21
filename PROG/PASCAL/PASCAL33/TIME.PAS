PROGRAM voorbeeld_time;

VAR uur,min,sec : BYTE;

BEGIN
  Time(uur,min,sec);
  WRITELN('Het is nu ',uur,' uur ',min,' minuten en ',sec,
          ' seconden.   ');
END.
