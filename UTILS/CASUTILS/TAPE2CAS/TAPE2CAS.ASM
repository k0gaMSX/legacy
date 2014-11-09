;
;  * * * * * * * * *
;  * TAPE2CAS.COM  *
;  *     v1.72     *
;  *   by Martos   *
;  * * * * * * * * *
;
; This utility reads an MSX tape and generates a CAS file out of it.
;
; Improvements in revision 1.1:
;  - Added support for Spectrum-format turbo blocks
;  - Alignment gaps are filled with zeros instead of random bytes
;
; Improvements in revision 1.2:
;  - Gap autodetection and more reliable reading for standard data
;  - Runtime key interface less tricky
;  - Disk doesn't spin all the time
;  - Disallowed to stop & save amid data
;  - Clean results with attached turbo blocks, when stopping at inner lead in
;  - Turbo loader detection less strict
;  - Parity of turbo blocks remains correct when patched
;
; Improvements in revisions 1.3x:
;  - Better patching of turbo loaders, standard loader enhanced
;
; Improvements in revision 1.4:
;  - Tape files parsed more strictly
;  - Reliability of standard data further checked, added recovery capabilities
;  - Joined in a single option all functionalities for error tolerance
;
; Improvements in revisions 1.5x:
;  - Adaptive patching for several common variants of turbo loader
;  - Added support for Opera leadless blocks
;  - Turbo loader detection more reliable
;  - Restored a separate option for raw reading
;  - Options for error tolerance now apply to turbo blocks too
;  - Disallowed 0-length blocks
;
; Improvements in revisions 1.6x:
;  - Certain Basic files formerly rejected are now taken as good
;  - Standard loader more compact for better patching
;  - Autodetection of attached turbo blocks
;
; Improvements in revisions 1.7x:
;  - Added support for very long turbo blocks (up to twice the buffer's size)
;  - Detects and patches Namco / Bug Byte loaders

CALSLT	EQU	001CH
BREAKX	EQU	00B7H
TAPION	EQU	00E1H
TAPIOF	EQU	00E7H
VOICCQ	EQU	0FA75H
LOWLIM	EQU	0FCA4H
EXPTBL	EQU	0FCC1H
H.TIMI	EQU	0FD9FH

BDOS	EQU	0005H
FCB	EQU	005CH
DMA	EQU	0080H

FLAGS	EQU	DMA+1
BAKPOS	EQU	DMA+2

; To maximize the available memory for data buffer, the start-up sequence has
; been moved there, allowing it to be overwritten later and therefore adding to
; its size.

	CALL	DATA
	CALL	MAIN
	PUSH	AF
	LD	HL,(BAKPOS)
	LD	(FCB+33),HL	; Back to the last secure position
	LD	A,L
	OR	H
	LD	HL,(BAKPOS+2)
	LD	(FCB+35),HL
	OR	L
	OR	H		; Is that position = 0?
	PUSH	AF
	LD	HL,0		; Cut off unsecure data
	CALL	FILEWR
	LD	C,10H
	CALL	FILACC		; Close file
	POP	AF
	LD	C,13H
	CALL	Z,FILACC	; Delete file if length = 0
	POP	AF
	OR	A
	RET	Z
	LD	HL,STRTAB-2
	ADD	A,A
	ADD	A,L
	LD	L,A
	JR	NC,GETSTR
	INC	H
GETSTR:	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
STRING:	LD	A,(HL)		; Console output has to be done through BDOS
	OR	A		; function 06H. Any other function will abort
	RET	Z		; the program when CTRL+STOP is pressed.
	CALL	WRCHAR
	INC	HL
	JR	STRING

STRTAB:	DW	S_DISK,S_MEM,S_DATA
S_DISK:	DB	'Insufficient disk space',0
S_MEM:	DB	'Data block too long',0
S_DATA:	DB	'Data not reliable',0

; MAIN continuously reads data blocks from tape and adds them to output file.
; It can recognize standard tape files (unless raw mode is activated) and
; check their consistence, and also turbo or leadless blocks. Output values in
; A are the following:
; 0: ended normally (CTRL+STOP when seeking a data block)
; 1: file write error
; 2: data buffer overflowed
; 3: data not reliable

MAIN:	LD	HL,FLAGS
	BIT	1,(HL)		; Flag for turbo mode
	JP	NZ,TMAIN
	BIT	5,(HL)		; Flag for leadless loader
	JR	Z,LDSRCH
	RES	5,(HL)		; Flag for leadless loader
	SET	6,(HL)		; Flag for leadless mode
	CALL	TAPSET
LLHEAD:	LD	B,200
HEDCNT:	CALL	CHKKEY
	JP	Z,TAPEOF	; CTRL+STOP
	PUSH	BC
	CALL	LTAPIN
	POP	BC
	JR	C,LLHEAD
	DJNZ	HEDCNT
	LD	HL,S_RAW
	CALL	STRING
	CALL	TAPINI
	LD	HL,DATA
	LD	DE,DATA+1
	LD	C,255
	LD	(HL),C
	LDIR
HEDEND:	CALL	TAPEIN
	JR	C,DISCAR
	OR	A
	JR	Z,RD1ST
	DEC	DE
	JR	HEDEND
LDSRCH:	CALL	TAPEON
	LD	A,0
	RET	C
	LD	HL,S_RAW
	CALL	STRING
	CALL	TAPINI
RD1ST:	CALL	TAPEIN
	JR	C,DISCAR
RDRAW:	CALL	TAPEIN
	JR	C,RAWEND
	JR	NZ,RDRAW
DISCAR:	PUSH	AF
	LD	HL,S_DISC
	CALL	STRING
	POP	AF
	RET
RAWEND:	JR	Z,DISCAR	; Fatal BIOS-like error (usually CTRL+STOP)
	LD	A,(FLAGS)
	BIT	6,A		; Flag for leadless mode
	JR	NZ,SAVBLK
	AND	11H		; Flags for raw or blind modes
	JR	NZ,PATRAW
	LD	HL,DATA+16
	SBC	HL,DE
	JR	NZ,PATRAW
	LD	HL,DATA
	LD	A,(HL)
	LD	B,9
HEADID:	INC	HL
	CP	(HL)
	JR	NZ,PATRAW
	DJNZ	HEADID
	CP	0EAH
	JR	Z,ASCII
	CP	0D3H
	JP	Z,BASIC
	CP	0D0H
	JP	Z,BINARY
PATRAW:	PUSH	DE
	LD	HL,DATA
	CALL	TPATCH
	POP	DE
	CALL	LLNDET
SAVBLK:	PUSH	DE
	CALL	ADDBLK
	POP	DE
	JR	NZ,DISCAR
	LD	A,(FLAGS)
	AND	13H		; Flags for raw, turbo and blind modes
	CP	2
	LD	HL,S_BOK
	CALL	Z,STRING
	LD	HL,-DATA	-200H ; M80/L80 BUG WORKAROUND
	ADD	HL,DE		; Block length, to be displayed
	CALL	NUMBER
	LD	HL,S_BYTE
STROUT:	CALL	STRING
	LD	HL,FLAGS
	BIT	3,(HL)		; Flag indicating a turbo loader was found
	JR	Z,CHKLLN
	RES	3,(HL)
	BIT	2,(HL)		; Flag for leaving loaders unpatched
	PUSH	HL
	LD	HL,S_TPAT
	CALL	Z,STRING
	POP	HL
	BIT	1,(HL)		; Flag for turbo mode
	SET	1,(HL)
	LD	HL,S_TMOD
	CALL	Z,STRING
	JR	ADVPOS
CHKLLN:	BIT	5,(HL)		; Flag for leadless loader
	PUSH	HL
	LD	HL,S_LMOD
	CALL	NZ,STRING
	POP	HL
	BIT	7,(HL)		; Flag for patched Namco loader
	RES	7,(HL)
	LD	HL,S_NPAT
	CALL	NZ,STRING
ADVPOS:	LD	HL,FCB+33	; Current file position is secure
	LD	DE,BAKPOS
	LD	BC,4
	LDIR
	JP	MAIN
DISCA2:	CALL	TAPERR		; A = 3 and tape off, flags unaffected
DISCA3:	JP	DISCAR

ASCII:	LD	HL,S_ASC
	CALL	TAPHED
	JR	NZ,DISCA3
ASCBLK:	CALL	TAPEON
	JR	C,DISCA3
	LD	B,0		; = 256 bytes
RDASC:	CALL	TAPEIN
	JR	C,DISCA3
	DJNZ	RDASC
	CALL	TAPEIN
	JR	NC,DISCA2	; Too much bytes in data block
	CALL	ADDBLK
	JR	NZ,DISCA3
	LD	A,1AH		; EOF character
	LD	HL,DATA
	LD	BC,256
	CPIR
	JR	NZ,ASCBLK	; No EOF, more ascii blocks
FILEOK:	LD	HL,S_FOK
	JR	STROUT

BASIC:	LD	HL,S_BAS
	CALL	TAPHED
	JR	NZ,DISCA3
	CALL	TAPEON
	JR	C,DISCA3
RESCNT:	LD	B,10
RDBAS:	CALL	TAPEIN
	JR	C,DISCA3
	JR	Z,DISCA3
	OR	A
	JR	NZ,RESCNT
	DJNZ	RDBAS		; 10th consecutive zero read?
	CALL	TAPEIN
	JR	C,SAVBOD
	JR	Z,DISCA3
	OR	A
	JR	NZ,DISCA2	; Only an optional 11th zero will be allowed
	CALL	TAPEIN
	JR	NC,DISCA2	; Too much bytes in data block
SAVBOD:	CALL	ADDBLK
	JR	NZ,DISCA3
	JR	FILEOK

BINARY:	LD	HL,S_BIN
	CALL	TAPHED
	JR	NZ,DISCA3
	CALL	TAPEON
	JR	C,DISCA3
	LD	B,6
RDBIN1:	CALL	TAPEIN
	JR	C,DISCA3
	DJNZ	RDBIN1
	LD	HL,(DATA+2)	; Last address
	LD	BC,(DATA)	; First address
	SBC	HL,BC
	JP	C,DISCA2
	INC	HL
	LD	B,H
	LD	C,L
RDBIN2:	CALL	TAPEIN
	JP	C,DISCA3
	JP	Z,DISCA3
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,RDBIN2
	CALL	TAPEIN
	JP	NC,DISCA2	; Too much bytes in data block
	PUSH	DE
	LD	HL,DATA+6
	CALL	TPATCH
	POP	DE
	CALL	LLNDET
	JR	SAVBOD

NUMBER:	LD	C,0		; Output of initial zeros disabled
	LD	DE,10000
	CALL	DIGIT
	LD	DE,1000
	CALL	DIGIT
	LD	DE,100
	CALL	DIGIT
	LD	DE,10
	CALL	DIGIT
	LD	A,L
	ADD	A,'0'
	JR	WRCHAR
DIGIT:	XOR	A
SUBSTR:	SBC	HL,DE
	JR	C,REMAIN
	INC	A
	LD	C,'0'		; Enable output from now on
	JR	SUBSTR
REMAIN:	ADD	HL,DE		; A = quotient, HL = remainder of HL/DE
	ADD	A,C
	RET	Z		; All digits are zero up till now
WRCHAR:	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	E,A
	LD	C,6		; Console output without checking CTRL+STOP
	CALL	BDOS
	POP	BC
	POP	DE
	POP	HL
	RET

; ADDBLK adds to output file the data stored in memory up to DE-1, preceded by
; a CAS-format lead in. It returns A=0 (Z) if succeeded, or A=1 (NZ) if a file
; write error occured.
; TAPHED displays a tape file's header information, then performs ADDBLK.

TAPHED:	CALL	STRING
	LD	HL,S_FILE
	CALL	STRING
	LD	HL,DATA+15	; Last character of file name
	LD	A,' '
	LD	B,5
CHKSPC:	CP	(HL)
	JR	NZ,WRNAME
	DEC	HL
	DJNZ	CHKSPC
WRNAME:	INC	B		; Name length discarding spaces
	LD	HL,DATA+10
NAMCHR:	LD	A,(HL)
	CALL	WRCHAR
	INC	HL
	DJNZ	NAMCHR
	LD	HL,S_QUOT
	CALL	STRING
	LD	DE,DATA+16
ADDBLK:	PUSH	DE
	LD	HL,FLAGS
	BIT	6,(HL)		; Flag for leadless mode
	RES	6,(HL)
	LD	DE,DATA
	JR	NZ,SETDMA	; Leadless blocks don't need any alligment
	LD	DE,LEADIN
	LD	A,(FCB+33)
	DEC	A
	AND	7
	LD	L,A
	LD	H,0
	ADD	HL,DE		; LEADIN + 8-byte allignment
	EX	DE,HL
SETDMA:	PUSH	DE
	LD	C,1AH
	CALL	TOBDOS		; Set DMA to alligned lead in + following DATA
	POP	DE
	POP	HL
	SBC	HL,DE		; Block length from the start of DMA
FILEWR:	LD	C,26H
FILACC:	LD	DE,FCB
TOBDOS:	CALL	BDOS
	OR	A
	RET

; Standard tape read functions are performed through TAPEON, TAPEIN and TAPEOF,
; which include several related operations. TAPEIN stores the byte read at (DE)
; and increases DE, unless a buffer overflow occured (noted with A=2 and NC,Z).
; TAPEON initializes DE to the buffer's start address. Both will return A=3 and
; C flag activated in case of a tape read error, with TAPEIN making a further
; distinction between BIOS-like fatal errors (C,Z) and gaps or timeouts (C,NZ).

TAPEIN:	PUSH	BC
	PUSH	DE
	CALL	LTAPIN
	POP	DE
	POP	BC
	JR	C,TAPERR
	CALL	TOBUFF
	RET	NZ
	LD	A,2
	JR	TAPEOF
TAPEON:	CALL	TAPSET
	LD	IX,TAPION
	CALL	BIOS
	LD	DE,DATA
	RET	NC
TAPERR:	LD	A,3
TAPEOF:	PUSH	AF
	LD	IX,BREAKX
	CALL	BIOS		; Let the BIOS realize CTRL+STOP state
	POP	AF
	LD	IX,TAPIOF
BIOS:	LD	IY,(EXPTBL-1)
	JP	CALSLT

TOBUFF:	LD	HL,(BDOS+1)	; End of TPA
	SBC	HL,DE
	RET	Z
	LD	(DE),A
	INC	DE
	RET

LTAPIN:	LD	IX,(LOWLIM)	; IXH = (WINWID)
	XOR	A
	DB	0DDH
	SUB	L		; IXL
	DB	0FDH
	LD	L,A		; IYL = -(LOWLIM)
	IN	A,(0A2H)	; Bit 7 = input signal from cassete
	LD	E,A
	CALL	CHRON2
	JR	NZ,TIMOUT
WTSYNC:	LD	C,B		; Store the measure of the previous phase
	CALL	CHRONO
	RET	C
	JR	NZ,TIMOUT
	LD	A,B
	ADD	A,C		; Measure of the last 2 phases (a whole pulse)
	JR	C,GAPFND
	DB	0DDH
	CP	L		; LOWLIM, measure for 3/4 of a bit window
	JR	C,WTSYNC	; Too short, start bit not found yet
	DB	0FDH
	LD	H,E		; IYH = signal state at the start of bit window
	DB	0DDH
	LD	C,H		; IXH, duration of flank count for next window
	LD	L,0		; Initial flank count for next window
	LD	D,80H
NEWWIN:	CALL	WINDOW		; Count signal flanks in 1st half of bit window
	DB	0DDH
	LD	C,H		; IXH
	LD	L,B		; = 0
	SRL	H
	DB	0FDH
	LD	B,L		; IYL, timeout at expected window limit + 25%
	CALL	NC,CHRON3
	CALL	CHRON3		; Synchronize to the 2nd / 4th / 6th... flank
	JR	Z,GETVAL	; No timeout
	LD	A,(FLAGS)
	AND	10H		; Flag for blind mode
	JR	Z,RETGAP
	SRL	C		; Flank count will last WINWID/2 in next window
	LD	A,E
	DB	0FDH
	XOR	H		; IYH
	JP	P,GETVAL
	INC	L		; Next window will start with 1 flank counted
GETVAL:	SRL	H
	JR	Z,PUTVAL	; Flanks in bit window not too many (2 or 4)
	LD	A,(FLAGS)
	AND	10H		; Flag for blind mode
	SCF
	RET	Z		; Return a fatal error, unless in blind mode
PUTVAL:	RR	D		; Get bit value from C flag
	JR	NC,NEWWIN	; Loop until bit 7 exits by the low end
	LD	A,D
	OR	A
	RET
WTFLNK:	CALL	CHRONO
	RET	C
	LD	B,255
	JR	Z,WTSYNC	; Flank detected, measure set to maximum
TIMOUT:	LD	A,(FLAGS)
	AND	10H		; Flag for blind mode
	JR	NZ,WTFLNK
	JR	RETGAP
GAPFND:	LD	A,(FLAGS)
	AND	10H		; Flag for blind mode
	JR	NZ,WTSYNC
RETGAP:	SUB	B		; Return C,NZ
	RET

CHRONO:	CALL	CHKKEY
	JR	NC,CHRON5
CHRON2:	LD	B,0
CHRON3:	INC	B
	JR	Z,CHRON4
	IN	A,(0A2H)
	XOR	E
	JP	P,CHRON3	; No flank yet
	XOR	E
	LD	E,A
	XOR	A		; Flank detected in time, return Z
	RET
CHRON4:	DEC	B		; Time out, return NZ & measure set to maximum
	RET
CHRON5:	SCF
	RET	Z		; CTRL+STOP, fatal error
	LD	A,(FLAGS)
	AND	10H		; STOP also fatal, unless in blind mode
	SCF
	RET
WINDOW:	LD	B,C		; Loops needed to poll bit window till its half
	LD	H,L		; Starting flank count
WINDO2:	IN	A,(0A2H)
	XOR	E
	JP	P,WINDO3
	XOR	E		; Flank reached, or...
	LD	E,A
	INC	H
	NOP
	DJNZ	WINDO2
	RET
WINDO3:	NOP			; ...no flank (both cases spend the same time)
	NOP
	NOP
	NOP
	DJNZ	WINDO2
	RET

TAPSET:	LD	B,0
HKCALL:	PUSH	BC
	CALL	H.TIMI		; BDOS counts down for stopping disk spin
	POP	BC
	DJNZ	HKCALL
TAPINI:	DI
	IN	A,(0AAH)
	AND	0E0H
	OR	6
	OUT	(0AAH),A	; Motor on, keyboard row 6 selected
	LD	A,14
	OUT	(0A0H),A	; PSG input port selected
	RET
CHKKEY:	LD	A,1
	OUT	(0ABH),A	; Set bit 0 of row selection ( = 7)
	IN	A,(0A9H)
	AND	10H		; STOP key
	LD	H,A
	XOR	A
	OUT	(0ABH),A	; Reset bit 0 of row selection ( = 6)
	IN	A,(0A9H)
	AND	2		; CTRL key
	SUB	H
	RET			; NC = STOP, Z = also CTRL
										
; When working in turbo mode, TMAIN is used instead of MAIN. It relays on TREAD
; for low-level reading of data blocks in Spectrum format, then jumps back to
; MAIN for the rest. TREAD can return the following:
; C,Z: turbo block was read entirely (buffer spans from DATA until DE-1)
; C,NZ: data buffer overflowed (as above, plus A = value of overflowing byte)
; NC,A=0: ended normally (CTRL+STOP when seeking a data block)
; NC,A=1: file write error
; NC,A=3: data not reliable

TMAIN:	CALL	TREAD
	JR	NC,TMEXIT
	JP	Z,SAVBLK
	LD	A,2
	CALL	TAPEOF
	JR	DISCA4
TMEXIT:	OR	A
	RET	Z
DISCA4:	JP	DISCAR

TREAD:	CALL	TAPSET
	IN	A,(0A2H)	; Bit 7 = input signal from cassete
	LD	C,A
HEDDET:	LD	B,0		; Start counting 256 fitting pulses
WAVCHK:	CALL	CHKKEY
	JP	Z,TAPEOF	; CTRL+STOP
	LD	H,152
	CALL	FULMEA
	JR	Z,HEDDET	; Too long
	LD	A,H
	CP	92
	JR	NC,HEDDET	; Too short
	DJNZ	WAVCHK
	LD	A,(FLAGS)
	AND	11H		; Flags for raw or blind modes
	LD	HL,S_TBLK
	JR	Z,BLKMES
	LD	HL,S_RAW
BLKMES:	CALL	STRING
	CALL	TAPINI
	LD	DE,DATA
	LD	H,172
	CALL	FULMEA		; Re-sync after console output
	JR	Z,LDERR
DATDET:	CALL	CHKKEY
	JR	NC,ERROR3
	LD	H,74
	CALL	HLFMEA
	JR	Z,LDERR
	LD	A,61
	CP	H
	JR	NC,DATDET	; Phase length not short, still no data
	LD	A,C		; Signal state after the 1st flank of the bits
	EX	AF,AF'
	LD	A,H
	SUB	45
	LD	H,A
	CALL	HLFMEA
	JR	Z,LDERR2
	LD	H,125
NEWBYT:	LD	L,1
NEWBIT:	CALL	FULMEA
CHKGAP:	JR	Z,DATERR	; Pulse timeout, no more data
	LD	A,49
	CP	H		; NC means a pulse larger than 1.13 ms
	LD	A,C
	RLA
	RLA
	RRCA
	LD	C,A
	LD	A,H
	CP	85
	RL	L		; Get bit value from C flag
	LD	H,124
	JR	NC,NEWBIT
	LD	A,C
	AND	3
	JP	Z,ATTLD		; Last 2 pulses were > 1.13 ms, no actual data
	LD	A,B
	XOR	L
	LD	B,A		; Parity count
	LD	A,L
	CALL	TOBUFF
	JP	Z,LNGBLK	; Couldn't store byte, out of memory
	CALL	CHKKEY
	LD	H,117
	JR	C,NEWBYT
DATSTP:	JR	Z,ERROR3	; CTRL+STOP
	LD	A,(FLAGS)
	AND	10H		; Flag for blind mode
	JR	Z,ERROR3
	JR	BLKLEN
PARITY:	LD	A,B
	OR	A
	JR	NZ,ERROR3	; Parity error
BLKLEN:	LD	HL,-DATA-1	-200H ; M80/L80 BUG WORKAROUND
	ADD	HL,DE
	JR	NC,ERROR3	; 0-length block
	CALL	TAPEOF
	PUSH	DE
	LD	HL,DATA+1
	DEC	DE
	CALL	TPATCH
	POP	DE
	XOR	A
	SCF
	RET

LDERR:	LD	A,(FLAGS)
	AND	10H		; Flag for blind mode
	JR	Z,ERROR3
LDSYNC:	LD	H,B		; = 0
	CALL	HLFMEA		; Re-sync after a gap in lead in
	JR	NZ,DATDET
	CALL	CHKKEY
	JR	C,LDSYNC
ERROR3:	OR	A
	JP	TAPERR		; A = 3 and tape off, flags unaffected

LDERR2:	LD	A,(FLAGS)
	AND	10H		; Flag for blind mode
	JR	Z,ERROR3
	LD	HL,114*256+1
	CALL	HLFMEA
	JR	CHKGAP
DATERR:	LD	A,(FLAGS)
	AND	11H		; Flags for raw or blind modes
	JR	Z,PARITY
	AND	10H		; Flag for blind mode
	JR	NZ,RESYNC
	LD	A,L
	DEC	L
	JR	Z,BLKLEN	; No trailing bits to be stored
FILBYT:	SCF
	RLA
	JR	NC,FILBYT	; Complete with ones the last byte
LSTBYT:	CALL	TOBUFF
	JR	Z,LNGBLK	; Couldn't store byte, out of memory
	JR	BLKLEN
RESYNC:	LD	IX,HLFMEA
	LD	H,74
	LD	B,68
	EX	AF,AF'
	XOR	C
	JP	P,HIDMID
	LD	IX,FULMEA	; First flank of the bit wasn't reached yet
	LD	H,60
	LD	B,54
HIDMID:	XOR	C
	EX	AF,AF'
	SCF
	RL	L		; Get bit value from C flag
	JR	NC,DATSYN
STOBYT:	LD	A,L
	CALL	TOBUFF
	JR	Z,LNGBLK	; Couldn't store byte, out of memory
	CALL	CHKKEY
	JP	NC,DATSTP
	LD	H,B
	LD	L,1
DATSYN:	LD	IY,CHKGAP
	PUSH	IY
	JP	(IX)

ATTLD:	LD	A,(FLAGS)
	AND	11H		; Flags for raw or blind modes
	JP	Z,PARITY
	AND	10H		; Flag for blind mode
	JR	Z,LSTBYT
	LD	IX,FULMEA
	LD	B,115
	JR	STOBYT

LNGBLK:	LD	HL,FLAGS
	BIT	6,(HL)		; Flag for leadless mode
	SCF
	RET	NZ		; Block too long, overflowed the buffer twice
	CALL	TAPEOF
	PUSH	DE
	LD	HL,DATA+1
	CALL	TPATCH
	POP	DE
	PUSH	DE
	CALL	ADDBLK
	POP	DE
	RET	NZ
	LD	HL,-DATA	-200H ; M80/L80 BUG WORKAROUND
	ADD	HL,DE		; Block length, to be displayed
	CALL	NUMBER
	LD	HL,S_BYTE
	CALL	STRING
	LD	HL,FLAGS
	SET	6,(HL)		; Flag for leadless mode
	LD	HL,S_LONG
	CALL	STRING
CLRLIN:	LD	HL,S_ERAS
	CALL	STRING		; Erase line
	CALL	TREAD
	JR	NC,TREXIT
	JR	Z,CLRLIN	; Buffer not overflowed, skip this block
	LD	DE,DATA
	LD	(DE),A
	INC	DE
	LD	H,118
	JP	NEWBYT		; Resume reading of half-saved block
TREXIT:	OR	A
	JR	NZ,CLRLIN	; Inconsistence detected, skip this block
	LD	HL,S_PREV	; CTRL+STOP, discard half-saved block
	CALL	STRING
	LD	A,3
	OR	A
	RET

FULMEA:	CALL	HLFMEA		; Measure first half (phase) of the pulse
	RET	Z		; Too long; otherwise, measure the second
HLFMEA:	LD	A,26
HOLDON:	DEC	A		
	JR	NZ,HOLDON	; Wait for input signal to stabilize
SIGCHK:	DEC	H
	RET	Z		; Maximum pulse length exceeded, returns Z
	IN	A,(0A2H)
	XOR	C
	JP	P,SIGCHK	; Input signal hasn't changed yet
	LD	A,C
	CPL
	LD	C,A		; Toggle current signal state
	RET			; Returns NZ and decreased value of H

; TPATCH searches turbo loading routines between HL and DE-1. It replaces them
; with the alternate routine STDLDR, unless /D option is set.

TPATCH:	OR	A
	EX	DE,HL
	LD	BC,98H		; Shortest known routine span from TSIGN1
	SBC	HL,BC		; Last possible location
	PUSH	HL
	SBC	HL,DE
	POP	DE
	RET	C
	EX	DE,HL
	LD	B,D
	LD	C,E
	INC	BC
	INC	BC		; BC = possible locations + 1
TSRCH:	LD	DE,TSIGN1
	CALL	SEQSEA
	RET	PO		; Location below first possible one reached
	PUSH	BC
	LD	BC,+9FH
	LD	A,90H
	CALL	RELSEA		; DE already points to TSIGN2
	POP	BC
	JP	PO,TSRCH	; Not a turbo loader
	PUSH	HL
	LD	HL,FLAGS
	SET	3,(HL)		; Flag indicating a turbo loader was found
	BIT	2,(HL)		; Flag for leaving loaders unpatched
	POP	HL
	RET	NZ
	PUSH	BC
	PUSH	HL
	LD	DE,TSIGN3
	LD	BC,+74H
	LD	A,2
	CALL	RELSEA
	LD	DE,TSIGN4
	LD	BC,+74H
	LD	A,3
	CALL	PO,RELSEA	; If TSIGN3 wasn't found, try TSIGN4
	PUSH	AF
	LD	DE,TSIGN5
	LD	BC,-2
	LD	A,2
	CALL	RELSEA
	LD	DE,TSIGN6
	LD	BC,-5
	LD	A,17H
	CALL	PE,RELSEA	; If TSIGN5 was found, try also TSIGN6
	EX	DE,HL
	JP	PO,LDRRPL	; Failed, put new loader at TSIGN1's location
	LD	DE,TSIGN7	; TSIGN6 found, now used as base search address
	LD	BC,-3
	LD	A,2
	CALL	RELSEA
	JP	PE,LDRRPL	; Found, put new loader at TSIGN7's location
	EX	DE,HL		; Otherwise, put it at TSIGN6's
LDRRPL:	INC	DE
	LD	HL,STDLDR
	CALL	SEQPAT
	POP	AF
	JP	PO,TESTP2	; Neither TSIGN3 nor 4 were found in old loader
	DEC	DE
	LD	HL,TSIGN3	; Replace last RET of new loader with TSIGN3
	CALL	SEQPAT
	POP	HL
	PUSH	HL
	LD	DE,TSIGN8
	LD	BC,-13H
	LD	A,6
	CALL	RELSEA
	INC	DE
	INC	DE
	LD	HL,PATCH1
	CALL	PE,SEQPAT	; TSIGN8 found, replace its write address
TESTP2:	POP	HL
	PUSH	HL
	LD	DE,TSIGN9
	LD	BC,-5EH
	LD	A,51H
	CALL	RELSEA
	JP	PO,SRCHON
	EX	DE,HL		; TSIGN9 found, use this as base search address
	PUSH	HL
	LD	DE,TSGN10
	LD	BC,+30H
	LD	A,0AH
	CALL	RELSEA
	POP	HL
	JP	PO,SRCHON
	PUSH	HL		; TSGN10 also found, bypass both
	LD	HL,PATCH2
	PUSH	HL
	INC	DE
	INC	DE
	CALL	SEQPAT
	POP	HL
	POP	DE
	INC	DE
	INC	DE
	INC	DE
	CALL	SEQPAT
SRCHON:	POP	HL
	POP	BC
	JP	TSRCH

SEQSEA:	LD	A,(DE)		; First sequence length
	INC	DE
	EX	AF,AF'
	LD	A,(DE)		; First byte of the sequence series
	INC	DE
	CPDR
	RET	PO		; Below first location - return ignoring Z flag
	PUSH	BC
	PUSH	DE
	PUSH	HL
	INC	HL
	INC	HL
	EX	AF,AF'
	LD	B,A
CHKFOL:	DJNZ	CPFOL		; The sequence continues
	LD	A,(DE)
	INC	DE
	OR	A
	JR	Z,ENDSEA	; End of sequence series, exit with PE flag set
SEQGAP:	INC	HL		; Leap a gap before checking next sequence
	DEC	A
	JR	NZ,SEQGAP
	LD	A,(DE)		; New sequence length
	INC	DE
	LD	B,A
CPFOL:	LD	A,(DE)
	INC	DE
	CP	(HL)
	INC	HL
	JR	Z,CHKFOL	; Location fits the sequence so far
	POP	HL
	POP	DE
	POP	BC
	DEC	DE
	DEC	DE
	JR	SEQSEA
ENDSEA:	POP	HL
	POP	BC		; Keep DE pointing to the next sequence series
	POP	BC
	RET

RELSEA:	PUSH	HL
	ADD	HL,BC		; Start searching at a location relative to HL
	LD	B,0
	LD	C,A
	CALL	SEQSEA
	EX	DE,HL		; DE = finding location as returned by CPDR
	POP	HL
	RET

SEQPAT:	LD	B,0
	LD	C,(HL)		; Patch length
	INC	HL
	XOR	A
BYTRPL:	EX	DE,HL
	XOR	(HL)
	EX	DE,HL
	XOR	(HL)		; Save parity difference, then replace
	LDI
	JP	PE,BYTRPL
	EX	DE,HL
	XOR	(HL)
	EX	DE,HL
	LD	HL,FLAGS
	BIT	1,(HL)		; Flag for turbo mode
	RET	Z
	LD	(DE),A		; Extra patch byte for parity correction
	RET

LLNDET:	LD	A,(FLAGS)
	AND	0AH		; Flags for turbo mode or turbo loader found
	RET	NZ
	LD	HL,-DATA-0A3H	-200H ; M80/L80 BUG WORKAROUND
	ADD	HL,DE
	RET	NC		; Avoid detecting LLSIGN out of bounds
	PUSH	DE
	LD	DE,LLSIGN
	LD	HL,DATA+9DH	; Last possible location
	LD	BC,22H		; BC = possible locations + 1
	CALL	SEQSEA
	POP	DE
	JP	PO,NPATCH	; Location below first possible one reached
	LD	HL,FLAGS
	SET	5,(HL)		; Flag for leadless loader
	RET
NPATCH:	LD	HL,-DATA-3CFH	-200H ; M80/L80 BUG WORKAROUND
	ADD	HL,DE
	RET	NC		; Avoid detecting NSIGN out of bounds
	PUSH	DE
	LD	DE,NSIGN
	LD	HL,DATA+3C9H	; Last possible location
	LD	BC,2		; BC = possible locations + 1
	CALL	SEQSEA
	POP	DE
	RET	PO		; Location below first possible one reached
	LD	HL,FLAGS
	BIT	2,(HL)		; Flag for leaving loaders unpatched
	RET	NZ
	SET	7,(HL)		; Flag for patched Namco loader
	PUSH	DE
	LD	HL,PATCH3
	LD	DE,DATA+348H
	LD	C,41
	LDIR
	LD	DE,DATA+3BFH
	LD	C,4
	LDIR
	LD	DE,DATA+3C9H
	LD	C,9
	LDIR
	LD	DE,DATA+41EH
	LDI
	POP	DE
	RET

TSIGN1:	DB	3,14H,08H,15H,0			; INC D / EX AF,AF' / DEC D
TSIGN2:	DB	2,0DBH,0A2H,0			; IN A,(0A2H)
TSIGN3:	DB	3,0D8H,18H,0FEH,0		; RET C / JR -2
TSIGN4:	DB	3,0D8H,0EDH,5FH,0		; RET C / LD A,R
TSIGN5:	DB	1,0D3H,1			; OUT (xx),A
	DB	1,0F1H,0			; POP AF
TSIGN6:	DB	2,0F5H,3EH,1			; PUSH AF / LD A,xx
	DB	1,0D3H,0			; OUT (xx),A
TSIGN7:	DB	1,21H,2				; LD HL,xxxx
	DB	1,0E5H,0			; PUSH HL
TSIGN8:	DB	3,32H,0D7H,05H,0		; LD (05D7H),A
TSIGN9:	DB	3,3EH,0F9H,32H,0		; LD A,0F9H / LD (xxxx),A
TSGN10:	DB	2,0AFH,32H,0			; XOR A / LD (xxxx),A
PATCH1:	DB	1,55H+(LDREND-LDRSTA)		; xxF3H
PATCH2:	DB	2,18H,01H			; JR +1

LLSIGN:	DB	6,0CDH,0E4H,00H,0B7H,20H,0FAH,0	; CALL 00E4H / OR A / JR NZ,-6

NSIGN:	DB	6,3AH,57H,0C1H,57H,0DBH,0A2H,0
PATCH3:	DB	0F5H,3EH,0E1H,18H,08H,0F5H,3EH,0E4H,18H,03H,0F5H,3EH,0F3H,32H
	DB	7EH,0C1H,0F1H,0E5H,0F5H,0DBH,0A8H,0F5H,0E6H,0FCH,0D3H,0A8H,0E1H
	DB	0F1H,0E5H,0CDH,00H,00H,0F5H,0E1H,0F1H,0D3H,0A8H,0E5H,0F1H,0E1H
	DB	0C9H
	DB	0AFH,0CDH,6AH,0C1H
	DB	0CDH,2DH,0C2H,0CDH,65H,0C1H,38H,3BH,0C9H
	DB	0C9H

; Unless /D option is set, any turbo loading routine found in the program being
; read will be overwritten with this alternate routine, which uses standard
; BIOS calls (and therefore, standard MSX tape format) instead of direct I/O.

STDLDR:	DB	LDREND-LDRSTA
LDRSTA:	DI
	EX	AF,AF'
	EXX
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	HL,0FCA6H
	LD	B,0CH
L1:	DEC	HL
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	PUSH	DE
	DJNZ	L1
	LD	A,H
	LD	H,B
	LD	L,B
	ADD	HL,SP
	LD	SP,0FCA4H
	LD	DE,0C961H
	PUSH	DE
	LD	DE,0EDD9H
	PUSH	DE
	LD	DE,00E1H
	PUSH	DE
	LD	DE,0CDD9H
	PUSH	DE
	LD	DE,69EDH
	PUSH	DE
	PUSH	HL
	EXX
	LD	C,0A8H
	IN	H,(C)
	AND	H
	LD	L,A
	CALL	0FC9AH
	JR	C,L5
	LD	A,0E4H
	LD	(0FC9EH),A
	CALL	0FC9AH
	JR	C,L5
	LD	B,A
	EX	AF,AF'
	CP	B
	SCF
	JR	NZ,L5
	JR	L4
L2:	POP	AF
	PUSH	IX
	EXX	
	POP	BC
	LD	HL,-0FC8EH
	ADD	HL,BC
	JR	NC,L3
	EX	DE,HL
	LD	HL,-18H
	ADD	HL,DE
	JR	C,L3
	POP	HL
	PUSH	HL
	ADD	HL,DE
	LD	(HL),A
	LD	A,(BC)
L3:	LD	(BC),A
	EXX
	INC	IX
	DEC	DE
L4:	CALL	0FC9AH
	JR	C,L5
	PUSH	AF
	XOR	B
	LD	B,A
	LD	A,E
	OUT	(99H),A
	OR	D
	LD	A,87H
	OUT	(99H),A
	JR	NZ,L2
	POP	AF
L5:	SBC	A,A
	OR	B
	EX	AF,AF'
	LD	A,0F3H
	LD	(0FC9EH),A
	XOR	A
	CALL	0FC9AH
	EXX
	POP	HL
	LD	SP,HL
	LD	HL,0FC8EH
	LD	B,0CH
L6:	POP	DE
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	DJNZ	L6
	POP	HL
	POP	DE
	POP	BC
	EXX
	EX	AF,AF'
	CP	1
	RET
LDREND:

S_RAW:	DB	'Raw data: ',0
S_BYTE:	DB	' bytes read',13,10,0
S_ASC:	DB	13,'Ascii',0
S_BAS:	DB	13,'Basic',0
S_BIN:	DB	13,'Binary',0
S_FILE:	DB	' file "',0
S_QUOT:	DB	'": ',0
S_FOK:	DB	'OK',13,10,0
S_DISC:	DB	'discarded',13,10,0
S_TPAT:	DB	' - Spectrum turbo loader patched',13,10,0
S_TMOD:	DB	' - switched to Spectrum data format',13,10,0
S_TBLK:	DB	'Turbo block: ',0
S_BOK:	DB	'OK, ',0
S_LMOD:	DB	' - next block uses Opera data format',13,10,0
S_NPAT:	DB	' - Namco / Bug Byte loader patched',13,10,0
S_LONG:	DB	' - too long, rewind for self resume',13,10,0
S_ERAS:	DB	27,'M',0
S_PREV:	DB	' - previous data has been ',0

LEADIN:	DB	0,0,0,0,0,0,0,1FH,0A6H,0DEH,0BAH,0CCH,13H,7DH,74H
DATA:

; Start-up sequence, put here for allowing its space to be used later for data.

	LD	A,(FCB+1)
	CP	' '
	LD	HL,S_INST
	JR	Z,EXIT		; Invalid arguments => show instructions
	LD	HL,FCB+9
	LD	A,(HL)
	CP	' '
	JR	NZ,SRCHSW
	LD	(HL),'C'	; No extension => set it to .CAS
	INC	HL
	LD	(HL),'A'
	INC	HL
	LD	(HL),'S'
SRCHSW:	LD	DE,0016H	; Default values in case of no switches
	LD	HL,DMA
	LD	C,(HL)
	LD	B,0
	INC	HL
SWCHK1:	LD	A,'/'
	CPIR
	JP	PO,INITSW
	LD	A,(HL)
	AND	0DFH		; To capital letters
	CP	'R'
	JR	NZ,SWCHK2
	SET	0,D
SWCHK2:	CP	'A'
	JR	NZ,SWCHK3
	LD	E,0FH
SWCHK3:	CP	'T'
	JR	NZ,SWCHK4
	SET	1,D
SWCHK4:	CP	'D'
	JR	NZ,SWCHK5
	SET	2,D
SWCHK5:	CP	'B'
	JR	NZ,SWCHK1
	SET	4,D
	JR	SWCHK1
INITSW:	LD	A,D		; = 000[/B]0[/D][/T][/R]
	LD	(FLAGS),A
	LD	C,E		; Create (16H), or just open (0FH) if [/A]ppend
	CALL	FILACC
	LD	HL,S_OPEN
	JR	NZ,EXIT
	LD	HL,1
	LD	(FCB+14),HL	; Register length = 1
	LD	HL,(FCB+16)
	LD	(FCB+33),HL	; Set register pointer to the end of file
	LD	(BAKPOS),HL	; Previous contents will never be cut off
	LD	HL,(FCB+18)
	LD	(FCB+35),HL
	LD	(BAKPOS+2),HL
	POP	DE
	POP	BC
	LD	SP,VOICCQ+128	; Stack in Basic's PLAY statement queues
	PUSH	BC
	PUSH	DE
	RET
EXIT:	POP	AF
	JP	STRING

S_INST:	DB	10
	DB	'  TAPE2CAS <output file> [options]',13,10
	DB	10
	DB	'[/A]ppend to an existing CAS file',13,10
	DB	'[/T]urbo, use Spectrum data format',13,10
	DB	'[/D]isable patching of known loaders',13,10
	DB	'[/R]aw mode, no parsing done on data',13,10
	DB	'[/B]lind mode, also ignore any error',13,10
	DB	10
	DB	'Press CTRL+STOP to exit at any time,',13,10
	DB	'or just STOP to force a data error.',13,10
	DB	'The latter is useful for marking the',13,10
	DB	'end of data blocks in [/B]lind mode.',13,10,0
S_OPEN:	DB	"Can't open output file",0

	END

