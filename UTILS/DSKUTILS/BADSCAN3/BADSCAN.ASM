;MSX-DOS  Bad sector scan  v1.59
;
BOOT	equ	0000h
BDOS	equ	0005h
DMA0	equ	0080h
;
CR	equ	0Dh
LF	equ	0Ah
TAB	equ	09h
BELL	equ	07h
CTLC	equ	03h
CLS	equ	0Ch
ESC	equ	1Bh
;
DISKVE	equ	0F323h		;Disk error jump vector (for ERRSYS)
ERRCLS	equ	0FF7h		;Error cluster mark
EXPTBL	equ	0FCC1h		;Main-ROM slot state
CALSLT	equ	001Ch		;BIOS call
CHGCAP	equ	0132h		;Change CAP-lamp
CAPST	equ	0FCABh		;CAP-lamp state
CSRSW	equ	0FCA9h		;Cursor switch
;
LRGSIZ	equ	64d		;Large media size(media size/64kbyte)
STKSIZ	equ	128d		;Stack size
;
;
	org	0100h
;
	jp	INIT
;
;--- Lamp switch bit pattern ---
;ON:1  OFF:0 (CPL)
INTLMP	equ	0-1-11110000b				;No error
ERRLMP	equ	0-1-10100000b				;Bad cluster found

;--- Option BIT vector ---
;
DEFOPT	equ	00000000b				;option default
NULOPT	equ	11111111b				;invalibity option
;
@OPT	equ	$
;		 Upcase   CHR    Set      Mask
	defb	11011111b,'N',00000001b,11101111b	;FAT No registering
	defb	11011111b,'R',00000010b,11111111b	;Repeat
	defb	11011111b,'A',00000100b,11111111b	;Alarm lamp (CAP lamp)
	defb	11011111b,'C',00001000b,11111111b	;Counter
	defb	11011111b,'L',00010000b,11111111b	;Large media switch
	defb	11011111b,'Q',00100000b,11111101b	;Quick start
	defb	00000000b,00h,00000000b,11101111b	;End of table
;
;--- Message ---
;
;
VER:	call	TYPERR
	defm	'MSX-DOS  Bad sector scan v1.59'
	defb	CR,LF,0
;
;
USAGE:	CALL	TYPERR
	defm	'Usage: BADSCAN  Drive: [/Option]'
	defb	CR,LF
	defm	'       /A :Alarm lamp (CAP lamp)'
	defb	CR,LF
	defm	'       /C :Counter of sector'
	defb	CR,LF
	defm	'       /L :Large media (registering of FAT)'
	defb	CR,LF
	defm	'       /N :No registering of FAT'
	defb	CR,LF
	defm	'       /R :Repeat'
	defb	CR,LF
	defm	'       /Q :Quick start'
	defb	CR,LF,0
	jp	QUIT
;
;
ABORT:	call	TYPERR
	defb	BELL,CR,LF
	defm	'Abort!!'
	defb	BELL,CR,LF,0
	jp	QUIT
;
;
BREAK:	call	TYPERR
	defb	CR,LF
	defm	'Break!'
	defb	BELL,CR,LF,0
	pop	hl
	jp	EXIT
;
;
LRGERR:	call	TYPERR
	defm	'/L option off'
	defb	CR,LF
	defm	'<Warning> Media size is large'
	defb	CR,LF,0
	jp	QUIT
;
;
NOERR:	call	TYPE
	defm	'Bad cluster not found'
	defb	CR,LF,0
	jp	EXIT
;
;
OFFDSK:	call	TYPERR
	defm	'Disk offline'
	defb	CR,LF,0
	jp	QUIT
;
;
BOTERR:	call	TYPERR
	defm	'Disk read error (BOOT sector)'
	defb	CR,LF,0
	jp	EXIT
;
;
FATERR:	call	TYPERR
	defm	'Disk read error (FAT)'
	defb	CR,LF,0
	jp	EXIT
;
;
DIRERR:	call	TYPERR
	defm	'Disk read error (Directory)'
	defb	CR,LF,0
	jp	EXIT
;
;
ERSTAT:	call	TYPERR
	defm	'Illegality disk parameter'
	defb	CR,LF,0
	jp	EXIT
;
;
MEMERR:	call	TYPERR
	defm	'Not enough memory'
	defb	CR,LF,0
	jp	QUIT
;
;
BADFAT:	call	TYPERR
	defm	'Difference between FAT1 and FAT2'
	defb	CR,LF,0
	jp	EXIT
;
;
MLTFAT:	call	TYPERR
	defm	'Too much FAT in disk'
	defb	CR,LF,0
	jp	EXIT
;
;
LNGFAT:	call	TYPERR
	defm	'Large FAT than memory'
	defb	CR,LF,0
	jp	QUIT
