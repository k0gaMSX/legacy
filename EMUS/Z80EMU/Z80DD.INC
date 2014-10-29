zDD09:			;DD 09        ADD IX,BC

	EXX
	ADD IX,BC
	EXX
	JP NEXTOP
zDD19:			;DD 19        ADD IX,DE

	EXX
	ADD IX,DE
	EXX
	JP NEXTOP
zDD21:			;DD 21 nn nn  LD IX,nn
	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	PUSH DE
	POP IX
	JP NEXTOP
zDD22:			;DD 22 nn nn  LD (nn),IX
	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	DEFW #7DDD	;LD A,IXl
	CALL PUTA
	INC HL
	DEFW #7CDD	;LD A,IXh
	CALL PUTA
	EX DE,HL
	JP NEXTOP

zDD23:			;DD 23        INC IX

	INC IX
	JP NEXTOP
zDD24:			;DD 24        INC IXh  (*)
	DEFW #24DD
	JP NEXTOP
zDD25:			;DD 25        DEC IXh  (*)
	DEFW #25DD
	JP NEXTOP
zDD26:			;DD 26 nn     LD IXh,n  (*)
	CALL GETA
	INC HL ;MI
	DEFW #67DD	; LD IXh,a (*)
	JP NEXTOP

zDD29:			;DD 29        ADD IX,IX

	EX AF,AF'
	ADD IX,IX
	EX AF,AF'
	JP NEXTOP
zDD2A:			;DD 2A nn nn  LD IX,(nn)

	CALL GETA
	LD E,A
	INC HL ;MI
	CALL GETA
	LD D,A
	INC HL ;MI
	EX DE,HL
	CALL GETA
	DEFW #6FDD	;LD IXl,A
	INC HL
	CALL GETA
	DEFW #67DD	;LD IXh,A
	EX DE,HL
	JP NEXTOP
zDD2B:			;DD 2B        DEC IX

	DEC IX
	JP NEXTOP


zDD2C:			;DD 2C        INC IXl  (*)
	DEFW #2CDD
	JP NEXTOP
zDD2D:			;DD 2D        DEC IXl  (*)
	DEFW #2DDD
	JP NEXTOP
zDD2E:			;DD 2E nn     LD IXl,n  (*)
	CALL GETA
	INC HL ;MI
	DEFW #6FDD	; LD IXl,a (*)
	JP NEXTOP


