;--------------------------------------
;        SUPER-X ver 1.22 BODY
;	      on 4000H-
;--------------------------------------
; SUPER-X version 1.2 is made by Romi (1994)
; Unoffical SUPER-X version 1.22 is Made By: NYYRIKKI (2011)
;                                                                      
; Changes in version 1.22: (Made By: NYYRIKKI 2011)
;
; - Super-X can now be compiled with Sjasm v.0.42b8 instead of M80/L80
; - Disassembler labeling engine has been redone to support disassembling self modifying code.
; - Disassember does not put "END"-text anymore to output file.
; - Corrected indent in assembler data export
; - Added possibility to export X-BASIC inline ML
; - "I"-command in MULTI-mode now defaults to 20 lines
; - BASIC _CHCPU now supports also Z80 DRAM (MSX tR only)
; - VR command has been removed. Variables can be now always refered with "@". Value can be set also with "="
; - New special variables added: @B (begin), @E (end), @S (size / start)
; - Variables can now be used as parameters to return 16bit address (assembler, CL etc.)
; - Full screen editing works fine now also in main menu
; - Now Super-X comes with updated English documentation
; - Hidden feature: "Repeat previous byte" in DUMP-mode has been documented
; - LD & SV commands now support offset & loading to anywhere in memory
; - LD command now corrects end address automatically if it is too long
; - Global offset has been implemented
; - New keyboard shortcut: ^Z = Set global offset to Zero (ASCII,DUMP,CHAR,DISASM)
; - Check sum type has been removed from statusbar
; - Global offset has been added to status bar
; - Pressing Esc on BASE address setting does not anymore quit to mainmenu (ASCII,DUMP,CHAR,DISASM)
; - Internal help updated
; - On DISASM-mode ^O allows setting global Offset (relative)
; - OF command added for seting global offset (absolute)
; - KL command is now fixed to use new flexible disk routines.
; - Fixed bug in internal CLS routine (insert mode works now properly)
; - RS (RESISTER) is now known as RG (REGISTER)
; - New command "TP" to type file on screen
; - CO command now accepts any number or parameters (1-3)
; - SD command parameter order changed to match other disk commands
; - Math operations OR, XOR and MOD are now represented with "|", "^" and "%" in commands.
;
; Changes in version 1.21: (Made By: NYYRIKKI 2002)
;
; - Corrupted sourcefile repaired.
; - Disassembler labeling bug fixed
; - Z80 DRAM mode support added (CU3)
; - Characters reselected so, that they work well also in non Japanese computers.
; - M (MULTI) Supports now I<lines> parameter (disassemble).
; - SPACE is now allowed between command and parameters.
; - CLS command added.
; - CD command added to change directory
; - FS command remade for DOS2 it now shows also directorys and you can specify full path as parameter.
;   (In Dos2 it does not show number of files found)
; - Japanese Documentation support has been dropped
;
; Changes in version 1.2: (Made by: Romi 1994)
;
; - Added support for BL (BASIC list) command
; - Added Characted mode support
;
; Version 1.1: (Made by: Romi 1993)
;
; Super-X is based on LORD (Made by: Romi 1991)
;
; Please note: Changes after version 1.2 have been done without permission from author as Romi could not be contacted.
;
;--------------------------------------
	;.Z80

	;.ASEG
	
	OUTPUT "SUPER-X.BDY"

	ORG	100H

FCB:	EQU	0F41FH
DMA:	EQU	0F41FH+37
BEEP:   EQU	0C0H

	PHASE	4000H

	DB 0,0,0,0
	DW START
	DB 0,0,0,0
	DB 0,0,0,0,0,0

WIZATB:	DS 2	;SUPER-X ±ÄØËÞ­°Ä ±ÄÞÚ½
TNKBYT:	DS 2	;INDEXÉ ¶½Þ

;--- SUB RAUTINES ---
; PAGE0 É Ù°ÁÝ ÖËÞÀÞ¼
; IN/IX=±ÄÞÚ½
P0CALL:	DI
	PUSH	AF
	PUSH	HL
	IN	A,(0A8H)
	LD	(IOSAV),A
	AND	11111100B
	LD	L,A
	LD	A,(0F341H)
	AND	11B
	OR	L
	OUT	(0A8H),A
	LD	A,(0FFFFH)
	CPL
	LD	(FFSAV),A
	AND	11111100B
	LD	L,A
	LD	A,(0F341H)
	RRCA
	RRCA
	AND	11B
	OR	L
	LD	(0FFFFH),A

	LD	A,(38H)
	LD	(INTSV),A
	LD	A,0C9H
	LD	(38H),A
	EI

	POP	HL
	POP	AF

	LD	(P0CAL1+1),IX
	LD	IX,P0CAL2
	PUSH	IX
P0CAL1:	JP	0000H
P0CAL2:	PUSH	AF
	DI
	LD	A,(INTSV)
	LD	(38H),A
	LD	A,(FFSAV)
	LD	(0FFFFH),A
	LD	A,(IOSAV)
	OUT	(0A8H),A
	EI
	POP	AF
	RET

INTSV:	DS 1	;RAM 0038HÉ Î¿ÞÝÊÞ¼®
IOSAV:	DS 1	;I/O A8HÉ Î¿ÞÝÊÞ¼®
FFSAV:	DS 1	;FFFFHÉ Î¿ÞÝÊÞ¼®

; VDP±¸¾½Îß°Ä É ±À²
VWRTPT:	DS 1
VREDPT:	DS 1

; ±ÄÞÚ½¦ ¾¯Ä¼ VRAM¦ ÖÐÀÞ¾ÙÖ³Æ½Ù
; IN/HL=VRAM±ÄÞÚ½
SETRD:	PUSH	BC
	LD	A,(VREDPT)
	CALL	SETRWS
	OUT	(C),A
	POP	BC
	EI
	RET

; ±ÄÞÚ½¦ ¾¯Ä¼ VRAMÆ ¶·ÀÞ¾ÙÖ³Æ½Ù
; IN/HL=VRAM±ÄÞÚ½
SETWRT:	PUSH	BC
	LD	A,(VWRTPT)
	CALL	SETRWS
	SET	6,A
	OUT	(C),A
	POP	BC
	EI
	RET

;SETRD,SETWRTÉ »ÌÞÙ°ÁÝ
SETRWS:	DI
	INC	A
	LD	C,A
	XOR	A
	OUT	(C),A
	LD	A,45+80H
	OUT	(C),A
	LD	A,H
	RLCA
	RLCA
	AND	3
	OUT	(C),A
	LD	A,14+80H
	OUT	(C),A
	OUT	(C),L
	LD	A,H
	AND	3FH
	RET

;VRAMÆ ×²Ä
;IN/HL=±ÄÞÚ½ A=ÃÞ°À
WRTVRM:	PUSH	BC
	PUSH	AF
	CALL	SETWRT
	LD	A,(VWRTPT)
	LD	C,A
	POP	AF
	OUT	(C),A
	POP	BC
	RET

;VRAMØ°ÄÞ
;I/HL=±ÄÞÚ½ O/A=ÃÞ°À
RDVRM:	PUSH	BC
	CALL	SETRD
	LD	A,(VREDPT)
	LD	C,A
	IN	A,(C)
	POP	BC
	RET

; VRAMÌ¨Ù
; I/HL=±ÄÞÚ½ BC=ÊÞ²Ä½³ A=ÃÞ°À
FILVRM:	PUSH	AF
	CALL	SETWRT
	POP	DE
	PUSH	BC
	POP	HL
	LD	A,(VWRTPT)
	LD	C,A
FILVM1:	OUT	(C),D
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,FILVM1
	RET

; VRAM(HL)=>ÒÓØ(DE) BCbyte ÃÝ¿³
LDIRMV:	CALL	SETRD
	EX	DE,HL
	PUSH	BC
	POP	DE
	LD	A,(VREDPT)
	LD	C,A
LDRMV1:	IN	A,(C)
	LD	(HL),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,LDRMV1
	RET

; ÒÓØ(HL)=>VRAM(DE) BCbyte ÃÝ¿³
LDIRVM:	EX	DE,HL
	CALL	SETWRT
	EX	DE,HL
	PUSH	BC
	POP	DE
	LD	A,(VWRTPT)
	LD	C,A
LDRVM1:	LD	A,(HL)
	OUT	(C),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,LDRVM1
	RET

; A¦ 16¼Ý Ë®³¼Þ(1¹À)
HEXPR:	AND	0FH
	CP	0AH
	JR	NC,HEXPR2
	ADD	A,30H
HEXPR1:	CALL	CHPUT
	RET
HEXPR2:	ADD	A,37H
	JR	HEXPR1

; A¦ 16¼Ý Ë®³¼Þ(2¹À)
DATPR:	PUSH	AF
	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	HEXPR
	POP	AF
	CALL	HEXPR
	POP	AF
	RET

; HL¦ 16¼Ý Ë®³¼Þ
ADRSPR:	LD	A,(CARFG)
	OR	A
	JR	Z,ADRSP1
	LD	A,'1'
	CALL	CHPUT
ADRSP1:	LD	A,H
	CALL	DATPR
	LD	A,L
	CALL	DATPR
	XOR	A
	LD	(CARFG),A
	RET

; A¦ Ó¼ÞÄ¼Ã Ë®³¼Þ
MOJIPR:	PUSH	AF
	CP	32
	JR	NC,MOJPR1
	LD	A,32
MOJPR1:	CP	127
	JR	NZ,MOJPR2
	LD	A,32
MOJPR2:	CALL	CHPUT
	POP	AF
	RET

; HL¦ 2¼Ý Ë®³¼Þ
BINPR:	PUSH	DE
	PUSH	BC
	LD	C,H
	CALL	BINPR1
	LD	C,L
	CALL	BINPR1
	POP	BC
	POP	DE
	RET
BINPR1:	LD	B,8
	LD	D,10000000B
BINPR2:	LD	E,'0'
	LD	A,C
	AND	D
	JR	Z,BINPR3
	INC	E
BINPR3:	LD	A,E
	CALL	CHPUT
	SRL	D
	DJNZ	BINPR2
	RET

; HL¦ 10¼Ý Ë®³¼Þ(+)
DECPR:	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	IX
	LD	IX,SBWORK+6
	CALL	DECSUB
	LD	(IX),'$'
	LD	HL,SBWORK+6
	CALL	NPRINT
	POP	IX
	POP	BC
	POP	DE
	POP	HL
	RET	

; (IX)Æ HL¦ 10¼Ý ÃÞ ²ÚÙ
DECSUB:	LD	IY,SBWORK
	PUSH	IY
	LD	A,5
DECPR1:	PUSH	AF
	ADD	A,A
	LD	C,A
	LD	B,0
	PUSH	HL
	LD	HL,KETA2-2
	ADD	HL,BC
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	POP	HL
	LD	D,0
DECPR2:	OR	A
	SBC	HL,BC
	JR	C,DECPR3
	INC	D
	JR	DECPR2
DECPR3:	ADD	HL,BC
	LD	A,D
	ADD	A,'0'
	LD	(IY),A
	POP	AF
	INC	IY
	DEC	A
	JR	NZ,DECPR1
	LD	(IY),0
	POP	HL
	LD	B,0
DECPR6:	LD	A,(HL)
	OR	A
	JR	Z,DECPR5
	CP	'0'
	JR	Z,DECPR4
	INC	HL
	LD	B,1
DECPR8:	LD	(IX),A
	INC	IX
	JR	DECPR6
DECPR4:	INC	HL
	INC	B
	DEC	B
	JR	Z,DECPR6
	JR	DECPR8
DECPR5:	INC	B
	DEC	B
	RET	NZ
	LD	(IX),'0'
	INC	IX
	RET

; HL¦ 10¼Ý Ë®³¼Þ(+-)
NDECPR:	PUSH	DE
	LD	DE,8000H
	RST	20H
	POP	DE
	JP	C,DECPR
	LD	A,'-'
	CALL	CHPUT
	PUSH	HL
	LD	A,H
	CPL
	LD	H,A
	LD	A,L
	CPL
	LD	L,A
	INC	HL
	CALL	DECPR
	POP	HL
	RET

; 1½Íß°½ Ë®³¼Þ
ONEPUT:	LD	A,' '
	JP	CHPUT

; 1ºÛÝ Ë®³¼Þ
COROPR:	LD	A,':'
	JP	CHPUT

; ¶²·Þ®³(ÌßØÝÀ Å¼)
CRLF:	LD	A,13
	CALL	HICHP
	LD	A,10
	JP	HICHP

; ¶²·Þ®³(ÌßØÝÀ À²µ³)
NCRLF:	LD	A,0DH
	CALL	CHPUT
	LD	A,0AH
	JP	CHPUT

; ¶²·Þ®³(ÌßØÝÀ ÉÐ)
PCRLF:	LD	A,0DH
	CALL	NCHPUT
	LD	A,0AH
	JP	NCHPUT

; HL=HL+DE
PLUS:	ADD	HL,DE
	OR	A
	RET

; HL=HL-DE
NMNAS:	OR	A
	SBC	HL,DE
	OR	A
	RET

; HL=HL and DE
CL_AND:	LD	A,H
	AND	D
	LD	H,A
	LD	A,L
	AND	E
	LD	L,A
	RET

; HL=HL or DE
CL_OR:	LD	A,H
	OR	D
	LD	H,A
	LD	A,L
	OR	E
	LD	L,A
	RET

; HL=HL xor DE
CL_XOR:	LD	A,H
	XOR	D
	LD	H,A
	LD	A,L
	XOR	E
	LD	L,A
	RET

; HL=HL*DE
MULT:	LD	B,H
	LD	C,L
	JP	MLDEBC

; HL=DE*BC	
MLDEBC:	LD	A,16
	LD	HL,0
MLDEB1:	SRL	B
	RR	C
	JR	NC,MLDEB2
	ADD	HL,DE
MLDEB2:	SLA	E
	RL	D
	DEC	A
	JR	NZ,MLDEB1
	RET

; HL=HL/DE O/Cf=´×°
DIV:	LD	A,D
	OR	E
	JR	NZ,DIV1
	SCF
	RET
DIV1:	LD	B,16
	LD	IX,0
DIV4:	ADD	IX,IX
	ADD	HL,HL
	JP	NC,DIV2
	INC	IX
DIV2:	PUSH	HL
	PUSH	IX
	POP	HL
	OR	A
	SBC	HL,DE
	LD	(DIV5+2),HL
	POP	HL
	JR	C,DIV3
	INC	HL
DIV5:	LD	IX,0
DIV3:	DJNZ	DIV4
	OR	A
	RET

; HL=HL mod DE
MOD:	CALL	DIV
	PUSH	IX
	POP	HL
	OR	A
	RET

; HLÄ DE¦ Ë¶¸
; O/Cf:DE>HL  Zf:DE=HL
DCOMPR:	PUSH	HL
	OR	A
	SBC	HL,DE
	POP	HL
	RET

; A¶Þ ºÓ¼Þ=>µµÓ¼Þ
ALPBIG:	CP	61H
	RET	C
	CP	7BH
	RET	NC
	SUB	20H
	RET

; ½³ÁÌßÛ¾¯»
; I/HL=½³ÁÓ¼ÞÚÂ±ÄÞÚ½
; O/DE=½³Á,HL=½³ÁÓ¼ÞÚÂÉ Â·ÞÉ ±ÄÞÚ½
CVAL:	CALL	VAL
	RET	C
	LD	(SBWORK),DE
	LD	A,(HL)
	OR	A
	RET	Z
	CP	','
	RET	Z
	CP	']'
	RET	Z
	CP	')'
	RET	Z
CVAL1:	LD	IX,STR50
	LD	B,8
CVAL2:	CP	(IX)
	JR	Z,CVAL3
	INC	IX
	DJNZ	CVAL2
	SCF
	RET
CVAL3:	LD	A,8
	SUB	B
	EX	DE,HL
	LD	L,A
	LD	H,0
	ADD	HL,HL
	EX	DE,HL
	LD	IX,CALCAD
	ADD	IX,DE
	LD	C,(IX)
	LD	B,(IX+1)
	PUSH	BC
	INC	HL
	CALL	VAL
	POP	IX
	RET	C
	PUSH	HL
	LD	HL,(SBWORK)
	LD	BC,CVAL4
	PUSH	BC
	JP	(IX)
CVAL4:	EX	DE,HL
	POP	HL
	LD	A,(HL)
	OR	A
	RET	Z
	CP	','
	RET	Z
	CP	']'
	RET	Z
	CP	')'
	RET	Z
	LD	(SBWORK),DE
	JR	CVAL1

; CVALÉ »ÌÞ
VAL:	PUSH	HL
	LD	A,(HL)
	CP	"'"
	JP	Z,STRVAL
        CP      "@"
        JP      Z,VARVAL
	CP	'-'
	JR	Z,VAL3
	CP	'+'
	JR	Z,VAL3
	CP	'9'+1
	JR	NC,VAL4
	CP	'0'
	JR	NC,VAL3
VAL4:	POP	HL
	SCF
	RET
VAL3:	LD	DE,STR49
	INC	HL
VAL1:	LD	A,(DE)
	CP	"'"
	JP	Z,STRVAL
	CP	(HL)
	JR	Z,VAL2
	INC	DE
	OR	A
	JR	NZ,VAL1
	JR	VAL3
VAL2:	DEC	HL
	LD	A,(HL)
	POP	HL
	CP	'H'
	JP	Z,HEXVAL
	CP	'B'
	JP	Z,BINVAL
	JP	DECVAL

; CVALÉ »ÌÞ
HEXVAL:	CALL	MNASCK
	PUSH	HL
	LD	B,6
HEXV02:	LD	A,(HL)
	CP	'H'
	JR	Z,HEXV01
	INC	HL
	DJNZ	HEXV02
HEXV03:	POP	HL
HEXV04:	SCF
	RET
HEXV01:	LD	A,6
	SUB	B
	JR	Z,HEXV03
	POP	HL
	LD	B,A
	SUB	4
	JR	NZ,HEXV09
	LD	A,(HL)
	CP	'0'
	JR	C,HEXV04
	CP	'9'+1
	JR	NC,HEXV04
	JR	HEXV08
HEXV09:	DEC	A
	JR	NZ,HEXV08
	LD	A,(HL)
	CP	'0'
	JR	NZ,HEXV04
HEXV08:	LD	IX,KETA1-2
	LD	IY,CKHEX
	CALL	VALSUB
	RET	C
	INC	HL
	JP	MNAS

; CVALÉ »ÌÞ
BINVAL:	CALL	MNASCK
	PUSH	HL
	LD	B,17
BINV02:	LD	A,(HL)
	CP	'B'
	JR	Z,BINV01
	INC	HL
	DJNZ	BINV02
BINV03:	POP	HL
BINV04:	SCF
	RET
BINV01:	LD	A,17
	SUB	B
	JR	Z,BINV03
	POP	HL
	LD	B,A
	LD	IX,KETA3-2
	LD	IY,CKBIN
	CALL	VALSUB
	RET	C
	INC	HL
	JP	MNAS

; CVALÉ »ÌÞ
DECVAL:	CALL	MNASCK
	PUSH	HL
	LD	B,6
DECV02:	LD	A,(HL)
	PUSH	HL
	LD	HL,STR49
DECV08:	CP	(HL)
	JR	Z,DECV01
	INC	(HL)
	DEC	(HL)
	INC	HL
	JR	NZ,DECV08
	POP	HL
	INC	HL
	DJNZ	DECV02
DECV03:	POP	HL
DECV04:	SCF
	RET
DECV01:	POP	HL
	LD	A,6
	SUB	B
	JR	Z,DECV03
	POP	HL
	LD	B,A
	LD	IX,KETA2-2
	LD	IY,CKDEC
	CALL	VALSUB
	RET	C
	JP	MNAS

; CVALÉ »ÌÞ
STRVAL:	POP	HL
	CALL	MNASCK
	LD	D,0
	LD	A,(HL)
	CP	"'"
	SCF
	RET	NZ
	INC	HL
	LD	A,(HL)
	OR	A
	SCF
	RET	Z
	LD	E,A
	INC	HL
	LD	A,(HL)
	OR	A
	SCF
	RET	Z
	CP	"'"
	JR	Z,STRVL1
	LD	D,A
	INC	HL
	LD	A,(HL)
	OR	A
	SCF
	RET	Z
	CP	"'"
	SCF
	RET	NZ
STRVL1:	INC	HL
	JP	MNAS

VARVAL:
        POP	HL
        INC     HL
        LD	A,(HL)
	OR	A
	SCF
	RET     Z
        CALL    VARNAM
	RET     C
	PUSH    HL
	LD      H,0
	LD      L,A

	LD	BC,ADSAV0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        POP     HL
        INC     HL
        RET

; CVALÉ »ÌÞ
MNASCK:	XOR	A
	LD	(MNASFG),A
	LD	A,(HL)
	CP	'+'
	JR	Z,MNSCK1
	CP	'-'
	RET	NZ
	LD	(MNASFG),A
MNSCK1:	INC	HL
	RET

; CVALÉ »ÌÞ
MNAS:	LD	A,(MNASFG)
	OR	A
	RET	Z
	LD	A,D
	CPL
	LD	D,A
	LD	A,E
	CPL
	LD	E,A
	INC	DE
	OR	A
	RET

; CVALÉ »ÌÞ
VALSUB:	LD	DE,0
VALSB4:	LD	A,(HL)
	EXX
	LD	HL,VALSB3
	PUSH	HL
	EXX
	JP	(IY)
VALSB3:	RET	C
	PUSH	HL
	PUSH	BC
	LD	H,0
	LD	L,B
	PUSH	IX
	POP	BC
	ADD	HL,HL
	ADD	HL,BC
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	LD	HL,0
VALSB2:	OR	A
	JR	Z,VALSB1
	ADD	HL,BC
	DEC	A
	JR	VALSB2
VALSB1:	ADD	HL,DE
	EX	DE,HL
	POP	BC
	POP	HL
	INC	HL
	DJNZ	VALSB4
	OR	A
	RET

; BFSAV1Æ Ì§²ÝÄÞÃÞ°À¾¯Ä
;O/(FINDBT)=ÊÞ²Ä½³ (FINDFG)=Ó°ÄÞ Cf=Brk
FDATST:	XOR	A
	LD	(FINDFG),A
	LD	HL,(ADXWK0)
	LD	(WORK),HL
	LD	HL,(SLXWK0)
	LD	(WORK+2),HL
	LD	HL,0
	LD	(SLXWK0),HL
	LD	HL,BUFSV1
	LD	(ADXWK0),HL
FDATS9:	LD	HL,STR53
	CALL	PRINT
	CALL	INLIN
	JR	C,FDATS2
	LD	IX,NALBIG
	CALL	P0CALL
	INC	HL
	LD	A,(HL)
	OR	A
	JR	NZ,FDATS1
FDATS2:	LD	HL,(WORK)
	LD	(ADXWK0),HL
	LD	HL,(WORK+2)
	LD	(SLXWK0),HL
	SCF
	RET
FDATS1:	CP	'*'
	JP	Z,FDATS3
	XOR	A
	LD	(JRFG),A
	CALL	MLCCK
	JR	NC,FDATS8
FDAS10:	LD	HL,STR34
	CALL	PRINT
	JP	FDATS9
FDATS8:	INC	B
	DEC	B
	JR	Z,FDAS10
	LD	A,(JRFG)
	OR	A
	JR	NZ,FDATS2
	LD	A,1
	LD	(FINDFG),A
	LD	A,B
	LD	(FINDBT),A
	LD	HL,(WORK)
	LD	(ADXWK0),HL
	LD	HL,(WORK+2)
	LD	(SLXWK0),HL
	OR	A
	RET
FDATS3:	INC	HL
	LD	B,0
	LD	DE,BUFSV1
FDATS4:	LD	A,(HL)
	LD	(DE),A
	OR	A
	JR	Z,FDATS5
	CP	' '
	JR	Z,FDATS6
	INC	DE
	INC	B
FDATS6:	INC	HL
	JR	FDATS4
FDATS5:	INC	B
	DEC	B
	JP	Z,FDATS2
	LD	A,B
	CP	22
	JR	C,FDATS7
	LD	A,21
FDATS7:	LD	(FINDBT),A
	LD	A,2
	LD	(FINDFG),A
	LD	HL,(WORK)
	LD	(ADXWK0),HL
	LD	HL,(WORK+2)
	LD	(SLXWK0),HL
	OR	A
	RET

; (BUFSV1),(FINDFG),(FINDBT)¦(SRCHZ)Î³º³Æ »°Á
;IN/(ADXWK0) OUT/Cf=end A7=Brk HL=±ÄÞÚ½
SEARCH:	LD	A,(FINDFG)
	DEC	A
	JR	NZ,SEARC1
SEARC7:	LD	A,(FINDBT)
	LD	B,A
	LD	HL,(ADXWK0)
	CALL	SADPUT
	LD	DE,BUFSV1
SEARC2:	PUSH	DE
	PUSH	BC
	CALL	PEEK
	POP	BC
	LD	C,A
	POP	DE
	LD	A,(DE)
	CP	C
	JP	NZ,SEARC3
	INC	HL
	INC	DE
	DJNZ	SEARC2
	LD	HL,(ADXWK0)
	XOR	A
	RET
SEARC3:	CALL	STOP
	JR	NZ,SEAC10
	OR	80H
	RET
SEAC10:	LD	HL,(ADXWK0)
	LD	DE,(ADXWK1)
	RST	20H
	SCF
	RET	Z
	LD	DE,(SRCHZ)
	ADD	HL,DE
	LD	(ADXWK0),HL
	JR	SEARC7
SEARC1:	LD	HL,(ADXWK0)
	CALL	SADPUT
	LD	IX,LWORK
	CALL	ADA
	LD	HL,FINDBT
	LD	A,22
	SUB	(HL)
	LD	B,A
	LD	HL,LWORK+19
SEARC6:	PUSH	BC
	LD	A,(FINDBT)
	LD	B,A
	PUSH	HL
	LD	DE,BUFSV1
SEARC5:	LD	A,(HL)
	CP	' '
	JR	NZ,SEARC8
	INC	HL
	JR	SEARC5
SEARC8:	LD	A,(DE)
	CP	(HL)
	JR	NZ,SEARC4
	INC	HL
	INC	DE
	DJNZ	SEARC5
	POP	HL
	POP	BC
	LD	HL,(ADXWK0)
	XOR	A
	RET
SEARC4:	POP	HL
	INC	HL
	POP	BC
	DJNZ	SEARC6
	CALL	STOP
	JR	NZ,SEAC11
	OR	80H
	RET
SEAC11:	LD	HL,(ADXWK0)
	LD	DE,(ADXWK1)
	RST	20H
	SCF
	RET	Z
	LD	DE,(SRCHZ)
	ADD	HL,DE
	LD	(ADXWK0),HL
	JR	SEARC1

; ¶ÞÒÝ¦Î¿ÞÝ
SCRSAV:	LD	HL,(0F3DCH)
	LD	(XYSAV),HL
	LD	HL,0
	LD	DE,VWORK
	LD	BC,40*21
	JP	LDIRMV

; ¶ÞÒÝ¦ ÓÄÞ½
SCRREM:	LD	HL,(XYSAV)
	LD	(0F3DCH),HL
	LD	HL,VWORK
	LD	DE,0
	LD	BC,40*21
	JP	LDIRVM

; º³¿¸ ²ÁÓ¼Þ Ë®³¼Þ I/A=Ó¼Þº°ÄÞ
HICHP:	CP	32
	JP	C,0A2H
	PUSH	IX
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	CALL	CALADR
HICHP2:	NOP
	CALL	WRTVRM
	LD	HL,0F3DDH
	INC	(HL)
	LD	A,(HL)
	SUB	41
	JR	C,HICHP1
	LD	(HL),1
	CALL	KAIGYO
HICHP1:	POP	AF
	POP	BC
	POP	DE
	POP	HL
	POP	IX
	RET

; º³¿¸ ¶²·Þ®³
; Scroll screen up trough VWORK if needed.
KAIGYO:	LD	HL,0F3DCH
	INC	(HL)
	LD	A,22
	CP	(HL)
	JR	C,KAIGY1
	RET	NZ
KAIGY1:	LD	(HL),21
	LD	BC,40*20
	LD	HL,40
	LD	DE,VWORK
	CALL	LDIRMV
	LD	HL,VWORK+800
	LD	DE,VWORK+801
	LD	(HL),' '
	LD	BC,39
	LDIR
	LD	HL,VWORK
	LD	DE,0
	LD	BC,40*21
	JP	LDIRVM

; ¹²»Ý:O/HL=¶°¿ÙÉ±Ù VRAM±ÄÞÚ½
CALADR:	CALL	LACAL
	LD	B,0
	ADD	HL,BC ;+X
	RET

; ¹²»Ý:O/HL=¶°¿ÙÉ±Ù ·Þ®³É VRAM±ÄÞÚ½
LACAL:	LD	HL,(0F3DCH)
	DEC	H
	DEC	L
	LD	C,H
	LD	H,0
	ADD	HL,HL ;Y*2
	ADD	HL,HL ;Y*4
	ADD	HL,HL ;Y*8
	LD	D,H
	LD	E,L
	ADD	HL,HL ;Y*16
	ADD	HL,HL ;Y*32
	ADD	HL,DE ;Y*32+Y*8=Y*40
	RET

; A¦ ²ÁÓ¼Þ Ë®³¼Þ
CHPUT:	PUSH	BC
	LD	B,A
	LD	A,(CRTOFF)
	OR	A
	LD	A,B
	CALL	Z,HICHP
	POP	BC

; A¦ ²ÁÓ¼Þ ÌßØÝÄ±³Ä
NCHPUT:	PUSH	AF
	LD	A,(PRNFG)
	OR	A
	JR	Z,NCHPT1
	POP	AF
	PUSH	AF
	CALL	0A5H
	JP	C,ERROR
NCHPT1:	POP	AF
	RET

; (HL)¦ ²Á·Þ®³ Ë®³¼Þ(ÌßØÝÄ±³Ä Å¼)
PRINT:	LD	A,(HL)
	CP	'$'
	RET	Z
	CALL	HICHP
	INC	HL
	JR	PRINT

; (HL)¦ ²Á·Þ®³ Ë®³¼Þ(ÌßØÝÄ±³Ä À²µ³)
NPRINT:	LD	A,(HL)
	CP	'$'
	RET	Z
	CALL	CHPUT
	INC	HL
	JR	NPRINT

; ÌßØÝÀ Â¶ÜÅ²
NOTPRN:	XOR	A
	LD	(PRNFG),A
	RET

; CLS
CLS:	;EQU     #C3
        LD	HL,0
	LD	BC,880
	LD      A,020H
	CALL	FILVRM
	CALL	0C9H
	LD	HL,0101H
	LD	(0F3DCH),HL
	LD	HL,0FBB2H
	LD	B,18H
CLS1:	LD	(HL),B
	INC	HL
	DJNZ	CLS1
	RET



VARNAM:       ; C=ERROR
        PUSH DE
        LD      E,4
        CP      'B'
        JR      Z,VARNA1
        INC     E
        CP      'E'
        JR      Z,VARNA1
        INC     E
        CP      'S'
        JR      Z,VARNA1
	SUB	'0'
	JR	C,VARNA1
	CP	4
	CCF
        LD      E,A
VARNA1:
	LD      A,E
	POP DE
	RET

; (HL)<>0 Å× ´×°
BUNMAT:	LD	A,(HL)
	OR	A
	JP	NZ,ERROR
	RET

; C¦ ²Û²ÛÄ Ë®³¼Þ
BSOMEP:	CALL	BSOMP1
	CALL	NCRLF
	JP	BSOMP2
BSOMP1:	LD	HL,STR63
	CALL	NPRINT
	LD	A,C
	CALL	DATPR
	LD	HL,STR64
	CALL	NPRINT
	JP	BINPR1
BSOMP2:	LD	HL,STR65
	CALL	NPRINT
	LD	H,0
	LD	L,C
	CALL	DECPR
	LD	HL,STR66
	CALL	NPRINT
	BIT	7,C
	LD	H,0
	LD	L,C
	JR	Z,BSOMP3
	LD	H,255
BSOMP3:	JP	NDECPR

; DE¦ ²Û²ÛÄ Ë®³¼Þ
SOMEPR:	PUSH	AF
	CALL	SOMPR1
	CALL	NCRLF
	CALL	SOMPR2
	CALL	NCRLF
	POP	AF
	RET
SOMPR1:	LD	HL,STR63
	CALL	NPRINT
	EX	DE,HL
	CALL	ADRSPR
	EX	DE,HL
	LD	HL,STR64
	CALL	NPRINT
	EX	DE,HL
	CALL	BINPR
	EX	DE,HL
	RET
SOMPR2:	LD	HL,STR65
	CALL	NPRINT
	EX	DE,HL
	CALL	DECPR
	EX	DE,HL
	LD	HL,STR66
	CALL	NPRINT
	EX	DE,HL
	CALL	NDECPR
	EX	DE,HL
	RET

; A¦ (IX)Æ 16¼ÝÓ¼ÞÄ¼Ã ²ÚÙ(1¹À)
HEXIN:	AND	0FH
	CP	0AH
	JR	NC,HEXIN2
	ADD	A,30H
HEXIN1:	LD	(IX),A
	INC	IX
	RET
HEXIN2:	ADD	A,37H
	JR	HEXIN1

; A¦ (IX)Æ 16¼ÝÓ¼ÞÄ¼Ã ²ÚÙ(2¹À)
DATIN:	PUSH	AF
	PUSH	AF
	RRCA
	RRCA
	RRCA
	RRCA
	CALL	HEXIN
	POP	AF
	CALL	HEXIN
	POP	AF
	RET

; HL¦ (IX)Æ ²ÚÙ
ADRSIN:	LD	A,H
	CALL	DATIN
	LD	A,L
	JP	DATIN

; A¦ Ó¼ÞÄ¼Ã (IX)Æ ²ÚÙ
MOJIIN:	PUSH	AF
	CP	32
	JR	NC,MOJIN1
	LD	A,32
MOJIN1:	CP	127
	JR	NZ,MOJIN2
	LD	A,32
MOJIN2:	LD	(IX),A
	INC	IX
	POP	AF
	RET

; (IX)É 1×²Ý ¸Ø±
LCLR:	PUSH	IX
	POP	HL
	PUSH	HL
	POP	DE
	INC	DE
	LD	BC,39
	LD	(HL),' '
	LDIR
	RET

;In: HL=Adr E=DATA
;(SFXWK0)=½Û¯Ä¼Ã² Ì×¸Þ (SLXWK0)=½Û¯Ä
POKE:	
        PUSH HL
        LD BC,(OFFSET)
        ADD HL,BC
        CALL POKE8
        POP HL
        RET
POKE8:
        LD	A,(SFXWK0)
	OR	A
	JP	NZ,POKE1
POKE4:	LD	(HL),E
	RET
POKE1:	LD	A,(SLXWK0)
	LD	B,A
	INC	A
	JP	Z,POKE2
	PUSH	HL
	PUSH	DE
	LD	DE,8000H
	ADD	HL,DE
	POP	DE
	POP	HL
	JR	NC,POKE3 ;P0-1
	PUSH	HL
	PUSH	DE
	LD	DE,4000H
	ADD	HL,DE
	POP	DE
	POP	HL
	JR	C,POKE7 ;P3
	LD	A,(0F341H+2)
	CP	B
	JP	Z,POKE4
	PUSH	HL
	LD	HL,3F00H
	ADD	HL,SP
	POP	HL
	JR	C,POKE3
	JP	ERROR4
POKE7:	LD	A,(0F341H+3)
	CP	B
	JR	Z,POKE4
	RET
POKE3:	LD	A,B
	CALL	14H
	EI
	RET
POKE2:	DI
	LD	A,(VWRTPT)
	INC	A
	LD	C,A
	XOR	A
	OUT	(C),A
	LD	A,45+80H
	OUT	(C),A
	LD	A,H
	RLCA
	RLCA
	AND	3
	SET	2,A
	OUT	(C),A
	LD	A,14+80H
	OUT	(C),A
	OUT	(C),L
	LD	A,H
	AND	3FH
	SET	6,A
	OUT	(C),A
	DEC	C
	OUT	(C),E
	EI
	RET

;I/HL=±ÄÞÚ½ (SFXWK0)=½Û¯Ä¼Ã² Ì×¸Þ
; (SLXWK0)=½Û¯Ä
;O/A=DATA
PEEK:
        PUSH HL
        LD BC,(OFFSET)
        ADD HL,BC
        CALL PEEK8
        POP HL
        RET
PEEK8:
        LD	A,(SFXWK0)
	OR	A
	JP	NZ,PEEK1
PEEK4:	LD	A,(HL)
	RET
PEEK1:	LD	A,(SLXWK0)
	LD	B,A
	INC	A
	JP	Z,PEEK2
	PUSH	HL
	LD	DE,8000H
	ADD	HL,DE
	POP	HL
	JR	NC,PEEK3 ;P0-1
	PUSH	HL
	LD	DE,4000H
	ADD	HL,DE
	POP	HL
	JR	C,PEEK7 ;P3
	LD	A,(0F341H+2) ;P2Áª¯¸
	CP	B
	JR	Z,PEEK4
	PUSH	HL
	LD	HL,3F00H
	ADD	HL,SP
	POP	HL
	JR	C,PEEK3
	JP	ERROR4
PEEK7:	LD	A,(0F341H+3)
	CP	B
	JR	Z,PEEK4
	LD	A,255
	RET
PEEK3:	LD	A,B
	CALL	0CH
	EI
	RET
PEEK2:	DI
	LD	A,(VREDPT)
	INC	A
	LD	C,A
	XOR	A
	OUT	(C),A
	LD	A,45+80H
	OUT	(C),A
	LD	A,H
	RLCA
	RLCA
	AND	3
	SET	2,A
	OUT	(C),A
	LD	A,14+80H
	OUT	(C),A
	OUT	(C),L
	LD	A,H
	AND	3FH
	OUT	(C),A
	LD	A,(VREDPT)
	LD	C,A
	IN	A,(C)
	EI
	RET