;
;
REGERR:	call	TYPERR
	defm	'Disk write error'
	defb	CR,LF,0
	jp	EXIT
;
;
;--- Sub-routin ---
;
QUIT:	ld	c,0		;reset
	jp	BDOS
;
;
CHKBRK:	call	INPKEY
	cp	CTLC
	jp	z,ABORT
	cp	ESC
	jp	z,BREAK
;
	ret
;
;
;Skip space & TAB
;HL :Strings
;
SKPSPC:	ld	a,(hl)
	inc	hl
	cp	TAB		;09h
	jp	z,SKPSPC
	cp	' '
	jp	z,SKPSPC
;
	dec	hl
	ret			;CY=1 Terminate
;
;
;DE * HL = HL
MULTI:	ld	c,l
	ld	b,h
	ld	hl,0
MULTIX:
	ld	a,c
	or	b
	ret	z
;
	srl	b
	rr	c
	jr	nc,MULTI0
	add	hl,de
MULTI0:
	ex	de,hl
	add	hl,hl
	ex	de,hl
	jr	MULTIX
;
;
;DE \ HL = HL
;DE mod HL = DE
;
DIVIDE:	ld	a,l
	or	h
	scf
	ret	z		;divide by zero
;
	ld	bc,0
	push	bc		;(SP) = 0
DIVX:
	rl	c
	rl	b
	add	hl,hl
	jr	nc,DIVX
DIVCNT:
	rr	h
	rr	l
	call	CPDEHL
	jr	c,DIV0
;
	ld	a,e
	sub	l
	ld	e,a
	ld	a,d
	sbc	a,h
	ld	d,a
	ex	(sp),hl
	add	hl,bc
	ex	(sp),hl
DIV0:
	srl	b
	rr	c
	jr	nc,DIVCNT
;
	pop	hl
	ret
;
;
;Test DE - HL
CPDEHL:	ld	a,d
	cp	h
	ret	nz
;
	ld	a,e
	cp	l
	ret
;
;
;Wait timer
TWAIT:	ei
	halt
	djnz	TWAIT
;
	ret
;
;
CAPLMP:	ld	iy,(EXPTBL-1)		;Main-ROM slot
	ld	ix,CHGCAP		;Change CAP lamp
	call	CALSLT
	ei
	ret
;
;
SELCUS:	di
	ld	(CSRSW),a		;cursor switch
	ei
	ret
;
;
OUTCON:	ld	e,a
	ld	c,02h
	jp	BDOS
;
;
INPKEY:	ld	a,0FFh
OUTERR:	ld	e,a
	ld	c,06h
	call	BDOS
	cp	01h		;A = 0 (CY = 1)
	ret
;
;
BINBCD:	push	de
	xor	a
	ld	b,3		;log(2^16)/log(10)/2
BCDCLR:
	ld	(de),a
	inc	de
	djnz	BCDCLR
;
	pop	de
	ld	b,16d		;Bit length
BITBCD:
	ld	c,b
	ld	b,3		;log(2^16)/log(10)/2
	push	de
	add	hl,hl
BTBCD1:
	ld	a,(de)
	adc	a,a
	daa
	ld	(de),a
	inc	de
	djnz	BTBCD1
;
	pop	de
	ld	b,c
	djnz	BITBCD
;
	ret
;
;
HEXBYT:	push	af
	rrca
	rrca
	rrca
	rrca
	call	HEXCHR
	pop	af
HEXCHR:
	and	0Fh
	cp	10d
	ccf
	adc	a,'0'
	daa
	jp	OUTCON
;
;
TYPBCD:	ld	a,b
	or	a
	ret	z
;
	dec	a
	rra
	add	a,e
	ld	e,a
	adc	a,d
	sub	e
	ld	d,a
;
	ld	c,' '
	srl	b
	inc	b
	jr	c,BCDLOW
;
	dec	b
BCDBYT:
	ld	a,(de)
	rrca
	rrca
	rrca
	rrca
	call	PUTBCD
BCDLOW:
	ld	a,(de)
	dec	b
	jr	z,BCDEND
;
	call	PUTBCD
	dec	de
	jr	BCDBYT
PUTBCD:
	and	0Fh
	jr	z,BCD0
	ld	c,'0'
BCDEND:
	push	bc
	push	de
	call	HEXCHR
	pop	de
	pop	bc
	ret
BCD0:
	ld	a,c
	push	bc
	push	de
	call	OUTCON
	pop	de
	pop	bc
	ret
;
;
BITWRD:	ex	de,hl
	ld	c,a
BITWD1:
	ld	a,(hl)
	inc	hl
	or	a
	scf
	jr	z,BITWD0	;End of table
;
	and	c		;mask
	cp	(hl)
BITWD0:
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	jr	nz,BITWD1
;
	ex	de,hl
	ret
