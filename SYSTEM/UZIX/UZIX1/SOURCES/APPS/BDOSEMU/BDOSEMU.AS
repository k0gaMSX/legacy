;----------------------------------------------------------
;	        CP/M 2.2 emulator for UZIX
;	    a port of EMU.ASZ by Harold F.Bower
;	     Copyright (C)1999 by A&L Software
;----------------------------------------------------------
; It provides a minimal CP/M 2.2 functional subset to allow
; applications to execute in an UZIX process.  It must be
; compiled under Hitech-C to create a "host" UZIX program,
; that will  contain the  CP/M  application.  It  will  be
; "inserted" on the compiled code by the CPM2UZIX program.
; The BDOS code is a port of EMU.ASZ from UZI180 by Harold
; F. Bower,  with  some  parts  enhanced  and/or modified.
;       This file is released under GNU GPL license.
;----------------------------------------------------------
;
; Startup code
; stolen from C0U.AS - UZIX Start Up Code
; change this if C0U.AS is changed!
;
; memory map:
;  0100h startup code (this file)
;  xxyyh CPM application
;  7200h BDOSEMU.C
;
;  xxyyh is the cpmprg label address.
;
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; WARNING!!!!! CPM APPLICATIONS READ COMMAND LINE AT 80h. IN UZIX, 80h
; IS STILL udata AREA, BUT IS PROCESS CHILDREN'S TIMES. IF udata STRUCT
; IS CHANGED, IMPORTANT DATA CAN BE CORRUPTED MOVING COMMAND LINE TO 80h
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

PRGSIZE 	equ	28890	; maximum size of CPM application
buff		equ	0080h	; CP/M default buffer
syscalls	equ	8	; UZIX syscalls entry-point
STDIN		equ	0	; STDIN file number
STDOUT		equ	1	; STDOUT file number
TTY_COOKED	equ	0	; TTY modes: 	cooked
TTY_RAW		equ	1	;		raw
TTY_RAW_UNBUFF	equ	2	;		raw unbuffered

; UZIX syscalls codes

UzixRead	equ	23
UzixOpen	equ	20
UzixClose	equ	6
UzixUnlink	equ	33
UzixLink	equ	17
UzixStat	equ	27
UzixTime	equ	30
UzixSeek	equ	25
UzixSignal	equ	26
UzixExit	equ	11
UzixIoctl	equ	15
UzixWrite	equ	36

	global	small_model
small_model 	equ 	1
	psect	text,class=CODE
	psect	strings,class=CODE
	psect	const,class=CODE
	psect	data,class=DATA
	psect	bss,class=DATA
	psect	_bssend,class=DATA

	global	_main
	global	start

	psect 	text

; At the start, SP points to user stack.
	org	100h
;;; executable header layout
start:	defb	0C3h
	defw	start0

	org	103h
e_flags: defb	80h			; disable system vectors refresh
e_text:  defw	etext
e_data:  defw	edata
e_bss:	 defw	ebss
e_heap:	 defw	0
e_stack: defw	0
e_env:	 defw	__argc
;;; total size of header == 16 bytes

	org	110h
start0: ld	(___stktop),sp
	pop	bc		; drop retaddr
; now there are the next stack structure:
;	+4 envp
;	+2 argv
; sp->	+0 argc
	ld	ix, 0
	add	ix, sp
	ld	l, (ix+4)
	ld	h, (ix+5)
	ld	(_environ),hl
	ld	l, (ix+2)
	ld	h, (ix+3)
	ld	(__argv),hl
	ld	l, (ix+0)
	ld	h, (ix+1)
	ld	(__argc),hl
start1:	
	call	_main		; initialize args
	ld	hl,WBoot	; allow CPM program terminate simply by RET
	push	hl
	push	hl		; just to be sure...
	ld	hl,cpmprg
	ld	de,0100h
	ld	bc,PRGSIZE
	jp	_gocpm

cpmprg:	defm	'MOMBASSA'	; signature for CPM2UZIX.C
	defw	PRGSIZE		; maximum CPM application size
	defs	PRGSIZE-8-2	; space for CPM application

;[]------------------------------------------------------------[]
;|	Start Up Data Area					|
;[]------------------------------------------------------------[]

	psect	data
etext:

; Initialize both FCB entries to blank values

_main:	;; ** CPM default FCBs not available under UZIX **
	;;LD	HL,fcbDat	; Move initial FCB
	;;LD	DE,fcb		;  into
	;;LD	BC,16		;   position
	;;LDIR
	;;LD	HL,fcbDat
	;;LD	C,16		;    init 2nd entry
	;;LDIR

; Catenate argv[] elements into default buffer

	ld	ix,(__argv)	;  Get Ptr to argv[]
	LD	DE,buff+1	; Pt to CP/M Dflt Buffer
	LD	C,0		;  Cnt to 0
	INC	IX		;   Skip Argv[0]
	INC	IX
Cold0:	LD	L,(IX+0)	; Get Ptr to Arg element
	INC	IX
	LD	H,(IX+0)
	INC	IX
	LD	A,H
	OR	L		; End?
	JR	Z,Cold2		; ..exit if Yes
	LD	A,' '		; Add space separator for args
	LD	(DE),A
	INC	DE
	INC	C		;   bump count
Cold1:	LD	A,(HL)
	OR	A		; End of string?
	JR	Z,Cold0		; ..try next if Yes
	CP	'a'		; insure
	JR	C,NoCap		;  it
	CP	'z'+1		;   is
	JR	NC,NoCap	;    UCase
	AND	5FH
NoCap:	LD	(DE),A		; Move a byte
	INC	HL
	INC	DE		;  bump ptrs
	INC	C		;   bump count
	BIT	7,E		; buff overflow?
	JR	NZ,Cold1	; ..get next byte if No
				;..else 0FF->100H, terminate
	DEC	DE		;  (back up for Null-termination)
Cold2:	XOR	A
	LD	(DE),A		;   Null-terminate for safety

	LD	HL,buff		; Pt to count loc'n in buff
	LD	(HL),C		;  save total arg count
	INC	HL		;   advance to 1st char

;; ** CPM default FCBs not available under UZIX **
;;	LD	DE,fcb+1
;;	CALL	FilNm		; Get Name/Typ in 1st FCB
;;	OR	A		;  (set End flag)
;;	LD	DE,fcb+17	;   (prepare)
;;	CALL	NZ,FilNm	;    Get Tame/Typ in 2nd FCB if present

	LD	DE,dir
	LD	B,128
	CALL	ZeroDE		; Clear Directory Buffer

	LD	HL,0
	LD	(0003H),HL	; Clear IOBYTE and Default Drive/User

	JP	__bios		; Go to Cold Start setup

;; ** CPM default FCBs not available under UZIX **
;; Fill FCB Name.Typ fields with any present data
;;
;;FilNm:	LD	A,(HL)		; Get char
;;	INC	HL		;   bump
;;	OR	A		; End of String?
;;	RET	Z
;;	CP	' '		; "Whitespace"?
;;	JR	Z,FilNm0	; ..jump if Yes
;;	CP	TAB
;;	JR	NZ,FilNm1	; ..jump if No
;;FilNm0:	DEC	C		; Count down total length
;;	LD	A,C		;  (prepare)
;;	JR	NZ,FilNm	; ..loop if Not End
;;	RET			;  ..else Exit showing EOL
;;
;;FilNm1:	LD	B,8		; Set length of Name field
;;	PUSH	DE		;   save Ptr to Name[0]
;;	CALL	FilFl0		;  Get Name
;;	POP	DE		;   restore Ptr to Name
;;	OR	A
;;	RET	Z		; ..return if End-of-Line
;;	CP	' '
;;	RET	Z		; ..return if separator
;;	CP	'.'
;;	JR	Z,FilNm2	; ..bypass char skip
;;
;;FilNm3:	LD	A,(HL)
;;	INC	HL
;;	OR	A
;;	RET	Z		; Exit if End of Line
;;	CP	' '
;;	RET	Z		;  or End of Field
;;	CP	'.'
;;	JR	NZ,FilNm3	; ..loop til End or period
;;
;;FilNm2:	LD	A,E
;;	ADD	A,8		; Adjust FCB ptr to type field
;;	LD	E,A
;;	LD	B,3
;;			;..fall thru to get next char..
;; Move bytes from (HL) to (DE) for Count in C, Count in B or Ch in {' ','.',0}
;;
;;FilFld:	LD	A,(HL)		; Get Char
;;	INC	HL		;   bump ptr
;;	OR	A		; End of String?
;;	RET	Z		; ..return if Yes
;;FilFl0:	CP	'.'		; Period?
;;	RET	Z
;;	CP	' '		; Space?
;;	RET	Z
;;	LD	(DE),A		; Else Store byte
;;	INC	DE		;   bump dest ptr
;;	DEC	C		; End of Input String?
;;	LD	A,C		;  (prepare)
;;	RET	Z		; .return End if Yes
;;	DJNZ	FilFld		; ..loop til field counter ends
;;	OR	0FFH		; Return flag
;;	RET
;;
;;fcbDat:	DEFB	0
;;	DEFM	'           '
;;	DEFB	0,0,0,0

;==========================================================
;     Resident Portion of Basic Disk Operating System
;==========================================================
; bdos()
; {
__bdos:	JP	_bdos0
; }

;.....
; BDOS Function Dispatch Table

fcnTbl:	defw	Fcn0		; Warm Boot
	defw	Fcn1		; ConIn
	defw	Fcn2		; ConOut
	defw	Fcn3		; Reader In
	defw	Fcn4		; Punch Out
	defw	Fcn5		; List Output
	defw	Fcn6		; Direct Console IO
	defw	Fcn7		; Get IOBYTE [on MSX: ConIn with echo]
	defw	Fcn8		; Set IOBYTE [on MSX: ConIn without echo]
	defw	Fcn9		; WrBuf
	defw	Fcn10		; RdBuf
	defw	Fcn11		; Get Console Status
	defw	Fcn12		; Return Version #
	defw	Fcn13		; Reset Disk Drive
	defw	Fcn14		; Select Disk
	defw	Fcn15		; Open File
	defw	Fcn16		; Close File
	defw	Fcn17		; Search First Occurance
	defw	Fcn18		; Search Next Occurance
	defw	Fcn19		; Delete File
	defw	Fcn20		; Read File
	defw	Fcn21		; Write File
	defw	Fcn22		; Create File
	defw	Fcn23		; Rename File
	defw	Fcn24		; Return Disk Login Vector
	defw	Fcn25		; Return Current Disk
	defw	Fcn26		; Set DMA
	defw	Fcn27		; Get Allocation Map
	defw	Fcn28		; Write Protect Disk
	defw	Fcn29		; Get R/O Vector Address
	defw	Fcn30		; Set File Attributes
	defw	Fcn31		; Get Disk Parameter Table Address
	defw	Fcn32		; Set/Get User Code
	defw	Fcn33		; Read Random
	defw	Fcn34		; Write Random
	defw	Fcn35		; Compute File Size
	defw	Fcn36		; Set Random Record Field in FCB
	defw	Fcn37		; Reset Multiple Drives
	defw	Fcn38		; Block write random  
	defw	Fcn39		; Block read random
	defw	Fcn40		; ????
	defw	Fcn41		; ????
	defw	Fcn42		; Get date
	defw	Fcn43		; Change date
	defw	Fcn44		; Get hour
TBLSZ	 EQU  $-fcnTbl
MAXFCN	 EQU  TBLSZ/2

;------------------------------------------------
; bdos0()
; {

_bdos0:	LD	(_arg),DE
	ld	(_arg1),HL
	LD	A,C
	LD	(_call),A
	cp	27
	jr	z,_bdosZ
	CP	MAXFCN		; Legal Function?
	LD	A,0FFH		;  Prepare Error code
	LD	L,A
	RET	NC		; ..return if Illegal
	PUSH	IX
	PUSH	IY
	LD	B,0		; Fcn # to Word
	LD	HL,_bdosX
	PUSH	HL		;  (ret Addr to Stack)
	LD	HL,fcnTbl
	ADD	HL,BC
	ADD	HL,BC		;   Pt to Fcn entry in Table
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	JP	(HL)		; "Call" Function #

_bdosX:	POP	IY
	POP	IX
	LD	DE,(_arg)	; Return Orig contents of DE
	LD	A,(_call)
	cp	27
	LD	C,A		; Return Orig contents of C
	LD	A,L
	LD	B,H		; Strict compatibility
	ld	hl,(_arg1)
	OR	A
	RET

_bdosZ:	call	Fcn27
	ret
; }

;------------------------------------------------
;         case 0: _exit();			/* Warm Boot */

Fcn0:	JP	WBoot


;------------------------------------------------
;         case 6: if (arg < 0xfe)		/* Direct Console I/O */
;                     goto conout;
;                 else if (arg == 0xfe)		/* Not available under UZIX */
;                     return (ConSt);
;                 else if (ConSt)       /* 0xff */
;                     goto conout;
;                 else return (0);

