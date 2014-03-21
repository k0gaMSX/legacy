; A basic and compreensive BDOS function test.
; Made for testing BDOSEMU for UZIX.
; Public domain software.
; (c) 1999 A&L Software
;
; BDOS functions tested:
;  0 - terminate program
;  1 - console input
;  2 - console output
;  3 - auxiliar device input  	[not implemented]
;  4 - auxuliar device output 	[not implemented]
;  5 - printer output		[not implemented]
;  6 - console input/output
;  7 - console input
;  8 - console input
;  9 - string output
; 10 - string input
; 12 - sys version
; 15 - open file
; 16 - close file
; 17 - find first file
; 18 - find next file
; 19 - erase file
; 20 - sequencial read
; 21 - sequencial write
; 22 - create file
; 23 - rename file
; 24 - get drive vector
; 25 - get default drive
; 26 - set DMA
; 27 - get disk parameters
; 31 - get disk parameters
; 33 - random read		[128-byte blocks]
; 34 - random write		[128-byte blocks]
; 35 - get file size
; 36 - set FCB record size
; 38 - block random write
; 39 - block random read
; 42 - get date
; 44 - get hour

	org 0100h

	macro	SYSTEM, fun
	ld	c, fun
	call	5
	endm

	macro	PRINT, msg
	ld	de, msg
	SYSTEM	9
	endm

	PRINT	string		; function 9	
	SYSTEM	1		; function 1
	call	prtkey
	PRINT	strin3
	PRINT	strin4
	PRINT	strin1
