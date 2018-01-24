;
;  * * * * * * * * *
;  * CAS2TAPE.COM  *
;  *     v1.1      *
;  *   by Martos   *
;  * * * * * * * * *
;
; This utility records a CAS file on tape, or whatever device connected to the
; standard cassete output.
;
; Improvements in revision 1.1:
; - Simplified the scheme of supported speeds
; - Non-standard ones (1800, 3600) use lower/safer base speed + 1 stop bit only

CALSLT	EQU	001CH
DISSCR	EQU	0041H
CHGMOD	EQU	005FH
VOICCQ	EQU	0FA75H
OLDSCR	EQU	0FCB0H
EXPTBL	EQU	0FCC1H
H.TIMI	EQU	0FD9FH

BDOS	EQU	0005H
FCB	EQU	005CH
FCB2	EQU	006CH
DMA	EQU	0080H

VRMFLG	EQU	DMA+1
LOW	EQU	DMA+2
HIGH	EQU	DMA+4
HEADER	EQU	DMA+6

; To maximize the available memory for data buffer, the start-up sequence has
; been moved there, allowing it to be overwritten later and therefore adding to
; its size.

	CALL	DATA
	CALL	MAIN
	LD	C,10H		; Close file
FILACC:	LD	DE,FCB
	CALL	BDOS
	OR	A
	RET

; MAIN continuously reads data blocks from CAS file and records them to tape.

MAIN:	CALL	FILBUF
	PUSH	HL
	LD	B,8
	LD	HL,LEADIN
	CALL	STRCMP
	POP	HL
	RET	NZ		; No lead in
	SBC	HL,DE
	ADD	HL,DE
	RET	C		; Data window exceeded
	CALL	FILBUF
	CALL	GETEND
	LD	(VRMFLG),A
	JR	Z,RECBLK	; Data block fully loaded in memory
	LD	IX,DISSCR
	CALL	BIOS		; Blank screen to hide the use of VRAM
	LD	DE,DATA
	LD	BC,4000H
	LD	A,C
	OUT	(99H),A
	LD	A,B
	OUT	(99H),A
SAVVRM:	LD	A,(DE)		; Dump to VRAM the first 16 KB of the block
	OUT	(98H),A
	INC	DE
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,SAVVRM
	CALL	FILBUF		; Get 16 KB more from file
	CALL	GETEND
	JR	NZ,SCRON	; Data block too large, set text mode and exit
RECBLK:	PUSH	HL
	PUSH	DE
	LD	B,0
HKCALL:	PUSH	BC
	CALL	H.TIMI		; BDOS counts down for stopping disk spin
	POP	BC
	DJNZ	HKCALL
	POP	DE
	CALL	TAPEON
	JR	Z,EXIREC
	LD	A,(VRMFLG)
	OR	A
	LD	A,-14		; Timing adjustment header-1st byte on ram
	JR	Z,RECMEM
	LD	HL,4000H
	LD	A,L
	OUT	(99H),A
	OUT	(99H),A
	LD	A,-14		; Timing adjustment header-1st byte on vram
RECVRM:	LD	C,98H
	IN	C,(C)
	CALL	TAPEWR
	JR	Z,EXIREC
	DEC	HL
	LD	A,H
	OR	L
	LD	A,-10		; Timing adjustment between data bytes
	JR	NZ,RECVRM
	LD	A,-13		; Timing adjustment vram data-ram data
RECMEM:	LD	HL,DATA
RECBYT:	SBC	HL,DE
	ADD	HL,DE
	JR	Z,ENDREC
	LD	C,(HL)
	INC	HL
	CALL	TAPEWR
	LD	A,-10		; Timing adjustment between data bytes
	JR	NZ,RECBYT
EXIREC:	POP	HL
CHKSCR:	LD	A,(VRMFLG)
	OR	A
	RET	Z
SCRON:	LD	A,(OLDSCR)	; Clear and activate screen
	LD	IX,CHGMOD
BIOS:	LD	IY,(EXPTBL-1)
	JP	CALSLT