Fcn6:	LD	A,E		; _arg in DE
	CP	0FFH		; < 0FF ?
	JR	C,Fcn2		; ..jump to Write if Yes
	ld	hl,TTY_RAW_UNBUFF
	call	IoCtl		; set TTY to raw unbuffered mode
	call	BConIn
	call	Fcn1B		; set TTY to "cooked" mode
	ld	b,a		; B=char, if available
	LD	A,H
	OR	L		; Any char ready?
	RET	Z		; ..exit if Nothing available
	ld	l,b		; else return char
	ld	h,0
	ret

;------------------------------------------------
;         case 1:				/* Console Input */
;         conin:  read (0, &c, 1);
;                 if (c == '\n')
;                     c = '\r';
;                 return (c);

Fcn7:
Fcn1:	ld	hl,TTY_RAW	; set TTY to raw mode
	call	IoCtl
	CALL	BConIn		; Get Char from Bios
Fcn1A:	call	Fcn1B
	push	af
	ld	c,a
	call	BConOu		; Echo
	pop	af
	LD	H,0
	CP	0AH		; \n?
	LD	L,A		;  (prepare for return
	RET	NZ		; ..return if Not
	LD	L,0DH		; Else return CR
	RET
Fcn1B:	push	af
	push	hl
	ld	hl,TTY_COOKED	; set TTY to "cooked" mode
	call	IoCtl
	pop	hl
	pop	af
	ret

;------------------------------------------------
;         case 3:				/* Reader (Aux) Input */
;         conin:  read (0, &c, 1);
;                 if (c == '\n')
;                     c = '\r';
;                 return (c);

Fcn3:	CALL	AuxIn		; Get Char from Bios
	JR	Fcn1A		; ..exit via common code

;------------------------------------------------
;         case 2:				/* Console Output */
;         conout: if (arg == '\r')
;                     return (0);
;                 c = arg;
;                 write (1, &c, 1);
;                 break;

Fcn2:	LD	C,E		; _arg in DE, need char in C
	JP	BConOu

;------------------------------------------------
;         case 4:				/* Punch (Aux) Output */
;         conout: if (arg == '\r')
;                     return (0);
;                 c = arg;
;                 write (1, &c, 1);
;                 break;

Fcn4:	LD	C,E		; _arg in DE, need char in C
	JP	AuxOut

;------------------------------------------------
;         case 5: if (arg == '\r')		/* List (Prntr) Output */
;                     return (0);
;                 c = arg;
;                 write (2, &c, 1);
;                 break;

Fcn5:	LD	A,E		; _arg in DE
	CP	13		; \r?
	RET	Z
	JP	List		; ..go to Bios

;------------------------------------------------
;         case 9: ptr = (char *)arg;		/* Print '$'-term String */
;                 while (*ptr != '$')
;                 {
;                     if (*ptr != '\r')
;                         write (1, ptr, 1);
;                     ++ptr;
;                 }
;                 break;
				; Enter: DE -> String (arg)
Fcn9:	LD	A,(DE)		; Get char
	INC	DE		;   pt to Next
	CP	'$'		; End?
	RET	Z		; ..quit if Yes
	LD	C,A
	PUSH	DE
	CALL	BConOu
	POP	DE
	JR	Fcn9		; ..loop Til done
	
;------------------------------------------------
;         case 10: rdbuf (arg);
;                  break;
; rdbuf (arg)
; char *arg;
; {
;     int nread;

;     nread = read (0, arg+2, *arg & 0xff);

Fcn10:	LD	A,(DE)		; Enter DE -> Buffer
	LD	C,A
	LD	B,0
	PUSH	DE		; (save ptr to buffer beginning)
	PUSH	BC		; cnt (*arg & 0xff)
	INC	DE
	INC	DE
	PUSH	DE		;  arg+2
	LD	C,0
	PUSH	BC		;   0 (stdin)
	LD	HL,UzixRead	;    UZI Read Fcn
	PUSH	HL
	CALL	syscalls	;     Execute!
	ex	de,hl
	POP	BC		; Clear Stack
	POP	BC
	POP	BC
	POP	BC
	POP	DE		; Restore Ptr to Buff

;     --nread;                     /* Forget about newline */

	DEC	HL
	LD	A,L

;     arg[nread+2] = '\0';         /* Remove newline */

	ADD	HL,DE
	INC	HL
	INC	HL
	LD	(HL),0

;     arg[1] = nread;

	INC	DE
	LD	(DE),A
; }
	RET

;------------------------------------------------
;         case 12:				/* Return Version # */

Fcn12:	LD	HL,0022H	; Say this is CP/M 2.2
	ld	(_arg1),hl
	RET

;------------------------------------------------
;         case 8:				/* Console input without echo */

Fcn8:	ld	e,0FFh
	call	Fcn6		; wait for a char
	ld	a,l
	or	a
	jr	z,Fcn8
	ret			; return char

;------------------------------------------------
;         case 11:				/* Get Console Status */
;         case 13:				/* Reset Disk Drive */
;         case 14: break;			/* Select Disk
;         case 25: break;			/* Return Current Disk */
;         case 28: break;			/* Write Protect Disk */
;         case 30: break;			/* Set File Attribytes */
;         case 32: break;			/* Get/Set User Code */


;------------------------------------------------
Fcn11:
Fcn13:
Fcn14:
Fcn25:				; 0 = Drive A
Fcn28:
Fcn30:
Fcn32:				; Return User 0
Fcn37:
Fcn40:
Fcn41:
Fcn43:
;         default: break;
;     }
;     return (0);

Exit0:	LD	HL,0
	RET

;------------------------------------------------
;         case 15: return (openfile (arg));		/* Open File */
; openfile (blk)
; {
;     desc = open (getname (arg), 2);
				; DE -> arg
Fcn15:	CALL	CkSrch		; Insure Search file closed
				; (_arg still in DE)
	CALL	Fcn17		; Does this file exist?
	LD	A,H
	AND	L
	INC	A		; File Not Found (-1)?
	RET	Z		; ..return -1 if File doesn't exist

	LD	DE,(_arg)	; Else
	CALL	GetNam		;  Parse FCB Fn.Ft to String

	LD	DE,2		;  Open for R/W
	CALL	OpenF		;  _open (Path, Mode);

;     arg.recno = 0;

	LD	IY,(_arg)
	LD	(IY+32),0	; Init Current Record #
	ld	(iy+14),128
	ld	(iy+15),0	; Init record size

;     if (desc == -1)
;         return (255);

	RET	Z		; ..return -1 if Yes

;     blk->desc = desc;

OpEx0:	EX	DE,HL
	LD	HL,(_arg)
	LD	BC,16
	ADD	HL,BC
	LD	(HL),E		; Store File Desc in FCB
	INC	HL
	LD	(HL),D

;     return (0);

	JR	Exit0		;  Return Dir Code for Entry
; }