zDD34:			;DD 34 nn     INC (IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
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
zDD35:			;DD 35 nn     DEC (IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
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

zDD36:			;DD 36 nn oo  LD (IX+n),o

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	CALL GETA
	INC HL
	LD B,A
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	LD A,B
	CALL PUTA
	POP HL
	JP NEXTOP


zDD39:			;DD 39        ADD IX,SP

	LD DE,(PILKSP)
	EX AF,AF'
	ADD IX,DE
	EX AF,AF'
	JP NEXTOP

zDD44:			;DD 44        LD B,IXH (*)
	EXX
	DEFW #44DD
	EXX
	JP NEXTOP
zDD45:			;DD 45        LD B,IXL (*)

	EXX
	DEFW #45DD
	EXX
	JP NEXTOP

zDD46:			;DD 46 nn     LD B,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD B,A
	EXX
	POP HL
	JP NEXTOP


zDD4C:			;DD 4C        LD C,IXH (*)

	EXX
	DEFW #4CDD
	EXX
	JP NEXTOP
zDD4D:			;DD 4D        LD C,IXL (*)

	EXX
	DEFW #4DDD
	EXX
	JP NEXTOP


zDD4E:			;DD 4E nn     LD C,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD C,A
	EXX
	POP HL
	JP NEXTOP

zDD54:			;DD 54        LD D,IXH (*)

	EXX
	DEFW #54DD
	EXX
	JP NEXTOP
zDD55:			;DD 55        LD D,IXL (*)

	EXX
	DEFW #55DD
	EXX
	JP NEXTOP

zDD56:			;DD 56 nn     LD D,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD D,A
	EXX
	POP HL
	JP NEXTOP
zDD5C:			;DD 5C        LD E,IXH (*)

	EXX
	DEFW #5CDD
	EXX
	JP NEXTOP
zDD5D:			;DD 5D        LD E,IXL (*)

	EXX
	DEFW #5DDD
	EXX
	JP NEXTOP

zDD5E:			;DD 5E nn     LD E,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD E,A
	EXX
	POP HL
	JP NEXTOP
ZDD60:			;DD 60        LD IXH,B (*)
	EXX
	DEFW #60DD
	EXX
	JP NEXTOP
ZDD61:			;DD 61        LD IXH,C (*)
	EXX
	DEFW #61DD
	EXX
	JP NEXTOP
ZDD62:			;DD 60        LD IXH,D (*)
	EXX
	DEFW #62DD
	EXX
	JP NEXTOP
ZDD63:			;DD 63        LD IXH,E (*)
	EXX
	DEFW #63DD
	EXX
	JP NEXTOP
ZDD65:			;DD 65        LD IXH,IXL (*)
	DEFW #65DD
	JP NEXTOP
zDD66:			;DD 66 nn     LD H,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD H,A
	EXX
	POP HL
	JP NEXTOP

ZDD67:			;DD 67        LD IXH,A (*)
	EX AF,AF'
	DEFW #67DD
	EX AF,AF'
	JP NEXTOP

ZDD68:			;DD 68        LD IXL,B (*)
	EXX
	DEFW #68DD
	EXX
	JP NEXTOP
ZDD69:			;DD 69        LD IXL,C (*)
	EXX
	DEFW #69DD
	EXX
	JP NEXTOP
ZDD6A:			;DD 6A        LD IXL,D (*)
	EXX
	DEFW #6ADD
	EXX
	JP NEXTOP

ZDD6B:			;DD 6B        LD IXL,E (*)
	EXX
	DEFW #6BDD
	EXX
	JP NEXTOP

ZDD6C:			;DD 6C        LD IXL,IXH (*)
	DEFW #6CDD
	JP NEXTOP


zDD6E:			;DD 6E nn     LD L,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	EXX
	LD L,A
	EXX
	POP HL
	JP NEXTOP
ZDD6F:			;DD 6F        LD IXL,A (*)
	EX AF,AF'
	DEFW #6FDD
	EX AF,AF'
	JP NEXTOP

zDD70:			;DD 70 nn     LD (IX+n),B

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,B
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zDD71:			;DD 71 nn     LD (IX+n),C

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,C
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zDD72:			;DD 72 nn     LD (IX+n),D

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,D
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zDD73:			;DD 73 nn     LD (IX+n),E

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,E
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zDD74:			;DD 74 nn     LD (IX+n),H

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,H
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zDD75:			;DD 75 nn     LD (IX+n),L

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	EXX
	LD A,L
	EXX
	CALL PUTA
	POP HL
	JP NEXTOP
zDD77:			;DD 77 nn     LD (IX+n),A

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	EX AF,AF'
	LD B,A
	EX AF,AF'
	LD A,B
	CALL PUTA
	POP HL
	JP NEXTOP

ZDD7C:			;DD 7C        LD A,IXH (*)
	EX AF,AF'
	DEFW #7CDD
	EX AF,AF'
	JP NEXTOP
ZDD7D:			;DD 7D        LD A,IXL (*)
	EX AF,AF'
	DEFW #7DDD
	EX AF,AF'
	JP NEXTOP

zDD7E:			;DD 7E nn     LD A,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	LD A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZDD84:			;DD 84        ADD A,IXH (*)
	EX AF,AF'
	DEFW #84DD
	EX AF,AF'
	JP NEXTOP
ZDD85:			;DD 85        ADD A,IXL (*)
	EX AF,AF'
	DEFW #85DD
	EX AF,AF'
	JP NEXTOP




zDD86:			;DD 86 nn     ADD A,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	ADD A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZDD8C:			;DD 8C        ADC A,IXH (*)
	EX AF,AF'
	DEFW #8CDD
	EX AF,AF'
	JP NEXTOP

ZDD8D:			;DD 8D        ADC A,IXL (*)
	EX AF,AF'
	DEFW #8DDD
	EX AF,AF'
	JP NEXTOP

zDD8E:			;DD 8E nn     ADC A,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	ADC A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZDD94:			;DD 94        SUB IXH (*)
	EX AF,AF'
	DEFW #94DD
	EX AF,AF'
	JP NEXTOP

ZDD95:			;DD 95        SUB IXL (*)
	EX AF,AF'
	DEFW #95DD
	EX AF,AF'
	JP NEXTOP

zDD96:			;DD 96 nn     SUB (IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	SUB B
	EX AF,AF'
	POP HL
	JP NEXTOP

ZDD9C:			;DD 9C        SBC A,IXH (*)
	EX AF,AF'
	DEFW #9CDD
	EX AF,AF'
	JP NEXTOP

ZDD9D:			;DD 9D        SBC A,IXL (*)
	EX AF,AF'
	DEFW #9DDD
	EX AF,AF'
	JP NEXTOP

zDD9E:			;DD 9E nn     SBC A,(IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	SBC A,B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZDDA4:			;DD A4        AND IXH (*)
	EX AF,AF'
	DEFW #A4DD
	EX AF,AF'
	JP NEXTOP

ZDDA5:			;DD A5        AND IXL (*)
	EX AF,AF'
	DEFW #A5DD
	EX AF,AF'
	JP NEXTOP

zDDA6:			;DD A6 nn     AND (IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	AND B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZDDAC:			;DD AC        XOR IXH (*)
	EX AF,AF'
	DEFW #ACDD
	EX AF,AF'
	JP NEXTOP

ZDDAD:			;DD AD        XOR IXL (*)
	EX AF,AF'
	DEFW #ADDD
	EX AF,AF'
	JP NEXTOP

zDDAE:			;DD AE nn     XOR (IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	XOR B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZDDB4:			;DD B4        OR IXH (*)
	EX AF,AF'
	DEFW #B4DD
	EX AF,AF'
	JP NEXTOP

ZDDB5:			;DD B5        OR IXL (*)
	EX AF,AF'
	DEFW #B5DD
	EX AF,AF'
	JP NEXTOP

zDDB6:			;DD B6 nn     OR (IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
	EX (SP),HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	OR B
	EX AF,AF'
	POP HL
	JP NEXTOP
ZDDBC:			;DD BC        CP IXH (*)
	EX AF,AF'
	DEFW #BCDD
	EX AF,AF'
	JP NEXTOP

ZDDBD:			;DD BD        CP IXL (*)
	EX AF,AF'
	DEFW #BDDD
	EX AF,AF'
	JP NEXTOP

zDDBE:			;DD BE nn     CP (IX+n)

	CALL GETA
	INC HL ;MI
	LD E,A
	LD D,0
	PUSH IX
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

ZDDCB:			;DD CB nn oo = oo (IX+nn)[,r]

	CALL GETA
	INC HL
	LD E,A
	LD D,0
	CALL GETA
	INC HL
	LD C,A
	AND %11111000	; (HL) -> B
	LD (ZDDCBP),A
	PUSH HL

	PUSH IX
	POP HL
	ADD HL,DE
	CALL GETA
	LD B,A
	EX AF,AF'
	DEFB #CB
ZDDCBP:	DEFB 0
	EX AF,AF'
	LD A,B
	CALL PUTA

	LD A,C
	AND 7
	CP 6
	JR NZ,ZDDCBJ
	POP HL
	JP NEXTOP

; NOT STANDARD OPERATIONS

ZDDCBJ:		; (IX+N),A
	CP 7
	JR NZ,ZDDCBJ2
	EX AF,AF'
	LD A,B
	EX AF,AF'
	POP HL
	JP NEXTOP

ZDDCBJ2:		; (IX+N),r
	RLCA
	RLCA
	RLCA
	OR %01000111
	LD (ZDDCBP2),A	; LD r,A
	LD A,B
	EXX
ZDDCBP2:	DEFB 0
	EXX
	POP HL
	JP NEXTOP


;---------------------------------------------------------

zDDE1:			;DD E1        POP IX

	PUSH HL
	LD HL,(PILKSP)
	CALL GETA
	INC HL
	DEFW #6FDD	;LD IXl,A
	CALL GETA
	INC HL
	DEFW #67DD	;LD IXh,A
	LD (PILKSP),HL
	POP HL
	JP NEXTOP
zDDE3:			;DD E3        EX (SP),IX


	PUSH HL
	PUSH IX
	POP DE
	LD HL,(PILKSP)
	CALL GETA
	DEFW #6FDD	;LD IXl,A
	LD A,E
	CALL PUTA
	INC HL
	CALL GETA
	DEFW #67DD	;LD IXh,A
	LD A,D
	CALL PUTA
	POP HL
	JP NEXTOP
zDDE5:			;DD E5        PUSH IX
	PUSH HL
	LD HL,(PILKSP)
	DEC HL
	DEFW #7CDD	;LD A,IXh
	CALL PUTA
	DEC HL
	LD (PILKSP),HL
	DEFW #7DDD	;LD A,IXl
	CALL PUTA
	POP HL
	JP NEXTOP
zDDE9:			;DD E9        JP (IX)	; Notation should be: JP IX

	PUSH IX
	POP HL
	JP NEXTOP
zDDF9:			;DD F9        LD SP,IX

	LD (PILKSP),IX
	JP NEXTOP