ENDREC:	CALL	TAPEOF
	PUSH	DE
	CALL	CHKSCR
	POP	DE
	POP	HL
	JP	MAIN


; FILBUF moves the data window (between DE and HL-1) to the start of the
; buffer, then appends to it as much new data from the CAS file as possible. DE
; and HL will be updated to point the new start and end of the data window.

FILBUF:	OR	A
	SBC	HL,DE		; Length of the unprocessed data
	LD	B,H
	LD	C,L
	EX	DE,HL
	LD	DE,DATA
	PUSH	DE
	JR	Z,SETDMA
	LDIR			; Move unprocessed data to the buffer's start
SETDMA:	SBC	HL,DE		; Length of the freed space
	PUSH	DE
	PUSH	HL
	LD	C,1AH
	CALL	BDOS		; Set the DMA to the start of the free space
	POP	HL
	LD	C,27H
	CALL	FILACC
	POP	DE
	ADD	HL,DE		; New end of the data
	POP	DE
	RET

; GETEND explores the data window (from DE to HL-1) advancing DE until the end
; of current block is reached. NZ means it wasn't found within the window.

GETEND:	PUSH	HL
	SBC	HL,DE		; Length of data window
	LD	BC,6
	SBC	HL,BC		; Posible locations of next lead-in, plus one
	LD	B,H
	LD	C,L
	EX	DE,HL
SEEKLD:	LD	DE,LEADIN
	LD	A,(DE)
	INC	DE
	CPIR
	JP	PO,TSTEOF	; No lead-in found in window, check end of file
	PUSH	HL
	PUSH	BC
	LD	B,7
	CALL	STRCMP
	POP	BC
	POP	HL
	JR	NZ,SEEKLD	; Not a lead-in, continue
	DEC	HL
	EX	DE,HL
	POP	HL
	RET
TSTEOF:	POP	HL
	LD	D,H
	LD	E,L
	LD	B,4
	LD	IX,FCB
EOFCMP:	LD	A,(IX+33)
	SUB	(IX+16)
	RET	NZ		; No EOF, data block larger than the window
	INC	IX
	DJNZ	EOFCMP
	RET

STRCMP:	LD	A,(DE)
	SUB	(HL)
	RET	NZ
	INC	HL
	INC	DE
	DJNZ	STRCMP
	RET

LEADIN:	DB	1FH,0A6H,0DEH,0BAH,0CCH,13H,7DH,74H

; TAPEON and TAPEWR perform the standard writing operations on tape. If STOP
; key is pressed, both will stop the tape and return Z flag set.

TAPEON:	IN	A,(0AAH)
	AND	0E0H
	OR	7
	OUT	(0AAH),A	; Motor on, keyboard row 7 selected
	LD	BC,0
WAITON:	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,WAITON
	LD	A,(HEADER)
	LD	B,A
WRHEAD:	PUSH	BC
	NOP			; Equalize timings
	NOP			;
	CALL	WRHIGH
	POP	BC
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,WRHEAD
	JR	CHKSTP

TAPEWR:	LD	B,11
	CP	A		; NC (forces start bit), Z
BITWIN:	PUSH	BC
	CALL	NC,WRLOW
	CALL	C,WRHIGH
	POP	BC
	SCF
	RR	C		; Always NZ, no timing compensation
	DJNZ	BITWIN
CHKSTP:	IN	A,(0A9H)
	AND	10H		; STOP key
	RET	NZ
TAPEOF:	LD	A,9
	OUT	(0ABH),A
	RET

WRHIGH:	LD	BC,(HIGH)
	CALL	WRBIT
	LD	B,6		; Equalize timings
SYNCHI:	DJNZ	SYNCHI		;
	NOP			;
	LD	BC,(HIGH)
	CALL	WRBIT
	RET
WRLOW:	LD	BC,(LOW)
	RET	C		; Equalize timings
	RET	C		;
	JR	NZ,WRBIT
	ADD	A,B		; Timing compensation for start bit
	LD	B,A
	OR	A		; Preserve NC