; Ü°¸´Ø± ¼®·¶
INITWK:	XOR	A
	LD	(FINDFG),A
	LD	(DAPAGE),A
	LD	(SUMTYP),A
	LD	(MAPFG),A
	LD	(0FCA9H),A ;¶°¿ÙË®³¼ÞÅ¼
	LD	(CRTOFF),A
	LD	(BUFSV0),A
	LD	HL,ADSAV0
	LD	DE,ADSAV0+1
	LD	BC,15 +12 +4 ; New variables B,E,S  ,OFFSET ,POFSET
	LD	(HL),A
	LDIR
	LD	HL,RESAVE
	LD	DE,RESAVE+1
	LD	BC,23
	LD	(HL),A
	LDIR
	CALL	VNOTCR
	LD	A,(0FB20H) ;Ï¯ÊßÁª¯¸
	BIT	0,A
	RET	Z
	XOR	A
	LD	DE,0402H
	CALL	0FFCAH
	OR	A
	RET	Z
	LD	(MAPFG),A
	LD	(MAPJP),HL
	LD	DE,1BH
	ADD	HL,DE
	LD	IX,MAPWK
	LD	B,4
INTWK2:	LD	DE,INTWK1
	PUSH	DE
	JP	(HL)
INTWK1:	LD	(IX),A
	LD	DE,6
	ADD	HL,DE
	INC	IX
	DJNZ	INTWK2
	RET

; VRAMÉ°Ä¸Ø±
VNOTCR:	LD	HL,2000H
	LD	BC,0C00H
	LD	A,' '
	JP	FILVRM

; ASK ADDRESS & SLOT
SINLIN:	CALL	156H
	LD	A,(0F3DDH)
	LD	(XSAV),A
	LD	HL,STR37
	CALL	PRINT
SINLN1:	LD	HL,(SLSAV0)
	LD	(SLXWK0),HL
	LD	A,(XSAV)
	INC	A
	LD	E,4
	CALL	ADINL
	BIT	7,A
	SCF
	RET	NZ
	BIT	4,A
	JR	NZ,SINLN1
	BIT	6,A
	SCF
	RET	NZ
	LD	(ADXWK0),HL
	AND	100000B
	RET	NZ
SINLNJ:	LD	A,(XSAV)
	ADD	A,6
	CALL	SLINL
	BIT	7,A
	SCF
	RET	NZ
	BIT	4,A
	JR	NZ,SINLN1
	LD	HL,SLXWK0
	LD	(HL),E
	INC	HL
	LD	(HL),255
	BIT	6,A
	JR	Z,SINLN3
	LD	HL,(SLSAV0)
	LD	(SLXWK0),HL
	JR	SINLN4
SINLN3:	INC	E
	INC	E
	JR	NZ,SINLN4
	LD	HL,SFXWK0
	LD	(HL),0
SINLN4:	OR	A
	RET

; ½Û¯Ä Æ­³Ø®¸
; IN/A=·ÎÝ¶°¿Ù²Á
; OUT/E=½Û¯Ä A=¼Þ®³À²
SLINL:	LD	C,A
SLINL5:	LD	HL,0F3DDH
	LD	(HL),C
	LD	A,'_'
	CALL	HICHP
	INC	(HL)
	CALL	HICHP
	LD	(HL),C
SLINL1:	CALL	9FH
	CALL	ALPBIG
	CP	' '
	JP	Z,SLINL8
	CP	30
	JP	Z,SLINL8
	CP	27
	JR	Z,SLINL6
	CP	8
	JR	Z,SLINL7
	CP	29
	JR	Z,SLINL6
	CP	13
	JR	Z,SLINL9
	CP	'S'
	JR	Z,SLINL2
	CP	'5'
	JR	Z,SLINL2
	CP	'V'
	JR	Z,SLINL3
	CP	'4'
	JR	Z,SLINL3
	CP	'0'
	JR	C,SLINL1
	CP	'3'+1
	JR	NC,SLINL1
	CALL	HICHP
	SUB	'0'
	LD	HL,EXPTBL
	LD	D,0
	LD	E,A
	ADD	HL,DE
	LD	E,A
	BIT	0,(HL)
	LD	A,0
	RET	Z
	LD	HL,0F3DDH
	LD	A,C
	ADD	A,2
	LD	(HL),A
SLINL4:	CALL	9FH
	CP	8
	JR	Z,SLINL5
	CP	29
	JR	Z,SLINL6
	CP	27
	JR	Z,SLINL6
	CP	'0'
	JR	C,SLINL4
	CP	'3'+1
	JR	NC,SLINL4
	CALL	HICHP
	SUB	'0'
	RLCA
	RLCA
	OR	E
	SET	7,A
	LD	E,A
	XOR	A
	RET
SLINL2:	LD	A,'S'
	CALL	HICHP
	LD	E,0FEH
	XOR	A
	RET
SLINL3:	LD	A,'V'
	CALL	HICHP
	LD	E,0FFH
	XOR	A
	RET
SLINL6:	LD	A,80H
	RET
SLINL7:	LD	A,10H
	RET
SLINL8:	LD	E,0
	LD	A,01000000B
	RET
SLINL9:	LD	E,0
	LD	A,01100000B
	RET

; ±ÄÞÚ½(ÃÞ°À) Æ­³Ø®¸
; IN/A=·ÎÝ¶°¿Ù²Á E=¹À½³
; OUT/A=¼Þ®³À² HL=½³Á
ADINL:	LD	(0F3DDH),A
	PUSH	AF
	LD	B,E
	LD	A,'_'
AINL20:	CALL	HICHP
	DJNZ	AINL20
	POP	AF
	LD	C,A ;·ÎÝ ¶°¿Ù²Á
	LD	B,0 ;Ó¼Þ½³
ADINL8:	LD	A,C
	ADD	A,E
	DEC	A
	LD	(0F3DDH),A
ADINL2:	CALL	TENIN
	CALL	ALPBIG
	CP	127	;DEL
	JR	Z,ADINL9
	CP	27	;ESC
	JR	Z,ADINL1
	CP	29	;ËÀÞØ
	JR	Z,ADINL1
	CP	8	;BS
	JR	Z,AINL15
	CP	30	;³´
	JR	Z,AINL11
	CP	' '
	JR	Z,AINL11
	CP	13	;RET
	JR	Z,AINL13
	CP	'0'
	JR	C,ADINL2
	CP	'9'+1
	JR	C,ADINL3
	CP	'A'
	JR	C,ADINL2
	CP	'F'+1
	JR	NC,ADINL2
ADINL3:	PUSH	DE
	LD	HL,ADINWK
	LD	D,0
	LD	E,B
	ADD	HL,DE
	POP	DE
	LD	(HL),A
	INC	B
AINL10:	LD	A,C
	LD	(0F3DDH),A
	LD	A,E
	SUB	B
	LD	D,A
ADINL5:	INC	D
	DEC	D
	JR	Z,ADINL4
	LD	A,'_'
	CALL	HICHP
	DEC	D
	JR	ADINL5
ADINL4:	PUSH	BC
	LD	HL,ADINWK
ADINL7:	INC	B
	DEC	B
	JR	Z,ADINL6
	LD	A,(HL)
	CALL	HICHP
	INC	HL
	DEC	B
	JR	ADINL7
ADINL6:	POP	BC
	LD	A,B
	CP	E
	JR	NZ,ADINL8
AINL12:	CALL	THEX
	XOR	A
	RET
ADINL9:	INC	B
	DEC	B
	JR	Z,ADINL2
AINL30:	DEC	B
	JR	AINL10
ADINL1:	LD	A,10000000B;ºÏÝÄÞÄØ¹¼
	RET
AINL11:	INC	B
	DEC	B
	JR	NZ,AINL12
AINL31:	LD	A,01000000B;·¬Ý¾Ù
	RET
AINL13:	INC	B
	DEC	B
	JR	NZ,AINL14
	LD	A,01100000B;·¬Ý¾Ù_ØÀ°Ý
	RET
AINL14:	CALL	THEX
	LD	A,00100000B;ØÀ°Ý
	RET
AINL15:	INC	B
	DEC	B
	JR	NZ,AINL30
	LD	A,C
	LD	(0F3DDH),A
	LD	B,E
	LD	A,'_'
AINL21:	CALL	HICHP
	DJNZ	AINL21
	LD	A,00010000B;1½Ã¯Ìß ÓÄÞÙ
	RET

XSAV:	DS	2 ;±ÄÞÚ½Æ­³Ø®¸É XÎ¿ÞÝ
ADINWK:	DS	4 ;±ÄÞÚ½Æ­³Ø®¸ Ü°¸

; HEXÓ¼ÞÚÂ=>½³Á ÍÝ¶Ý
;IN/B=¹À½³ (ADINWK)=HEX½³¼Þ OUT/HL=½³Á
THEX:	LD	HL,0
	LD	IX,ADINWK
THEX4:	LD	A,(IX)
	CALL	CKHEX
	RET	C
	PUSH	BC
	LD	D,0
	LD	E,A
THEX3:	DEC	B
	JR	Z,THEX1
	PUSH	BC
	LD	B,4
THEX2:	SLA	E
	RL	D
	DJNZ	THEX2
	POP	BC
	JR	THEX3
THEX1:	POP	BC
	ADD	HL,DE
	INC	IX
	DJNZ	THEX4
	OR	A
	RET

; 16¼Ý ÃÝ·°À²µ³ ²ÁÓ¼ÞÆ­³Ø®¸ O/A=Ó¼Þ
TENIN:	PUSH	BC
	PUSH	HL
	CALL	9FH
TENIN5:	PUSH	AF
	LD	A,9
	CALL	141H
	XOR	255
	JR	NZ,TENIN4
	LD	A,10
	CALL	141H
	XOR	255
	JR	NZ,TENIN4
	POP	AF
	JR	TENIN3
TENIN4:	POP	AF
	LD	B,6
	LD	C,'A'
	LD	HL,TENSTR
TENIN2:	CP	(HL)
	JR	Z,TENIN1
	INC	C
	INC	HL
	DJNZ	TENIN2
TENIN3:	POP	HL
	POP	BC
	RET
TENIN1:	LD	A,C
	JR	TENIN3

; A¶Þ ÃÝ·°Ó¼ÞÚÂÅ× 16¼ÝÆ ÍÝ¶Ý
TENCH:	PUSH	BC
	PUSH	HL
	JR	TENIN5

; AÉ HEXÓ¼Þ¦ ½³ÁÍÝ¶Ý (Cf=ERROR)
CKHEX:	CALL	ALPBIG
	CP	30H
	RET	C
	CP	3AH
	JR	NC,CKHEX2
	SUB	30H
	RET
CKHEX2:	CP	41H
	RET	C
	CP	47H
	CCF
	RET	C
	SUB	37H
	RET

; AÉ ÊÞ²ÅØÓ¼Þ¦ ½³ÁÍÝ¶Ý
CKBIN:	CP	30H
	RET	C
	CP	32H
	CCF
	RET	C
	SUB	30H
	RET

; AÉ ÃÞ¼ÞÏÙÓ¼Þ¦ ½³ÁÍÝ¶Ý
CKDEC:	CP	30H
	RET	C
	CP	3AH
	CCF
	RET	C
	SUB	30H
	RET

; ¼ÌÄ·° Áª¯¸ Z=µ»ÚÃ²Ù
SHIFTC:	LD	A,6
	CALL	141H
	BIT	0,A
	RET

; ½Ä¯Ìß·° ÅÄÞ
; O/Zf=TABor\¶Þµ»ÚÃ²À
; Cf=ESCÅÄÞ,¢Á­³ÀÞÝ£É ·° ¶Þ µ»ÚÃ²Ù
STOP:	CALL	9CH
	JR	NZ,STOP1
	XOR	A ;Cf=0
	INC	A ;Zf=0
	RET
STOP1:	CALL	9FH
	CP	9
	RET	Z
	CP	'\'
	RET	Z
	CP	8
	JR	Z,STOP3
	CP	27
	JR	Z,STOP3
	CP	' '
	JR	Z,STOP2
	CP	13
	JR	Z,STOP2
	CP	30
	JR	Z,STOP2
	XOR	A
	INC	A
	RET
; ·°Æ­³Ø®¸ÏÁ
STOP2:	CALL	9FH
	EX	AF,AF'
	LD	A,(0FCAFH)
	CP	2
	JR	Z,STOP8
	EX	AF,AF'
	CP	22
	JR	NZ,STOP5
	CALL	VCOPY
	JR	STOP2
STOP5:	CP	16
	JR	NZ,STOP6
	CALL	PCOPY
	JR	STOP2
STOP6:	CP	24
	JR	NZ,STOP7
	CALL	CHGPAG
	JR	STOP2
STOP7:	CP	9
	RET	Z
	CP	'\'
	RET	Z
	CP	27
	JR	Z,STOP3
	CP	8
	JR	Z,STOP3
	CP	30
	JR	Z,STOP4
	CP	' '
	JR	Z,STOP4
	CP	13
	JR	NZ,STOP2
STOP4:	XOR	A
	INC	A
	RET
STOP3:	SCF
	RET
STOP8:	EX	AF,AF'
	JR	STOP7

; ²ÁÓ¼ÞÌ¯¸ ¾¯Ä
HOOKST:	LD	HL,0FDA4H ;0FDC2H
	LD	DE,HOOKSV
	LD	BC,5
	PUSH	HL
	PUSH	BC
	LDIR
	POP	BC
	POP	DE
	LD	HL,HOOKDT
	LDIR
	RET

; ²Á·Þ®³ Æ­³Ø®¸
INLIN:	CALL	HOOKST
	CALL	0AEH ; 0B1H
	JP	HOOKOF

; ²ÁÓ¼ÞÌ¯¸ ÓÄÞ½
HOOKOF:	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	LD	HL,HOOKSV
	LD	DE,0FDA4H ;0FDC2H;
	LD	BC,5
	LDIR
	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET

; ²ÁÓ¼Þ Ì¯¸ ÄËÞ»·
; Global keyboard shortcuts in INLIN

HOOK:	CP	12	;CLS
	JR	Z,HOOK4
	CP	16	;CTRL+P
	JR	Z,HOOK1
	CP	22	;CTRL+V
	JR	Z,HOOK2
	CP	24	;SELECT
	JR	Z,HOOK7
	CP	' '	;HELP
	JR	Z,HOOK8
	CALL	TENCH
	EX	AF,AF'
	POP	HL
	POP	AF
	EX	AF,AF'
	PUSH	AF
	PUSH	HL
	JP	HOOKSV
HOOK7:	CALL	CHGPAG
	JR	HOOK3
HOOK2:	CALL	VCOPY
	JR	HOOK3
HOOK1:	CALL	PCOPY
HOOK3:	XOR	A
	JP	HOOKSV
HOOK4:  CALL    CLS
HOOK9:	POP	HL	;Ó¼Þ Ï¯»Â
	POP	AF
	XOR	A
	PUSH	AF
	PUSH	HL
	JP	HOOKSV

HOOK8:	LD	A,6
	CALL	141H
	BIT	2,A
	JP	NZ,HOOKSV
	LD	HL,0
	LD	DE,2000H
	LD	BC,40*20
	CALL	HELP1
	LD	IX,HELPSB
	CALL	P0CALL
HELP2:	CALL	9CH
	JR	Z,HELP2
	CALL	9FH
	LD	HL,2000H
	LD	DE,0
	LD	BC,40*20
	CALL	HELP1
	JP	HOOK9
HELP1:	CALL	RDVRM
	EX	DE,HL
	CALL	WRTVRM
	EX	DE,HL
	INC	DE
	INC	HL
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,HELP1
	RET

; VRAM É°Ä ¶·ºÐ
VCOPY:	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	LD	HL,0
	LD	DE,2800H
	LD	BC,960
VCOPY1:	CALL	4AH
	EX	DE,HL
	CALL	WRTVRM
	EX	DE,HL
	INC	HL
	INC	DE
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,VCOPY1
PCOPY6:	CALL	BEEP
	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET

; Ã·½ÄºËß°
PCOPY:	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	CALL	0A8H
	JR	Z,PCOPY6
	INC	A
	JR	NZ,PCOPY6
	LD	C,24
	LD	HL,0
PCOPY5:	LD	B,40
PCOPY4:	CALL	4AH
	CP	32
	JR	NC,PCOPY7
	LD	D,A
	LD	A,1
	CALL	0A5H
	JR	C,PCOP13
	LD	A,D
	ADD	A,40H
PCOPY7:	CALL	0A5H
	JR	C,PCOP13
	INC	HL
	DJNZ	PCOPY4
	LD	A,10
	CALL	0A5H
	JR	C,PCOP13
	LD	A,13
	CALL	0A5H
	JR	C,PCOP13
	DEC	C
	JR	NZ,PCOPY5
	JR	PCOPY6
PCOP13:	CALL	PCRLF
	JR	PCOPY6

; VRAMÉ°Ä Ë×¸
CHGPAG:	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	CALL	BEEP
	CALL	156H
	LD	BC,0A02H
	CALL	47H
	CALL	9FH
	LD	BC,0002H
	CALL	47H
	JP	PCOPY6

; ´×°Ì¯¸ ¾¯Ä
ERHKST:	LD	A,(0F341H+1)
	LD	(ERHKDT+1),A
	LD	HL,0FFB1H
	LD	DE,ERHKSV
	LD	BC,5
	PUSH	HL
	PUSH	BC
	LDIR
	POP	BC
	POP	DE
	LD	HL,ERHKDT
	LDIR
	RET

; ´×°Ì¯¸ ÓÄÞ½
ERHKOF:	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF
	LD	HL,ERHKSV
	LD	DE,0FFB1H
	LD	BC,5
	LDIR
	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET

; ´×°Ì¯¸ ¼®Ø
ERHOOK:	LD	A,(0F3DDH)
	DEC	A
	CALL	NZ,NCRLF
	LD	HL,ERRDAT
ERHOK2:	LD	A,(HL)
	OR	A
	JP	Z,ERROR
	CP	E
	JR	Z,ERHOK1
	INC	HL
	INC	HL
	INC	HL
	JR	ERHOK2
ERHOK1:	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	CALL	PRINT
	JP	SYSTEM

;Ï¯Êß ¼®·¶
MAPNEW:	LD	A,(MAPFG)
	OR	A
	RET	Z
	LD	HL,(MAPJP)
	LD	DE,18H
	ADD	HL,DE
	LD	IY,MAPWK
	LD	B,4
MAPNW2:	LD	A,(IY)
	LD	IX,MAPNW1
	PUSH	IX
	JP	(HL)
MAPNW1:	INC	IY
	LD	DE,6
	ADD	HL,DE
	DJNZ	MAPNW2
	RET

; # Ë®³¼Þ
SHARPR:	LD	A,'#'
	JP	CHPUT

; Ï¯Êß ¶¸¼Þ®³Î³ Ë®³¼Þ
MAPPR:	LD	HL,STR19
	CALL	NPRINT
	LD	A,(MAPFG)
	OR	A
	JP	Z,MAPPR1
	LD	DE,0401H
	CALL	0FFCAH
	LD	A,'o' ; Was '„'
	CALL	CHPUT
	CALL	NCRLF
	PUSH	HL
	LD	HL,STR20
	CALL	NPRINT
	POP	HL
MAPPR3:	CALL	SHARPR
	LD	A,(HL)
	CALL	NSLTPR
	LD	A,'/'
	CALL	CHPUT
	PUSH	HL
	LD	HL,STR21
	CALL	NPRINT
	POP	HL
	INC	HL
	LD	A,(HL)
	DEC	A
	PUSH	HL
	LD	H,0
	LD	L,A
	CALL	DECPR
	POP	HL
	LD	DE,7
	ADD	HL,DE
	LD	A,(HL)
	OR	A
	JR	Z,MAPPR2
	LD	A,':'
	CALL	CHPUT
	JR	MAPPR3
MAPPR2:	CALL	NCRLF
	LD	HL,(MAPJP)
	LD	DE,1BH
	ADD	HL,DE
	PUSH	HL
	LD	HL,STR22
	CALL	NPRINT
	POP	HL
	LD	B,0
MAPPR5:	LD	A,'P'
	CALL	CHPUT
	LD	A,'0'
	ADD	A,B
	CALL	CHPUT
	LD	A,'='
	CALL	CHPUT
	LD	A,'%'
	CALL	CHPUT
	PUSH	HL
	LD	DE,MAPPR4
	PUSH	DE
	JP	(HL)
MAPPR4:	LD	H,0
	LD	L,A
	CALL	DECPR
	POP	HL
	LD	DE,6
	ADD	HL,DE
	INC	B
	LD	A,B
	CP	4
	JR	NZ,MAPPR6
MAPPR7:	CALL	NCRLF
	RET
MAPPR6:	LD	A,':'
	CALL	CHPUT
	JR	MAPPR5
MAPPR1:	LD	A,'*'
	CALL	CHPUT
	JR	MAPPR7

; AÉ ½Û¯Ä Ë®³¼Þ (ÌßØÝÀ Å¼)
SLOTPR:	LD	B,A
	LD	A,(PRNFG)
	PUSH	AF
	CALL	NOTPRN
	LD	A,B
	CALL	NSLTPR
	POP	AF
	LD	(PRNFG),A
	RET

; AÉ ½Û¯Ä Ë®³¼Þ (ÌßØÝÀ À²µ³)
NSLTPR:	CP	255	;VRAM
	JR	Z,NSLPR1
	CP	254	;SELECT
	JR	Z,NSLPR3
	LD	B,A
	AND	3
	ADD	A,'0'
	CALL	CHPUT
	LD	A,B
	AND	80H
	RET	Z
	LD	A,'-'
	CALL	CHPUT
	LD	A,B
	RRCA
	RRCA
	AND	3
	ADD	A,'0'
NSLPR2:	CALL	CHPUT
	RET
NSLPR1:	PUSH	HL
	LD	HL,STR09
NSLPR4:	CALL	NPRINT
	POP	HL
	RET
NSLPR3:	PUSH	HL
	LD	HL,STR10
	JR	NSLPR4

; PAGE BÉ ½Û¯Ä¦ CÆ ´Ù
PGSLOT:	CALL	138H
	PUSH	BC
PGSLT2:	INC	B
	DEC	B
	JR	Z,PGSLT1
	RRCA
	RRCA
	DEC	B
	JR	PGSLT2
PGSLT1:	AND	3
	LD	C,A
	LD	B,0
	LD	HL,0FCC1H
	ADD	HL,BC
	LD	C,A
	LD	A,(HL)
	AND	80H
	OR	C
	LD	D,A
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	LD	A,(HL)
	POP	BC
	LD	E,B
	INC	B
	DEC	B
	JR	NZ,PGSLT3
	RLCA
	RLCA
	JR	PGSLT4
PGSLT3:	DEC	B
	JR	Z,PGSLT4
	DEC	B
	JR	NZ,PGSLT5
	RRCA
	RRCA
	JR	PGSLT4
PGSLT5:	RRCA
	RRCA
	RRCA
	RRCA
PGSLT4:	AND	0CH
	OR	D
	LD	C,A
	LD	B,E
	RET

; ±ÄÞÚ½#½Û¯Ä Ë®³¼Þ
; IN/HL=±ÄÞÚ½ D=½Û¯ÄÌ×¸Þ E=½Û¯Ä
ADPRSL:	CALL	ADRSPR
	INC	D
	DEC	D
	JR	NZ,ADPRS1
	LD	E,254
ADPRS1:	LD	A,'#'
	CALL	CHPUT
	LD	A,E
	CALL	NSLTPR
	RET

; ÌßÛÝÌßÄ Ë®³¼Þ
PROMPT:	LD	A,(0F3DDH)
	DEC	A
	CALL	NZ,CRLF
	LD	A,7
	CALL	0A2H
	IN	A,(0FEH)
	PUSH	AF
	LD	C,19H
	CALL	0F37DH
	ADD	A,'A'
	CALL	HICHP
	POP	AF
	OUT	(0FEH),A
	LD	A,'>'
	JP	HICHP

; SET BASE ADDRESS
;O/HL=(ADXWK0)=±ÄÞÚ½
; (SLXWK0)=½Û¯Ä,(SFXWK0)=½Û¯Ä¼Ã²Ì×¸Þ
INADRS:	LD	HL,1*256+21
	LD	(0F3DCH),HL
	LD	HL,STR36
	CALL	PRINT
	LD      HL,(BASE)
	PUSH    HL
        CALL	SINLIN
	LD	HL,(ADXWK0)
	POP     DE
	RET     NC
        EX      DE,HL
        LD      (ADXWK0),HL
	RET

; Ì§²Ù ¸Û°½Þ
CLOSE:	XOR	A
	LD	(OPNFG),A
	LD	DE,FCB
	LD	C,10H
	JP	SYSCAL

; ¼½ÃÑ º°Ù
SYSCAL:	CALL	0F37DH
	OR	A
	RET	Z
	JP	ERROR

; ADXWK0,SLXWK0=>ADSAV0,SLSAV0
ADRSAV:	LD	HL,(SLXWK0)
	LD	(SLSAV0),HL
	LD	HL,(ADXWK0)
	LD	(ADSAV0),HL
	RET

; VWORK¦ ¶ÞÒÝÆ Ë®³¼Þ
VWKPUT:	LD	HL,VWORK
	LD	DE,0
	LD	BC,40*20
	JP	LDIRVM

; ²Á·Þ®³ ·¬×¹²¼·ÃÞ(IX)Æ ²ÚÙ
; IN/HL=Adr,(SLXWK)=½Û¯Ä,(SFXWK0)=Ì×¸Þ
; O/HL,IXÄÓ,º³½Ý»ÚÙ
AC_W:	PUSH	HL
	LD	DE,(ADXWK1)
	RST	20H
	JR	NZ,AC_W4
	LD	A,255
	LD	(SAMEFG),A
AC_W4:	PUSH	HL
	CALL	LCLR
	POP	HL
	CALL	ADRSIN
	LD	(IX),' '
	INC	IX
	CALL	PEEK
	PUSH	AF
	CALL	AC_W2
	LD	DE,16
	ADD	HL,DE
	CALL	PEEK
	PUSH	AF
	CALL	AC_W2
	LD	(IX),':'
	INC	IX
	POP	BC
	POP	AF
	CALL	DATIN
	LD	(IX),':'
	INC	IX
	LD	A,B
	CALL	DATIN
	POP	HL
	INC	HL
	RET
AC_W2:	LD	E,A
	LD	B,8
AC_W1:	LD	A,'-' ; WAS '¥'
	RL	E
	JR	NC,AC_W3
	LD	A,'O'; WAS 'Û'
AC_W3:	LD	(IX),A
	INC	IX
	DJNZ	AC_W1
	RET

; ²Á·Þ®³ ÀÞÝÌß¹²¼·ÃÞ(IX)Æ ²ÚÙ
; IN/HL=Adr,(SLXWK)=½Û¯Ä,(SFXWK0)=Ì×¸Þ
; O/HL,IXÄÓ,º³¼Ý»ÚÙ
AD_W:	PUSH	HL
	LD	C,0
	LD	A,(SUMTYP)
	OR	A
	JR	Z,AD_W1
	XOR	A
	ADD	A,H
	ADD	A,L
AD_W1:	LD	C,A
	CALL	ADRSIN
	LD	B,8
AD_W2:	LD	(IX),' '
	INC	IX
	PUSH	BC
	CALL	PEEK
	POP	BC
	CALL	DATIN
	ADD	A,C
	LD	C,A
	INC	HL
	DJNZ	AD_W2
	LD	(IX),':'
	INC	IX
	LD	A,C
	CALL	DATIN
	LD	(IX),':'
	INC	IX
	POP	HL
	LD	B,8
	JP	AA_W1

; ²Á·Þ®³ ±½·°¹²¼·ÃÞ (IX)Æ ²ÚÙ
; IN/B=ÊÞ²Ä½³
; HL=Adr,(SLXWK)=½Û¯Ä,(SFXWK0)=Ì×¸Þ
; O/HL,IXÄÓ,º³¼Ý»ÚÙ
AA_W:	CALL	ADRSIN
	LD	(IX),'"'
	INC	IX
AA_W1:	PUSH	BC
	LD	DE,(ADXWK1)
	RST	20H
	JR	NZ,AA_W2
	LD	A,0FFH
	LD	(SAMEFG),A
AA_W2:	CALL	PEEK
	CALL	MOJIIN
	INC	HL
	POP	BC
	DJNZ	AA_W1
	RET

; ²Á·Þ®³ ÃÞ¨½±¾ÝÌÞÙ¦ (IX)Æ ²ÚÙ
; IN/HL=Adr,(SLXWK)=½Û¯Ä,(SFXWK0)=Ì×¸Þ
; O/HL,IXÄÓ,º³¼Ý»ÚÙ
ADA:	LD	(DAWORK),IX
	PUSH	HL
	CALL	SBWKRD
	CALL	LCLR
	POP	HL
	LD	(IXBRG),IX
	LD	IX,ADIP0
	CALL	P0CALL
	LD	IX,(DAWORK)
	LD	DE,40
	ADD	IX,DE
	RET

; (HL)¶× 4byte SBWORKÆ Ø°ÄÞ
SBWKRD:	LD	DE,SBWORK
	LD	B,4
SBWKR1:	PUSH	DE
	PUSH	BC
	CALL	PEEK
	POP	BC
	POP	DE
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	SBWKR1
	INC	DE
	XOR	A
	LD	(DE),A
	INC	DE
	INC	DE
	LD	(DE),A
	RET

; 1×²Ý ·¬×
ACHA:	LD	IX,LWORK
	CALL	AC_W
	JR	ADUMP3

; ²Á·Þ®³ ÀÞÝÌßØ½Ä
; IN/HL=Adr,(SLXWK)=½Û¯Ä,(SFXWK0)=Ì×¸Þ
ADUMP:	LD	IX,LWORK
	CALL	AD_W
ADUMP3:	PUSH	HL
	LD	A,(CRTOFF)
	OR	A
	JR	NZ,ADUMP6
	LD	A,1
	LD	(0F3DDH),A
	CALL	CALADR
	EX	DE,HL
	LD	HL,LWORK
	LD	BC,40
	CALL	LDIRVM
	CALL	KAIGYO
	LD	A,(PRNFG)
	OR	A
	JR	Z,ADUMP1
ADUMP6:	LD	HL,LWORK
	LD	B,40
ADUMP2:	LD	A,(HL)
	OR	A
	JR	Z,ADUMP4
	CALL	0A5H
	JP	C,ERROR
	INC	HL
	DJNZ	ADUMP2
ADUMP4:	CALL	PCRLF
ADUMP1:	LD	A,(OPNFG)
	OR	A
	JR	Z,ADUMP5
	LD	HL,LWORK
	CALL	LOUT
ADUMP5:	POP	HL
	RET

; ²Á·Þ®³ ±½·°ÀÞÝÌß
; IN/HL=Adr,(SLXWK)=½Û¯Ä,(SFXWK0)=Ì×¸Þ
ASDMP:	LD	IX,LWORK
	CALL	AA_W
	CALL	ASDMP1
	JR	ADUMP3
ASDMP1:	LD	(IX),' '
	INC	IX
	LD	(IX),' '
	INC	IX
	LD	(IX),' '
	INC	IX
	RET

; ²Á·Þ®³ ÃÞ¨½±¾ÝÌÞÙ
; IN/HL=Adr,(SLXWK)=½Û¯Ä,(SFXWK0)=Ì×¸Þ
ADISAS:	LD	IX,LWORK
	CALL	ADA
	JP	ADUMP3

; ºÏÝÄÞ¼®ØÁ­³±ÄÞÚ½=HL Ë®³¼Þ
SADPUT:	PUSH	HL
	PUSH	BC
	PUSH	DE
	LD	IX,LWORK
	CALL	ADRSIN
	LD	HL,LWORK
	LD	DE,40*23+7
	LD	BC,4
	CALL	LDIRVM
	POP	DE
	POP	BC
	POP	HL
	RET

; ¸Þ×Ì¨¯¸³²ÝÄÞ° I/HL=Adr
GRAWIN:	LD	B,32
	LD	DE,0FC18H
GRAWN3:	PUSH	BC
	PUSH	DE
	CALL	PEEK
	POP	DE
	POP	BC
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	GRAWN3
	LD	HL,(0FC18H)
	PUSH	HL
	CALL	GRASUB
	LD	HL,TANKWK
	LD	DE,800H+8
	LD	BC,48
	CALL	LDIRVM
	POP	HL
	LD	A,H
	LD	H,L
	LD	L,A
	LD	IX,JIS
	CALL	P0CALL
	CALL	GR1SUB
	LD	HL,TANKWK
	LD	DE,7*8+800H
	LD	BC,48
	CALL	LDIRVM
	LD	HL,GRASTR
	LD	DE,40*22+33
	LD	BC,7
	CALL	LDIRVM
	LD	HL,GRASTR+7
	LD	DE,40*23+33
	LD	BC,7
	JP	LDIRVM

GRASTR:	DB 25,1,3,5,7,8,9
	DB 22,2,4,6,10,11,12

GR1SUB:	LD	IX,TANKWK
	LD	HL,0FC18H
	LD	B,2
G1ASB3:	PUSH	BC
	LD	B,8
G1ASB1:	LD	A,(HL)
	INC	HL
	LD	C,0
	SRL	A
	RR	C
	SRL	A
	RR	C
	RLCA
	RLCA
	LD	(IX),A
	LD	(IX+8),C
	INC	IX
	DJNZ	G1ASB1
	LD	B,8
G1ASB2:	LD	A,(HL)
	INC	HL
	PUSH	AF
	RRCA
	RRCA
	AND	00111100B
	OR	(IX)
	LD	(IX),A
	POP	AF
	AND	15
	RRCA
	RRCA
	RRCA
	RRCA
	AND	0F0H
	LD	(IX+8),A
	INC	IX
	DJNZ	G1ASB2
	LD	DE,8
	ADD	IX,DE
	POP	BC
	DJNZ	G1ASB3
	RET

GRASUB:	LD	IX,TANKWK
	LD	B,16
	LD	HL,0FC18H
GRASB1:	LD	A,(HL)
	INC	HL
	LD	C,0
	SRL	A
	RR	C
	SRL	A
	RR	C
	RLCA
	RLCA
	LD	(IX),A
	LD	(IX+16),C
	INC	IX
	DJNZ	GRASB1
	LD	B,16
GRASB2:	LD	A,(HL)
	INC	HL
	PUSH	AF
	RRCA
	RRCA
	AND	00111100B
	OR	(IX)
	LD	(IX),A
	POP	AF
	AND	15
	RRCA
	RRCA
	RRCA
	RRCA
	AND	0F0H
	LD	(IX+16),A
	INC	IX
	DJNZ	GRASB2
	RET

; (HL)É Ó¼ÞÚÂ¦ ÃÞ¨½¸Æ ±³Ä
LOUT:	LD	B,40
LOUT3:	LD	DE,DMA
	LD	C,0
LOUT1:	LD	A,(HL)
	OR	A
	JR	Z,LOUT2
	LD	(DE),A
	INC	HL
	INC	DE
	INC	C
	DJNZ	LOUT1
LOUT2:	EX	DE,HL
	LD	(HL),13
	INC	HL
	LD	(HL),10
	INC	C
	INC	C
	LD	L,C
	LD	H,0
	LD	DE,FCB
	LD	C,26H
	JP	SYSCAL

; (ADXWK0)Æ E¦ ×²Ä ÉÁ INC
INCPOK:	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	HL,(ADXWK0)
	CALL	POKE
	INC	HL
	LD	(ADXWK0),HL
	POP	BC
	POP	DE
	POP	HL
	RET

; MULTI input routine
; (HL)É Ó¼ÞÚÂ¦ ÏÙÁ×²Ã¨Ý¸Þ
; OUT/Cf=err B=¶·ºÝÀÞ ÊÞ²Ä½³
MLCCK:	LD	B,0
	LD	A,(HL)
	CP	'"'
	JR	Z,MLCCK1
	CP	'.'
	JR	Z,MLCCK2
	CP	':'
	JR	Z,MLCCK3
	CP	';'
	JR	Z,MLCCK4
	CP	'['
	JR	Z,MLCCK5
	LD	IX,ASM
	CALL	P0CALL
	RET	C
	LD	HL,ASMWK1
	LD	C,(HL)
	LD	B,C
ASMPK1:	INC	HL
	LD	E,(HL)
	CALL	INCPOK
	DJNZ	ASMPK1
	LD	B,C
	OR	A
	RET
MLCCK1:	INC	HL
	LD	A,(HL)
	OR	A
	RET	Z
	LD	E,A
	CALL	INCPOK
	INC	B
	JR	MLCCK1
MLCCK2:	INC	HL
	LD	A,(HL)
	OR	A
	RET	Z
	PUSH	BC
	CALL	GTBYTE
	POP	BC
	RET	C
	CALL	INCPOK
	INC	B
	LD	A,(HL)
	OR	A
	RET	Z
	JR	MLCCK2
MLCCK3:	INC	HL
	LD	A,(HL)
	OR	A
	RET	Z
	PUSH	BC
	CALL	ADSUB
	POP	BC
	RET	C
	CALL	INCPOK
	INC	B
	LD	E,D
	CALL	INCPOK
	INC	B
	LD	A,(HL)
	OR	A
	RET	Z
	JR	MLCCK3
MLCCK4:	INC	HL
	LD	A,(HL)
	OR	A
	RET	Z
	PUSH	BC
	CALL	CVAL
	POP	BC
	RET	C
	CALL	INCPOK
	INC	B
	LD	E,D
	CALL	INCPOK
	INC	B
	LD	A,(HL)
	OR	A
	RET	Z
	JR	MLCCK4
MLCCK5:	INC	HL
	LD	A,(HL)
	OR	A
	RET	Z
	PUSH	BC
	CALL	CVAL
	POP	BC
	RET	C
	CALL	INCPOK
	INC	B
	LD	A,(HL)
	OR	A
	RET	Z
	JR	MLCCK5

; (HL)É ±ÄÞÚ½Ó¼ÞÚÂ¦ ±ÄÞÚ½Ä¼Ã DEÆ²ÚÙ
; O/DE=Adr HL=º³¼Ý»ÚÙ Cf=Err
ADSUB:	PUSH	HL
	LD	B,5
