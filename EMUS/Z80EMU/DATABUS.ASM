
; DATABUS.GEN for MSX homecomputers (Made By: NYYRIKKI)
;
; This program reads a value from databus when Z80 leaves databus control to peripherals.
; Read may fail if data changes between interrupts, since reading is done with two HALT
; instructions. If failure happens computer may hang or cause unwanted actions.
; Use with own risk.
;
; Usage from MSX-BASIC:
;
;	BLOAD "DATABUS.BIN",R:PRINT USR(0)
;
;
; Ps. Unmodifyed MSX should give value #FF allways. (according to my knowledge)
;-----------------------------------------------------------------------------------------

USR:	EQU #F7F8
USR0:	EQU #F39A

	DEFB #FE
	DEFW BEGIN
	DEFW END
	DEFW START

	ORG #C400

BEGIN:
START:
	LD HL,CODE
	LD (USR0),HL
	RET
CODE:
	DI
	LD HL,#C0C1
	LD DE,NEWINT
	LD (#C200),HL
	CALL INST
	LD HL,#C1C0
	CALL INST
	LD HL,#C200
	LD DE,#C202
	LD BC,#102
	LDIR
	LD A,#C2
	LD I,A
	IM 2
	EI
	NOP
	HALT

	DI
	LD H,#C2
	AND 1
	XOR 1
	LD L,A
	LD B,#81

LOOP:
	LD (HL),#C0
	INC HL
	LD (HL),A
	INC HL
	INC A
	INC A
	DJNZ LOOP

	LD HL,#C000
	LD DE,#C001
	LD BC,#FF
	LD (HL),#3D
	LDIR
	LD (HL),#C9
	EI
	XOR A
	HALT
	IM 1
	LD (USR),A
	XOR A
	LD (USR+1),A
	RET


NEWINT:
	POP AF
	RETI

INST:
	LD (HL),#CD
	INC HL
	LD (HL),E
	INC HL
	LD (HL),D
	RET

END: