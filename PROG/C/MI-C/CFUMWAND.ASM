;MI - C  v-3.18   (C) COPYRIGHT  G. KERSTING / H. ROSE, 1983
;
; RUNTIME LIBRARY   MI - C   V  3.1   UMWANDLUNGEN
;
; ENTRY CUTOD,CUSTOD,CCTOD,CCSTOD
; ENTRY CFTOI,CFSTOI,CFTOL,CFSTOL
; ENTRY CLTOD,CLSTOD
; EXT CFPRIM,CLPRIM,CLSEC,CLREST
; EXT CFSHL,CFNEG,CFSWAP,CLNEG,CCNEG
; EXT CLSFLAG,CLDIV,CUDIV
;
VORZEI EQU 6
EXPONENT EQU 7
;
;	DSEG
CFWSTZ:   DS 1
CFWMINUS: DS 1
CFWDIVIS: DS 4
CFWERGEB: DS 2
CFWBYZAE: DS 1
CFWBYT:   DS 1
CFWUEBTR: DS 1
;	CSEG
;
CFSTOI:
	CALL	CFSWAP
	CALL	CFTOI
	JMP	CFSWAP
CFTOI:
	LXI	H,CFPRIM+EXPONENT		
	MOV	A,M
	SUI	81H			
	JNC	CWFI0			
	LXI	H,0			
	RET				
CWFI0:
	MVI	A,85H			
	SUB	M			
	JNC	CWFI2			
CWFIZGRO:
	LDA	CFPRIM+VORZEI		
	ANA	A			
	JZ	CWFI1			
	LXI	H,8000H			
	RET
CWFI1:
	LXI	H,7FFFH
	RET
CWFI2:
	PUSH	PSW		
	DCX	H		
	MOV	A,M
	ANI	0F0H		
	STA	CFWMINUS	
	JZ	CWFI3
	CALL	CFNEG
CWFI3:
	POP	B		
	MVI	C,3		
	LXI	H,CFPRIM+VORZEI-2
	CALL	CFSHR		
	MVI	B,16			
	MVI	A,3			
	STA	CFWBYZAE		
	PUSH	D			
	CALL	CFDD2
	POP	D
	LXI	H,CFPRIM+VORZEI		
	MOV	A,M			
	DCX	H			
	ORA	M			
	DCX	H
	ORA	M
	JNZ	CWFIZGRO
	LHLD	CFWERGEB
	LDA	CFWMINUS
	ANA	A
	RZ
	JMP	CCNEG
CFTOL:
	LXI	H,CFPRIM+EXPONENT
	MOV	A,M
	SUI	81H
	JNC	CWDL0
	LXI	H,0			
	SHLD	CLPRIM
	RET
CWDL0:
	MVI	A,8AH			
	SUB	M
	JNC	CWDL2			
CWDLZGRO:
	LDA	CFPRIM+VORZEI		
	ANI	0F0H			
	JZ	CWDL1
	LXI	H,8000H			
	SHLD	CLPRIM			
	LXI	H,0			
	RET
CWDL1:
	LXI	H,7FFFH			
	SHLD	CLPRIM			
	LXI	H,0FFFFH		
	RET
CWDL2:
	PUSH	D	
	PUSH	PSW	
	DCX	H			
	MOV	A,M
	ANI	0F0H
	JZ	CWDL3
	CALL	CFNEG
	LXI	H,CFPRIM+VORZEI
	MVI	A,1			
CWDL3:
	STA	CFWMINUS		
	MVI	B,1
	MVI	C,6
	LXI	H,CFPRIM+VORZEI
	CALL	CFSHL
	POP	B			
	MVI	C,5			
	LXI	H,CFPRIM+VORZEI-4
	CALL	CFSHR
	XRA	A			
	STA	CFWUEBTR
	MVI	B,16			
	MVI	A,5
	STA	CFWBYZAE
	CALL	CFDD2
	SHLD	CLPRIM		
	LDA	CFWMINUS	
	ANA	A
	JZ	CWDL4
	MOV	A,H		
	ORA	L
	JNZ	CWDL4
	MVI	A,1		
	STA	CFWUEBTR
CWDL4:
	MVI	B,16
	MVI	A,5
	STA	CFWBYZAE
	CALL	CFDD2
	LDA	CFWUEBTR
	ANA	A
	JZ	CWDL5
	INX	H
CWDL5:
	XCHG
	LHLD	CLPRIM
	XCHG
	SHLD	CLPRIM		
	MOV	A,H		
	RAL			
	JC	CWDLZ0
	LXI	H,CFPRIM+VORZEI	
	MOV	A,M		
	DCX	H		
	ORA	M
	DCX	H
	ORA	M
	DCX	H
	ORA	M
	DCX	H
	ORA	M
	JNZ	CWDLZ0
	XCHG
	POP	D
	LDA	CFWMINUS	
	ANA	A
	RZ
	JMP	CLNEG
CWDLZ0:
	POP	D
	JMP	CWDLZGRO
CFSTOL:
	CALL	CFSWAP
	CALL	CFTOL
	JMP	CFSWAP
CFDD2:
	LXI	H,CFPRIM+VORZEI
	LDA	CFWBYZAE	
	MOV	C,A
CFDD20:
	MOV	A,M		
	ANA	A		
	JNZ	CFDD22		
	DCX	H		
	DCR	C		
	JNZ	CFDD20
	LHLD	CFWERGEB	
CFDD21:				
	MOV	A,H		
	ANA	A
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	DCR	B
	JNZ	CFDD21
	SHLD	CFWERGEB
	RET			
CFDD22:
	MVI	D,0		
	LDA	CFWBYZAE	
	MOV	C,A
	LXI	H,CFPRIM+VORZEI
CFDD23:
	MOV	A,M		
	ANI	1		
	MOV	E,A
	MOV	A,M		
	ANA	A
	RAR
	MOV	M,A
	MOV	A,D		
	SUI	1
	JNZ	CFWRE1
	MOV	A,M		
	ADI	50H		
	MOV	M,A
CFWRE1:
	MOV	A,M		
	ANI	8H
	JZ	CFWRE2
	MOV	A,M		
	ANI	0F7H		
	ADI	5H
	MOV	M,A
CFWRE2:
	MOV	D,E		
	DCX	H
	DCR	C
	JNZ	CFDD23
CFDD24:
	LHLD	CFWERGEB		
	MOV	A,H
	ANA	A
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	MOV	A,D		
	SUI	1
	JNZ	CFDD25
	MOV	A,H		
	ADI	80H
	MOV	H,A

CFDD25:
	SHLD	CFWERGEB
	DCR	B		
	JNZ	CFDD2
	RET
CCTOD:
	CALL	CWDNUL		
	MOV	A,L		
	ORA	H
	RZ			
CWID0:
	MOV	A,H
	ANI	80H		
	PUSH	PSW
	JZ	CWID1		
	CALL	CCNEG		
CWID1:				
	CALL	CWUD		
	POP	PSW
	RZ
	JMP	CFNEG
CCSTOD:
 	CALL	CFSWAP
	CALL	CCTOD
	JMP	CFSWAP
CUTOD:
	CALL	CWDNUL		
	MOV	A,L		
	ORA	H
	RZ
CWUND0:
	JMP	CWUD
CUSTOD:
	CALL	CFSWAP
	CALL	CUTOD
	JMP	CFSWAP
CWDNUL:
	PUSH	H
	LXI	H,CFPRIM+EXPONENT
	MVI	B,8
	XRA	A
CWDNU0:
	MOV	M,A
	DCX	H
	DCR	B
	JNZ	CWDNU0
	POP	H
	RET
CWUD:
	PUSH	B		
	PUSH	D		
	XRA	A		
	STA	CFWSTZ
	STA	CFWBYT		
	XCHG			
	LXI	H,CFPRIM+VORZEI
	PUSH	H
	LXI	H,10000
	PUSH	H
CWUD0:
	POP	H
	PUSH	H
	CALL	CUDIV		
	XTHL			
	PUSH	D
	XCHG
	LXI	H,10		
	CALL	CUDIV
	POP	D
	XTHL			
	MOV	A,L		
	ANA	A		
	JNZ	CWUD1
	LDA	CFWSTZ		
	ANA	A
	JZ	CWUD0
CWUD1:
	LDA	CFWSTZ
	INR	A
	STA	CFWSTZ		
	RAR			
	JC	CWUD2		
	MOV	A,L
	RAL
	RAL
	RAL
	RAL
	ANI	0F0H
	STA	CFWBYT
	JMP	CWUD3
CWUD2:
	LDA	CFWBYT
	ADD	L		
	POP	H		
	XTHL			
	MOV	M,A		
	DCX	H
	XTHL			
	PUSH	H
CWUD3:
	POP	H		
	PUSH	H
	MOV	A,L
	ORA	H
	JNZ	CWUD0
	POP	H		
	POP	H		
	LDA	CFWSTZ
	RAR			
	JC	CWUD4
	LDA	CFWBYT
	MOV	M,A
CWUD4:				
	LDA	CFWSTZ
	ADI	80H
	STA	CFPRIM+EXPONENT
	POP	D
	POP	B
	RET
CLTOD:
	CALL	CWDNUL		
	PUSH	H
	CALL	CLSFLAG		
	POP	H
	RZ
	PUSH	D		
	XCHG
	LHLD	CLSEC
	PUSH	H
	LXI	H,CFPRIM+VORZEI 
	PUSH	H
	XCHG
	LDA	CLPRIM+1		
	ANI	80H
	STA	CFWMINUS
	JZ	CWLD0
	CALL	CLNEG
CWLD0:
	XRA	A		
	STA	CFWSTZ
	STA	CFWBYT		
	XCHG			
	LHLD	CLPRIM
	SHLD	CLSEC
	LXI	H,3B9AH		
	SHLD	CFWDIVIS+2
	SHLD	CLPRIM
	LXI	H,0CA00H	
	SHLD	CFWDIVIS
CWLD1:
	LHLD	CFWDIVIS	
	PUSH	H
	CALL	CLSFLAG		
	POP	H
	JZ	CWLD4
	CALL	CLDIV	
	PUSH	H		
	LHLD	CLREST
	PUSH	H
	LHLD	CLREST+2
	PUSH	H
	LHLD	CFWDIVIS+2	
	SHLD	CLSEC		
	LHLD	CFWDIVIS
	XCHG
	LXI	H,10		
	CALL	CLDIV
	SHLD	CFWDIVIS	
	LHLD	CLPRIM
	SHLD	CFWDIVIS+2
	POP	H		
	SHLD	CLSEC
	POP	H
	XCHG
	POP	H		
	MOV	A,L		
	ANA	A
	JNZ	CWLD2
	LDA	CFWSTZ		
	ANA	A
	JZ	CWLD1		
CWLD2:
	LDA	CFWSTZ
	INR	A
	STA	CFWSTZ		
	RAR			
	JC	CWLD3		
	MOV	A,L
	RAL
	RAL
	RAL
	RAL
	ANI	0F0H
	STA	CFWBYT
	JMP	CWLD1
CWLD3:
	LDA	CFWBYT
	ADD	L		
	POP	H		
	MOV	M,A		
	DCX	H
	PUSH	H
	JMP	CWLD1
CWLD4:
	LDA	CFWSTZ		
	RAR			
	POP	H
	JC	CWLD6
	LDA	CFWBYT		
	MOV	M,A		
CWLD6:
	LDA	CFWSTZ
	ADI	80H		
	STA	CFPRIM+EXPONENT
	LDA	CFWMINUS	
	ANA	A
	JZ	CWLD7
	CALL	CFNEG
CWLD7:
	POP	H		
	SHLD	CLSEC
	POP	D
	RET

CLSTOD:
	CALL	CFSWAP
	CALL	CLTOD
	JMP	CFSWAP
CFSHR:
	MOV	A,B
	ANA	A
	RZ			
	PUSH	H
	MOV	E,C		
CFSR1:
	MOV	C,E		
	MVI	D,0		
	POP	H
	PUSH	H

CFSR2:
	MOV	A,M
	RAR
	RAR
	RAR
	RAR			
	ANI	0FH		
	MOV	D,A
	DCR	C		
	JZ	CFSR3		
	INX	H
	MOV	A,M
	RAL
	RAL
	RAL
	RAL			
	ANI	0F0H		
	ADD	D		
	DCX	H		
	MOV	M,A
	INX	H
	JMP	CFSR2
CFSR3:
	MOV	M,A		
	DCR	B
	JNZ	CFSR1
	POP	H
	RET