;
;
TYPE:	ex	(sp),hl
	ld	e,(hl)
	inc	hl
	ex	(sp),hl
	inc	e
	dec	e
	ret	z
;
	ld	c,02h
	call	BDOS
	jr	TYPE
;
;
TYPERR:	ex	(sp),hl
	ld	e,(hl)
	inc	hl
	ex	(sp),hl
	inc	e
	dec	e
	ret	z
;
	ld	c,06h
	call	BDOS
	jr	TYPERR
;
;
TYPMSG:	ld	a,(de)
	or	a
	ret	z
;
	push	de
	call	OUTCON
	pop	de
	inc	de
	jr	TYPMSG
;
;
DSKONL:	ld	c,18h			;Disk login vector
	jp	BDOS
;
;
SETDMA:	ld	(DMAPNT),de
	ld	c,1Ah			;set DMA
	jp	BDOS
;
;
DSKINF:	ld	e,a
	ld	c,1Bh			;Disk parameter
	call	BDOS
	inc	a
	sub	1
	ret
;
;
RDFAT:	add	hl,bc
	srl	b
	rr	c
	sbc	a,a		;save CY
	add	hl,bc
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	or	a
	jr	nz,RDFATH
;
	ld	a,d
	and	0Fh
	ld	d,a
	xor	a		;A = 0
	ret
RDFATH:
	ex	de,hl
	add	hl,hl
	adc	a,a
	add	hl,hl
	adc	a,a
	add	hl,hl
	adc	a,a
	add	hl,hl
	adc	a,a
	ld	l,h
	and	0Fh
	ld	h,a
	ex	de,hl
	xor	a
	dec	a		;A = 0FFh
	ret
;
;
WTFAT:	add	hl,bc
	srl	b
	rr	c
	sbc	a,a		;save CY
	add	hl,bc
	or	a
	jr	nz,WTFATH
;
	ld	(hl),e
	inc	hl
	ld	a,d
	and	0Fh
	ld	d,a
	ld	a,(hl)
	and	0F0h
	or	d
	ld	(hl),a
	xor	a		;A = 0
	ret
WTFATH:
	ex	de,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,hl
	ex	de,hl
	ld	a,(hl)
	and	0Fh
	or	e
	ld	(hl),a
	inc	hl
	ld	(hl),d
	xor	a
	dec	a		;A = 0FFh
	ret
;
;
RDSEC:	ld	h,l
	ld	a,(SELDRV)
	ld	l,a
	ld	c,2Fh		;Read sector (absolute)
	call	ERRSYS
	ld	a,(BDSTAT)
	cp	01h
	ccf
	ret
;
;
WTSEC:	ld	h,l
	ld	a,(SELDRV)
	ld	l,a
	ld	c,30h		;Write sector (absolute)
	call	ERRSYS
	ld	a,(BDSTAT)
	cp	01h
	ccf
	ret
;
;
;--- Disk error trap system call ---
;
ERRSYS:	push	hl
	ld	hl,(DISKVE)
	ld	(VECSAV),hl
	ld	hl,ERRVEC
	ld	(DISKVE),hl
;
	ld	hl,BDSTAT
	ld	(hl),00h
	pop	hl
;
	ld	(SPSAV),sp
	call	BDOS
	jr	@GOOD
;
;
@ERROR:	ld	sp,(SPSAV)
	ld	a,c
	ld	(BDSTAT),a
@GOOD:
	push	hl
	ld	hl,(VECSAV)
	ld	(DISKVE),hl
	pop	hl
	ret
;
;
ERRVEC:	defw	@ERROR
;
;
;--- Disk error message ---
;
@DISK	equ	$		;BDSATAT (w=0:reading ,w=1:writing)
				;7 6 5 4 3 2 1 0   (BIT)
	defb	80h,80h		;1 x x x x x x x   bad fat
	defw	@80
	defb	0FFh,01h	;0 0 0 0 0 0 0 1   write protect
	defw	@01
	defb	0FEh,02h	;0 0 0 0 0 0 1 w   not ready
	defw	@02
	defb	0FEh,04h	;0 0 0 0 0 1 0 w   crc error
	defw	@04
	defb	0FEh,06h	;0 0 0 0 0 1 1 w   seek error
	defw	@06
	defb	0FEh,08h	;0 0 0 0 1 0 0 w   record not found
	defw	@08
	defb	0FFh,0Ah	;0 0 0 0 1 0 1 0   unsupported media (* option)
	defw	@0A
	defb	0FFh,0Bh	;0 0 0 0 1 0 1 1   write error
	defw	@0B
	defb	0FEh,0Ch	;0 0 0 0 1 1 0 w   other error
	defw	@0C
	defb	00h,00h		;end of table
	defw	@END
;
;
@80:	defm	'Bad FAT'
	defb	0
@01:	defm	'[ Write protect DISK ]'
	defb	0
