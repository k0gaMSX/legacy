	cseg

mk_num:	ld	(_base),a
	ld	(_chars),bc
	ld	a,32
	ld	(_base+1),a
	exx
	ld	hl,number
	exx
	call	mn0
	exx
	ld	(hl),0
	exx
	ld	hl,number
	ld	a,(sign)
	or	a
	ret	z
	dec	hl
	ret
;------------------------------------	
mn0:	ld	bc,(_base)
	xor	a
mn1:	add	hl,hl
	rl	e
	rl	d
	rla
	cp	c
	jr	c,mn2
	sub	c
	inc	l
mn2:	djnz	mn1
;				DEHL-quot; A-rem
	push	af
	ld	a,d
	or	e
	or	h
	or	l
	call	nz,mn0
	pop	af
	push	hl
	ld	hl,(_chars)
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	a,(hl)
	pop	hl
	exx
	ld	(hl),a
	inc	hl
	exx
	ret
;-------------------------------------------
scan_length:
	xor	a
	ld	(flong),a
	ld	(fladj),a
	ld	(flen+0),a	;make length = 0
	ld	(flen+1),a
	ld	a,' '
	ld	(padch),a	;space padding by default
	ld	a,(hl)
	cp	'-'
	jr	nz,sl1
	ld	(fladj),a	;all will be LEFT adjusted, not right
	inc	hl
sl1:	ld	a,(hl)
	cp	'0'
	jr	nz,sl2
	ld	a,(fladj)
	or	a
	jr	nz,sl1a
	ld	a,'0'
	ld	(padch),a	;pad numbers with '0's, not spaces
sl1a:	inc	hl
sl2:	ld	de,0
sl2a:	ld	a,(hl)
	sub	'0'
	jr	c,sl3
	cp	10
	jr	nc,sl3
	ex	de,hl
	ld	c,l
	ld	b,h
	add	hl,hl
	add	hl,hl
	add	hl,bc
	add	hl,hl
	ld	b,0
	ld	c,a
	add	hl,bc
	ex	de,hl
	inc	hl
	jr	sl2a
;
sl3:	ld	(flen),de	;set explicit length
	ld	a,(hl)
	cp	'l'
	jr	z,sl4
	cp	'L'
	ret	nz
sl4:	ld	(flong),a
	inc	hl
	ret
;--------------------------------------------
_pad:	dec	hl
	bit	7,h
	ret	nz
	push	hl
	ld	a,(padch)
	call	outch
	pop	hl
	jp	_pad
;--------------------------------------------	

;int	@spr@(char *fmt,char (* callback)(), int param)

@spr@::	ld	(outch+4),bc	;optional parameter
	ld	(outch+7),de	;callback pointer
	push	hl
	pop	iy		;at (iy+2) we have current parameter
	ld	l,(iy+0)	;at iy we have pointer to format string
	ld	h,(iy+1)
.1:	ld	a,(hl)
	inc	hl
	or	a
	jr	z,.2
	cp	'%'
	jr	z,.3
.4:	call	outch
	jp	.1
;
.2:	ld	hl,(nprtd)
	ret
;
.3:	ld	a,(hl)
	inc	hl
	cp	'%'
	jr	z,.4
	dec	hl
	call	scan_length	;scan [-][0][0-9*][lL]
	ld	a,(hl)
	inc	hl
	cp	'c'
	jp	z,prt_c
	cp	'C'
	jp	z,prt_c		;print single character
	cp	'd'
        jp	z,prt_d
	cp	'D'
	jp	z,prt_d
	cp	'u'
	jp	z,prt_u
	cp	'U'
	jp	z,prt_u
	cp	'o'
	jp	z,prt_o
	cp	'O'
	jp	z,prt_o
	cp	'x'
	jp	z,prt_x1
	cp	'X'
	jp	z,prt_x2
	cp	's'
	jp	z,prt_s
	cp	'S'
	jp	z,prt_s
	jp	.1
;
prt_c:	ld	a,(iy+2)
	call	outch
prt_q:	ld	de,(nprtd)
	inc	de
	ld	(nprtd),de
	inc	iy
	inc	iy
	ld	a,(flong)
	or	a
	jp	z,.1
	inc	iy
	inc	iy
	jp	.1
;
prt_s:	ld	a,' '
	ld	(padch),a
	push	hl
	push	iy
	ld	l,(iy+2)
	ld	h,(iy+3)
fmt0:	push	hl
	call	strlen_##
	ex	de,hl
	ld	hl,(flen)
	or	a
	sbc	hl,de
	ld	(flen),hl
	ld	a,(fladj)
	or	a
	call	z,_pad
	pop	hl
fmt1:	ld	a,(hl)
	inc	hl
	or	a
	jr	z,fmt2
	call	outch
	jp	fmt1
fmt2:	ld	hl,(fladj)
	ld	a,(flen)
	or	a
	call	nz,_pad
	pop	iy
	pop	hl
	jp	prt_q
;
prt_u:	push	hl
	push	iy
	call	getnum
	jr	fmt4
;
prt_d:	push	hl
	push	iy
	call	getnum
	ld	a,(flong)
	or	a
	jr	nz,fmt3
	bit	7,h
	jr	z,fmt3
	ld	de,0FFFFh
fmt3:	bit	7,d
	jr	z,fmt4
	ld	a,'-'
	ld	(sign),a
	xor	a
	sub	l
	ld	l,a
	ld	a,0
	sbc	a,h
	ld	h,a
	ld	a,0
	sbc	a,e
	ld	e,a
	ld	a,0
	sbc	a,d
	ld	d,a
fmt4:	ld	a,10
	ld	bc,char1
	call	mk_num
	jp	fmt0
;
prt_o:	push	hl
	push	iy
	call	getnum
	ld	a,8
	ld	bc,char1
	call	mk_num
	jp	fmt0
;
prt_x2:	push	hl
	push	iy
	call	getnum
	ld	a,16
	ld	bc,char1
	call	mk_num
	jp	fmt0
;
prt_x1:	push	hl
	push	iy
	call	getnum
	ld	a,16
	ld	bc,char2
	call	mk_num
	jp	fmt0
;---------------------------------------
getnum:	xor	a
	ld	(sign),a
	ld	l,(iy+2)
	ld	h,(iy+3)
	ld	a,(flong)
	or	a
	jr	z,gnu1
	ld	e,(iy+4)
	ld	d,(iy+5)
	ret
gnu1:	ld	de,0
	ret
;---------------------------------------
outch:	push	hl
	push	iy
	ld	de,0
	call	0
	or	a
	jr	z,och1
	ld	hl,8000h
	ld	(nprtd),hl
och1:	pop	iy
	pop	hl
	ret

char1:	db	'0123456789ABCDEF'
char2:	db	'0123456789abcdef'

	dseg
_chars:	ds	2
_base:	ds	2
nprtd:	ds	2
flen:	dw	0
fladj:	db	0
flong:	db	0
padch:	db	' '
;
sign:	db	0
number:	ds	16

