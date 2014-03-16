{                    M S X L I B - A . I N C                           }
{                                                                      }
{ Version 1.0, by A.v.Gerven, january 1988                             }
{ This is part 1 of a 3-file package:                                  }
{ MSXLIB-A.INC : routines for devices that are not implemented in DOS  }
{ MSXLIB-B.INC : screen specific routines                              }
{ MSXLIB.DOC   : documentation file.                                   }

PROCEDURE BIOS_CALL(version: byte; VAR a,b,c,d,e,h,l: byte;
                    entry_address: integer);
   { This procedure does a CALSLT to the BIOS specified in <version> }
   { version : 0 = MSX-1 ROM BIOS (primary_slot=0, secundary_slot=0) }
   { version : 1 = MSX-2 BIOS extension, slotcode is stored in the   }
   {               system variable EXBRSA at address FAF8            }
   { values for the registers are passed to and from this routine in }
   { the variables a,b,c, etc.                                       }
   { When calling this procedure, <entry_address> should hold the    }
   { address of the routine that has to be called.                   }

VAR slotcode: integer;
BEGIN
  IF version=0 THEN slotcode:=0 ELSE slotcode:=256*Mem[$FAF8];
  INLINE($3A/l/                         { LD   A,(l)         }
         $6F/                           { LD   L,A           }
         $3A/h/                         { LD   A,(h)         }
         $67/                           { LD   H,A           }
         $3A/e/                         { LD   A,(e)         }
         $5F/                           { LD   E,A           }
         $3A/d/                         { LD   A,(d)         }
         $57/                           { LD   D,A           }
         $3A/c/                         { LD   A,(c)         }
         $4F/                           { LD   C,A           }
         $3A/b/                         { LD   A,(b)         }
         $47/                           { LD   B,A           }
         $3A/a/                         { LD   A,(a)         }
         $FD/$2A/slotcode/              { LD   IY,(slotcode) }
         $DD/$2A/entry_address/         { LD   IX,(entry_address)}
         $CD/$1C/$00/                   { CALL CALSLT        }
         $32/a/                         { LD   (a),A         }
         $78/                           { LD   A,B           }
         $32/b/                         { LD   (b),A         }
         $79/                           { LD   A,C           }
         $32/c/                         { LD   (c),A         }
         $7A/                           { LD   A,D           }
         $32/d/                         { LD   (d),A         }
         $7B/                           { LD   A,E           }
         $32/e/                         { LD   (e),A         }
         $7C/                           { LD   A,H           }
         $32/h/                         { LD   (h),A         }
         $7D/                           { LD   A,L           }
         $32/l);                        { LD   (l),A         }
END;

{       m e m o r y   &   s l o t   m a n a g e m e n t                }

FUNCTION peek(primary_slot,secundary_slot: byte;
              address: integer): byte;
VAR val: byte;
BEGIN
  INLINE($3A/primary_slot/               { LD   A,(primary_slot)   }
         $E6/$03/                        { AND  $03                }
         $47/                            { LD   B,A                }
         $3A/secundary_slot/             { LD   A,(secundary_slot) }
         $E6/$03/                        { AND  $03                }
         $07/                            { RLCA                    }
         $07/                            { RLCA                    }
         $F6/$80/                        { OR   $80                }
         $B0/                            { OR   B                  }
         $2A/address/                    { LD   HL,(address)       }
         $CD/$0C/$00/                    { CALL RDSLT              }
         $32/val);                       { LD   val,(A)            }
  peek:=val;
END;

PROCEDURE poke(primary_slot,secundary_slot: byte;
               address: integer; data: byte);
BEGIN
  INLINE($3A/data/                       { LD   A,(data)           }
         $5F/                            { LD   E,A                }
         $3A/primary_slot/               { LD   A,(primary_slot)   }
         $E6/$03/                        { AND  $03                }
         $47/                            { LD   B,A                }
         $3A/secundary_slot/             { LD   A,(secundary_slot) }
         $E6/$03/                        { AND  $03                }
         $07/                            { RLCA                    }
         $07/                            { RLCA                    }
         $F6/$80/                        { OR   $80                }
         $B0/                            { OR   B                  }
         $2A/address/                    { LD   HL,(address)       }
         $CD/$14/$00);                   { CALL WRSLT              }
END;

Function ram(Primary_slot,Secundary_slot: byte;
             Address: integer): boolean;
VAR buf,test_value : byte;
    tr             : boolean;

  FUNCTION test_result(ps,ss:byte;a:integer;d:byte): boolean;
  BEGIN poke(ps,ss,a,d); test_result:=(d = peek(ps,ss,a)); END;

