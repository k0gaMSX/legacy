zFD09:			;FD 09        ADD IY,BC

	EXX
	ADD IY,BC
	EXX
	JP NEXTOP
zFD19:			;FD 19        ADD IY,DE

	EXX
	ADD IY,DE
	EXX
	JP NEXTOP
zFD21:			;FD 21 nn nn  LD IY,nn
	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	PUSH DE
	POP IY
	JP NEXTOP
zFD22:			;FD 22 nn nn  LD (nn),IY
	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	DEFW #7DFD	;LD A,IYl
	CALL PUTA
	INC HL
	DEFW #7CFD	;LD A,IYh
	CALL PUTA
	EX DE,HL
	JP NEXTOP

zFD23:			;FD 23        INC IY

	INC IY
	JP NEXTOP
zFD24:			;FD 24        INC IYh  (*)
	DEFW #24FD
	JP NEXTOP
zFD25:			;FD 25        DEC IYh  (*)
	DEFW #25FD
	JP NEXTOP
zFD26:			;FD 26 nn     LD IYh,n  (*)
	CALL GETA
	INC HL ;MI
	DEFW #67FD	; LD IYh,a (*)
	JP NEXTOP

zFD29:			;FD 29        ADD IY,IY

	EX AF,AF'
	ADD IY,IY
	EX AF,AF'
	JP NEXTOP
zFD2A:			;FD 2A nn nn  LD IY,(nn)

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	CALL GETA
	DEFW #6FFD	;LD IYl,A
	INC HL
	CALL GETA
	DEFW #67FD	;LD IYh,A
	EX DE,HL
	JP NEXTOP
zFD2B:			;FD 2B        DEC IY

	DEC IY
	JP NEXTOP


zFD2C:			;FD 2C        INC IYl  (*)
	DEFW #2CFD
	JP NEXTOP
zFD2D:			;FD 2D        DEC IYl  (*)
	DEFW #2DFD
	JP NEXTOP
zFD2E:			;FD 2E nn     LD IYl,n  (*)
	CALL GETA
	INC HL ;MI
	DEFW #6FFD	; LD IYl,a (*)
	JP NEXTOP


