
; Z80/R800 emulator for Z80/R800 Made By: NYYRIKKI (2003)
;--------------------------------------------------------
;
; Known "features" :
;
;
; - RETN & RETI acts as RET
;	This does not have effect on MSX computers.
;
; - START routine can not detect current interrupt (IM) mode used.
;	Normally 1 on MSX
;
; - You have to manually set databus value for IM mode 0 and 2
;	Databus should allways have value #FF on MSX computers. You can check
;	your databus value by compiling databus.asm source.
;
; - R-register incrementation is not emulated. LD A,R will return real value.
;	Should not generate a problem as this register is normally not used.
;	Sometimes this register is used to generate seed for random routine,
;	but in that case this implementation works well enough.
;
; - I/O Block functions do not set CF,HF,NF and PF flags correctly (OTI,OTIR,INI,INIR)
;
;REGISTRY LAYOUT & OTHER Z80 INTERNAL INFO

	;REAL	EMULATOR
	;AF	= NOT USED
	;DE 	= NOT USED
	;BC 	= NOT USED
	;HL 	= PC
	;SP 	= NOT USED
	;IX 	= IX
	;IY 	= IY

	;AF' 	= AF
	;HL' 	= HL
	;DE' 	= DE
	;BC' 	= BC

	;R 	= R
	;I	= NOT USED
	;PC	= NOT USED

	;PILKSP	= SP 
	;PILKI	= I
	;PILKAF	= AF'
	;PILKHL	= HL'
	;PILKDE	= DE'
	;PILKBC	= BC'
	;IMODE	= IM mode
	;INTENAB= DI/EI		;0=EI 1=DI


