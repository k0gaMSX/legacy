
; R800 instructions

zedC1:			;C1		MULUB A,B
zedC3:			;C3		MULUW HL,BC
zedC9:			;C9		MULUB A,C
zedD1:			;D1		MULUB A,D
zedD3:			;D3		MULUW HL,DE	(Should not work)
zedD9:			;D9		MULUB A,E
zedE1:			;E1		MULUB A,H	(Should not work)
zedE3:			;E3		MULUW HL,HL	(Should not work)
zedE9:			;E9		MULUB A,L	(Should not work)
zedF3:			;F3		MULUW HL,SP
zedF9:			;F9		MULUB A,A	(Should not work)