ADSB02:	LD	A,(HL)
	OR	A
	JR	Z,ADSB01
	CP	','
	JR	Z,ADSB01
	CP	'#'
	JR	Z,ADSB01
	CP	' '
	JR	Z,ADSB01
	CP	')'
	JR	Z,ADSB01
	INC	HL
	DJNZ	ADSB02
ADSB03:	POP	HL
ADSB04:	SCF
	RET
ADSB01:	LD	A,5
	SUB	B
	JR	Z,ADSB03
	LD	B,A
	POP	HL
	LD	IX,KETA1-2
	LD	IY,CKHEX
	JP	VALSUB

; (HL)É ÃÞ°ÀÓ¼ÞÚÂ¦ ÃÞ°ÀÄ¼Ã EÆ²ÚÙ
GTBYTE:	CALL	ADSUB
	RET	C
	INC	D
	DEC	D
	SCF
	RET	NZ
	LD	A,E
	OR	A
	RET

; (HL)<>','Å× ´×°
BUNCON:	LD	A,(HL)
	INC	HL
	CP	' '
	RET	Z
	CP	','
	RET	Z
	JP	ERROR

; FCB¸Ø±&DMA¾¯Ä
FCBCLR:	PUSH	HL
	LD	HL,FCB
	LD	DE,FCB+1
	LD	BC,36
	LD	(HL),0
	LDIR
	POP	HL
DMASET:	PUSH	HL
	LD	DE,DMA
	LD	C,1AH
	CALL	0F37DH
	POP	HL
	RET

; Û°ÄÞÖ³ µ°ÌßÝ (IN/FCB=Ì§²ÙÒ²)
LDOPEN:	LD	DE,FCB
	LD	C,0FH
	CALL	SYSCAL
	LD	HL,1
	LD	(FCB+14),HL
	RET

; ¾°ÌÞÖ³ µ°ÌßÝ (IN/FCB=Ì§²ÙÒ²)
SVOPEN:	PUSH	HL
	LD	DE,DMA+32
	LD	C,1AH
	CALL	0F37DH
	LD	DE,FCB
	LD	C,11H
	CALL	0F37DH
	OR	A
	JR	NZ,SVOPN1
	LD	DE,FCB
	LD	C,13H
	CALL	SYSCAL
SVOPN1:	LD	DE,FCB
	LD	C,16H
	CALL	SYSCAL
	LD	DE,FCB
	LD	C,0FH
	CALL	SYSCAL
	CPL
	LD	(OPNFG),A
	LD	HL,1
	LD	(FCB+14),HL
	LD	DE,DMA
	LD	C,1AH
	CALL	0F37DH
	POP	HL
	RET

; Adr1or2&filenameÉ ºÏÝÄÞÖ³ Adr¾¯ÄÙ°ÁÝ
;I/HL=Ó¼ÞÚÂÉ ¾ÝÄ³
;O/HL=º³¼Ý»ÚÙ
;(ADXWK0),(SLXWK0),(SFXWK0) - 1ÂÒÉ Adr,½Û¯Ä,½Û¯Ä¼Ã²Ì×¸Þ
;(SFXWK1)-2ÂÒÉAdr¶Þ ±Ù¶É Ì×¸Þ
;(ADXWK1)-2ÂÒÉAdr
;Ì§²ÙÈ°Ñ¶ÞÂÂÞ²Ã²À×,¿ÉÌ§²Ù¦µ°ÌßÝ.(OPNFG)¦0²¶Þ²Æ ½Ù
SUBMAN:	XOR	A
	LD	(SFXWK1),A
	CALL	SUB101
	LD	A,(HL)
	OR	A
	RET	Z
	CALL	BUNCON
	LD	IX,ADRES
	CALL	P0CALL
	JP	C,ERROR
	PUSH	HL
	LD	HL,(ADXWK0)
	RST	20H
	JR	C,SUBMN1
	EX	DE,HL
SUBMN1:	LD	(ADXWK0),HL
	LD	(ADXWK1),DE
	LD	A,255
	LD	(SFXWK1),A
	POP	HL
	LD	A,(HL)
	OR	A
	RET	Z
	CALL	BUNCON
	CALL	FLNAME
	CALL	SVOPEN
	JP	BUNMAT

; Adr1É ºÏÝÄÞÖ³ Adr¾¯ÄÙ°ÁÝ
SUB100:	CALL	SUB101
	JP	BUNMAT
SUB101:	LD	IX,ADRES
	CALL	P0CALL
	JP	C,ERROR
	LD	(ADXWK0),DE
	LD	(SLXWK0),BC
	RET

; Adr2É ºÏÝÄÞÖ³ Adr¾¯ÄÙ°ÁÝ
SUB200:	CALL	SUB101
	CALL	BUNCON
	LD	IX,ADRES
	CALL	P0CALL
	JP	C,ERROR
	PUSH	HL
	LD	HL,(ADXWK0)
	RST	20H
	JR	C,SUB201
	EX	DE,HL
SUB201:	LD	(ADXWK0),HL
	LD	(ADXWK1),DE
	LD	HL,(SLXWK0)
	LD	(SLXWK1),HL
	POP	HL
	RET

; Adr3É ºÏÝÄÞÖ³ Adr¾¯ÄÙ°ÁÝ
SUB300:	CALL	SUB200
	CALL	BUNCON
	LD	IX,ADRES
	CALL	P0CALL
	JP	C,ERROR
	LD	(ADXWK2),DE
	LD	(SLXWK2),BC
	RET

; DISKÈ°Ñ¾¯Ä
; I/HL=Ó¼ÞÚÂ¾ÝÄ³ O/A=(FCB+0)=DISK
DSKNM:	LD	A,(HL)
	OR	A
	JR	Z,DSKST1
	CP	'A'
	JP	C,ERROR
	CP	'H'+1
	JP	NC,ERROR
	PUSH	AF
	PUSH	HL
	LD	C,18H
	CALL	0F37DH
	EX	DE,HL
	POP	HL
	POP	AF
	SUB	'A'-1
	LD	B,1
	PUSH	AF
DSKST3:	DEC	A
	JR	Z,DSKST2
	SLA	B
	JR	DSKST3
DSKST2:	LD	A,B
	AND	E
	JP	Z,ERROR
	POP	AF
	OR	A
DSKST1:	LD	(FCB),A
	RET	Z
	INC	HL
	LD	A,(HL)
	CP	':'
	LD	A,(FCB)
	RET	NZ
	INC	HL
	RET

;Ì§²ÙÈ°Ñ¦ FCBÆ ¾¯Ä
;I/HL=Ó¼ÞÚÂ¾ÝÄ³  O/FCBÆÌ§²ÙÒ²¦¾¯Ä HLÊº³¼Ý»ÚÙ
FLNAME:	PUSH	HL
	LD	HL,0F87FH
	LD	DE,0F87FH+1
	LD	BC,15
	LD	(HL),0
	LDIR
	POP	HL
	CALL	FCBCLR
	LD	IX,0F87FH
	INC	HL
	LD	A,(HL)
	DEC	HL
	CP	':'
	JR	Z,FLNAM8
	LD	C,19H
	PUSH	IX
	PUSH	HL
	CALL	0F37DH
	POP	HL
	POP	IX
	INC	A
	JR	FLNA10
FLNAM8:	PUSH	IX
	CALL	DSKNM
	POP	IX
FLNA10:	ADD	A,'A'-1
	LD	(IX),A
	INC	IX
	LD	(IX),':'
	INC	IX
	EX	DE,HL
	LD	HL,FCB+1
	LD	B,8
FLNAM3:	LD	A,(DE)
	OR	A
	JP	Z,FLNAM1
	CP	','
	JP	Z,FLNAM1
	CP	' '
	JP	Z,FLNAM1
	CP	'.'
	JP	Z,FLNAM2
	CP	'*'
	JP	Z,FLNAM9
	CP	'?'
	JP	Z,FLNAM9
	CALL	ALPBIG
	LD	(HL),A
	LD	(IX),A
	INC	HL
	INC	DE
	INC	IX
	DJNZ	FLNAM3
	LD	A,(DE)
	CP	'.'
	JR	NZ,FLNAM7
	LD	(IX),'.'
	INC	IX
	INC	DE
FLNAM7:	LD	B,3
FLNAM4:	LD	A,(DE)
	OR	A
	JR	Z,FLNAM6
	CP	' '
	JP	Z,FLNAM6
	CP	','
	JR	Z,FLNAM6
	CP	'.'
	JP	Z,FLNAM9
	CP	'*'
	JP	Z,FLNAM9
	CP	'?'
	JP	Z,FLNAM9
	CALL	ALPBIG
	LD	(HL),A
	LD	(IX),A
	INC	HL
	INC	DE
	INC	IX
	DJNZ	FLNAM4
	LD	(IX),0
	EX	DE,HL
	RET
FLNAM1:	INC	B
	INC	B
	INC	B
FLNAM6:	LD	(HL),' '
	INC	HL
	DJNZ	FLNAM6
	LD	(IX),0
	EX	DE,HL
	RET
FLNAM2:	LD	(HL),' '
	INC	HL
	DJNZ	FLNAM2
	LD	(IX),'.'
	INC	IX
	INC	DE
	JR	FLNAM7
FLNAM9:	XOR	A
	LD	(0F87FH),A
	JP	ERROR

; DMA=>(ADXWK0) BCbyteÃÝ¿³
DMATRR:	LD	DE,DMA
	LD	HL,(ADXWK0)
DMATR1:	LD	A,(DE)
	PUSH	DE
	LD	E,A
	PUSH	BC
	CALL	POKE
	POP	BC
	POP	DE
	INC	DE
	INC	HL
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,DMATR1
	LD	(ADXWK0),HL
	RET

; (ADXWK0)=>DMA BCbyteÃÝ¿³
DMATRW:	LD	DE,DMA
	LD	HL,(ADXWK0)
DMATW1:	PUSH	DE
	PUSH	BC
	CALL	PEEK
	POP	BC
	POP	DE
	LD	(DE),A
	INC	DE
	INC	HL
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,DMATW1
	LD	(ADXWK0),HL
	RET

SCREEN:	XOR	A	; ¶Ý¼ÞÓ°ÄÞ µÌ
	LD	D,11H
	LD	E,A
	CALL	0FFCAH
	OR	A
	JR	Z,SCREN1
	XOR	A
	LD	D,11H
	LD	E,1
	CALL	0FFCAH
SCREN1:	LD	A,40
	LD	(0F3AEH),A
	LD	A,22
	LD	(0F3B1H),A
	XOR	A
	LD	(0FCAFH),A
	CALL	5FH
	CALL	0CFH
	LD	DE,0BF0H
	LD	HL,FONTDT
	LD	BC,8
	JP	LDIRVM



; SpPAGINGÉ PAGEË®³¼Þ
PAGPR:	LD	HL,13*256+24
	LD	(0F3DCH),HL
	LD	A,(DAPAGE)
	JP	HEXPR

; KANJI MODE
KM:	CALL	72H
	LD	IX,KNJON
	JP	P0CALL

; --- CALLÒ²Ú² ÊÝÃ² ---
START:	PUSH	HL
	LD	DE,0FD89H
	LD	A,(DE)
	CP	'@'
	JR	Z,START6
	CP	'S'
	JR	NZ,STAT11
	INC	DE
	LD	A,(DE)
	OR	A
	JR	NZ,STAT12
	LD	HL,STR01
	LD	DE,0FD89H
	LD	BC,7
	LDIR
	JR	STAT13
STAT12:	LD	HL,STR01+1 ; _SYSTEM
	LD	B,6
START7:	LD	A,(DE)
	CP	(HL)
	JR	NZ,START2
	INC	HL
	INC	DE
	DJNZ	START7
STAT13:	LD	HL,(WIZATB)
	LD	(HL),0
START2:	POP	HL
	SCF
	RET
STAT11:	LD	HL,STR00 ; _CHCPU Áª¯¸
	LD	B,6
START1:	LD	A,(DE)
	CP	(HL)
	JR	NZ,START2
	INC	HL
	INC	DE
	DJNZ	START1
	LD	A,(2DH)
	CP	3
	JR	C,START2
	POP	HL
	PUSH	HL
	LD	A,(HL)
	CP	'('
	JR	NZ,START2
	INC	HL
	LD	IX,521CH
	CALL	159H
	LD	A,(HL)
	CP	')'
	JR	NZ,START2
	LD	A,E
	INC	HL
	EX	(SP),HL
	CP	3
        JR      Z,STAT14
	JR	C,START5
	LD	E,5	; ERROR(5)
	LD	IX,406FH
	JP	159H
START5:	SET	7,A	; CPU ÁªÝ¼Þ
	CALL	180H
	POP	HL
	OR	A
	RET
STAT14:
        LD      A,128
        CALL    180H
        CALL    CHCPU7
        POP     HL
        OR      A
        RET

START6:	INC	DE	; _@ ¼Þ¯º³
	LD	A,(DE)
	OR	A
	JR	NZ,START2
STAT10:	POP	HL
	LD	(STACK),SP
	LD	(RESAVE+24),SP

	LD	A,(0F3DEH)
	LD	(FNKFG),A

	LD	A,0FFH	; CAPS·° ¾¯Ä
	LD	(0FCABH),A
	XOR	A
	CALL	132H

START9:	LD	A,(0006H)
	LD	(VREDPT),A
	LD	A,(0007H)
	LD	(VWRTPT),A
	CALL	INITWK
	CALL	SCREEN

	CALL	ERHKST

	LD	IX,TITLE
	CALL	P0CALL
	LD	A,23H
	LD	(HICHP2),A
	LD	DE,NWSLTP
	LD	BC,NWSLEN-NWSLTP
	LD	IX,CMTRNS
	CALL	P0CALL
	CALL	VWORK
	XOR	A
	LD	(HICHP2),A
	LD	A,14
	LD	(0F3DCH),A
	CALL	CRLF

; --- SYSTEM ---
; MAIN RAUTINE
; ºº¶× ¶¸ºÏÝÄÞÍÄ ÌÞÝ·½Ù
SYSTEM:	LD	A,(0F3AEH)
	CP	40
	CALL	NZ,SCREEN
	LD	A,(0FCAFH)
	OR	A
	CALL	NZ,SCREEN
	CALL	0C9H
	LD	A,(OPNFG)
	OR	A
	JR	Z,SYSTM1
	CALL	CLOSE
SYSTM1:	LD	SP,(RESAVE+24)
	XOR	A
	LD	(SAMEFG),A
	LD	(PRNFG),A
	LD	(CARFG),A
	LD	(CRTOFF),A
	LD	HL,STR32
	LD	IX,MAKSLA
	CALL	P0CALL
	CALL	PROMPT
SYST11:	CALL	INLIN
	JR	C,SYSTEM
	INC	HL
	LD	DE,BUFSV0
	LD	HL,0F55EH+1
        LD      A,(HL)
        DEC     HL
        CP      '>'
 	LD	A,(HL)
        CALL    Z,SYST17
        DEC     HL
SYST18:
        INC     HL
        LD      A,(HL)
        CP      ' '
        JR      Z,SYST18

	OR	A
	JR	NZ,SYSTM7
	LD	HL,0F3DCH
	DEC	(HL)
	INC	HL
	LD	(HL),3
	LD	HL,STR96
	CALL	PRINT
	CALL	PROMPT
	LD	HL,(0F3DCH)
	PUSH	HL
	LD	B,-1
SYSTM8:	LD	A,(DE)
	CALL	0A2H
	INC	DE
	INC	B
	OR	A
	JR	NZ,SYSTM8
	LD	A,B
	ADD	A,4
	LD	H,0
	LD	L,A
	LD	DE,40
	CALL	DIV
	LD	A,L
	POP	HL
	ADD	A,L
	LD	B,A
	LD	A,(0F3DEH)
	OR	A
	JR	Z,SYSTM9
	LD	A,-1
SYSTM9:	ADD	A,22
	LD	C,A
	LD	A,B
	SUB	C
	JR	C,SYST10
	LD	C,A
	LD	A,L
	SUB	C
	LD	L,A
SYST10:	LD	(0F3DCH),HL
	JR	SYST11
SYSTM7:
        PUSH    HL
        LD	BC,40
	LDIR
	POP HL
	XOR	A
	LD	(DE),A

	LD	A,(HL)
	CP	'?'
	JR	NZ,SYSTM6
	CALL	0A8H
	JP	Z,ERROR2
	LD	A,255
	LD	(PRNFG),A
	INC	HL
SYSTM6:	LD	A,(HL)
	CP	'#'
	JR	NZ,SYST12
	LD	IX,SLT
	CALL	P0CALL
	JP	C,ERROR
	CALL	BUNMAT
	LD	(SLSAV0),BC
	JP	SYSTM1
SYST12:	INC	HL
	LD	A,(HL)
	DEC	HL
	CP	':'
	JR	NZ,SYST16
	CALL	DSKNM
	CALL	BUNMAT
	LD	A,(FCB)
	LD	C,0EH
	DEC	A
	LD	E,A
	CALL	0F37DH
	JP	SYSTM1	
SYST16:	PUSH	HL
	POP	IY
	LD	IX,COMAND
SYSTM4:	LD	A,(IX)
	OR	A
	JP	Z,ERROR
	CP	(IY)
	JR	Z,SYSTM3
SYSTM5:	LD	DE,8
	ADD	IX,DE
	JR	SYSTM4
SYSTM3:	LD	A,(IX+1)
	OR	A
	JR	Z,SYSTM2
	CP	(IY+1)
	JR	NZ,SYSTM5
	INC	IY
SYSTM2:	INC	IY
	LD	A,(IY)
	CP	' '
	JR	Z,SYSTM2
	PUSH	IY
	POP	HL
	LD	E,(IX+2)
	LD	D,(IX+3)
	PUSH	DE
	LD	E,(IX+4)
	LD	D,(IX+5)
	LD	C,(IX+6)
	LD	B,(IX+7)
	POP	IX
	JP	(IX)

SYST17: ;Drive letter = Repeated command -> skip
        CP 'A'
        RET C
        CP 'H'+1
        RET NC
        INC HL
        INC HL
        RET



; ºÏÝÄÞÁ­³ÀÞÝ
BREAK:	LD	HL,STR98
	JR	ERREND

; ºÏÝÄÞ¶ÝØ®³
COMPLT:	LD	A,(0F3DDH)
	DEC	A
	CALL	NZ,CRLF
	LD	HL,STR52
	CALL	PRINT
	JP	SYSTEM

ERROR:	LD	HL,STR34 ;Error
ERREND:	PUSH	HL
	LD	A,(0F3AEH)
	CP	40
	CALL	NZ,SCREEN
	POP	HL
	LD	A,(0F3DDH)
	DEC	A
	CALL	NZ,CRLF
	CALL	PRINT
	JP	SYSTEM

ERROR2:	LD	HL,STR35 ;Printer err
	JR	ERREND

ERROR4:	CALL	CLS
	LD	HL,STR30 ;STACK err
	JR	ERREND

ERROR5:	LD	HL,STR83 ;File too big
	JR	ERREND

ERROR6:	LD	HL,STR77 ;Notfound
	JR	ERREND

; P0É ºÏÝÄÞ ¼Þ¯º³
P0CM:	LD	IX,CMTRNS
	CALL	P0CALL
	JP	VWORK

;  Disassembler keys (I)
DA:	XOR	A
	LD	(Y),A
	LD	(BASE),HL
DA19:	LD	IX,SITACL
	CALL	P0CALL
	CALL	PAGPR
DA5:	LD	HL,(BASE)
	LD	IX,VWORK
	LD	B,20
DA1:	PUSH	BC
	CALL	ADA
	POP	BC
	DJNZ	DA1
DA3:	CALL	VWKPUT
	LD	HL,VWORK
	LD	DE,ADINWK
	LD	BC,4
	LDIR
	LD	B,4
	CALL	THEX
	LD	(BASE),HL
DA12:	LD	A,(Y)
	INC	A
	LD	(0F3DCH),A
	LD	A,19
	LD	(0F3DDH),A
	CALL	DA27
	CALL	SADPUT
	CALL	GRAWIN
DA11:	CALL	9FH
	CP	24
	CALL	Z,CHGPAG
	CP	22
	CALL	Z,VCOPY
	CP	16
	CALL	Z,PCOPY
	CP	6
	JP	Z,DA50
	CP	4
	JP	Z,DA70
	CP	' '
	JP	Z,DA60
	CP	19
	JP	Z,DA51
	CP	31
	JR	Z,DA2
	CP	30
	JR	Z,DA4
	CP	28
	JP	Z,DA14
	CP	29
	JP	Z,DA20
	CP	'\'
	JR	Z,DA6
	CP	9
	JR	Z,DA6
	CP      15 ; ^O
	JP      Z,DA152
	CP      26
	JP      Z,DA262
	CP	27
	JP	Z,DA7
	CP	18
	JP	Z,DA8
	CP	127
	JP	Z,DA9
	CP	13
	JP	Z,DA10
	CP	11
	JP	Z,DA25
	CP	12
	JP	Z,DA26
	JP	DA11
DA2:	CALL	SHIFTC
	JR	Z,DA28
	LD	HL,Y
	INC	(HL)
	LD	A,(HL)
	CP	20
	JP	NZ,DA12
	DEC	(HL)
DA28:	LD	HL,VWORK+40
	LD	DE,VWORK
	LD	BC,40*19
	LDIR
	LD	IX,40*19+VWORK
	LD	HL,(ADSAV0)
	CALL	ADA
	JP	DA3
DA4:	CALL	SHIFTC
	JR	Z,DA29
	LD	HL,Y
	DEC	(HL)
	LD	A,(HL)
	CP	-1
	JP	NZ,DA12
	INC	(HL)
DA29:	LD	HL,(BASE)
	DEC	HL
	LD	(BASE),HL
	JP	DA5
DA6:	CALL	DA80
	JR	NC,DA100
	LD	HL,1*256+21
	LD	(0F3DCH),HL
	LD	HL,STR36
	CALL	PRINT
	CALL	SINLIN
DA101:	JP      C,DA18
	JP      DISASJ

DA100:	LD	HL,1*256+21
	LD	(0F3DCH),HL
	LD	HL,STR36
	CALL	PRINT
	LD	A,3
	LD	(XSAV),A
	LD	HL,STR37
	CALL	PRINT
	LD	A,4
	LD	(0F3DDH),A
	LD	HL,(ADXWK0)
	CALL	ADRSPR
	CALL	SINLNJ
	JR	DA101

DA152:	LD	HL,1*256+21
	LD	(0F3DCH),HL
        LD      HL,(BASE)
        PUSH    HL
	LD	HL,STR36
	CALL	PRINT
	CALL	SINLIN
	POP     HL
	JP      C,DA18
        LD      DE,(ADXWK0)
        ADD     HL,DE
        LD      (ADXWK0),HL
        LD      HL,0
        OR      A
        SBC     HL,DE
        LD      DE,(OFFSET)
        ADD     HL,DE
        LD      (OFFSET),HL
	JP      DISASJ

DA7:	LD	HL,1*256+21
	LD	(0F3DCH),HL
DA102:	LD	HL,(BASE)
	LD	(ADSAV0),HL
	JP	SYSTEM
DA8:	LD	HL,40*16+VWORK
	LD	DE,ADINWK
	LD	BC,4
	LDIR
	LD	B,4
	CALL	THEX
	LD	(BASE),HL
	JP	DA5
DA9:	LD	HL,(BASE)
	LD	DE,-20
	ADD	HL,DE
	LD	(BASE),HL
	JP	DA5
DA10:	CALL	DA27
	CALL	BUNKI
	JP	DA3
DA14:	LD	A,(DAPAGE)
	CP	15
	JR	NZ,DA22
DA18:	LD	A,7
	CALL	0A2H
	JP	DA19
DA22:	CALL	DA80
	JR	NC,DA15
	CALL	DA23
	CALL	SINLIN
	JR	DA24
DA15:	CALL	DA23
	LD	HL,STR37
	CALL	PRINT
	LD	A,4
	LD	(XSAV),A
	INC	A
	LD	(0F3DDH),A
	LD	HL,(ADXWK0)
	CALL	ADRSPR
	CALL	SINLNJ
DA24:	JP	C,DA18
	LD	HL,DAPAGE
	LD	A,(HL)
	CP	15
	JR	Z,DA18
	INC	(HL)
	LD	L,A
	LD	H,0
	PUSH	HL
	POP	BC
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
	LD	BC,DAPGWK
	ADD	HL,BC
	LD	BC,(BASE)
	LD	(HL),C
	INC	HL
	LD	(HL),B
	INC	HL
	LD	BC,(SLSAV0)
	LD	(HL),C
	INC	HL
	LD	(HL),B
	INC	HL
	LD	A,(Y)
	LD	(HL),A
	LD	HL,(ADXWK0)
	LD	(BASE),HL
	LD	HL,(SLXWK0)
	LD	(SLSAV0),HL
	XOR	A
	LD	(Y),A
DA21:	LD	HL,STDISA
	LD	IX,MAKSLA
	CALL	P0CALL
	JP	DA19
DA20:	LD	HL,DAPAGE
	LD	A,(HL)
	OR	A
	JP	Z,DA18
	DEC	(HL)
	LD	L,(HL)
	LD	H,0
	PUSH	HL
	POP	DE
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	LD	DE,DAPGWK
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(BASE),DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	(SLSAV0),DE
	LD	(SLXWK0),DE
	LD	A,(HL)
	LD	(Y),A
	JP	DA21
DA23:	LD	HL,1*256+21
	LD	(0F3DCH),HL
	LD	HL,STR39
	JP	PRINT
DA25:	XOR	A
	LD	(Y),A
	JP	DA12
DA262:  CALL    SOFSET
        JP       DISASJ
DA26:	CALL	DA27
	LD	(BASE),HL
	XOR	A
	LD	(Y),A
	JP	DA5
DA27:	LD	HL,(Y)
	LD	H,0
	LD	DE,40
	CALL	MULT
	LD	DE,VWORK
	ADD	HL,DE
	LD	DE,ADINWK
	LD	BC,4
	LDIR
	LD	B,4
	JP	THEX
DA50:	LD	HL,0FFFFH
	LD	(ADXWK1),HL
	LD	HL,1
DA71:	LD	(SRCHZ),HL
	LD	A,(FINDFG)
	OR	A
	JP	Z,DA11
	CALL	DA27
	LD	DE,(SRCHZ)
	ADD	HL,DE
	LD	(ADXWK0),HL
	INC	D
	JR	Z,DA72
	LD	A,H
	OR	L
	JP	Z,DA5
	JR	DA73
DA72:	LD	A,H
	AND	L
	CP	255
	JP	Z,DA5
DA73:	CALL	SEARCH
	JP	C,DA5
	BIT	7,A
	JP	NZ,DA5
	XOR	A
	LD	(Y),A
	LD	(BASE),HL
	JP	DA5
DA70:	LD	HL,0
	LD	(ADXWK1),HL
	LD	HL,-1
	JR	DA71
DA51:	CALL	CLS
	CALL	FDATST
	JP	C,DA5
	JR	DA50
DA60:	CALL	SHIFTC
	JR	Z,DA110
	CALL	DA80
	JP	C,DA11
	CALL	DASUB
	JP	DA11
DA110:	CALL	DA27
	CALL	D_W_AS
	JP	DA5
DA80:	XOR	A
	LD	(SOMPRF),A
	LD	HL,(Y)
	LD	H,0
	LD	DE,40
	CALL	MULT
	LD	DE,VWORK+39
	ADD	HL,DE
	LD	B,20
DA61:	LD	A,(HL)
	CP	'H'
	JR	Z,DA62
DA65:	DEC	HL
	DJNZ	DA61
	SCF
	RET
DA62:	PUSH	BC
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	DE,ADINWK
	LD	BC,4
	LDIR
	LD	B,4
	CALL	THEX
	JR	C,DA63
	EX	DE,HL
	POP	HL
	POP	BC
DA64:	LD	(ADXWK0),DE
	OR	A
	RET
DA63:	POP	HL
	PUSH	HL
	DEC	HL
	DEC	HL
	LD	DE,ADINWK
	LD	BC,2
	LDIR
	LD	B,2
	CALL	THEX
	EX	DE,HL
	POP	HL
	POP	BC
	JR	C,DA65
	LD	A,255
	LD	(SOMPRF),A
	JR	DA64

DASUB:	CALL	SCRSAV
	LD	HL,0
	LD	BC,80
	LD	A,' '
	CALL	FILVRM
	LD	HL,80
	LD	BC,40
	LD	A,'-'
	CALL	FILVRM
	LD	HL,0101H
	LD	(0F3DCH),HL
	LD	DE,(ADXWK0)
	LD	A,(SOMPRF)
	OR	A
	CALL	Z,SOMEPR
	LD	C,E
	CALL	NZ,BSOMEP
	CALL	JTNKRD
	LD	A,(TNKFG)
	OR	A
	JR	NZ,DASUB1
DASUB2:	CALL	9CH
	JR	Z,DASUB2
	CALL	9FH
DASUB1:	JP	SCRREM

; CHARACTER editor keys
C_W:	LD	(BASE),HL
	LD	HL,VWORK
	LD	DE,VWORK+1
	LD	BC,40*20-1
	LD	(HL),32
	LDIR
	LD	IX,CHRHLP
	CALL	P0CALL
	LD	B,16
	XOR	A
	LD	IX,VWORK+5
C_W91:	PUSH	AF
	CALL	HEXIN
	POP	AF
	INC	A
	DJNZ	C_W91
	LD	IX,SITACL
	CALL	P0CALL
	CALL	PAGPR
C_W25:	LD	HL,0
	LD	(Y),HL
C_W5:	LD	HL,(BASE)
	LD	IX,VWORK+40
	LD	B,16
C_W1:	PUSH	BC
	PUSH	BC
	CALL	AC_W
	POP	BC
	LD	(IX),' '
	INC	IX
	LD	A,16
	SUB	B
	CALL	HEXIN
	LD	B,11
C_W90:	LD	(IX),' '
	INC	IX
	DJNZ	C_W90
	POP	BC
	DJNZ	C_W1
C_W9:	LD	HL,(BASE)
	LD	(ADSAV0),HL
	CALL	VWKPUT
C_W3:	LD	A,(X)
	ADD	A,6
	LD	HL,0F3DDH
	LD	(HL),A
	LD	A,(Y)
	ADD	A,2
	DEC	HL
	LD	(HL),A
C_W11:	CALL	C_WSUB
	CALL	SADPUT
	CALL	GRAWIN
	CALL	9FH
	CALL	ALPBIG
	LD	HL,C_W11
	PUSH	HL
	CP	24
	JP	Z,CHGPAG
	CP	22
	JP	Z,VCOPY
	CP	16
	JP	Z,PCOPY
	POP	HL
	CP	' '
	JP	Z,C_W70
	CP	6
	JP	Z,C_W50
	CP	4
	JP	Z,C_W52
	CP	19
	JP	Z,C_W51
	CP	28
	JP	Z,C_W2
	CP	31
	JP	Z,C_W4
	CP	29
	JP	Z,C_W6
	CP	8
	JP	Z,C_W6
	CP	30
	JP	Z,C_W7
	CP	'\'
	JP	Z,C_W8
	CP	9
	JP	Z,C_W8
        CP      26
        JP      Z,C_W26
	CP	27
	JP	Z,C_W10
	CP	18
	JP	Z,C_W14
	CP	127
	JP	Z,C_W16
	CP	11
	JP	Z,C_W24
	CP	12
	JP	Z,C_W15
	CP	13
	JP	Z,C_W30
	CP	'C'
	JP	Z,C_W110
	CP	'U'
	JP	Z,C_W112
	CP	'D'
	JP	Z,C_W113
	CP	'R'
	JP	Z,C_W114
	CP	'L'
	JP	Z,C_W115
	CP	'V'
	JP	Z,C_W120
	CP	'O'
	JP	Z,C_W121
	CP	'F'
	JP	Z,C_W122
	JP	C_W11
C_W80:	CALL	C_WSUB
	CALL	PEEK
	LD	D,A
	LD	A,(X)
	AND	111B
	INC	A
	LD	B,A
	LD	A,1
C_W81:	RRCA
	DJNZ	C_W81
	LD	E,A
	LD	A,D
	XOR	E
	LD	E,A
	CALL	POKE
	JP	C_W5

C_W26:  CALL    SOFSET
        JP      CHARAJ;C_W25

C_W2:	LD	HL,X
	INC	(HL)
	LD	A,(HL)
	CP	16
	JP	NZ,C_W3
	LD	(HL),0
C_W4:	CALL	SHIFTC
	JR	Z,C_W40
	LD	HL,Y
	INC	(HL)
	LD	A,(HL)
	CP	16
	JP	NZ,C_W3
	DEC	(HL)
C_W40:	LD	HL,(BASE)
	INC	HL
	LD	(BASE),HL
	JP	C_W5
C_W6:	LD	HL,X
	DEC	(HL)
	LD	A,(HL)
	CP	-1
	JP	NZ,C_W3
	LD	(HL),15
C_W7:	CALL	SHIFTC
	JR	Z,C_W41
	LD	HL,Y
	DEC	(HL)
	LD	A,(HL)
	CP	-1
	JP	NZ,C_W3
	INC	(HL)
C_W41:	LD	HL,(BASE)
	DEC	HL
	LD	(BASE),HL
	JP	C_W5
C_W8:	LD	HL,CHARAJ
	PUSH	HL
	JP	INADRS
C_W10:	LD	A,20
	LD	(0F3DCH),A
	JP	SYSTEM
C_W14:	LD	HL,(BASE)
	LD	DE,16
	ADD	HL,DE
	LD	(BASE),HL
	JP	C_W5
C_W16:	LD	HL,(BASE)
	LD	DE,-16
	ADD	HL,DE
	LD	(BASE),HL
	JP	C_W5
C_W24:	LD	HL,0
	LD	(Y),HL
	JP	C_W3
C_W15:	CALL	C_WSUB
	LD	(BASE),HL
	JP	C_W25
C_W30:	CALL	C_WSUB
	CALL	BUNKI
	JP	C_W9
C_W50:	LD	HL,0FFFFH
	LD	(ADXWK1),HL
	LD	HL,1
C_W53:	LD	(SRCHZ),HL
	LD	A,(FINDFG)
	OR	A
	JP	Z,C_W11
	CALL	C_WSUB
	LD	DE,(SRCHZ)
	ADD	HL,DE
	LD	(ADXWK0),HL
	INC	D
	JR	Z,C_W54
	LD	A,H
	OR	L
	JP	Z,C_W5
	JR	C_W55
C_W54:	LD	A,H
	AND	L
	CP	255
	JP	Z,C_W5
C_W55:	CALL	SEARCH
	JP	C,C_W5
	BIT	7,A
	JP	NZ,C_W5
	LD	(BASE),HL
	JP	C_W25
C_W52:	LD	HL,0
	LD	(ADXWK1),HL
	LD	HL,-1
	JR	C_W53
C_W51:	CALL	CLS
	CALL	FDATST
	JP	C,C_W25
	JR	C_W50
C_W70:	CALL	SHIFTC
	JP	NZ,C_W80
	CALL	C_WSUB
	CALL	D_W_AS
	JP	C_W11
C_W110:	LD	HL,(BASE)
	LD	B,32
C_W111:	LD	E,0
	PUSH	BC
	CALL	POKE
	POP	BC
	INC	HL
	DJNZ	C_W111
	JP	C_W5
C_W112:	CALL	C_WSUB
	CALL	PEEK
	PUSH	AF
	LD	A,(Y)
	OR	A
	JR	Z,C_W116
	DEC	HL
	CALL	PEEK
	POP	DE
	LD	E,D
	PUSH	AF
	CALL	POKE
	POP	AF
	LD	E,A
	INC	HL
	CALL	POKE
	JP	C_W5
C_W116:	LD	DE,15
	ADD	HL,DE
	CALL	PEEK
	POP	DE
	PUSH	AF
	LD	E,D
	CALL	POKE
	LD	DE,-15
	ADD	HL,DE
	POP	AF
	LD	E,A
	CALL	POKE
	JP	C_W5
C_W113:	CALL	C_WSUB
	CALL	PEEK
	PUSH	AF
	LD	A,(Y)
	CP	15
	JR	Z,C_W117
	INC	HL
	CALL	PEEK
	POP	DE
	LD	E,D
	PUSH	AF
	CALL	POKE
	POP	AF
	LD	E,A
	DEC	HL
	CALL	POKE
	JP	C_W5
C_W117:	LD	DE,-15
	ADD	HL,DE
	CALL	PEEK
	POP	DE
	PUSH	AF
	LD	E,D
	CALL	POKE
	LD	DE,15
	ADD	HL,DE
	POP	AF
	LD	E,A
	CALL	POKE
	JP	C_W5
C_W114:	LD	A,(X)
	CP	8
	JR	Z,C_W118
	CP	7
	JR	Z,C_W118
	CALL	C_WSUB
	CALL	PEEK
	RRCA
	LD	E,A
	CALL	POKE
	JP	C_W5
C_W118:	LD	DE,(Y)
	LD	D,0
	LD	HL,(BASE)
	ADD	HL,DE
	CALL	PEEK
	PUSH	AF
	RRCA
	PUSH	AF
	LD	DE,16
	ADD	HL,DE
	CALL	PEEK
	LD	E,A
	POP	AF
	RR	E
	PUSH	AF
	CALL	POKE
	LD	DE,-16
	ADD	HL,DE
	POP	AF
	POP	DE
	LD	E,D
	RR	E
	CALL	POKE
	JP	C_W5
C_W115:	LD	A,(X)
	CP	7
	JR	Z,C_W119
	CP	8
	JR	Z,C_W119
	CALL	C_WSUB
	CALL	PEEK
	RLCA
	LD	E,A
	CALL	POKE
	JP	C_W5
C_W119:	LD	DE,(Y)
	LD	D,0
	LD	HL,(BASE)
	ADD	HL,DE
	CALL	PEEK
	PUSH	AF
	RLCA
	PUSH	AF
	LD	DE,16
	ADD	HL,DE
	CALL	PEEK
	LD	E,A
	POP	AF
	RL	E
	PUSH	AF
	CALL	POKE
	LD	DE,-16
	ADD	HL,DE
	POP	AF
	POP	DE
	LD	E,D
	RL	E
	CALL	POKE
	JP	C_W5
C_W120:	CALL	C_WSUB
	CALL	PEEK
	XOR	255
	LD	E,A
	CALL	POKE
	JP	C_W5
C_W121:	CALL	C_WSUB
	LD	E,255
	CALL	POKE
	JP	C_W5
C_W122:	CALL	C_WSUB
	LD	E,0
	CALL	POKE
	JP	C_W5

C_WSUB:	CALL	LACAL
	LD	IX,VWORK
	EX	DE,HL
	ADD	IX,DE
	LD	A,(X)
	CP	8
	LD	E,0
	JR	C,C_WSB1
	LD	E,16
C_WSB1:	LD	A,(Y)
	ADD	A,E
	LD	D,0
	LD	E,A
	LD	HL,(BASE)
	ADD	HL,DE
	RET

; ASCII editor keys
A_W:	LD	(BASE),HL
	LD	IX,SITACL
	CALL	P0CALL
	CALL	PAGPR
A_W25:	LD	HL,0
	LD	(Y),HL
A_W5:	LD	HL,(BASE)
	LD	IX,VWORK
	LD	B,20
A_W1:	PUSH	BC
	LD	B,32
	CALL	AA_W
	CALL	ASDMP1
	POP	BC
	DJNZ	A_W1
A_W9:	LD	HL,(BASE)
	LD	(ADSAV0),HL
	CALL	VWKPUT
A_W3:	LD	A,(X)
	ADD	A,6
	LD	HL,0F3DDH
	LD	(HL),A
	LD	A,(Y)
	INC	A
	DEC	HL
	LD	(HL),A
A_W11:	CALL	A_WSUB
	CALL	SADPUT
	CALL	GRAWIN
	CALL	9FH
	LD	HL,A_W11
	PUSH	HL
	CP	24
	JP	Z,CHGPAG
	CP	22
	JP	Z,VCOPY
	CP	16
	JP	Z,PCOPY
	POP	HL
	CP	' '
	JP	Z,A_W70
	CP	6
	JP	Z,A_W50
	CP	4
	JP	Z,A_W52
	CP	19
	JP	Z,A_W51
	CP	28
	JP	Z,A_W2
	CP	31
	JP	Z,A_W4
	CP	29
	JP	Z,A_W6
	CP	8
	JP	Z,A_W6
	CP	30
	JP	Z,A_W7
	CP	'\'
	JP	Z,A_W8
	CP	9
	JP	Z,A_W8
	CP	27
	JP	Z,A_W10
	CP	18
	JP	Z,A_W14
	CP	127
	JP	Z,A_W16
	CP	11
	JP	Z,A_W24
	CP      26
	JP      Z,A_W26
	CP	12
	JP	Z,A_W15
	CP	13
	JP	Z,A_W30
A_W80:	PUSH	AF
	CALL	A_WSUB
	POP	AF
	LD	E,A
	CALL	POKE
	LD	A,(BASE)
	AND	11111B
	LD	B,A
A_W18:	LD	A,L
	AND	11111B
	CP	B
	JR	Z,A_W17
	DEC	HL
	JR	A_W18
A_W17:	LD	B,32
	CALL	AA_W
	CALL	ASDMP1
	CALL	VWKPUT
A_W2:	LD	HL,X
	INC	(HL)
	LD	A,(HL)
	CP	32
	JP	NZ,A_W3
	LD	(HL),0
A_W4:	CALL	SHIFTC
	JR	Z,A_W40
	LD	HL,Y
	INC	(HL)
	LD	A,(HL)
	CP	20
	JP	NZ,A_W3
	DEC	(HL)
A_W40:	LD	HL,(BASE)
	LD	DE,32
	ADD	HL,DE
	LD	(BASE),HL
	PUSH	HL
	LD	HL,VWORK+40
	LD	DE,VWORK
	LD	BC,40*19
	LDIR
	LD	IX,40*19+VWORK
	POP	HL
	LD	DE,19*32
	ADD	HL,DE
	LD	B,32
	CALL	AA_W
	CALL	ASDMP1
	JP	A_W9
A_W6:	LD	HL,X
	DEC	(HL)
	LD	A,(HL)
	CP	-1
	JP	NZ,A_W3
	LD	(HL),31
A_W7:	CALL	SHIFTC
	JR	Z,A_W41
	LD	HL,Y
	DEC	(HL)
	LD	A,(HL)
	CP	-1
	JP	NZ,A_W3
	INC	(HL)
A_W41:	LD	HL,(BASE)
	LD	DE,-32
	ADD	HL,DE
	PUSH	HL
	LD	(BASE),HL
	LD	HL,40*18+VWORK+39
	LD	DE,40*19+VWORK+39
	LD	BC,40*19
	LDDR
	LD	IX,VWORK
	POP	HL
	LD	B,32
	CALL	AA_W
	CALL	ASDMP1
	JP	A_W9
A_W8:	LD	HL,ASCIIJ
	PUSH	HL
	JP	INADRS
A_W10:	LD	A,20
	LD	(0F3DCH),A
	JP	SYSTEM
A_W14:	LD	HL,(BASE)
	LD	DE,608
	ADD	HL,DE
	LD	(BASE),HL
	JP	A_W5
A_W16:	LD	HL,(BASE)
	LD	DE,-608
	ADD	HL,DE
	LD	(BASE),HL
	JP	A_W5
A_W24:	LD	HL,0
	LD	(Y),HL
	JP	A_W3
A_W26:  CALL    SOFSET
	JP	ASCIIJ;A_W25
A_W15:	CALL	A_WSUB
	LD	(BASE),HL
	JP	A_W25
A_W30:	CALL	A_WSUB
	CALL	BUNKI
	JP	A_W9
A_W50:	LD	HL,0FFFFH
	LD	(ADXWK1),HL
	LD	HL,1
A_W53:	LD	(SRCHZ),HL
	LD	A,(FINDFG)
	OR	A
	JP	Z,A_W11
	CALL	A_WSUB
	LD	DE,(SRCHZ)
	ADD	HL,DE
	LD	(ADXWK0),HL
	INC	D
	JR	Z,A_W54
	LD	A,H
	OR	L
	JP	Z,A_W5
	JR	A_W55
A_W54:	LD	A,H
	AND	L
	CP	255
	JP	Z,A_W5
A_W55:	CALL	SEARCH
	JP	C,A_W5
	BIT	7,A
	JP	NZ,A_W5
	LD	(BASE),HL
	JP	A_W25
A_W52:	LD	HL,0
	LD	(ADXWK1),HL
	LD	HL,-1
	JR	A_W53
A_W51:	CALL	CLS
	CALL	FDATST
	JP	C,A_W25
	JR	A_W50
A_W70:	CALL	SHIFTC
	LD	A,' '
	JP	NZ,A_W80
	CALL	A_WSUB
	CALL	D_W_AS
	JP	A_W11

A_WSUB:	CALL	LACAL
	LD	IX,VWORK
	EX	DE,HL
	ADD	IX,DE
	LD	HL,(Y)
	LD	H,0
	ADD	HL,HL ;2
	ADD	HL,HL ;4
	ADD	HL,HL ;8
	ADD	HL,HL ;16
	ADD	HL,HL ;32
	LD	A,(X)
	LD	D,0
	LD	E,A
	ADD	HL,DE
	LD	DE,(BASE)
	ADD	HL,DE
	RET

; HEX-EDITOR keys
D_W:	LD	(BASE),HL
	LD	IX,SITACL
	CALL	P0CALL
	CALL	PAGPR
D_W25:	LD	HL,0
	LD	(Y),HL
D_W5:	LD	HL,(BASE)
	LD	IX,VWORK
	LD	B,20
D_W1:	PUSH	BC
	CALL	AD_W
	POP	BC
	DJNZ	D_W1
D_W9:	LD	HL,(BASE)
	LD	(ADSAV0),HL
	CALL	VWKPUT
D_W3:	LD	A,(X)
	LD	B,A
	SRL	A
	ADD	A,B
	ADD	A,6
	LD	HL,0F3DDH
	LD	(HL),A
	LD	A,(Y)
	INC	A
	DEC	HL
	LD	(HL),A
D_W11:	CALL	D_WSUB
	CALL	SADPUT
	CALL	GRAWIN
	CALL	TENIN
	CP	24
	CALL	Z,CHGPAG
	CP	22
	CALL	Z,VCOPY
	CP	16
	CALL	Z,PCOPY
	CP	' '
	JP	Z,D_W70
	CP	6
	JP	Z,D_W50
	CP	4
	JP	Z,D_W52
	CP	19
	JP	Z,D_W51
	CP	28
	JP	Z,D_W2
	CP	31
	JP	Z,D_W4
	CP	29
	JP	Z,D_W6
	CP	8
	JP	Z,D_W6
	CP	30
	JP	Z,D_W7
	CP	'\'
	JP	Z,D_W8
	CP	9
	JP	Z,D_W8
	CP	27
	JP	Z,D_W10
	CP	18
	JP	Z,D_W14
	CP	127
	JP	Z,D_W16
	CP	'"'
	JP	Z,D_W19
	CP	'@'
	JP	Z,D_W21
	CP	11
	JP	Z,D_W24
	CP      26
	JP      Z,D_W26
	CP	12
	JP	Z,D_W15
	CP	13
	JP	Z,D_W30
	CALL	CKHEX
	JP	C,D_W11
	PUSH	AF
	CALL	D_WSUB
	CALL	PEEK
	LD	E,A
	LD	A,(X)
	BIT	0,A
	JR	NZ,D_W12
	LD	A,E
	AND	0FH
	LD	E,A
	POP	AF
	RLCA
	RLCA
	RLCA
	RLCA
	JR	D_W13
D_W12:	LD	A,E
	AND	0F0H
	LD	E,A
	POP	AF
D_W13:	OR	E
D_W20:	LD	E,A
	CALL	POKE
	LD	A,(BASE)
	AND	111B
	LD	B,A
D_W18:	LD	A,L
	AND	111B
	CP	B
	JR	Z,D_W17
	DEC	HL
	JR	D_W18
D_W17:	CALL	AD_W
	CALL	VWKPUT
D_W2:	LD	HL,X
	INC	(HL)
	LD	A,(HL)
	CP	16
	JP	NZ,D_W3
	LD	(HL),0
D_W4:	CALL	SHIFTC
	JR	Z,D_W40
	LD	HL,Y
	INC	(HL)
	LD	A,(HL)
	CP	20
	JP	NZ,D_W3
	DEC	(HL)
D_W40:	LD	HL,(BASE)
	LD	DE,8
	ADD	HL,DE
	LD	(BASE),HL
	PUSH	HL
	LD	HL,VWORK+40
	LD	DE,VWORK
	LD	BC,40*19
	LDIR
	LD	IX,40*19+VWORK
	POP	HL
	LD	DE,19*8
	ADD	HL,DE
	CALL	AD_W
	JP	D_W9
D_W6:	LD	HL,X
	DEC	(HL)
	LD	A,(HL)
	CP	-1
	JP	NZ,D_W3
	LD	(HL),15
D_W7:	CALL	SHIFTC
	JR	Z,D_W41
	LD	HL,Y
	DEC	(HL)
	LD	A,(HL)
	CP	-1
	JP	NZ,D_W3
	INC	(HL)
D_W41:	LD	HL,(BASE)
	LD	DE,-8
	ADD	HL,DE
	PUSH	HL
	LD	(BASE),HL
	LD	HL,40*18+VWORK+39
	LD	DE,40*19+VWORK+39
	LD	BC,40*19
	LDDR
	LD	IX,VWORK
	POP	HL
	CALL	AD_W
	JP	D_W9
D_W8:	LD	HL,DUMPJ
	PUSH	HL
	JP	INADRS
D_W10:	LD	A,20
	LD	(0F3DCH),A
	JP	SYSTEM
D_W14:	LD	HL,(BASE)
	LD	DE,152
	ADD	HL,DE
	LD	(BASE),HL
	JP	D_W5
D_W16:	LD	HL,(BASE)
	LD	DE,-152
	ADD	HL,DE
	LD	(BASE),HL
	JP	D_W5
D_W19:	LD	HL,X
	BIT	0,(HL)
	JR	NZ,D_W23
	INC	(HL)
D_W23:	LD	A,(HL)
	SRL	A
	ADD	A,33
	LD	(0F3DDH),A
	CALL	D_WSUB
	CALL	9FH
	JP	D_W20
D_W21:	LD	HL,X
	BIT	0,(HL)
	JR	NZ,D_W22
	INC	(HL)
D_W22:	CALL	D_WSUB
	DEC	HL
	CALL	PEEK
	INC	HL
	JP	D_W20
D_W24:	LD	HL,0
	LD	(Y),HL
	JP	D_W3
D_W26   CALL    SOFSET
        JP      DUMPJ;D_W25
D_W15:	CALL	D_WSUB
	LD	(BASE),HL
	JP	D_W25
D_W30:	CALL	D_WSUB
	CALL	BUNKI
	JP	D_W9
D_W50:	LD	HL,0FFFFH
	LD	(ADXWK1),HL
	LD	HL,1
D_W53:	LD	(SRCHZ),HL
	LD	A,(FINDFG)
	OR	A
	JP	Z,D_W11
	CALL	D_WSUB
	LD	DE,(SRCHZ)
	ADD	HL,DE
	LD	(ADXWK0),HL
	INC	D
	JR	Z,D_W54
	LD	A,H
	OR	L
	JP	Z,D_W5
	JR	D_W55
D_W54:	LD	A,H
	AND	L
	CP	255
	JP	Z,D_W5
D_W55:	CALL	SEARCH
	JP	C,D_W5
	BIT	7,A
	JP	NZ,D_W5
	LD	(BASE),HL
	JP	D_W25
D_W52:	LD	HL,0
	LD	(ADXWK1),HL
	LD	HL,-1
	JR	D_W53
D_W51:	CALL	CLS
	CALL	FDATST
	JP	C,D_W25
	JR	D_W50
D_W70:	CALL	D_WSUB
	CALL	D_W_AS
	JP	D_W11

D_WSUB:	CALL	LACAL
	LD	IX,VWORK
	EX	DE,HL
	ADD	IX,DE
	LD	HL,(Y)
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	A,(X)
	SRL	A
	LD	D,0
	LD	E,A
	ADD	HL,DE
	LD	DE,(BASE)
	ADD	HL,DE
	RET

; ²Û²ÛË®³¼Þ
D_W_AS:	PUSH	HL
	CALL	SCRSAV
	LD	HL,0
	LD	BC,40*7
	LD	A,' '
	CALL	FILVRM
	LD	HL,40
	LD	BC,40
	LD	A,'-'
	CALL	FILVRM
	LD	HL,160
	LD	BC,40
	LD	A,'-'
	CALL	FILVRM
	LD	HL,280
	LD	BC,40
	LD	A,'-'
	CALL	FILVRM
	LD	HL,0103H
	LD	(0F3DCH),HL
	POP	HL
	PUSH	HL
	CALL	ADRSPR
	LD	HL,0106H
	LD	(0F3DCH),HL
	POP	HL
	CALL	ADRSPR
	PUSH	HL
	PUSH	HL
	CALL	PEEK
	LD	E,A
	INC	HL
	PUSH	DE
	CALL	PEEK
	POP	DE
	LD	D,A
	PUSH	DE
	LD	HL,0603H
	LD	(0F3DCH),HL
	LD	A,E
	CALL	DATPR
	LD	A,11
	LD	(0F3DDH),A
	LD	C,E
	CALL	BSOMP1
	LD	HL,0B04H
	LD	(0F3DCH),HL
	CALL	BSOMP2
	POP	DE
	LD	HL,0606H
	LD	(0F3DCH),HL
	LD	A,E
	CALL	DATPR
	LD	HL,0F3DDH
	LD	A,D
	CALL	DATPR
	INC	(HL)
	CALL	SOMPR1
	LD	HL,0B07H
	LD	(0F3DCH),HL
	CALL	SOMPR2
	POP	HL
	LD	IX,LWORK
	CALL	ADA
	LD	HL,LWORK
	LD	DE,0
	LD	BC,40
	CALL	LDIRVM
	POP	HL
	LD	(ADXWK0),HL
	CALL	JTNKRD
	LD	A,(TNKFG)
	OR	A
	JR	NZ,D_W_A2
D_W_A1:	CALL	9CH
	JR	Z,D_W_A1
	CALL	9FH
D_W_A2:	JP	SCRREM

BUNKI:	LD	(ADXWK0),HL
	LD	IX,BUNSUB
	CALL	P0CALL
BUNKI5:	CALL	9CH
	JR	Z,BUNKI5
	CALL	9FH
	CP	30
	JR	Z,BUNKI2
	CP	29
	JR	Z,BUNKI3
	CP	31
	JR	Z,BUNKI4
	CP	28
	JR	Z,BUNKI6
	CP	' '
	JR	Z,BUNKI7
	RET
BUNKI2:	POP	AF
	JP	DUMPJ
BUNKI3:	POP	AF
	JP	ASCIIJ
BUNKI4:	POP	AF
	JP	DISASJ
BUNKI6:	POP	AF
	LD	HL,1*256+20
	LD	(0F3DCH),HL
	JP	MULTIJ
BUNKI7:	POP	AF
	JP	CHARAJ

; ÀÞÝÌß
DUMP:	CALL	SUBMAN
DUMPJ:	CALL	ADRSAV
	PUSH	HL
	LD	HL,STDUMP
	LD	IX,MAKSLA
	CALL	P0CALL
	POP	HL
	LD	A,(SFXWK1)
	OR	A
	JP	Z,D_W
DUMP2:	CALL	ADUMP
	LD	(ADSAV0),HL
	CALL	STOP
	JR	NZ,DUMP3
	JP	SYSTEM
DUMP3:	LD	A,(SAMEFG)
	OR	A
	JR	Z,DUMP2
	JP	SYSTEM

; ±½·°ÀÞÝÌß
ASCII:	CALL	SUBMAN
ASCIIJ:	CALL	ADRSAV
	PUSH	HL
	LD	HL,STASCI
	LD	IX,MAKSLA
	CALL	P0CALL
	POP	HL
	LD	A,(SFXWK1)
	OR	A
	JP	Z,A_W
ASCII1:	LD	B,32
	CALL	ASDMP
	LD	(ADSAV0),HL
	CALL	STOP
	JR	NZ,ASCII2
	JP	SYSTEM
ASCII2:	LD	A,(SAMEFG)
	OR	A
	JR	Z,ASCII1
	JP	SYSTEM

; ÃÞ¨½±¾ÝÌÞ×
DISASM:	CALL	SUBMAN
DISASJ:	CALL	ADRSAV
	PUSH	HL
	LD	HL,STDISA
	LD	IX,MAKSLA
	CALL	P0CALL
	POP	HL
	LD	A,(SFXWK1)
	OR	A
	JP	Z,DA
DISAS1:	CALL	ADISAS
	CALL	STOP
	JR	NZ,DISAS2
	JP	SYSTEM
DISAS2:	LD	A,(SAMEFG)
	OR	A
	JR	Z,DISAS1
	JP	SYSTEM

; ·¬×¸À
CHARA:	CALL	SUBMAN
CHARAJ:	CALL	ADRSAV
	PUSH	HL
	LD	HL,STCHRA
	LD	IX,MAKSLA
	CALL	P0CALL
	POP	HL
	LD	A,(SFXWK1)
	OR	A
	JP	Z,C_W
CHARA1:	CALL	ACHA
	CALL	STOP
	JR	NZ,CHARA2
	JP	SYSTEM
CHARA2:	LD	A,(SAMEFG)
	OR	A
	JR	Z,CHARA1
	JP	SYSTEM

; ÏÙÁ×²Ã¨Ý¸Þ
MULTI:	CALL	SUB100
	XOR	A
	LD	(SFXWK1),A
MULTIJ:	CALL	CLS
	CALL	NOTPRN
MULTI3:	CALL	ADRSAV
	LD	HL,STMLTI
	LD	IX,MAKSLA
	CALL	P0CALL
	LD	HL,(ADXWK0)
	CALL	ADRSPR
	CALL	ONEPUT
	CALL	156H
	CALL	INLIN
	JP	C,SYSTEM
MULTI2:	LD	IX,NALBIG
	CALL	P0CALL
	INC	HL
	LD	A,(HL)
	OR	A
	JR	Z,MULI10
	LD	IX,ADRES
	CALL	P0CALL
	JR	NC,MULTI4
MULTI7:	LD	HL,STR34
	CALL	PRINT
	CALL	CRLF
	CALL	BEEP
	JR	MULTI3
MULTI4:
	LD	(ADXWK0),DE
	LD	(SLXWK0),BC
        LD	A,(HL)
	OR	A
	JR	Z,MULI10
	INC	HL

	LD	A,(HL)
	CP	'I'
	CALL	Z,MULI11

	CALL	NZ,MLCCK
	JR	C,MULTI7
	JP	MULTI3

MULI10:	CALL	SCRSAV
	LD	HL,(ADXWK0)
	CALL	BUNKI
	CALL	SCRREM
	JP	MULTI3


;------------------------------

MULI11:
	INC	HL
	LD	A,(HL)
	DEC	HL
	OR	A
	PUSH	AF
	LD	DE,20
	JR	Z,MULI13
	PUSH	HL
	INC	HL
	CALL	CVAL
	POP	HL
	JR	NC,MULI13
	POP	AF
	RET	

MULI13:
	POP	AF
	LD 	A,D
	OR	A
	JP	NZ,MULI15
	LD	B,E

MULI14:
	PUSH	HL
	PUSH	BC
	LD	HL,(ADXWK0)
	LD	IX,LWORK
	CALL	ADA
	PUSH	HL
	PUSH	DE
	LD	HL,(ADXWK0)
	CALL	ADRSPR
	CALL	ONEPUT
	LD	HL,LWORK+19
	LD	B,40-19
MULI12:	LD	A,(HL)
	INC	HL
	CP	' '
	JR	NZ,MULI16
	DEC	B
	CP	(HL)
	JR	Z,MULI12
	INC	B
MULI16:
	CALL	CHPUT
	DJNZ	MULI12
	CALL	NCRLF
	POP	DE
	POP	HL
	LD	(ADXWK0),HL
	POP	BC
	POP	HL
	DJNZ	MULI14
	XOR	A
	RET
MULI15:
	XOR	A
	SCF
	RET
	

; Add comment to begining of file (;XXXXH-YYYYH)
COMENT:	LD	HL,LWORK
	LD	(HL),';'
	INC	HL
	PUSH	HL
	POP	IX
COMET1:	LD	HL,(ADXWK0)
	CALL	ADRSIN
	LD	(IX),'H'
	INC	IX
	LD	(IX),'-'
	INC	IX
	LD	HL,(ADXWK1)
	CALL	ADRSIN
	LD	(IX),'H'
	LD	(IX+1),0
	LD	HL,LWORK
	JP	LOUT

; AÉÃÞ°À > 0A0H Å×(IX)Æ '0'¦ ²ÚÙ
MOJIHD:	PUSH	AF
	AND	0F0H
	CP	0A0H
	JR	C,MOJHD1
	LD	(IX),'0'
	INC	IX
MOJHD1:	POP	AF
	RET

; HLÉÓ¼ÞÚÂ¦(IX)Æ²ÚÙ
STRIN:	LD	A,(HL)
	CP	'$'
	RET	Z
	LD	(IX),A
	INC	HL
	INC	IX
	JR	STRIN

; ½°Êß°ÃÞ¨½±¾ÝÌÞ×
SPDISA:	
	CALL	FLNAME
	CALL	BUNCON
        CALL	SUB200
	LD	A,(HL)
	OR	A
	JP	Z,SPDS17
	CALL	BUNCON
	LD	A,(HL)
        CP      'X'
        JP      Z,SPDS24
	CP	'B'
	JR	Z,SPDS18
	CP	'D'
	JP	NZ,ERROR
	; BASIC DATA
	CALL	SVOPEN
	LD	HL,STR108
	LD	IX,LWORK
	CALL	STRIN
	CALL	COMET1
	LD	IY,DDATA
	LD	HL,10001
	LD	(ADXWK2),HL
	JR	SPDS21
        ; XBASIC type
SPDS24:	CALL	SVOPEN
	LD	HL,STR108
	LD	IX,LWORK
	CALL	STRIN
	CALL	COMET1
	LD	IY,DXBAS
	LD	HL,10001
	LD	(ADXWK2),HL
	JR	SPDS21
	; Assembler type
SPDS18:	CALL	SVOPEN
	CALL	COMENT
	LD	IY,DDEFB
SPDS21:	LD	IX,VWORK
	BIT	0,(IY+3)
	JR	NZ,SPDS22
	LD	HL,(ADXWK2)
	PUSH	HL
	PUSH	IY
	CALL	DECSUB
	POP	IY
	POP	HL
	INC	HL
	LD	(ADXWK2),HL
	LD	(IX),' '
	INC	IX
SPDS22:	LD	L,(IY)
	LD	H,(IY+1)
	CALL	STRIN
	LD	B,(IY+2)
SPDS20:	LD	HL,(ADXWK0)
	PUSH	BC
	CALL	PEEK
	INC	HL
	LD	(ADXWK0),HL

	BIT	0,(IY+3)
	PUSH	AF
	CALL	NZ,MOJIHD
        BIT     2,(IY+3)
        JR      Z,SPDS25
        LD      (IX),"&"
        INC     IX
        LD      (IX),"H"
        INC     IX
SPDS25:
	CALL	DATIN
	POP	AF
	JR	Z,SPDS23
	LD	(IX),'H'
	INC	IX

SPDS23:	LD	DE,(ADXWK1)
	INC	DE
	RST	20H
	LD	C,0
	JR	Z,SPDS19
	POP	BC
	DEC	B
	LD	C,1
	JR	Z,SPDS19
	BIT	1,(IY+3)
	JR	Z,SPDS20
	LD	(IX),','
	INC	IX
	JR	SPDS20
SPDS19:	LD	(IX),0
	LD	HL,VWORK
	PUSH	BC
	PUSH	IY
	LD	B,0
	CALL	LOUT3
	POP	IY
	POP	BC
	DEC	C
	JP	Z,SPDS21
	POP	BC
	CALL	CLOSE
	JP	COMPLT
SPDS17:	CALL	SVOPEN
	LD	HL,4000H
	LD	BC,4000H
	LD	A,0
	CALL	FILVRM
	LD	HL,STR99
	CALL	PRINT
	LD	HL,(ADXWK0)
	LD	(ADXWK2),HL    ; Start addr: ADXWK2, END: ADXWK1


        DEC     HL             ; No EQU before start
	CALL	CLLABL         ;/8
	LD	DE,6000H
	ADD	HL,DE
	CALL	RDVRM
	OR	B
	CALL	WRTVRM

SPDIS2:	LD	HL,(ADXWK0)
	LD	IX,LWORK
	PUSH	HL
	CALL	ADA
	LD	(ADXWK0),HL
	POP	HL
	CALL	CLLABL   ;/8
	LD	DE,6000H      ; #6000-#7FFF Command start flags
	ADD	HL,DE
	CALL	RDVRM
	OR	B
	CALL	WRTVRM
	CALL	SPASUB        ; Search address
	JR	C,SPDIS1
	EX	DE,HL
	LD	DE,(ADXWK2)
	RST	20H
	JR	C,SPDIS1
	LD	DE,(ADXWK1)
	INC	DE
	LD	A,D
	OR	E
	JR	Z,SPDIS3
	RST	20H
	JR	NC,SPDIS1
SPDIS3:	CALL	CLLABL
	LD	DE,4000H      ; #4000-#5FFF Put label flag
	ADD	HL,DE
	CALL	RDVRM
	OR	B
	CALL	WRTVRM
SPDIS1:	LD	A,(SAMEFG)
	OR	A
	JP	Z,SPDIS2

	LD	HL,STR100
	CALL	PRINT
	XOR	A
	LD	(SAMEFG),A
	LD	HL,(ADXWK2)
	LD	(ADXWK0),HL
	CALL	COMENT

	; ORG routine can be added here if wanted

SPDS12:	LD	HL,(ADXWK0)

        LD A,1
        LD (SLXWK2),A
SPDS13:
        DEC HL
        PUSH HL
        CALL	CLLABL          ; Check previous command flag
	LD	DE,6000H
	ADD	HL,DE
	CALL	RDVRM
	AND	B
        POP HL

        JR NZ, SPDS28           ; No need for prev label
        
        PUSH HL
        CALL	CLLABL          ; Check also label flag
	LD	DE,4000H
	ADD	HL,DE
	CALL	RDVRM
	LD      C,A
	AND	B
        JP NZ, SPDS27           ; Yes, do EQU $-X (POP HL)
        POP HL

        LD A,(SLXWK2)
        INC A
        LD (SLXWK2),A
        CP 4
        JR NZ, SPDS13            ; No prev label inside range

SPDS28:
        LD	HL,(ADXWK0)
        PUSH    HL
        CALL	CLLABL          ; Check label flag
	LD	DE,4000H
	ADD	HL,DE
	CALL	RDVRM
	AND	B
        POP     HL
 	LD	IY,VWORK
        JR      Z,SPDIS4

	LD	IX,VWORK+1     ; Put label in front of command
	LD	(IY),'X'
	LD	HL,(ADXWK0)
	CALL	ADRSIN

        LD	(IX),':'

	LD	IY,VWORK+6

SPDIS4:	LD	(IY),9
	INC	IY
	LD	HL,(ADXWK0)
	LD	IX,LWORK
	PUSH	IY
	CALL	ADA
	LD	(ADXWK0),HL
	POP	IY
	LD	HL,LWORK+19
SPDIS6:	LD	A,(HL)
	OR	A
	JP	Z,SPDIS7
	CP	' '
	JR	Z,SPDIS5
	LD	(IY),A
	INC	IY
	INC	HL
	JR	SPDIS6
SPDIS5:	LD	(IY),9
	INC	IY
	LD	HL,LWORK+26
SPDIS8:	LD	A,(HL)
	OR	A
	JP	Z,SPDIS7
	CP	'0'
	JR	C,SPDIS9
	CP	'9'+1
	JR	C,SPDS10
SPDIS9:	LD	(IY),A
	INC	IY
	INC	HL
	JR	SPDIS8
SPDS10:	PUSH	HL
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	LD	A,(HL)
	CP	'H'
	DEC	HL
	DEC	HL
	DEC	HL
	JR	NZ,SPDS16
	DEC	HL
SPDS16:	LD	DE,ADINWK
	LD	BC,4
	LDIR
	LD	B,4
	CALL	THEX
	JR	NC,SPDS11
	POP	HL
	LD	A,(HL)
	JR	SPDIS9
SPDS11:	PUSH	HL
        LD      DE,(ADXWK2)       ; Check if inside disasm block
        RST     20H
        JR      C,SPDS26
        LD      DE,(ADXWK1)
        INC     DE
        RST     20H
        JR      C,SPDS14
SPDS26: POP	HL
	POP	HL
SPDS15:	LD	A,(HL)
	LD	(IY),A
	INC	IY
	INC	HL
	CP	'H'
	JR	Z,SPDIS8
	JR	SPDS15
SPDS14:	POP	HL
	LD	(IY),'X'          ;Inside command
	INC	IY
	PUSH	IY
	POP	IX
	CALL	ADRSIN
	PUSH	IX
	POP	IY
	POP	HL
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	INC	HL
        LD      A,(HL)
        CP      'H'
        JR      NZ,SPDIS8
        INC     HL
        JR      SPDIS8


SPDS27:
	LD      A,C
	XOR	B      ; Reset flag
	CALL	WRTVRM
	POP HL

	LD	IX,VWORK
	LD	(IX),'X'
	INC     IX
	LD	HL,(ADXWK0)

	XOR     A
	LD      D,A
	LD      A,(SLXWK2)
	LD      E,A
	SBC     HL,DE

	CALL	ADRSIN
        LD	(IX),':'

	LD	HL,VWORK+6
        LD	(HL),9
	INC	HL
	LD      (HL),"E"
	INC	HL
	LD      (HL),"Q"
	INC	HL
	LD      (HL),"U"
	INC	HL
	LD      (HL),9
	INC	HL
	LD      (HL),"$"
	INC	HL
	LD      (HL),"-"
	INC	HL
	LD      A,(SLXWK2)
	ADD     A,"0"
	LD      (HL),A
        INC     HL
        PUSH HL
        POP IY

SPDIS7:	LD	(IY),0
	LD	HL,VWORK
	CALL	LOUT
	LD	A,(SAMEFG)
	OR	A
	JP	Z,SPDS12
	LD	HL,LWORK
;	PUSH	HL
;	LD	(HL),13
;	INC	HL
;	LD	(HL),10
;	INC	HL
;	LD	(HL),9
;	INC	HL
;	LD	(HL),'E'
;	INC	HL
;	LD	(HL),'N'
;	INC	HL
;	LD	(HL),'D'
;	INC	HL
	LD	(HL),0
;	POP	HL
	CALL	LOUT
	CALL	CLOSE
	JP	COMPLT

; HLÉ ×ÍÞÙÌ×¸ÞÃ°ÌÞÙ¦ HLÄBÆ ´Ù
CLLABL:	LD	DE,8
	CALL	DIV	
	PUSH	IX
	POP	BC
	INC	B
CLLAB2:	INC	C
	DEC	C
	JR	Z,CLLAB1
	SLA	B
	DEC	C
	JR	CLLAB2
CLLAB1:	RET

; Search back for address
SPASUB:	LD	B,20
	LD	HL,LWORK+39
SPASB2:	LD	A,(HL)
	CP	'H'
	JR	Z,SPASB1
SPASB3:	DEC	HL
	DJNZ	SPASB2
	SCF
	RET
SPASB1:	PUSH	BC
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	DE,ADINWK
	LD	BC,4
	LDIR
	LD	B,4
	CALL	THEX
	EX	DE,HL
	POP	HL
	POP	BC
	JR	C,SPASB3
	RET
CLCLS:
	CALL	CLS
	JP	SYSTEM

SOFSET:
        LD      HL,(BASE)
        LD      DE,(OFFSET)
        LD      A,D
        OR      E
        JR      Z,SOFSET2
        LD      (POFSET),DE
        ADD     HL,DE ; Don't move
        LD      (ADXWK0),HL
        LD      DE,0
        LD      (OFFSET),DE
        JP      BEEP
SOFSET2:
        LD      DE,(POFSET)
        LD      (OFFSET),DE
        XOR     A
        SBC     HL,DE
        LD      (ADXWK0),HL
        JP      BEEP

; ¹²»Ý
CALC:	LD	A,(HL)
	CP	'S'	;CLS
	JR	Z,CLCLS

	CALL	CVAL
	JP	C,ERROR
	CALL	BUNMAT
CALC4:	CALL	SOMEPR
	JP	SYSTEM

; Ï¼ÝÁª¯¸
CHECK:	CALL	BUNMAT
	LD	DE,NWSLTP
	LD	BC,NWSLEN-NWSLTP
	LD	IX,CMTRNS
	CALL	P0CALL
	CALL	VWORK
	JP	SYSTEM

; ÌÞÛ¯¸ÃÝ¿³
TRANS:	CALL	TRANS3
	JP	COMPLT

TRANS3:	CALL	SUB300
	CALL	BUNMAT
	LD	HL,(ADXWK2)
	LD	(WORK),HL;ÃÝ¿³»·¾ÝÄ³
	PUSH	HL
	LD	HL,(ADXWK1)
	LD	(WORK+8),HL;ÃÝ¿³ÓÄ»²ºÞ
	LD	DE,(ADXWK0)
	OR	A
	SBC	HL,DE
	POP	DE
	ADD	HL,DE
	JP	C,ERROR
	LD	(WORK+2),HL;ÃÝ¿³»·»²ºÞ
	LD	HL,(ADXWK2)
	LD	DE,(ADXWK0)
	OR	A
	SBC	HL,DE
	LD	(WORK+4),HL;ÍÝ²
	LD	HL,(ADXWK0)
	LD	(WORK+6),HL;ÃÝ¿³ÓÄ¾ÝÄ³
	LD	DE,(ADXWK2)
	RST	20H
	JR	C,TRANS2
	LD	BC,1
	JR	TRANS1
TRANS2:	PUSH	DE
	LD	DE,(ADXWK1)
	LD	(ADXWK1),HL
	LD	(ADXWK0),DE
	EX	DE,HL
	OR	A
	SBC	HL,DE
	POP	DE
	ADD	HL,DE
	LD	(ADXWK2),HL
	LD	BC,-1
TRANS1:	LD	HL,(SLXWK1)
	LD	(SLXWK0),HL
	LD	HL,(ADXWK0)
	PUSH	BC
	CALL	PEEK
	POP	BC
	LD	HL,(SLXWK2)
	LD	(SLXWK0),HL
	LD	HL,(ADXWK2)
	LD	E,A
	PUSH	BC
	CALL	POKE
	POP	BC
	ADD	HL,BC
	LD	(ADXWK2),HL
	LD	HL,(ADXWK0)
	ADD	HL,BC
	LD	(ADXWK0),HL
	OR	A
	SBC	HL,BC
	LD	DE,(ADXWK1)
	OR	A
	SBC	HL,DE
	JP	NZ,TRANS1
	RET

; ºÝÍß± »ÌÞ
MEMCSB:	PUSH	BC
	CALL	ADPRSL
	POP	BC
	LD	A,'='
	CALL	CHPUT
	LD	A,B
	CALL	DATPR
	LD	A,':'
	CALL	CHPUT
	LD	A,B
	JP	MOJIPR

; Ï¯Êß¿³»
MAPPER:	LD	A,(MAPFG)
	OR	A
	JR	NZ,MAPER1
	LD	HL,STR69
	CALL	PRINT
	JP	SYSTEM
MAPER1:	LD	A,(HL)
	OR	A
	JR	NZ,MAPER3
	CALL	MAPNEW
	LD	HL,STR70
	CALL	NPRINT
	CALL	NCRLF
	CALL	MAPPR
	JP	SYSTEM
MAPER3:	PUSH	HL
	LD	HL,(MAPJP)
	LD	DE,12H
	ADD	HL,DE
	LD	(MAPER2),HL
	POP	DE
	LD	A,(DE)
	SUB	'0'
	CP	4
	JP	NC,ERROR
	PUSH	AF
	EX	DE,HL
	INC	HL
	CALL	BUNCON
	CALL	CVAL
	JP	C,ERROR
	LD	A,D
	OR	A
	JP	NZ,ERROR
	POP	AF
	CP	2
	JR	C,MAPER4
	RRCA
	RRCA
	LD	H,A
	LD	A,E
	DEFB 0CDH
MAPER2:	DEFS 2
MAPER4:	CALL	MAPPR
	JP	SYSTEM

; ¹Ý»¸
FIND:	CALL	SUB200
	CALL	BUNMAT
	CALL	FDATST
	JP	C,BREAK
	LD	HL,0
	LD	(WORK),HL
	LD	(WORK+2),HL
FIND5:	LD	HL,1
	LD	(SRCHZ),HL
	CALL	SEARCH
	JP	C,FIND6
	BIT	7,A
	JP	NZ,BREAK
	CALL	ADRSPR
	LD	HL,(WORK)
	INC	HL
	LD	(WORK),HL
	CALL	ONEPUT
	LD	A,9
	CALL	0A2H
	LD	A,(WORK+2)
	INC	A
	CP	5
	JR	NZ,FIND3
	CALL	PCRLF
	LD	A,(WORK+3)
	INC	A
	CP	20
	JR	NZ,FIND4
	CALL	STOP2
	JP	Z,BREAK
	CALL	CRLF
	XOR	A
FIND4:	LD	(WORK+3),A
	XOR	A
FIND3:	LD	(WORK+2),A
FIND1:	CALL	STOP
	JP	Z,BREAK
	LD	HL,(ADXWK0)
	LD	DE,(ADXWK1)
	RST	20H
	JR	Z,FIND6
	INC	HL
	LD	(ADXWK0),HL
	JP	FIND5
FIND6:	LD	HL,(WORK)
	LD	A,H
	OR	L
	JR	Z,FIND7
	CALL	NCRLF
	CALL	DECPR
	LD	HL,STR55
FIND8:	CALL	NPRINT
	JP	SYSTEM
FIND7:	LD	HL,STR56
	JR	FIND8

; Ú¼Þ½À¿³»
RESIST:	LD	A,(HL)
	OR	A
	JP	Z,REST12
	CP	'*'
	JR	NZ,REST18
	INC	HL
	CALL	BUNMAT
	LD	HL,STR82
	CALL	NPRINT
	LD	HL,RESAVE
	LD	DE,RESAVE+1
	LD	BC,23
	LD	(HL),0
	LDIR
	JP	REST12
REST18:	CP	'+'
	JR	NZ,REST21
	INC	HL
	CALL	BUNMAT
	LD	HL,STR102
	CALL	NPRINT
	LD	HL,(STACK)
	LD	(RESAVE+24),HL
	JP	REST12
REST21:	LD	IY,REDATA
	PUSH	HL
	EXX
	POP	IX
REST10:	LD	A,(IY)
	CP	'$'
	JP	Z,ERROR
	CP	(IX)
	JP	NZ,REST11
	LD	A,(IY+1)
	OR	A
	JR	Z,REST15
	SUB	(IX+1)
	JR	NZ,REST11
	LD	A,(IY+2)
	OR	A
	JR	Z,RESIT9
	SUB	(IX+2)
	JR	Z,REST20
REST11:	LD	BC,5
	ADD	IY,BC
	JR	REST10
REST15:	LD	A,1
	LD	(WORK),A
	EXX
	JR	REST16
REST20:	LD	A,1
	LD	(WORK),A
	EXX
	INC	HL
	INC	HL
	JR	REST16
RESIT9:	XOR	A
	LD	(WORK),A
	EXX
	INC	HL
REST16:	LD	E,(IY+3)
	LD	D,(IY+4)
	EX	DE,HL
	INC	DE
	PUSH	DE
	LD	DE,RESAVE+16
	RST	20H
	POP	DE
	PUSH	HL
	POP	IX
	JR	NC,RESIT8
RESIT7:	LD	A,(DE)
	CP	"'"
	JR	NZ,RESIT8
	INC	DE
	INC	IX
	INC	IX
RESIT8:	LD	A,(DE)
	CP	' '
	JR	REST40
	CP	','
	JP	NZ,ERROR
REST40:	INC	DE
	EX	DE,HL
	PUSH	IX
	CALL	CVAL
	JP	C,ERROR
	CALL	BUNMAT
	POP	IX
	LD	A,(WORK)
	OR	A
	JR	NZ,REST17
	LD	(IX+1),D
REST17:	LD	(IX),E
REST12:	LD	HL,(RESAVE+24)
	LD	DE,80FFH
	RST	20H
	JR	NC,REST30
	LD	HL,80FFH
	LD	(RESAVE+24),HL
REST30:	CALL	RESPR
	JP	SYSTEM

; Ú¼Þ½À Ë®³¼Þ
RESPR:	LD	A,(CRTOFF)
	OR	A
	JR	NZ,RESPR3
	LD	A,(0F3AEH)
	CP	40
	CALL	NZ,SCREEN
	LD	A,(0FCAFH)
	OR	A
	CALL	NZ,SCREEN
	LD	A,(0F3DDH)
	DEC	A
	CALL	NZ,CRLF
RESPR3:	LD	HL,STR80
	CALL	NPRINT
	LD	IX,RESAVE
	LD	L,(IX)
	LD	H,(IX+1)
	CALL	ADRONE
	LD	L,(IX+4)
	LD	H,(IX+5)
	CALL	ADRONE
	LD	L,(IX+8)
	LD	H,(IX+9)
	CALL	ADRONE
	LD	L,(IX+12)
	LD	H,(IX+13)
	CALL	ADRONE
	LD	L,(IX+16)
	LD	H,(IX+17)
	CALL	ADRONE
	LD	L,(IX+18)
	LD	H,(IX+19)
	CALL	ADRONE
	LD	L,(IX+24)
	LD	H,(IX+25)
	CALL	ADRONE
	LD	L,(IX+20)
	LD	H,(IX+21)
	CALL	ADRONE
	CALL	NCRLF
	LD	HL,STR81
	CALL	NPRINT
	LD	L,(IX+2)
	LD	H,(IX+3)
	CALL	ADRONE
	LD	L,(IX+6)
	LD	H,(IX+7)
	CALL	ADRONE
	LD	L,(IX+10)
	LD	H,(IX+11)
	CALL	ADRONE
	LD	L,(IX+14)
	LD	H,(IX+15)
	CALL	ADRONE
	LD	L,(IX+22)
	LD	H,(IX+23)
	CALL	ADRONE
	LD	B,8
	LD	A,80H
RESPR2:	LD	C,'0'
	PUSH	AF
	AND	(IX)
	JR	Z,RESPR1
	INC	C
RESPR1:	LD	A,C
	CALL	CHPUT
	POP	AF
	SRL	A
	DJNZ	RESPR2
	JP	NCRLF
ADRONE:	CALL	ADRSPR
	JP	ONEPUT

; ÄÚ°½
TRACE:	LD	A,(HL)
	OR	A
	JR	NZ,TRAC18
	XOR	A
	LD	(SFXWK0),A
	LD	HL,(RESAVE+20)
	LD	(ADXWK0),HL
	JR	TRAC17
TRAC18:	CALL	SUB100
	LD	A,(SFXWK0)
	OR	A
	JP	NZ,ERROR
TRAC17:	CALL	ADRSAV
	LD	HL,TRCSTR
	LD	IX,MAKSLA
	CALL	P0CALL
	LD	A,(PRNFG)
	LD	(CRTOFF),A
	LD	HL,(ADXWK0)
	LD	(RESAVE+20),HL
TRACE2:	CALL	RESPR
	LD	HL,0
	LD	(TRACOC),HL
	LD	(TRACOC+2),HL
	LD	HL,(RESAVE+20)
	PUSH	HL
	CALL	ADISAS
	LD	(WORK),HL
	POP	HL
	LD	A,(OBYTE)
	LD	B,A
	LD	DE,TRACOC
TRACE1:	LD	A,(HL)
	LD	(DE),A
	INC	DE
	INC	HL
	DJNZ	TRACE1
TRAC16:	CALL	9FH
	CP	27
	JP	Z,SYSTEM
	CP	8
	JP	Z,SYSTEM
	CP	'?'
	JP	Z,TRAC15
	LD	B,A
	LD	HL,STR101
	CALL	NPRINT
	LD	HL,(WORK)
	LD	(RESAVE+20),HL
	LD	A,(POPDT)
	CP	2FH ;JP
	JR	Z,TRACE4
	CP	30H ;JR
	JR	Z,TRACE4
	CP	31H ;CALL
	JR	Z,TRAC10
	CP	33H ;RET
	JR	Z,TRAC11
	CP	32H ;DJNZ
	JR	Z,TRAC12
TRAC13:	CALL	RESGET
TRACOC:	DS 4
	LD	(RESAVE+24),SP
	CALL	RESCOP
	JR	TRACE2
TRACE4:	CALL	TRASUB
	JR	Z,TRACE5
	JR	NC,TRACE2
TRACE8:	CALL	SPASUB
TRACE9:	LD	(RESAVE+20),DE
	LD	(RESAVE+24),SP
	JR	TRACE2
TRACE5:	LD	A,(POPDT+1)
	CP	4CH ;(HL)
	JR	Z,TRACE6
	CP	7CH ;(IX)
	JR	Z,TRACE7
	CP	7DH ;(IY)
	JR	NZ,TRACE8
	LD	DE,(RESAVE+18)
	JR	TRACE9
TRACE6:	LD	DE,(RESAVE+12)
	JR	TRACE9
TRACE7:	LD	DE,(RESAVE+16)
	JR	TRACE9
TRAC10:	LD	A,B
	CP	13
	JR	NZ,TRAC14
	LD	HL,STR103
	CALL	NPRINT
	JR	TRAC13
TRAC14:	CALL	TRASUB
	JP	NC,TRACE2
	LD	HL,(RESAVE+20)
	PUSH	HL
	JR	TRACE8
TRAC11:	CALL	TRASUB
	JP	NC,TRACE2
	POP	DE
	JR	TRACE9
TRAC12:	LD	HL,RESAVE+5
	DEC	(HL)
	JR	NZ,TRACE8
	JP	TRACE2
TRAC15:	LD	A,(CRTOFF)
	OR	A
	JP	NZ,TRAC16
	CALL	SPASUB
	JP	C,TRAC16
	LD	(ADXWK0),DE
	CALL	DASUB
	JP	TRAC16

TRASUB:	LD	A,(POPDT+1)
	SUB	64H
	JR	C,TRASB2
	CP	8
	JR	NC,TRASB2
	LD	DE,FLAGTB
	LD	H,0
	LD	L,A
	ADD	HL,HL
	ADD	HL,DE
	LD	A,(HL)
	INC	HL
	OR	A
	LD	A,(RESAVE)
	JR	Z,TRASB1
	AND	(HL)
	JR	Z,TRASB3
	XOR	A
	INC	A
	RET
TRASB1:	AND	(HL)
	JR	NZ,TRASB3
	XOR	A
	INC	A
	RET
TRASB2:	XOR	A ;Z&Cf
	SCF
	RET
TRASB3:	XOR	A ;Cf
	INC	A
	SCF
	RET

FLAGTB:	DEFB 255,40H,255,1,255,4,255,80H,0,40H,0,1,0,4,0,80H

; ¼Þ¯º³
RUN:	CALL	SUB100
	LD	HL,(ADXWK0)
	LD	A,(SFXWK0)
	OR	A
	JR	Z,RUN1
	LD	A,(SLXWK0)
	CP	0FFH
	JP	Z,ERROR
	CALL	ERHKOF
	LD	(RUNDAT),A
	LD	(RUNDAT+1),HL
	CALL	RESGET
	RST	30H
RUNDAT:	DEFS	3
	CALL	RESCOP
RUN3:	EI
	CALL	ERHKST
	JP	REST12
RUN1:	CALL	ERHKOF
	LD	(RUNDT1+1),HL
	LD	HL,(RESAVE+22)
	LD	A,(HL)
	LD	(WORK),A
	LD	(HL),0DFH
	LD	HL,0FEE4H
	PUSH	HL
	LD	DE,HOOKS1
	LD	BC,5
	LDIR
	POP	DE
	LD	HL,TRAPJP
	LD	BC,3
	LDIR
	CALL	RESGET
RUNDT1:	DB 0CDH
	DS 2
	CALL	RESCOP
RUN4:	LD	A,(WORK)
	LD	HL,(RESAVE+22)
	LD	(HL),A
	LD	HL,HOOKS1
	LD	DE,0FEE4H
	LD	BC,5
	LDIR
	JR	RUN3
TRAP:	POP	AF
	POP	AF
	CALL	RESCOP
	POP	AF
	LD	(RESAVE+24),SP
	LD	HL,(RESAVE+22)
	LD	(RESAVE+20),HL
	JR	RUN4

TRAPJP:	JP	TRAP
HOOKS1:	DS 5

; Ú¼Þ½À¦ ¾°ÌÞ´Ø±Æ Î¿ÞÝ
RESCOP:	LD	(RESAVE+12),HL
	PUSH	AF
	POP	HL
	LD	(RESAVE),HL
	LD	(RESAVE+4),BC
	LD	(RESAVE+8),DE
	LD	(RESAVE+16),IX
	LD	(RESAVE+18),IY
	EXX
	EX	AF,AF'
	LD	(RESAVE+14),HL
	PUSH	AF
	POP	HL
	LD	(RESAVE+2),HL
	LD	(RESAVE+6),BC
	LD	(RESAVE+10),DE
	RET

; Ú¼Þ½À´Ø±¦ Ú¼Þ½ÀÆ ²ÚÙ
RESGET:	LD	HL,(RESAVE+2)
	PUSH	HL
	POP	AF
	LD	BC,(RESAVE+6)
	LD	DE,(RESAVE+10)
	LD	HL,(RESAVE+14)
	LD	IX,(RESAVE+16)
	LD	IY,(RESAVE+18)
	EXX
	EX	AF,AF'
	LD	HL,(RESAVE)
	PUSH	HL
	POP	AF
	LD	BC,(RESAVE+4)
	LD	DE,(RESAVE+8)
	LD	HL,(RESAVE+12)
	RET

; LOAD RAW FILE
SPLOAD:	CALL	FLNAME
	CALL	BUNCON
	LD	IX,ADRES
	CALL	P0CALL
	; Add Offset & Len code here
	CALL	BUNMAT
	
	CALL    SPLOD6
	JP      COMPLT

SPLOD6:	LD	(ADXWK0),DE
	LD	(SLXWK0),BC
	LD	(ADXWK1),DE
	CALL	LDOPEN
	LD	HL,(FCB+18)
	LD	A,H
	OR	L
	JR	Z,SPLOD7
	DEC	HL
	LD	A,H
	OR	L
	JP	NZ,ERROR5
	LD	HL,(FCB+16)
	LD	A,H
	OR	L
	JP	NZ,ERROR5
	LD	A,1
	LD	(CARFG),A
SPLOD7:	LD	HL,STR95
	CALL	NPRINT
	LD	HL,(FCB+16)
 	LD      (ADSAVS),HL
	CALL	ADRSPR
	PUSH	HL
	LD	HL,STR85
	CALL	NPRINT
	POP	HL
	; HL=LEN
SPLOD8:
	LD	DE,(ADXWK0)
	DEC	HL
	PUSH	HL
	ADD	HL,DE
	JP	C,ERROR5
	LD	BC,(SLXWK0)
	INC	B
	DEC	B
	JR	Z,SPLOD1
	LD	A,(0F344H)
	CP	C
	JR	NZ,SPLOD2
SPLOD1:	LD	BC,0FFH
	ADD	HL,BC
	JP	C,ERROR5
	SBC	HL,SP
	JP	NC,ERROR5
SPLOD2:	POP	HL
	LD	DE,256
	CALL	DIV
	LD	(WORK),HL
	LD	(WORK+1),IX
SPLOD3:	LD	A,(WORK)
	OR	A
	JR	Z,SPLOD5
	DEC	A
	LD	(WORK),A
	LD	DE,FCB
	LD	HL,256
	LD	C,27H
	CALL	SYSCAL
	LD	BC,256
	CALL	DMATRR
	JR	SPLOD3
SPLOD5:	LD	HL,(WORK+1)
	LD	H,0
	INC	HL
	PUSH	HL
	LD	DE,FCB
	LD	C,27H
	CALL	SYSCAL
	POP	BC
	CALL	DMATRR
	LD	HL,STR91
	CALL	NPRINT
	LD	HL,(ADXWK1)
	LD	DE,(SLXWK0)
        LD      (ADSAVB),HL
 	LD      (ADSAVB+2),DE
 	LD      (ADSAVE+2),DE
 	LD      (ADSAVS+2),DE
        CALL	ADPRSL
	LD	HL,STR92
	CALL	NPRINT
	LD	HL,(ADXWK0)
	DEC	HL
        LD      (ADSAVE),HL
	CALL	ADRSPR
	CALL	NCRLF
	;JP	COMPLT
        RET

; ½°Êß°¾°ÌÞ
SPSAVE:	CALL	FLNAME
	CALL	BUNCON
	CALL	SUB200
	CALL	BUNMAT
	LD	HL,(ADXWK1)
	LD	DE,(ADXWK0)
	OR	A
	SBC	HL,DE
	LD	DE,256
	CALL	DIV
	LD	(WORK),HL
	LD	(WORK+1),IX
	CALL	SVOPEN
SPSAV3:	LD	BC,256
	CALL	DMATRW
	LD	A,(WORK)
	OR	A
	JR	Z,SPSAV2
	DEC	A
	LD	(WORK),A
	LD	DE,FCB
	LD	HL,256
	LD	C,26H
	CALL	SYSCAL
	JR	SPSAV3
SPSAV2:	LD	HL,(WORK+1)
	LD	H,0
	INC	HL
	LD	DE,FCB
	LD	C,26H
	CALL	SYSCAL
	CALL	CLOSE
	JP	COMPLT

; ¶Ý¼Þ±½·°
KASCII:	CALL	SUB100
	CALL	KM
KASCI1:	LD	HL,(ADXWK0)
	CALL	PEEK
	LD	E,A
	INC	HL
	LD	(ADXWK0),HL
	LD	IX,KPRINT
	CALL	P0CALL
	CALL	STOP
	JR	Z,KTYPE3
	LD	A,(0F3DCH)
	CP	12
	JR	C,KASCI1
	CALL	KS
	JR	KASCI1

; ¶Ý¼ÞÀ²Ìß (v1.1)
KTYPE:	CALL	FLNAME
	CALL	LDOPEN
	CALL	KM
KTYPE1:	LD	C,27H
	LD	HL,1
	LD	DE,FCB
	CALL	0F37DH
	DEC	A
	JP	Z,KTYPE2
	LD	A,(DMA)
	CP	1AH
	JR	Z,KTYPE2
	LD	E,A
	LD	IX,KPRINT
	CALL	P0CALL
	CALL	STOP
	JR	Z,KTYPE3
	LD	A,(0F3DCH)
	CP	12
	JR	C,KTYPE1
	CALL	KS
	JR	KTYPE1
KTYPE2:	CALL	STOP2
KTYPE3:	CALL	VNOTCR
	JP	SYSTEM
KS:	CALL	STOP2
	JR	Z,KTYPE3
	LD	HL,0
	LD	(0F3DCH),HL
	LD	HL,0
	LD	BC,1800H
	XOR	A
	JP	FILVRM
	
; TYPE
TPTP:	CALL	FLNAME
	CALL	LDOPEN
TPTP1:	LD	C,27H
	LD	HL,1
	LD	DE,FCB
	CALL	0F37DH
	DEC	A
	JP	Z,SYSTEM
	LD	A,(DMA)
	CP	1AH
	JP	Z,SYSTEM
	LD	E,A
        CALL    CHPUT
	CALL	STOP
	JP	Z,SYSTEM
	JR	TPTP1
TPEN:


; ²ÝÃÞ¯¸½ÀÝ¸Áª¯¸
TNKRDX:	CALL	SUB100
	CALL	TNKRED
	CALL	SCRREM
	JP	SYSTEM

TNKRED:	CALL	SCRSAV
JTNKRD:	XOR	A
	LD	(TNKFG),A
	LD	BC,(TNKBYT)
	LD	HL,8000H
TNKRD2:	LD	A,B
	OR	C
	RET	Z
	PUSH	BC
	PUSH	HL
	LD	DE,TANKWK
	LD	BC,4
	CALL	LDIRMV
	LD	HL,(TANKWK)
	LD	DE,(ADXWK0)
	RST	20H
	JR	Z,TNKRD1
TNKRD5:	POP	HL
	POP	BC
	LD	DE,64
	ADD	HL,DE
	DEC	BC
	JR	TNKRD2
TNKRD1:	LD	A,255
	LD	(TNKFG),A
	LD	HL,(TANKWK)
	LD	(ADXWK0),HL
	LD	HL,(TANKWK+2)
	LD	(ADXWK1),HL
	POP	HL
	PUSH	HL
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	LD	DE,TANKWK+4
	LD	BC,60
	CALL	LDIRMV
	LD	IX,BOX
	CALL	P0CALL
	LD	IX,KIND
	CALL	P0CALL
	LD	HL,TANKWK+4
	LD	DE,13*40+13
	LD	B,5
TNKRD3:	PUSH	BC
	PUSH	HL
	PUSH	DE
	LD	BC,12
	CALL	LDIRVM
	POP	HL
	LD	BC,40
	ADD	HL,BC
	EX	DE,HL
	POP	HL
	LD	BC,12
	ADD	HL,BC
	POP	BC
	DJNZ	TNKRD3
TNKRD6:	CALL	9CH
	JR	Z,TNKRD6
	CALL	9FH
	CP	27
	JP	NZ,TNKRD5
	POP	HL
	POP	BC
	RET

; ²ÝÃÞ¯¸½ÀÝ¸ »¸¾²
TNKSET:	CALL	SUB101
	CALL	BUNCON
	CALL	CVAL
	INC	D
	DEC	D
	JP	NZ,ERROR
	LD	A,E
	CP	5
	JP	NC,ERROR
	LD	(ADXWK1),A
	CALL	BUNCON
	CALL	CVAL
	INC	D
	DEC	D
	JP	NZ,ERROR
	LD	A,E
	CP	8
	JP	NC,ERROR
	LD	(ADXWK1+1),A
	CALL	BUNMAT
	CALL	NOTPRN
	LD	HL,(TNKBYT)
	LD	DE,512
	OR	A
	SBC	HL,DE
	JR	C,TNKST2
	LD	HL,STR59
	CALL	PRINT
	JP	SYSTEM
TNKST2:	CALL	SCRSAV
	LD	IX,BOX
	CALL	P0CALL
	LD	IX,KIND
	CALL	P0CALL
	LD	HL,0
	LD	(TNK_Y),HL
TNKST5:	LD	A,(TNK_Y)
	ADD	A,14
	LD	(0F3DCH),A
	LD	A,(TNK_X)
	ADD	A,14
	LD	(0F3DDH),A
TNKST4:	CALL	9FH
	CP	28
	JR	Z,TNKST3
	CP	29
	JR	Z,TNKST6
	CP	30
	JR	Z,TNKST7
	CP	31
	JR	Z,TNKST8
	CP	13
	JR	Z,TNKST9
	CP	27
	JR	Z,TNKS10
	CP	32
	JR	C,TNKST4
	LD	HL,(TNK_Y)
	LD	H,0
	LD	DE,40
	PUSH	AF
	CALL	MULT
	POP	AF
	LD	DE,(TNK_X)
	LD	D,0
	ADD	HL,DE
	LD	DE,40*13+13
	ADD	HL,DE
	CALL	WRTVRM
TNKST3:	LD	HL,TNK_X
	LD	A,(HL)
	CP	11
	JR	Z,TNKS13
	INC	(HL)
	JR	TNKST5
TNKST6:	LD	HL,TNK_X
	LD	A,(HL)
	OR	A
	JR	Z,TNKS14
	DEC	(HL)
	JR	TNKST5
TNKS14:	LD	(HL),11
TNKST7:	LD	HL,TNK_Y
	LD	A,(HL)
	OR	A
	JR	Z,TNKS16
	DEC	(HL)
	JR	TNKST5
TNKS16:	LD	(HL),4
	JR	TNKST5
TNKS13:	LD	(HL),0
TNKST8:	LD	HL,TNK_Y
	LD	A,(HL)
	CP	4
	JR	Z,TNKS15
	INC	(HL)
	JR	TNKST5
TNKS15:	LD	(HL),0
	JR	TNKST5
TNKS10:	CALL	SCRREM
	JP	SYSTEM
TNKST9:	LD	HL,(ADXWK0)
	LD	(TANKWK),HL
	LD	HL,(ADXWK1)
	LD	(TANKWK+2),HL
	LD	B,5
	LD	HL,13*40+13
	LD	DE,TANKWK+4
TNKS12:	PUSH	BC
	PUSH	HL
	PUSH	DE
	LD	BC,12
	CALL	LDIRMV
	POP	HL
	LD	BC,12
	ADD	HL,BC
	EX	DE,HL
	POP	HL
	LD	BC,40
	ADD	HL,BC
	POP	BC
	DJNZ	TNKS12
	LD	HL,(TNKBYT)
	INC	HL
	LD	(TNKBYT),HL
	DEC	HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,8000H
	ADD	HL,DE
	EX	DE,HL
	LD	HL,TANKWK
	LD	BC,64
	CALL	LDIRVM
	JP	TNKS10

; CPUÁªÝ¼Þ
CHCPU:	LD	A,(2DH)
	CP	3
	JP	C,ERROR
	LD	A,(HL)
	OR	A
	JR	NZ,CHCPU1
	CALL	CHCPU5
CHCPU6:	CALL	NCRLF
	JP	SYSTEM
CHCPU5:	LD	HL,STR42
	CALL	NPRINT
CHCPU3:	CALL	183H
	OR	A
	JR	NZ,CHCPU2
	LD	HL,STR43E
	LD	A,6
	OUT	(0E4H),A
	IN	A,(0E5H)
	AND	40H
	JP	Z,NPRINT
	LD	HL,STR43
	JP	NPRINT
CHCPU2:	DEC	A
	JR	NZ,CHCPU4
	LD	HL,STR44
	JP	NPRINT
CHCPU4:	DEC	A
	JP	NZ,ERROR
	LD	HL,STR45
	JP	NPRINT
CHCPU1:	CALL	CVAL
	JP	C,ERROR
	CALL	BUNMAT
	INC	D
	DEC	D
	JP	NZ,ERROR
	LD	A,E
	CP	4
	JP	NC,ERROR
	PUSH	AF
	CALL	CHCPU5
	LD	HL,STR46
	CALL	NPRINT
	POP	AF
	PUSH	AF
	INC	A
	AND	3
	DEC	A
	SET	7,A
	CALL	180H
	POP 	AF
	CP	3 ;Z80 DRAM
	CALL	Z,CHCPU7
	CALL	CHCPU3
	JR	CHCPU6
CHCPU7:	LD	A,6
	OUT	(0E4H),A
	LD	A,20H
	OUT	(0E5H),A
	RET

; BASICLIST
BLIST:	LD	A,(HL)
	OR	A
	JR	Z,BLIST4
	CALL	CVAL
	JP	C,ERROR
	LD	(BLIST5+1),DE
	LD	HL,(0F676H)
BLIST6:	PUSH	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,B
	OR	C
	JP	Z,ERROR
BLIST5:	LD	HL,0
	RST	20H
	POP	HL
	JR	Z,BLIST2
	PUSH	BC
	POP	HL
	JR	BLIST6
BLIST4:	LD	HL,(0F676H)
BLIST2:	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,B
	OR	C
	JP	Z,SYSTEM
	PUSH	BC ;ØÝ¸
	PUSH	HL
	EX	DE,HL
	CALL	DECPR
	CALL	ONEPUT
	POP	HL
	LD	IX,5284H
	CALL	159H
	LD	HL,0F55EH
BLIST3:	LD	A,(HL)
	OR	A
	JR	Z,BLIST1
	CALL	CHPUT
	INC	HL
	JR	BLIST3
BLIST1:	CALL	NCRLF
	CALL	STOP
	JP	Z,BREAK
	POP	HL
	JR	BLIST2

;--- DATA/WORK AREA ---
STR00:	DEFM 'CHCPU'
	DEFB 0
STR01:	DEFM 'SYSTEM'
	DEFB 0
STR03:	DEFM '# Bad FAT$'
STR04:	DEFM '# Disk I/O err$'
STR05:	DEFM '# Disk offline$'
STR06:	DEFM '# Protected$'
STR07:	DEFM 'SLOT$'
STR08:	DEFM ':P$'
STR09:	DEFM 'VRAM$'
STR10:	DEFM 'SELECT$'
STR11:	DEFM 'RAM$'
STR12:	DEFM 'EXP$'
STR14:	DEFM 'X(P0-1):#$'
STR15:	DEFM ' MAIN-ROM(P0-1):#$'
STR16:	DEFM 'SUB-ROM(P0):#$'
STR17:	DEFM 'FDC-ROM(P1)$'
STR18:	DEFM 'DISK$'
STR19:	DEFM 'MAPPER SUPPORT=$'
STR20:	DEFM 'MAPPER RAM:$'
STR21:	DEFM 'SEG=0~$'
STR22:	DEFM 'MAPPER:$'
STR23:	DEFM 'STACK:$'
STR24:	DEFM 'SLOT:$'
STR25:	DEFM 'SELECT$'
STR26:	DEFM 'SUM:$'
STR27:	DEFM 'NORMAL$'
STR28:	DEFM '+ADR$'
STR29:  DEFM '0=$'
STR30:	DEFM '# STACK err$'
STR32:	DEFM '*****$'
STR33:	DEFM '[     :****:*]$'
STR34:	DEFM '# Error'
	DB 10,13,'$'
STR35:	DEFM '# Printer err$'
STR36:	DEFM '\>'
	DB 7,'$'
STR37:	DEFM '[____#_-_]$'
STR39:	DEFM 'P>>'
	DB 7,'$'
STR42:	DEFM 'CPU:$'
STR43:	DEFM 'Z80(ROM)$'
STR43E:	DEFM 'Z80(DRAM)$'
STR44:	DEFM 'R800(ROM)$'
STR45:	DEFM 'R800(DRAM)$'
STR46:	DEFM '-->$'
STR47:	DEFM '.,+-*/'; KEY1¥TYPE1
	DEFM '/*-+,.'; KEY1¥TYPE2
	DEFM ',.+*/-'; KEY2¥TYPE1
	DEFM '-/*+.,'; KEY2¥TYPE2
STR49:	DEFM ' !"#$%&()*+,-./:;<=>?@[\]^X`{|}~'
	DB 0
STR50:	DEFM '+-*/%&|^'
STR52:	DEFM '>>Ok!$'
STR53:	DEFM 'Search data:'
	DB 10,13,'$'
STR54:	DEFM '-->$'
STR55:	DEFM 'point(s) found'
	DB 10,13,'$'
STR56:	DEFM '# Not found'
	DB 10,13,'$'
STR57:	DEFM 'line(s) found'
	DB 10,13,'$'
STR59:	DEFM '# TANK full$'
STR63:	DEFM 'HEX:$'
STR64:	DEFM '  BIN:$'
STR65:	DEFM 'DEC(+):$'
STR66:	DEFM '  DEC(+-):$'
STR67:	DEFM ' = $'
STR68:	DEFM ' <> $'
STR69:	DEFM '# No support$'
STR70:	DEFM 'o Map. restore$'
STR72:	DEFM 'Start:$'
STR73:	DEFM ' End:$'
STR74:	DEFM ' Exec:$'
STR76:	DEFM 'DRIVE$'
STR77:	DEFM '# File not found$'
STR78:	DEFM 'file(s) found'
	DEFB 10,13,'$'
STR80:	DEFM ' AF   BC   DE   HL   IX   IY   SP   PC'
	DEFB 10,13,'$'
STR81:	DEFM " AF'  BC'  DE'  HL'  BP  SZ*H*VNC"
	DEFB 10,13,'$'
STR82:	DEFM 'o Reg. clear'
	DEFB 10,13,'$'
STR83:	DEFM '# Too big$'
STR85:	DEFM 'H byte(s)'
	DEFB 10,13,'$'
STR91:	DEFM 'ADR:from $'
STR92:	DEFM ' to $'
STR95:	DEFM 'Size:$'
STR96:	DEFM '-->AGAIN'
	DB 10,13,'$'
STR98:	DEFM '- Break -$'
STR99:	DEFM 'Labeling $'
STR100:	DEFM '/ Writing !$'
STR103:	DEFM '[CALL]'
	DEFB 10,13
STR101:	DEFM '--------'
	DEFB 10,13,'$'
STR102:	DEFM 'o STACK restore'
	DEFB 10,13,'$'
STR104:	DEFM 'CLUSTER:$'
STR105:	DEFM '@$'
STR106:	DEFM 9,'DEFB $'
STR107:	DEFM 'DATA $'
STR108:	DEFM "10000 '$"
STR109: DEFM "'#I $"

DDEFB:	DW STR106
	DB 8,1+2
DDATA:	DW STR107
	DB 32,0
DXBAS:  DW STR109
	DB 13,2+4
;	   <data/line>,
;			bit0: SET = No Linenumbers, ASM outlook
;			bit1: SET = ","
;			bit2: SET = XBASIC (also bit 0=0)

CALCAD:	DEFW PLUS,NMNAS,MULT,DIV,MOD,CL_AND,CL_OR,CL_XOR

FONTDT:	DEFB 00,00,40H,0A8H,10H,0,0,0

TENSTR:	DEFM '.,+-*/'
TFILNM:	DEFM 'SUPER-X TNK'
KFILNM:	DEFM 'SUPER-X FNT'

ERHKDT:	RST	30H	;New´×°Ì¯¸
	DS	1
	DW	ERHOOK
ERHKSV:	DS 5	;´×°Ì¯¸ Î¿ÞÝ

HOOKDT:	JP	HOOK	;New²ÁÓ¼ÞÌ¯¸
HOOKSV:	DS 5	;1Ó¼ÞÌ¯¸ Î¿ÞÝ

; ÃÞ¨½¸´×° Ö³
ERRDAT:	DB 60
	DW STR03
	DB 69
	DW STR04
	DB 70
	DW STR05
	DB 68
	DW STR06

; ½³Á Ö³
KETA1:	DEFW 1H,10H,100H,1000H,0H
KETA2:	DEFW 1,10,100,1000,10000
KETA3:	DEFW 1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768

; ØÛ¹°À Ö³ ÃÞ°À
RELCDT:	DEFB 3AH,32H
	DEFB 01H,11H,21H,31H,2AH,22H
	DEFB 0C3H,0DAH,0D2H,0CAH,0C2H,0EAH,0E2H,0FAH,0F2H ;JP
	DEFB 0CDH,0DCH,0D4H,0CCH,0C4H,0ECH,0E4H,0FCH,0F4H,0 ;CALL
RELDT1:	DEFB 4BH,5BH,7BH,43H,53H,73H,0

; ºÏÝÄÞ
COMAND:	DB 'D',0
	DW DUMP
	DW 0,0

	DB 'A',0
	DW ASCII
	DW 0,0

	DB 'I',0
	DW DISASM
	DW 0,0

	DB 'M',0
	DW MULTI
	DW 0,0

	DB 'H',0
	DW CHARA
	DW 0,0

	DB 'QT'
	DW P0CM
	DW QTTP,QTEN-QTTP

	DB 'CU'
	DW CHCPU
	DW 0,0

	DB 'TK'
	DW P0CM
	DW TKTP,TKEN-TKTP

	DB 'CS'
	DW P0CM
	DW CSTP,CSEN-CSTP

	DB 'CL'
	DW CALC
	DW 0,0
	
	DB 'OF'
	DW P0CM
	DW OFTP,OFEN-OFTP

	DB 'FL'
	DW P0CM
	DW FLTP,FLEN-FLTP

	DB 'CK'
	DW CHECK
	DW 0,0

	DB 'TS'
	DW P0CM
	DW TSTP,TSEN-TSTP

	DB 'FD'
	DW FIND
	DW 0,0

	DB 'BF'
	DW P0CM
	DW BFTP,BFEN-BFTP

	DB 'BL'
	DW BLIST
	DW 0,0

	DB 'BT'
	DW TRANS
	DW 0,0

	DB 'CM'
	DW P0CM
	DW CMTP,CMEN-CMTP

	DB 'PP'
	DW MAPPER
	DW 0,0

	DB 'RG'
	DW RESIST
	DW 0,0

	DB 'GO'
	DW RUN
	DW 0,0

	DB 'RT'
	DW P0CM
	DW RTTP,RTEN-RTTP

	DB 'TR'
	DW TRACE
	DW 0,0

	DB 'CO'
	DW P0CM
	DW COTP,COEN-COTP

	DB 'iM'
	DW TNKSET
	DW 0,0

	DB 'iC'
	DW TNKRDX
	DW 0,0

	DB 'iS'
	DW P0CM
	DW ISTP,ISEN-ISTP

	DB 'iL'
	DW P0CM
	DW ILTP,ILEN-ILTP

	DB 'FS'
	DW P0CM
	DW FSTP,FSEN-FSTP

	DB 'CD'
	DW P0CM
	DW CDTP,CDEN-CDTP

	DB 'LD'
	DW P0CM
	DW LDTP,LDEN-LDTP

	DB 'L#'
	DW SPLOAD
	DW 0,0

	DB 'L%'
	DW P0CM
	DW SCLTP,SCLEN-SCLTP

	DB 'SV'
	DW P0CM
	DW SVTP,SVEN-SVTP

	DB 'S#'
	DW SPSAVE
	DW 0,0

	DB 'S%'
	DW P0CM
	DW SCSTP,SCSEN-SCSTP

	DB 'SD'
	DW SPDISA
	DW 0,0

	DB 'CI'
	DW P0CM
	DW CITP,CIEN-CITP

	;DB 'VR'
	DB '@',0
	DW P0CM
	DW VRTP,VREN-VRTP

	DB 'SF'
	DW P0CM
	DW SFTP,SFEN-SFTP

	DB 'KL'
	DW P0CM
	DW KLTP,KLEN-KLTP

	DB 'KT'
	DW KTYPE
	DW 0,0

	DB 'KR'
	DW KASCII
	DW 0,0

	DB 'PI'
	DW P0CM
	DW PITP,PIEN-PITP

	DB 'PO'
	DW P0CM
	DW POTP,POEN-POTP

	DB 'TP'
	DW TPTP
	DW 0,0

	DB 0	;ºÏÝÄÞÉ µÜØ