; JUMP TABLE INFO:

	;LO PRIMARY JP TABLE (#x000-#x0FF)
	;HI PRIMARY JP TABLE (#x100-#x1FF)
	;LO #DD JP TABLE (#x200-#x2FF)
	;HI #DD JP TABLE (#x300-#x3FF)
	;LO #ED JP TABLE (#x400-#x4FF)
	;HI #ED JP TABLE (#x500-#x5FF)
	;LO #FD JP TABLE (#x600-#x6FF)
	;HI #FD JP TABLE (#x700-#x7FF)

;---------------------------
;       Confiquration:

DEFIM:	 EQU 1	; This will set default IM mode for first time use
		; Next start will expect, that mode has not been changed.

DATABUS: EQU #FF; This is the databus value on interrupt. 
		; You can check your computers databus value by executing program
		; generated from DATABUS.ASM (Unmodifyed MSX should have allways value #FF)

INTNUM:	 EQU 30	; This value defines, how often interrupt should be emulated
		; (1/x times of real interrupt)

; NOTE: R800 Emulation selection is later on this source.
;---------------------------
;	Header for MSX-BASIC BLOAD file (Remove if used on other platforms)

	DEFB #FE
	DEFW BEGIN
	DEFW END
	DEFW START

;---------------------------

;	Load address (Lo byte needs to be 0)
	ORG #9800
BEGIN:

;---------------------------
;	Tables:

tabz80:	include z80tbl.inc
tabdd:	include z80ddtbl.inc
tabed:	include z80edtbl.inc
tabfd:	include z80fdtbl.inc

START:
	JP INIT			; INIT ROUTINE BEGIN + #800
	DEFB #FD,#FD,#C9	; EXIT ROUTINE BEGIN + #803

;---------------------------
;	Variables & temp storage

IMODE:	DEFB DEFIM
ICOUNT:	DEFB 0
INTENAB:DEFB 0
IENAB:	DEFB 0
PILKAF:	DEFW 0
PILKHL:	DEFW 0
PILKDE:	DEFW 0
PILKBC:	DEFW 0
PILKSP:	DEFW 0
PILKI:	DEFB 0

	DEFW 0 ; THIS IS BECAUSE OF BUG IN MY COMPILER!!! (Can be removed)

;---------------------------
;	Initialization routine

INIT:		; Does not have effect to registers

	EXX
	EX AF,AF'
	PUSH HL
	PUSH AF
	POP HL
	LD (PILKAF),HL
	POP HL
	LD (PILKHL),HL
	LD (PILKDE),DE
	LD (PILKBC),BC

	LD A,I
	LD (PILKI),A
	LD A,0
	JP PE,ININTEI
	INC A
ININTEI:
	LD (INTENAB),A

	; Interrupt emulation installation routine

	LD A,END / 256 +1; We don't know, 101% sure what is on data bus, so we have to make 
	LD H,A		 ; 257 bytes long address table after program end.
	LD L,0
	LD D,A
	LD E,1
	LD BC,#101
	INC A
	LD (HL),A
	LDIR		
			

	LD L,A		; Now we have to make jump to real interrupt handler.
	LD H,A
	LD (HL),#C3	; JP
	INC HL
	LD DE,NEWINT
	LD (HL),E
	INC HL
	LD (HL),D

	DEC A
	LD I,A		; Now we enable NEWINT routine
	IM 2

	POP HL	; = RET = START RUNNING EMULATION
	LD (PILKSP),SP
	LD SP,BEGIN
	EI

	JP NEXTOP

;---------------------------
;	EXIT routine

EXIT:				;FD FD Used as break code
	DI
	LD (EXITJ),HL
	LD A,(PILKI)
	LD I,A
	LD A,(IMODE)
	AND A
	JR NZ,EXNOIM0
	IM 0
	JR EXIMOK
EXNOIM0:
	DEC A
	JR NZ,EXNOIM1
	IM 1
	JR EXIMOK
EXNOIM1:
	IM 2
EXIMOK:
	LD A,(INTENAB)
	AND A
	JR NZ,EXINTDI
	EI
	NOP
	HALT		; Let's wait one real interrupt to avoid it coming when SP is at wrong place.
EXINTDI:
	LD HL,(PILKAF)
	PUSH HL
	LD DE,(PILKDE)
	LD BC,(PILKBC)
	LD HL,(PILKHL)
	POP AF
	EXX
	EX AF,AF'
	LD SP,(PILKSP)
	JP 0
EXITJ:	EQU $-2

;--------------------------
; Real interrupt handler

NEWINT:
	PUSH AF
	LD A,(INTENAB)
	AND A
	JR NZ,INTNOEXEC
	LD A,(ICOUNT)
	AND A
	JR Z,INTNOEXEC
	INC A
	CP INTNUM
	JR NZ,INTNORES
	XOR A
INTNORES:
	LD (ICOUNT),A
INTNOEXEC:
	POP AF
	RET


;---------------------------
; Emulated interrupt handler

IHANDLE:
	INC A
	LD (ICOUNT),A
	LD A,(IMODE)
	DEC A
	JP Z,ZZFF	; IM 1
	INC A
	JR Z,IMIM0	; IM 0
			; IM 2
	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD A,E
	CALL PUTA
	LD (PILKSP),HL

	LD A,(PILKI)
	LD H,A
	LD L,DATABUS
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	EX DE,HL
	JP NEXTOP
IMIM0:
	DEC HL
	LD E,DATABUS
	JP IMIM0J

;------------------------------------------------------------
;	Main loop of emulation code

NEXTOP:
	LD D,tabz80 / 256

	LD A,(ICOUNT)
	AND A
	JR Z,IHANDLE

NEXTSUB:
	CALL GETA
	LD E,A
IMIM0J:	LD A,(DE)
	LD C,A
	INC D
	LD A,(DE)
	LD B,A
	INC HL ;MI
	PUSH BC
	RET


;------------------------------------------------------------
; IO.inc includes I/O routines used by all emulated I/O commands.

	include IO.INC

;------------------------------------------------------------
; MEM.INC includes memory routines used by all emulated memory commands.

	include MEM.INC

;-------------------- R800 OPCODES --------------------------

	; Select here, how to emulate R800 commands:

	; noR800.inc 		do not emulate R800
	; RealR800.inc		Emulate R800 on R800
	; EmuR800.inc		Emulate R800 on Z80

	include EmuR800.inc

;-------------------- Z80 OPCODES --------------------------
;	Unemulated commands:

	include zddund.inc
	include zedund.inc
	include zfdund.inc

;	Acts as NOP (zz00)

zz00:			;00           NOP
	JP NEXTOP
zz01:			;01 nn nn     LD BC,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	PUSH DE
	EXX
	POP BC
	EXX
	JP NEXTOP

zz02:			;02           LD (BC),A

	EXX
	PUSH BC
	EXX
	EX (SP),HL
	EX AF,AF'
	CALL PUTA
	EX AF,AF'
	POP HL
	JP NEXTOP
zz03:			;03           INC BC

	EX AF,AF'
	EXX
	INC BC
	EXX
	EX AF,AF'
	JP NEXTOP
zz04:			;04           INC B

	EX AF,AF'
	EXX
	INC B
	EXX
	EX AF,AF'
	JP NEXTOP
zz05:			;05           DEC B

	EX AF,AF'
	EXX
	DEC B
	EXX
	EX AF,AF'
	JP NEXTOP
zz06:			;06 nn        LD B,n

	CALL GETA
	INC HL ;MI
	EXX
	LD B,A
	EXX

	JP NEXTOP
zz07:			;07           RLCA

	EX AF,AF'
	RLCA
	EX AF,AF'
	JP NEXTOP
zz08:			;08           EX AF,AF'
	LD DE,(PILKAF)
	PUSH DE
	POP AF
	EX AF,AF'
	PUSH AF
	POP DE
	LD (PILKAF),DE
	JP NEXTOP

zz09:			;09           ADD HL,BC

	EX AF,AF'
	EXX
	ADD HL,BC
	EXX
	EX AF,AF'
	JP NEXTOP
zz0A:			;0A           LD A,(BC)

	EXX
	PUSH BC
	EXX
	EX (SP),HL
	CALL GETA
	LD B,A
	EX AF,AF'
	LD A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
zz0B:			;0B           DEC BC

	EX AF,AF'
	EXX
	DEC BC
	EXX
	EX AF,AF'
	JP NEXTOP
zz0C:			;0C           INC C

	EX AF,AF'
	EXX
	INC C
	EXX
	EX AF,AF'
	JP NEXTOP
zz0D:			;0D           DEC C

	EX AF,AF'
	EXX
	DEC C
	EXX
	EX AF,AF'
	JP NEXTOP


zz0E:			;0E nn        LD C,n
	CALL GETA
	INC HL ;MI
	EXX
	LD C,A
	EXX
	JP NEXTOP
zz0F:			;0F           RRCA

	EX AF,AF'
	RRCA
	EX AF,AF'
	JP NEXTOP


zz10:			;10 nn        DJNZ n
	CALL GETA
	INC HL ;MI
	EX AF,AF'
	EXX
	DEC B
	JR Z,ZZ10J1
	EXX
	EX AF,AF'

	LD E,A
	LD D,0
	AND #80
	JR Z,ZZ10J2
	DEC D
ZZ10J2:	ADD HL,DE
	JP NEXTOP

ZZ10J1:	EXX
	EX AF,AF'
	JP NEXTOP

zz11:			;11 nn nn     LD DE,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	PUSH DE
	EXX
	POP DE
	EXX
	JP NEXTOP
zz12:			;12           LD (DE),A

	EXX
	EX DE,HL
	EX AF,AF'
	CALL PUTA
	EX AF,AF'
	EX DE,HL
	EXX
	JP NEXTOP
zz13:			;13           INC DE

	EX AF,AF'
	EXX
	INC DE
	EXX
	EX AF,AF'
	JP NEXTOP
zz14:			;14           INC D

	EX AF,AF'
	EXX
	INC D
	EXX
	EX AF,AF'
	JP NEXTOP
zz15:			;15           DEC D

	EX AF,AF'
	EXX
	DEC D
	EXX
	EX AF,AF'
	JP NEXTOP
zz16:			;16           LD D,n

	CALL GETA
	INC HL ;MI
	EXX
	LD D,A
	EXX
	JP NEXTOP
zz17:			;17           RLA

	EX AF,AF'
	RLA
	EX AF,AF'
	JP NEXTOP


zz18:			;18           JR n
	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	AND #80
	JR Z,ZZ18J
	DEC D
ZZ18J:	ADD HL,DE
	JP NEXTOP

zz19:			;19           ADD HL,DE

	EX AF,AF'
	EXX
	ADD HL,DE
	EXX
	EX AF,AF'
	JP NEXTOP
zz1A:			;1A           LD A,(DE)

	EXX
	EX DE,HL
	CALL GETA
	EX DE,HL
	EXX
	LD B,A
	EX AF,AF'
	LD A,B
	EX AF,AF'
	JP NEXTOP
zz1B:			;1B           DEC DE

	EX AF,AF'
	EXX
	DEC DE
	EXX
	EX AF,AF'
	JP NEXTOP
zz1C:			;1C           INC E

	EX AF,AF'
	EXX
	INC E
	EXX
	EX AF,AF'
	JP NEXTOP
zz1D:			;1D           DEC E

	EX AF,AF'
	EXX
	DEC E
	EXX
	EX AF,AF'
	JP NEXTOP
zz1E:			;1E nn        LD E,n

	CALL GETA
	INC HL ;MI
	EXX
	LD E,A
	EXX
	JP NEXTOP
zz1F:			;1F           RRA

	EX AF,AF'
	RRA
	EX AF,AF'
	JP NEXTOP
zz20:			;20 nn        JR NZ,n

	CALL GETA
	INC HL ;MI
	EX AF,AF'
	JR Z,ZZ20J2
	EX AF,AF'
	LD E,A
	LD D,0
	AND #80
	JR Z,ZZ20J1
	DEC D
ZZ20J1:	ADD HL,DE
	JP NEXTOP
ZZ20J2: EX AF,AF'
	JP NEXTOP

zz21:			;21 nn nn     LD HL,nn
	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	PUSH DE
	EXX
	POP HL
	EXX
	JP NEXTOP
zz22:			;22 nn nn     LD (nn),HL

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	EXX
	LD A,L
	EXX
	CALL PUTA
	INC HL
	EXX
	LD A,H
	EXX
	CALL PUTA
	EX DE,HL
	JP NEXTOP
zz23:			;23           INC HL

	EX AF,AF'
	EXX
	INC HL
	EXX
	EX AF,AF'
	JP NEXTOP
zz24:			;24           INC H

	EX AF,AF'
	EXX
	INC H
	EXX
	EX AF,AF'
	JP NEXTOP
zz25:			;25           DEC H

	EX AF,AF'
	EXX
	DEC H
	EXX
	EX AF,AF'
	JP NEXTOP
zz26:			;26 nn        LD H,n

	CALL GETA
	INC HL ;MI
	EXX
	LD H,A
	EXX
	JP NEXTOP
zz27:			;27           DAA

	EX AF,AF'
	DAA
	EX AF,AF'
	JP NEXTOP
zz28:			;28 nn        JR Z,n

	CALL GETA
	INC HL ;MI
	EX AF,AF'
	JR NZ,ZZ28J2
	EX AF,AF'
	LD E,A
	LD D,0
	AND #80
	JR Z,ZZ28J1
	DEC D
ZZ28J1:	ADD HL,DE
	JP NEXTOP
ZZ28J2: EX AF,AF'
	JP NEXTOP

zz29:			;29           ADD HL,HL

	EX AF,AF'
	EXX
	ADD HL,HL
	EXX
	EX AF,AF'
	JP NEXTOP
zz2A:			;2A nn nn     LD HL,(nn)
	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	CALL GETA
	EXX
	LD L,A
	EXX
	INC HL
	CALL GETA
	EXX
	LD H,A
	EXX
	EX DE,HL
	JP NEXTOP
zz2B:			;2B           DEC HL

	EX AF,AF'
	EXX
	DEC HL
	EXX
	EX AF,AF'
	JP NEXTOP
zz2C:			;2C           INC L

	EX AF,AF'
	EXX
	INC L
	EXX
	EX AF,AF'
	JP NEXTOP
zz2D:			;2D           DEC L

	EX AF,AF'
	EXX
	DEC L
	EXX
	EX AF,AF'
	JP NEXTOP
zz2E:			;2E nn        LD L,n

	CALL GETA
	INC HL ;MI
	EXX
	LD L,A
	EXX
	JP NEXTOP
zz2F:			;2F           CPL

	EX AF,AF'
	CPL
	EX AF,AF'
	JP NEXTOP
zz30:			;30 nn        JR NC,n

	CALL GETA
	INC HL ;MI
	EX AF,AF'
	JR C,ZZ30J2
	EX AF,AF'
	LD E,A
	LD D,0
	AND #80
	JR Z,ZZ30J
	DEC D
ZZ30J:	ADD HL,DE
	JP NEXTOP
ZZ30J2: EX AF,AF'
	JP NEXTOP

zz31:			;31 nn nn     LD SP,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	LD (PILKSP),DE
	JP NEXTOP
zz32:			;32 nn nn     LD (nn),A
	EX AF,AF'
	LD B,A
	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	LD A,B
	CALL PUTA
	EX DE,HL
	JP NEXTOP
zz33:			;33           INC SP

	LD DE,(PILKSP)
	EX AF,AF'
	INC DE
	EX AF,AF'
	LD (PILKSP),DE
	JP NEXTOP
zz34:			;34           INC (HL)
	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	INC B
	EX AF,AF'
	LD A,B
	EXX
	CALL PUTA
	EXX
	JP NEXTOP
zz35:			;35           DEC (HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	DEC B
	EX AF,AF'
	LD A,B
	EXX
	CALL PUTA
	EXX
	JP NEXTOP
zz36:			;36 nn        LD (HL),n

	CALL GETA
	INC HL ;MI
	EXX
	CALL PUTA
	EXX
	JP NEXTOP
zz37:			;37           SCF

	EX AF,AF'
	SCF
	EX AF,AF'
	JP NEXTOP
zz38:			;38 nn        JR C,n

	CALL GETA
	INC HL ;MI
	EX AF,AF'
	JR NC,ZZ38J2
	EX AF,AF'
	LD E,A
	LD D,0
	AND #80
	JR Z,ZZ38J
	DEC D
ZZ38J:	ADD HL,DE
	JP NEXTOP
ZZ38J2:
	EX AF,AF'
	JP NEXTOP
zz39:			;39           ADD HL,SP

	EXX
	PUSH DE
	LD DE,(PILKSP)
	EX AF,AF'
	ADD HL,DE
	EX AF,AF'
	POP DE
	EXX
	JP NEXTOP

zz3A:			;3A nn nn     LD A,(nn)

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	CALL GETA
	EX DE,HL
	LD B,A
	EX AF,AF'
	LD A,B
	EX AF,AF'
	JP NEXTOP
zz3B:			;3B           DEC SP

	LD DE,(PILKSP)
	EX AF,AF'
	DEC DE
	EX AF,AF'
	LD (PILKSP),DE
	JP NEXTOP
zz3C:			;3C           INC A

	EX AF,AF'
	INC A
	EX AF,AF'
	JP NEXTOP
zz3D:			;3D           DEC A

	EX AF,AF'
	DEC A
	EX AF,AF'
	JP NEXTOP
zz3E:			;3E nn        LD A,n
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	LD A,D
	EX AF,AF'
	JP NEXTOP
zz3F:			;3F           CCF

	EX AF,AF'
	CCF
	EX AF,AF'
	JP NEXTOP
zz40:			;40           LD B,B

	JP NEXTOP
zz41:			;41           LD B,C

	EXX
	LD B,C
	EXX
	JP NEXTOP
zz42:			;42           LD B,D

	EXX
	LD B,D
	EXX
	JP NEXTOP
zz43:			;43           LD B,E

	EXX
	LD B,E
	EXX
	JP NEXTOP
zz44:			;44           LD B,H

	EXX
	LD B,H
	EXX
	JP NEXTOP
zz45:			;45           LD B,L

	EXX
	LD B,L
	EXX
	JP NEXTOP
zz46:			;46           LD B,(HL)

	EXX
	CALL GETA
	LD B,A
	EXX
	JP NEXTOP
zz47:			;47           LD B,A

	EX AF,AF'
	EXX
	LD B,A
	EXX
	EX AF,AF'
	JP NEXTOP
zz48:			;48           LD C,B

	EXX
	LD C,B
	EXX
	JP NEXTOP
zz49:			;49           LD C,C

	JP NEXTOP
zz4A:			;4A           LD C,D

	EXX
	LD C,D
	EXX
	JP NEXTOP
zz4B:			;4B           LD C,E

	EXX
	LD C,E
	EXX
	JP NEXTOP
zz4C:			;4C           LD C,H

	EXX
	LD C,H
	EXX
	JP NEXTOP
zz4D:			;4D           LD C,L

	EXX
	LD C,L
	EXX
	JP NEXTOP
zz4E:			;4E           LD C,(HL)

	EXX
	CALL GETA
	LD C,A
	EXX
	JP NEXTOP
zz4F:			;4F           LD C,A

	EX AF,AF'
	EXX
	LD C,A
	EXX
	EX AF,AF'
	JP NEXTOP
zz50:			;50           LD D,B

	EXX
	LD D,B
	EXX
	JP NEXTOP
zz51:			;51           LD D,C

	EXX
	LD D,C
	EXX
	JP NEXTOP
zz52:			;52           LD D,D

	JP NEXTOP
zz53:			;53           LD D,E

	EXX
	LD D,E
	EXX
	JP NEXTOP
zz54:			;54           LD D,H

	EXX
	LD D,H
	EXX
	JP NEXTOP
zz55:			;55           LD D,L

	EXX
	LD D,L
	EXX
	JP NEXTOP
zz56:			;56           LD D,(HL)

	EXX
	CALL GETA
	LD D,A
	EXX
	JP NEXTOP
zz57:			;57           LD D,A

	EX AF,AF'
	EXX
	LD D,A
	EXX
	EX AF,AF'
	JP NEXTOP
zz58:			;58           LD E,B

	EXX
	LD E,B
	EXX
	JP NEXTOP
zz59:			;59           LD E,C

	EXX
	LD E,C
	EXX
	JP NEXTOP
zz5A:			;5A           LD E,D

	EXX
	LD E,D
	EXX
	JP NEXTOP
zz5B:			;5B           LD E,E

	JP NEXTOP
zz5C:			;5C           LD E,H

	EXX
	LD E,H
	EXX
	JP NEXTOP
zz5D:			;5D           LD E,L

	EXX
	LD E,L
	EXX
	JP NEXTOP
zz5E:			;5E           LD E,(HL)

	EXX
	CALL GETA
	LD E,A
	EXX
	JP NEXTOP
zz5F:			;5F           LD E,A

	EX AF,AF'
	EXX
	LD E,A
	EXX
	EX AF,AF'
	JP NEXTOP
zz60:			;60           LD H,B

	EXX
	LD H,B
	EXX
	JP NEXTOP
zz61:			;61           LD H,C

	EXX
	LD H,C
	EXX
	JP NEXTOP
zz62:			;62           LD H,D

	EXX
	LD H,D
	EXX
	JP NEXTOP
zz63:			;63           LD H,E

	EXX
	LD H,E
	EXX
	JP NEXTOP
zz64:			;64           LD H,H

	JP NEXTOP
zz65:			;65           LD H,L

	EXX
	LD H,L
	EXX
	JP NEXTOP
zz66:			;66           LD H,(HL)

	EXX
	CALL GETA
	LD H,A
	EXX
	JP NEXTOP
zz67:			;67           LD H,A

	EX AF,AF'
	EXX
	LD H,A
	EXX
	EX AF,AF'
	JP NEXTOP
zz68:			;68           LD L,B

	EXX
	LD L,B
	EXX
	JP NEXTOP
zz69:			;69           LD L,C

	EXX
	LD L,C
	EXX
	JP NEXTOP
zz6A:			;6A           LD L,D

	EXX
	LD L,D
	EXX
	JP NEXTOP
zz6B:			;6B           LD L,E

	EXX
	LD L,E
	EXX
	JP NEXTOP
zz6C:			;6C           LD L,H

	EXX
	LD L,H
	EXX
	JP NEXTOP
zz6D:			;6D           LD L,L

	JP NEXTOP
zz6E:			;6E           LD L,(HL)

	EXX
	CALL GETA
	LD L,A
	EXX
	JP NEXTOP
zz6F:			;6F           LD L,A

	EX AF,AF'
	EXX
	LD L,A
	EXX
	EX AF,AF'
	JP NEXTOP
zz70:			;70           LD (HL),B

	EXX
	LD A,B
	CALL PUTA
	EXX
	JP NEXTOP
zz71:			;71           LD (HL),C

	EXX
	LD A,C
	CALL PUTA
	EXX
	JP NEXTOP
zz72:			;72           LD (HL),D

	EXX
	LD A,D
	CALL PUTA
	EXX
	JP NEXTOP
zz73:			;73           LD (HL),E

	EXX
	LD A,E
	CALL PUTA
	EXX
	JP NEXTOP
zz74:			;74           LD (HL),H

	EXX
	LD A,H
	CALL PUTA
	EXX
	JP NEXTOP
zz75:			;75           LD (HL),L

	EXX
	LD A,L
	CALL PUTA
	EXX
	JP NEXTOP
zz76:			;76           HALT

	LD A,(ICOUNT)
	AND A
	JR NZ,ZZ76
	JP NEXTOP
zz77:			;77           LD (HL),A

	EX AF,AF'
	LD B,A
	EX AF,AF'
	LD A,B
	EXX
	CALL PUTA
	EXX
	JP NEXTOP
zz78:			;78           LD A,B

	EX AF,AF'
	EXX
	LD A,B
	EXX
	EX AF,AF'
	JP NEXTOP
zz79:			;79           LD A,C

	EX AF,AF'
	EXX
	LD A,C
	EXX
	EX AF,AF'
	JP NEXTOP
zz7A:			;7A           LD A,D

	EX AF,AF'
	EXX
	LD A,D
	EXX
	EX AF,AF'
	JP NEXTOP
zz7B:			;7B           LD A,E

	EX AF,AF'
	EXX
	LD A,E
	EXX
	EX AF,AF'
	JP NEXTOP
zz7C:			;7C           LD A,H

	EX AF,AF'
	EXX
	LD A,H
	EXX
	EX AF,AF'
	JP NEXTOP
zz7D:			;7D           LD A,L

	EX AF,AF'
	EXX
	LD A,L
	EXX
	EX AF,AF'
	JP NEXTOP
zz7E:			;7E           LD A,(HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	LD A,B
	EX AF,AF'
	JP NEXTOP
zz7F:			;7F           LD A,A

	JP NEXTOP
zz80:			;80           ADD A,B

	EX AF,AF'
	EXX
	ADD A,B
	EXX
	EX AF,AF'
	JP NEXTOP
zz81:			;81           ADD A,C

	EX AF,AF'
	EXX
	ADD A,C
	EXX
	EX AF,AF'
	JP NEXTOP
zz82:			;82           ADD A,D

	EX AF,AF'
	EXX
	ADD A,D
	EXX
	EX AF,AF'
	JP NEXTOP
zz83:			;83           ADD A,E

	EX AF,AF'
	EXX
	ADD A,E
	EXX
	EX AF,AF'
	JP NEXTOP
zz84:			;84           ADD A,H

	EX AF,AF'
	EXX
	ADD A,H
	EXX
	EX AF,AF'
	JP NEXTOP
zz85:			;85           ADD A,L

	EX AF,AF'
	EXX
	ADD A,L
	EXX
	EX AF,AF'
	JP NEXTOP
zz86:			;86           ADD A,(HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	ADD A,B
	EX AF,AF'
	JP NEXTOP
zz87:			;87           ADD A,A

	EX AF,AF'
	ADD A,A
	EX AF,AF'
	JP NEXTOP
zz88:			;88           ADC A,B

	EX AF,AF'
	EXX
	ADC A,B
	EXX
	EX AF,AF'
	JP NEXTOP
zz89:			;89           ADC A,C

	EX AF,AF'
	EXX
	ADC A,C
	EXX
	EX AF,AF'
	JP NEXTOP
zz8A:			;8A           ADC A,D

	EX AF,AF'
	EXX
	ADC A,D
	EXX
	EX AF,AF'
	JP NEXTOP
zz8B:			;8B           ADC A,E

	EX AF,AF'
	EXX
	ADC A,E
	EXX
	EX AF,AF'
	JP NEXTOP
zz8C:			;8C           ADC A,H

	EX AF,AF'
	EXX
	ADC A,H
	EXX
	EX AF,AF'
	JP NEXTOP
zz8D:			;8D           ADC A,L

	EX AF,AF'
	EXX
	ADC A,L
	EXX
	EX AF,AF'
	JP NEXTOP
zz8E:			;8E           ADC A,(HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	ADC A,B
	EX AF,AF'
	JP NEXTOP
zz8F:			;8F           ADC A,A

	EX AF,AF'
	ADC A,A
	EX AF,AF'
	JP NEXTOP
zz90:			;90           SUB B

	EX AF,AF'
	EXX
	SUB B
	EXX
	EX AF,AF'
	JP NEXTOP
zz91:			;91           SUB C

	EX AF,AF'
	EXX
	SUB C
	EXX
	EX AF,AF'
	JP NEXTOP
zz92:			;92           SUB D

	EX AF,AF'
	EXX
	SUB D
	EXX
	EX AF,AF'
	JP NEXTOP
zz93:			;93           SUB E

	EX AF,AF'
	EXX
	SUB E
	EXX
	EX AF,AF'
	JP NEXTOP
zz94:			;94           SUB H

	EX AF,AF'
	EXX
	SUB H
	EXX
	EX AF,AF'
	JP NEXTOP
zz95:			;95           SUB L

	EX AF,AF'
	EXX
	SUB L
	EXX
	EX AF,AF'
	JP NEXTOP
zz96:			;96           SUB (HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	SUB B
	EX AF,AF'
	JP NEXTOP
zz97:			;97           SUB A

	EX AF,AF'
	SUB A
	EX AF,AF'
	JP NEXTOP
zz98:			;98           SBC A,B

	EX AF,AF'
	EXX
	SBC A,B
	EXX
	EX AF,AF'
	JP NEXTOP
zz99:			;99           SBC A,C

	EX AF,AF'
	EXX
	SBC A,C
	EXX
	EX AF,AF'
	JP NEXTOP
zz9A:			;9A           SBC A,D

	EX AF,AF'
	EXX
	SBC A,D
	EXX
	EX AF,AF'
	JP NEXTOP
zz9B:			;9B           SBC A,E

	EX AF,AF'
	EXX
	SBC A,E
	EXX
	EX AF,AF'
	JP NEXTOP
zz9C:			;9C           SBC A,H

	EX AF,AF'
	EXX
	SBC A,H
	EXX
	EX AF,AF'
	JP NEXTOP
zz9D:			;9D           SBC A,L

	EX AF,AF'
	EXX
	SBC A,L
	EXX
	EX AF,AF'
	JP NEXTOP
zz9E:			;9E           SBC A,(HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	SBC A,B
	EX AF,AF'
	JP NEXTOP
zz9F:			;9F           SBC A,A

	EX AF,AF'
	SBC A,A
	EX AF,AF'
	JP NEXTOP
zzA0:			;A0           AND B

	EX AF,AF'
	EXX
	AND B
	EXX
	EX AF,AF'
	JP NEXTOP
zzA1:			;A1           AND C

	EX AF,AF'
	EXX
	AND C
	EXX
	EX AF,AF'
	JP NEXTOP
zzA2:			;A2           AND D

	EX AF,AF'
	EXX
	AND D
	EXX
	EX AF,AF'
	JP NEXTOP
zzA3:			;A3           AND E

	EX AF,AF'
	EXX
	AND E
	EXX
	EX AF,AF'
	JP NEXTOP
zzA4:			;A4           AND H

	EX AF,AF'
	EXX
	AND H
	EXX
	EX AF,AF'
	JP NEXTOP
zzA5:			;A5           AND L

	EX AF,AF'
	EXX
	AND L
	EXX
	EX AF,AF'
	JP NEXTOP
zzA6:			;A6           AND (HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	AND B
	EX AF,AF'
	JP NEXTOP
zzA7:			;A7           AND A

	EX AF,AF'
	AND A
	EX AF,AF'
	JP NEXTOP
zzA8:			;A8           XOR B

	EX AF,AF'
	EXX
	XOR B
	EXX
	EX AF,AF'
	JP NEXTOP
zzA9:			;A9           XOR C

	EX AF,AF'
	EXX
	XOR C
	EXX
	EX AF,AF'
	JP NEXTOP
zzAA:			;AA           XOR D

	EX AF,AF'
	EXX
	XOR D
	EXX
	EX AF,AF'
	JP NEXTOP
zzAB:			;AB           XOR E

	EX AF,AF'
	EXX
	XOR E
	EXX
	EX AF,AF'
	JP NEXTOP
zzAC:			;AC           XOR H

	EX AF,AF'
	EXX
	XOR H
	EXX
	EX AF,AF'
	JP NEXTOP
zzAD:			;AD           XOR L

	EX AF,AF'
	EXX
	XOR L
	EXX
	EX AF,AF'
	JP NEXTOP
zzAE:			;AE           XOR (HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	XOR B
	EX AF,AF'
	JP NEXTOP
zzAF:			;AF           XOR A

	EX AF,AF'
	XOR A
	EX AF,AF'
	JP NEXTOP
zzB0:			;B0           OR B

	EX AF,AF'
	EXX
	OR B
	EXX
	EX AF,AF'
	JP NEXTOP
zzB1:			;B1           OR C

	EX AF,AF'
	EXX
	OR C
	EXX
	EX AF,AF'
	JP NEXTOP
zzB2:			;B2           OR D

	EX AF,AF'
	EXX
	OR D
	EXX
	EX AF,AF'
	JP NEXTOP
zzB3:			;B3           OR E

	EX AF,AF'
	EXX
	OR E
	EXX
	EX AF,AF'
	JP NEXTOP
zzB4:			;B4           OR H

	EX AF,AF'
	EXX
	OR H
	EXX
	EX AF,AF'
	JP NEXTOP
zzB5:			;B5           OR L

	EX AF,AF'
	EXX
	OR L
	EXX
	EX AF,AF'
	JP NEXTOP
zzB6:			;B6           OR (HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	OR B
	EX AF,AF'
	JP NEXTOP
zzB7:			;B7           OR A

	EX AF,AF'
	OR A
	EX AF,AF'
	JP NEXTOP
zzB8:			;B8           CP B

	EX AF,AF'
	EXX
	CP B
	EXX
	EX AF,AF'
	JP NEXTOP
zzB9:			;B9           CP C

	EX AF,AF'
	EXX
	CP C
	EXX
	EX AF,AF'
	JP NEXTOP
zzBA:			;BA           CP D

	EX AF,AF'
	EXX
	CP D
	EXX
	EX AF,AF'
	JP NEXTOP
zzBB:			;BB           CP E

	EX AF,AF'
	EXX
	CP E
	EXX
	EX AF,AF'
	JP NEXTOP
zzBC:			;BC           CP H

	EX AF,AF'
	EXX
	CP H
	EXX
	EX AF,AF'
	JP NEXTOP
zzBD:			;BD           CP L

	EX AF,AF'
	EXX
	CP L
	EXX
	EX AF,AF'
	JP NEXTOP
zzBE:			;BE           CP (HL)

	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	CP B
	EX AF,AF'
	JP NEXTOP
zzBF:			;BF           CP A

	EX AF,AF'
	CP A
	EX AF,AF'
	JP NEXTOP

zzC0:			;C0           RET NZ
	EX AF,AF'
	JR Z,ZZC0J
	EX AF,AF'

	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP

ZZC0J:	EX AF,AF'
	JP NEXTOP
zzC1:			;C1           POP BC

	EXX
	PUSH HL
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD C,A
	CALL GETA
	INC HL
	LD B,A
	LD (PILKSP),HL
	POP HL
	EXX
	JP NEXTOP
zzC2:			;C2 nn nn     JP NZ,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JR Z,ZZC2J
	EX DE,HL
ZZC2J:	EX AF,AF'
	JP NEXTOP

zzC3:			;C3 nn nn     JP nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
;	INC HL ;MI
	EX DE,HL
	JP NEXTOP

zzC4:			;C4 nn nn     CALL NZ,nn
	EX AF,AF'
	JR Z,ZZC4J
	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP

ZZC4J:	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP
zzC5:			;C5           PUSH BC

	EXX
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,B
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,C
	CALL PUTA
	POP HL
	EXX
	JP NEXTOP
zzC6:			;C6 nn        ADD A,n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	ADD A,B
	EX AF,AF'
	JP NEXTOP
zzC7:			;C7           RST #00

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#00
	JP NEXTOP
zzC8:			;C8           RET Z

	EX AF,AF'
	JR NZ,ZZC8J
	EX AF,AF'
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
ZZC8J:	EX AF,AF'
	JP NEXTOP

zzC9:			;C9           RET

	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
zzCA:			;CA nn nn     JP Z,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JR NZ,ZZCAJ
	EX DE,HL
ZZCAJ:	EX AF,AF'
	JP NEXTOP

;------------------------------------------------------------

; BIT operations

zzCB:			;CB XX        BIT HANDLING ROUTINES...

	CALL GETA
	INC HL ;MI
	LD B,A
	AND 7
	CP 6
	LD A,B
	JR Z,ZZCBJ
	LD (ZZCBP),A
	EX AF,AF'
	EXX
	DEFB #CB
ZZCBP:	DEFB 0
	EXX
	EX AF,AF'
	JP NEXTOP

ZZCBJ:
	AND %11111000	; (HL) -> B
	LD (ZZCBP2),A
	EXX
	CALL GETA
	EXX
	LD B,A
	EX AF,AF'
	DEFB #CB
ZZCBP2:	DEFB 0
	EX AF,AF'
	LD A,B
	EXX
	CALL PUTA
	EXX
	JP NEXTOP
;---------------------------------------------------------

zzCC:			;CC nn nn     CALL Z,nn

	EX AF,AF'
	JR NZ,ZZCCJ
	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP

ZZCCJ:	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP
zzCD:			;CD nn nn     CALL nn

	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP
zzCE:			;CE nn        ADC A,n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	ADC A,B
	EX AF,AF'
	JP NEXTOP
zzCF:			;CF           RST #08

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#08
	JP NEXTOP
zzD0:			;D0           RET NC

	EX AF,AF'
	JR C,ZZD0J
	EX AF,AF'
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
ZZD0J:	EX AF,AF'
	JP NEXTOP
zzD1:			;D1           POP DE

	EXX
	PUSH HL
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	POP HL
	EXX
	JP NEXTOP
zzD2:			;D2 nn nn     JP NC,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JR C,ZZD2J
	EX DE,HL
ZZD2J:	EX AF,AF'
	JP NEXTOP
zzD3:			;D3 nn        OUT n,A
	CALL GETA
	LD C,A
	INC HL ;MI
	EX AF,AF'
	LD B,A
	EX AF,AF'
	LD A,B
	CALL OUTPUT
	JP NEXTOP
zzD4:			;D4 nn nn     CALL NC,nn

	EX AF,AF'
	JR C,ZZD4J
	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP

ZZD4J:	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP
zzD5:			;D5           PUSH DE

	EXX
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	EXX
	JP NEXTOP
zzD6:			;D6 nn        SUB n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	SUB B
	EX AF,AF'
	JP NEXTOP
zzD7:			;D7           RST #10

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#10
	JP NEXTOP
zzD8:			;D8           RET C

	EX AF,AF'
	JR NC,ZZD8J
	EX AF,AF'
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
ZZD8J:	EX AF,AF'
	JP NEXTOP

zzD9:			;D9           EXX

	PUSH HL
	LD HL,(PILKHL)
	LD DE,(PILKDE)
	LD BC,(PILKBC)
	EXX
	LD (PILKHL),HL
	LD (PILKDE),DE
	LD (PILKBC),BC
	POP HL
	JP NEXTOP
zzDA:			;DA nn nn     JP C,nn


	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JR NC,ZZDAJ
	EX DE,HL
ZZDAJ:	EX AF,AF'
	JP NEXTOP
zzDB:			;DB nn        IN A,(n)

	CALL GETA
	LD C,A
	INC HL ;MI
	CALL INPUT
	LD B,A
	EX AF,AF'
	LD A,B
	EX AF,AF'
	JP NEXTOP
zzDC:			;DC nn nn     CALL C,nn

	EX AF,AF'
	JR NC,ZZDCJ
	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP

ZZDCJ:	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP

;---------------------------------------------------------------------------------------------------



zzDD:			;DD Support here...
	LD D,tabdd / 256
	JP NEXTSUB

	include z80dd.inc


;----------------------------------------------------------------------------------------------------

zzDE:			;DE nn        SBC A,n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	SBC A,B
	EX AF,AF'
	JP NEXTOP
zzDF:			;DF           RST #18

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#18
	JP NEXTOP
zzE0:			;E0           RET PO

	EX AF,AF'
	JP PE,ZZE0J
	EX AF,AF'
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
ZZE0J:	EX AF,AF'
	JP NEXTOP
zzE1:			;E1           POP HL

	EXX
	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	POP HL
	EX DE,HL
	EXX
	JP NEXTOP
zzE2:			;E2 nn nn     JP PO,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JP PE,ZZE2J
	EX DE,HL
ZZE2J:	EX AF,AF'
	JP NEXTOP
zzE3:			;E3           EX (SP),HL

	PUSH HL
	EXX
	PUSH HL
	EXX
	POP DE
	LD HL,(PILKSP)
	CALL GETA
	LD C,A
	LD A,E
	CALL PUTA
	INC HL
	CALL GETA
	LD B,A
	LD A,D
	CALL PUTA
	PUSH BC
	EXX
	POP HL
	EXX
	POP HL
	JP NEXTOP
zzE4:			;E4 nn nn     CALL PO,nn

	EX AF,AF'
	JP PE,ZZE4J
	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP

ZZE4J:	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP
zzE5:			;E5           PUSH HL

	EXX
	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	EX DE,HL
	EXX
	JP NEXTOP
zzE6:			;E6 nn        AND n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	AND B
	EX AF,AF'
	JP NEXTOP
zzE7:			;E7           RST #20

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#20
	JP NEXTOP
zzE8:			;E8           RET PE

	EX AF,AF'
	JP PO,ZZE8J
	EX AF,AF'
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
ZZE8J:	EX AF,AF'
	JP NEXTOP
zzE9:			;E9           JP (HL)	; Should be JP HL


	EXX
	LD A,H
	EXX
	LD H,A
	EXX
	LD A,L
	EXX
	LD L,A
	JP NEXTOP
zzEA:			;EA nn nn     JP PE,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JP PO,ZZEAJ
	EX DE,HL
ZZEAJ:	EX AF,AF'
	JP NEXTOP
zzEB:			;EB           EX DE,HL

	EXX
	EX DE,HL
	EXX
	JP NEXTOP
zzEC:			;EC nn nn     CALL PE,nn

	EX AF,AF'
	JP PO,ZZECJ
	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP

ZZECJ:	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP
;----------------------------------------------------------------

ZZED:			; ED HANDLING ROUTINE HERE
	LD D,tabed / 256
	JP NEXTSUB

	include z80ed.inc

;----------------------------------------------------------------


zzEE:			;EE nn        XOR n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	XOR B
	EX AF,AF'
	JP NEXTOP
zzEF:			;EF           RST #28

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#28
	JP NEXTOP
zzF0:			;F0           RET P

	EX AF,AF'
	JP P,ZZF0J
	EX AF,AF'
	JP NEXTOP
ZZF0J:	EX AF,AF'
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
zzF1:			;F1           POP AF

	PUSH HL
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	POP HL
	PUSH DE
	EX AF,AF'
	POP AF
	EX AF,AF'
	JP NEXTOP
zzF2:			;F2 nn nn     JP P,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JP P,ZZF2J
	EX AF,AF'
	JP NEXTOP
ZZF2J:	EX DE,HL
	EX AF,AF'
	JP NEXTOP
zzF3:			;F3           DI

	LD A,1
	LD (INTENAB),A
	LD A,(ICOUNT)
	AND A
	JP NZ,NEXTOP
	INC A
	LD (ICOUNT),A
	JP NEXTOP
zzF4:			;F4 nn nn     CALL P,nn

	EX AF,AF'
	JP P,ZZF4J
	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP

ZZF4J:	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP


zzF5:			;F5           PUSH AF

	EX AF,AF'
	PUSH AF
	EX AF,AF'
	POP DE	
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP
zzF6:			;F6 nn        OR n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	OR B
	EX AF,AF'
	JP NEXTOP
zzF7:			;F7           RST #30

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#30
	JP NEXTOP
zzF8:			;F8           RET M
	EX AF,AF'
	JP M,ZZF8J
	EX AF,AF'
	JP NEXTOP
ZZF8J:	EX AF,AF'
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	LD E,A
	CALL GETA
	INC HL
	LD D,A
	LD (PILKSP),HL
	EX DE,HL
	JP NEXTOP
zzF9:			;F9           LD SP,HL

	EXX
	LD (PILKSP),HL
	EXX
	JP NEXTOP
zzFA:			;FA nn nn     JP M,nn

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX AF,AF'
	JP M,ZZFAJ
	EX AF,AF'
	JP NEXTOP
ZZFAJ:	EX DE,HL
	EX AF,AF'
	JP NEXTOP
zzFB:			;FB           EI

	XOR A
	LD (INTENAB),A
	LD D,tabz80 / 256
	JP NEXTSUB


zzFC:			;FC nn nn     CALL M,nn
	EX AF,AF'
	JP M,ZZFCJ
	EX AF,AF'
	INC HL
	INC HL
	JP NEXTOP

ZZFCJ:	EX AF,AF'
	CALL GETA
	LD E,A
	INC HL
	CALL GETA
	LD D,A
	INC HL

	EX DE,HL
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	POP HL
	JP NEXTOP

;----------------------------------------------------------------

zzFD:			;FD HANDLING ROUTINE HERE...

	LD D,tabfd / 256
	JP NEXTSUB

	include z80fd.inc

;----------------------------------------------------------------

zzFE:			;FE nn        CP n

	CALL GETA
	LD B,A
	INC HL ;MI
	EX AF,AF'
	CP B
	EX AF,AF'
	JP NEXTOP
zzFF:			;FF           RST #38

	EX DE,HL
	LD HL,(PILKSP)
	DEC HL
	LD A,D
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	LD A,E
	CALL PUTA
	LD HL,#38
	JP NEXTOP

END:

