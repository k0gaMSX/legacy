;
;MULTIPLY 8-BIT VALUES
;IN:  MULTIPLY H WITH E
;OUT: HL = RESULT
;
MULT8:
	LD D,0
	LD L,D
	LD B,8
MULT8_LOOP:
	ADD HL,HL
	JR NC,MULT8_NOADD
	ADD HL,DE
MULT8_NOADD:
	DJNZ MULT8_LOOP
	RET

;
;Multiply 16-bit values (with 16-bit result)
;In: Multiply BC with DE
;Out: HL = result
;
Mult16:	ld a,b
	ld b,16
Mult16_Loop:
	add hl,hl
	sla c
	rla
	jr nc,Mult16_NoAdd
	add hl,de
Mult16_NoAdd:
	djnz Mult16_Loop
	ret
	
;
;Divide 16-bit values (with 16-bit result)
;In: Divide BC by divider DE
;Out: BC = result, HL = rest
;
Div16:	ld hl,0
	ld a,b
	ld b,8
Div16_Loop1:
	rla
	adc hl,hl
	sbc hl,de
	jr nc,Div16_NoAdd1
	add hl,de
Div16_NoAdd1:
	djnz Div16_Loop1
	ld b,a
	ld a,c
	ld c,b
	ld b,8
Div16_Loop2:
	rla
	adc hl,hl
	sbc hl,de
	jr nc,Div16_NoAdd2
	add hl,de
Div16_NoAdd2:
	djnz Div16_Loop2
	rla
	cpl
	ld b,a
	ld a,c
	ld c,b
	rla
	cpl
	ld b,a
	ret	
	
	
;
;Multiply 16-bit values (with 32-bit result)
;In: Multiply BC with DE
;Out: BCHL = result
;
Mult32:	ld a,c
	ld c,b
	ld hl,0
	ld b,16
Mult32_Loop:
	add hl,hl
	rla
	rl c
	jr nc,Mult32_NoAdd
	add hl,de
	adc a,0
	jp nc,Mult32_NoAdd
	inc c
Mult32_NoAdd:
	djnz Mult32_Loop
	ld b,c
	ld c,a
	ret
	
;==================================================
; MULTIPLY ROUTINE 32*32BIT=32BIT
; H'L'HL = B'C'BC * D'E'DE
; NEEDS REGISTER A, CHANGES FLAGS
;
MUL32:
        AND     A               ; RESET CARRY FLAG
        SBC     HL,HL           ; LOWER RESULT = 0
        EXX
        SBC     HL,HL           ; HIGHER RESULT = 0
        LD      A,B             ; MPR IS AC'BC
        LD      B,32            ; INITIALIZE LOOP COUNTER
MUL32LOOP:
        SRA     A               ; RIGHT SHIFT MPR
        RR      C
        EXX
        RR      B
        RR      C               ; LOWEST BIT INTO CARRY
        JR      NC,MUL32NOADD
        ADD     HL,DE           ; RESULT += MPD
        EXX
        ADC     HL,DE
        EXX
MUL32NOADD:
        SLA     E               ; LEFT SHIFT MPD
        RL      D
        EXX
        RL      E
        RL      D
        DJNZ    MUL32LOOP
        EXX
        
; RESULT IN H'L'HL
        RET
	
RAND16:
	LD	DE,0		; SEED IS USUALLY 0
	LD	A,D
	LD	H,E
	LD	L,253
	OR	A
	SBC	HL,DE
	SBC	A,0
	SBC	HL,DE
	LD	D,0
	SBC	A,D
	LD	E,A
	SBC	HL,DE
	JR	NC,RAND
	INC	HL
RAND:
	LD	(RAND16+1),HL
	RET

NRDPAD:	
	PUSH BC	
	PUSH DE
	PUSH HL
	LD	IX,1ADH
	CALL CALSUB
	POP	HL
	POP	DE
	POP	BC
	RET

READ_MOUSE:
	LD		B,A
	CALL	NRDPAD
	INC		B
	LD		A,B
	CALL	NRDPAD
	AND		$FE
	LD		E,A
	BIT		7,A
	JR		Z,.POS_X
	LD		D,-1
	JR		.CONT_X
.POS_X:
	LD		D,0
.CONT_X:
	XOR		A
	OR		E
	JP		Z,.READ_Y
	LD		HL,(MOUSE_POS_X)
	ADD		HL,DE
	BIT		7,H
	JR		Z,.X_GT_0
	LD		HL,0
.X_GT_0:
	EX		DE,HL
	LD		HL,SCREEN_W*2-1
	AND		A
	SBC		HL,DE
	JP		P,.X_GT_W
	LD		DE,SCREEN_W*2-1
.X_GT_W:	
	LD		(MOUSE_POS_X),DE
	LD		A,1
	LD		(SCR_DIRTY),A
.READ_Y:
	INC		B
	LD		A,B
	CALL	NRDPAD
	AND		$FE
	LD		E,A
	BIT		7,A
	JR		Z,.POS_Y
	LD		D,-1
	JR		.CONT_Y
.POS_Y:
	LD		D,0
.CONT_Y:
	XOR		A
	OR		E
	RET		Z
	LD		HL,(MOUSE_POS_Y)
	ADD		HL,DE
	BIT		7,H
	JR		Z,.Y_GT_0
	LD		HL,0
.Y_GT_0:
	EX		DE,HL
	LD		HL,SCREEN_H*4-1
	AND		A
	SBC		HL,DE
	JP		P,.Y_GT_H
	LD		DE,SCREEN_H*4-1
.Y_GT_H:	
	LD		(MOUSE_POS_Y),DE
	LD		A,1
	LD		(SCR_DIRTY),A
	RET
		
READ_MOUSE_BUTTONS:
	
	LD		A,(MOUSE_LBUTTON)
	PUSH	AF
	
	
	LD		IX,GTTRIG	
	LD		A,1
	CALL	CALLBIOS	
	LD		(MOUSE_LBUTTON),A

	LD		A,2
	CALL	CALLBIOS
	LD		HL,MOUSE_LBUTTON
	OR		(HL)
	LD		(HL),A

	LD		A,3
	CALL	CALLBIOS	
	LD		(MOUSE_RBUTTON),A

	LD		A,4
	CALL	CALLBIOS
	LD		HL,MOUSE_RBUTTON
	OR		(HL)
	LD		(HL),A

	POP		BC
	
	LD		A,(MOUSE_LBUTTON)
	OR		A
	JP		Z,.LNPRESSED
	
	LD		DE,(LBUTTON_TICK)
	LD		HL,(VDP_TICK)
	OR		A
	SBC		HL,DE
	LD		A,(_VDPFREQ)
	SRA		A
	LD		E,A
	LD		D,0
	OR		A
	SBC		HL,DE
	JP		M,.LDCLICK
	XOR		A
	JR		.LCONT
.LDCLICK:
	LD		A,B
	OR		A
	JR		NZ,.TICK
	LD		A,1
.LCONT:	
	LD		(MOUSE_LDOUBLECLICK),A
.TICK:
	LD		HL,(VDP_TICK)
	LD		(LBUTTON_TICK),HL		
.LNPRESSED:
	XOR		A
	
	RET

STRNCMP:
; HL: STRING1
; DE: STRING2
; B = STRING SIZE
; NC = EQUAL, C NOT EQUAL
	
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
.LOOP:
	LD		A,(DE)
	INC		DE
	CP		(HL)
	INC		HL
	JR		NZ,.NONEQUAL
	DJNZ	.LOOP
	POP		HL
	POP		DE
	POP		BC
	POP		AF
	OR		A
	RET
	
.NONEQUAL:
	POP		HL
	POP		DE
	POP		BC
	POP		AF
	SCF
	RET

STRCPY:
; HL: STRING1
; DE: STRING2
	
	PUSH	AF
	PUSH	DE
	PUSH	HL
.LOOP:
	LD		A,(HL)
	INC		HL
	LD		(DE),A
	INC		DE
	OR		A
	JR		NZ,.LOOP
	POP		HL
	POP		DE
	POP		AF
	RET

