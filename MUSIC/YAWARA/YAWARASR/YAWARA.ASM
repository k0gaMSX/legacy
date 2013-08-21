;
;                 Yawara.Asm/YawaraSf.Asm
;
;         Yawara: General Game Music Player Loader
;
; Version Bianca-1-1 (2nd Ver., 1st Release, 1st Revision)
;
;   This  MSX  Assembly  source file is part of "Yawara:
;   General Game  Music Player". Please, read the notice
;   and documentation file "Yawara.html". If you use the
;   program  in any way  you are  automatically agreeing
;   with  everything stated in  that  file, even if  you
;   haven't read it, so  I  recommend you  do  it. Thank
;   you for your cooperation, good night.
;
;    This file was created, edited and programmed from
;    1994  to 1998 by  "Cyberknight" Masao Kawata  for
;    "Unicorn Dreams Artwork Programs".  For  contact,
;    send an E-Mail to:
;
;                cyber_unicorn@hotmail.com
;
;    Check also the Home Page for new releases:
;
;            http://unicorndreams.home.ml.org
;

;
;   Compile using M80 and L80:
;
;   M80 =Yawara.Asm
;   L80 Yawara,Yawara.Bin /n/e
;
;   To create the "safe mode" file, remove all sections
;   marked with "%%%" and  save as "YawaraSf.Asm", them
;   compile:
;
;   M80 =YawaraSf.Asm
;   L80 YawaraSf,Yawara.Bin /n/e
;

;
;   To execute, go to MSX BASIC and command:
;
;   BLOAD"Yawara.Bin",R
;

;
;   Please, read the documentation file ("Yawara.Txt").
;


; Program addresses.

LdrBsA equ  09000H ; Loader Base Address.
ShlBsA equ  09000H ; Shell Base Address.


; MSX PPI constants.

PrSReg equ  0A8H   ; Primary Slot Register.
KCInpt equ  0A9H   ; Keyboard Column Input.
KRCOMC equ  0AAH   ; Keyboard click, LED and Row, Cas.Out. and Motor Control.
PPICtP equ  0ABH   ; PPI Control Port.


; MSX standard BIOS addresses.

VDPRd  equ  00006H ; Port number to receive data from VDP.
VDPWr  equ  00007H ; Port number to send data to VDP.
MSXVId equ  0002BH ; MSX ROM Identification bytes (5 bytes).
CHGCPU equ  00180H ; Change CPU.


; MSX standard addresses and constants.

GRPNAM equ  0F3C7H ; Graphic mode Name table address.
GRPCOL equ  0F3C9H ; Graphic mode Colour table address.
GRPCGP equ  0F3CBH ; Graphic mode Character image table address.
GRPATR equ  0F3CDH ; Graphic mode sprite Attribute table address.
GRPPAT equ  0F3CFH ; Graphic mode sprite Pattern table address.
CLIKSW equ  0F3DBH ; Key Click Sound Switch (0=Off;NZ=On).
RG0SAV equ  0F3DFH ; VDP Register 0 Save state.
RG1SAV equ  0F3E0H ; VDP Register 1 Save state.
RG7SAV equ  0F3E6H ; VDP Register 7 Save state.
STATFL equ  0F3E7H ; VDP Status register Flag copy.
SCNCNT equ  0F3F6H ; Scan Counter.
REPCNT equ  0F3F7H ; Repetition Counter.
KBUF   equ  0F41FH ; Tokenized Buffer (318).
KBUFSz equ  318    ; KBUF Size.
BUF    equ  0F55EH ; Buffer (259).
BUFSiz equ  259    ; BUF Size.
TEMPST equ  0F67AH ; Temporary String (30).
TEMPSS equ  30     ; TEMPST Size.
TEMP3  equ  0F69DH ; Temporary 3 (2).
TEMP   equ  0F6A7H ; Temporary (2).
TEMP2  equ  0F6BCH ; Temporary 2 (2).
PARM1  equ  0F6E8H ; FN Parameters 1 (100).
PARM1S equ  100    ; PARM1 Size.
PARM2  equ  0F750H ; FN Parameters 2 (100).
PARM2S equ  100    ; PARM2 Size.
TEMP9  equ  0F7B8H ; Temporary 9 (2).
FBUFFR equ  0F7C5H ; Work buffer (43).
FBFFRS equ  43     ; FBUFFR Size.
HOLD8  equ  0F806H ; Multiplication data Hold 8 (65).
HOLD8S equ  65     ; HOLD8 Size.
FNKSTR equ  0F87FH ; Function Key Strings (160).
FNKSTS equ  160    ; FNKSTR Size.
VOICAQ equ  0F975H ; PSG Voice A Queue (128 B for each channel).
VOICSz equ  128*3  ; PSG Voice Queue total Size.
LINTTB equ  0FBB2H ; Line Transpass Table (24).
LNTTBS equ  24     ; LINTTB Size.
OLDKEY equ  0FBDAH ; Old Keys (11).
NEWKEY equ  0FBE5H ; New Keys (11).
LINWRK equ  0FC18H ; Line Work buffer (40).
LINWKS equ  40     ; Line Work buffer Size.
SAVENT equ  0FCBFH ; BSAVE and BLOAD Save Entry.
EXPTBL equ  0FCC1H ; Expanded slot flag Table.
SLTTBL equ  0FCC5H ; Slot Table.
HKEYI  equ  0FD9AH ; Key Interruption Hook.
HTIMI  equ  0FD9FH ; Time Interruption Hook.
RG8SAV equ  0FFE7H ; VDP Register 8 Save state.
RG25SA equ  0FFFAH ; VDP Register 25 Save state.
ScSltR equ  0FFFFH ; Secondary Slot Register.