loop6:	ld	e,0ffh
	SYSTEM	6		; function 6, input
	or	a
	jr	z,loop6
	push	af
	PRINT	strin2
	pop	af
	ld	e,a
	SYSTEM	6		; function 6, output
	PRINT	strin3
	PRINT	strin1
	SYSTEM	7		; function 7
	call	prtkey
	PRINT	strin3
	PRINT	strin4
	PRINT	strin1
	SYSTEM	8		; function 8
	call	prtkey
	PRINT	strin5
	ld	de,buff
	SYSTEM	10		; function 10
	PRINT	strin6
	ld	a,(buff+1)
	ld	l,a
	ld	h,0
	ld	de,buff+2
	add	hl,de
	ld	a,24h
	ld	(hl),a
	PRINT	buff+2
	ld	e,''''
	SYSTEM	2	
	ld	e,'.'
	SYSTEM	2
	PRINT	strin7
	SYSTEM	12		; function 12
	call	prthex
	PRINT	strin8
	SYSTEM	24		; function 24
	call	prthex
	PRINT	strin9
	SYSTEM	25		; function 25
	call	prthe1
	PRINT	strin10		; function 3
	SYSTEM	3
	PRINT	strin11		; function 4
	SYSTEM	4
	PRINT	strin12		; function 5
	SYSTEM	5
	PRINT	strin13		; function 27
	SYSTEM	27
	PRINT	strin14		; function 31
	SYSTEM	31
	PRINT	strin15		; function 36
	ld	de,fcb
	SYSTEM	36
	PRINT	strin16
	ld	de,fcb
	SYSTEM	22		; function 22
	or	a
	jp	nz,error
	ld	hl,astr
	ld	de,80h
	ld	bc,20
	ldir
	PRINT	strin17
	ld	de,fcb
	SYSTEM	21		; function 21
	or	a
	jp	nz,error
	PRINT	strin18
	ld	de,fcb
	SYSTEM	16		; function 16
	PRINT	strin19
	ld	hl,mybuf
	call	prthex
	ld	de,mybuf
	SYSTEM	26		; function 26
	PRINT	strin20
	ld	de,fcb
	SYSTEM	35		; function 35
	or	a
	jp	nz,error
	ld	hl,(fcb+33)
	call	prthex
	PRINT	strin21
	ld	de,fcb2
	SYSTEM	22
	or	a
	jp	nz,error
	PRINT	strin22
	ld	de,fcb
	SYSTEM	15		; function 15
	or	a
	jp	nz,error
	PRINT 	strin23
	ld	de,fcb
	SYSTEM	20		; function 20
	or	a
	jp	nz,error
	ld	de,fcb2
	SYSTEM	21
	or	a
	jp	nz,error
	ld	a,24h
	ld	(mybuf+20),a
	PRINT	mybuf
	ld	de,fcb2
	SYSTEM	16
	ld	de,fcb
	SYSTEM	16
	PRINT	strin24
	ld	de,fcbr
	SYSTEM	23		; function 23
	or	a
	jp	nz,error
	PRINT	strin25
	ld	de,fcbs
	SYSTEM	17		; function 17
	or	a
	jp	nz,error
	call	prtfile
ffnext:	PRINT	strin26
	ld	de,fcbs
	SYSTEM	18		; function 18
	or	a
	jp	nz,nnext
	call	prtfile
	jp	ffnext
nnext:	PRINT	strin27
	ld	de,fcb2
	SYSTEM	19		; function 19
	or	a
	jp	nz,error
	PRINT	strin16
	ld	de,fcb
	SYSTEM	22
	or	a
	jp	nz,error
	PRINT	strin28
	ld	a,48
filfil:	ld	(mybuf),a
	ld	hl,mybuf
	ld	de,mybuf+1
	ld	bc,127
	ldir
	push	af
	ld	de,fcb
	SYSTEM	21
	or	a
	jp	nz,error
	pop	af
	inc	a
	cp	58
	jp	nz,filfil
	ld	de,fcb
	SYSTEM	16
	PRINT	strin22
	ld	de,fcb
	SYSTEM	15
	or	a
	jp	nz,error
	PRINT	strin29
	ld	hl,9
	call	dmp		; function 33
	ld	hl,0
	call	dmp
	ld	hl,8
	call	dmp
	ld	hl,1
	call	dmp
	ld	hl,mybuf
	ld	de,mybuf+1
	ld	(hl),'A'
	ld	bc,127
	ldir
	PRINT	strin31
	ld	de,fcb
	ld	hl,2
	ld	(fcb+33),hl
	dec	hl
	dec	hl
	ld	(fcb+35),hl
	SYSTEM	34		; function 34
	or	a
	jp	nz,error
	PRINT	strin32
	ld	hl,mybuf
	ld	de,mybuf+1
	ld	(hl),'B'
	ld	bc,127
	ldir
	ld	de,64
	ld	(fcb+14),de
	ld	hl,1
	ld	(fcb+33),hl
	dec	hl
	ld	(fcb+35),hl
	ld	de,fcb
	ld	hl,2
	SYSTEM	38		; function 38
	or	a
	jp	nz,error
	ld	de,fcb
	SYSTEM	16
	ld	a,'*'
	ld	(mybuf+192),a
	PRINT	strin22
	ld	de,fcb
	SYSTEM	15
	ld	hl,2
	ld	(fcb+33),hl
	dec	hl
	dec	hl
	ld	(fcb+35),hl
	ld	hl,64
	ld	(fcb+14),hl
	ld	de,fcb
	ld	hl,3
	SYSTEM	39		; function 39
	or	a
	jp	nz,error
	PRINT	strin33
	ld	e,'*'
	SYSTEM	2	
	ld	hl,mybuf
	ld	bc,193
lop39:	ld	a,(hl)
	ld	e,a
	push	hl
	push	bc
	SYSTEM	2
	pop	bc
	pop	hl
	inc	hl
	djnz	lop39
	PRINT	strin34
	SYSTEM	42		; function 42
	push	hl
	push	de
	ld	a,e
	call	prthe1
	ld	e,'/'
	SYSTEM	2
	pop	de
	ld	a,d
	call	prthe1
	ld	e,'/'
	SYSTEM	2
	pop	hl
	call	prthex
	PRINT	strin35
	SYSTEM	44		; function 44
	push	de
	push	hl
	ld	a,h
	call	prthe1
	ld	e,':'
	SYSTEM	2
	pop	hl
	ld	a,l
	call	prthe1
	ld	e,':'
	SYSTEM	2
	pop	de
	ld	a,d
	call	prthe1
	PRINT	strin36
	SYSTEM	0			; function 0

dmp:	ld	(fcb+33),hl		; 128-bytes dump
	ld	hl,0
	ld	(fcb+35),hl
	ld	de,fcb
	SYSTEM	33
	or	a
	jp	nz,error
	ld	hl,mybuf
	ld	b,128
dmp1:	ld	a,(hl)
	ld	e,a
	push	hl
	push	bc
	SYSTEM	2
	pop	bc
	pop	hl
	inc	hl
	djnz	dmp1
	PRINT	strin30
	SYSTEM	1
	ret

error:	PRINT	errmsg
	SYSTEM	0		; function 0

prtfile:ld	hl,mybuf+1	; print filename in mybuf
	ld	b,8
prtf1:	push	bc
	push	hl
	ld	a,(hl)
	ld	e,a
	SYSTEM	2
	pop	hl
	pop	bc
	inc	hl
	djnz	prtf1
	ld	e,'.'
	SYSTEM	2
	ld	b,3
	ld	hl,mybuf+9
prtf2:	push	bc
	push	hl
	ld	a,(hl)
	ld	e,a
	SYSTEM	2
	pop	hl
	pop	bc
	inc	hl
	djnz	prtf2
	ld	e,0dh
	SYSTEM	2
	ld	e,0ah
	SYSTEM	2
	ret
		
prthex: ld	a,h		; print hex number in HL
	call	prthe1
	ld	a,l
	call	prthe1
	ret
prthe1: push	hl		; print hex byte in A
	push	af
	and	0F0h
	srl	a
	srl	a
	srl	a
	srl	a
	call	prthe2
	pop	af
	push	af
	and	0Fh
	call	prthe2
	pop	af
	pop	hl
	ret
prthe2: cp	10
	jr	c,prthe3
	add	a,7
prthe3: add	a,48
	ld	e,a
	SYSTEM	2
	ret
	
prtkey:	push	af
	PRINT	strin2
	pop	af
	ld	e,a
	SYSTEM	2		; function 2
	ret

errmsg: defm	" ERROR!"
	defb	0dh,0ah,0ah,24h
string: defm	"BDOSEMU tester"
	defb	0dh,0ah,0ah
	defm	"[fcn 9] Welcome to BDOSEMU tester."
	defb	0dh,0ah
strin1:	defm	"[fcn 1/6/7/8] Hit a key: $"
strin2: defb	0dh,0ah
	defm	"[fcn 2] You pressed key $"
strin3: defb	0dh,0ah
	defm	"[fcn 9] Let's try again."
	defb	0dh,0ah,24h
strin4: defm	"[fcn 6/8] You should not see the pressed key."
	defb	0dh,0ah,24h
strin5: defb	0dh,0ah
	defm	"[fcn 10] Now enter up to 20 chars:"
	defb	0dh,0ah,24h
strin6: defm	"[fcn 9] You entered '$"
strin7:	defb	0dh,0ah
	defm	"[fcn 12] BDOS version is $"
strin8:	defb	0dh,0ah
	defm	"[fcn 24] Drive vector is $"
strin9: defb	0dh,0ah
	defm	"[fcn 25] Default drive is $"
strin10:defb	0dh,0ah
	defm	"[fcn 3] No result$"
strin11:defb	0dh,0ah
	defm	"[fcn 4] No result$"
strin12:defb	0dh,0ah
	defm	"[fcn 5] No result$"
strin13:defb	0dh,0ah
	defm	"[fcn 27] No result$"
strin14:defb	0dh,0ah
	defm	"[fcn 31] No result$"
strin15:defb	0dh,0ah
	defm	"[fcn 36] Setting random record field in FCB$"
strin16:defb	0dh,0ah
	defm	"[fcn 22] Creating file 'A_FILE.TXT'...$"
strin17:defb	0dh,0ah
	defm	"[fcn 21] Writing 'Hello, I'm a string.' to file...$"
strin18:defb	0dh,0ah
	defm	"[fcn 16] Closing file.$"
strin19:defb	0dh,0ah
	defm	"[fcn 26] Changing DMA to $"
strin20:defb	0dh,0ah
	defm	"[fcn 35] 'A_FILE.TXT' size: $"
strin21:defb	0dh,0ah
	defm	"[fcn 22] Creating file 'O_FILE.TXT'...$"
strin22:defb	0dh,0ah
	defm	"[fcn 15] Opening file 'A_FILE.TXT'...$"
strin23:defb	0dh,0ah
	defm	"[fcn 20] Copying file 'A_FILE.TXT' to 'O_FILE.TXT':"
	defb	0dh,0ah,'*',24h
strin24:defb	'*',0dh,0ah
	defm	"[fcn 23] Renaming file 'A_FILE.TXT' to 'OTH_FILE.TXT'...$"
strin25:defb	0dh,0ah
	defm	"[fcn 17] First file *.TXT in this directory: $"
strin26:defm	"[fcn 18] Next file *.TXT in this directory: $"
strin27:defm	"(none)"
	defb	0dh,0ah
	defm	"[fcn 19] Erasing file 'O_FILE.TXT'...$"
strin28:defb	0dh,0ah
	defm	"[fcn 21] Writing to file...$"
strin29:defb	0dh,0ah
	defm	"[fcn 33] 128-bytes dump (9,0,8,1): "
	defb	0dh,0ah,'$'
strin30:defb	0dh,0ah
	defm	"[fcn 1] Hit any key to continue..."
	defb	0dh,0ah,'$'
strin31:defm	"[fcn 34] Changing file to 01A3456789...$"
strin32:defb	0dh,0ah
	defm	"[fcn 38] Changing file to 0BB1AA33445566778899...$"
strin33:defb	0dh,0ah
	defm	"[fcn 39] Records 2,3,4 are:"
	defb	0dh,0ah,'$'	
strin34:defb	0dh,0ah
	defm	"[fcn 42] Current date (hex): $"
strin35:defb	0dh,0ah
	defm	"[fcn 44] Current hour (hex): $"
strin36:defb	0dh,0ah
	defm	"[fcn 0] The end!"
	defb	0dh,0ah,'$'

buff:	defb	20,0
	defw	0,0,0,0,0,0,0,0,0,0
	defb	0
astr:	defm	"Hello, I'm a string."

fcb:	defb	0
	defm	"A_FILE  TXT"
	defw	0,0,0,0,0,0,0,0,0,0,0,0	
fcbr:	defb	0
	defm	"A_FILE  TXT"
	defb	0,0,0,0,0
	defm	"OTH_FILETXT"
	defw	0,0,0,0
fcb2:	defb	0
	defm	"O_FILE  TXT"
	defw	0,0,0,0,0,0,0,0,0,0,0,0	
fcbs:	defb	0
	defm	"????????TXT"
	defw	0,0,0,0,0,0,0,0,0,0,0,0

mybuf: