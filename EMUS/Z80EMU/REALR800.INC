
; R800 instructions

zedC1:			;C1		MULUB A,B
	EX AF,AF'
	EXX
	DEFB #ED,#C1
	EXX
	EX AF,AF'
	JP NEXTOP

zedC3:			;C3		MULUW HL,BC
	EX AF,AF'
	EXX
	DEFB #ED,#C3
	EXX
	EX AF,AF'
	JP NEXTOP

zedC9:			;C9		MULUB A,C
	EX AF,AF'
	EXX
	DEFB #ED,#C9
	EXX
	EX AF,AF'
	JP NEXTOP

zedD1:			;D1		MULUB A,D
	EX AF,AF'
	EXX
	DEFB #ED,#D1
	EXX
	EX AF,AF'
	JP NEXTOP

zedD3:			;D3		MULUW HL,DE	(Should not work)
	EX AF,AF'
	EXX
	DEFB #ED,#D3
	EXX
	EX AF,AF'
	JP NEXTOP

zedD9:			;D9		MULUB A,E
	EX AF,AF'
	EXX
	DEFB #ED,#D9
	EXX
	EX AF,AF'
	JP NEXTOP

zedE1:			;E1		MULUB A,H	(Should not work)
	EX AF,AF'
	EXX
	DEFB #ED,#E1
	EXX
	EX AF,AF'
	JP NEXTOP

zedE3:			;E3		MULUW HL,HL	(Should not work)
	EX AF,AF'
	EXX
	DEFB #ED,#E3
	EXX
	EX AF,AF'
	JP NEXTOP

zedE9:			;E9		MULUB A,L	(Should not work)
	EX AF,AF'
	EXX
	DEFB #ED,#E9
	EXX
	EX AF,AF'
	JP NEXTOP

zedF3:			;F3		MULUW HL,SP
	EX AF,AF'
	EXX
	DEFB #ED,#F3
	EXX
	EX AF,AF'
	JP NEXTOP

zedF9:			;F9		MULUB A,A	(Should not work)
	EX AF,AF'
	EXX
	DEFB #ED,#F9
	EXX
	EX AF,AF'
	JP NEXTOP
