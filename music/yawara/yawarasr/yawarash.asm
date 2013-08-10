;
;                       YawaraSh.Asm
;
;         Yawara: General Game Music Player Shell
;
; Version Bianca-2-1 (2nd Ver., 2nd Release, 1st Revision)
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
;   M80 =YawaraSh.Asm
;   L80 YawaraSh,Yawara.Shl /n/e
;
;   To create the "safe mode" file, remove all sections
;   marked with "%%%" and  save as "YawaraSS.Asm", them
;   compile:
;
;   M80 =YawaraSS.Asm
;   L80 YawaraSS,Yawara.SSh /n/e
;

;
;    To execute, run the  program loader "Yawara.Bin".
;    Please, read the documentation file "Yawara.Txt".
;


; Program addresses.

ShlBsA equ  09000H           ; Base Address.


; MSX PSG constants.

PSGAdr equ  0A0H             ; PSG register Address port.
PSGWrP equ  0A1H             ; PSG Write Port.
PSGRdP equ  0A2H             ; PSG Read Port.
PALwPr equ  000H             ; PSG channel A Low Period.
PAHgPr equ  001H             ; PSG channel A High Period.
PBLwPr equ  002H             ; PSG channel B Low Period.
PBHgPr equ  003H             ; PSG channel B High Period.
PCLwPr equ  004H             ; PSG channel C Low Period.
PCHgPr equ  005H             ; PSG channel C High Period.
PNsTon equ  006H             ; PSG Noise Tone.
PChnCt equ  007H             ; PSG Channel Control.
PAVol  equ  008H             ; PSG channel A Volume.
PBVol  equ  009H             ; PSG channel B Volume.
PCVol  equ  00AH             ; PSG channel C Volume.
PELwPr equ  00BH             ; PSG Envelope Low Period.
PEHgPr equ  00CH             ; PSG Envelope High Period.
PEWvFm equ  00DH             ; PSG Envelope Wave Format.


; MSX PPI constants.

PrSReg equ  0A8H             ; Primary Slot Register.
KCInpt equ  0A9H             ; Keyboard Column Input.
KRCOMC equ  0AAH             ; Key click, LED and Row, Cas.Out. and Motor Control.
PPICtP equ  0ABH             ; PPI Control Port.


; MSX standard BIOS addresses.

VDPRd  equ  00006H           ; Port number to receive data from VDP.
VDPWr  equ  00007H           ; Port number to send data to VDP.
MSXVId equ  0002BH           ; MSX ROM Identification bytes (5 bytes).


; MSX standard addresses and constants.

GRPNAM equ  0F3C7H           ; Graphic mode Name table address.
GRPCOL equ  0F3C9H           ; Graphic mode Colour table address.
GRPCGP equ  0F3CBH           ; Graphic mode Character image table address.
GRPATR equ  0F3CDH           ; Graphic mode sprite Attribute table address.
GRPPAT equ  0F3CFH           ; Graphic mode sprite Pattern table address.
CLIKSW equ  0F3DBH           ; Key Click Sound Switch (0=Off;NZ=On).
RG0SAV equ  0F3DFH           ; VDP Register 0 Save state.
RG1SAV equ  0F3E0H           ; VDP Register 1 Save state.
RG7SAV equ  0F3E6H           ; VDP Register 7 Save state.
STATFL equ  0F3E7H           ; VDP Status register Flag copy.
SCNCNT equ  0F3F6H           ; Scan Counter.
REPCNT equ  0F3F7H           ; Repetition Counter.
KBUF   equ  0F41FH           ; Tokenized Buffer (318).
KBUFSz equ  318              ; KBUF Size.
BUF    equ  0F55EH           ; Buffer (259).
BUFSiz equ  259              ; BUF Size.
TEMPST equ  0F67AH           ; Temporary String (30).
TEMPSS equ  30               ; TEMPST Size.
TEMP3  equ  0F69DH           ; Temporary 3 (2).
TEMP   equ  0F6A7H           ; Temporary (2).
TEMP2  equ  0F6BCH           ; Temporary 2 (2).
PARM1  equ  0F6E8H           ; FN Parameters 1 (100).
PARM1S equ  100              ; PARM1 Size.
PARM2  equ  0F750H           ; FN Parameters 2 (100).
PARM2S equ  100              ; PARM2 Size.
TEMP9  equ  0F7B8H           ; Temporary 9 (2).
FBUFFR equ  0F7C5H           ; Work buffer (43).
FBFFRS equ  43               ; FBUFFR Size.
HOLD8  equ  0F806H           ; Multiplication data Hold 8 (65).
HOLD8S equ  65               ; HOLD8 Size.
FNKSTR equ  0F87FH           ; Function Key Strings (160).
FNKSTS equ  160              ; FNKSTR Size.
VOICAQ equ  0F975H           ; PSG Voice A Queue (128 B for each channel).
VOICSz equ  128*3            ; PSG Voice Queue total Size.
LINTTB equ  0FBB2H           ; Line Transpass Table (24).
LNTTBS equ  24               ; LINTTB Size.
OLDKEY equ  0FBDAH           ; Old Keys (11).
NEWKEY equ  0FBE5H           ; New Keys (11).
LINWRK equ  0FC18H           ; Line Work buffer (40).
LINWKS equ  40               ; Line Work buffer Size.
SAVENT equ  0FCBFH           ; BSAVE and BLOAD Save Entry.
EXPTBL equ  0FCC1H           ; Expanded slot flag Table.
SLTTBL equ  0FCC5H           ; Slot Table.
HKEYI  equ  0FD9AH           ; Key Interruption Hook.
HTIMI  equ  0FD9FH           ; Time Interruption Hook.
RG8SAV equ  0FFE7H           ; VDP Register 8 Save state.
RG25SA equ  0FFFAH           ; VDP Register 25 Save state.
ScSltR equ  0FFFFH           ; Secondary Slot Register.


