PROGRAM INDEXIT;
{-------------------------------------------------------}
{Purpose  : Find procedure and function declarations and}
{           output them in alphabetical order to a file }
{Inputs   : File to be indexed.                         }
{Outputs  : File of procedures and functions            }
{CREATED  : Jan 31, 1981 NJL                            } 
{-------------------------------------------------------}

CONST
  CPMLINESZ = 127;

TYPE
  STRNG=STRING[20];
  FILENAME = STRING[127];
  RWFILE = (RESETT,REWRITTE);
  FYLE = FILE;
  SUM_TYPE = (SHORT,LONG);
VAR
  FIN : TEXT;
  FOUT : TEXT;
  NAME : FILENAME;
  STR : STRING;
  I : INTEGER;
  CPMCMDBUF : ABSOLUTE[$80] PACKED ARRAY [0..CPMLINESZ] OF CHAR;
  CPMSTR : STRING[CPMLINESZ];
  PROGFLG : BOOLEAN;
  SUMMARY : SUM_TYPE;

EXTERNAL FUNCTION KEYPRESSED:BOOLEAN;
EXTERNAL PROCEDURE @HLT;

PROCEDURE ABORT;
BEGIN
  WRITELN;
  WRITELN('Pascal/MT+ Program Index utility aborted from console');
  @HLT
END;


FUNCTION DOFILE(VAR F : TEXT;RW : RWFILE; NAME : FILENAME) : BOOLEAN;
{---------------------------------------------------------------}
{ Purpose: Attempt to reset or rewrite the given file. Check    }
{          IORESULT.                                            }
{ Inputs:  File,whether to reset or rewrite, and name of file.  }
{ Outputs: File open for reading or writing. True if successful,}
{          false if not successful.                             }
{ Last Mod:                                                     }
{---------------------------------------------------------------}
BEGIN
  ASSIGN(F,NAME);
  IF RW = RESETT THEN
    RESET(F)
  ELSE
    REWRITE(F);
  IF IORESULT = 255 THEN
    DOFILE := FALSE
  ELSE
    DOFILE := TRUE;
END;

PROCEDURE GETNAME(VAR OUTSTR : FILENAME);
{---------------------------------------------------------------}
{ Purpose: Read a name from the keyboard, return in STR.        }
{ Inputs:  CPMCMDBUF.                                           }
{ Outputs: STR contains name of file if it was given to start.  }
{ Last Mod: 11/23/80                                            }
{---------------------------------------------------------------}
BEGIN
  OUTSTR := '';
  WHILE (LENGTH(STR) <> 0) AND (STR[1] <> ' ') DO
    BEGIN
      OUTSTR := CONCAT(OUTSTR,STR[1]);
      DELETE(STR,1,1)
    END;
  IF LENGTH(STR) <> 0 THEN
    DELETE(STR,1,1);            (* DELETE NEXT BLANK *)
END;


FUNCTION STRIPBLNKS(S : STRING):INTEGER;
VAR
  I : INTEGER;
BEGIN
  STRIPBLNKS := 0;
  I := 1;
  WHILE (S[I] = ' ') AND (I <= LENGTH(S)) DO
    I := I + 1;
  IF I > LENGTH(S) THEN
    STRIPBLNKS := 0
  ELSE
    STRIPBLNKS := I;
END;

FUNCTION PRESENT(KEYWORD,STR : STRING):BOOLEAN; 
{---------------------------------------------------------------}
{ Purpose: Return true if the string KEYWORD                    }
{          the first string on the input line STR.  If it is    }
{          not first or is  not present return false.           }
{ Inputs:  KEYWORD,STR.                                         }
{ Outputs: Function return value of true or false.             n}
{ Last Mod: 11/23/80                                            }
{---------------------------------------------------------------}
VAR 
  FIRSTCH : INTEGER;
