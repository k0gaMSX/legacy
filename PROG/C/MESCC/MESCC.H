/*	mescc.h

	Mike's Enhanced Small C Compiler for Z80 & CP/M

	Runtime library.

	Copyright (c) 1999-2007 Miguel I. Garcia Lopez

	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2, or (at your option) any
	later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

	Revisions:

	16 Jan 2001 : Last revision.
	23 Mar 2007 : Expand ccladr1 and ccladr2 for more speed.
	16 Apr 2007 : GPL'd.

	NOTES:

	Must be included first!

	Need following EQU's:

	ccSTACKSIZE	Stack size in bytes
	ccDEFARGS	Non zero to define argc and argv
*/

#asm
;	Start at TPA

	ORG	0100H

;	Set stack under BDOS (xx00h)

	LD	HL,(6)
	LD	L,0
	LD	SP,HL

;	Leave space for stack and init. variables

	LD	DE,ccSTACKSIZE
	OR	A
	SBC	HL,DE
	DEC	HL
	LD	(ccfreelast),HL
	LD	DE,ccfreemem
	LD	(ccfreefirst),DE
	OR	A
	SBC	HL,DE
	INC	HL
	LD	(ccfreebytes),HL
	JR	C,ccnostack

	IF	ccDEFARGS

;	Copy command line

	LD	HL,81H
	LD	DE,ccmdbuf
	LD	BC,127
	LDIR

	LD	A,(80H)
	LD	B,0
	LD	C,A
	LD	HL,ccmdbuf
	ADD	HL,BC
	LD	(HL),0

;	Init. argc & argv

	LD	DE,cchptr
	LD	HL,ccmdbuf - 1
	LD	BC,1 
ccspc
	INC	HL
	LD	A,(HL)
	OR	A
	JR	Z,ccarg
	CP	' '
	JR	Z,ccspc
	LD	A,L 
	LD	(DE),A
	LD	A,H
	INC	DE
	LD	(DE),A
	INC	DE
	INC	C
ccpar
	INC	HL
	LD	A,(HL)
	OR	A
	JR	Z,ccarg 
	CP	' ' 
	JR	NZ,ccpar
	LD	(HL),0
	JR	ccspc
ccarg
	LD	HL,cchptr - 2
	PUSH	BC		;argc
	PUSH	HL		;argv

	ENDIF

;	Execute program

	CALL main

;	Exit to CP/M

exit
	JP	0

;	Error, no memory for stack

ccnostack
	LD	C,9
	LD	DE,ccerrstack
	CALL	5
	JP	0

ccerrstack
	DEFB	'Runtime Error - No stack$'

ccfreefirst
	DEFW	0	;Adr. first free byte
ccfreelast
	DEFW	0	;Adr. last free byte
ccfreebytes
	DEFW	0	;Number of free bytes

	IF	ccDEFARGS

ccmdbuf
	DEFS	128	;Command line buffer

	DEFW ccNULL	;Pointers table for argv
cchptr
	DEFW ccNULL,ccNULL,ccNULL,ccNULL,ccNULL
	DEFW ccNULL,ccNULL,ccNULL,ccNULL,ccNULL
	DEFW ccNULL,ccNULL,ccNULL,ccNULL,ccNULL
	DEFW ccNULL,ccNULL,ccNULL,ccNULL,ccNULL
	DEFW ccNULL,ccNULL,ccNULL,ccNULL,ccNULL

ccNULL
	DEFB	0 	;Null pointer

	ENDIF

;	Basic routines

;	Call formats to access locals:
;
;	Format 1:	CALL routine
;			DEFB SpOffset
;
;	Format 2:	CALL routine
;			DEFW SpOffset

;	HL = unsigned char from local (format 2)

ccxgb2
	CALL	ccladr2
	JR	ccxgb3

;	HL = unsigned char from local (format 1)

ccxgb
	CALL	ccladr1
ccxgb3
	LD	L,(HL)
	LD	H,0
	RET

;	HL = signed char from local (format 2)

ccxgc2
	CALL	ccladr2
	JR	ccgc