STRCAT:
; HL: STRING1
; DE: STRING2
	PUSH	AF
	PUSH	DE
	PUSH	HL
.LOOP1:
	LD		A,(DE)
	OR		A
	JR		Z,.LOOP
	INC		DE
	JR		.LOOP1
.LOOP:
	LD		A,(HL)
	INC		HL
	LD		(DE),A
	INC		DE
	OR		A
	JR		NZ,.LOOP
	POP		HL
	POP		DE
	POP		AF
	RET


STRCAT_NOTRAILSPACE:
; HL: STRING1
; DE: STRING2
	PUSH	AF
	PUSH	DE
	PUSH	HL
.LOOP1:
	LD		A,(DE)
	OR		A
	JR		Z,.LOOP2
	INC		DE
	JR		.LOOP1
.LOOP2:
	DEC		DE
	LD		A,(DE)
	CP		' '
	JR		Z,.LOOP2
	INC		DE
	INC		DE
.LOOP:
	LD		A,(HL)
	INC		HL
	LD		(DE),A
	INC		DE
	OR		A
	JR		NZ,.LOOP
	POP		HL
	POP		DE
	POP		AF
	RET	
	
STRCAT_NOLEADSPACE:
; HL: STRING1
; DE: STRING2
	PUSH	AF
	PUSH	DE
	PUSH	HL
.LOOP1:
	LD		A,(HL)
	CP		' '
	JR		NZ,.CAT
	INC		HL
	JR		.LOOP1
.CAT:
	CALL	STRCAT
	POP		HL
	POP		DE
	POP		AF
	RET
	
STRLEN:
; HL: STRING
; RETURN: B = STRING SIZE
	LD		B,0
	PUSH	AF
	PUSH	HL
	LD		A,H
	OR		L
	JR		NZ,.COUNT
	POP		HL
	POP		AF
	RET
.COUNT:
	DEC		B
.LOOP_SIZE:
	LD		A,(HL)
	INC		HL
	INC		B
	OR		A
	JR		NZ,.LOOP_SIZE
	POP		HL
	POP		AF
	RET
	
KEY_IS_PRESSED:
; A = ROW | BIT
	LD		HL,$FBE5
	LD		B,A
	AND		$F0
	SRL		A
	SRL		A
	SRL		A
	SRL		A
	ADD		A,L
	LD		L,A
	LD		A,0
	ADC		A,H
	LD		H,A ; GO TO CORRECT ROW
	
	LD		A,B
	AND		$0F
	LD		B,A
	LD		A,(HL)
	JR		Z,.BIT_0
.BIT_LOOP:
	SRL		A
	DJNZ	.BIT_LOOP
.BIT_0:
	AND		1
	CPL
	RRC		A
	RET	
	
ZERO_FILL:
; HL: ADDR
; BC: BYTES
	LD		A,B
	OR		C
	RET		Z
.LOOP:
	XOR		A
	LD		(HL),A
	INC		HL
	DEC		BC
	LD		A,B
	OR		C
	JR		NZ,.LOOP
	RET
		
		
%MACRO	DEC32	%N,%N
	LD	A,'0'-1
.LOOP:
	INC	A
	LD	BC,#1
	ADD	HL,BC
	EX	DE,HL
	LD	BC,#2
	ADC	HL,BC
	EX	DE,HL
	JR	C,.LOOP
	LD	BC,#1
	SBC	HL,BC
	EX	DE,HL
	LD	BC,#2
	SBC	HL,BC
	EX	DE,HL

	CP	'0'
	JR	NZ,.NONZERO
	EX	AF,AF'
	JR	C,.ZERO
	EX	AF,AF'
	EXX
	INC	DE	; SKIP LEFT ZEROES
	EXX
	JR	.SKIP
.NONZERO:
	EX	AF,AF'
	SCF
.ZERO:
	EX		AF,AF'
	EXX
	LD	(DE),A
	INC	DE
	EXX	
.SKIP:
	