BEGIN
  FIRSTCH :=  STRIPBLNKS(STR);
  IF FIRSTCH <> 0 THEN
    BEGIN
      IF POS(KEYWORD,STR) = FIRSTCH THEN
        PRESENT := TRUE
      ELSE
        PRESENT := FALSE
    END
  ELSE
    PRESENT := FALSE;
END;


PROCEDURE TRANSFER(VAR STR : STRING);
{---------------------------------------------------------------}
{ Purpose: Transfer lines from FIN to FOUT until the next proc/ }
{          func or begin is encountered.                        }
{ Inputs:  STR contains the line with the PROC, FUNC or PROG def}
{          FIN provides the text.                               }
{ Outputs: STR contains the line containing a PROC, FUNC def or }
{          a begin. FOUT contains new text.                     }
{ Last Mod: 11/23/80                                            }
{---------------------------------------------------------------}
VAR SHORTSTR : STRING[25];
    DONE : BOOLEAN;
    TSTRING : STRING;
BEGIN
  DONE := FALSE;
  TSTRING := STR;
  WRITELN(FOUT,TSTRING);
  IF SUMMARY = LONG THEN
  REPEAT
    READLN(FIN,TSTRING);
    WRITE('.');
    IF KEYPRESSED THEN
      ABORT;
    SHORTSTR := TSTRING;
    IF (PRESENT('BEGIN',SHORTSTR)) THEN
         DONE := TRUE
    ELSE
      BEGIN
        IF (PRESENT('FUNCTION',SHORTSTR)) OR
         (PRESENT('PROCEDURE',SHORTSTR)) THEN
          BEGIN
            WRITELN(FOUT);
            WRITELN(FOUT);
          END;
        WRITELN(FOUT,TSTRING) 
      END
  UNTIL ( EOF(FIN)) OR (DONE);

  IF SUMMARY = SHORT THEN
    BEGIN
      READLN(FIN,TSTRING);
      WRITE('.')
    END;

  IF KEYPRESSED THEN
    ABORT;
  STR := TSTRING;  
  WRITELN(FOUT);
  WRITELN(FOUT);
END;


PROCEDURE DOINDEX;
VAR
  I : INTEGER;
  STR : STRING;
BEGIN
  WHILE NOT EOF(FIN) DO
    BEGIN
      IF PRESENT('PROCEDURE',STR) THEN
          TRANSFER(STR)
      ELSE
        IF PRESENT('FUNCTION',STR) THEN
            TRANSFER(STR);
      READLN(FIN,STR);
      WRITE('.');
      IF KEYPRESSED THEN
        ABORT;
    END;
END;

        
  

BEGIN
  MOVE(CPMCMDBUF,STR,CPMLINESZ + 1); (* COPY COMMAND TAIL *)
  IF LENGTH(STR) <> 0 THEN
    DELETE(STR,1,1);                 (* STRIP CP/M'S LEADING BLANK *)

  WRITELN('Pascal/MT+ Program Index Utility -- Release 5.2');
  WRITELN('Copyright (c) 1981 by MT MicroSYSTEMS');
  WRITELN;

  GETNAME(NAME);
  WRITELN('Reading text from:  ',NAME);
  IF DOFILE(FIN,RESETT,NAME) THEN
    BEGIN
      GETNAME(NAME);
      WRITELN('Output directed to: ',NAME);
      IF DOFILE(FOUT,REWRITTE,NAME) THEN
      BEGIN
        GETNAME(NAME);
        WRITELN('Summary form:       ',NAME);
        IF NAME[1] IN ['L','l'] THEN
          SUMMARY := LONG
        ELSE
          SUMMARY := SHORT;
        READLN(FIN,STR);
        WRITE('.');
        TRANSFER(STR);
        DOINDEX;
        CLOSE(FOUT,I);
        WRITELN('Pascal/MT+ Program Index utility processing complete');
      END
      ELSE
        WRITELN('Cannot create ',NAME)
    END
  ELSE
    WRITELN('Cannot open ',NAME);
END.
                               �     E E                   EAM  N �����E�{��s�b�n���0 N ��>� �2   	�   �����[ � ��ŊG