;.....
; Common File Open Routine.  Used by Open and Search First.
; Enter: DE = File Mode
;	 HL = Ptr to Null-terminated Path String
; Exit : A = 0 if Error, HL = -1
;	     File Descriptor, A <> 0 if Ok

OpenF:	PUSH	DE		; Mode
	PUSH	HL		;  Path
	LD	HL,UzixOpen	;   UZI Open Fcn
	PUSH	HL
	call	syscalls	;    _open (Path, Mode);
	ex	de,hl
	POP	BC		; Clean Stack
	POP	BC
	POP	BC

	LD	A,H
	AND	L
	INC	A		; FF -> 0?
	RET			; ..return (HL=-1/A=0 if Err, HL=fd/A<>0 of Ok)

;------------------------------------------------
;         case 16: return (closefile (arg));		/* Close File */

;     if (close (arg->desc) == -1)

Fcn16:	CALL	RWprep		; prepare for file access
				;   (desc (fd) still in DE)
			; Internal entry Point
CloseV:	PUSH	DE
	LD	HL,UzixClose	;  UZI Close Fcn
	PUSH	HL
	CALL	syscalls	;   Execute!
	POP	BC		; Clean Stack
	POP	BC

OpEx1:	LD	A,H		;--- Common Exit Code with Delete ---
	AND	L
	INC	A		; FF->0?
	JR	NZ,Exit0	;  return Ok if No

;         return (255);

	LD	HL,-1
	RET

;     return (0);
; }

;------------------------------------------------
;         case 17:					/* Search First */

Fcn17:	LD	HL,'.'		; Open current directory
	LD	(RName),HL	;  store name in Secondary work string
	LD	DE,0		; Open Read-Only
	LD	HL,RName
	CALL	OpenF		;  _open ('.', 0);
	RET	Z		; HL = -1, A = 0 if Can't Open

	LD	(srchFD),HL	; Else Ok, Save File Descriptor
	LD	(curFil),HL	;   Duplicate for Reading
			;..fall thru to read one entry..
;------------------------------------------------
;         case 18: return (255);			/* Search Next */

Fcn18:	LD	HL,(dmaadr)
	LD	(dmaSav),HL	; Save "real" DMA
Fcn18A:	LD	HL,dir+16
	LD	(dmaadr),HL	;  Set DMA for Dir Op'n
	LD	A,UzixRead	; UZI Read Function
	LD	DE,16		;  Len of Dir entries
	CALL	RdWrt0		;   Read an Entry
	JR	C,Fcn18E	; Error if Carry Set
	OR	A		; Read Ok?
	JR	Z,Fcn18E	; ..Return HL=-1 if EOF
	CALL	ChkDir		; Else Set Dir to CP/M, Check Match
	OR	A
	JR	NZ,Fcn18A	; ..loop if No Match

	LD	A,(_call)
	CP	15		; Is this a File Open internal Call?
	LD	HL,0		;  (set Success, Index 0)
	JR	Z,Fcn18X	; ..exit now if Yes

	LD	HL,dir		; Else
	LD	DE,(dmaSav)	;  Move Dir Buffer to "real" DMA
	LD	BC,37
	LDIR
	LD	L,B		; Use 0 in BC
	LD	H,C		;   to show Index 0 (success)
	JR	Fcn18X		;  ..exit

Fcn18E:	LD	HL,-1
Fcn18X:	LD	DE,(dmaSav)
	LD	(dmaadr),DE	; Restore "real" DMA Addr
	RET

;------------------------------------------------
;         case 19: return (delete (arg));		/* Delete File */

Fcn19:	CALL	CkSrch		; Insure Search file closed

;     if (unlink (getname (arg)) == -1)
				; DE -> arg
	CALL	GetNam		;  Parse to String
	PUSH	HL		; String
	LD	HL,UzixUnlink	;  UZI Unlink Fcn
	PUSH	HL
	call	syscalls	;   Execute!
	ex	de,hl
	POP	BC		; Clean Stack
	POP	BC

;         return (255);
;     return (0);

	JR	OpEx1		; ..go to Common Exit

;------------------------------------------------
;         case 38:					/* Write Block Random */

Fcn38:	ld	a,UzixWrite
	ld	(_389Fcn),a
	jp	Fcn389

;------------------------------------------------
;         case 39:					/* Read Block Random */

Fcn39:	ld	a,UzixRead
	ld	(_389Fcn),a

Fcn389:	call	RWprep		; Prepare file
	call	SkOff		; Position
	ld	hl,(dmaadr)	; Save actual DMA address
	push	hl
	ld	hl,0		; HL=number of records read/written
	ld	iy,(_arg)
	ld	e,(iy+14)
	ld	d,(iy+15)	; DE=record size
	ld	bc,(_arg1)	; BC=number of records to read
Fcn389l:push	bc
	push	de
	push	hl
	ld	a,(_389Fcn)	; A=UZIX read/write function
	call	RdWrt0		; read/write one record
	pop	hl
	pop	de
	pop	bc
	ld	a,1		; error code in case of error
	jr	c,Fcn389X	; error?
	push	hl
	ld	hl,(dmaadr)	; update DMA address
	add	hl,de
	ld	(dmaadr),hl
	ld	iy,(_arg)
	ld	l,(iy+33)
	ld	h,(iy+34)	; HL=low word of record number
	inc	hl		; increase
	ld	(iy+33),l
	ld	(iy+34),h
	ld	a,h
	or	l
	jr	nz,Fcn389I	; carry?
	ld	l,(iy+35)	; so, increase high word
	ld	h,(iy+36)
	inc	hl
	ld	(iy+35),l
	ld	(iy+36),h
Fcn389I:pop	hl
	inc	hl		; increase number of records read/written
	dec	bc		; decrease number of records to read/write
	ld	a,b
	or	c
	jr	nz,Fcn389l	; loop...
	ld	a,0
Fcn389X:ld	(_arg1),hl
	pop	hl
	ld	(dmaadr),hl	; restore original DMA address
	ld	l,a
	ld	h,0
	ret			; return success of fail