@02:	defm	'Not ready'
	defb	0
@04:	defm	'CRC error'
	defb	0
@06:	defm	'Seek error'
	defb	0
@08:	defm	'Record not found'
	defb	0
@0A:	defm	'Un-supported media'
	defb	0
@0B:	defm	'Write error'
	defb	0
@0C:	defm	'Disk error'
	defb	0
@END:	defm	'???'
	defb	0
;
;
;--- Main ---
;
INIT:	ld	sp,(BDOS+1)
	ld	hl,DMA0
	ld	a,(hl)
	or	a
	jp	z,VER
;
	ld	e,a
	ld	d,0
	inc	hl
	ex	de,hl
	add	hl,de
	ld	(hl),0			;set EOL
	ex	de,hl
	call	SKPSPC
	jp	c,USAGE
;
	inc	hl
	ld	a,(hl)
	dec	hl
	cp	':'
	jp	nz,USAGE
;
	push	hl
	call	DSKONL			;disk on-line vec.
	pop	de
	ld	a,(de)
	res	5,a			;'a'->'A'
	sub	'A'
	ld	c,a
	sub	17d
	cpl				;0->16,1->15...15->1
	ld	b,a
VECBIT:
	ld	a,l
	or	h
	jr	z,VECNUL
;
	add	hl,hl
	djnz	VECBIT
VECNUL:
	ccf
	sbc	a,a
	or	c
	ld	(SELDRV),a		;'A:'=0,'B:'=1 ...
;
	ex	de,hl
	inc	hl
	ld	c,DEFOPT		;ooption default
	ld	b,NULOPT		;disable option
ARG:
	inc	hl
	call	SKPSPC
	jr	c,EOL
;
	cp	'/'
	jp	nz,USAGE
;
	push	bc
	inc	hl
	ld	a,(hl)
	push	hl
	ld	de,@OPT
	call	BITWRD
	ex	de,hl
	pop	hl
	jr	nc,SETOPT

	push	de
	push	hl
	dec	hl
	ld	a,(hl)
	call	OUTERR
	pop	hl
	ld	a,(hl)
	push	hl
	call	OUTERR
	call	TYPERR
	defm	' ???'
	defb	CR,LF,0
	pop	hl
	pop	de
SETOPT:
	pop	bc
	ld	a,c
	or	e
	ld	c,a
	ld	a,b
	and	d
	ld	b,a
	jr	ARG
EOL:
	ld	a,c
	and	b
	ld	(OPTBIT),a
;
	ld	a,(SELDRV)
	or	a
	jp	m,OFFDSK
;
	ld	hl,0000h
	ld	(ERRCNT),hl
;
	ld	a,(OPTBIT)
	bit	5,a			;Quick start
	jr	nz,QSTART
;
;
;Repeat start
REP:	scf
	sbc	a,a
	call	SELCUS			;cursor on
;
	call	TYPERR
	defb	CR,LF
	defm	'[ Set disk & hit any key ]'
	defb	CR,LF,0
PAUSE:
	ld	a,(OPTBIT)
	bit	2,a			;alarm lamp(CAP)
	jr	nz,HIT1
;
;
HIT0:	call	INPKEY
	jr	c,HIT0
	jr	HITKEY
;
;/A option on
HIT1:	ld	a,(CAPST)
	cp	1
	sbc	a,a
	push	af
;
	ld	hl,(ERRCNT)
	ld	a,l
	or	h
	add	a,0FFh
	sbc	a,a
	and	ERRLMP-INTLMP
	add	a,INTLMP
	ld	c,a			;alarm lamp switch pattern
;
ALMLMP:
	ld	b,7d			;60*1/8 sec
	call	TWAIT
	ld	a,c
	rlca
	ld	c,a
	sbc	a,a
	push	bc
	call	CAPLMP
	call	INPKEY
	pop	bc
	jr	c,ALMLMP
;
	ld	h,a
	ex	(sp),hl
	call	CAPLMP
	pop	af
;
HITKEY:
	cp	ESC
	jr	z,PAUSE
	cp	CTLC
	jp	z,ABORT
;
;
;Initialize
QSTART:	ld	hl,0000h
	ld	(ERRCNT),hl		;reset
	ld	(ERRNEW),hl		;reset
;
	call	TYPERR
	defb	CR,LF,0
	xor	a
	call	SELCUS			;cursor off
;
	ld	de,EOC
	call	SETDMA
;
	ld	de,0000h		;Boot sector
	ld	l,01h			;length
	call	RDSEC
	jp	c,BOTERR		;Read error (boot sector)
;
	ld	hl,(DMAPNT)
	ld	a,(hl)
	cp	0F8h			;Disk ID (F8h - FFh)
	jr	c,BOOTSC