STDUMP:	DEFM 'DUMP$'
STASCI:	DEFM 'ASCII$'
STDISA:	DEFM 'DISAS$'
STMLTI:	DEFM 'MULTI$'
STCHRA:	DEFM 'CHARA$'
TRCSTR:	DEFM 'TRACE$'

; Ú¼Þ½ÀÉ ÃÞ°À
REDATA:	DB 'AF',0
	DW RESAVE
	DB 'BC',0
	DW RESAVE+4
	DB 'DE',0
	DW RESAVE+8
	DB 'HL',0
	DW RESAVE+12
	DB 'BP',0
	DW RESAVE+22
	DB 'A',0,0
	DW RESAVE+1
	DB 'F',0,0
	DW RESAVE+0
	DB 'B',0,0
	DW RESAVE+5
	DB 'C',0,0
	DW RESAVE+4
	DB 'D',0,0
	DW RESAVE+9
	DB 'E',0,0
	DW RESAVE+8
	DB 'H',0,0
	DW RESAVE+13
	DB 'L',0,0
	DW RESAVE+12
	DEFM 'IXH'
	DW RESAVE+17
	DEFM 'IXL'
	DW RESAVE+16
	DEFM 'IYH'
	DW RESAVE+19
	DEFM 'IYL'
	DW RESAVE+18
	DB 'IX',0
	DW RESAVE+16
	DB 'IY',0
	DW RESAVE+18
	DB 'SP',0
	DW RESAVE+24
	DB 'PC',0
	DW RESAVE+20
	DB '$'

STACK:	DS 2	;½À¯¸ Î¿ÞÝ
IXBRG:	DS 2	;IX¦ P0Æ ³¹ÜÀ½
PRNFG:	DS 1	;ÌßØÝÀÌ×¸Þ
SUMTYP:	DS 1	;»Ñ À²Ìß
OPNFG:	DS 1	;Ì§²Ù µ°ÌßÝ Ì×¸Þ
CARFG:	DS 1	;·¬Ø°
MAPFG:	DS 1	;Ï¯Êß Ì×¸Þ
MAPJP:	DS 2	;Ï¯Êß ±ÄÞÚ½
MAPWK:	DS 4	;Ï¯Êß Ü°¸
EXPTBL:	DEFS 4	;¶¸½Û¯ÄÉ ¶¸Á®³É ³Ñ
WORK:	DS 10	;Ü°¸1
SBWORK:	DS 12	;Ü°¸2
SBWOK1:	DS 8	;Ü°¸3
ASMWK:	DS 9	;±¾ÝÌÞ×Ö³Ü°¸1
ASMWK1:	DS 5	;±¾ÝÌÞ×Ö³Ü°¸2
RESAVE:	DS 26	;Ú¼Þ½À¾°ÌÞ´Ø±
MNASFG:	DS 1	;Ï²Å½Ì×¸Þ
SAMEFG:	DS 1 ;¼Ã²ÊÞ²ÄË®³¼ÞÉÄ·É Ì×¸Þ
JRFG:	DS 1 ;JRÒ²Ú²É Ì×¸Þ
FNKFG:	DS 1 ;Ì§Ý¸¼®Ý·° Ë®³¼Þ Ì×¸Þ
COMSTR:	DS 2 ;ºÏÝÄÞÓ¼ÞÚÂ ±ÄÞÚ½
BASE:	DS 2 ;·ÎÝ±ÄÞÚ½
Y:	DS 1 ;ºÏÝÄÞÅ² ¶°¿Ù²Á
X:	DS 1
TNK_Y:	DS 1 ;INDEX SETÉ »ÞË®³
TNK_X:	DS 1
DAWORK:	DS 2 ;ÃÞ¨½±½ Ö³ Ü°¸
DAPAGE:	DS 1 ;ÃÞ¨½±½ Ö³ Íß°¼Þ
DAPGWK:	DS 5*16 ;¶¸Íß°¼ÞÉ ÍÞ°½Adr
OBYTE:	DS 1 ;ÃÞ¨½±½¥ÊÞ²Ä½³
POPDT:	DS 4 ;ÃÞ¨½±½¥Ë®³¼ÞDATA
FINDFG:	DS 1 ;1-É°ÏÙ¾¯Ä 2-ÃÞ¨½±½ ¾¯Ä
FINDBT:	DS 1 ;FINDÃÞ°À½³
XYSAV:	DS 2 ;»ÞË®³Î¿ÞÝ
TNKFG:	DS 1 ;²ÝÃÞ¯¸½¶Þ ÐÂ¶¯À¶
SOMPRF:	DS 1 ;Ë®³¼Þ½Ù ½³¼Þ¶Þ 1ÊÞ²Ä¶
TENTYP:	DS 1 ;ÃÝ·°À²Ìß
SRCHZ:	DS 2 ;»°Á¿Þ³ÌÞÝ
LABEL:	DS 2 ;×ÍÞÙ½³
CRTOFF:	DS 1 ;¶ÞÒÝË®³¼Þ µÌ

ADSAV0:	DS 2 ;±ÄÞÚ½ÍÝ½³¾°ÌÞ´Ø±
SLSAV0:	DS 2
ADSAV1:	DS 12
ADSAVB: DS 4
ADSAVE: DS 4
ADSAVS: DS 4

OFFSET: DW 0
POFSET: DW 0

ADXWK0:	DS 2 ;±ÄÞÚ½Ü°¸1
SLXWK0:	DS 1 ;½Û¯Ä
SFXWK0:	DS 1 ;½Û¯ÄÌ×¸Þ
ADXWK1:	DS 2
SLXWK1:	DS 1
SFXWK1:	DS 1
ADXWK2:	DS 2
SLXWK2:	DS 1
SFXWK2:	DS 1

BUFSV0:	DS 41 ;±¹Þ²Ý·É³ Ö³
BUFSV1:	DS 257 ;»°ÁÃÞ°À Ö³
LWORK:	DS 40 ;1·Þ®³ Ü°¸
VWORK:	DS 40*24 ;¶ÞÒÝÎ¿ÞÝÖ³
TANKWK:	DS 64  ;GRA-WIN&IdxTANK¹ÝÖ³
;	DB '!!' ;PAGE1µÜØÉ¼Ù¼(Å¸ÃÓ²²)

	DS	8000H-$

	DEPHASE


;   SUPER-X ver 1.22  PAGE 0
	
	PHASE	100H

; ºÏÝÄÞÃÝ¿³ I/DE=¾ÝÄ³ BC=ÃÝ¿³ÊÞ²Ä½³
CMTRNS:	PUSH	HL
	EX	DE,HL
	LD	DE,VWORK
	LDIR
	POP	HL
	RET

; KANJI FONT LOAD
KLTP:	CALL	FCBCLR
	CALL	DSKNM
        LD      HL,(OFFSET)
	PUSH    HL
	LD      HL,0
        LD      (OFFSET),HL
        LD	HL,KFILNM
	LD	DE,FCB+1
	LD	BC,11
	LDIR
	LD	DE,0
	LD	BC,0FFFFH
	LD	A,255
	LD	(CRTOFF),A
	CALL	SPLOD6
	POP     HL
	LD      (OFFSET),HL
	JP      COMPLT
KLEN:	;

; PORT OUT
POTP:	CALL	CVAL
	JP	C,ERROR
	LD	A,D
	OR	A
	JP	NZ,ERROR
	PUSH	DE
	CALL	BUNCON
	CALL	CVAL
	JP	C,ERROR
	LD	A,D
	OR	A
	JP	NZ,ERROR
	POP	BC
	OUT	(C),E
	JP	COMPLT
POEN:	;

; DISK INFO (FREE CLUSTERS)
CITP:	CALL	DSKNM
	CALL	BUNMAT
	LD	A,(FCB)
	LD	E,A
	LD	C,1BH
	CALL	0F37DH
	INC	A
	JP	Z,ERROR
	EX	DE,HL
	PUSH	HL
	OR	A
	SBC	HL,DE
	PUSH	HL
	LD	HL,STR104
	CALL	NPRINT
	POP	HL
	CALL	DECPR
	LD	A,'/'
	CALL	CHPUT
	POP	HL
	CALL	DECPR
	CALL	NCRLF
	JP	SYSTEM
CIEN:	;

; PORT IN
PITP:	CALL	CVAL
	JP	C,ERROR
	LD	A,D
	OR	A
	JP	NZ,ERROR
	LD	C,E
	IN	A,(C)
	LD	C,A
	CALL	BSOMEP
	JP	SYSTEM
PIEN:	;

; COMPARE
CMTP:	CALL	SUB300
	LD	A,(HL)
	OR	A
	JR	Z,MEMCM6
	CALL	BUNCON
	LD	A,(HL)
	CP	'S'
	JP	NZ,ERROR
	INC	HL
	CALL	BUNMAT
	LD	A,255
MEMCM6:	LD	(WORK+4),A
	LD	HL,0
	LD	(WORK),HL
	LD	(WORK+1),HL
MEMCM4:	CALL	STOP
	JP	Z,BREAK
	LD	HL,(SLXWK1)
	LD	(SLXWK0),HL
	LD	HL,(ADXWK0)
	CALL	PEEK
	PUSH	AF
	LD	HL,(SLXWK2)
	LD	(SLXWK0),HL
	LD	HL,(ADXWK2)
	CALL	PEEK
	LD	C,A
	POP	AF
	LD	B,A
	CP	C
	PUSH	AF
	LD	A,(WORK+4)
	OR	A
	JR	Z,MEMCM8
	POP	AF
	JR	NZ,MEMC11
	LD	HL,STR67
	JR	MEMCM9
MEMCM8:	POP	AF
	JR	Z,MEMC11
	LD	HL,STR68
MEMCM9:	PUSH	HL
	LD	HL,(WORK)
	INC	HL
	LD	(WORK),HL
	LD	HL,(ADXWK0)
	LD	DE,(SLXWK1)
	CALL	MEMCSB
	POP	HL
	JR	MEMC12
MEMC13:	JR	MEMCM4
MEMC12:	CALL	NPRINT
	LD	HL,(ADXWK2)
	LD	DE,(SLXWK2)
	LD	B,C
	CALL	MEMCSB
	CALL	NCRLF
	LD	A,(PRNFG)
	OR	A
	JR	NZ,MEMC11
	LD	A,(WORK+2)
	INC	A
	CP	20
	JR	NZ,MEMCM1
	CALL	STOP2
	JP	Z,BREAK
	CALL	CRLF
	XOR	A
MEMCM1:	LD	(WORK+2),A
MEMC11:	LD	HL,(ADXWK2)
	INC	HL
	LD	(ADXWK2),HL
	LD	HL,(ADXWK0)
	INC	HL
	LD	(ADXWK0),HL
	DEC	HL
	LD	DE,(ADXWK1)
	OR	A
	SBC	HL,DE
	JR	NZ,MEMC13
	LD	HL,(WORK)
	LD	A,H
	OR	L
	JR	Z,MEMCM5
	CALL	DECPR
	LD	HL,STR55
	CALL	NPRINT
	JP	SYSTEM
MEMCM5:	LD	HL,STR56
	CALL	NPRINT
	JP	SYSTEM
CMEN:	;

; CHANGE SUM TYPE
CSTP:	CALL	BUNMAT
	LD	A,(SUMTYP)
	CPL
	LD	(SUMTYP),A
	PUSH	AF
	LD	HL,STR26
	CALL	PRINT
	POP	AF
	LD	HL,STR27
	OR	A
	JR	Z,SUMCG1
	LD	HL,STR28
SUMCG1:	CALL	PRINT
	JP	SYSTEM
CSEN:	;

; RELOCATE
RTTP:	CALL	TRANS3
	LD	HL,(SLXWK2)
	LD	(SLXWK0),HL
	LD	HL,(WORK)
	LD	(ADXWK0),HL
RELOC4:	CALL	STOP
	JP	Z,BREAK
	LD	HL,(ADXWK0)
	PUSH	HL
	CALL	SBWKRD
	LD	IX,GETBT
	CALL	P0CALL
	POP	DE
	PUSH	DE
	LD	HL,(OBYTE)
	LD	H,0
	ADD	HL,DE
	LD	(ADXWK0),HL
	DEC	HL
	EX	DE,HL
	LD	HL,(WORK+2)
	RST	20H
	JP	C,COMPLT
	LD	IX,SBWORK
	LD	DE,RELCDT
	LD	A,(IX)
	CP	0DDH
	JR	Z,RELOC8
	CP	0FDH
	JR	Z,RELOC8
	CP	0EDH
	JR	NZ,RELOC5
	LD	DE,RELDT1
	JR	RELOC8
RELC10:	JR	RELOC4
RELOC8:	INC	IX
RELOC5:	LD	A,(DE)
	OR	A
	JR	Z,RELOC7
	CP	(IX)
	JR	Z,RELOC1
	INC	DE
	JR	RELOC5
RELOC1:	LD	L,(IX+1)
	LD	H,(IX+2)
	LD	DE,(WORK+6)
	RST	20H
	JR	C,RELC11
	LD	DE,(WORK+8)
	INC	DE
	LD	A,D
	OR	E
	JR	Z,RELOC9
	RST	20H
	JR	C,RELOC9
RELC11:	JR	RELOC7
RELOC9:	LD	DE,(WORK+4)
	ADD	HL,DE
	LD	(IX+1),L
	LD	(IX+2),H
	LD	A,(OBYTE)
	LD	B,A
	LD	DE,SBWORK
	POP	HL
	PUSH	HL
RELOC2:	LD	A,(DE)
	PUSH	BC
	PUSH	DE
	LD	E,A
	CALL	POKE
	POP	DE
	POP	BC
	INC	HL
	INC	DE
	DJNZ	RELOC2
	POP	HL
	LD	IX,LWORK
	CALL	ADA
	LD	B,39
	LD	HL,LWORK
RELOC6:	LD	A,(HL)
	OR	A
	JR	Z,RELOC3
	CALL	CHPUT
	INC	HL
	DJNZ	RELOC6
RELOC3:	CALL	NCRLF
	JR	RELC10
RELOC7:	POP	AF
	JR	RELC10
RTEN:	;

; FILL
FLTP:	CALL	SUB200
	CALL	BUNCON
	CALL	CVAL
	JP	C,ERROR
	CALL	BUNMAT
	INC	D
	DEC	D
	JP	NZ,ERROR
	LD	HL,(ADXWK0)
FILL1:	PUSH	DE
	CALL	POKE
	POP	DE
	PUSH	HL
	LD	BC,(ADXWK1)
	OR	A
	SBC	HL,BC
	POP	HL
	INC	HL
	JP	Z,COMPLT
	JR	FILL1
FLEN:	;

; BASIC FIND
BFTP:	LD	HL,0
	LD	(WORK),HL
	LD	(WORK+2),HL
	LD	HL,STR53
	CALL	PRINT
	CALL	INLIN
	JP	C,ERROR
	XOR	A
	LD	(FINDFG),A
	INC	HL
	LD	A,(HL)
	OR	A
	JR	Z,BFND12
	LD	DE,BUFSV1
BFIND1:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	OR	A
	JR	NZ,BFIND1
	LD	HL,(0F676H) ;HL=¾ÝÄ³
BFND10:	LD	C,(HL)
	INC	HL
	LD	B,(HL) ;BC=ØÝ¸Îß²ÝÀ
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL) ;DE=·Þ®³ÊÞÝºÞ³
	INC	HL
	LD	A,B
	OR	C
	JR	NZ,BFIND2
	LD	IX,WORK
	LD	A,(IX)
	OR	(IX+1)
	JR	NZ,BFND11
BFND12:	LD	HL,STR56
	CALL	NPRINT
	JP	SYSTEM
BFND11:	CALL	NCRLF
	LD	HL,(WORK)
	CALL	DECPR
	LD	HL,STR57  
	CALL	NPRINT
	JP	SYSTEM
BFIND2:	PUSH	BC ;ØÝ¸
	PUSH	DE ;·Þ®³
	LD	IX,5284H
	CALL	159H
	LD	HL,0F55EH
BFIND6:	LD	DE,BUFSV1
	PUSH	HL
BFIND5:	LD	A,(DE)
	OR	A
	JR	Z,BFIND3 ;Ê¯¹Ý
	LD	A,(HL)
	OR	A
	JR	Z,BFIND8 ;Å¶¯À
	LD	A,(DE)
	CP	'?'
	JR	Z,BFND13
	CP	(HL)
	JR	NZ,BFIND4
BFND13:	INC	DE
	INC	HL
	JR	BFIND5
BFIND4:	POP	HL
	INC	HL
	JR	BFIND6
BFIND8:	POP	AF
	JR	BFIND9
BFND17:	JR	BFND10
BFIND3:	POP	AF
	LD	IX,WORK
	LD	L,(IX)
	LD	H,(IX+1)
	INC	HL
	LD	(IX),L
	LD	(IX+1),H
	POP	HL
	PUSH	HL
	CALL	DECPR
	CALL	ONEPUT
	LD	A,9
	CALL	0A2H
	LD	A,(WORK+2)
	INC	A
	CP	5
	JR	NZ,BFND14
	CALL	PCRLF
	LD	A,(WORK+3)
	INC	A
	CP	20
	JR	NZ,BFND16
	CALL	STOP2
	JP	Z,BREAK
	CALL	CRLF
	XOR	A
BFND16:	LD	(WORK+3),A
	XOR	A
BFND14:	LD	(WORK+2),A
BFIND9:	CALL	STOP
	JP	Z,BREAK
	POP	DE
	POP	HL
	JR	BFND17
BFEN:	;

; INDEX SAVE
ISTP:	CALL	FCBCLR
	CALL	DSKNM
	LD	HL,TFILNM
	LD	DE,FCB+1
	LD	BC,11
	LDIR
	CALL	SVOPEN
	LD	HL,(TNKBYT)
	LD	(DMA),HL
	LD	DE,FCB
	LD	HL,2
	LD	C,26H
	CALL	SYSCAL
	LD	B,128
	LD	HL,8000H
TNKSV1:	PUSH	BC
	PUSH	HL
	LD	DE,DMA
	LD	BC,256
	CALL	LDIRMV
	LD	DE,FCB
	LD	HL,256
	LD	C,26H
	CALL	SYSCAL
	POP	HL
	LD	DE,256
	ADD	HL,DE
	POP	BC
	DJNZ	TNKSV1
	CALL	CLOSE
	JP	COMPLT
ISEN:	;

; INDEX LOAD
ILTP:	CALL	FCBCLR
	CALL	DSKNM
	LD	HL,TFILNM
	LD	DE,FCB+1
	LD	BC,11
	LDIR
	CALL	LDOPEN
	LD	DE,FCB
	LD	HL,2
	LD	C,27H
	CALL	SYSCAL
	LD	HL,(DMA)
	LD	(TNKBYT),HL
	LD	B,128
	LD	HL,8000H
TNKLD1:	PUSH	BC
	PUSH	HL
	LD	DE,FCB
	LD	HL,256
	LD	C,27H
	CALL	SYSCAL
	POP	DE
	PUSH	DE
	LD	HL,DMA
	LD	BC,256
	CALL	LDIRVM
	POP	HL
	LD	DE,256
	ADD	HL,DE
	POP	BC
	DJNZ	TNKLD1
	JP	COMPLT
ILEN:	;

; EXIT
QTTP:	CALL	BUNMAT
	CALL	ERHKOF
	CALL	MAPNEW
	LD	IX,CLSLIN
	CALL	P0CALL
	LD	HL,(0F6C2H)
	LD	(0F6C4H),HL
	LD	(0F6C6H),HL
	CALL	0CCH
	LD	A,24
	LD	(0F3B1H),A
	LD	A,(FNKFG)
	OR	A
	CALL	NZ,0CFH
	LD	IX,409BH
	LD	A,(0FCC1H)
	PUSH	AF
	POP	IY
	LD	SP,(STACK)
	JP	1CH
QTEN:	;


OFTP:
	LD      DE,0
	LD      A,(HL)
	OR      A
	JR      Z,OFSET1
	LD	IX,ADRES
	CALL	P0CALL
	JP	C,ERROR
	CALL	BUNMAT
OFSET1:
        XOR     A
        LD      HL,0
        SBC     HL,DE
        LD      (OFFSET),HL
	JP	SYSTEM
OFEN:


; TENKEY TYPE
TKTP:	LD	A,(HL)
	SUB	'1'
	JP	C,ERROR
	CP	4
	JP	NC,ERROR
	LD	(TENTYP),A
	LD	H,0
	LD	L,A
	PUSH	HL
	POP	DE
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	ADD	HL,DE
	LD	DE,STR47
	ADD	HL,DE
	LD	DE,TENSTR
	LD	BC,6
	LDIR
	JP	SYSTEM
TKEN:	;

; TOTAL SUM
TSTP:	CALL	SUB200
	CALL	BUNMAT
	LD	HL,(ADXWK0)
	LD	DE,0
TOTAL1:	PUSH	DE
	CALL	PEEK
	POP	DE
	LD	C,A
	LD	B,0
	EX	DE,HL
	ADD	HL,BC
	EX	DE,HL
	PUSH	HL
	LD	BC,(ADXWK1)
	OR	A
	SBC	HL,BC
	POP	HL
	INC	HL
	JP	Z,CALC4
	JR	TOTAL1
TSEN:	;