;	HL = signed char from local (format 1)

ccxgc
	CALL	ccladr1
	
;	HL = signed char from (HL)

ccgc
	LD	A,(HL)

;	HL = signed char from A

ccsxt
;	LD	L,A
;	RLCA
;	SBC	A
;	LD	H,A
;	RET

	LD	H,0
	LD	L,A
	AND	128
	RET	Z
	DEC	H
	RET

;	HL = word from local (format 2)

ccxgw2
	CALL	ccladr2
	JR	ccgw

;	HL = word from local (format 1)

ccxgw
	CALL	ccladr1

;	HL = word from (HL)

ccgw
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	RET

;	char local = HL (format 2)

ccxpb2
	EX	DE,HL
	CALL	ccladr2
	JR	ccxpb3

;	char local = HL (format 1)

ccxpb
	EX	DE,HL
	CALL	ccladr1
ccxpb3
	LD	(HL),E
	EX	DE,HL
	RET

;	int/ptr local = HL (format 2)

ccxpw2
	EX	DE,HL
	CALL	ccladr2
	JR	ccxpw3

;	int/ptr local = HL (format 1)

ccxpw
	EX	DE,HL
	CALL	ccladr1
ccxpw3
	LD	(HL),E
	INC	HL
	LD	(HL),D
	EX	DE,HL
	RET

;	Copy 1 byte from HL to (DE)

;ccpchar
;	LD	A,L
;	LD	(DE),A
;	RET

;	Copy 1 word from HL to (DE)

ccpw
	LD	A,L
	LD	(DE),A
	INC	DE
	LD	A,H
	LD	(DE),A
	RET

;	Calc. local adress

ccladr2
;	OR	A
;	JR	ccladr3
;ccladr1
;	SCF
;ccladr3
	POP	IX
	POP	HL
;	LD	B,0
	LD	C,(HL)
;	JR	C,ccladr4
	INC	HL
	LD	B,(HL)
;ccladr4
	INC	HL
	PUSH	HL
	PUSH	IX
	LD	HL,4
	ADD	HL,BC
	ADD	HL,SP
	RET

;ccladr2
;	OR	A
;	JR	ccladr3
ccladr1
;	SCF
;ccladr3
	POP	IX
	POP	HL
	LD	B,0
	LD	C,(HL)
;	JR	C,ccladr4
;	INC	HL
;	LD	B,(HL)
;ccladr4
	INC	HL
	PUSH	HL
	PUSH	IX
	LD	HL,4
	ADD	HL,BC
	ADD	HL,SP
	RET

;	OR	HL = HL | DE

ccor
	LD	A,L
	OR	E
	LD	L,A
	LD	A,H
	OR	D
	LD	H,A
	RET

;	XOR	HL = HL ^ DE

ccxor
	LD	A,L
	XOR	E
	LD	L,A
	LD	A,H
	XOR	D
	LD	H,A
	RET

;	AND	HL = HL & DE

ccand
	LD	A,L
	AND	E
	LD	L,A
	LD	A,H
	AND	D
	LD	H,A
	RET

;	LOGIC OR	HL = DE || HL

cclgor
	LD	A,H
	OR	L
	OR	D
	OR	E
	LD	L,A
	RET

	;LD	A,H
	;OR	L
	;RET	NZ
	;LD	A,D
	;OR	E
	;RET	Z
	;INC	L
	;RET

;	LOGIC AND	HL = DE && HL

cclgand
	LD	A,H
	OR	L
	RET	Z
	LD	A,D
	OR	E
	RET	NZ
	JP	ccfalse

;	HL = HL == DE

cceq
	OR	A
	SBC	HL,DE

;	LOGIC NOT	HL = !HL

cclgnot
	LD	A,H
	OR	L
	JP	NZ,ccfalse
	INC	L
	RET

;	HL = HL != DE

ccne
	OR	A
	SBC	HL,DE
	RET

;	HL = DE > HL	(SIGNED)

ccgt
	EX	DE,HL

;	HL = DE < HL	(SIGNED)

cclt
	CALL	cccmp
	RET	C
	DEC	L
	RET

;	HL = DE <= HL	(SIGNED)

ccle
	CALL	cccmp
	RET	Z
	RET	C
	DEC	L
	RET

;	HL = DE >= HL	(SIGNED)

ccge
	CALL	cccmp
	RET	NC
	DEC	L
	RET

;	Compare DE with HL, and return: (SIGNED)
;
;	CARRY if DE < HL
;	ZERO if DE == HL
;	HL = 1

cccmp
	LD	A,E
	SUB	L
	LD	E,A
	LD	A,D
	SBC	H
	LD	HL,1
	JP	M,cccmp1
	OR	E
	RET

cccmp1
	OR	E
	SCF
	RET

;	HL = DE <= HL	(UNSIGNED)

ccule
	CALL	ccucmp
	RET	Z
	RET	C
	DEC	L
	RET

;	HL = DE >= HL	(UNSIGNED)

ccuge
	CALL	ccucmp
	RET	NC
	DEC	L
	RET

;	HL = DE > HL	(UNSIGNED)

ccugt
	EX	DE,HL

;	HL = DE < HL	(UNSIGNED)

ccult
	CALL	ccucmp
	RET	C
	DEC	L
	RET

;	Compare DE with HL, and return: (UNSIGNED)
;
;	CARRY if DE < HL
;	ZERO if DE == HL
;	HL = 1

ccucmp
	LD	A,D
	CP	H
	JR	NZ,ccucmp1
	LD	A,E
	CP	L

ccucmp1
	LD	HL,1
	RET

;	HL = DE >> HL	(UNSIGNED)

ccuasr
	LD	B,L
	EX	DE,HL
ccuasr1
	SRL	H
	RR	L
	DJNZ	ccasr1
	RET

;	HL = DE >> HL	(ARITMETIC)

ccasr
	LD	B,L
	EX	DE,HL
ccasr1
	;LD	A,H
	;RLA
	;RR	H
	SRA	H
	RR	L
	DJNZ	ccasr1
	RET

;	HL = DE << HL	(UNSIGNED)
ccuasl

;	HL = DE << HL	(ARITMETIC)

ccasl
	LD	B,L
	EX	DE,HL
ccasl1
	ADD	HL,HL
	DJNZ	ccasl1
	RET

;	HL = DE - HL

ccsub
	EX	DE,HL
	OR	A
	SBC	HL,DE
	RET

;	HL = ~HL	(1 COMPLEMENT)

cccom
	LD	A,H
	CPL
	LD	H,A
	LD	A,L
	CPL
	LD	L,A
	RET

;	HL = -HL	(2 COMPLEMENT)

ccneg
	LD	A,H
	CPL
	LD	H,A
	LD	A,L
	CPL
	LD	L,A
	INC	HL
	RET

;	HL = DE * HL	(UNSIGNED)

ccumul

;	HL = DE * HL	(SIGNED)

ccmul
	LD	A,H
	LD	C,L
	LD	HL,0
	LD	B,16
ccmul0
	SLA	C
	RL	A
	JR	NC,ccmul1
	ADD	HL,HL
	ADD	HL,DE
	DJNZ	ccmul0
	RET
ccmul1
	ADD	HL,HL
	DJNZ	ccmul0
	RET

;	HL = DE % HL	(SIGNED)

ccmod
	CALL	ccdiv
	EX	DE,HL
	RET

;	HL = DE / HL	(SIGNED)
;	DE = DE % HL	(SIGNED)

ccdiv
	LD	B,H
	LD	C,L
	LD	A,D
	XOR	B
	PUSH	AF
	LD	A,D
	OR	A
	CALL	M,ccdivdeneg
	LD	A,B
	OR	A

	JP	P,ccdiv0

	LD	A,B
	CPL
	LD	B,A
	LD	A,C
	CPL
	LD	C,A
	INC	BC

ccdiv0
	EX	DE,HL
	LD	DE,0
	LD	A,16

ccdiv1
	PUSH	AF

	ADD	HL,HL

	RL	E
	RL	D
	LD	A,D
	OR	E

	JR	Z,ccdiv2

	LD	A,E
	SUB	C
	LD	A,D
	SBC	B

	JP	M,ccdiv2
	LD	A,L
	OR	1
	LD	L,A
	LD	A,E
	SUB	C
	LD	E,A
	LD	A,D
	SBC	B
	LD	D,A

ccdiv2
	POP	AF
	DEC	A
	JR	NZ,ccdiv1
	POP	AF
	RET	P

	CALL	ccneg

ccdivdeneg
	LD	A,D
	CPL
	LD	D,A
	LD	A,E
	CPL
	LD	E,A
	INC	DE
	RET

;	HL = DE % HL	(UNSIGNED)

ccumod
	CALL	ccudiv
	EX	DE,HL
	RET

;	HL = DE / HL	(UNSIGNED)
;	DE = DE % HL	(UNSIGNED)

ccudiv:

;DIVE:	;(EXTERNAL ENTRY FROM MAIN PROGRAM)
;	EX	DE,HL ;SWAP D,E WITH H,L FOR DIVIDE FUNCTION

;	COMPUTE X/Y WHERE X IS IN D,E AND Y IS IN H,L
;	THE VALUE OF X/Y APPEARS IN D,E AND X MOD Y IS IN H,L
;
	LD	(ccudiv_tmp),HL	;SAVE X IN TEMPORARY
	LD	HL,ccudiv_cnt	;STORE BIT COUNT
	LD	(HL),17
	LD	BC,0	;INTIALIZE RESULT
	PUSH	BC
	XOR	A
ccudiv0
;	LD	A,E	;GET LOW Y BYTE
;	RLA
;	LD	E,A
;	LD	A,D
;	RLA
;	LD	D,A

	RL	E
	RL	D
	DEC	(HL)	;DECREMENT BIT COUNT
	POP	HL	;RESTORE TEMP RESULT
	JR	Z,ccudiv2		;ZERO BIT COUNT MEANS ALL DONE
	LD	A,0	;ADD IN CARRY
	ADC	0	;CARRY
	ADD	HL,HL	;SHIFT TEMP RESULT LEFT ONE BIT
	LD	B,H	;COPY HA AND L TO A A ND C
	ADD	L
	LD	HL,(ccudiv_tmp)	;GET ADDRESS OF X
	SUB	L	;SUBTRACT FROM TEMPORARY RESULT
	LD	C,A
	LD	A,B
	SBC	H
	LD	B,A
	PUSH	BC	;SAVE TEMP RESULT IN STACK
	JR	NC,ccudiv1	;NO BORROW FROM SUBTRACT
	ADD	HL,BC	;ADD X BACK IN
	EX	(SP),HL	;REPLACE TEMP RESULT ON STACK
ccudiv1
	LD	HL,ccudiv_cnt	;RESTORE H,L
	CCF
	JR	ccudiv0	;REPEAT LOOP STEPS

ccudiv2
	EX	DE,HL
	RET
;
ccudiv_tmp
	DEFW	0
ccudiv_cnt
	DEFB	0


;	Switch, on entry:
;
;	DE = Table adress
;	HL = Where go if value there's not in table
;	B  = Number of entries in table

ccswtch
	EX	(SP),HL
	EX	DE,HL

ccswch1
	LD	A,E
	CP	(HL)
	INC	HL
	JR	NZ,ccswch2
	LD	A,D
	CP	(HL)
	JR	NZ,ccswch2
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	POP	BC
	JP	(HL)

ccswch2
	INC	HL
	INC	HL
	INC	HL
	DJNZ	ccswch1
	EX	(SP),HL
	POP	BC
	JP	(HL)

;	HL = TRUE

cctrue
	LD	L,1
	RET

;	HL = FALSE

ccfalse
	LD	HL,0
	RET

;ccbdos	JP	5	;Call BDOS
;
;ccbios	LD	HL,(1)	;Call BIOS
;	PUSH	DE	;Entry: A=function*3
;	LD	D,0
;	LD	E,A
;	ADD	HL,DE
;	POP	DE
;	JP	(HL)

#endasm