;
	inc	hl
	ld	a,(hl)
	inc	hl
	and	(hl)
	inc	a
	jr	nz,BOOTSC
;
	ld	a,(SELDRV)
	inc	a
	call	DSKINF
	jp	c,OFFDSK
;
	ld	(CLSLEN),a		;cluster length (sector)
	ld	(SECSIZ),bc		;sector size
	ld	l,(ix+8d)		;FAT sector
	ld	h,(ix+9d)
	ld	(FATSEC),hl
	ld	l,(ix+11d)		;Directory entry
	ld	h,0
	ld	(DIRNUM),hl
	ld	l,(ix+16d)		;FAT length (sector)
	ld	(FATLEN),hl
	ld	a,(ix+10d)		;Number of FAT
	ld	(FATNUM),a
	ld	l,(ix+12d)		;Data sector
	ld	h,(ix+13d)
	push	hl
	ld	a,(CLSLEN)
	ld	l,a
	ld	h,0			;DE = Cluster MAX
	call	MULTI
	pop	de
	add	hl,de
	ld	(MAXSEC),hl
	ld	(TRKSEC),hl		;non-seek device?
	ld	hl,0
	ld	(HEDNUM),hl		;Drive hed
	jr	FATSC
;
;
;Boot sector
BOOTSC:	ld	ix,(DMAPNT)
	ld	l,(ix+0Bh)
	ld	h,(ix+0Ch)		;sector size (byte)
	ld	(SECSIZ),hl
	ld	l,(ix+0Eh)
	ld	h,(ix+0Fh)		;reserved sector (FAT sec. - Boot sec.)
	ld	(FATSEC),hl
	ld	l,(ix+11h)
	ld	h,(ix+12h)		;directory entry
	ld	(DIRNUM),hl
	ld	l,(ix+13h)
	ld	h,(ix+14h)		;max sector
	ld	(MAXSEC),hl
	ld	l,(ix+16h)
	ld	h,(ix+17h)		;FAT length (sector)
	ld	(FATLEN),hl
	ld	l,(ix+18h)
	ld	h,(ix+19h)		;sector per track
	ld	(TRKSEC),hl
	ld	l,(ix+1Ah)
	ld	h,(ix+1Bh)		;drive hed
	ld	(HEDNUM),hl
;
	ld	a,(ix+0Dh)		;cluster length (sector)
	ld	(CLSLEN),a
	ld	a,(ix+10h)		;number of FAT
	ld	(FATNUM),a
;
;
;Read FAT sector
FATSC:	ld	hl,(FATLEN)
	ld	de,(SECSIZ)
	call	MULTI
	ld	a,l
	or	h
	jp	z,ERSTAT		;FATLEN=0 or SECSIZ=0
;
	ld	c,l
	ld	b,h
	ld	hl,(DMAPNT)
	ld	(FAT1),hl
	ld	(FAT2),hl
;
	ld	de,(FATLEN)
	ld	a,(FATNUM)
	cp	3d
	jp	nc,MLTFAT
;
	dec	a
	jp	m,ERSTAT		;A=0
	jr	z,FATONE
;
	ex	de,hl
	add	hl,hl
	ex	de,hl
	add	hl,bc
	ld	(FAT2),hl
FATONE:	add	hl,bc
	ld	(DATA),hl
	inc	d
	dec	d
	jp	nz,LNGFAT

	push	de
	ld	de,(FAT1)
	call	BUFLEN
	pop	de
	jp	c,MEMERR
;
	ex	de,hl
	call	CPDEHL
	jp	c,LNGFAT
;
	ld	a,l
	ld	de,(FATSEC)
	add	hl,de
	ld	(DIRSEC),hl
	ld	l,a
	call	RDSEC
	jp	c,FATERR
;
;
;Compare FAT1,FAT2
	ld	a,(FATNUM)
	dec	a
	jr	z,DIRSC
;
	ld	hl,(MAXSEC)
	ld	de,(DATSEC)
	xor	a
	sbc	hl,de
	ex	de,hl
	ld	a,(CLSLEN)
	ld	l,a
	ld	h,0
	call	DIVIDE
	ld	a,l
	or	h
	jp	z,ERSTAT
;
	ld	de,ERRCLS-2		;0FF7h-2
	call	CPDEHL
	jp	c,ERSTAT
;
	inc	hl
	inc	hl
	ld	c,l
	ld	b,h
	srl	b
	rr	c
	sbc	a,a
	ex	af,af'
	add	hl,bc
	ld	c,l
	ld	b,h
	ld	de,(FAT1)
	ld	hl,(FAT2)
CPFAT:
	ld	a,(de)
	inc	de
	cpi
	jp	nz,BADFAT		;FAT1 <> FAT2
	jp	pe,CPFAT		;BC > 0
;
	ex	af,af'
	or	a
	jr	z,DIRSC