; BDOS functions.

OpnFil equ  00FH             ; Open file.
ReadBD equ  014H             ; Read Block from file into DTA.
SetDTA equ  01AH             ; Set DTA address.


; BDOS constants.

FCBSiz equ  00028H           ; File Control Block Size.
DTASiz equ  00080H           ; Disk Data Transfer Area Size.


; BDOS addresses.

RAMAD0 equ  0F341H           ; RAM slot ID for page 0 (0000H-3FFFH).
RAMAD1 equ  0F342H           ; RAM slot ID for page 1 (4000H-7FFFH).
RAMAD2 equ  0F343H           ; RAM slot ID for page 2 (8000H-BFFFH).
MASTERS equ 0F348H           ; Disk-driver interface Master Slot.
BDOS   equ  0F37DH           ; Basic BDOS entry point.

; Key definitions.

CrRetK equ  00DH             ; <Carriage Return Key>.
SelctK equ  018H             ; <Select Key>.
EscapK equ  01BH             ; <Escape Key>.
ArrowR equ  01CH             ; <Arrow Right>.
ArrowL equ  01DH             ; <Arrow Left>.
ArrowU equ  01EH             ; <Arrow Up>.
ArrowD equ  01FH             ; <Arrow Down>.


; Constant definitions.

OpnAnS equ  001H             ; Opening Animation State.
SttAnS equ  002H             ; Start Animation State.
MMAnmS equ  003H             ; Main Menu Animation State.
PlyMsS equ  004H             ; Play Music State.

KbTRat equ  002H             ; Keyboard Typing Rate (30/s at 60 Hz).


; VRAM addresses.

GRPNM0 equ  01800H           ; Graphic mode Name table 0.
GRPNM1 equ  01C00H           ; Graphic mode Name table 1.


; Export address bases.

EBTb0  equ  HOLD8   ; 65     ; Enhanced BIOS table address.
EBTb0S equ  HOLD8S           ; Enhanced BIOS table Size.
EBTb1  equ  FBUFFR  ; 43     ; Enhanced BIOS table address.
EBTb1S equ  FBFFRS           ; Enhanced BIOS table Size.
EBDBnk equ  FNKSTR  ; 160    ; EBIOS Data Bank.
EBRBk0 equ  KBUF    ; 318    ; EBIOS Routine Bank 0.
EBRBS0 equ  KBUFSz           ; EBIOS Routine Bank 0 Size.
EBRBk1 equ  PARM1   ; 100    ; EBIOS Routine Bank 1.
EBRBS1 equ  PARM1S           ; EBIOS Routine Bank 1 Size.
EBRBk2 equ  BUF     ; 259    ; EBIOS Routine Bank 2.
EBRBS2 equ  BUFSiz           ; EBIOS Routine Bank 2 Size.
EBRBk3 equ  PARM2   ; 100    ; EBIOS Routine Bank 3.
EBRBS3 equ  PARM2S           ; EBIOS Routine Bank 3 Size.
EBRBk4 equ  TEMPST  ; 30     ; EBIOS Routine Bank 4.
EBRBS4 equ  TEMPSS           ; EBIOS Routine Bank 4 Size.
TDBuf  equ  VOICAQ  ; 128x3  ; Temporary Data Buffer.
TDBfSz equ  VOICSz           ; Temporary Data Buffer Size.
SysDB  equ  LINTTB  ; 24     ; System Data Bank.


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
       .Phase ShlBsA

