
; R800 instructions

zedC1:			;C1		MULUB A,B
	EXX
	LD A,B
	JP R800MUL16


zedC3:			;C3		MULUW HL,BC

	EXX
	LD A,B
	EXX
	LD D,A
	EXX
	LD A,C
	EXX
	LD E,A
	JP R800MUL32

zedC9:			;C9		MULUB A,C
	EXX
	LD A,C
	JP R800MUL16


zedD1:			;D1		MULUB A,D
	EXX
	LD A,D
	JP R800MUL16
zedD9:			;D9		MULUB A,E
	EXX
	LD A,E
	JP R800MUL16
zedF3:			;F3		MULUW HL,SP

	LD (ZEDF3B),SP
	LD DE,0
ZEDF3B: EQU $-2
	JP R800MUL32


; 16bit multibly:

R800MUL16:	
		EXX
		LD E,A
		EX AF,AF'
		LD D,A
		EX AF,AF'

		XOR A
		LD B,8
R800MUL16J2:	RR E
		JR NC,R800MUL16J1
		ADD A,D
R800MUL16J1:	RRA
		DJNZ R800MUL16J2
		RR E
		EXX
		LD H,A
		EXX
		LD A,E
		EXX
		LD L,A
		EXX
		JP NEXTOP

; 32bit multibly:

R800MUL32:
		EXX
		LD A,L
		EXX
		LD C,A
		EXX
		LD A,H
		EXX

		LD B,16
		LD (R800MUL32HL),HL
		LD HL,0
		OR A
R800MUL32J2:	RRA
		RR C
		JR NC,R800MUL32J3
		ADD HL,DE
R800MUL32J3:	RR H
		RR L
		DJNZ R800MUL32J2
		RRA
		RR C

		EXX
		LD H,A
		EXX
		LD A,C
		EXX
		LD L,A
		EXX
		LD A,H
		EXX
		LD D,A
		EXX
		LD A,L
		EXX
		LD E,A
		EXX

		LD HL,0
R800MUL32HL:	EQU $-2
		JP NEXTOP

zedD3:			;D3		MULUW HL,DE	(Should not work)
zedE1:			;E1		MULUB A,H	(Should not work)
zedE3:			;E3		MULUW HL,HL	(Should not work)
zedE9:			;E9		MULUB A,L	(Should not work)
zedF9:			;F9		MULUB A,A	(Should not work)