WRBIT:	DJNZ	WRBIT
	LD	A,0BH
	OUT	(0ABH),A
	LD	B,C
WRBIT1:	DJNZ	WRBIT1
	LD	A,0AH
	OUT	(0ABH),A
	RET

; Start-up sequence, put here for allowing its space to be used later for data.

DATA:	LD	A,(FCB+1)
	CP	' '
	JR	Z,EXIT		; Invalid arguments => show instructions
	LD	HL,FCB+9
	LD	A,(HL)
	CP	' '
	JR	NZ,GETSPD
	LD	(HL),'C'	; No extension, set it to .CAS
	INC	HL
	LD	(HL),'A'
	INC	HL
	LD	(HL),'S'
GETSPD:	LD	DE,FCB2+9
	LD	B,3
	CALL	GETNUM
	JR	C,EXIT		; Invalid non-numeric parameter
	LD	DE,FCB2+1
	LD	B,8
	CALL	GETNUM
	JR	C,EXIT		; Invalid non-numeric parameter
	EX	DE,HL
	LD	IX,PARTAB
	LD	BC,8
CHKSPD:	LD	H,(IX+7)
	LD	L,(IX+6)
	SBC	HL,DE
	JR	NC,SETPAR
	ADD	IX,BC
	JR	CHKSPD
SETPAR:	LD	A,(IX+5)
	LD	(TAPEWR+1),A	; Total bits per byte (start + data + stop)
	PUSH	IX
	POP	HL
	LD	DE,LOW
	LD	C,5
	LDIR
FILOPN:	LD	C,0FH
	CALL	FILACC
	LD	DE,S_OPEN
	JR	NZ,EXIT2
	LD	HL,1
	LD	(FCB+14),HL	; Register length = 1
	LD	L,H
	LD	(FCB+33),HL
	LD	(FCB+35),HL	; Register pointer = 0
	POP	DE
	POP	BC
	LD	SP,VOICCQ+128	; Stack in Basic's PLAY statement queues
	PUSH	BC
	PUSH	DE
	LD	HL,(BDOS+1)	; End of TPA
	LD	D,H
	LD	E,L		; Initialize processing pointer
	RET
EXIT:	LD	DE,S_INST
EXIT2:	POP	AF
	LD	C,9
	JP	BDOS

GETNUM:	LD	HL,0
GETDGT:	LD	A,(DE)
	CP	' '
	RET	Z
	SUB	'0'
	RET	C		; Non-numeric character
	CP	10
	CCF
	RET	C		; Non-numeric character
	PUSH	DE
	LD	D,H
	LD	E,L
	ADD	HL,HL
	JR	C,TOOBIG
	ADD	HL,HL
	JR	C,TOOBIG
	ADD	HL,DE
	JR	C,TOOBIG
	ADD	HL,HL
	JR	C,TOOBIG
	LD	D,0
	LD	E,A
	ADD	HL,DE
	JR	NC,NXTDGT
TOOBIG:	LD	HL,65535
NXTDGT:	POP	DE		; HL = 10 * HL + A, unsigned and clipped
	INC	DE
	DJNZ	GETDGT
	RET

; Values for LOW, HIGH and HEADER that set each supported recording speed.

PARTAB:	DB	105,96,52,42, 8,11	; 1198
	DW	1499
	DB	 76,67,37,28,11,10	; 1645 * 1.1 = 1810
	DW	2099
	DB	 52,43,25,16,15,11	; 2380
	DW	2999
	DB	 37,28,18, 8,21,10	; 3302 * 1.1 = 3632
	DW	65535

S_INST:	DB	10
	DB	'  CAS2TAPE <input file> [speed]',13,10
	DB	10
	DB	'Supported speeds are 1200 (default),',13,10
	DB	'1800, 2400 and 3600. Pressing STOP',13,10
	DB	'aborts the recording.',13,10,'$'
S_OPEN:	DB	"Can't open input file",'$'

	END