LstMnu:di                    ; List Menu.
       im   1
       ld   sp,(SaveSP)
       xor  a
       ld   (CmdKey),a
       cpl
       ld   (GCtrlR),a
       ld   a,KbTRat
       ld   (SCNCNT),a
       ld   a,(KbSlRD)
       ld   (REPCNT),a
       ld   a,0C9H
       ld   (StupRH),a
       ld   (SilnRH),a
       ld   (StMsRH),a
       ld   (PlayRH),a
       ld   hl,MainHR
       ld   (MainHk+1),hl

       ld   a,(EXPTBL)       ; %%% Copy BIOS to RAM: remove this
       ld   hl,00000H        ; %%% section to create "YawaraSS.Asm".
       call EnSlt            ; %%%
       ld   de,04000H        ; %%%
       ld   bc,04000H        ; %%%
       ldir                  ; %%%
       ld   a,(RAMAD0)       ; %%%
       ld   hl,00000H        ; %%%
       call EnSlt            ; %%%
       ex   de,hl            ; %%%
       ld   hl,04000H        ; %%%
       ld   bc,04000H        ; %%%
       ldir                  ; %%%

       call EMainH
LdList:ld   hl,GameDt        ; Load List.
       ld   (hl),0FFH
       inc  hl
       ld   (LsItPt),hl
       xor  a
       ld   (PrgmSt),a
       call VDPCtl
       call ClASpr
       call StDfCS
       ld   hl,LstNum
       ld   de,LstNam+8
       ld   bc,3
       ldir
LdLst1:call ClrGSc           ; Load List (I).
       ld   hl,GameDt+1
       ld   de,LstNam
       call LdStrm
       jp   z,PtLsSc
       ld   hl,0010AH
       ld   de,01E10H
       ld   ix,BdChr0
       call DrwBox
       ld   de,32*12+2
       call PrtCRM
       ld   hl,(GRPNAM)
       ld   de,32*14+6
       add  hl,de
       call SVDPIW
       ld   d,000H
       call PrtStr
       db   'Press ',0
       ld   d,080H
       call PrtStr
       db   '<Space>',0
       ld   d,000H
       call PrtStr
       db   ' key...',0
       ld   a,001H
       call VDPCtl
       call WaitSp
       jp   LdList

LstNam:db   'YawaraML'       ; List Base Name.
       ds   3

DfLsNb:db   '000'            ; Default List Number.

Title0:db    '"Yawara$: General Game'
       db    'Music and Effect Player'
       db   '1994,1998 Unicorn Dreams'
       db   'Artwork Programs release'
       db   'Program by "Cyberknight$'

PtLsSc:call ClrGSc           ; Print List Screen.
       ld   hl,LstNam+8
       ld   de,LstNum
       ld   bc,3
       ldir
       ld   hl,00000H
       ld   de,01F06H
       ld   ix,BdChr0
       call DrwBox
       ld   hl,32*1+8
       ld   de,Title0
       ld   bc,01680H
       call GPrint
       ld   hl,32*2+8
       ld   b,017H
       call GPrint
       ld   hl,32*3+7
       ld   bc,01800H
       call GPrint
       ld   hl,32*4+7
       call GPrint
       ld   hl,32*5+7
       call GPrint
       call PrtUni
       call StAnmt
       ld   hl,32*8+4
       ld   de,(GRPNAM)
       add  hl,de
       ld   (MrkdVA),hl
       ld   ix,BdChr1
       ld   hl,00107H
       ld   de,01E15H
       call DrwBox
       ld   de,32*8+4
       ld   hl,(GRPNAM)
       add  hl,de
       ld   de,GameDt+1
       ex   de,hl
       ld   a,(ItmNum)
PrtLst:ex   af,af'           ; Print List.
       ld   a,(hl)
       inc  a
       jr   z,SlcItm
       ld   bc,24
       push hl
       call LVMIR
       pop  hl
       ex   af,af'
       or   a
       jp   nz,PrNxLI
       ld   (MrkdVA),de
       ld   (LsItPt),hl
PrNxLI:dec  a                ; Print Next List Item.
       ld   c,32
       add  hl,bc
       ex   de,hl
       add  hl,bc
       ex   de,hl
       jr   PrtLst