%ENDMACRO

U16_TO_ASCII:
; DE : STR
; HL : NUMBER
	EX		AF,AF'
	OR		A ; RESET CARRY
	EX		AF,AF'	
	CALL	U16
	EX		AF,AF'
	JR		C,.END
	LD		A,'0'
	DEC		DE
	LD		(DE),A
	INC		DE
.END:
	RET
U8_TO_ASCII:
; DE : STR
; L : NUMBER
	EX		AF,AF'
	OR		A ; RESET CARRY
	EX		AF,AF'	
	LD		H,0
	CALL	U8
	EX		AF,AF'
	JR		C,.END
	LD		A,'0'
	DEC		DE
	LD		(DE),A
	INC		DE
.END:
	RET
	
U32_TO_ASCII:
; DE' : STR
; DE:HL : NUMBER
	LD		A,D
	OR		E
	JR		NZ,FULL
	EXX
	PUSH	DE
	EXX
	POP		DE
	INC		DE
	INC		DE
	INC		DE
	INC		DE
	INC		DE
	JP		U16_TO_ASCII
	
FULL:
	EX		AF,AF'
	OR		A ; RESET CARRY
	EX		AF,AF'
	
ONE_BILLION:
	DEC32	$3600,$C465
HUNDRED_MILLIONS:
	DEC32	$1F00,$FA0A
TEN_MILLIONS:
	DEC32	$6980,$FF67
ONE_MILLION:
	DEC32	$BDC0,$FFF0
HUNDRED_THOUSANDS:
	DEC32	$7960,$FFFE
TEN_THOUSANDS:
	DEC32	$D8F0,$FFFF

	EXX
	PUSH	DE
	EXX
	POP		DE
	LD	BC,-1000
	CALL	U8.NUM1
	CALL	U8
	EX		AF,AF'
	JR		C,.END
	LD		A,'0'
	DEC		DE
	LD		(DE),A
	INC		DE
.END:
	RET
	
U16:
	LD	BC,-10000
	CALL	U8.NUM1
	LD	BC,-1000
	CALL	U8.NUM1
U8:
	LD	BC,-100
	CALL	.NUM1
	LD	C,-10
	CALL	.NUM1
	LD	C,B
.NUM1:	
	LD	A,'0'-1
.NUM2:	
	INC	A
	ADD	HL,BC
	JR	C,.NUM2
	SBC	HL,BC

	CP	'0'
	JR	NZ,.NONZERO
	EX	AF,AF'
	JR	C,.ZERO
	EX	AF,AF'
	INC	DE	; SKIP LEFT ZEROES
	JR	.SKIP
.NONZERO:
	EX	AF,AF'
	SCF
.ZERO:
	EX		AF,AF'
	LD	(DE),A
	INC	DE
.SKIP:
	RET
	

STRLESS:
; HL: STRING1
; DE: STRING2
; B = STRING SIZE
; NC = STRING1 IS GREATER THAN STRING2, C STRING1 IS LESSER OR EQUAL THAN STRING2
.LOOP:
	LD		A,(DE)
	CP		(HL)
	JR		C,.ISGREATER
	JR		NZ,.ISSMALLER
	INC		DE
	INC		HL
	DJNZ	.LOOP
.ISSMALLER:
	SCF
	RET
.ISGREATER:
	OR		A
	RET

;
; KANJI-driver check - BiFi'96/'99
;
; Out: Z-flag set when no driver
;
KNJCHK: LD    A,255
        LD    DE,$1100       ; D = ID-code, E = Command
        CALL  $FFCA
        INC   A
        RET
;
; Read KANJI-mode - BiFi'96/'99
;
; Out: A=Current KANJI-mode
;         =0   ANK
;         =1   KANJI0
;         =2   KANJI1
;         =3   KANJI2
;         =4   KANJI3
;
RD_KNJ: LD    DE,$1100
        JP    $FFCA
;
; Set KANJI-mode - BiFi'96/'99
;
; In:  A = KANJI-mode
;
WRTKNJ: LD    DE,$1101
        JP    $FFCA