; BDOS functions.

OpnFil equ  00FH   ; Open file.
ReadBD equ  014H   ; Read Block from file into DTA.
SetDTA equ  01AH   ; Set DTA address.


; BDOS constants.

FCBSiz equ  00028H ; File Control Block Size.
DTASiz equ  00080H ; Disk Data Transfer Area Size.


; BDOS addresses.

RAMAD0 equ  0F341H ; RAM slot ID for page 0 (0000H-3FFFH).
RAMAD1 equ  0F342H ; RAM slot ID for page 1 (4000H-7FFFH).
RAMAD2 equ  0F343H ; RAM slot ID for page 2 (8000H-BFFFH).
BDOS   equ  0F37DH ; Basic BDOS entry point.


; Constant definitions.

KbTRat equ  002H   ; Keyboard Typing Rate (30/s at 60 Hz).
DfKFRD equ  002H   ; Default Keyboard Fast Repeat Delay.
DfKSRD equ  004H   ; Default Keyboard Slow Repeat Delay.
DfFBDR equ  004H   ; Default Frequency Bar graphic Decrement Rate.


; VRAM addresses.

GrpCP0 equ  00000H ; Graphic mode Character generator Pattern table 0 base.
GrpNm0 equ  01800H ; Graphic mode Name table 0 base.
GrpAt0 equ  01B00H ; Graphic mode sprite Attribute table 0 base.
GrpNm1 equ  01C00H ; Graphic mode Name table 1 base.
GrpAt1 equ  01F00H ; Graphic mode sprite Attribute table 1 base.
GrpCl0 equ  02000H ; Graphic mode Colour table 0 base.
GrpPt0 equ  03800H ; Graphic mode sprite Pattern table 0 base.


; Export address bases.

EBTb0  equ  HOLD8  ; 65      ; Enhanced BIOS table address.
EBTb0S equ  HOLD8S           ; Enhanced BIOS table Size.
EBTb1  equ  FBUFFR ; 43      ; Enhanced BIOS table address.
EBTb1S equ  FBFFRS           ; Enhanced BIOS table Size.
EBDBnk equ  FNKSTR ; 160     ; EBIOS Data Bank.
EBRBk0 equ  KBUF   ; 318     ; EBIOS Routine Bank 0.
EBRBS0 equ  KBUFSz           ; EBIOS Routine Bank 0 Size.
EBRBk1 equ  PARM1  ; 100     ; EBIOS Routine Bank 1.
EBRBS1 equ  PARM1S           ; EBIOS Routine Bank 1 Size.
EBRBk2 equ  BUF    ; 259     ; EBIOS Routine Bank 2.
EBRBS2 equ  BUFSiz           ; EBIOS Routine Bank 2 Size.
EBRBk3 equ  PARM2  ; 100     ; EBIOS Routine Bank 3.
EBRBS3 equ  PARM2S           ; EBIOS Routine Bank 3 Size.
EBRBk4 equ  TEMPST ; 30      ; EBIOS Routine Bank 4.
EBRBS4 equ  TEMPSS           ; EBIOS Routine Bank 4 Size.
TDBuf  equ  VOICAQ ; 128x3   ; Temporary Data Buffer.
TDBfSz equ  VOICSz           ; Temporary Data Buffer Size.
SysDB  equ  LINTTB ; 24      ; System Data Bank.


; EBIOS Table 0 entries.

LExecF equ  EBTb0            ; Load and Execute File (3).
LdStrm equ  EBTb0+003H       ; Load Stream (3).
LdFile equ  EBTb0+006H       ; Load File (3).
LdImgH equ  EBTb0+009H       ; Load Image (3).
StNewH equ  EBTb0+00CH       ; Set New interruption Hook (3).
StOldH equ  EBTb0+00FH       ; Set Old interruption Hook (3).
StVDPW equ  EBTb0+012H       ; Set VDP for Writing (3).
StVDPR equ  EBTb0+015H       ; Set VDP for Reading (3).
SVDPIW equ  EBTb0+018H       ; Set VDP for Immediate Writing (3).
SVDPIR equ  EBTb0+01BH       ; Set VDP for Immediate Reading (3).
WrVRMB equ  EBTb0+01EH       ; Write VRAM Byte (3).
RdVRMB equ  EBTb0+021H       ; Read VRAM Byte (3).
WrVDPR equ  EBTb0+024H       ; Write into VDP Register (3).
LVMIR  equ  EBTb0+027H       ; Copy VRAM <- Memory (3).
LMVIR  equ  EBTb0+02AH       ; Copy Memory <- VRAM (3).
LVVIR  equ  EBTb0+02DH       ; Copy VRAM <- VRAM (3).
FilVRB equ  EBTb0+030H       ; Fill VRAM Block (3).
VDPCtl equ  EBTb0+033H       ; VDP Control (3).
RdKbd  equ  EBTb0+036H       ; Read Keyboard (3).
Where  equ  EBTb0+039H       ; Where? (2).


; EBIOS Table 1 entries.

