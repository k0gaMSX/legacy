PROGRAM Voorbeeld_Date;

CONST weeks  : ARRAY[0..6] OF STRING[9]=
               ('Zondag','Maanndag','Dinsdag','Woensdag','Donderdag',
                'Vrijdag','Zaterdag');
      maands : ARRAY[1..12] OF STRING[9]=
               ('Januari','Februari','Maart','April','Mei','Juni',
                'Juli','Augustus','September','Oktober','November',
                'December');

VAR jaar              : INTEGER;
    maand,dag,weekdag : BYTE;

BEGIN
  Date(jaar,maand,dag,weekdag);
  WRITELN('Het is vandaag ',weeks[weekdag],' ',dag,' ',maands[maand],
          ' ',jaar);
END.
