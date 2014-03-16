{                       M S X L I B - B . I N C                        }
{                                                                      }
{ Version 1.0; by A.v.Gerven, january 1988                             }
{ This is part 2 of 3-file package:                                    }
{ MSXLIB-A.INC : routines for devices not implemented in DOS           }
{ MSXLIB-B.INC : screen specific routines                              }
{ MSXLIB.DOC   : document file.                                        }

{--------------------------------------------------------------------}
{            s c r e e n   o u t p u t   r o u t i n e s             }

FUNCTION get_screen: byte;
   { returns value of current display mode [0..8] }
VAR val: byte;
BEGIN
  INLINE($3A/$AF/$FC/                  { LD   A,(SCRMOD)   }
         $32/val);                     { LD   (val),A      }
  get_screen:=val;
END;

PROCEDURE set_screen(nr: byte);
   { changes display mode to value specified in nr.        }
   { The valid range for nr. depends on the system used:   }
   { MSX-1 : nr IN [0..2]                                  }
   { MSX-2 & 64 k VideoRAM: nr IN [0..6]                   }
   { MSX-2 & 128k VideoRAM: nr IN [0..8]                   }
   { Please note that this procedure does not check whether}
   { nr is in a valid range!                               }
BEGIN
  INLINE($3A/nr/                       { LD   A,(nr)       }
         $32/$AF/$FC/                  { LD   (SCRMOD),A   }
         $FD/$21/$00/$00/              { LD   IY,$0000     }
         $DD/$21/$5F/$00/              { LD   IX,CHGMOD    }
         $CD/$1C/$00);                 { CALL CALSLT       }
END;

PROCEDURE get_colours(VAR fore,bak,bdr: byte);
   { returns current values for screencolours; }
   { fore:= foreground colour                  }
   { bak:= background colour                   }
   { bdr:= border colour                       }
BEGIN
  INLINE($21/$E9/$F3/                  { LD   HL,FORCLR   }
         $7E/                          { LD   A,(HL)      }
         $32/fore/                     { LD   (fore),A    }
         $23/                          { INC  HL          }
         $7E/                          { LD   A,(HL)      }
         $32/bak/                      { LD   (bak),A     }
         $23/                          { INC  HL          }
         $7E/                          { LD   A,(HL)      }
         $32/bdr);                     { LD   (bdr),A     }
END;