;------------------------------------------------
;         case 33:					/* Read File Random */
;	    readrandom (fcb)
;	    {
				; DE -> fcb
Fcn33:	CALL	RWprep		; Prepare File for access (fd to DE)
	CALL	SkBlk		;  Seek to Offset (128-byte rec in Block)

;		_seek (f, (int)(fcb+33) / 128, 3);          /* block seek */

	JR	Fcn20A		; ..Now Read as Normal..

;------------------------------------------------
;         case 20: return (readfile (arg));		/* Read File */
; readfile (arg)
; {
;     nread = read (blk->desc, dmaadr, 128);
				; DE -> arg (FCB)
Fcn20:	CALL	RWprep		; Prepare file for access
Fcn20A:	CALL	BRead		; Read 1 Sector
	JR	C,RWErr		; ..Error if Carry Set

;     arg.recno++;

RWEx:	LD	IY,(_arg)
	INC	(IY+32)		; Bump current Record #

;     if (nread == 0)
;         return (0);

	OR	A		; Good Read?
	JP	Z,Exit0		;   exit w/0 if Yes

;	else return (1)

RWErr:	LD	HL,1		
	RET
;------------------------------------------------
;         case 34:					/* Write File Random */
;	    writerandom (fcb)
;	    {
;	    /* CAUTION the seek calls MUST be in this order */
;	        _seek (f, (int)(fcb+33) % 128, 0);          /* byte  seek */
Fcn34:	CALL	RWprep		; Prepare file for access
	CALL	SkBlk		;  Seek to Offset (128-byte rec in Block)

;		_seek (f, (int)(fcb+33) / 128, 3);          /* block seek */

	JR	Fcn21A		; ..now Write as Normal..

;------------------------------------------------
;         case 21: return (writefile (arg));		/* Write File */
; writefile (arg)
; {
;     if (write (blk->desc, dmaadr, 128) != 128)

				; DE -> arg (FCB)
Fcn21:	CALL	RWprep		; Prepare file for access
Fcn21A:	CALL	BWrit		;   Write

;         return (255);
;     return (0);

	JR	RWEx		; ..exit via Common R/W Code
; }

;------------------------------------------------
;         case 22: return (makefile (arg));		/* Create File */
; makefile (arg)
; {
;     desc = creat (getname (blk), 0666);

Fcn22:	CALL	CkSrch		; Insure Search file closed
	LD	HL,01B6h	; Own/Grp/Oth are Read/Execute
	PUSH	HL		; DE -> arg
	LD	HL,0301h	; Create file flag
	PUSH	HL
	CALL	GetNam		;  This name string
	PUSH	HL
	LD	HL,UzixOpen	;   UZI Open Fcn
	PUSH	HL
	call	syscalls	;    Execute!
	ex	de,hl
	POP	BC		; Clean Stack
	POP	BC
	POP	BC
	pop	bc

;     if (desc == -1)

	LD	A,H
	AND	L
	INC	A		; FF -> 0?

;         return (255);

	RET	Z		; ..return -1 if Yes

;     arg.recno = 0;

	LD	IY,(_arg)
	LD	(IY+32),0	; Init Current Record #
	ld	(iy+14),128	; Init Record size
	ld	(iy+15),0

;     blk->desc = desc;
;     return (0);

	JP	OpEx0		; ..finish up in Open
; }

;------------------------------------------------
;         case 23: return (rename (arg));		/* Rename File */
; rename (arg)
; {
;     RName = getname (arg);

Fcn23:	CALL	CkSrch		; Insure Search file closed
	PUSH	DE		; Save FCB Ptr
	CALL	GetNam		;  parse to UZI String

	LD	HL,FName
	LD	DE,RName
	LD	BC,12
	LDIR			; Copy to Rename string

;     FName = getname (arg+16);

	POP	DE		; DE -> _arg
	LD	HL,16
	ADD	HL,DE		; Offset to New Name
	EX	DE,HL
	CALL	GetNam		;  parse it returning HL -> FName

;     if (link (RName, FName) < 0) {

	PUSH	HL		; New Name
	LD	HL,RName	;  Old Name
	PUSH	HL
	LD	HL,UzixLink	;   UZI link Fcn
	PUSH	HL
	call	syscalls	;    Execute!
	ex	de,hl
	POP	BC		; Clean Stack
	POP	BC
	POP	BC

;         return (-1);

	JP	C,FilErr	; Exit w/Err if Bad
;     }
;     if (unlink (RName) < 0) {

	LD	HL,RName	; Old Name
	PUSH	HL
	LD	HL,UzixUnlink	;  UZI unlink Fcn
	PUSH	HL
	call	syscalls	;    Execute!
	ex	de,hl
	POP	BC		; Clean Stack
	POP	BC
	JP	NC,Exit0	;   exit w/0 if Ok

;         unlink (FName);
				; Else remove the new iNode
	LD	HL,FName	; New Name
	PUSH	HL
	LD	HL,UzixUnlink	;  UZI unlink Fcn
	PUSH	HL
	call	syscalls	;    Execute!
	ex	de,hl
	POP	BC		; Clean Stack
	POP	BC

;         return (-1);

	JP	C,FilErr	;  return -1 if Bad
;     }
;     return (0);

	JP	Exit0		;   else return Ok
	
;     return (-1)

FilErr:	LD	HL,-1
	RET
; }

;------------------------------------------------
;         case 24: return (1);			/* Return Disk Login Vector */

Fcn24:	LD	HL,1
	ld	(_arg1),hl
	RET

;------------------------------------------------
;         case 26: dmaadr = (char *)arg;		/* Set DMA Address */
;                  break;
				; Enter DE = DMA Address
Fcn26:	LD	C,E
	LD	B,D		; Move to Bios Regs
	JP	BSDma		;  Set in Bios & return

;------------------------------------------------
;         case 27: return (-1)			/* Get Allocation Map */

Fcn27:	ld	a,e
	cp	1
	ld	a,255
	ret	nz		; return A=255 if desired drive is not A
	ld	a,1		; sectors per cluster
	ld	bc,512		; bytes per sector
	ld	de,65535	; number of clusters
	ld	hl,1440		; number of free clusters
	ld	iy,0		; FAT? what FAT?
	ld	ix,dpb
	ret

;------------------------------------------------
;         case 29: return (-1)			/* Get R/O Vector Address */

Fcn29:	LD	HL,-1
	RET

;------------------------------------------------
;         case 31: return (&dpb);		/* Get Disk Param Table Addr */

Fcn31:	LD	HL,dpb
	RET
; }

;------------------------------------------------
;         case 35:				/* Return File Size in FCB */
;	    if (_stat (dname, &statbuf) == 0) {

				; DE -> fcb
Fcn35:	CALL	CkSrch		; Insure Search file closed
	CALL	GetNam		;  parse to UZI String
	LD	DE,stBuf
	PUSH	DE		; &statbuf
	PUSH	HL		;  dname
	LD	HL,UzixStat	;   UZI stat Fcn
	PUSH	HL
	call	syscalls	;    Execute!
	ex	de,hl
	POP	BC		; Clean Stk
	POP	BC
	POP	BC
	LD	IY,(_arg)
	LD	A,H
	OR	L		; 0?
	JR	NZ,Fcn35X	; ..jump if Bad

;		(int)fcb+33 = ((512 * statbuf.st_size.o_blkno
;	     		      + statbuf.st_size.o_offset));

	ld	hl,(stBuf+14)
	ld	(iy+33),l
	ld	(iy+34),h
	ld	hl,(stBuf+16)
	ld	(iy+35),l
	ld	(iy+36),h
	
;		return (0);
	ld	hl,0
	RET

;	    else {
;		(int)fcb+33 = 0;

Fcn35X:	LD	(IY+33),0
	LD	(IY+34),0
	ld	(iy+35),l
	ld	(iy+36),h

;		return (-1);

	LD	HL,-1
;	    }
	RET

;------------------------------------------------
;         case 36:			/* Set Random Record Field in FCB */

Fcn36:	LD	HL,32		; Offset to RecNo
	add	hl,de
	LD	A,(HL)		; Fetch
	INC	HL
	LD	(HL),A		;  place in LSB of RR field
	INC	HL
	LD	(HL),0		;   Clear Hi byte of RR
	LD	HL,0		; Return Ok
	RET

;------------------------------------------------
;         case 42:			/* Get actual date */

Fcn42:	call 	Fcn42X		; read date/time
	ld	a,(TimBuf+3)
	and	11111110B
	srl	a
	ld	l,a
	ld	h,0
	ld	de,1980
	add	hl,de		; HL=year
	ld	a,(TimBuf+2)
	and	00011111B
	ld	e,a		; E=day
	ld	a,(TimBuf+3)
	and	00000001B
	sla	a
	sla	a
	sla	a
	ld	b,a		; B=0000m000
	ld	a,(TimBuf+2)
	and	11100000B
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a		; A=00000mmm
	or	b
	ld	d,a
	ld	(_arg),de
	ld	(_arg1),hl
	ret
Fcn42X:	ld	de,TimBuf	; Time/Date buffer
	push	de
	ld	hl,UzixTime	; UZIX Time function
	push	hl
	call	syscalls
	pop	bc
	pop	bc
	ret

;------------------------------------------------
;         case 44:			/* Get actual hour */

Fcn44:	call	Fcn42X		; read date/time
	ld	a,(TimBuf+1)
	and	11111000B
	srl	a
	srl	a
	srl	a
	ld	h,a		; H=hour
	ld	a,(TimBuf)
	and	00011111B
	add	a,a
	ld	d,a		; D=seconds
	ld	e,0		; E=centesimos
	ld	a,(TimBuf+1)
	and	00000111B
	sla	a
	sla	a
	sla	a
	ld	b,a		; B=00mmm000
	ld	a,(TimBuf)
	and	11100000B
	srl	a
	srl	a
	srl	a
	srl	a
	srl	a		; A=00000mmm
	or	b
	ld	l,a
	ld	(_arg),de
	ld	(_arg1),hl
	ret
	
;===========================================================
;		  BDos Support Routines
;===========================================================
; char *
; getname (struct fcb *blk)
; {
;     int j;
;     static char name[16];
;     char *p;

;     p = name;
				; Enter: DE -> FCB drive byte
GetNam:	LD	IX,FName	; Dest to string
	EX	DE,HL
	PUSH	HL		;   (save)
	INC	HL		;  adv to 1st char of FN

;     for (j = 0; j < 8; ++j)
;     {
;         if (!blk->name[j] || blk->name[j] == ' ')
;             break;

	LD	B,8
GetN0:	LD	A,(HL)
	INC	HL
	OR	A
	JR	Z,GetN1
	CP	' '
	JR	Z,GetN1

;         *p++ = chlower (blk->name[j]);

	CALL	ChLower
	LD	(IX+0),A
	INC	IX
	DJNZ	GetN0
;     }

GetN1:	POP	HL
	LD	DE,9
	ADD	HL,DE		; Pt to 1st char of FT
	LD	A,(HL)
	CP	' '		; Any Type?
	JR	Z,GetNX		; ..quit if Not

;     *p++ = '.';

	LD	(IX+0),'.'
	INC	IX

;     for (j = 0; j < 3; ++j)

	LD	B,3

;     {
;         if (!blk->ext[j] || blk->ext[j] == ' ')
;             break;

GetN2:	LD	A,(HL)
	INC	HL
	CP	' '
	JR	Z,GetNX

;         *p++ = chlower (blk->ext[j]);

	CALL	ChLower
	LD	(IX+0),A
	INC	IX
	DJNZ	GetN2

;     }
;     *p = '\0';

GetNX:	LD	(IX+0),0

;     return (name);

	LD	HL,FName
	RET
; }

;.....
; Seek Offset.
;

SkBlk:	ld	ix,0
	ld	hl,0
	ld	de,0
	call	SkOff2
	ld	iy,(_arg)
	ld	bc,128
	jr	SkOff0
	
SkOff:	ld	ix,0
	ld	hl,0
	ld	de,0
	call	SkOff2		; position file to beginning
	ld	iy,(_arg)
	ld	c,(iy+14)
	ld	b,(iy+15)	; BC=record size
SkOff0:	ld	e,(iy+33)	; HL:DE=record number
	ld	d,(iy+34)
	ld	l,(iy+35)
	ld	h,(iy+36)
	ld	a,h		; record 0?
	or	l
	or	d
	or	e
	ret	z		; so return
	ld	a,b
	or	a
	jr	nz,SkOff1
	ld	a,c
	cp	3fh
	jr	nc,SkOff1
	ld	h,0		; record minor than 63: FCB byte 23h not used
SkOff1: push	bc
	push	de
	push	hl		; offset = record number
	ld	ix,1		; 1 Mode (Relative Offset Position)
	call	SkOff2
	pop	hl
	pop	de
	pop	bc
	dec	bc
	ld	a,b
	or	c		; repeat N times (N=record size)
	jr	nz,SkOff1
	ret
SkOff2: push	ix		; IX = mode, HL:DE=offset
	push	hl		; offset msw
	push	de		; offset lsw
	ld	hl,(curFil)	; fd
	PUSH	HL
	LD	HL,UzixSeek	; UZI Seek Fcn
	PUSH	HL
	call	syscalls	; Execute!
	ex	de,hl
	POP	BC
	POP	BC
	POP	BC
	pop	bc
	POP	BC
	ret

;.....
; Perform File Access Preparatory actions; Clear Directory Ops, Close Dir,
; load File Descriptor from storage in FCB to Bios Storage as current file.

RWprep:	CALL	CkSrch		; Insure Search file closed
	LD	HL,16
	ADD	HL,DE		; Offset to file desc in FCB
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	(curFil),DE	;  store for Bios
	RET

;.....
; Convert UZI Directory Entry at dir+16 to CP/M FCB entry at dir, Zero rest.
; Ambiguously compare FCB FN.FT at dir to that passed at arg, returning Zero
; if Match, Non-Zero if mismatch.

ChkDir:	LD	DE,dir
	LD	HL,dir+16+2	; Pt to 1st char of Name
	XOR	A
	LD	(DE),A		; Zero Drive field
	INC	DE		;  Pt to 1st char of FN
	LD	B,8
	CALL	ChkD0		;   Fix Name
	LD	B,3
	CALL	ChkD0		;    & Type
	LD	B,21
	CALL	ZeroDE		;     Clear rest of Dir entry

	LD	DE,(_arg)
	INC	DE		; Pt to 1st char of FN
	LD	A,(DE)
	CP	' '		; Any Name present?
	JR	NZ,ChkFN0	; ..jump if Yes
	LD	HL,8
	ADD	HL,DE		;  Else offset to 1st char of FT
	LD	A,(HL)
	CP	' '		;   Type present?
	LD	A,0FFH		;    (Assume Error)
	RET	Z		;     Return w/Err Flag if no Type either

ChkFN0:	LD	HL,dir+1	; Else Compare name/type fields
	LD	B,11
			; Ambiguous FN.FT compare of (HL) to (DE)
ChkL:	LD	A,(DE)
	CP	'?'		; Accept anything?
	JR	Z,ChkL0		; ..jump if ambiguous
	XOR	(HL)
	AND	7FH		; Match?
	RET	NZ		; .Return Non-Zero if Not
ChkL0:	INC	HL
	INC	DE
	DJNZ	ChkL		; ..loop til Done
	RET			;    return Zero for Match

;.....
; Parse FileSpec addressed by HL into FN.FT Spec addressed by DE.

ChkD0:	LD	A,(HL)		; Get Char
	CP	'a'
	JR	C,ChkD1
	CP	'z'+1
	JR	NC,ChkD1
	AND	5FH		; Convert to Uppercase
ChkD1:	OR	A		; End of String?
	JR	Z,ChkDE		; ..jump if End
	INC	HL		;     (bump Inp Ptr if Not End)
	CP	'.'
	JR	Z,ChkDE		;  ..or Period field separator
	LD	(DE),A		; Store char
	INC	DE		;  bump Dest
	DJNZ	ChkD0		; ..loop til field done
ChkD2:	LD	A,(HL)		; Get Next
	OR	A
	RET	Z		;  Exit at End of string
	INC	HL		;   (adv to next)
	CP	'.'
	RET	Z		;   or field separator
	JR	ChkD2		;  ..loop til end found

ChkDE:	LD	A,' '		; Fill rest w/Spaces
ChkD3:	INC	B
	DEC	B		; More in field?
	RET	Z		; ..exit if Not
	JR	ZeroL		;  ..else stuff spaces til field ends

;.....
; Zero area addressed by DE for B Bytes.  Uses A,B,DE.

ZeroDE:	XOR	A
ZeroL:	LD	(DE),A
	INC	DE
	DJNZ	ZeroL
	RET

;.....
; Close the Directory if we just exitted a SearchF/SearchN sequence

CkSrch:	PUSH	DE		; Save Regs
	PUSH	HL
	LD	DE,(srchFD)	; Get File Desc
	LD	A,D
	OR	E		; Anything open?
	CALL	NZ,CloseV	;  Close file if Yes
	LD	HL,0
	LD	(srchFD),HL	;   Mark as closed
	POP	HL		;    (ignore Errors)
	POP	DE
	RET

;.....
; Convert char in A to Lowercase Ascii

ChLower: CP	'A'
	RET	C
	CP	'Z'+1
	RET	NC
	OR	20H		; Convert to Lcase
	RET

;= = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; Bdos data in Text Segment for treating as single module

_arg:	DEFW	00		; Argument passed to BDOS	(char *arg;)
_arg1:	defw	00		; Argument passed to BDOS
_call:	DEFB	0		; Bdos Function #		(char call;)
FName:	DEFM	'            '	; Storage for FCB "name" String
	DEFB	0
RName:	DEFM	'            '	; 2nd Storage for FCB "name" String (rename)
	DEFB	0
curFil:	DEFW	00		; Storage for File Descriptor of FCB
				;  (set by Bdos, Used by Bios)
stBuf:	DEFS	30		; Buffer for stat() results

;= = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
; BDOS jump table

__bios:	JP	__cold		; 0 Cold Boot
WBoot:	JP	Exit		; 1 Warm Boot
BConSt:	JP	ConSt		; 2 Console Status
BConIn:	JP	ConIn		; 3 Console Input
BConOu:	JP	ConOut		; 4 Console Output
	JP	List		; 5 Printer Output
	JP	AuxOut		; 6 Auxiliary Output (Punch)
	JP	AuxIn		; 7 Auxiliary Input (Reader)
	JP	Home		; 8 Home drive head
	JP	SelDsk		; 9 Select Drive
	JP	SetTrk		; 10 Set Track
	JP	SetSec		; 11 Set Sector
BSDma:	JP	SetDMA		; 12 Set DMA Address
BRead:	JP	Read		; 13 Read Sector
BWrit:	JP	Write		; 14 Write Sector
	JP	ListSt		; 15 Printer Status
	JP	SecTrn		; 16 Translate Sector

;------------------------------------------------
; Cold Entry.  Set up CP/M vectors
; Stack is not changed, since it's already set by kernel

__cold:	LD	A,0C3H
	LD	HL,__bdos
	LD	(0005H),A	;  Set Bdos Vector
	LD	(0006H),HL
	LD	HL,WBoot
	LD	(0000H),A	;   Set Bios Warm Boot Vector
	LD	(0001H),HL
	ret			; return, so startup can load and 
				; execute CPM application
	
;.....
; 1 - Warm Boot Vector (Exits back to UZI)		{exit (0);}

Exit:	
ExtAgn:	LD	HL,0		; Exit Good Status
	PUSH	HL
	ld	hl,UzixExit
	PUSH	HL		;  UZI Fcn (_exit)
	call	syscalls	;   Execute!
	ex	de,hl
	pop	hl		; We should not be here
	pop	hl
	jp	ExtAgn		; Try exiting again

;.....
; 2 - Return Console Input Status (not implemented)

ConSt:	ret

;.....
; 3 - Read Console Input Char			{read (stdin, &char, 1);}

ConIn:	LD	HL,1		; 1 char
	PUSH	HL
	LD	DE,char		;  Addr to put char
	PUSH	DE
	LD	HL,STDIN	;   fd
	PUSH	HL
	LD	L,UzixRead	;    UZI Read Fcn
ChrV0:	PUSH	HL
	call	syscalls	;     Execute
	ex	de,hl
	POP	BC
	POP	BC
	POP	BC
	POP	BC
	LD	A,(char)
	RET

;.....
; 4 - Write Char in C to Console		{write (stdout, &char, 1);}

ConOut:	LD	A,C
	LD	DE,char
	LD	(DE),A		; Stash char
	LD	HL,1		; 1 char
	PUSH	HL
	PUSH	DE		;  Addr to get char
	LD	HL,STDOUT	;   fd
	PUSH	HL
	LD	L,UzixWrite	;    UZI Write Fcn
	JR	ChrV0		;   ..go to common code

;.....

List:				; Bios Fcn 5
AuxOut:				; Bios Fcn 6
AuxIn:				; Bios Fcn 7
Home:				; Bios Fcn 8
SetTrk:				; Bios Fcn 10
SetSec:				; Bios Fcn 11
ListSt:				; Bios Fcn 15
SecTrn:	XOR	A		; Bios Fcn 16.  These are No-Ops
	RET

;.....
; 9 - Select Disk.  Simply return the DPH pointer

SelDsk:	LD	HL,dph		; Return DPH Pointer
	RET

;.....
; 12 - Set DMA Transfer Address

SetDMA:	LD	(dmaadr),BC	; Save Address
	Ret

;.....
; 13 - Read a "Sector" to DMA Address		{read (curFil, dmaadr, 128);}

Read:	LD	A,UzixRead	; Set UZI Read Fcn
	CALL	RdWrt		;  Do the work
	RET	C		; ..exit if Error
	OR	A		; 0 bytes Read?
	JR	Z,XErr		; ..Return Error if Yes (EOF)
	SUB	128		; A full 128 bytes Read?
	RET	Z		;   return Ok if Yes
	LD	DE,(dmaadr)
	ADD	HL,DE		; Else offset to byte after end
	LD	(HL),1AH	;  stuff EOF in case of text
	XOR	A		;   set Ok status
	RET			;    and exit

;.....
; 14 - Write a "Sector" from DMA Address	{write (curFil, dmaadr, 128);}

Write:	LD	A,UzixWrite	; Set UZI Write Fcn
	CALL	RdWrt		;  Do the work
	RET	C		; ..exit if Error
	SUB	128		; Good Write?
	RET	Z		;   return Ok if Yes
	JR	XErr		;  Else Return Error

; Common Read/Write Support Routine

RdWrt:	LD	DE,128		; 1 "Sector" char
			; Entry Point accessed by Search Next (BDos)
RdWrt0:	PUSH	DE
	LD	HL,(dmaadr)	;  from here
	PUSH	HL
	LD	HL,(curFil)	;   to this file
	PUSH	HL
	LD	E,A		;    Position R/W Fcn #
	PUSH	DE
	call	syscalls	;     Execute!
	ex	de,hl
	POP	BC		; Clear Stack
	POP	BC
	POP	BC
	POP	BC
	LD	A,L		; Shuffle possible byte quantity
	RET	NC		; ..return if No Error
XErr:	LD	A,01H		; Else Signal Error (keeping Carry)
	RET

;==========================================================
;		 Bios Support Utilities
;==========================================================
;.....
; Execute ioctl Function on STDIN
; Enter: HL = ioctl Function to execute
; Exit : None
; Uses : AF,BC,DE,HL

IoCtl:	PUSH	HL		; ioctl function
	ld	hl,STDIN	; STDIN
	push	hl
	ld	hl,UzixIoctl	;    UZI ioctl Fcn
	push	hl
	call	syscalls	;     Execute!
	POP	BC		; Clean Stack
	POP	BC
	POP	BC
	RET

;- - - - - - - - - - Data Structures - - - - - - - - -

dph:	DEFW	0		; Ptr to Skew Table
	DEFW	0,0,0		; Scratch Words for BDos use
	DEFW	dir		; Ptr to Directory Buffer
	DEFW	dpb		; Ptr to DPB
	DEFW	0		; Ptr to Disk Checksum Buffer
	DEFW	0		; Ptr to ALV Buffer


dpb:	DEFW	64		; Dummy Disk Parameter Block
	DEFB	4
	DEFB	15
	DEFW	0FFFFH
	DEFW	1023
	DEFB	0FFH,0
	DEFB	0,0,0,0

;----------------------- Data -----------------------

dmaadr:	DEFW	0080H		; Read/Write Transfer Addr   (char *dmaadr;)
dmaSav:	DEFW	0		; Temp storage of current DMA Address
srchFD:	DEFW	0		; File Descriptor for Searches
char:	DEFB	' '		; Byte storage for Conin/Conout
_389Fcn:defb	0		; Function to use for common Fcn38/Fcn39 code
TimBuf:	defw	0		; HHHHHmmm.mmmSSSSS
	defw	0		; YYYYYYYm.mmmDDDDD

dir:	DEFS	128		; Directory Buffer

BIOSIZ	EQU	$-__bios
CPMSIZ	EQU	$-__bdos

;- - - - - - - - - - Data Structures - - - - - - - - -

;	Memory management variables
	global	___heapbase, ___brklvl, ___heaptop, ___stktop

___heapbase:	defw	ebss
___brklvl:	defw	ebss
___heaptop:	defw	ebss
___stktop:	defw	0

	psect	bss
	global	__argc, __argv, _environ, _errno, ___cleanup
edata:	
__argc:		defs	2
__argv:		defs	2
_environ:	defs	2
_errno:		defs	2
___cleanup:	defs	2

	psect	_bssend
ebss:
		; code for moving CPM application to 100h and executing it
_gocpm:		defb	0EDh,0B0h,0C3h,00h,01h

	end	start