GPrint:push bc               ; Graphical menu Print:
       push bc               ; I(HL=Offset;DE=Str.Ptr;B=Length;C=Offset);
       push de               ; O(DE=Next Address); m(AF,DE,HL).
       ld   de,(GRPNAM)
       add  hl,de
       call StVDPW
       pop  de
       pop  bc
       ex   de,hl
       call WrVRAM
       ex   de,hl
       pop  bc
       ret

SlcItm:ld   (CmdKey),a       ; Select Item.
       ld   a,001H
       call VDPCtl
       ld   hl,(MrkdVA)
       dec  hl
       dec  hl
       ld   (MrkdVA),hl
SlcIt1:ld   hl,(MrkdVA)      ; Select Item (I).
       call SVDPIW
       ld   hl,(LsItPt)
       ld   a,'{'
       out  (c),a
       ld   a,' '
       out  (c),a
       ld   bc,01880H
       call WrVRAM
       ld   a,' '
       out  (c),a
       ld   a,'}'
       out  (c),a
SlItKy:ei                    ; Select Item Key.
       ld   a,(CmdKey)
       bit  5,a
       jp   nz,SlItUp
       bit  6,a
       jp   nz,SlItDw
       bit  3,a
       jp   nz,TryRtB
       bit  0,a
       jr   z,SlItKy
       ld   a,003H
       call SetSFX
WaitSl:ei                    ; Wait for Silence.
       ld   a,(SndStR)
       or   a
       jr   nz,WaitSl
       xor  a
       ld   (CmdKey),a
       ld   hl,(LsItPt)
       ld   bc,24
       add  hl,bc
       ld   a,(hl)
       cp   '.'
       jp   z,LstSlc
       ld   de,ModNam
       ld   bc,8
       ldir
       dec  hl
       ld   de,GMMFFN+7
       ld   bc,8
       lddr
       ld   hl,00008H
       ld   de,01F0EH
       ld   ix,BdChr0
       call DrwBox
       ld   hl,(GRPNAM)
       ld   de,32*10+12
       add  hl,de
       call SVDPIW
       ld   d,000H
       call PrtStr
       db   'Loading:',0
       ld   hl,(GRPNAM)
       ld   de,32*12+4
       add  hl,de
       call SVDPIW
       ld   hl,(LsItPt)
       ld   bc,01880H
       call WrVRAM
       ld   hl,GameDt
       ld   de,GMMFFN
       call LdStrm
       jr   nz,GLdErr
       call DMainH
       ld   hl,(GMPBAd)
       ld   de,GMPNam
       call LExecF
       call EMainH
GLdErr:ld   a,001H           ; General Loading Error.
       call VDPCtl
       ld   hl,00111H
       ld   de,01E17H
       ld   ix,BdChr1
       call DrwBox
       ld   de,32*19+3
       call PrtCRM
       ld   hl,(GRPNAM)
       ld   de,32*21+3
       add  hl,de
       call SVDPIW
       ld   d,080H
       call PrtFEM
       jp   LdList

GMMFFN:ds   8                ; Game Music Module Full File Name.
       db   'GMM'

LstSlc:inc  hl               ; List Selected.
       ld   de,LstNam+8
       ld   bc,3
       ldir
       ld   hl,GameDt+1
       ld   (LsItPt),hl
       xor  a
       ld   (ItmNum),a
       jp   LdLst1

SlItUp:xor  a                ; Select Item Up.
       ld   (CmdKey),a
       ld   hl,(LsItPt)
       dec  hl
       ld   a,(hl)
       inc  a
       jp   z,SlItKy
       call ClItCs
       or   a
       sbc  hl,bc
       ld   (MrkdVA),hl
       ld   hl,(LsItPt)
       or   a
       sbc  hl,bc
       ld   (LsItPt),hl
       ld   hl,ItmNum
       dec  (hl)
       ld   a,001H
       call SetSFX
       jp   SlcIt1

SlItDw:xor  a                ; Select Item Down.
       ld   (CmdKey),a
       ld   hl,(LsItPt)
       ld   bc,32
       add  hl,bc
       ld   a,(hl)
       inc  a
       jp   z,SlItKy
       exx
       call ClItCs
       add  hl,bc
       ld   (MrkdVA),hl
       exx
       ld   (LsItPt),hl
       ld   hl,ItmNum
       inc  (hl)
       ld   a,002H
       call SetSFX
       jp   SlcIt1