; BLOAD <FILENAME>,[<OFFSET#SLOT>]
LDTP:   CALL	FLNAME
        LD      DE,0
        LD      BC,0
        LD	A,(HL)
	OR	A
	JR	Z,LDTP2
	CALL	BUNCON
	LD	IX,ADRES
	CALL	P0CALL
	CALL	BUNMAT
LDTP2:
        LD	(ADXWK0),DE
	LD	(SLXWK0),BC
	LD	(ADXWK1),DE
	CALL	LDOPEN
	LD	DE,FCB
	LD	HL,7
	LD	C,27H
	CALL	SYSCAL
	LD	A,(DMA)
	CP	0FEH
	JP	NZ,ERROR
	LD	HL,STR72
	CALL	NPRINT
	LD	HL,(DMA+1)
	PUSH	HL
	LD      DE,(ADXWK0)
	ADD     HL,DE
	CALL	ADRSPR
	LD	HL,STR73
	CALL	NPRINT
	LD	HL,(DMA+3)

        ; Select smaller option
        PUSH    DE
        PUSH    HL
        LD      HL,(FCB+16)
        LD      DE,-8
        ADD     HL,DE
        LD      DE,(DMA+1)
        ADD     HL,DE
        POP     DE
        RST     #20
        JR      C,LDTP1
        EX      DE,HL
LDTP1:  POP     DE
        LD      (DMA+3),HL

	ADD     HL,DE
	CALL	ADRSPR
	LD	HL,STR74
	CALL	NPRINT
	LD	HL,(DMA+5)
	ADD     HL,DE
	LD      (ADSAVS),HL
	CALL	ADRSPR
	CALL	NCRLF
	POP	DE
	LD	HL,(DMA+3)
	OR	A
	SBC	HL,DE
	INC	HL      ;HL=Lenght DE=Start

	LD	BC,0FFFFH
	LD	A,255
	LD	(CRTOFF),A

	PUSH    HL
        LD      HL,(ADXWK0)
        ADD     HL,DE
        LD	(ADXWK0),HL
         LD	(ADXWK1),HL
        POP     HL
	CALL	SPLOD8
	JP      COMPLT
LDEN:	;

; SECTOR SAVE
SCSTP:	CALL	DMASET
	PUSH	HL
	LD	C,19H
	CALL	0F37DH
	POP	HL
	LD	(WORK+4),A
	LD	A,(HL)
	CALL	ALPBIG
	CP	'A'
	JR	C,SCSAV1
	CP	'H'+1
	JR	NC,SCSAV1
	CALL	DSKNM
	DEC	A
	LD	(WORK+4),A
SCSAV1:	CALL	CVAL
	JP	C,ERROR
	LD	(WORK),DE
	CALL	BUNCON
	LD	A,(HL)
	INC	HL
	CP	','
	JR	Z,SCSAV2
	CP	' '
	JR	Z,SCSAV2
	DEC	HL
	CALL	CVAL
	JP	C,ERROR
	CALL	BUNCON
	PUSH	HL
	LD	HL,(WORK)
	EX	DE,HL
	RST	20H
	JP	C,ERROR
	EX	DE,HL
	POP	HL
SCSAV2:	LD	(WORK+2),DE
	CALL	SUB100
SCSAV5:	LD	BC,512
	CALL	DMATRW
	LD	DE,(WORK)
	LD	HL,(WORK+4)
	LD	H,1
	LD	C,30H
	CALL	SYSCAL
	LD	HL,(WORK)
	LD	DE,(WORK+2)
	RST	20H
	JP	Z,COMPLT
	INC	HL
	LD	(WORK),HL
	JR	SCSAV5
SCSEN:	;

; BSAVE <FILENAME>,<BEGIN>[<#SLOT>],<END>,[<START>[,<OFFSET>]]
SVTP:	CALL	FLNAME
	CALL	BUNCON
	CALL	SUB200
	PUSH	HL
	LD	HL,(ADXWK0)
	LD	A,H
	CP	80H
	JP	C,ERROR
	LD	(DMA+1),HL
	LD	HL,(ADXWK1)
	LD	(DMA+3),HL
	POP	HL
	LD	A,(HL)
	OR	A
	JR	NZ,SAVE2
	LD	HL,(DMA+1)
	LD	(DMA+5),HL
	JR	SAVE3
SAVE2:	CALL	BUNCON
	LD	IX,ADRES
	CALL	P0CALL
	LD	(DMA+5),DE
	
	LD      A,(HL)
	OR      A
	JR      Z,SAVE3

        CALL	BUNCON
	LD	IX,ADRES
	CALL	P0CALL
	
	PUSH    HL
	LD      HL,(DMA+1)
	ADD     HL,DE
	LD      (DMA+1),HL
	LD      HL,(DMA+3)
	ADD     HL,DE
	LD      (DMA+3),HL
	LD      HL,(DMA+5)
	ADD     HL,DE
	LD      (DMA+5),HL
	POP     HL

	CALL	BUNMAT
SAVE3:	LD	A,0FEH
	LD	(DMA),A
	CALL	SVOPEN
	LD	DE,FCB
	LD	HL,7
	LD	C,26H
	CALL	SYSCAL

	LD	HL,(ADXWK1)
	LD	DE,(ADXWK0)
	OR	A
	SBC	HL,DE
	LD	DE,256
	CALL	DIV
	LD	(WORK),HL
	LD	(WORK+1),IX
	JP      SPSAV3
SVEN:	;

; ¾¸ÀÛ°ÄÞ ÎÝÀ²
SCLTP:	CALL	DMASET
	PUSH	HL
	LD	C,19H
	CALL	0F37DH
	POP	HL
	LD	(WORK+4),A
	LD	A,(HL)
	CALL	ALPBIG
	CP	'A'
	JR	C,SCLOD1
	CP	'H'+1
	JR	NC,SCLOD1
	CALL	DSKNM
	DEC	A
	LD	(WORK+4),A
SCLOD1:	CALL	CVAL
	JP	C,ERROR
	LD	(WORK),DE
	CALL	BUNCON
	LD	A,(HL)
	CP	','
	INC	HL
	JR	Z,SCLOD2
	CP	' '
	JR	Z,SCLOD2
	DEC	HL
	CALL	CVAL
	JP	C,ERROR
	CALL	BUNCON
	PUSH	HL
	LD	HL,(WORK)
	EX	DE,HL
	RST	20H
	JP	C,ERROR
	EX	DE,HL
	POP	HL
SCLOD2:	LD	(WORK+2),DE
	CALL	SUB100
	LD	(ADXWK1),DE
	LD	HL,(WORK+2)
	LD	DE,(WORK)
	OR	A
	SBC	HL,DE
	LD	DE,128
	RST	20H
	JP	NC,ERROR5
	INC	HL
	LD	DE,512
	CALL	MULT
	LD	A,H
	OR	L
	JR	NZ,SCLOD3
	LD	A,1
	LD	(CARFG),A
SCLOD3:	EX	DE,HL
	LD	HL,STR95
	CALL	NPRINT
	EX	DE,HL
	LD      (ADSAVS),HL
	CALL	ADRSPR
	EX	DE,HL
	LD	HL,STR85
	CALL	NPRINT
	EX	DE,HL
	LD	DE,(ADXWK0)
	DEC	HL
	ADD	HL,DE
	JP	C,ERROR5
	LD	BC,(SLXWK0)
	INC	B
	DEC	B
	JR	Z,SCLOD4
	LD	A,(0F344H)
	CP	C
	JR	NZ,SCLOD5
SCLOD4:	LD	BC,0FFH
	ADD	HL,BC
	JP	C,ERROR5
	SBC	HL,SP
	JP	NC,ERROR5
SCLOD5:	LD	DE,(WORK)
	LD	HL,(WORK+4)
	LD	H,1
	LD	C,2FH
	CALL	SYSCAL
	LD	BC,512
	CALL	DMATRR
	LD	HL,(WORK)
	LD	DE,(WORK+2)
	RST	20H
	JR	Z,SCLOD6
	INC	HL
	LD	(WORK),HL
	JR	SCLOD5
SCLOD6:	LD	HL,STR91
	CALL	NPRINT
	LD	HL,(ADXWK1)
	LD      (ADSAVB),HL
	LD	DE,(SLXWK0)
	LD      (ADSAVB+2),DE
	LD      (ADSAVE+2),DE
	LD      (ADSAVS+2),DE
	CALL	ADPRSL
	LD	HL,STR92
	CALL	NPRINT
	LD	HL,(ADXWK0)
	DEC	HL
	LD      (ADSAVE),HL
	CALL	ADRSPR
	CALL	NCRLF
	JP	COMPLT
SCLEN:	;

; COºÏÝÄÞ ÎÝÀ²	
COTP:	LD      A,(HL)
        INC     HL
        CP      ","
        JR      Z,COLOR4
        DEC     HL
        CALL	CVAL
	INC	D
	DEC	D
	JP	NZ,ERROR
	LD	A,E
	CP	16
	JP	NC,ERROR
	LD	(0F3E9H),A
	LD      A,(HL)
	OR      A
	JR      Z,COLOR3
	CALL	BUNCON
COLOR4: LD      A,(HL)
        INC     HL
        CP      ","
        JR      Z,COLOR5
        DEC     HL
	CALL	CVAL
	INC	D
	DEC	D
	JP	NZ,ERROR
	LD	A,E
	CP	16
	JP	NC,ERROR
	LD	(0F3EAH),A
	LD      A,(HL)
	OR      A
	JR      Z,COLOR3
	CALL	BUNCON
COLOR5: CALL	CVAL
	INC	D
	DEC	D
	JP	NZ,ERROR
	LD	A,E
	CP	16
	JP	NC,ERROR
	LD	(0F3EBH),A
	CALL	BUNMAT
COLOR3:	CALL	62H
	JP	SYSTEM
COEN:	;

; FSºÏÝÄÞ ÎÝÀ²
FSTP:	

	LD	C,6FH
	PUSH	HL
	CALL	0F37DH
	POP	HL
	LD	A,B
	CP	2
	JR	C,FSDOS1

	PUSH	HL
	POP	DE
	LD	IX,FCB
	LD	B,37H 	;RHDS
	LD	C,40H
	CALL	0F37DH
	AND	A
	JP	NZ,SYSTEM
	LD	C,0
FSD24:	
	LD	B,2
	INC	C

FSD23:	
	PUSH	BC
	LD	B,19

	LD	HL,FCB+1
	LD	A,(FCB+14)
	AND	10H
	JR	Z,FSD21
	LD	A,"<"
	CALL	CHPUT
	DEC	B


FSD21:	LD	A,(HL)
	CALL	CHPUT
	INC	HL
	DEC	B
	AND	A
	JR	NZ,FSD21

	LD	A,(FCB+14)
	AND	10H
	JR	Z,FSD22
	LD	A,">"
	CALL	CHPUT
	DEC	B

FSD22:
	LD	A,' '
	CALL	CHPUT
	DJNZ	FSD22

	LD	C,41H
	LD	IX,FCB
	CALL	0F37DH
	AND	A

	POP	BC
	JP	NZ,SYSTEM
	DJNZ	FSD23

	LD	A,C
	CP	21
	JR	NZ,FSD25
	CALL	STOP2
	JP	Z,BREAK
	LD	C,0
FSD25:	
	CALL	NCRLF
	JR 	FSD24

FSDOS1:

	CALL	FCBCLR
	CALL	DSKNM
	CALL	BUNMAT
	XOR	A
	LD	HL,WORK
	LD	(HL),A
	INC	HL
	LD	(HL),A
	INC	HL
	LD	(HL),A
	LD	HL,FCB+1
	LD	DE,FCB+2
	LD	BC,10
	LD	(HL),'?'
	LDIR
	LD	C,11H
	LD	DE,FCB
	CALL	0F37DH
	OR	A
	JP	NZ,ERROR6
FILES5:	OR	A
	JR	Z,FILES6
	LD	A,(WORK+1)
	OR	A
	CALL	NZ,NCRLF
	LD	HL,(WORK)
	LD	H,0
	CALL	DECPR
	LD	HL,STR78
	CALL	NPRINT
	JP	SYSTEM
FILES6:	CALL	STOP
	JP	Z,ERROR
	LD	HL,DMA+1
	LD	B,8
FILES1:	LD	A,(HL)
	CALL	CHPUT
	INC	HL
	DJNZ	FILES1
	LD	A,(HL)
	CP	' '
	JR	Z,FILES7
	LD	A,'.'
FILES7:	CALL	CHPUT
	LD	B,3
FILES2:	LD	A,(HL)
	CALL	CHPUT
	INC	HL
	DJNZ	FILES2
	CALL	ONEPUT
	LD	HL,WORK
	INC	(HL)
	INC	HL
	INC	(HL)
	LD	A,(HL)
	SUB	3
	JR	NZ,FILES4
	LD	(HL),A
	INC	HL
	INC	(HL)
	LD	A,(HL)
	SUB	21
	JR	NZ,FILES8
	LD	(HL),A
	CALL	STOP2
	JP	Z,BREAK
FILES8:	CALL	NCRLF
FILES4:	LD	C,12H
	CALL	0F37DH
	JR	FILES5
FSEN:	;

CDTP:	; CD command

	LD	C,6FH

	PUSH	HL
	CALL	0F37DH
	POP	DE
	AND 	A
	JP	NZ,ERROR
	LD	A,B
	CP	2
	JR	NC,CD1

	LD	HL,STR69
CD2:
	CALL	NPRINT
	JP	SYSTEM

CD1:
	LD	C,5AH
	CALL	0F37DH
	AND	A
	LD	HL,STR56
	JR	NZ,CD2
	JP	SYSTEM

CDEN:	; CD command end

; VRºÏÝÄÞ ÎÝÀ²
VRTP:
        LD	A,(HL)
	OR	A
	JR	Z,VARBL1
        CALL    VARNAM
	JP	C,ERROR
	LD      D,0
	LD      E,A
VARBL5:
	EX	DE,HL

	LD	BC,ADSAV0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
	PUSH	HL
	EX	DE,HL
	INC	HL
	LD      A,(HL)
	INC     HL
	CP      "="
	JR      Z,VARBL7
	DEC     HL
	CALL	BUNCON
VARBL7:
	LD	IX,ADRES
	CALL	P0CALL
	JP	C,ERROR
	CALL	BUNMAT
	INC	B
	DEC	B
	JR	NZ,VARBL4
	LD	BC,(SLSAV0)
VARBL4:	POP	IX
	LD	(IX),E
	LD	(IX+1),D
	LD	(IX+2),C
	LD	(IX+3),B
	JP	SYSTEM
VARBL1:	LD	B,0
VARBL3:	PUSH	BC
	LD	HL,STR105
	CALL	NPRINT
	LD	A,'0'
	ADD     A,B
	LD      C,A
	LD      A,B
	CP      4
	JR      C,VARBL6
	LD      C,"B"
	JR      Z,VARBL6
	CP      5
	LD      C,"E"
	JR      Z,VARBL6
	CP      6
	LD      C,"S"
	;JR      Z,VARBL6
VARBL6: LD      A,C
	CALL	CHPUT
	LD	A,'='
	CALL	CHPUT
	LD	L,B
	LD	H,0
	LD	DE,ADSAV0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	PUSH	HL
	POP	IX
	LD	L,(IX)
	LD	H,(IX+1)
	LD	E,(IX+2)
	LD	D,(IX+3)
	CALL	ADPRSL
	CALL	NCRLF
	POP	BC
	INC	B
	LD	A,B
	CP	4+3
	JR	NZ,VARBL3
	JP	SYSTEM
	

VREN:   ; Variable end

; SFºÏÝÄÞ ÎÝÀ²
SFTP:	LD	A,(HL)
	OR	A
	JR	NZ,STFUN1
	CALL	3EH
	JP	SYSTEM
STFUN1:	CALL	CVAL
	JP	C,ERROR
	CALL	BUNCON
	LD	A,D
	OR	A
	JP	NZ,ERROR
	LD	A,E
	OR	A
	JP	Z,ERROR
	CP	11
	JP	NC,ERROR
	LD	BC,0F87FH-16
	EX	DE,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,BC
	EX	DE,HL
	LD	B,15
STFUN2:	LD	A,(HL)
	CP	'['
	JR	NZ,STFUN3
	INC	HL
	PUSH	BC
	PUSH	DE
	CALL	CVAL
	JP	C,ERROR
	LD	A,D
	OR	A
	JP	NZ,ERROR
	LD	A,(HL)
	CP	']'
	JP	NZ,ERROR
	LD	A,E
	POP	DE
	POP	BC
STFUN3:	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	STFUN2
	XOR	A
	LD	(DE),A
	JP	SYSTEM
SFEN:

; SUB

; Ï¼ÝÃÞ°À Ë®³¼Þ
NWSLTP:	LD	HL,STR07
	CALL	NPRINT
	LD	B,0
NWSLT1:	LD	HL,STR08
	CALL	NPRINT
	LD	A,B
	ADD	A,'0'
	CALL	CHPUT
	LD	A,'='
	CALL	CHPUT
	CALL	PGSLOT
	PUSH	BC
	CALL	SHARPR
	LD	A,C
	CALL	NSLTPR
	POP	BC
	INC	B
	LD	A,B
	CP	4
	JR	NZ,NWSLT1
	CALL	NCRLF
	LD	HL,STR11
	CALL	NPRINT
	LD	B,4
	LD	HL,0F341H
NWSLT6:	EXX
	LD	HL,STR08
	CALL	NPRINT
	EXX
	LD	A,'4'
	SUB	B
	CALL	CHPUT
	LD	A,'='
	CALL	CHPUT
	CALL	SHARPR
	LD	A,(HL)
	PUSH	BC
	CALL	NSLTPR
	POP	BC
	INC	HL
	DJNZ	NWSLT6
	CALL	NCRLF
	LD	HL,STR14
	CALL	NPRINT
	LD	A,(0F341H)
	CALL	NSLTPR
	LD	A,':'
	CALL	CHPUT
	LD	A,'#'
	CALL	CHPUT
	LD	A,(0F342H)
	CALL	NSLTPR
	LD	HL,STR15
	CALL	NPRINT
	LD	A,(0FCC1H)
	CALL	NSLTPR
	CALL	NCRLF
	LD	HL,STR16
	CALL	NPRINT
	LD	A,(0FAF8H)
	CALL	NSLTPR
	CALL	ONEPUT
	LD	HL,STR17
	CALL	NPRINT
	LD	HL,0FB21H
NWSLT5:	LD	A,(HL)
	OR	A
	JR	Z,NWSLT4
	LD	A,':'
	CALL	CHPUT
	CALL	SHARPR
	INC	HL
	LD	A,(HL)
	CALL	NSLTPR
	INC	HL
	JR	NWSLT5
NWSLT4:	CALL	NCRLF
	LD	DE,0FCC1H
	LD	HL,STR12
	CALL	NPRINT
	LD	B,4
	LD	IX,EXPTBL
NWSLT8:	LD	A,':'
	CALL	CHPUT
	LD	A,'*'
	LD	(IX),0
	EX	DE,HL
	BIT	7,(HL)
	EX	DE,HL
	JR	Z,NWSLT9
	LD	A,'o' ; WAS '„'
	LD	(IX),255
NWSLT9:	CALL	CHPUT
	INC	DE
	INC	IX
	DJNZ	NWSLT8
	CALL	ONEPUT
	LD	HL,STR18
	CALL	NPRINT
	LD	C,18H
	CALL	0F37DH
	LD	B,8
	LD	C,'A'
	LD	D,1
NWST11:	LD	A,D
	AND	L
	JR	Z,NWST10
	PUSH	AF
	LD	A,':'
	CALL	CHPUT
	LD	A,C
	CALL	CHPUT
	POP	AF
NWST10:	INC	C
	SLA	D
	DJNZ	NWST11
	CALL	ONEPUT
	LD	HL,STR23
	CALL	NPRINT
	LD	HL,(RESAVE+24)
	CALL	ADRSPR
	CALL	NCRLF
	CALL	MAPPR
	JP	PCRLF
NWSLEN:

; ÊÞ¯Ì§Å² ½ÍÞÃ µµÓ¼Þ1
ALLBIG:	PUSH	HL
	LD	HL,0F55EH
ALBIG2:	LD	A,(HL)
	CALL	ALPBIG
	LD	(HL),A
	LD	DE,0F65FH
	CALL	DCOMPR
	JR	Z,ALBIG1
	INC	HL
	JR	ALBIG2
ALBIG1:	POP	HL
	RET

; ÊÞ¯Ì§Å² ½ÍÞÃµµÓ¼Þ2
NALBIG:	PUSH	HL
	LD	HL,0F55EH
	LD	B,0
NALBG1:	LD	A,(HL)
	CP	'"'
	JR	Z,NALBG2
	CP	"'"
	JR	NZ,NALBG3
	LD	A,B
	CPL
	LD	B,A
	LD	A,"'"
NALBG3:	INC	B
	DEC	B
	CALL	Z,ALPBIG
	LD	(HL),A
	LD	DE,0F65FH
	CALL	DCOMPR
	INC	HL
	JR	NZ,NALBG1
NALBG2:	POP	HL
	RET

; ÌÞÝ·ÊÞÝ Ë®³¼Þ
BUNSUB:	LD	HL,NST05
	LD	B,7
	LD	E,6
BUNSB1:	LD	D,(HL)
	INC	HL
	LD	(0F3DCH),DE
	CALL	PRINT
	INC	HL
	INC	E
	DJNZ	BUNSB1
	RET

; ·¬× ÍÙÌß
CHRHLP:	LD	HL,NST06
	LD	DE,VWORK+40*17
	LD	BC,120
	LDIR
	RET

; ¼ÀÉ·Þ®³ ¹½(ºÏÝÄÞ»ÌÞ)
SITACL:	XOR	A
	LD	(PRNFG),A
	LD	HL,40*20
	LD	BC,40
	LD	A,' '
	JP	FILVRM

; ¼ÀÉ ¾Ý ¶¸
LINE:	LD	A,23
LINE1:	LD	HL,880
	LD	BC,40
	JP	FILVRM

; ¼ÀÉ ¾Ý ¹½
CLSLIN:	LD	A,' '
	LD	HL,880
	LD	BC,80
	JP	FILVRM

; IN/HL=SHIFTJIS
; O/FC18H¶×32ÊÞ²ÄÆ ¿É¶Ý¼ÞÉÌ«ÝÄ
JIS:	PUSH	HL
	LD	HL,0FC18H
	LD	DE,0FC19H
	LD	BC,31
	LD	(HL),0
	LDIR
	POP	HL
	LD	A,H
	CALL	CODECK
	RET	C
JIS1:	LD	B,H
	LD	C,L
	CALL	CODEGT
	JP	KNJFNT

; A¶Þ ¶Ý¼Þº°ÄÞ¶ Áª¯¸ (Cf=Á¶Þ³)
CODECK:	CP	81H
	RET	C
	CP	0A0H
	CCF
	RET	NC
	CP	0E0H
	RET	C
	CP	0FDH
	CCF
	RET

; BC=¼ÌÄJISº°ÄÞ => BC=JISº°ÄÞ
CODEGT:	LD	A,C
	CP	80H
	ADC	A,0FFH
	CP	9EH
	PUSH	AF
	JR	C,CODGT1
	SUB	5EH
CODGT1:	SUB	3FH
	LD	C,A
	LD	A,B
	CP	0E0H
	JR	C,CODGT2
	SUB	40H
CODGT2:	SUB	81H
	LD	B,A
	POP	AF
	CCF
	LD	A,B
	RLA
	INC	A
	ADD	A,20H
	LD	B,A
	LD	A,C
	ADD	A,20H
	LD	C,A
	RET

; ¶Ý¼ÞÌ«ÝÄ ¶¸Ä¸ IN/BC=JIS
KNJFNT:	LD	A,B
	CP	21H
	JR	NC,KNJFN1
KNJFN2:	SCF
	RET
KNJFN1:	CP	28H
	JR	C,KNJFN3
	CP	30H
	JR	C,KNJFN2
	CP	75H
	JR	NC,KNJFN2
KNJFN3:	LD	A,C
	CP	21H
	JR	C,KNJFN2
	CP	7FH
	JR	NC,KNJFN2
	LD	A,C
	SUB	20H
	LD	E,A
	LD	D,00H
	LD	A,B
	SUB	20H
	LD	L,A
	LD	H,D
	LD	C,L
	LD	B,H
	ADD	HL,HL
	ADD	HL,BC
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	CP	30H
	JR	C,KNJFN4
	LD	A,H
	SUB	12H
	LD	H,A
	LD	C,0DAH
	JR	KNJFN5
KNJFN4:	CP	10H
	JR	C,KNJFN6
	DEC	H
	DEC	H
KNJFN6:	LD	C,0D8H
KNJFN5:	OUT	(C),L
	ADD	HL,HL
	ADD	HL,HL
	INC	C
	OUT	(C),H
	LD	B,20H
	LD	HL,0FC18H
	INIR
	OR	A
	RET

; ¶Ý¼ÞÓ°ÄÞ ON
KNJON:	LD	HL,0
	LD	(0F3DCH),HL
	XOR	A
	LD	(COUNT),A
	LD	HL,2000H
	LD	BC,800H*3
	LD	A,(0F3E9H)
	RLCA
	RLCA
	RLCA
	RLCA
	LD	E,A
	LD	A,(0F3EAH)
	OR	E
	JP	FILVRM

; ¶Ý¼Þ1Ó¼Þ Ë®³¼Þ IN/E=ASC
KPRINT:	LD	A,(COUNT)
	OR	A
	JR	NZ,KPRNT2
	LD	A,E
	CP	' '
	JR	NC,KPRNT8
	CP	9
	JR	Z,KPRNT1
	CP	13
	RET	NZ
KPRNT3:	LD	HL,0F3DDH
	JP	KCRLF
KPRNT8:	CALL	CODECK
	JR	C,KPRNT4
	LD	(COUNT),A
	RET
KPRNT4:	SUB	' '
	LD	DE,HNKNDT
	CP	160-' '
	JR	C,KPRNT9
	SUB	160-' '
	LD	DE,HNKDT1
KPRNT9:	LD	H,0
	LD	L,A
	ADD	HL,HL
	ADD	HL,DE
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	JR	KPRNT7
KPRNT2:	LD	B,A
	LD	C,E
	CALL	CODEGT
KPRNT7:	CALL	FONTGT
	CALL	FONTST
	XOR	A
	LD	(COUNT),A
	RET
KPRNT1:	LD	A,(0F3DDH)
	ADD	A,8
	AND	11111000B
	CP	30
	JR	NC,KPRNT3
	LD	(0F3DDH),A
	RET

FONTST:	LD	HL,(0F3DCH)
	PUSH	HL
	LD	H,0
	LD	DE,8*32*2
	CALL	MULT
	POP	DE
	PUSH	HL
	LD	E,D
	INC	E
	LD	D,0
	LD	HL,8
	CALL	MULT
	POP	DE
	ADD	HL,DE
	EX	DE,HL
	PUSH	DE
	LD	HL,FONTWK
	LD	BC,8
	CALL	LDIRVM
	POP	HL
	LD	DE,8*32
	ADD	HL,DE
	EX	DE,HL
	LD	HL,FONTWK+8
	LD	BC,8
	CALL	LDIRVM
	LD	HL,0F3DDH
	INC	(HL)
	LD	A,(HL)
	CP	30
	RET	NZ
KCRLF:	LD	(HL),0
	DEC	HL
	INC	(HL)
	RET

FONTGT:	LD	A,B
	CP	30H
	JR	C,FNTGT1
	SUB	7
FNTGT1:	SUB	21H
	LD	H,0
	LD	L,A
	LD	DE,96
	PUSH	BC
	CALL	MULT
	POP	BC
	LD	A,C
	SUB	21H
	LD	C,A
	LD	B,0
	ADD	HL,BC
	ADD	HL,HL ;*16
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	DI
	LD	A,(VWRTPT)
	INC	A
	LD	C,A
	XOR	A
	OUT	(C),A
	LD	A,45+80H
	OUT	(C),A
	LD	A,H
	RLCA
	RLCA
	AND	3
	SET	2,A
	OUT	(C),A
	LD	A,14+80H
	OUT	(C),A
	OUT	(C),L
	LD	A,H
	AND	3FH
	OUT	(C),A
	LD	A,(VREDPT)
	LD	C,A
	LD	B,16
	LD	HL,FONTWK
FNTGT2:	IN	A,(C)
	LD	(HL),A
	INC	HL
	DJNZ	FNTGT2
	EI
	RET

FONTWK:	DS 16
COUNT:	DS 1

TITLE:	XOR	A
	LD	(PRNFG),A
	LD	HL,NST04
	CALL	PRINT
	LD	B,8
	LD	HL,40*4
	LD	A,'|'
TITLE1:	CALL	WRTVRM
	LD	DE,39
	ADD	HL,DE
	CALL	WRTVRM
	INC	HL
	DJNZ	TITLE1
	EX	DE,HL
	LD	HL,NST04
	LD	BC,40
	JP	LDIRVM

; ÍÙÌß»ÌÞ
HELPSB:	LD	HL,HELPMS
	LD	DE,0
	LD	BC,40*20
	JP	LDIRVM

; ²ÝÃÞ¯¸½É¼­Ù²
KIND:	XOR	A
	LD	(PRNFG),A
	LD	HL,18*256+10
	LD	(0F3DCH),HL
	LD	HL,(ADXWK0)
	CALL	ADRSPR
	LD	HL,14*256+12
	LD	(0F3DCH),HL
	LD	HL,(ADXWK1)
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,NST02
	ADD	HL,DE
	LD	B,4
KIND1:	LD	A,(HL)
	CALL	HICHP
	INC	HL
	DJNZ	KIND1
	LD	HL,21*256+12
	LD	(0F3DCH),HL
	LD	A,(ADXWK1+1)
	LD	H,0
	LD	L,A
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,NST03
	ADD	HL,DE
	LD	B,4
KIND2:	LD	A,(HL)
	CALL	HICHP
	INC	HL
	DJNZ	KIND2
	RET

; ²ÝÃÞ¯¸½³²ÝÄÞ°
BOX:	LD	HL,NST01
	LD	B,11
	LD	E,9
BOX1:	LD	D,13
	LD	(0F3DCH),DE
	CALL	PRINT
	INC	HL
	INC	E
	DJNZ	BOX1
	RET

; Info on bottom of screen
MAKSLA:	PUSH	HL
	POP	IX
	CALL	CLSLIN
	CALL	LINE
	LD	HL,(0F3DCH)
	PUSH	HL
	LD	A,24
	LD	(0F3B1H),A
	LD	HL,256+24
	LD	(0F3DCH),HL
	LD	HL,STR33
	CALL	PRINT
	LD	A,2
	LD	(0F3DDH),A
	PUSH	IX
	POP	HL
	CALL	PRINT ;ºÏÝÄÞ
	LD	A,16
	LD	(0F3DDH),A
	LD	HL,STR24
	CALL	PRINT ;½Û¯Ä
	LD	A,(SLSAV0+1)
	OR	A
	JR	NZ,MAKSL1
	LD	HL,STR25
	CALL	PRINT
	JR	MAKSL2
MAKSL1:	LD	A,(SLSAV0)
	CALL	SLOTPR
MAKSL2:	LD	A,28
	LD	(0F3DDH),A
        LD      HL,STR29
        CALL    PRINT
        LD      DE,(OFFSET)
        LD      HL,0
        XOR     A
        SBC     HL,DE
        LD	A,H
	CALL	DATPR
	LD	A,L
	CALL	DATPR

	POP	HL
	LD	(0F3DCH),HL
	LD	A,22
	LD	(0F3B1H),A
	RET

; ÊÞ¯Ì§Å²±ÄÞÚ½ DE=Adr B=Slotfg C=slot
ADRES:	LD	A,(HL)
	CP	'@'
	JR	NZ,ADRS18
	INC	HL
	LD	A,(HL)
	OR	A
	JR	Z,ADRS20
	CALL    VARNAM
	RET	C
	CP	4+3
	CCF
	RET	C
	PUSH	HL
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	LD	DE,ADSAV0
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	POP	HL
	INC	HL
	OR	A
	RET
ADRS20:	LD	DE,(ADSAV0)
	JR	ADRS07
ADRS18:	LD	A,(HL)
	CALL	ADSUB
	RET	C
	LD	A,(HL)
	OR	A
	JR	NZ,ADRS06
ADRS07:	LD	BC,(SLSAV0)
	OR	A
	RET
ADRS06:	CP	','
	JR	Z,ADRS07
	CP	' '
	JR	Z,ADRS07
	CP	'#'
	JR	NZ,ADRS04
SLT:	INC	HL
	LD	A,(HL)
	CALL	ALPBIG
	CP	'4'
	JR	Z,ADRS13
	CP	'V'
	JR	NZ,ADRS09
ADRS13:	LD	BC,0FFFFH
	JR	ADRS10
ADRS09:	CP	'5'
	JR	Z,ADRS15
	CP	'S'
	JR	NZ,ADRS14
ADRS15:	LD	B,0
	JR	ADRS10
ADRS14:	LD	B,0
	SUB	'0'
	CP	4
	JR	NC,ADRS04
	LD	B,A
	INC	HL
	LD	A,(HL)
	CP	'-'
	JR	Z,ADRS11
	LD	C,B
	LD	B,0FFH
	JR	ADRS12
ADRS11:	INC	HL
	LD	A,(HL)
	SUB	'0'
	CP	4
	JR	NC,ADRS04
	RLCA
	RLCA
	OR	B
	OR	80H
	LD	C,A
	LD	B,0FFH
ADRS10:	INC	HL
ADRS12:	LD	A,(HL)
	OR	A
	JR	Z,ADRS05
	CP	','
	JR	Z,ADRS05
	CP	' '
	JR	Z,ADRS05
	SCF
	RET
ADRS05:	INC	B
	DEC	B
	JR	Z,ADRS16
	BIT	6,C
	JR	NZ,ADRS16
	LD	A,C
	AND	11B
	EXX
	LD	HL,0FCC1H
	LD	B,0
	LD	C,A
	ADD	HL,BC
	LD	A,(HL)
	EXX
	AND	80H
	JR	Z,ADRS17
	BIT	7,C
	JR	NZ,ADRS16
	SCF
	RET
ADRS17:	BIT	7,C
	JR	NZ,ADRS04
ADRS16:	OR	A
	RET
ADRS04:	SCF
	RET

; ²Á·Þ®³ ÃÞ¨½±¾ÝÌÞÙ ÎÝÀ²
ADIP0:	LD	IX,(IXBRG)
	PUSH	DE
	LD	(ADSAV0),HL
	CALL	GETBT
	LD	A,(OBYTE)
	LD	B,A
	PUSH	AF
	CALL	PUTAD
	POP	AF
	LD	D,0
	LD	E,A
	ADD	HL,DE
	PUSH	HL
	LD	IY,POPDT
ADISA3:	LD	A,(IY)
	OR	A
	JR	Z,ADISA1
	CALL	OPEPR
	INC	IY
	JR	ADISA3
ADISA1:	POP	HL
	LD	(ADSAV0),HL
	LD	DE,(ADXWK1)
	CALL	DCOMPR
	LD	A,0FFH
	JR	C,ADISA2
	JR	Z,ADISA2
	LD	(SAMEFG),A
ADISA2:	POP	DE
	LD	(IX),0
	RET

PUTAD:	CALL	ADRSIN
	LD	DE,SBWORK
	PUSH	DE
	LD	C,B
	LD	(IX),' '
	INC	IX
PUTAD1:	LD	A,(DE)
	CALL	DATIN
	INC	DE
	DJNZ	PUTAD1
	LD	IX,(DAWORK)
	LD	DE,13
	ADD	IX,DE
	LD	(IX),':'
	INC	IX
	POP	DE
	LD	B,C
PUTAD2:	LD	A,(DE)
	CALL	MOJIIN
	INC	DE
	DJNZ	PUTAD2
	LD	IX,(DAWORK)
	LD	DE,18
	ADD	IX,DE
	LD	(IX),':'
	INC	IX
	RET

OPEPR:	LD	B,(IY)
	LD	HL,SBWORK+5
	INC	(HL)
	LD	A,(HL)
	SUB	2
	JR	Z,OPEP19
	DEC	A
	JR	NZ,OPEP18
	LD	A,58H
	JR	OPEP20
OPEP19:	LD	A,86H
OPEP20:	PUSH	BC
	CALL	OPEP23
	POP	BC
OPEP18:	LD	A,B
OPEP23:	CP	80H
	JR	C,OPEP14
	SUB	80H
OPEP22:	JR	Z,OPEPR5
	DEC	A
	JR	Z,OPEPR7
	DEC	A
	JR	Z,OPEPR8
	DEC	A
	JP	Z,OPEP10
	DEC	A
	JP	Z,OPEP11
	DEC	A
	JP	Z,OPEP13
	DEC	A
	JR	Z,OPEPR4
	DEC	A
	JR	Z,OPEP25
	LD	A,(SBWORK+2)
	JP	OPEPR6
OPEP25:	INC	IY
	LD	A,(IY)
	JR	OPEPR6

OPEP14:	LD	B,A
	LD	HL,OPSTR
OPEP16:	DEC	B
	JR	Z,OPEPR2
	LD	A,(HL)
	SUB	'0'-1
	LD	D,0
	LD	E,A
	ADD	HL,DE
	JR	OPEP16
OPEPR2:	LD	A,(HL)
	SUB	'0'
	LD	B,A
OPEP17:	INC	HL
	LD	A,(HL)
	CP	'a'
	JR	C,OPEP21
	CP	'z'+1
	JR	NC,OPEP21
	SUB	'a'
	PUSH	HL
	PUSH	BC
	CALL	OPEP22
	POP	BC
	POP	HL
	DJNZ	OPEP17
	RET
OPEP21:	LD	(IX),A
	INC	IX
	DJNZ	OPEP17
	RET
OPEPR4:	LD	IX,(DAWORK)
	LD	DE,26
	ADD	IX,DE
	RET
OPEPR5:	LD	A,(SBWORK+1)
	JR	OPEPR6
OPEPR7:	LD	A,(SBWORK+2)
	LD	B,'+'
	BIT	7,A
	JR	Z,OPEP24
	CPL
	INC	A
	INC	B
	INC	B
OPEP24:	PUSH	AF
	LD	A,B
	LD	(IX),A
	INC	IX
	POP	AF
	JR	OPEPR6
OPEPR8:	LD	A,(SBWORK+3)
OPEPR6:	CALL	MOJIHD
	CALL	DATIN
OPEPR9:	LD	(IX),'H'
	INC	IX
	RET
OPEP10:	LD	HL,(SBWORK+1)
	JR	OPEP12
OPEP11:	LD	HL,(SBWORK+2)
OPEP12:	LD	A,H
	CALL	MOJIHD
	CALL	ADRSIN
	JR	OPEPR9
OPEP13:	LD	A,(SBWORK+1)
	LD	HL,(ADSAV0)
	INC	HL
	INC	HL
	BIT	7,A
	JR	Z,OPEP15
	LD	E,A
	LD	D,0FFH
	ADD	HL,DE
	JR	OPEP12
OPEP15:	LD	E,A
	LD	D,0
	ADD	HL,DE
	JR	OPEP12

DIV8:	SRL	A
	SRL	A
	SRL	A
	RET

; ÊÞ²Ä½³¶¸Ä¸ & ÃÞ¨½±¾ÝÌÞ×
; OBYTE=ÊÞ²Ä½³ POPDT=Ë®³¼ÞÃÞ°À
GETBT:	PUSH	DE
	PUSH	HL
	LD	HL,OBYTE
	LD	DE,SBWORK
	LD	A,(DE)
	CP	40H
	JP	C,GETBT2
	CP	0C0H
	JP	NC,GETBT2
	LD	(HL),1
	INC	HL
	LD	A,(DE)
	CP	76H
	JR	NZ,GETBT3
	LD	(HL),17H
	INC	HL
	JP	GBEND
GETBT3:	PUSH	AF
	SUB	40H
	CALL	DIV8
	AND	0FH
	PUSH	AF
	CP	8
	JR	NC,GETBT4
	LD	(HL),1
	INC	HL
	POP	AF
	ADD	A,46H
	LD	(HL),A
	INC	HL
	JR	GETBT5
GETBT4:	SUB	6
	LD	(HL),A
	INC	HL
	POP	AF
	CP	0CH
	JR	NC,GETBT5
	CP	0AH
	JR	Z,GETBT5
	LD	A,4DH
	LD	(HL),A
	INC	HL
GETBT5:	POP	AF
	AND	7
	ADD	A,46H
	LD	(HL),A
	INC	HL
	JP	GBEND

GETBT2:	CP	0CBH
	JP	NZ,GETBT6
	LD	A,2
	LD	(HL),A
	INC	HL
	LD	A,(SBWORK+1)
	PUSH	AF
	CALL	DIV8
	CP	8
	JR	NC,GETBT7
	CP	6
	JP	NZ,GETBT9
	POP	AF
	LD	A,75H
	LD	(HL),A
	INC	HL
	JP	GBEND
GETBT9:	CP	7
	JR	NZ,GETB10
	DEC	A
GETB10:	ADD	A,22H
	LD	(HL),A
	INC	HL
GETBT8:	POP	AF
	AND	7
	ADD	A,46H
	LD	(HL),A
	INC	HL
	JP	GBEND
GETBT7:	PUSH	AF
	CALL	DIV8
	ADD	A,36H
	LD	(HL),A
	INC	HL
	POP	AF
	AND	7
	ADD	A,6CH
	LD	(HL),A
	INC	HL
	JR	GETBT8

GETBT6:	CP	0EDH
	JP	Z,GETB18
	CP	0DDH
	JP	Z,GETB11
	CP	0FDH
	JP	Z,GETB24
	CP	40H
	JR	C,GETB17
	SUB	80H
GETB17:	LD	DE,ASMOP
	PUSH	HL
	LD	H,0
	LD	L,A
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,DE
	EX	DE,HL
	POP	HL
GETB22:	LD	A,(DE)
	LD	(HL),A
	INC	HL
	LD	B,3
GETB14:	INC	DE
	LD	A,(DE)
	OR	A
	JP	Z,GBEND
	CP	52H
	JR	Z,GETB34
	CP	5EH
	JR	Z,GETB34
	CP	60H
	JR	Z,GETB34
	CP	62H
	JR	Z,GETB34
	CP	7CH
	JR	Z,GETB34
GETB32:	LD	(HL),A
	INC	HL
	DJNZ	GETB14
	JP	GBEND
GETB34:	LD	C,A
	LD	A,(SBWORK+4)
	ADD	A,C
	JR	GETB32

GETB19:	LD	(HL),2
	INC	HL
GETB26:	LD	A,75H
	LD	(HL),A
	INC	HL
	JP	GBEND
GETB18:	LD	IY,ASMOP1
GETB31:	LD	A,(SBWORK+1)
	LD	B,A
GETB20:	LD	A,(IY)
	CP	255
	JR	Z,GETB19
	INC	IY
	CP	B
	JR	Z,GETB23
GETB21:	LD	DE,4
	ADD	IY,DE
	JR	GETB20
GETB23:	PUSH	IY
	POP	DE
	JP	GETB22

GETB11:	XOR	A
	JR	GETB25
GETB24:	LD	A,1
GETB25:	LD	(SBWORK+4),A
	LD	A,(SBWORK+1)
	CP	0CBH
	JR	NZ,GETB29
	LD	(HL),4
	INC	HL
	LD	A,(SBWORK+3)
	LD	B,A
	CP	36H
	JR	Z,GETB26
	AND	7
	CP	6
	JR	NZ,GETB26
	LD	A,B
	CALL	DIV8
	CP	8
	JR	NC,GETB27
	CP	7
	JR	NZ,GETB28
	DEC	A
GETB28:	ADD	A,22H
	LD	(HL),A
	INC	HL
GETB30:	LD	A,(SBWORK+4)
	ADD	A,52H
	LD	(HL),A
	INC	HL
	JP	GBEND
GETB27:	PUSH	AF
	CALL	DIV8
	ADD	A,36H
	LD	(HL),A
	INC	HL
	POP	AF
	AND	7
	ADD	A,6CH
	LD	(HL),A
	INC	HL
	JR	GETB30

GETB29:	LD	IY,ASMOP2
	JP	GETB31

GBEND:	LD	(HL),0
	POP	HL
	POP	DE
	RET

; ±¾ÝÌÞ×
ASM:	LD	(SBWOK1+6),HL
	LD	HL,ASMWK
	LD	DE,ASMWK+1
	LD	BC,8
	XOR	A
	LD	(SBWOK1),A
	LD	(HL),A
	LDIR
ASM6:	LD	DE,OPSTR
	LD	(SBWOK1+2),DE
	XOR	A
ASM1:	INC	A
	LD	(SBWOK1+1),A
	LD	DE,(SBWOK1+2)
	LD	A,(DE)
	OR	A
	SCF
	RET	Z	;ERROR
	SUB	'0'
	PUSH	DE
	POP	HL
	LD	C,A
	LD	B,0
	INC	BC
	ADD	HL,BC
	LD	(SBWOK1+2),HL
	LD	HL,(SBWOK1+6)
	LD	B,A
ASM2:	INC	DE
	LD	A,(DE)
	CP	'a'
	JR	C,ASM3
	CP	'z'+1
	JR	NC,ASM3
	PUSH	DE
	PUSH	BC
	CALL	CVAL
	POP	BC
	JR	NC,ASM4
	POP	AF
ASM8:	LD	A,(SBWOK1+1)
	JR	ASM1
ASM3:	CP	(HL)
	JR	NZ,ASM8
	INC	HL
	JR	ASM9
ASM4:	PUSH	HL
	PUSH	BC
	LD	BC,ASMWK+3
	LD	A,(SBWOK1)
	ADD	A,A
	LD	L,A
	LD	H,0
	ADD	HL,BC
	LD	(HL),E
	INC	HL
	LD	(HL),D
	POP	BC
	POP	HL
	POP	DE
ASM9:	DEC	B
	JP	NZ,ASM2
	LD	A,(HL)
	OR	A
	JR	Z,ASM7
	CP	','
	JR	Z,ASM7
	CP	' '
	JR	NZ,ASM8
ASM11:	INC	HL
	LD	A,(HL)
	CP	' '
	JR	Z,ASM11
	DEC	HL
ASM7:	LD	B,A
	INC	HL
	LD	(SBWOK1+6),HL
	LD	A,(SBWOK1)
	LD	DE,ASMWK
	LD	L,A
	LD	H,0
	ADD	HL,DE
	LD	A,(SBWOK1+1)
	LD	(HL),A
	LD	A,(SBWOK1)
	INC	A
	LD	(SBWOK1),A
	CP	3
	JR	Z,ASM10
	LD	A,B
	OR	A
	JP	NZ,ASM6
	INC	HL
	LD	(HL),A
ASM10:	XOR	A
	LD	(SBWOK1),A
	LD 	A,(ASMWK)
	CP	1AH	;IM
	JR	Z,ASM13
	CP	37H	;BIT
	JR	C,ASM12
	CP	39H+1	;SET
	JR	NC,ASM12
ASM13:	LD	(SBWOK1),A
ASM12:	LD	HL,ASMWK+1
	LD	DE,ASMWK+5
	LD	B,2
ASM14:	LD	A,(SBWOK1)
	OR	A
	JR	NZ,ASM15
	LD	A,(HL)
	SUB	6CH
	JR	C,ASM15
	CP	9
	JR	NC,ASM15
	LD	(DE),A
	INC	DE
	XOR	A
	LD	(DE),A
	DEC	DE
	LD	A,7EH
	LD	(HL),A
ASM15:	LD	A,(HL)
	SUB	7CH
	JR	Z,ASM16
	CP	1
	JR	NZ,ASM17
ASM16:	ADD	A,52H
	LD	(HL),A
	XOR	A
	LD	(DE),A
	INC	DE
	LD	(DE),A
	DEC	DE
ASM17:	INC	HL
	INC	DE
	INC	DE
	DJNZ	ASM14
	LD	IX,ASMWK1
	LD	HL,ASMWK
	LD	A,(HL)
	DEC	A
	JR	NZ,ASM19
	LD	B,2
ASM20:	INC	HL
	LD	A,(HL)
	CP	46H
	JR	C,ASM19
	CP	4DH+1
	JR	NC,ASM19
	DJNZ	ASM20
	DEC	HL
	LD	A,1
	LD	(IX),A
	LD	A,(HL)
	SUB	46H
	RLA
	RLA
	RLA
	ADD	A,40H
	LD	B,A
	INC	HL
	LD	A,(HL)
	SUB	46H
	ADD	A,B
	LD	(IX+1),A
	OR	A
	RET
ASM19:	LD	HL,ASMWK
	LD	A,(HL)
	SUB	22H
	JR	C,ASM21
	CP	7
	JR	NC,ASM21
	CP	6
	JR	NZ,ASM22
	INC	A
ASM22:	OR	A
	RLA
	RLA
	RLA
	LD	B,A
	INC	HL
	LD	A,(HL)
	SUB	46H
	JR	C,ASM21
	CP	8
	JR	NC,ASM21
ASM25:	ADD	A,B
	LD	(IX+2),A
	LD	(IX),2
	LD	(IX+1),0CBH
	OR	A
	RET
ASM21:	LD	HL,ASMWK
	LD 	A,(HL)
	SUB	37H
	JR	C,ASM23
	CP	3
	JR	NC,ASM23
	LD	B,A
	INC	B
	XOR	A
ASM24:	ADD	A,40H
	DJNZ	ASM24
	LD	B,A
	INC	HL
	LD	A,(HL)
	SUB	6CH
	JR	C,ASM23
	CP	8
	JR	NC,ASM23
	OR	A
	RLA
	RLA
	RLA
	ADD	A,B
	LD 	B,A
	INC	HL
	LD 	A,(HL)
	SUB	46H
	JR	C,ASM23
	CP	8
	JR	C,ASM25
ASM23:	LD	HL,ASMWK
	LD	A,(HL)
	CP	17H
	JR	NZ,ASM99
	LD	(IX),1
	LD	(IX+1),76H
	OR	A
	RET
ASM99:	SUB	2
	JR	C,ASM26
	CP	8
	JR	NC,ASM26
	LD	C,A
	OR	A
	RLA
	RLA
	RLA
	ADD	A,80H
	LD	B,A
	LD	A,C
	CP	2
	JR	Z,ASM27
	CP	4
	JR	NC,ASM27
	INC	HL
	LD	A,(HL)
	CP	4DH
	JR	NZ,ASM26
ASM27:	INC	HL
	LD	A,(HL)
	SUB	46H
	JR	C,ASM26
	CP	8
	JR	NC,ASM26
	ADD	A,B
	LD	(IX),1
	LD	(IX+1),A
	OR	A
	RET
ASM26:	XOR	A
	LD	(SBWOK1),A
	LD	HL,ASMDT
ASM31:	LD	B,(HL)
	INC	B
	DEC	B
	JP	Z,ASM32
	LD	C,B
	LD	DE,ASMWK
	PUSH	HL
ASM28:	INC	HL
	LD	A,(DE)
	CP	(HL)
	JR	NZ,ASM29
	INC	DE
	DJNZ	ASM28
	POP	AF
	INC	HL
	LD	(IX),1
	LD	A,(SBWOK1)
	LD	(IX+1),A
	LD	A,(HL)
	OR	A
	CALL	NZ,ASSUB
	OR	A
	RET
ASM29:	LD	HL,SBWOK1
	LD	A,(HL)
	INC	A
	LD	(HL),A
	CP	40H
	JR	NZ,ASM33
	LD	(HL),0C0H
ASM33:	POP	HL
	LD	B,0
	ADD	HL,BC
	INC	HL
	INC	HL
	JR	ASM31
ASM32:	LD	HL,ASMDT1
ASM37:	LD	B,(HL)
	INC	B
	DEC	B
	JP	Z,ASM34
	LD	C,B
	LD	DE,ASMWK
	PUSH	HL
ASM35:	INC	HL
	LD	A,(DE)
	CP	(HL)
	JR	NZ,ASM36
	INC	DE
	DJNZ	ASM35
	POP	AF
	INC	HL
	LD	(IX),2
	LD	(IX+1),0EDH
	LD	A,(HL)
	LD	(IX+2),A
	INC	HL
	LD	A,(HL)
	OR	A
	CALL	NZ,ASSUB
	OR	A
	RET
ASM36:	POP	HL
	LD	B,0
	ADD	HL,BC
	INC	HL
	INC	HL
	INC	HL
	JR	ASM37
ASM34:	LD	A,0DDH
	LD	(SBWOK1),A
	LD	B,2
	LD	HL,ASMWK+1
ASM39:	LD	A,(HL)
	CP	53H
	JR	Z,ASM38
	CP	5FH
	JR	Z,ASM38
	CP	61H
	JR	Z,ASM38
	CP	63H
	JR	Z,ASM38
ASM41:	INC	HL
	DJNZ	ASM39
	JR	ASM40
ASM38:	LD	A,0FDH
	LD	(SBWOK1),A
	DEC	(HL)
	JR	ASM41
ASM40:	LD	HL,ASMDT2
ASM44:	LD	B,(HL)
	INC	B
	DEC	B
	SCF
	RET	Z
	LD	C,B
	LD	DE,ASMWK
	PUSH	HL
ASM43:	INC	HL
	LD	A,(DE)
	CP	(HL)
	JR	NZ,ASM42
	INC	DE
	DJNZ	ASM43
	POP	AF
	INC	HL
	LD	(IX),2
	LD	A,(SBWOK1)
	LD	(IX+1),A
	LD	A,(HL)
	LD	(IX+2),A
	INC	HL
	LD	A,(HL)
	OR	A
	CALL	NZ,ASSUB
	OR	A
	RET
ASM42:	POP	HL
	LD	B,0
	ADD	HL,BC
	INC	HL
	INC	HL
	INC	HL
	JR	ASM44

; ±¾ÝÌÞ×»ÌÞ
ASSUB:	DEC	A
	JR	Z,ASSUB1
	DEC	A
	JR	Z,ASSUB2
	DEC	A
	JR	Z,ASSUB3
	DEC	A
	JR	Z,ASSUB6
	DEC	A
	JR	Z,ASSUB8
	DEC	A
	JR	Z,ASSB10
	DEC	A
	JP	Z,ASSB12
	DEC	A
	JP	Z,ASSB14
	DEC	A
	JP	Z,ASSB15
	DEC	A
	JP	Z,ASSB17
	DEC	A
	JP	Z,ASSB18
	DEC	A
	JP	Z,ASSB20
	DEC	A
	JP	Z,ASSB21
	DEC	A
	JP	Z,ASSB22
	DEC	A
	JP	Z,ASSB23
	RET
ASSUB1:	LD	HL,(ASMWK+7)
ASSUB9:	LD	(IX+2),L
	LD	(IX+3),H
	INC	(IX)
	INC	(IX)
	RET
ASSUB2:	LD	A,(ASMWK+7)
ASSB13:	LD	(IX+2),A
	INC	(IX)
	RET
ASSUB3:	LD	HL,(ASMWK+5)
ASSUB7:	LD	A,1
	LD	(JRFG),A
	LD	BC,(ADXWK0)
	INC	BC
	INC	BC
	XOR	A
	SBC	HL,BC
	EX	DE,HL
	LD	HL,007FH
	OR	A
	SBC	HL,DE
	JR	NC,ASSUB4
	LD	HL,0FF7FH
	OR	A
	SBC	HL,DE
	JR	C,ASSUB4
	INC	A
ASSUB4:	OR	A
	JR	Z,ASSUB5
ASSB11:	POP	AF
	SCF
	RET
ASSUB5:	LD	(IX+2),E
	INC	(IX)
	RET
ASSUB6:	LD	HL,(ASMWK+7)
	JR	ASSUB7
ASSUB8:	LD	HL,(ASMWK+5)
	JR	ASSUB9
ASSB10:	LD	HL,(ASMWK+5)
	LD	A,H
	OR	A
	JR	NZ,ASSB11
	LD	A,L
	AND	0C7H
	JR	NZ,ASSB11
	LD	A,L
	ADD	A,0C7H
	LD	(IX+1),A
	RET
ASSB12:	LD	A,(ASMWK+5)
	JR	ASSB13
ASSB14:	LD	HL,(ASMWK+5)
ASSB16:	LD	(IX+3),L
	LD	(IX+4),H
	INC	(IX)
	INC	(IX)
	RET
ASSB15:	LD	HL,(ASMWK+7)
	JR	ASSB16
ASSB17:	INC	(IX)
	LD	A,(ASMWK+7)
ASSB19:	LD	(IX+3),A
	RET
ASSB18:	INC	(IX)
	LD	A,(ASMWK+5)
	JR	ASSB19
ASSB20:	CALL	ASSB18
	INC	(IX)
	LD	A,(ASMWK+7)
	LD	(IX+4),A
	RET
ASSB21:	LD	HL,(ASMWK+5)
	LD	A,H
	OR	L
	RET	Z
	POP	AF
	SCF
	RET
ASSB22:	CALL	ASSB24
	JR	ASSB18
ASSB23:	CALL	ASSB24
	JR	ASSB17
ASSB24:	INC	(IX)
	LD	A,(IX+2)
	LD	(IX+4),A
	LD	A,0CBH
	LD	(IX+2),A
	RET

OPSTR:	DEFM '2LD3ADD3ADC3SUB3SBC3AND3XOR2OR2CP3INC3DEC4PUSH3POP3LDI4LDIR3LDD'
	DEFM '4LDDR3CPI4CPIR3CPD4CPDR3NOP4HALT2DI2EI2IM3DAA3CPL3NEG3CCF3SCF2EX'
	DEFM '3EXX3RLC3RRC2RL2RR3SLA3SRA3SRL3RLD3RRD4RLCA4RRCA3RLA3RRA2JP2JR'
	DEFM '4CALL4DJNZ3RET4RETI4RETN3RST3BIT3RES3SET2IN3INI4INIR3IND4INDR'
	DEFM '3OUT4OUTI4OTIR4OUTD4OTDR5MULUB5MULUW1B1C1D1E1H1L4(HL)1A4(BC)'
	DEFM '4(DE)4(SP)3(C)5(IXb)5(IYb)1A1A1I1R1,2BC2DE2HL2AF2SP2IX2IY3IXH'
	DEFM '3IYH3IXL3IYL2NZ2NC2PO1P1Z1C2PE1M1011121314151617183???3(d)3(e)'
	DEFM "3(a)3(b)3(c)3AF'4(IX)4(IY)1a"
	DEFB 0

ASMOP:
        DEFB 1,16H,0,0
        DEFB 3,1,59H,83H
        DEFB 1,1,4EH,4DH
        DEFB 1,0AH,59H,0
        DEFB 1,0AH,46H,0
        DEFB 1,0BH,46H,0
        DEFB 2,1,46H,80H
        DEFB 1,2BH,0,0
        DEFB 1,20H,5CH,7BH
        DEFB 1,2,5BH,59H
        DEFB 1,1,4DH,4EH
        DEFB 1,0BH,59H,0
        DEFB 1,0AH,47H,0
        DEFB 1,0BH,47H,0
        DEFB 2,1,47H,80H
        DEFB 1,2CH,0,0
        
        DEFB 2,32H,85H,0
        DEFB 3,1,5AH,83H
        DEFB 1,1,4FH,4DH
        DEFB 1,0AH,5AH,0
        DEFB 1,0AH,48H,0
        DEFB 1,0BH,48H,0
        DEFB 2,01H,48H,80H
        DEFB 1,2DH,0,0
        DEFB 2,30H,85H,0
        DEFB 1,2,5BH,5AH
        DEFB 1,1,4DH,4FH
        DEFB 1,0BH,5AH,0
        DEFB 1,0AH,49H,0
        DEFB 1,0BH,49H,0
        DEFB 2,1,49H,80H
        DEFB 1,2EH,0,0
        
        DEFB 2,30H,64H,85H
        DEFB 3,1,5BH,83H
        DEFB 3,1,76H,5BH
        DEFB 1,0AH,5BH,0
        DEFB 1,0AH,4AH,0
        DEFB 1,0BH,4AH,0
        DEFB 2,1,4AH,80H
        DEFB 1,1BH,0,0
        DEFB 2,30H,68H,85H
        DEFB 1,2,5BH,5BH
        DEFB 3,1,5BH,76H
        DEFB 1,0BH,5BH,0
        DEFB 1,0AH,4BH,0
        DEFB 1,0BH,4BH,0
        DEFB 2,1,4BH,80H
        DEFB 1,1CH,0,0
        
        DEFB 2,30H,65H,85H
        DEFB 3,1,5DH,83H
        DEFB 3,1,76H,4DH
        DEFB 1,0AH,5DH,0
        DEFB 1,0AH,4CH,0
        DEFB 1,0BH,4CH,0
        DEFB 2,1,4CH,80H
        DEFB 1,1FH,0,0
        DEFB 2,30H,69H,85H
        DEFB 1,2,5BH,5DH
        DEFB 3,1,4DH,76H
        DEFB 1,0BH,5DH,0
        DEFB 1,0AH,4DH,0
        DEFB 1,0BH,4DH,0
        DEFB 2,1,4DH,80H
        DEFB 1,1EH,0,0
        
        DEFB 1,33H,64H,0
        DEFB 1,0DH,59H,0
        DEFB 3,2FH,64H,83H
        DEFB 3,2FH,83H,0
        DEFB 3,31H,64H,83H
        DEFB 1,0CH,59H,0
        DEFB 2,2,4DH,80H
        DEFB 1,36H,87H,0
        DEFB 1,33H,68H,0
        DEFB 1,33H,0,0
        DEFB 3,2FH,68H,83H
        DEFB 0,0,0,0
        DEFB 3,31H,68H,83H
        DEFB 3,31H,83H,0
        DEFB 2,3,4DH,80H
        DEFB 1,36H,87H,8
        
        DEFB 1,33H,65H,0
        DEFB 1,0DH,5AH,0
        DEFB 3,2FH,65H,83H
        DEFB 2,3FH,78H,4DH
        DEFB 3,31H,65H,83H
        DEFB 1,0CH,5AH,0
        DEFB 2,04H,80H,0
        DEFB 1,36H,87H,10H
        DEFB 1,33H,69H,0
        DEFB 1,21H,0,0
        DEFB 3,2FH,69H,83H
        DEFB 2,3AH,4DH,78H
        DEFB 3,31H,69H,83H
        DEFB 0,0,0,0
        DEFB 2,5,4DH,80H
        DEFB 1,36H,87H,18H
        
        DEFB 1,33H,66H,0
        DEFB 1,0DH,5BH,0
        DEFB 3,2FH,66H,83H
        DEFB 1,20H,50H,5BH
        DEFB 3,31H,66H,83H
        DEFB 1,0CH,5BH,0
        DEFB 2,06H,80H,0
        DEFB 1,36H,87H,20H
        DEFB 1,33H,6AH,0
        DEFB 1,2FH,4CH,0
        DEFB 3,2FH,6AH,83H
        DEFB 1,20H,5AH,5BH
        DEFB 3,31H,6AH,83H
        DEFB 0,0,0,0
        DEFB 2,07H,80H,0
        DEFB 1,36H,87H,28H
        
        DEFB 1,33H,67H,0
        DEFB 1,0DH,5CH,0
        DEFB 3,2FH,67H,83H
        DEFB 1,18H,0,0
        DEFB 3,31H,67H,83H
        DEFB 1,0CH,5CH,0
        DEFB 2,08H,80H,0
        DEFB 1,36H,87H,30H
        DEFB 1,33H,6BH,0
        DEFB 1,1,5DH,5BH
        DEFB 3,2FH,6BH,83H
        DEFB 1,19H,0,0
        DEFB 3,31H,6BH,83H
        DEFB 0,0,0,0
        DEFB 2,9,80H,0
        DEFB 1,36H,87H,38H

ASMOP1:
        DEFB 40H,2,3AH,46H,51H
        DEFB 41H,2,3FH,51H,46H
        DEFB 42H,2,5,5BH,59H
        DEFB 43H,4,1,77H,59H
        DEFB 44H,2,1DH,0,0
        DEFB 45H,2,35H,0,0
        DEFB 46H,2,1AH,6CH,0
        DEFB 47H,2,1,56H,4DH
        DEFB 48H,2,3AH,47H,51H
        DEFB 49H,2,3FH,51H,47H
        DEFB 4AH,2,3,5BH,59H
        DEFB 4BH,4,1,59H,77H
        DEFB 4DH,2,34H,0,0
        DEFB 4FH,2,1,57H,4DH
        DEFB 50H,2,3AH,48H,51H
        DEFB 51H,2,3FH,51H,48H
        DEFB 52H,2,5,5BH,5AH
        DEFB 53H,4,1,77H,5AH
        DEFB 56H,2,1AH,6DH,0
        DEFB 57H,2,1,4DH,56H
        DEFB 58H,2,3AH,49H,51H
        DEFB 59H,2,3FH,51H,49H
        DEFB 5AH,2,3,5BH,5AH
        DEFB 5BH,4,1,5AH,77H
        DEFB 5EH,2,1AH,6EH,0
        DEFB 5FH,2,1,4DH,57H
        DEFB 60H,2,3AH,4AH,51H
        DEFB 61H,2,3FH,51H,4AH
        DEFB 62H,2,5,5BH,5BH
        DEFB 67H,2,2AH,0,0
        DEFB 68H,2,3AH,4BH,51H
        DEFB 69H,2,3FH,51H,4BH
        DEFB 6AH,2,3,5BH,5BH
        DEFB 6FH,2,29H,0,0
        DEFB 70H,2,3AH,4CH,51H
        DEFB 72H,2,5,5BH,5DH
        DEFB 73H,4,1,77H,5DH
        DEFB 78H,2,3AH,4DH,51H
        DEFB 79H,2,3FH,51H,4DH
        DEFB 7AH,2,3,5BH,5DH
        DEFB 7BH,4,1,5DH,77H
        DEFB 0A0H,2,0EH,0,0
        DEFB 0A1H,2,12H,0,0
        DEFB 0A2H,2,3BH,0,0
        DEFB 0A3H,2,40H,0,0
        DEFB 0A8H,2,10H,0,0
        DEFB 0A9H,2,14H,0,0
        DEFB 0AAH,2,3DH,0,0
        DEFB 0ABH,2,42H,0,0
        DEFB 0B0H,2,0FH,0,0
        DEFB 0B1H,2,13H,0,0
        DEFB 0B2H,2,3CH,0,0
        DEFB 0B3H,2,41H,0,0
        DEFB 0B8H,2,11H,0,0
        DEFB 0B9H,2,15H,0,0
        DEFB 0BAH,2,3EH,0,0
        DEFB 0BBH,2,43H,0,0
        DEFB 0C1H,2,44H,4DH,46H
        DEFB 0C3H,2,45H,5BH,59H
        DEFB 0C9H,2,44H,4DH,47H
        DEFB 0D1H,2,44H,4DH,48H
        DEFB 0D3H,2,45H,5BH,5AH
        DEFB 0D9H,2,44H,4DH,49H
        DEFB 0E1H,2,44H,4DH,4AH
        DEFB 0E3H,2,45H,5BH,5BH
        DEFB 0E9H,2,44H,4DH,4BH
        DEFB 0F3H,2,45H,5BH,5DH
        DEFB 0F9H,2,44H,4DH,4DH
        DEFB 0FFH

ASMOP2:
        DEFB 7EH,3,1,4DH,52H
        DEFB 46H,3,1,46H,52H
        DEFB 4EH,3,1,47H,52H
        DEFB 56H,3,1,48H,52H
        DEFB 5EH,3,1,49H,52H
        DEFB 66H,3,1,4AH,52H
        DEFB 6EH,3,1,4BH,52H
        DEFB 77H,3,1,52H,4DH
        DEFB 70H,3,1,52H,46H
        DEFB 71H,3,1,52H,47H
        DEFB 72H,3,1,52H,48H
        DEFB 73H,3,1,52H,49H
        DEFB 74H,3,1,52H,4AH
        DEFB 75H,3,1,52H,4BH
        DEFB 36H,4,1,52H,82H
        DEFB 21H,4,1,5EH,84H
        DEFB 2AH,4,1,5EH,77H
        DEFB 22H,4,1,77H,5EH
        DEFB 0E5H,2,0CH,5EH,0
        DEFB 0E1H,2,0DH,5EH,0
        DEFB 0F9H,2,1,5DH,5EH
        DEFB 86H,3,2,4DH,52H
        DEFB 8EH,3,3,4DH,52H
        DEFB 96H,3,4,52H,0
        DEFB 9EH,3,5,4DH,52H
        DEFB 0A6H,3,6,52H,0
        DEFB 0AEH,3,7,52H,0
        DEFB 0B6H,3,8,52H,0
        DEFB 0BEH,3,9,52H,0
        DEFB 34H,3,0AH,52H,0
        DEFB 35H,3,0BH,52H,0
        DEFB 0E3H,2,20H,50H,5EH
        DEFB 9,2,2,5EH,59H
        DEFB 19H,2,2,5EH,5AH
        DEFB 29H,2,2,5EH,5EH
        DEFB 39H,2,2,5EH,5DH
        DEFB 23H,2,0AH,5EH,0
        DEFB 2BH,2,0BH,5EH,0
        DEFB 0E9H,2,2FH,7CH,0
        DEFB 7CH,2,1,4DH,60H
        DEFB 7DH,2,1,4DH,62H
        DEFB 44H,2,1,46H,60H
        DEFB 45H,2,1,46H,62H
        DEFB 4CH,2,1,47H,60H
        DEFB 4DH,2,1,47H,62H
        DEFB 54H,2,1,48H,60H
        DEFB 55H,2,1,48H,62H
        DEFB 5CH,2,1,49H,60H
        DEFB 5DH,2,1,49H,62H
        DEFB 64H,2,1,60H,60H
        DEFB 65H,2,1,60H,62H
        DEFB 6CH,2,1,62H,60H
        DEFB 6DH,2,1,62H,62H
        DEFB 67H,2,1,60H,4DH
        DEFB 60H,2,1,60H,46H
        DEFB 61H,2,1,60H,47H
        DEFB 62H,2,1,60H,48H
        DEFB 63H,2,1,60H,49H
        DEFB 6FH,2,1,62H,4DH
        DEFB 68H,2,1,62H,46H
        DEFB 69H,2,1,62H,47H
        DEFB 6AH,2,1,62H,48H
        DEFB 6BH,2,1,62H,49H
        DEFB 26H,3,1,60H,88H
        DEFB 2EH,3,1,62H,88H
        DEFB 84H,2,2,4DH,60H
        DEFB 85H,2,2,4DH,62H
        DEFB 8CH,2,3,4DH,60H
        DEFB 8DH,2,3,4DH,62H
        DEFB 94H,2,4,60H,0
        DEFB 95H,2,4,62H,0
        DEFB 9CH,2,5,4DH,60H
        DEFB 9DH,2,5,4DH,62H
        DEFB 0A4H,2,6,60H,0
        DEFB 0A5H,2,6,62H,0
        DEFB 0ACH,2,7,60H,0
        DEFB 0ADH,2,7,62H,0
        DEFB 0B4H,2,8,60H,0
        DEFB 0B5H,2,8,62H,0
        DEFB 0BCH,2,9,60H,0
        DEFB 0BDH,2,9,62H,0
        DEFB 24H,2,0AH,60H,0
        DEFB 2CH,2,0AH,62H,0
        DEFB 25H,2,0BH,60H,0
        DEFB 2DH,2,0BH,62H,0
        DEFB 0FFH

ASMDT:
        DEFB 1,16H,0
        DEFB 3,01H,59H,7EH,1
        DEFB 3,01H,4EH,4DH,0
        DEFB 2,0AH,59H,0
        DEFB 2,0AH,46H,0
        DEFB 2,0BH,46H,0
        DEFB 3,01H,46H,7EH,2
        DEFB 1,2BH,0
        DEFB 3,20H,5CH,7BH,0
        DEFB 3,02H,5BH,59H,0
        DEFB 3,01H,4DH,4EH,0
        DEFB 2,0BH,59H,0
        DEFB 2,0AH,47H,0
        DEFB 2,0BH,47H,0
        DEFB 3,01H,47H,7EH,2
        DEFB 1,2CH,0
        
        DEFB 2,32H,7EH,3
        DEFB 3,01H,5AH,7EH,1
        DEFB 3,01H,4FH,4DH,0
        DEFB 2,0AH,5AH,0
        DEFB 2,0AH,48H,0
        DEFB 2,0BH,48H,0
        DEFB 3,01H,48H,7EH,2
        DEFB 1,2DH,0
        DEFB 2,30H,7EH,3
        DEFB 3,02H,5BH,5AH,0
        DEFB 3,01H,4DH,4FH,0
        DEFB 2,0BH,5AH,0
        DEFB 2,0AH,49H,0
        DEFB 2,0BH,49H,0
        DEFB 3,01H,49H,7EH,2
        DEFB 1,2EH,0
        
        DEFB 3,30H,64H,7EH,4
        DEFB 3,01H,5BH,7EH,1
        DEFB 3,01H,76H,5BH,5
        DEFB 2,0AH,5BH,0
        DEFB 2,0AH,4AH,0
        DEFB 2,0BH,4AH,0
        DEFB 3,01H,4AH,7EH,2
        DEFB 1,1BH,0
        DEFB 3,30H,68H,7EH,4
        DEFB 3,02H,5BH,5BH,0
        DEFB 3,01H,5BH,76H,1
        DEFB 2,0BH,5BH,0
        DEFB 2,0AH,4BH,0
        DEFB 2,0BH,4BH,0
        DEFB 3,01H,4BH,7EH,2
        DEFB 1,1CH,0
        
        DEFB 3,30H,65H,7EH,4
        DEFB 3,01H,5DH,7EH,1
        DEFB 3,01H,76H,4DH,5
        DEFB 2,0AH,5DH,0
        DEFB 2,0AH,4CH,0
        DEFB 2,0BH,4CH,0
        DEFB 3,01H,4CH,7EH,2
        DEFB 1,1FH,0
        DEFB 3,30H,47H,7EH,4
        DEFB 3,02H,5BH,5DH,0
        DEFB 3,01H,4DH,76H,1
        DEFB 2,0BH,5DH,0
        DEFB 2,0AH,4DH,0
        DEFB 2,0BH,4DH,0
        DEFB 3,01H,4DH,7EH,2
        DEFB 1,1EH,0
        
        DEFB 2,33H,64H,0
        DEFB 2,0DH,59H,0
        DEFB 3,2FH,64H,7EH,1
        DEFB 2,2FH,7EH,5
        DEFB 3,31H,64H,7EH,1
        DEFB 2,0CH,59H,0
        DEFB 3,02H,4DH,7EH,2
        DEFB 2,36H,7EH,6
        DEFB 2,33H,68H,0
        DEFB 2,33H,0,0
        DEFB 3,2FH,68H,7EH,1
        DEFB 1,0,0
        DEFB 3,31H,68H,7EH,1
        DEFB 2,31H,7EH,5
        DEFB 3,03H,4DH,7EH,2
        DEFB 1,0,0
        
        DEFB 2,33H,65H,0
        DEFB 2,0DH,5AH,0
        DEFB 3,2FH,65H,7EH,1
        DEFB 3,3FH,76H,4DH,7
        DEFB 3,31H,65H,7EH,1
        DEFB 2,0CH,5AH,0
        DEFB 2,04H,7EH,7
        DEFB 1,0,0
        DEFB 2,33H,47H,0
        DEFB 1,21H,0
        DEFB 3,2FH,47H,7EH,1
        DEFB 3,3AH,4DH,76H,2
        DEFB 3,31H,47H,7EH,1
        DEFB 1,0,0
        DEFB 3,05H,4DH,7EH,2
        DEFB 1,0,0
        
        DEFB 2,33H,66H,0
        DEFB 2,0DH,5BH,0
        DEFB 3,2FH,66H,7EH,1
        DEFB 3,20H,50H,5BH,0
        DEFB 3,31H,66H,7EH,1
        DEFB 2,0CH,5BH,0
        DEFB 2,06H,7EH,7
        DEFB 1,0,0
        DEFB 2,33H,6AH,0
        DEFB 2,2FH,4CH,0
        DEFB 3,2FH,6AH,7EH,1
        DEFB 3,20H,5AH,5BH,0
        DEFB 3,31H,6AH,7EH,1
        DEFB 1,0,0
        DEFB 2,07H,7EH,7
        DEFB 1,0,0
        
        DEFB 2,33H,67H,0
        DEFB 2,0DH,5CH,0
        DEFB 3,2FH,67H,7EH,1
        DEFB 1,18H,0
        DEFB 3,31H,67H,7EH,1
        DEFB 2,0CH,5CH,0
        DEFB 2,08H,7EH,7
        DEFB 1,0,0
        DEFB 2,33H,6BH,0
        DEFB 3,01H,5DH,5BH,0
        DEFB 3,2FH,6BH,7EH,1
        DEFB 1,19H,0
        DEFB 3,31H,6BH,7EH,1
        DEFB 1,0,0
        DEFB 2,09H,7EH,7
        DEFB 1,0,0
        DEFB 0

ASMDT1:
        DEFB 3,3AH,46H,51H,40H,0
        DEFB 3,3FH,51H,46H,41H,0
        DEFB 3,05H,5BH,59H,42H,0
        DEFB 3,01H,76H,59H,43H,8
        DEFB 1,1DH,44H,0
        DEFB 1,35H,45H,0
        DEFB 2,1AH,6CH,46H,0
        DEFB 3,01H,56H,4DH,47H,0
        DEFB 3,3AH,47H,51H,48H,0
        DEFB 3,3FH,51H,47H,49H,0
        DEFB 3,03H,5BH,59H,4AH,0
        DEFB 3,01H,59H,76H,4BH,9
        DEFB 1,34H,4DH,0
        DEFB 3,01H,57H,4DH,4FH,0
        DEFB 3,3AH,48H,51H,50H,0
        DEFB 3,3FH,51H,48H,51H,0
        DEFB 3,05H,5BH,5AH,52H,0
        DEFB 3,01H,76H,5AH,53H,8
        DEFB 2,1AH,6DH,56H,0
        DEFB 3,01H,4DH,56H,57H,0
        DEFB 3,3AH,49H,51H,58H,0
        DEFB 3,3FH,51H,49H,59H,0
        DEFB 3,03H,5BH,5AH,5AH,0
        DEFB 3,01H,5AH,76H,5BH,9
        DEFB 2,1AH,6EH,5EH,0
        DEFB 3,01H,4DH,57H,5FH,0
        DEFB 3,3AH,4AH,51H,60H,0
        DEFB 3,3FH,51H,4AH,61H,0
        DEFB 3,05H,5BH,5BH,62H,0
        DEFB 1,2AH,67H,0
        DEFB 3,3AH,4BH,51H,68H,0
        DEFB 3,3FH,51H,4BH,69H,0
        DEFB 3,03H,5BH,5BH,6AH,0
        DEFB 1,29H,6FH,0
        DEFB 3,3AH,4CH,51H,70H,0
        DEFB 3,05H,5BH,5DH,72H,0
        DEFB 3,01H,76H,5DH,73H,8
        DEFB 3,3AH,4DH,51H,78H,0
        DEFB 3,3FH,51H,4DH,79H,0
        DEFB 3,03H,5BH,5DH,7AH,0
        DEFB 3,01H,5DH,76H,7BH,9
        DEFB 1,0EH,0A0H,0
        DEFB 1,12H,0A1H,0
        DEFB 1,3BH,0A2H,0
        DEFB 1,40H,0A3H,0
        DEFB 1,10H,0A8H,0
        DEFB 1,14H,0A9H,0
        DEFB 1,3DH,0AAH,0
        DEFB 1,42H,0ABH,0
        DEFB 1,0FH,0B0H,0
        DEFB 1,13H,0B1H,0
        DEFB 1,3CH,0B2H,0
        DEFB 1,41H,0B3H,0
        DEFB 1,11H,0B8H,0
        DEFB 1,15H,0B9H,0
        DEFB 1,3EH,0BAH,0
        DEFB 1,43H,0BBH,0
        DEFB 3,44H,4DH,46H,0C1H,0
        DEFB 3,44H,4DH,47H,0C9H,0
        DEFB 3,44H,4DH,48H,0D1H,0
        DEFB 3,44H,4DH,49H,0D9H,0
        DEFB 3,44H,4DH,4AH,0E1H,0
        DEFB 3,44H,4DH,4BH,0E9H,0
        DEFB 3,44H,4DH,4DH,0F9H,0
        DEFB 3,45H,5BH,59H,0C3H,0
        DEFB 3,45H,5BH,5AH,0D3H,0
        DEFB 3,45H,5BH,5BH,0E3H,0
        DEFB 3,45H,5BH,5DH,0F3H,0
        DEFB 0

ASMDT2:
        DEFB 3,01H,4DH,52H,7EH,10
        DEFB 3,01H,46H,52H,46H,10
        DEFB 3,01H,47H,52H,4EH,10
        DEFB 3,01H,48H,52H,56H,10
        DEFB 3,01H,49H,52H,5EH,10
        DEFB 3,01H,4AH,52H,66H,10
        DEFB 3,01H,4BH,52H,6EH,10
        DEFB 3,01H,52H,4DH,77H,11
        DEFB 3,01H,52H,46H,70H,11
        DEFB 3,01H,52H,47H,71H,11
        DEFB 3,01H,52H,48H,72H,11
        DEFB 3,01H,52H,49H,73H,11
        DEFB 3,01H,52H,4AH,74H,11
        DEFB 3,01H,52H,4BH,75H,11
        DEFB 3,01H,52H,7EH,36H,12
        DEFB 3,01H,5DH,5EH,0F9H,0
        DEFB 3,01H,5EH,7EH,21H,9
        DEFB 3,01H,5EH,76H,2AH,9
        DEFB 3,01H,76H,5EH,22H,8
        DEFB 2,0CH,5EH,0E5H,0
        DEFB 2,0DH,5EH,0E1H,0
        DEFB 3,02H,4DH,52H,86H,10
        DEFB 3,03H,4DH,52H,8EH,10
        DEFB 2,04H,52H,96H,11
        DEFB 3,05H,4DH,52H,9EH,10
        DEFB 2,06H,52H,0A6H,11
        DEFB 2,07H,52H,0AEH,11
        DEFB 2,08H,52H,0B6H,11
        DEFB 2,09H,52H,0BEH,11
        DEFB 2,0AH,52H,34H,11
        DEFB 2,0BH,52H,35H,11
        DEFB 3,20H,50H,5EH,0E3H,0
        DEFB 3,02H,5EH,59H,09H,0
        DEFB 3,02H,5EH,5AH,19H,0
        DEFB 3,02H,5EH,5DH,39H,0
        DEFB 3,02H,5EH,5EH,29H,0
        DEFB 2,0AH,5EH,23H,0
        DEFB 2,0BH,5EH,2BH,0
        DEFB 2,2FH,52H,0E9H,13
        DEFB 2,22H,52H,06H,14
        DEFB 2,23H,52H,0EH,14
        DEFB 2,24H,52H,16H,14
        DEFB 2,25H,52H,1EH,14
        DEFB 2,26H,52H,26H,14
        DEFB 2,27H,52H,2EH,14
        DEFB 2,28H,52H,3EH,14
        DEFB 3,37H,6CH,52H,46H,15
        DEFB 3,37H,6DH,52H,4EH,15
        DEFB 3,37H,6EH,52H,56H,15
        DEFB 3,37H,6FH,52H,5EH,15
        DEFB 3,37H,70H,52H,66H,15
        DEFB 3,37H,71H,52H,6EH,15
        DEFB 3,37H,72H,52H,76H,15
        DEFB 3,37H,73H,52H,7EH,15
        DEFB 3,38H,6CH,52H,86H,15
        DEFB 3,38H,6DH,52H,8EH,15
        DEFB 3,38H,6EH,52H,96H,15
        DEFB 3,38H,6FH,52H,9EH,15
        DEFB 3,38H,70H,52H,0A6H,15
        DEFB 3,38H,71H,52H,0AEH,15
        DEFB 3,38H,72H,52H,0B6H,15
        DEFB 3,38H,73H,52H,0BEH,15
        DEFB 3,39H,6CH,52H,0C6H,15
        DEFB 3,39H,6DH,52H,0CEH,15
        DEFB 3,39H,6EH,52H,0D6H,15
        DEFB 3,39H,6FH,52H,0DEH,15
        DEFB 3,39H,70H,52H,0E6H,15
        DEFB 3,39H,71H,52H,0EEH,15
        DEFB 3,39H,72H,52H,0F6H,15
        DEFB 3,39H,73H,52H,0FEH,15
        DEFB 3,01H,4DH,60H,7CH,0
        DEFB 3,01H,4DH,62H,7DH,0
        DEFB 3,01H,46H,60H,44H,0
        DEFB 3,01H,46H,62H,45H,0
        DEFB 3,01H,47H,60H,4CH,0
        DEFB 3,01H,47H,62H,4DH,0
        DEFB 3,01H,48H,60H,54H,0
        DEFB 3,01H,48H,62H,55H,0
        DEFB 3,01H,49H,60H,5CH,0
        DEFB 3,01H,49H,62H,5DH,0
        DEFB 3,01H,60H,60H,64H,0
        DEFB 3,01H,60H,62H,65H,0
        DEFB 3,01H,62H,60H,6CH,0
        DEFB 3,01H,62H,62H,6DH,0
        DEFB 3,01H,60H,4DH,67H,0
        DEFB 3,01H,62H,4DH,6FH,0
        DEFB 3,01H,60H,46H,60H,0
        DEFB 3,01H,62H,46H,68H,0
        DEFB 3,01H,60H,47H,61H,0
        DEFB 3,01H,62H,47H,69H,0
        DEFB 3,01H,60H,48H,62H,0
        DEFB 3,01H,62H,48H,6AH,0
        DEFB 3,01H,60H,49H,63H,0
        DEFB 3,01H,62H,49H,6BH,0
        DEFB 3,01H,60H,7EH,26H,10
        DEFB 3,01H,62H,7EH,2EH,10
        DEFB 3,02H,4DH,60H,84H,0
        DEFB 3,02H,4DH,62H,85H,0
        DEFB 3,03H,4DH,60H,8CH,0
        DEFB 3,03H,4DH,62H,8DH,0
        DEFB 2,04H,60H,94H,0
        DEFB 2,04H,62H,95H,0
        DEFB 3,05H,4DH,60H,9CH,0
        DEFB 3,05H,4DH,62H,9DH,0
        DEFB 2,06H,60H,0A4H,0
        DEFB 2,06H,62H,0A5H,0
        DEFB 2,07H,60H,0ACH,0
        DEFB 2,07H,62H,0ADH,0
        DEFB 2,08H,60H,0B4H,0
        DEFB 2,08H,62H,0B5H,0
        DEFB 2,09H,60H,0BCH,0
        DEFB 2,09H,62H,0BDH,0
        DEFB 2,0AH,60H,24H,0
        DEFB 2,0AH,62H,2CH,0
        DEFB 2,0BH,60H,25H,0
        DEFB 2,0BH,62H,2DH,0
        
        DEFB 0

NST01:	DEFM '--------------$'
	DEFM '|            |$'
	DEFM '--------------$'
	DEFM '|     |      |$'
	DEFM '--------------$'
	DEFM '|            |$'
	DEFM '|            |$'
	DEFM '|            |$'
	DEFM '|            |$'
	DEFM '|            |$'
	DEFM '--------------$'
NST02:	DEFM '    MAIN SUB FDC RAM'
NST03:	DEFM '    BIOSWORKDATAPORTMATHKEY HOOK'
NST04:	DEFM '+--------------------------------------+'
	DEFM '          SUPER-X version 1.22          '
	DEFM ' Copyright(C) 1991-2011 Romi & NYYRIKKI '
	DEFM '+--------------------------------------+$'

HELPMS:
        DEFM '---------------- HELP ------------------'
        DEFM '| [D]-DUMP     BF=BAS-FIND  BL=BAS-LIST|'
        DEFM '| [A]-ASCII    BT=TRANSFER  CK=CHECK   |'
        DEFM '| [I]-DISASM   CL=CALCU     CM=COMPARE |'
        DEFM '| [M]-MULTI    CO=COLOR     CS=CHG-SUM |'
        DEFM '| [H]-CHARA    CU=CHG-CPU   FD=FIND    |'
        DEFM '| TP=TYPE      GO=GO        KR=K-READ  |'
        DEFM '| KT=K-TYPE    PP=MAPPER    FL=FILL    |'
        DEFM '| PO=PORT OUT  RG=REGISTER  RT=RELOCATE|'
        DEFM '| PI=PORT IN   SF=FUNCTION  TK=TENKEY  |'
        DEFM '| TR=TRACE     TS=TOTALSUM  OF=OFFSET  |'
        DEFM '| SD=SpDISASM  CD=CHDIR     CLS=CLS    |'
        DEFM '|                           QT=QUIT    |'
        DEFM '|--------------------------------------|'
        DEFM '|   INDEX    | [LD]-BLOAD  [SV]-BSAVE  |'
        DEFM '| [iM]-MAKE  | [L#]-SpLOAD [S#]-SpSAVE |'
        DEFM '| [iC]-CHECK | [L%]-ScLOAD [S%]-ScSAVE |'
        DEFM '| [iL]-LOAD  | [FS]-FILES  [KL]-KnjLOAD|'
        DEFM '| [iS]-SAVE  | [CI]-Ck.DSK             |'
        DEFM '----------------------------------------'
NST05:	DB 15
	DEFM '----------$'
	DB 10
	DEFM '-----|  DUMP  |-----$'
	DB 10
	DEFM '|                  |$'
	DB 10
	DEFM '| ASCII CHAR MULTI |$'
	DB 10
	DEFM '|                  |$'
	DB 10
	DEFM '-----| DISASM |-----$'
	DB 15
	DEFM '----------$'
NST06:	DEFM '----------------------------------------'
	DEFM '| U/D/L/R=Roll V=Rev O=On F=Off C=Clr  |'
	DEFM '----------------------------------------'

HNKNDT:
        DW 2120H,212AH,216DH,2174H,2170H
        DW 2173H,2175H,216CH,214AH,214BH
        DW 2176H,215CH,2124H,215DH,2125H,213FH
        DW 2330H,2331H,2332H,2333H,2334H,2335H,2336H,2337H,2338H,2339H
        DW 2127H,2128H,2163H,2161H,2164H,2129H,2177H
        DW 2341H,2342H,2343H,2344H,2345H,2346H,2347H,2348H,2349H,234AH,234BH,234CH,234DH,234EH,234FH
        DW 2350H,2351H,2352H,2353H,2354H,2355H,2356H,2357H,2358H,2359H,235AH
        DW 214EH,216FH,214FH,2130H,2132H,212EH
        DW 2361H,2362H,2363H,2364H,2365H,2366H,2367H,2368H,2369H,236AH,236BH,236CH,236DH,236EH,236FH
        DW 2370H,2371H,2372H,2373H,2374H,2375H,2376H,2377H,2378H,2379H,237AH
        DW 2150H,2143H,2151H,2141H,2120H
HNKDT1:
        DW 2120H,2123H,2156H,2157H,2122H,2126H,2572H,2521H,2523H,2525H,2527H,2529H,2563H,2565H,2567H,2543H,213CH
        DW 2522H,2524H,2526H,2528H,252AH
        DW 252BH,252DH,252FH,2531H,2533H
        DW 2535H,2537H,2539H,253BH,253DH
        DW 253FH,2541H,2544H,2546H,2548H
        DW 254AH,254BH,254CH,254DH,254EH
        DW 254FH,2552H,2555H,2558H,255BH
        DW 255EH,255FH,2560H,2561H,2562H
        DW 2564H,2566H,2568H
        DW 2569H,256AH,256BH,256CH,256DH
        DW 256FH,2573H,212BH,212CH
          
        DEFM "It's all too much!"

	DEPHASE

	END
                                                