zFD34:			;FD 34 nn     INC (IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	INC B
	EX AF,AF'
	LD A,B
	CALL PUTA
	POP HL
	JP NEXTOP
zFD35:			;FD 35 nn     DEC (IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	DEC B
	EX AF,AF'
	LD A,B
	CALL PUTA
	POP HL
	JP NEXTOP

zFD36:			;FD 36 nn oo  LD (IY+n),o

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	CALL GETA
	INC HL
	LD B,A
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	LD A,B
	CALL PUTA
	POP HL
	JP NEXTOP


zFD39:			;FD 39        ADD IY,SP

	LD DE,(PILKSP)
	EX AF,AF'
	ADD IY,DE
	EX AF,AF'
	JP NEXTOP

zFD44:			;FD 44        LD B,IYH (*)
	EXX
	DEFW #44FD
	EXX
	JP NEXTOP
zFD45:			;FD 45        LD B,IYL (*)

	EXX
	DEFW #45FD
	EXX
	JP NEXTOP

zFD46:			;FD 46 nn     LD B,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD B,A
	EXX
	POP HL
	JP NEXTOP


zFD4C:			;FD 4C        LD C,IYH (*)

	EXX
	DEFW #4CFD
	EXX
	JP NEXTOP
zFD4D:			;FD 4D        LD C,IYL (*)

	EXX
	DEFW #4DFD
	EXX
	JP NEXTOP


zFD4E:			;FD 4E nn     LD C,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD C,A
	EXX
	POP HL
	JP NEXTOP

zFD54:			;FD 54        LD D,IYH (*)

	EXX
	DEFW #54FD
	EXX
	JP NEXTOP
zFD55:			;FD 55        LD D,IYL (*)

	EXX
	DEFW #55FD
	EXX
	JP NEXTOP

zFD56:			;FD 56 nn     LD D,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD D,A
	EXX
	POP HL
	JP NEXTOP
zFD5C:			;FD 5C        LD E,IYH (*)

	EXX
	DEFW #5CFD
	EXX
	JP NEXTOP
zFD5D:			;FD 5D        LD E,IYL (*)

	EXX
	DEFW #5DFD
	EXX
	JP NEXTOP

zFD5E:			;FD 5E nn     LD E,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD E,A
	EXX
	POP HL
	JP NEXTOP
ZFD60:			;FD 60        LD IYH,B (*)
	EXX
	DEFW #60FD
	EXX
	JP NEXTOP
ZFD61:			;FD 61        LD IYH,C (*)
	EXX
	DEFW #61FD
	EXX
	JP NEXTOP
ZFD62:			;FD 60        LD IYH,D (*)
	EXX
	DEFW #62FD
	EXX
	JP NEXTOP
ZFD63:			;FD 63        LD IYH,E (*)
	EXX
	DEFW #63FD
	EXX
	JP NEXTOP
ZFD65:			;FD 65        LD IYH,IYL (*)
	DEFW #65FD
	JP NEXTOP
zFD66:			;FD 66 nn     LD H,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD H,A
	EXX
	POP HL
	JP NEXTOP

ZFD67:			;FD 67        LD IYH,A (*)
	EX AF,AF'
	DEFW #67FD
	EX AF,AF'
	JP NEXTOP

ZFD68:			;FD 68        LD IYL,B (*)
	EXX
	DEFW #68FD
	EXX
	JP NEXTOP
ZFD69:			;FD 69        LD IYL,C (*)
	EXX
	DEFW #69FD
	EXX
	JP NEXTOP
ZFD6A:			;FD 6A        LD IYL,D (*)
	EXX
	DEFW #6ADD
	EXX
	JP NEXTOP

ZFD6B:			;FD 6B        LD IYL,E (*)
	EXX
	DEFW #6BFD
	EXX
	JP NEXTOP

ZFD6C:			;FD 6C        LD IYL,IYH (*)
	DEFW #6CFD
	JP NEXTOP


zFD6E:			;FD 6E nn     LD L,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD L,A
	EXX
	POP HL
	JP NEXTOP
ZFD6F:			;FD 6F        LD IYL,A (*)
	EX AF,AF'
	DEFW #6FFD
	EX AF,AF'
	JP NEXTOP

zFD70:			;FD 70 nn     LD (IY+n),B

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,B
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zFD71:			;FD 71 nn     LD (IY+n),C

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,C
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zFD72:			;FD 72 nn     LD (IY+n),D

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,D
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zFD73:			;FD 73 nn     LD (IY+n),E

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,E
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zFD74:			;FD 74 nn     LD (IY+n),H

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,H
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zFD75:			;FD 75 nn     LD (IY+n),L

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,L
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zFD77:			;FD 77 nn     LD (IY+n),A

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	EX AF,AF'
	LD B,A
	EX AF,AF'
	LD A,B
	CALL PUTA
	POP HL
	JP NEXTOP

ZFD7C:			;FD 7C        LD A,IYH (*)
	EX AF,AF'
	DEFW #7CFD
	EX AF,AF'
	JP NEXTOP
ZFD7D:			;FD 7D        LD A,IYL (*)
	EX AF,AF'
	DEFW #7DFD
	EX AF,AF'
	JP NEXTOP

zFD7E:			;FD 7E nn     LD A,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	LD A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZFD84:			;FD 84        ADD A,IYH (*)
	EX AF,AF'
	DEFW #84FD
	EX AF,AF'
	JP NEXTOP
ZFD85:			;FD 85        ADD A,IYL (*)
	EX AF,AF'
	DEFW #85FD
	EX AF,AF'
	JP NEXTOP




zFD86:			;FD 86 nn     ADD A,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	ADD A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZFD8C:			;FD 8C        ADC A,IYH (*)
	EX AF,AF'
	DEFW #8CFD
	EX AF,AF'
	JP NEXTOP

ZFD8D:			;FD 8D        ADC A,IYL (*)
	EX AF,AF'
	DEFW #8DFD
	EX AF,AF'
	JP NEXTOP

zFD8E:			;FD 8E nn     ADC A,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	ADC A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZFD94:			;FD 94        SUB IYH (*)
	EX AF,AF'
	DEFW #94FD
	EX AF,AF'
	JP NEXTOP

ZFD95:			;FD 95        SUB IYL (*)
	EX AF,AF'
	DEFW #95FD
	EX AF,AF'
	JP NEXTOP

zFD96:			;FD 96 nn     SUB (IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	SUB B
	EX AF,AF'
	POP HL
	JP NEXTOP

ZFD9C:			;FD 9C        SBC A,IYH (*)
	EX AF,AF'
	DEFW #9CFD
	EX AF,AF'
	JP NEXTOP

ZFD9D:			;FD 9D        SBC A,IYL (*)
	EX AF,AF'
	DEFW #9DFD
	EX AF,AF'
	JP NEXTOP

zFD9E:			;FD 9E nn     SBC A,(IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	SBC A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZFDA4:			;FD A4        AND IYH (*)
	EX AF,AF'
	DEFW #A4FD
	EX AF,AF'
	JP NEXTOP

ZFDA5:			;FD A5        AND IYL (*)
	EX AF,AF'
	DEFW #A5FD
	EX AF,AF'
	JP NEXTOP

zFDA6:			;FD A6 nn     AND (IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	AND B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZFDAC:			;FD AC        XOR IYH (*)
	EX AF,AF'
	DEFW #ACFD
	EX AF,AF'
	JP NEXTOP

ZFDAD:			;FD AD        XOR IYL (*)
	EX AF,AF'
	DEFW #ADDD
	EX AF,AF'
	JP NEXTOP

zFDAE:			;FD AE nn     XOR (IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	XOR B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZFDB4:			;FD B4        OR IYH (*)
	EX AF,AF'
	DEFW #B4FD
	EX AF,AF'
	JP NEXTOP

ZFDB5:			;FD B5        OR IYL (*)
	EX AF,AF'
	DEFW #B5FD
	EX AF,AF'
	JP NEXTOP

zFDB6:			;FD B6 nn     OR (IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	OR B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZFDBC:			;FD BC        CP IYH (*)
	EX AF,AF'
	DEFW #BCFD
	EX AF,AF'
	JP NEXTOP

ZFDBD:			;FD BD        CP IYL (*)
	EX AF,AF'
	DEFW #BDFD
	EX AF,AF'
	JP NEXTOP

zFDBE:			;FD BE nn     CP (IY+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IY
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	CP B
	EX AF,AF'
	POP HL
	JP NEXTOP

;------------------------------------------------------------

; BIT operations

ZFDCB:			;DD CB nn oo = oo (IY+nn)[,r]

	CALL GETA
	INC HL
	LD E,A
	LD D,0
	CALL GETA
	INC HL
	LD C,A
	AND %11111000	; (HL) -> B
	LD (ZFDCBP),A
	PUSH HL

	PUSH IY
	POP HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	DEFB #CB
ZFDCBP:	DEFB 0
	EX AF,AF'
	LD A,B
	CALL PUTA

	LD A,C
	AND 7
	CP 6
	JR NZ,ZFDCBJ
	POP HL
	JP NEXTOP

; NOT STANDARD OPERATIONS

ZFDCBJ:		; (IY+N),A
	CP 7
	JR NZ,ZFDCBJ2
	EX AF,AF'
	LD A,B
	EX AF,AF'
	POP HL
	JP NEXTOP

ZFDCBJ2:		; (IY+N),r
	RLCA
	RLCA
	RLCA
	OR %01000111
	LD (ZFDCBP2),A	; LD r,A
	LD A,B
	EXX
ZFDCBP2:	DEFB 0
	EXX
	POP HL
	JP NEXTOP


;---------------------------------------------------------

zFDE1:			;FD E1        POP IY

	PUSH HL
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	DEFW #6FFD	;LD IYl,A
	CALL GETA
	INC HL
	DEFW #67FD	;LD IYh,A
	LD (PILKSP),HL
	POP HL
	JP NEXTOP
zFDE3:			;FD E3        EX (SP),IY


	PUSH HL
	PUSH IY
	POP DE
	LD HL,(PILKSP)
	CALL GETA
	DEFW #6FFD	;LD IYl,A
	LD A,E
	CALL PUTA
	INC HL
	CALL GETA
	DEFW #67FD	;LD IYh,A
	LD A,D
	CALL PUTA
	POP HL
	JP NEXTOP
zFDE5:			;FD E5        PUSH IY
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	DEFW #7CFD	;LD A,IYh
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	DEFW #7DFD	;LD A,IYl
	CALL PUTA
	POP HL
	JP NEXTOP
zFDE9:			;FD E9        JP (IY)	; Notation should be: JP IY

	PUSH IY
	POP HL
	JP NEXTOP
zFDF9:			;FD F9        LD SP,IY

	LD (PILKSP),IY
	JP NEXTOP