OpenFl equ  EBTb1            ; Open File (3).
CpRdBt equ  EBTb1+003H       ; Copy Read Bytes (internal use, 3).
CpImgB equ  EBTb1+006H       ; Copy Read Bytes (internal use, 3).
ISVDPW equ  EBTb1+009H       ; Internal Set VDP for Writing (3).
ISVDPR equ  EBTb1+00CH       ; Internal Set VDP for Reading (3).
ChkEPR equ  EBTb1+00FH       ; Check if EI required, "POP AF" and "RET" (7).
IntHdl equ  EBTb1+016H       ; "LD A,I", "PUSH AF" and call Int. Handler (6).
MainHk equ  EBTb1+01CH       ; Call to Main Hook (3).
IntExt equ  EBTb1+01FH       ; Branch Interruption Exit (3).
LinInt equ  EBTb1+022H       ; Line Interruption Handler (3).
DMainH equ  EBTb1+025H       ; Disable Main Hook (3).
EMainH equ  EBTb1+028H       ; Enable Main Hook (3).


; EBIOS Data Bank.

ShlNam equ  EBDBnk           ; Shell Name (3).
LstNum equ  EBDBnk+00003H    ; List Number (3).
ItmNum equ  EBDBnk+00006H    ; Item Number (1).
ModNam equ  EBDBnk+00007H    ; List Item Name (8).
SaveSP equ  EBDBnk+0000FH    ; Save Stack Pointer (2).
CmdKey equ  EBDBnk+00011H    ; Command Keys (1).
KbFsRD equ  EBDBnk+00012H    ; Keyboard Fast Repeat Delay (1).
KbSlRD equ  EBDBnk+00013H    ; Keyboard Slow Repeat Delay (1).
FBGDRt equ  EBDBnk+00014H    ; Frequency Bar Graphic Decrement Rate (1).
FMSlt  equ  EBDBnk+00015H    ; MSX-Music Slot (1).
SCCSl0 equ  EBDBnk+00016H    ; SCC Slot 0 (1).
SCCSl1 equ  EBDBnk+00017H    ; SCC Slot 1 (1).
MIType equ  EBDBnk+00018H    ; Music I.C. Type/available, xx S1 S0 FM, (1).
DTA0   equ  EBDBnk+00019H    ; Disk Data Transfer Area 0 (DTASiz).
FCB0   equ  LINWRK           ; File Control Block 0 (FCBSiz).


; System Data Bank.

StupRH equ  SysDB            ; Set-up Routine Hook (3).
SilnRH equ  SysDB+003H       ; Silence Routine Hook (3).
StMsRH equ  SysDB+006H       ; Set Music Routine Hook (3).
PlayRH equ  SysDB+009H       ; Play Routine Hook (3).
VDPRdC equ  SysDB+00CH       ; VDP Reading port number Copy (1).
VDPWrC equ  SysDB+00DH       ; VDP Writing port number Copy (1).
MSXV0C equ  SysDB+00EH       ; MSX ROM Version Id. byte 0 Copy (1).
MSXV2C equ  SysDB+00FH       ; MSX ROM Version Id. byte 2 Copy (1).
SavHok equ  SysDB+010H       ; Save Hook (5).
TimeCt equ  SysDB+015H       ; Time Counter (2).
GCtrlR equ  SysDB+017H       ; General Control Register (1).


       .Z80
       aseg

       org  00100H
       .Phase LdrBsA-7

       db   0FEH             ; Standard MSX BASIC binary file header.
       dw   LdrBsA
       dw   LdrBsA+Tail-Loader
       dw   Loader

Loader:di                    ; Program Loader.
       im   1
       ld   (SaveSP),sp      ; Set-up system dependent values.
       ld   a,(VDPRd)
       ld   (VDPRdC),a
       ld   a,(VDPWr)
       ld   (VDPWrC),a
       ld   a,(MSXVId)
       ld   (MSXV0C),a
       ld   a,(MSXVId+2)
       ld   (MSXV2C),a
       cp   3
       jr   c,SetVar
       xor  a
       call CHGCPU
SetVar:xor  a                ; Set-up BIOS variables.
       ld   (CLIKSW),a
       ld   hl,GrpCP0
       ld   (GRPCGP),hl
       ld   hl,GrpCl0
       ld   (GRPCOL),hl
       ld   hl,GrpPt0
       ld   (GRPPAT),hl
       ld   hl,GrpNm0
       ld   (GRPNAM),hl
       ld   hl,GrpAt0
       ld   (GRPATR),hl

       ld   a,(RAMAD1)       ; Set-up RAM pages.
       ld   h,040H
       call EnSlt

       ld   hl,00000H        ; %%% Copy BIOS to RAM: remove this section
       ld   de,04000H        ; %%% to create "YawaraSf.Asm".
       ld   bc,04000H        ; %%%
       ldir                  ; %%%
       ld   a,(RAMAD0)       ; %%%
       ld   h,000H           ; %%%
       call EnSlt            ; %%%
       ex   de,hl            ; %%%
       ld   hl,04000H        ; %%%
       ld   bc,04000H        ; %%%
       ldir                  ; %%%

       ld   a,0C9H           ; Copy Enhanced BIOS entries.
       ld   (StupRH),a
       ld   (SilnRH),a
       ld   (PlayRH),a
       ld   (StMsRH),a
       ld   hl,EBT0Bn
       ld   de,EBTb0
       ld   bc,EBTb0S ; $$$
       ld   bc,EBT0En-EBT0Bn
       ldir
       ld   hl,EBT1Bn
       ld   de,EBTb1
       ld   bc,EBTb1S ; $$$
       ld   bc,EBT1En-EBT1Bn
       ldir

       ld   hl,EB0Bgn        ; Copy Enhanced BIOS routines.
       ld   de,EBRBk0
       ld   bc,EBRBS0 ; $$$
       ld   bc,EB0End-EB0Bgn
       ldir
       ld   hl,EB1Bgn
       ld   de,EBRBk1
       ld   bc,EBRBS1 ; $$$
       ld   bc,EB1End-EB1Bgn
       ldir
       ld   hl,EB2Bgn
       ld   de,EBRBk2
       ld   bc,EBRBS2 ; $$$
       ld   bc,EB2End-EB2Bgn
       ldir
       ld   hl,EB3Bgn
       ld   de,EBRBk3
       ld   bc,EBRBS3 ; $$$
       ld   bc,EB3End-EB3Bgn
       ldir
       ld   hl,EB4Bgn
       ld   de,EBRBk4
       ld   bc,EBRBS4 ; $$$
       ld   bc,EB4End-EB4Bgn
       ldir

       ld   hl,ShlFFN+8      ; Set-up Enhanced BIOS variables.
       ld   de,ShlNam
       ld   bc,3
       ldir
       ld   hl,DfLsNb
       ld   de,LstNum
       ld   bc,3
       ldir
       ld   hl,ModNam
       ld   de,ModNam+1
       ld   bc,7
       ld   (hl),' '
       ldir
       xor  a
       ld   (ItmNum),a
       ld   (MIType),a
       ld   (FMSlt),a
       ld   (SCCSl0),a
       ld   (SCCSl1),a
       ld   a,DfKFRD
       ld   (KbFsRD),a
       ld   a,DfKSRD
       ld   (KbSlRD),a
       ld   a,DfFBDR
       ld   (FBGDRt),a

       call ChkFM

       ld   hl,HKEYI         ; Save old hook.
       ld   de,SavHok
       ld   bc,5
       ldir
       call StNewH

       call RdKbd            ; Clear keyboard scan matrices.
       call RdKbd

       call IGrpSM           ; Activate SCREEN 2 mode.

       ei                    ; Load and execute default shell.
       ld   hl,ShlBsA
       ld   de,ShlFFN
       call LExecF
       jp   00000H