;
	ld	a,(de)
	and	0Fh
	ld	b,a
	ld	a,(hl)
	and	0Fh
	cp	b
	jp	nz,BADFAT
;
;
;Ceck directory area
DIRSC:	ld	de,(DATA)
	call	SETDMA
;
	ld	hl,(SECSIZ)
	ld	b,5d			;32=2^5
DIRDIV:
	srl	h
	rr	l
	jp	c,ERSTAT
;
	djnz	DIRDIV
;
	ld	de,(DIRNUM)
	call	DIVIDE
	ld	a,e
	or	d
	jr	z,DIRMD0
;
	inc	hl
DIRMD0:	ld	a,l
	or	h
	jp	z,ERSTAT
;
	ex	de,hl
	ld	hl,(DIRSEC)
	add	hl,de
	ld	(DATSEC),hl
	push	de
	ld	de,(DATA)
	call	BUFLEN
	pop	de
	jp	c,MEMERR
;
	ld	a,h
	add	0FFh
	sbc	a,a
	or	l
	ld	hl,(DIRSEC)
	ex	de,hl
	ld	c,a
	ld	b,0
CHKDIR:
	ld	a,l
	or	h
	jr	z,CHKINT			;end of directory
;
	ld	a,c
	sbc	hl,bc
	jr	nc,TSTDIR
;
	add	l
	ld	hl,0
TSTDIR:
	push	bc
	push	de
	push	hl
	ld	l,a
	call	RDSEC
	pop	hl
	pop	de
	pop	bc
	jp	c,DIRERR
;
	ex	de,hl
	add	hl,bc
	ex	de,hl
	jr	CHKDIR
;
;
;Set sector step
CHKINT:	ld	de,(DATA)
	call	BUFLEN
	jp	c,MEMERR
;
	ld	a,h
	add	a,0FFh
	sbc	a,a
	or	l
	ld	(CHKLEN),a
;
	ld	hl,(TRKSEC)
	ld	de,(HEDNUM)
	call	MULTI
	ld	a,h
	add	0FFh
	sbc	a,a
	or	l
	jr	z,DATSC
;
	ld	l,a
	ld	a,(CHKLEN)
	cp	l
	jr	c,DATSC
;
	ld	a,l
	ld	(CHKLEN),a
;
;
;Check DATA area
DATSC:	ld	de,@LIN1
	call	TYPMSG
;
	ld	de,(DATSEC)
	ld	a,(CHKLEN)
	ld	l,a
	ld	h,0
	call	DIVIDE
	ld	hl,(DATSEC)
	or	a
	sbc	hl,de
CHKTRK:
	ld	(SECNUM),hl
	ld	(SECPNT),hl
	ld	a,(OPTBIT)
	bit	3,a				;sector counter
	call	nz,TYPCNT
	call	CHKBRK
;
	ld	hl,(SECNUM)
	ld	de,(DATSEC)
	xor	a
	sbc	hl,de
	jr	nc,ONFAT
;
	ld	hl,0
ONFAT:	push	hl
	ld	d,a
	ld	a,(CHKLEN)
	ld	e,a
	add	hl,de
	ex	de,hl
	ld	a,(CLSLEN)
	ld	l,a
	push	hl
	call	DIVIDE
	pop	de
	ex	(sp),hl
	ex	de,hl
	call	DIVIDE
	pop	de
	ex	de,hl
	xor	a
	sbc	hl,de
	ld	c,e
	ld	b,d
	inc	bc
	inc	bc
	ex	de,hl
	inc	de
	ld	hl,(FAT1)
TRKFAT:
	push	bc
	push	de
	push	hl
	call	RDFAT
	ld	hl,ERRCLS
	xor	a
	sbc	hl,de
	pop	hl
	pop	de
	pop	bc
	scf
	jr	z,ERRTRK
;
	inc	bc
	dec	de
	ld	a,e
	or	d
	jr	nz,TRKFAT
;
	ld	de,(SECNUM)
	ld	a,(CHKLEN)
	ld	l,a
	call	RDSEC
ERRTRK:
	call	c,CHKSEC
;
	ld	hl,(SECNUM)
	ld	a,(CHKLEN)
	ld	e,a
	ld	d,0
	add	hl,de
	ex	de,hl
	ld	hl,(MAXSEC)
	scf
	sbc	hl,de
	ex	de,hl
	jr	c,DSKEND
;
	inc	de
	inc	d
	dec	d
	jp	nz,CHKTRK
;
	ld	a,(CHKLEN)
	scf
	sbc	a,e
	jp	c,CHKTRK
;
	ld	a,e
	ld	(CHKLEN),a
	jp	CHKTRK
DSKEND:
	ld	de,@LIN2
	call	TYPMSG
;
	ld	hl,(ERRCNT)
	ld	a,l
	or	h
	jp	z,NOERR
;
	push	hl
	ld	de,BCDBUF
	call	BINBCD
	ld	de,BCDBUF
	ld	b,6d
	call	TYPBCD
	call	TYPE
	defm	' error cluster'
	defb	0
;
	pop	hl
	dec	hl
	ld	a,l
	or	h
	ld	a,'s'
	call	nz,OUTCON
	call	TYPE
	defm	' found'
	defb	CR,LF,CR,LF,0
;
	ld	hl,(ERRNEW)
	ld	a,l
	or	h
	jp	z,EXIT			;all registered
;
	ld	a,(OPTBIT)
	bit	0,A			;FAT no registering option
	jp	nz,EXIT
;
;
;Check media size
	bit	4,a			;Large media option
	jr	nz,LRGDSK
;
	ld	de,8000h		;32kbyte
	ld	hl,(SECSIZ)
	call	DIVIDE
	add	hl,hl			;64k/sector size
	ex	de,hl
	ld	hl,(MAXSEC)
	ld	bc,(DATSEC)
	xor	a
	sbc	hl,bc
	ex	de,hl
	call	DIVIDE			;media size/64k
	ld	de,LRGSIZ
	call	CPDEHL
	jp	c,LRGERR		;Large option
LRGDSK:
	call	TYPERR
	defm	'Error cluster registering...'
	defb	CR,LF,0
	call	CHKBRK
;
	ld	de,(FAT1)
	call	SETDMA
	ld	hl,(DIRSEC)
	ld	de,(FATSEC)
	xor	a
	scf
	sbc	hl,de
	jp	c,ERSTAT
;
	inc	hl
	or	h
	jp	nz,ERSTAT
;
	call	WTSEC
	ld	hl,@CMPLT
	ld	de,@DISK
	call	c,BITWRD
	ex	de,hl
	call	TYPMSG
	call	TYPE
	defb	CR,LF,CR,LF,0
EXIT:
	ld	a,(OPTBIT)
	bit	1,A			;Repeat option
	jp	nz,REP
;
	jp	QUIT
;
;
;--- --- ---
;
BUFLEN:	ld	hl,0-STKSIZ
	add	hl,sp
	xor	a
	sbc	hl,de
	sbc	a,a
	ex	de,hl
	ld	hl,0
	ret	c			;No buffer
;
	ld	hl,(SECSIZ)
	call	DIVIDE
	ld	a,h
	or	l
	sub	1
	ret	c			;No buffer
;
	xor	a
	ret
;
;
;Check sector
CHKSEC:	ld	a,(CHKLEN)
	ld	b,a
CHKSC1:
	push	bc		;loop counter
	ld	a,(OPTBIT)
	bit	3,a
	call	nz,TYPCNT
	call	CHKBRK
;
	ld	hl,(SECPNT)
	ld	de,(DATSEC)
	or	a
	sbc	hl,de
	jr	c,CHKSC0
;
	ex	de,hl
	ld	a,(CLSLEN)
	ld	l,a
	ld	h,0
	call	DIVIDE
	inc	hl
	inc	hl
	ld	(FATPNT),hl
	ld	(MODVAL),de
	ld	c,l
	ld	b,h
	ld	hl,(FAT1)
	call	RDFAT
	ld	(FATVAL),de
	ld	hl,ERRCLS	;FF7h
	call	CPDEHL
	jr	z,NXTSEC
;
	ld	de,(SECPNT)
	ld	l,1
	call	RDSEC
	ld	(ERRSTA),a
	call	c,ERRLOG
CHKSC0:
	ld	hl,(SECPNT)
	inc	hl
	ld	(SECPNT),hl
	pop	bc
	djnz	CHKSC1
;
	ret
;
;
NXTSEC:	ld	hl,(MODVAL)
	ld	a,l
	or	h
	jr	nz,CHKSC0
;
	call	ERRINC
	ld	de,@SKIP
	call	TYPMSG
;
	call	TYPFAT
	ld	de,@DIDE
	call	TYPMSG
	call	TYPE
	defm	'< Registered in FAT >'
	defb	CR,LF,0
	jr	CHKSC0
;
;
ERRLOG:	call	TYPSEC
	call	TYPFAT
	ld	hl,(FATVAL)
	ld	a,l
	or	h
	jr	nz,USECLS
;
	call	NEWINC
	ld	de,@FREE
	call	TYPMSG
	;
	ld	a,(ERRSTA)		;BDSTAT
	ld	de,@DISK
	call	BITWRD
	ex	de,hl
	call	TYPMSG
	call	TYPE
	defb	CR,LF,0
;
	ld	bc,(FATPNT)
	ld	de,ERRCLS		;FF7h
	ld	hl,(FAT2)
	ld	a,(FATNUM)
	dec	a
	call	nz,WTFAT
	ld	bc,(FATPNT)
	ld	de,ERRCLS		;FF7h
	ld	hl,(FAT1)
	jp	WTFAT