BEGIN
  buf:=peek(Primary_slot,Secundary_slot,Address);
  test_value:=$AA; { 10101010 }
  tr:=false;
  IF test_result(Primary_slot,Secundary_slot,Address,test_value)
  THEN BEGIN
         test_value:=$55; { 01010101 }
         IF test_result(Primary_slot,Secundary_slot,
                 Address,test_value)
         THEN BEGIN
                tr:=true; poke(Primary_slot,Secundary_slot,
                               Address,buf);
              END;
       END;
  ram:=tr;
END;

{-------------------------------------------------------------------}
{              M S X   I N P U T   D E V I C E S                    }

FUNCTION device(dev_nr,func_nr: byte): byte;
  { This is a help function that contains code common to  different }
  { device input routines. Here code reduction was favored to       }
  { execution speed. (it's fast enough anyhow)                      }
VAR value: byte;
    bios_entry: integer;
    slot_code : integer;
BEGIN
  slot_code:=$0000;
  CASE func_nr OF
   1 : bios_entry:=$00D5; {msx1bios routine GTSTCK}
   2 : bios_entry:=$00D8; {msx1bios routine GTTRIG}
   3 : bios_entry:=$00DB; {msx1bios routine GTPAD }
   4 : bios_entry:=$00DE; {msx1bios routine GTPDL }
   5 : BEGIN
         slot_code:=256*Mem[$FCC1];
         bios_entry:=$01AD;
       END; {msx2bios routine NEWPAD}
  ELSE END;
  IF (func_nr IN [1..5])
  THEN BEGIN
         INLINE($3A/dev_nr/             { LD   A,(dev_nr)         }
                $FD/$2A/slot_code/      { LD   IY,(slot_code)     }
                $DD/$2A/bios_entry/     { LD   IX,(bios_entry)    }
                $CD/$1C/$00/            { CALL CALSLT ; DOS entry }
                $32/value);             { LD   (value),A          }
         device:=value;
       END
  ELSE device:=0;
END;

PROCEDURE kill_kbd;
  { clears keyboard buffer }
BEGIN
  INLINE($FD/$21/$00/$00/              { LD   IY,$0000 }
         $DD/$21/$56/$01/              { LD   IX,KILBUF}
         $CD/$1C/$00);                 { CALL CALSLT   }
END;

FUNCTION get_stick(nr: byte): byte;
  { scans standard cursor input device, identified by nr. }
  { valid entries are: nr = 0 : cursor keys               }
  {                    nr = 1 : joystick 1                }
  {                    nr = 2 : joystick 2                }
  { returns same values as MSX-basic, eg.                 }
  {                  8  1  2                              }
  {                   \ | /                               }
  {                  7--0--3                              }
  {                   / | \                               }
  {                  6  5  4                              }
BEGIN
  IF (nr IN [0..2])
  THEN get_stick:=device(nr,1)
  ELSE get_stick:=0;
  IF nr=0 THEN kill_kbd;
END;

FUNCTION get_trigger(nr: byte): boolean;
  { scans standard trigger input device, identified by nr.}
  { valid entries are: nr = 0 : space bar                 }
  {                    nr = 1 : firebutton 1              }
  {                    nr = 2 : firebutton 2              }
BEGIN
  IF (nr IN [0..2])
  THEN BEGIN
         IF device(nr,2)=255 THEN get_trigger:=true;
       END
  ELSE get_trigger:=false;
  IF nr=0 THEN kill_kbd;
END;

FUNCTION get_pad(nr: byte): byte;
  {returns value of MSX1 touch pad, connected to a joystick port }
BEGIN
  IF (nr IN [1,2])
  THEN get_pad:=device(nr,3)
  ELSE get_pad:=0;
END;

FUNCTION get_paddle(nr: byte): byte;
  {returns value of MSX1 paddle, connected to a joystick port }
BEGIN
  IF (nr IN [1,2])
  THEN get_paddle:=device(nr,4)
  ELSE get_paddle:=0;
END;

FUNCTION get_newpad(code: byte): integer; { m s x 2 <----------------}
  {returns status/value for different MSX2 devices, connected }
  {to a joystick port.                                        }
  {valid codes are:                                           }
  { 8  : returns 255 if lightpen is connected                 }
  { 9  : returns X-value for lightpen                         }
  {10  : returns Y-value for lightpen                         }
  {11  : returns 255 if lightpen button was pushed            }
  {12  : returns 255 if mouse is connected to port 1          }
  {13  : returns X-offset of mouse on port 1                  }
  {14  : returns Y-offset of mouse on port 1                  }
  {16  : returns 255 if mouse is connected to port 2          }
  {17  : returns X-offset of mouse on port 2                  }
  {18  : returns Y-offset of mouse on port 2                  }
BEGIN
  IF (code IN [8..14,16..18])
  THEN get_newpad:=device(code,5)
  ELSE get_newpad:=0;
END;

FUNCTION scan_fkey: byte;
  { scans MSX-keyboard once for function keys }
  { returns 00 if no key pressed, otherwise   }
  { returns nr. of function key [1..10]       }
VAR F_key: byte;
BEGIN
  INLINE($3E/$06/               {        LD   A,$06       }
         $FD/$21/$00/$00/       {        LD   IY,$0000    }
         $DD/$21/$41/$01/       {        LD   IX,SNSMAT   }
         $CD/$1C/$00/           {        CALL CALSLT      }
                                {; A:=low_active status   }
                                {; of row # 6             }
         $2F/                   {        CPL              }
         $16/$03/               {        LD   D,$03 ; key nr }
         $07/                   {tf123   RLCA                }
                                {; put status in carry       }
         $DA/*+40/              {        JP   C,shift        }
                                {; key pressed, test for     }
                                {; shift key                 }
         $15/                   {        DEC  D           }
         $C2/*-06/              {        JP   NZ,tf123    }
         $16/$04/               {        LD   D,$04       }
         $3E/$07/               {        LD   A,$07       }
         $FD/$21/$00/$00/       {        LD   IY,$0000    }
         $DD/$21/$41/$01/       {        LD   IX,SNSMAT   }
         $CD/$1C/$00/           {        CALL CALSLT      }
         $2F/                   {        CPL              }
         $1E/$02/               {        LD   E,$02       }
         $0F/                   {tf45    RRCA             }
         $DA/*+14/              {        JP   C,shift     }
         $14/                   {        INC  D           }
         $1D/                   {        DEC  E           }
         $C2/*-07/              {        JP   NZ,tf45     }
         $16/$00/               {        LD   D,$00       }
         $3E/$00/               {incr0   LD   A,$00       }
         $C3/*+22/              {        JP   scanrdy     }
         $3E/$06/               {shift   LD   A,$06       }
         $FD/$21/$00/$00/       {        LD   IY,$0000    }
         $DD/$21/$41/$01/       {        LD   IX,SNSMAT   }
         $CD/$1C/$00/           {        CALL CALSLT      }
         $2F/                   {        CPL              }
         $0F/                   {        RRCA             }
         $D2/*-21/              {        JP   NC,incr0    }
         $3E/$05/               {        LD   A,$05       }
         $82/                   {scanrdy ADD   A,D        }
         $32/F_key);            {        LD    (F_key),A  }
  IF F_key<>0 THEN kill_kbd;
  scan_fkey:=F_key;
END;
{--------------------------------------------------------------------}
{             m s x   o u t p u t   d e v i c e s                    }
PROCEDURE init_sound;
  { initializes PSG sound generator }
BEGIN
  INLINE($FD/$21/$00/$00/      { LD   IY,$0000     }
         $DD/$21/$90/$00/      { LD   IX,GICINI    }
         $CD/$1C/$00);         { CALL CALSLT       }
END;

PROCEDURE put_sound(val,reg: byte);
  { writes <val> to register <reg> of sound generator }
  { valid register, value combinations are:           }
  {  reg: 0  frequency channel A [0..255]             }
  {       1  frequency channel A [0..15]              }
  {       2  frequency channel B [0..255]             }
  {       3  frequency channel B [0..15]              }
  {       4  frequency channel C [0..255]             }
  {       5  frequency channel C [0..15]              }
  {       6  noise frequency [0..31]                  }
  {       7  output mode [0..63]                      }
  {       8  volume channel A [0..15]                 }
  {       9  volume channel B [0..15]                 }
  {      10  volume channel C [0..15]                 }
  {      11  envelope timing 1 [0..255]               }
  {      12  envelope timing 2 [0..255]               }
  {      13  envelope mode [0..14]                    }
  { please note that this routine does NOT check for  }
  { illegal registers or data values!                 }
  { For more details please refer to your MSX BASIC   }
  { manual.                                           }
BEGIN
  INLINE($3A/val/                      { LD   A,(val)  }
         $5F/                          { LD   E,A      }
         $3A/reg/                      { LD   A,(reg)  }
         $FD/$21/$00/$00/              { LD   IY,$0000 }
         $DD/$21/$93/$00/              { LD   IX,WRTPSG}
         $CD/$1C/$00);                 { CALL CALSLT   }
END;

FUNCTION get_sound(reg: byte): byte;
 { returns contents of specified PSG register <reg> }
VAR val: byte;
BEGIN
  val:=0;
  IF (reg IN [1..13])
  THEN INLINE($3A/reg/                 { LD   A,(reg)  }
              $FD/$21/$00/$00/         { LD   IY,$0000 }
              $DD/$21/$96/$00/         { LD   IX,RDPSG }
              $CD/$1C/$00/             { CALL CALSLT   }
              $32/val);                { LD   (val),A  }
  get_sound:=val;
END;