PROCEDURE set_colours(fore,bak,bdr: byte);
   { sets system variables for screencolours to specified }
   { value's. The range of valid values depends on the    }
   { current screenmode. Please note that this procedure  }
   { does not check if a value is valid!                  }
   { Changes in the systems colour variables are not al-  }
   { ways immediatly updated on the screen. Please refer  }
   { to your systems manual for details.                  }
BEGIN
  INLINE($21/$E9/$F3/                  { LD   HL,FORCLR   }
         $3A/fore/                     { LD   A,(fore)    }
         $77/                          { LD   (HL),A      }
         $23/                          { INC  HL          }
         $3A/bak/                      { LD   A,(bak)     }
         $77/                          { LD   (HL),A      }
         $23/                          { INC  HL          }
         $3A/bdr/                      { LD   A,(bdr)     }
         $77/                          { LD   (HL),A      }
         $3A/$AF/$FC/                  { LD   A,(SCRMOD)  }
         $FD/$21/$00/$00/              { LD   IY,$0000    }
         $DD/$21/$62/$00/              { LD   IX,CHGCLR   }
         $CD/$1C/$00);                 { CALL CALSLT      }
END;

PROCEDURE get_colortable(tabnr: byte; VAR red,blue,green: byte);
   { returns composition of colour (or colour table), specified }
   { in tabnr. Valid values for tabnr are [0..15]               }
   { This procedure should be used on msx-2 systems only !!     }
BEGIN
  IF (tabnr IN [0..15])
  THEN INLINE($3A/tabnr/               { LD   A,(tabnr)     }
              $FD/$2A/$F7/$FA/         { LD   IY,(EXBRSA-1) }
              $DD/$21/$49/$01/         { LD   IX,GETPLT     }
              $CD/$1C/$00/             { CALL CALSLT        }
              $79/                     { LD   A,C           }
              $E6/$0F/                 { AND  $0F           }
              $32/green/               { LD   (green),A     }
              $78/                     { LD   A,B           }
              $E6/$0F/                 { AND  $0F           }
              $32/blue/                { LD   (blue),A      }
              $78/                     { LD   A,B           }
              $E6/$0F/                 { AND  $F0           }
              $0F/                     { RRCA               }
              $0F/                     { RRCA               }
              $0F/                     { RRCA               }
              $0F/                     { RRCA               }
              $32/red)                 { LD   (red),A       }
  ELSE BEGIN green:=0; blue:=0; red:=0; END;
END;

PROCEDURE set_colortable(tabnr,red,blue,green: byte);
  { sets composition of colour (or colourtable) specified in }
  { tabnr. to specified values.                              }
BEGIN
  IF (tabnr IN [0..15])
  THEN INLINE($3A/green/               { LD   A,(green)   }
              $E6/$0F/                 { AND  $0F         }
              $5F/                     { LD   E,A         }
              $3A/blue/                { LD   A,(blue)    }
              $E6/$0F/                 { AND  $0F         }
              $47/                     { LD   B,A         }
              $3A/red/                 { LD   A,(red)     }
              $E6/$0F/                 { AND  $0F         }
              $07/                     { RLCA             }
              $07/                     { RLCA             }
              $07/                     { RLCA             }
              $07/                     { RLCA             }
              $B0/                     { OR   B           }
              $FD/$2A/$F7/$FA/         { LD   IY,(EXBRSA-1) }
              $DD/$21/$4D/$01/         { LD   IX,SETPLT     }
              $CD/$1C/$00);            { CALL CALSLT        }
END;

FUNCTION get_textwidth: byte;
  { returns width for text screens [0..1], otherwise value 00 is }
  { returned.                                                    }
VAR s: byte;
BEGIN
  s:=get_screen;
  IF (s IN [0,1])
  THEN get_textwidth:=Mem[$F3B0]       { LINLEN }
  ELSE get_textwidth:=0;
END;

PROCEDURE set_textwidth(width: byte);
  { changes width for text screens to specified value, and clears }
  { screen, if screenmode:=0 or 1.                                }
  { Note that this procedure does not check for illegal values.   }
VAR s: byte;
BEGIN
  s:=get_screen;
  CASE s OF
    0 : BEGIN Mem[$F3AE]:=width; set_screen(0); END;
    1 : BEGIN Mem[$F3AF]:=width; set_screen(1); END;
  ELSE END;
END;

PROCEDURE text_cursor(x,y: integer);
  { positions cursor for text output at given position on ANY screen }
  { This procedure does not check for invalid coordinate values !!   }
BEGIN
  INLINE($3A/$AF/$FC/                  {          LD   A,(SCRMOD)  }
         $DD/$2A/x/                    {          LD   IX,(x)      }
         $FD/$2A/y/                    {          LD   IY,(y)      }
         $FE/$02/                      {          CP   $02         }
         $DA/*+13/                     {          JP   C,textscrn  }
         $DD/$22/$B7/$FC/              {          LD   (GRPACX),IX }
         $FD/$22/$B9/$FC/              {          LD   (GRPACY),IY }
         $C3/*+21/                     {          JP   crsr_ok     }
         $DD/$E5/                      { textscrn PUSH IX          }
         $E1/                          {          POP  HL          }
         $65/                          {          LD   H,L         }
         $FD/$E5/                      {          PUSH IY          }
         $D1/                          {          POP  DE          }
         $6B/                          {          LD   L,E         }
         $FD/$21/$00/$00/              {          LD   IY,$0000    }
         $DD/$21/$C6/$00/              {          LD   IX,POSIT    }
         $CD/$1C/$00/                  {          CALL CALSLT      }
         $00);                         { crsr_ok  NOP              }
END;

PROCEDURE pixel_cursor(x,y: integer);
  { positions cursor for graphics output at given position on screen }
  { [2..8]; This procedure does not check for invalid coordinate     }
  { values !!                                                        }
BEGIN
  IF get_screen>1
  THEN INLINE($ED/$4B/x/               { LD   BC,(x)        }
              $ED/$5B/y/               { LD   DE,(y)        }
              $FD/$21/$00/$00/         { LD   IY,$0000      }
              $DD/$21/$11/$01/         { LD   IX,MAPXYC     }
              $CD/$1C/$00/             { CALL CALSLT        }
              $FD/$21/$00/$00/         { LD   IY,$0000      }
              $DD/$21/$17/$01/         { LD   IX,STOREC     }
              $CD/$1C/$00);            { CALL CALSLT        }
END;

FUNCTION WhereX: byte;
  { returns X-value for text_cursor in screens [0..1], otherwise }
  { returns value 00. Now you can use some of the IBM goodies!!  }
BEGIN
  IF get_screen<2
  THEN WhereX:=Mem[$F3DD]    {system variable CSRX }
  ELSE WhereX:=0;
END;

FUNCTION WhereY: byte;
BEGIN
  IF get_screen<2
  THEN WhereY:=Mem[$F3DC]    {system variable CSRY }
  ELSE WhereY:=0;
END;

FUNCTION get_pixelclr(x,y: byte): byte;
  { returns colour of pixel at specified location, for screens [2..8] }
  { otherwise returns value 00.                                       }
VAR clr: byte;
BEGIN
  IF get_screen>1
  THEN BEGIN
         pixel_cursor(x,y);
         INLINE($FD/$21/$00/$00/             { LD   IY,$0000  }
                $DD/$21/$1D/$01/             { LD   IX,READC  }
                $CD/$1C/$00/                 { CALL CALSLT    }
                $32/clr);                    { LD   (clr),A   }
         get_pixelclr:=clr;
       END
  ELSE get_pixelclr:=0;
END;

PROCEDURE set_pixelclr(x,y,clr: byte);
  { sets pixel at specified location to specified colour }
BEGIN
  IF get_screen>1
  THEN BEGIN
         pixel_cursor(x,y); Mem[$F3F2]:=clr;
         INLINE($FD/$21/$00/$00/            { LD   IY,$0000  }
                $DD/$21/$20/$01/            { LD   IX,SETC   }
                $CD/$1C/$00);               { CALL CALSLT    }
       END;
END;

FUNCTION get_workclr: byte;
  { returns value of system variable ATRBYT }
BEGIN get_workclr:=Mem[$F3F2]; END;

PROCEDURE set_workclr(clr: byte);
  { sets value of working colour }
BEGIN Mem[$F3F2]:=clr; END;

PROCEDURE print_char(ch: char);
  { prints any msx-character to any screen at current position of }
  { the text_cursor. This position is updated automatically.      }
  { For details on printing graphic characters, please refer to   }
  { your systems manual.                                          }
BEGIN
  INLINE($FD/$21/$00/$00/          {          LD   IY,$0000  }
         $DD/$21/$A2/$00/          {          LD   IX,CHPUT  }
         $3A/$AF/$FC/              {          LD   A,(SCRMOD)}
         $FE/$02/                  {          CP   $02       }
         $DA/*+06/                 {          JP   C,scrn01  }
         $DD/$21/$8D/$00/          {          LD   IX,GRPPRT }
         $3A/ch/                   { scrn01   LD   A,(ch)    }
         $CD/$1C/$00);             {          CALL CALSLT    }
END;

PROCEDURE get_page(VAR work,displ: byte);
  { returns values for working page and display page.   }
  { These values only have a meaning for screens [5..8] }
BEGIN
  work:=Mem[$FAF6]; { system variable ACPAGE }
  displ:=Mem[$FAF5];{ system variable DPPAGE }
END;

PROCEDURE set_page(work,displ: byte);
  { changes values for working page and/or displayed page. }
  { Valid combinations for screen-mode page number are:    }
  { screen: 5 (64 kVideoRAM: [0..1])/(128 kVideoRAM: [0..3]}
  {         6 (64 kVideoRAM: [0..1])/(128 kVideoRAM: [0..3]}
  {         7 (128 kVideoRAM: [0..1] else illegal          }
  {         8 (128 kVideoRAM: [0..1] else illegal          }
  { Note that this procedure does not check for legal com- }
  { binations!                                             }
BEGIN
  Mem[$FAF6]:=work; Mem[$FAF5]:=displ;
  INLINE($FD/$2A/$F7/$FA/         { LD   IY,(EXBRSA-1) }
         $DD/$21/$3D/$01/         { LD   IX,SETPAG     }
         $CD/$1C/$00);            { CALL CALSLT        }
END;

PROCEDURE draw_line(x1,y1,x2,y2: integer; clr: byte);
  { draws a line from (x1,y1) to (x2,y2), with colour as  }
  { specified in clr. Valid screenmodes [5..8]            }
  { screenmode is NOT tested, in order to achieve maximum }
  { speed.                                                }
BEGIN
  INLINE($ED/$4B/x1/              { LD   BC,(x1)    }
         $ED/$5B/y1/              { LD   DE,(y1)    }
         $DD/$2A/x2/              { LD   IX,(x2)    }
         $DD/$22/$B3/$FC/         { LD   (GXPOS),IX }
         $FD/$2A/y2/              { LD   IY,(y2)    }
         $FD/$22/$B5/$FC/         { LD   (GYPOS),IY }
         $3A/clr/                 { LD   A,(clr)    }
         $32/$F2/$F3/             { LD   (ATRBYT),A }
         $FD/$2A/$F7/$FA/         { LD   IY,(EXBRSA-1)}
         $DD/$21/$85/$00/         { LD   IX,DOGRPH    }
         $CD/$1C/$00);            { CALL CALSLT       }
END;

PROCEDURE draw_box(x1,y1,x2,y2: integer; clr,mode: byte);
   { draws a rectangle from (x1,y1) to (x2,y2) with colour as }
   { specified in clr. Box is filled with clr when mode<>0    }
   { Valid screenmodes are [5..8]. They are NOT tested in or- }
   { der to achieve maximum speed.                            }
BEGIN
  INLINE($ED/$4B/x1/              {         LD   BC,(x1)    }
         $ED/$5B/y1/              {         LD   DE,(y1)    }
         $DD/$2A/x2/              {         LD   IX,(x2)    }
         $DD/$22/$B3/$FC/         {         LD   (GXPOS),IX }
         $FD/$2A/y2/              {         LD   IY,(y2)    }
         $FD/$22/$B5/$FC/         {         LD   (GYPOS),IY }
         $3A/clr/                 {         LD   A,(clr)    }
         $32/$F2/$F3/             {         LD   (ATRBYT),A }
         $FD/$2A/$F7/$FA/         {         LD   IY,(EXPBRSA-1)}
         $DD/$21/$C9/$00/         {         LD   IX,NVBXLN  }
         $3A/mode/                {         LD   A,(mode)   }
         $B7/                     {         OR   A          }
         $CA/*+06/                {         JP   Z,emptybox }
         $DD/$21/$CD/$00/         {         LD   IX,NVBXFL  }
         $CD/$1C/$00);            {emptybox CALL CALSLT     }
END;