USECLS:
	call	ERRINC
	ld	de,@ACTV
	call	TYPMSG
;
	ld	a,(ERRSTA)
	ld	de,@DISK
	call	BITWRD
	ex	de,hl
	call	TYPMSG
	call	TYPE
	defb	CR,LF,0
	ret
;
;
NEWINC:	ld	hl,(ERRNEW)
	inc	hl
	ld	(ERRNEW),hl
ERRINC:	ld	hl,(ERRCNT)
	inc	hl
	ld	(ERRCNT),hl
	ret
;
;		0....5....0....5....0....5....0....5....0....5....0....5
@LIN1:	defm	'    Sector      Cluster   State         Error type'
	defb	CR,LF
@LIN2:	defm	'--------------  -------  -------  -----------------------'
	defb	CR,LF,0
;
;		0....5....0....5....0....5....0....5....0....5....0....5
;                _*****(****h)     ***h     ****    *******************...
;
@SKIP:	defm	'   ...            '
	defb	0
@SEC1:	defm	      '('
	defb	0
@SEC2:	defm		   'h)     '
	defb	0
;
;		0....5....0....5....0....5....0....5....0....5....0....5
@FAT:	defm			     'h     '
	defb	0
;
;
@FREE:	defm				   'Free    '
	defb	0
@ACTV:	defm				   'Act.    '
	defb	0
@DIDE:	defm				   'Dide    '
	defb	0
;
;
@CMPLT:	defm	'Complete'
	defb	0
;
;
TYPSEC:	ld	hl,(SECPNT)
	push	hl
	ld	de,BCDBUF
	call	BINBCD
	ld	b,6d
	ld	de,BCDBUF
	call	TYPBCD
	ld	de,@SEC1
	call	TYPMSG
;
	pop	hl
	ld	a,h
	push	hl
	call	HEXBYT
	pop	hl
	ld	a,l
	call	HEXBYT
	ld	de,@SEC2
	jp	TYPMSG
;
;
TYPFAT:	ld	hl,(FATPNT)
	push	hl
	ld	a,h
	call	HEXCHR
	pop	hl
	ld	a,l
	call	HEXBYT
	ld	de,@FAT
	jp	TYPMSG
;
;
TYPCNT:	ld	a,' '
	call	OUTERR
	ld	hl,(SECPNT)
	call	CNTNUM
	ld	a,'/'
	call	OUTERR
	ld	hl,(MAXSEC)
	dec	hl
	call	CNTNUM
	ld	a,CR
	jp	OUTERR
;
;
CNTNUM:	ld	de,BCDBUF
	call	BINBCD
	ld	de,BCDBUF+2
	call	CNTNM1
	call	CNTNM2
CNTNM2:	ld	a,(de)
	push	af
	rrca
	rrca
	rrca
	rrca
	call	CNTNM1
	pop	af
	inc	de
CNTNM1:
	push	de
	and	0Fh
	add	a,'0'
	call	OUTERR
	pop	de
	dec	de
	ret
;
;--- Debug ---
;
;Type register
TYPREG:	push	af
	push	bc
	push	de
	push	hl
	ld	hl,10
	add	hl,sp
	push	hl
	ld	b,6
TYPRG1:
	dec	hl
	ld	a,(hl)
	dec	hl
	ld	c,(hl)
	push	hl
	push	bc
	call	HEXBYT
	pop	bc
	ld	a,c
	push	bc
	call	HEXBYT
	ld	a,' '
	call	OUTCON
	pop	bc
	pop	hl
	djnz	TYPRG1
;
	call	TYPE
	defb	CR,LF,0
	pop	hl
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
;
;--- Work area ---
;
BCDBUF:	defs	3d		;BCD (6 column) / 2
;
;
BDSTAT:	defb	0
CHKLEN:	defb	0
CLSLEN:	defb	0
DATA:	defw	0
DATSEC:	defw	0
DIRNUM:	defw	0
DIRSEC:	defw	0
DMAPNT:	defw	0
ERRCNT:	defw	0
ERRNEW:	defw	0
ERRSTA:	defb	0
FAT1:	defw	0
FAT2:	defw	0
FATLEN:	defw	0
FATNUM:	defb	0
FATPNT:	defw	0
FATSEC:	defw	0
FATVAL:	defw	0
HEDNUM:	defw	0
MAXSEC:	defw	0
MODVAL:	defw	0
OPTBIT:	defb	0
SECNUM:	defw	0
SECPNT:	defw	0
SECSIZ:	defw	0
SELDRV:	defb	0
SPSAV:	defw	0
TRKSEC:	defw	0
VECSAV:	defw	0
;
;
;--- END ---
;
EOC	equ	$		;End of code
;
end