ClItCs:ld   hl,(MrkdVA)      ; Clear Item Cursor.
       call SVDPIW           ; Cannot be optimized without risk to MSX VDP.
       ld   a,' '
       out  (c),a
       ld   hl,(LsItPt)
       out  (c),a
       ld   bc,01800H
       call WrVRAM
       ld   a,' '
       out  (c),a
       ld   hl,(MrkdVA)
       out  (c),a
       ld   c,32
       ret

WrVRAM:ld   d,c              ; Write B bytes to VRAM:
       ld   a,(VDPWrC)       ; I(VDP=Pos;B=# of Bytes;C=Offset;HL=Str.Ptr.);
       ld   c,a              ; O(C=VDPWP;HL=Next); m(AF,B=0,C,D,HL).
WrVRML:ld   a,(hl)           ; Write B bytes to VRAM (I).
       add  a,d
       out  (c),a
       inc  hl
       djnz WrVRML
       ret

PrtStr:ex   (sp),hl          ; Print String.
       jr   PrtSt2

PrtSt1:add  a,d              ; Print String (I).
       out  (c),a
PrtSt2:ld   a,(hl)           ; Print String (II).
       inc  hl
       or   a
       jr   nz,PrtSt1
       ex   (sp),hl
       ret

PrtCRM:ld   hl,(GRPNAM)
       add  hl,de
       call SVDPIW
       ld   hl,FCB0+1
       ld   bc,00800H
       call WrVRAM
       ld   a,'.'
       out  (c),a
       ld   bc,00300H
       call WrVRAM
       ld   d,080H
       call PrtStr
       db   ': cannot read.',0
       ret

PrtFEM:call PrtStr
       db   'Fatal error! Press <Space>',0
WaitSp:ei                    ; Wait <Space> key press.
       ld   a,(NEWKEY+8)
       bit  0,a
       ret  nz
       jr   WaitSp

LdDCSt:ld   hl,(GRPCGP)      ; Load Default Character Set.
       ld   de,DCSCGD
       call LdImgH
       jp   nz,GLdErr
       ld   hl,(GRPCOL)
       ld   de,DCSClD
       call LdImgH
       jp   nz,GLdErr
       ld   hl,(GRPPAT)
       ld   de,DCSSPD
       call LdImgH
       ret  z
       jp   GLdErr

DCSCGD:db   'YGMPDCSFCG2'    ; Default Character Set C.G.P. file Descriptor.
       dw   256*8
DCSClD:db   'YGMPDCSFCl2'    ; Default Character Set Colour file Descriptor.
       dw   256*8
DCSSPD:db   'YGMPDCSFSPR'    ; Default Char. Set Sprite Pattern file Desc.
       dw   3*32

StDfCS:call LdDCSt           ; Set Default Character Set.
       di
       ld   hl,256*8*1
       call St3PCS
       ld   hl,256*8*2
St3PCS:push hl
       ld   de,(GRPCGP)
       call S3PCS1
       pop  hl
       ld   de,(GRPCOL)
S3PCS1:add  hl,de
       ex   de,hl
       ld   bc,256*8
       jp   LVVIR

DrwBox:di                    ; Draw Box.
       call CkCDGC
       call ClcGPA
       call SVDPIW
       ld   a,(ix)
       out  (c),a
       ld   a,d
       sub  2
       ld   d,a
       call nc,DrwHLn
       ld   a,(ix+1)
       out  (c),a
       ld   a,e
       sub  2
       jr   c,DrwBx2
       jr   z,DrwBx2
       ld   e,a
DrwBx1:ld   bc,32            ; Draw Box (I).
       add  hl,bc
       call SVDPIW
       ld   a,(ix+5)
       out  (c),a
       ld   b,d
       ld   a,' '
       call FVRAML
       ld   a,(ix+5)
       out  (c),a
       dec  e
       jr   nz,DrwBx1
DrwBx2:ld   bc,32            ; Draw Box (II).
       add  hl,bc
       call SVDPIW
       ld   a,(ix+2)
       out  (c),a
       inc  hl
       ld   a,d
       add  a,2
       ld   a,d
       call nc,DrwHLn
       ld   a,(ix+3)
       out  (c),a
       ret

DrwHLn:ret  z                ; Draw Horizontal Line:
       ld   b,a              ; I(IX=Border Pointer;B=Length);m(AF,BC).
       ld   a,(ix+4)
FVRAML:out  (c),a            ; Fill VRAM Loop: I(B=#;C=VDP WrP;A=Dat.);m(F,B).
       nop                   ; Spend time to allow MSX VDP to "breath".
       djnz FVRAML
       ret

CkCDGC:push af               ; Check and Calc. Delta from Graphic Coordinates:
       ld   a,d              ; I(HL=X1Y1;DE=X2Y2); O(HL=minXY;DE=DXDY).
       sub  h
       jp   nc,SetGDX
       ld   a,h
       sub  d
       ld   h,d
SetGDX:inc  a                ; Set Graphic coordinate Delta X (maxX-minX+1).
       ld   d,a
       ld   a,e
       sub  l
       jp   nc,SetGDY
       ld   a,l
       sub  e
       ld   l,e
SetGDY:inc  a                ; Set Graphic coordinate Delta Y (maxY-minY+1).
       ld   e,a
       pop  af
       ret

ClcGPA:push af               ; Calculate Graphic Screen Physical Address:
       push de               ; I(H=X;L=Y); O(HL=VAddress).
       ld   e,h
       ld   h,0
       ld   d,h
       add  hl,hl
       add  hl,hl
       add  hl,hl
       add  hl,hl
       add  hl,hl
       add  hl,de
       ld   de,(GRPNAM)
       add  hl,de
       pop  de
       pop  af
Return:ret

ClrGSc:ld   hl,(GRPNAM)      ; Clear Screen.
       ld   bc,256*3
       ld   a,' '
       jp   FilVRB

ClASpr:ld   hl,(GRPATR)      ; Clear All Sprites.
       ld   de,4
       ld   b,32
       ld   a,0D4H
ClASpL:call WrVRMB           ; ClASpr Loop.
       add  hl,de
       djnz ClASpL
       ret

TryRtB:di                    ; Try to Return to MSX BASIC: this routine
       call StOldH           ; uses undocumented routines. It may not
       ld   a,001H           ; work with all systems, not all times.
       call VDPCtl
       ld   a,003H
       call VDPCtl
       ld   sp,(SaveSP)
       ld   a,(EXPTBL)
       ld   hl,00000H
       call EnSlt
       ld   a,(EXPTBL+1)
       ld   hl,04000H
       call EnSlt
       xor  a                ; Clear MSX-BASIC program header area.
       ld   hl,08000H
       ld   (hl),a
       inc  hl
       ld   (hl),a
       inc  hl
       ld   (hl),a
       ld   hl,0F410H        ; Clear BIOS work area.
       ld   de,0F411H
       ld   bc,0F662H-0F411H
       ld   (hl),a
       ldir
       ld   hl,07F27H        ; Restore BIOS work area default values.
       ld   de,0F380H ; RDPRIM
       ld   bc,00090H
       ldir
       ld   hl,KBUF
       ld   de,KBUF+1
       ld   bc,KBUFSz-1
       ld   (hl),a
       ldir
       ld   hl,BUF
       ld   de,BUF+1
       ld   bc,BUFSiz-1
       ld   (hl),a
       ldir
       ld   (0F87CH),a ; NLONLY
       dec  a
       ld   hl,0F41CH ; CURLIN
       ld   (hl),a
       inc  hl
       ld   (hl),a
       ld   a,','
       ld   (0F55DH),a ; BUFMIN
       ld   a,':'
       ld   (0F41EH),a ; KBFMIN
       call 0003EH ; INIFNK  ; Reset function keys.
       call 0006CH ; INITXT  ; Set text video mode.
       jp   0411FH ; MSX-BASIC main loop re-entry.

StAnmt:ld   hl,(GRPATR)      ; Set Animation.
       call SVDPIW
       ld   de,0F580H
       ld   b,8
       xor  a
StAnm1:out  (c),d            ; Set Animation (I).
       bit  0,(hl)           ; Spend time to allow MSX VDP to "breath".
       out  (c),a
       bit  0,(hl)           ; Spend time to allow MSX VDP to "breath".
       out  (c),e
       bit  0,(hl)           ; Spend time to allow MSX VDP to "breath".
       out  (c),a
       nop                   ; Spend time to allow MSX VDP to "breath".
       djnz StAnm1
       ld   b,3
       ld   de,0D430H
       xor  a
       ld   l,a
StAnm2:out  (c),d            ; Set Animation (II).
       bit  0,(hl)           ; Spend time to allow MSX VDP to "breath".
       out  (c),e
       bit  0,(hl)           ; Spend time to allow MSX VDP to "breath".
       out  (c),a
       bit  0,(hl)           ; Spend time to allow MSX VDP to "breath".
       out  (c),l
       add  a,4
       djnz StAnm2
       ld   a,001H
       ld   (PrgmSt),a
       ret

MainHR:call ChkKey           ; Main Hook Routine.
       ld   a,(SndStR)
       or   a
       call nz,PlySFX
       ld   a,(PrgmSt)
       ld   h,000H
       ld   l,a
       add  hl,hl
       ld   de,AnmTbl
       add  hl,de
       ld   e,(hl)
       inc  hl
       ld   d,(hl)
       ex   de,hl
       jp   (hl)

AnmTbl:dw   Return,UniAnm

ChkKey:ret  nz               ; Check Key.
       ld   a,(NEWKEY+7)
       ld   c,a
       ld   a,(GCtrlR)
       bit  0,c
       jr   nz,DcGCtR
       bit  1,c
       ret  z
       inc  a
       ret  z
StGCtR:ld   (GCtrlR),a       ; Set GCtrlR.
       ret

DcGCtR:or   a                ; Decrement GCtrlR.
       ret  z
       dec  a
       jp   StGCtR

SetSFX:ld   (SndStR),a
       xor  a
       ld   (SndCnt),a
       ret

SFXDTb:dw   SFXDt1,SFXDt2,SFXDt3

SFXDt1:db   040H,00FH
       db   038H,00DH
       db   030H,00BH
       db   028H,009H
       db   020H,007H
       db   018H,005H
       db   010H,003H
       db   008H,001H,0,0FFH

SFXDt2:db   008H,00FH
       db   010H,00DH
       db   018H,00BH
       db   020H,009H
       db   028H,007H
       db   030H,005H
       db   038H,003H
       db   040H,001H,0,0FFH

SFXDt3:db   080H,005H
       db   070H,00DH
       db   060H,00FH
       db   058H,00FH
       db   050H,00FH
       db   048H,00EH
       db   040H,008H
       db   038H,003H,0,0FFH

PlySFX:ld   a,(SndStR)
       or   a
       jr   z,Silenc
       dec  a
       ld   l,a
       ld   h,000H
       add  hl,hl
       ld   de,SFXDTb
       add  hl,de
       ld   e,(hl)
       inc  hl
       ld   d,(hl)
       ld   a,(SndCnt)
       ld   l,a
       ld   h,000H
       add  hl,hl
       add  hl,de
       ld   e,(hl)
       inc  hl
       ld   d,(hl)
       ld   a,d
       inc  a
       jr   z,Silenc
       ld   hl,SndCnt
       inc  (hl)
       ld   l,e
       ld   h,000H
       add  hl,hl
       add  hl,hl
       ld   c,PSGWrP
       ld   a,PAHgPr
       out  (PSGAdr),a
       out  (c),h
       ld   a,PALwPr
       out  (PSGAdr),a
       out  (c),l
       ld   a,PAVol
       out  (PSGAdr),a
       out  (c),d
       ld   a,PChnCt
       out  (PSGAdr),a
       in   a,(PSGRdP)
       and  11000000B
       or   00111110B
       out  (c),a
       ret

Silenc:xor  a
       ld   (SndStR),a
       ld   a,PChnCt
       out  (PSGAdr),a
       in   a,(PSGRdP)
       or   00111111B
       out  (PSGWrP),a
       ret

UniAnm:call WindAn
       call HBlink
       ld   hl,AnmtR1
       ld   a,(hl)
       or   a
       jr   z,UniAn1
       dec  (hl)
       ret  nz
UniAn1:exx
       ld   hl,AnmtR2
       inc  (hl)
       ld   l,(hl)
       ld   h,000H
       ld   de,AnTmTb
       add  hl,de
       ld   a,(hl)
       or   a
       jr   nz,UniAn2
       ld   (AnmtR2),a
       ex   de,hl
       ld   a,(hl)
UniAn2:exx
       ld   (hl),a
       ld   a,7
       ld   (AnmtR3),a
       ret

AnTmTb:db   157,95,117,243,37,183,207,116,69,125,226,160,77,179,99,0

HBlink:ld   a,(TimeCt)
       and  00000001B
       ret  z
       ld   hl,AnmtR3
       ld   a,(hl)
       or   a
       ret  z
       dec  a
       ld   (hl),a
       ld   hl,(GRPATR)
       ld   de,8*4
       add  hl,de
       ld   e,3
       exx
       ld   h,000H
       ld   l,a
       ld   de,HBAnTb
       add  hl,de
       ld   b,3
HBSSpr:ld   a,(hl)
       or   a
       jr   z,HBHidS
       ex   af,af'
       xor  a
       jr   HBPSpr

HBHidS:ex   af,af'
       ld   a,0D4H
HBPSpr:exx
       call WrVRMB
       add  hl,de
       ex   af,af'
       call WrVRMB
       inc  hl
       exx
       inc  hl
       djnz HBSSpr
       ret

HBAnTb:db   000H,000H,000H,004H,005H,007H,00FH,000H,000H

WindAn:ld   a,(TimeCt)
       cp   15
       ret  c
       xor  a
       ld   (TimeCt),a
PrtUni:ld   a,(AnmtR0)
       xor  080H
       ld   (AnmtR0),a
       ld   hl,UniPat        ; Print Unicorn.
       ld   d,a
       ld   a,(VDPWrC)
       ld   c,a
       exx
       ld   hl,(GRPNAM)
       ld   de,32*1+1
       add  hl,de
       ld   de,32
       ld   a,5
PrUniL:ex   af,af'           ; Print Unicorn Loop.
       call StVDPW
       exx
       ld   b,6
       call WrVRML
       exx
       add  hl,de
       ex   af,af'
       dec  a
       jr   nz,PrUniL
       ret

UniPat:db   020H,020H,020H,000H,001H,002H   ; Unicorn graphic Pattern.
       db   020H,020H,003H,004H,005H,006H
       db   020H,007H,008H,009H,00AH,00BH
       db   020H,00CH,00DH,00EH,00FH,010H
       db   011H,012H,013H,014H,020H,020H

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


; Program constants.

BdChr0:db   01AH,01BH,01CH,01DH,01EH,01FH
BdChr1:db   09AH,09BH,09CH,09DH,09EH,09FH


; Program variables.

PrgmSt:db   000H   ; Program State.
LsItPt:ds      2   ; List Item Pointer.
MrkdVA:ds      2   ; Marked VRAM Address.
AnmtR0:db   000H   ; Animation Register 0.
AnmtR1:db   000H   ; Animation Register 1.
AnmtR2:db   000H   ; Animation Register 2.
AnmtR3:db   000H   ; Animation Register 3.
SndStR:ds      1   ; Sound Status Register.
SndCnt:ds      1   ; Sound Counter.


; Music data.

GameDt:db   'Unicorn Dreams Artwork Programs!'   ; Game Data (32).
GmBlPt:dw   GmBlNm-GameDt    ; Game music routine Block list Pointer (2).
StupRP:dw   SetupR-GameDt    ; Set-up Routine Pointer (2).
SilnRP:dw   SilnRt-GameDt    ; Silence Routine Pointer (2).
StMsRP:dw   StMsRt-GameDt    ; Set Music Routine Address (2).
PlayRP:dw   PlayRt-GameDt    ; Play Routine Address (2).
GMPBAd:dw   0C000H           ; Game Music Player Base Address (2).
GMPNam:db   'Yawara  C00'    ; Game Music Player Name (11).
OpenMN:db   000H             ; Opening Music Number (1).
StrtSE:db   000H             ; Start Sound Effect Number (1).
ChATDD:dw   00000H           ; Channel A Tone Duration Datum address (2).
ChBTDD:dw   00000H           ; Channel B Tone Duration Datum address (2).
ChCTDD:dw   00000H           ; Channel C Tone Duration Datum address (2).
BGMSPt:dw   MusicT-GameDt    ; BGM List Start Point (2).
SFXSPt:dw   EffctT-GameDt    ; SFX List Start Point (2).
OpnGFN:db   'Opening Sc2'    ; Opening graphics File Name (11).
OpnGFS:dw   00000H           ; Opening graphics File Size (2).
MnuGFN:db   'MainMenuSc2'    ; Main Menu graphics File Name (11).
MnuGFS:dw   00000H           ; Main Menu graphics File Size (2).
OpnStC:dw   21*32+10         ; Opening String Coordinate (2).
Resorc:db   00000000B        ; Game music routine resources (1).
GCtRSt:db   'Control'        ; General Control Register String (7).

SetupR:or   a                ; Set-up Routine.
       ret  nz
       ld   hl,00000H
       ld   de,00001H
       ld   bc,00000H
       ld   (hl),000H
       ldir
       ret

SilnRt:jp   00000H           ; Silence Routine.

StMsRt:jp   00000H

PlayRt:jp   00000H

GmBlNm:db   'GameName000'    ; Game Block Name.
GmBlSz:dw   04000H           ; Game Block Size.
LoadAd:dw   08000H           ; Game block Loading Address.
       db   0FFH
MusicT:db   000H,'           00          '
       db   0FFH,0FFH
EffctT:db   0FFH,'           FF          '
       db   0FFH,0FFH

Tail:  end