; Program constants.

ShlFFN:db   'Yawara  '       ; Shell Full File Name.
       db   'Shl'            ; %%% Default Shell Name.
;       db   'SSh'            ; %%% Safe Shell Name: remove ";" of this line.

DfLsNb:db   '000'            ; Default List Number.


; Enhanced BIOS routines.

; ***************************************************************************

EB0Bgn:                      ; EBIOS 0 Begin.

LExcFR:push hl               ; Load and Execute File Routine:
       call LdStrm           ; I(HL=Address;DE=Name);
       pop  hl               ; O(Ret,A:NZ=Error;Pop,Jp (HL),DE=Calling Add.);
       ret  nz               ; m(AF,BC,DE,TEMP,TEMP2).
       pop  de
       jp   (hl)

OpnFlR:push de               ; Open File: I(HL=Destiny;DE=Name,[Length]);
       ld   (TEMP),hl        ; O(A:NZ=Error); m(AF,BC,DE,HL,TEMP,TEMP2).
       ld   hl,FCB0          ; Clears FCB.
       ld   de,FCB0+1
       ld   (hl),000H
       ld   bc,FCBSiz-1
       ldir
       pop  hl
       ld   de,FCB0+1
       ld   bc,11
       ldir
       ld   e,(hl)
       inc  hl
       ld   d,(hl)
       ld   (TEMP2),de
       ld   de,DTA0
       ld   c,SetDTA
       call BDOS
       ld   de,FCB0
       ld   c,OpnFil
       call BDOS
       or   a
       ret

LdStmR:call OpenFl           ; Load Stream: I(HL=Address;DE=Name);
       ret  nz               ; O(A=NZ:Error); m(AF,BC,DE,HL,TEMP,TEMP2).
RStmLp:ld   de,FCB0          ; Reads Stream Loop.
       ld   c,ReadBD
       call BDOS
       cp   002H
       jr   z,FRErr
       ld   bc,DTASiz
       cp   001H
       jr   z,CpRdBR
       call CpRdBt
       jr   RStmLp

CpRdBR:ld   hl,(TEMP)        ; Copy Read Bytes Routine.
       ld   d,h
       ld   e,l
       add  hl,bc
       ld   (TEMP),hl
       ld   hl,DTA0
       ldir
       xor  a
       ret

LdFilR:call OpenFl           ; Load File: I(HL=Address;DE=Name,Length);
       ret  nz               ; O(A=NZ:Error); m(AF,BC,DE,HL).
RdFBLp:ld   de,FCB0          ; Reads File Block Loop.
       ld   c,ReadBD
       call BDOS
       cp   002H
       jr   z,FRErr
       ld   hl,(TEMP2)
       ld   bc,DTASiz
       cp   001H
       jr   z,FndEoF
       or   a
       sbc  hl,bc
       jr   c,CpLsFB
       jr   z,CpLsFB
       ld   (TEMP2),hl
       call CpRdBt
       jr   RdFBLp

CpLsFB:ld   bc,(TEMP2)       ; Copy Last File Bytes.
       call CpRdBt
       ld   hl,0
       ld   (TEMP2),hl
       xor  a
       ret

FndEoF:or   a                ; Found End of File.
       sbc  hl,bc
       jr   c,CpLsFB
       jr   z,CpLsFB
FRErr: or   a                ; File Read Error.
       ret

SNewHR:ld   a,i              ; Set New interruption Hook Routine:
       push af               ; m(AF,DE,HL).
       di
       ld   hl,HKEYI
       ld   de,IntHdl
       ld   (hl),0C3H
       inc  hl
       ld   (hl),e
       inc  hl
       ld   (hl),d
       pop  af
       ret  po
       ei
       ret

