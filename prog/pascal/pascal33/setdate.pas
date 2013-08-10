PROGRAM voorbeeld_SetDate;

VAR jaar              : INTEGER;
    maand,dag,weekdag : BYTE;
    mogelijk          : BOOLEAN;

BEGIN
  REPEAT
    CLRSCR;
    WRITELN('dag (1..31):');
    READLN(dag);
    WRITELN('maand (1..12):');
    READLN(maand);
    WRITELN('jaar :');
    READLN(jaar);
    mogelijk:=SetDATE(jaar,maand,dag);
  UNTIL mogelijk;
END.