SOldHR:ld   a,i              ; Set Old interruption Hook Routine:
       push af               ; m(AF,BC,DE,HL).
       di
       ld   hl,SavHok
SetHKy:ld   de,HKEYI
       ld   bc,00005H
       ldir
       pop  af
       ret  po
       ei
       ret

SVDPWR:push bc               ; Set VDP for Writing Routine:
       call ISVDPW           ; I(HL=VRAM Address).
       pop  bc
       ret

SVDPRR:push bc               ; Set VDP for Reading Routine:
       call ISVDPR           ; I(HL=VRAM Address).
       pop  bc
       ret

WVRMBR:push bc               ; Write VRAM Byte Routine:
       call SVDPIW           ; I(HL=VRAM Address;A=Byte).
       out  (c),a
       pop  bc
       ret

RVRMBR:push bc               ; Read VRAM Byte Routine:
       call SVDPIR           ; I(HL=VRAM Address); O(A=Byte).
       in   a,(c)
       pop  bc
       ret

LVMIRR:push bc               ; Load VRAM <- Memory , Inc. and Repeat Routine:
       ex   de,hl            ; I(HL=Memory Add.;DE=VRAM Add.;BC=# of Bytes);
       call SVDPIW           ; O(VRAM Ptr=Next;C=VDPWrP;HL=Next RAM Add.);
       ex   (sp),hl          ; m(A=0,F=Z,C,HL).
       di
LVMIRL:ld   a,(de)           ; LVMIR Loop.
       out  (c),a
       inc  de
       dec  hl
       ld   a,h
       or   l
       jr   nz,LVMIRL
       pop  hl
       ex   de,hl
       ret

LMVIRR:push bc               ; Load Memory <- VRAM , Inc. and Repeat Routine:
       call SVDPIR           ; I(HL=VRAM Add.;DE=Memory Add.;BC=# of Bytes);
       ex   (sp),hl          ; O(VRAM Ptr.=Next;C=VDPRdP;DE=Next); m(A=0,F=Z,C,DE).
       di
LMVIRL:in   a,(c)            ; LMVIR Loop.
       ld   (de),a
       inc  de
       dec  hl
       ld   a,h
       or   l
       jr   nz,LMVIRL
       pop  hl
       ret


; Internal use EBIOS routines.

ISVPWR:push af               ; Internal Set VDP for Writing Routine:
       ld   a,i              ; I(HL=VRAM Address); O(C=VDPCmP).
       push af
       ld   a,(VDPWrC)
       inc  a
       ld   c,a
       ld   a,l
       di
       out  (c),a
       ld   a,h
       and  00111111B
       or   01000000B
       out  (c),a
       jp   ChkEPR

ISVPRR:ld   a,i              ; Internal Set VDP for Reading Routine:
       push af               ; I(HL=VRAM Address); O(C=VDPRdP); m(AF,C).
       ld   a,(VDPWrC)
       inc  a
       ld   c,a
       ld   a,l
       di
       out  (c),a
       ld   a,h
       and  00111111B
       out  (c),a
       pop  af
       ret  po
       ei
       ret

EB0End:                      ; EBIOS 0 End.

; ***************************************************************************

EB1Bgn:                      ; EBIOS 1 Begin.

SVPIWR:call ISVDPW           ; Set VDP for Immediate Writing Routine:
       dec  c                ; I(HL=VRAM Address); O(C=VDPWrP); m(C).
       ret

SVPIRR:call ISVDPR           ; Set VDP for Immediate Reading Routine:
       push af               ; I(HL=VRAM Address); O(C=VDPRdP); m(C).
       ld   a,(VDPRdC)
       ld   c,a
       pop  af
       ret

WVDPRR:push af               ; Write to VDP Register Routine:
       ld   a,i              ; I(B=Datum;C=Register).
       push af
       push hl
       push bc
       ld   a,c
       and  00111111B
       ld   l,a
       or   10000000B
       ld   h,a
       ld   a,(VDPWrC)
       inc  a
       ld   c,a
       di
       out  (c),b
       ld   a,l
       cp   28
       out  (c),h
       jr   nc,WVDPRE
       cp   24
       jr   z,WVDPRE
       jr   nc,UR25SG
       cp   8
       jr   nc,UR8SvG
       ld   a,b
       ld   bc,RG0SAV
UdVRSv:ld   h,000H           ; Update VDP Register Save copy.
       add  hl,bc
       ld   (hl),a
WVDPRE:pop  bc               ; Do Not Update Save copies.
       pop  hl
       jp   ChkEPR

UR25SG:sub  25               ; Update R25 Save copy group.
       ld   l,a
       ld   a,b
       ld   bc,RG25SA
       jr   UdVRSv

UR8SvG:sub  8                ; Update R25 Save copy group.
       ld   l,a
       ld   a,b
       ld   bc,RG8SAV
       jr   UdVRSv

FlVRBR:push bc               ; Fill VRAM Block Routine:
       call SVDPIW           ; I(A=Datum;HL=VRAM Address;BC=Number of Bytes);
       ex   (sp),hl          ; O(VRAM Ptr:Next;C=VDPWrP);m(AF,BC).
       ld   b,a
FVRBLp:out  (c),b            ; FlVRBR Loop.
       dec  hl
       ld   a,h
       or   l
       jr   nz,FVRBLp
       pop  hl
       ret

EB1End:                      ; EBIOS 1 End.

; ***************************************************************************

EB2Bgn:                      ; EBIOS 2 Begin.

LdImHR:call OpenFl           ; Load Image ignoring Header Routine:
       ret  nz               ; I(HL=VAddress;DE=Name,Length);
       ld   bc,DTASiz-7      ; O(A=NZ:Error);
       ld   (TEMP9),bc       ; m(AF,BC,DE,HL,TEMP,TEMP2,TEMP3,TEMP9).
       ld   hl,DTA0+7
       ld   (TEMP3),hl
       ld   a,(RG7SAV)       ; Sets VDP border colour to 1 (Black).
       and  0F0H
       or   001H
       ld   b,a
       ld   c,007H
       call WrVDPR
RdImLp:ld   de,FCB0          ; Read Image Loop.
       ld   c,ReadBD
       call BDOS
       cp   002H
       jr   z,IRdErr
       ld   hl,(TEMP2)
       ld   bc,(TEMP9)
       cp   001H
       jr   z,FEoImF
       or   a
       sbc  hl,bc
       jr   c,CpLsIB
       jr   z,CpLsIB
       ld   (TEMP2),hl
       call CpImgB
       ld   bc,DTASiz
       ld   (TEMP9),bc
       ld   bc,DTA0
       ld   (TEMP3),bc
       jr   RdImLp

FEoImF:or   a                ; Found End of Image File.
       sbc  hl,bc
       jr   c,CpLsIB
       jr   z,CpLsIB
IRdErr:or   a                ; Image file Read Error.
       ret

CpImBR:ld   hl,(TEMP)        ; Copies Image Bytes.
       ld   d,h
       ld   e,l
       add  hl,bc
       ld   (TEMP),hl
       ld   hl,(TEMP3)
       jp   LVMIR

CpLsIB:ld   bc,(TEMP2)       ; Copies Last Image Bytes.
       call CpImgB
       ld   hl,0
       ld   (TEMP2),hl
       xor  a
       ret

LVVIRR:push hl               ; LDIR VRAM <- VRAM :
       ld   hl,TDBfSz        ; I(HL=Source;DE=Destiny;BC=Length);
       or   a                ; O(C=VDP Writing Port); m(TDBuf;AF,BC,DE,HL).
       sbc  hl,bc
       pop  hl
       jr   nc,LVVIRE
       push bc
       push de
       ld   de,TDBuf
       ld   bc,TDBfSz
       call LMVIR
       pop  de
       push hl
       ld   hl,TDBuf
       ld   bc,TDBfSz
       call LVMIR
       pop  hl
       ex   (sp),hl
       ld   bc,TDBfSz
       or   a
       sbc  hl,bc
       ex   (sp),hl
       add  hl,bc
       ex   de,hl
       add  hl,bc
       ex   de,hl
       pop  bc
       jr   LVVIRR

LVVIRE:push bc               ; VRAM LDIR Exit.
       push de
       ld   de,TDBuf
       call LMVIR
       pop  de
       pop  bc
       ld   hl,TDBuf
       jp   LVMIR

VDPCtR:ld   bc,(RG1SAV-1)    ; VDP Control Routine:
       ld   c,a              ; I(A:0=Dis.Scr.,1=En.Scr.,2=Dis.Int.,3=En.Int.);
       and  00000001B        ; m(F,BC).
       bit  1,c
       jr   z,VDPCR2
       res  5,b
       rrca
VDPCR1:rrca                  ; VDPCtR (I).
       rrca
       or   b
       ld   b,a
       ld   c,001H
       jp   WrVDPR

VDPCR2:res  6,b              ; VDPCtR (II).
       jr   VDPCR1

IntHPR:call StOldH           ; Interruption Hook Processor Routine.
       call HKEYI
       ld   a,(VDPRdC)
       ld   c,a
       inc  c
       in   a,(c)
       and  a
       ld   (STATFL),a
       jp   p,LinInt
       ld   hl,(TimeCt)
       inc  hl
       ld   (TimeCt),hl
       call HTIMI
       jp   RdKbd

DManHR:ld   a,021H
       jr   SMainH

EManHR:ld   a,0CDH
SMainH:ld   (MainHk),a
       ret

EB2End:                      ; EBIOS 2 End.

; ***************************************************************************

EB3Bgn:                      ; EBIOS 3 Begin.

RdKbdR:ld   hl,SCNCNT        ; Read Keyboard Routine:
       ld   a,(hl)           ; O(Z=New Key Pressed);
       or   a                ; m(AF,BC,DE,HL,BC',DE',HL').
       jr   z,RdKbR1
       dec  (hl)
       ret  nz
RdKbR1:ld   (hl),KbTRat      ; RdKbdR (I).
       in   a,(KRCOMC)
       and  0F0H
       ld   c,a
       ld   b,11
       ld   hl,NEWKEY
       ld   de,OLDKEY
       exx
       ld   c,000H
       exx
RdKbR2:ld   a,c              ; RdKbdR (II).
       out  (KRCOMC),a
       ld   a,(hl)
       ld   (de),a
       exx
       ld   h,a
       in   a,(KCInpt)
       cpl
       ld   l,a
       xor  h
       and  l
       or   c
       ld   c,a
       ld   a,l
       exx
       ld   (hl),a
       inc  c
       inc  hl
       inc  de
       djnz RdKbR2
       exx
       ld   a,c
       or   a
       ld   hl,REPCNT
       ld   a,(KbSlRD)
       jr   nz,RdKbR4
       ld   a,(hl)
       or   a
       jr   z,RdKbR3
       dec  (hl)
       ret  nz
RdKbR3:ld   a,(KbFsRD)       ; RdKbdR (III).
RdKbR4:ld   (hl),a           ; RdKbdR (IV).
       ld   hl,NEWKEY+8
       ld   a,(hl)           ; Command Keys = Rg Dw Up Lf Es CR Sl Sp.
       and  11110001B
       ld   b,a
       dec  hl
       ld   a,(hl)
       rlca
       ld   c,a
       and  00001000B
       or   b
       ld   b,a
       ld   a,c
       rlca
       rlca
       and  00000110B
       or   b
       ld   (CmdKey),a
       xor  a
       ret

EB3End:                      ; EBIOS 3 End.

; ***************************************************************************

EB4Bgn:                      ; EBIOS 4 Begin.

ExtIHR:call StNewH           ; Exit Interruption Handler Routine.
       ld   a,003H
       call VDPCtl
       pop  af
       ld   i,a
       pop  hl               ; Discard calling routine return address.
       pop  ix
       pop  iy
       pop  af
       pop  bc
       pop  de
       pop  hl
       ex   af,af'
       exx
       pop  af
       pop  bc
       pop  de
       pop  hl
       ei
       ret

EB4End:                      ; EBIOS 4 End.

; ***************************************************************************


; Pieces of code...

EnSlt: call EnSlt2
       jp   m,EnSlt1
       in   a,(PrSReg)
       and  c
       or   b
       out  (PrSReg),a
       ret

EnSlt1:push hl
       call EnSlt5
       ld   c,a
       ld   b,000H
       ld   a,l
       and  h
       or   d
       ld   hl,SLTTBL
       add  hl,bc
       ld   (hl),a
       pop  hl
       ld   a,c
       jr   EnSlt

EnSlt2:di
       push af
       ld   a,h
       rlca
       rlca
       and  00000011B
       ld   e,a
       ld   a,11000000B
EnSlt3:rlca
       rlca
       dec  e
       jp   p,EnSlt3
       ld   e,a
       cpl
       ld   c,a
       pop  af
       push af
       and  00000011B
       inc  a
       ld   b,a
       ld   a,10101011B
EnSlt4:add  a,01010101B
       djnz EnSlt4
       ld   d,a
       and  e
       ld   b,a
       pop  af
       and  a
       ret

EnSlt5:push af
       ld   a,d
       and  11000000B
       ld   c,a
       pop  af
       push af
       ld   d,a
       in   a,(PrSReg)
       ld   b,a
       and  00111111B
       or   c
       out  (PrSReg),a
       ld   a,d
       rrca
       rrca
       and  00000011B
       ld   d,a
       ld   a,10101011B
EnSlt6:add  a,01010101B
       dec  d
       jp   p,EnSlt6
       and  e
       ld   d,a
       ld   a,e
       cpl
       ld   h,a
       ld   a,(ScSltR)
       cpl
       ld   l,a
       and  h
       or   d
       ld   (ScSltR),a
       ld   a,b
       out  (PrSReg),a
       pop  af
       and  00000011B
       ret

IGrpSM:xor  a                ; Initialize Graphical Screen Mode.
       call VDPCtl
       ld   a,(RG0SAV)       ; R0 = 0 0 0 0 0 0 M3 ExtnVideo.
       or   00000010B
       ld   b,a
       ld   c,000H
       call WrVDPR
       ld   a,(RG1SAV)       ; R1 = 4/16K DspEn IntEn M1 M2 0 SprSize SprMag.
       and  11000100B
       or   00100010B
       ld   b,a
       inc  c
       call WrVDPR
       ld   hl,GRPNAM
       ld   de,7F03H
       ld   bc,0602H
       call IGSCVR
       ld   b,10
       ld   a,d
       call IGSVRg
       ld   b,5
       ld   a,e
       call IGSVRg
       ld   b,9
       call IGSCVR
       ld   b,5
IGSCVR:xor  a                ; IGrpSM Set with Clear accumulator VDP Reg.
IGSVRg:push hl               ; IGrpSM Set VDP Register.
       push af
       ld   a,(hl)
       inc  hl
       ld   h,(hl)
       ld   l,a
       xor  a
IGRIAc:add  hl,hl            ; IGrpSM Rotate Into Accumulator.
       adc  a,a
       djnz IGRIAc
       ld   l,a
       pop  af
       or   l
       ld   b,a
       call WrVDPR
       pop  hl
       inc  hl
       inc  hl
       inc  c
       ret

RdKbRw:push bc               ; Read Keyboard Row:
       ld   c,a              ; I(A=Row); O(A=Column Datum); m(AF).
       ld   a,i
       push af
       di
       in   a,(KRCOMC)
       and  11110000B
       or   c
       out  (KRCOMC),a
       pop  bc
       in   a,(KCInpt)
       cpl
       bit  3,c
       pop  bc
       ret  z
       ei
       ret

LinItR:                      ; Line Interrupt Routine example. Do something...
       pop  hl               ; Remove call back address.
       call StNewH           ; Reactivate new hook.
       jp   IntExt           ; Return from interruption.

ChkFM: ld   hl,MIType        ; Check MSX-Music.
       ld   a,(hl)
       and  11111100B
       ld   (hl),a
       ld   a,10000000B
ChkFML:push af               ; ChkFM Loop.
       ld   b,a
       ld   a,(RAMAD1)
       cp   b
       jr   z,NxtSlt
       ld   a,b
       ld   h,040H
       call EnSlt
       ld   hl,AprlSt
       call CmpStr
       ld   a,00000001B
       jr   z,FndFM0
       ld   hl,Pac2St
       call CmpStr
       ld   a,00000011B
       jr   z,FndFM1
NxtSlt:pop  af               ; Next Slot.
       inc  a
       cp   10010000B
       jr   c,ChkFML
       jr   ExCkFM

FndFM1:ld   hl,07FF6H        ; Found FM type 1.
       ld   (hl),001H
FndFM0:ld   hl,05FFEH        ; Found FM type 0.
       ld   (hl),000H
       ld   hl,05FFFH
       ld   (hl),000H
       ld   hl,MIType
       or   (hl)
       ld   (hl),a
       pop  af
       ld   (FMSlt),a
ExCkFM:ld   a,(RAMAD1)       ; Exit Check MSX-Music.
       ld   h,040H
       jp   EnSlt

CmpStr:ld   de,04018H        ; Compare Strings.
       ld   b,8
CpStrL:ld   a,(de)           ; CmpStr Loop.
       cp   (hl)
       ret  nz
       inc  hl
       inc  de
       djnz CpStrL
       ret

AprlSt:db   'APRLOPLL'       ; MSX-Music type 0 String.
Pac2St:db   'PAC2OPLL'       ; MSX-Music type 1 String.


; Tron

Tron:  ld   hl,(GRPNAM)      ; Tracer On... $$$
       ld   de,32*23+12
       add  hl,de
       call SVDPIW
       ld   d,'0'
       ld   e,'1'
       ld   b,8
       ld   a,(CmdKey)
TronLp:rlca
       jr   nc,Tron0
       out  (c),e
       djnz TronLp
       ret

Tron0: out  (c),d
       djnz TronLp
       ret


; Game Patcher

       call Where
Here:  ld   de,There-Here
       add  hl,de
       ld   a,000H; Value
Patch: ex   af,af'
       ld   e,(hl)
       inc  hl
       ld   d,(hl)
       inc  hl
       ld   a,e
       inc  a
       jr   z,Init
       ld   a,d
       inc  a
       jr   z,Init
       ex   af,af'
       ld   (de),a
       jr   Patch

There: dw   00000H,00000H ;...
       dw   0FFFFH

Init:  ; Continue...


; Program variables.

ShelFN:db   'Yawara  '       ; Shell File Name.
       ds   3


EBT0Bn:                      ; EBIOS entry Table 0 Begin.

       jp   LExcFR-EB0Bgn+EBRBk0
       jp   LdStmR-EB0Bgn+EBRBk0
       jp   LdFilR-EB0Bgn+EBRBk0
       jp   LdImHR-EB2Bgn+EBRBk2
       jp   SNewHR-EB0Bgn+EBRBk0
       jp   SOldHR-EB0Bgn+EBRBk0
       jp   SVDPWR-EB0Bgn+EBRBk0
       jp   SVDPRR-EB0Bgn+EBRBk0
       jp   SVPIWR-EB1Bgn+EBRBk1
       jp   SVPIRR-EB1Bgn+EBRBk1
       jp   WVRMBR-EB0Bgn+EBRBk0
       jp   RVRMBR-EB0Bgn+EBRBk0
       jp   WVDPRR-EB1Bgn+EBRBk1
       jp   LVMIRR-EB0Bgn+EBRBk0
       jp   LMVIRR-EB0Bgn+EBRBk0
       jp   LVVIRR-EB2Bgn+EBRBk2
       jp   FlVRBR-EB1Bgn+EBRBk1
       jp   VDPCtR-EB2Bgn+EBRBk2
       jp   RdKbdR-EB3Bgn+EBRBk3
WherAI:pop  hl               ; Where Am I?
       jp   (hl)

EBT0En:                      ; EBIOS entry Table 0 End.

EBT1Bn:                      ; EBIOS entry Table 1 Begin.

       jp   OpnFlR-EB0Bgn+EBRBk0
       jp   CpRdBR-EB0Bgn+EBRBk0
       jp   CpImBR-EB2Bgn+EBRBk2
       jp   ISVPWR-EB0Bgn+EBRBk0
       jp   ISVPRR-EB0Bgn+EBRBk0
CkEPRR:pop  af
       jp   po,PpAFRR-EBT1Bn+EBTb1
       ei
PpAFRR:pop  af
       ret

IntHlR:ld   a,i                   ; Interruption Handler Routine.
       push af
       call IntHPR-EB2Bgn+EBRBk2
MainHE:ld   hl,00000H             ; Main Hook Entry point.
IntExB:jp   ExtIHR-EB4Bgn+EBRBk4  ; Interruption Exit Branch.
LinItE:ret                        ; Line Interruption Entry point.
       ret
       ret

       jp   DManHR-EB2Bgn+EBRBk2
       jp   EManHR-EB2Bgn+EBRBk2

EBT1En:                      ; EBIOS entry Table 1 End.


       db   'Yawara: General Game Music and Sound Effect Player.',00DH,00AH
       db   'Programmed by "Cyberknight" Masao Kawata.',00DH,00AH
       db   '1994, 1998 Unicorn Dreams Artwork Programs release.',00DH,00AH
       db   'This program is "freeware". It may be freely copied '
       db   'and distributed. IT CANNOT BE SOLD OR INCORPORATED '
       db   'INTO ANY COMMERCIAL PRODUCT WITHOUT PERMISSION.',00DH,00AH
       db   'Most music titles are mine - the composers have no guilt '
       db   'about that - because I generally have no way to know the '
       db   'original titles. For more information, please read the '
       db   'documentation file or find me in the Internet, searching '
       db   'for "Cyberknight".',00DH,00AH
       db   'Special thanks to my Family, the Unicorns, Isaac Asimov, '
       db   'Peter S. Beagle, Michael Ende, all Artists and all good '
       db   'MSX programmers and users.',00DH,00AH,0

Tail:  end
