	MODULE	FRMTS

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
	ld	a,8
	ld	bc,char1
	call	mk_num
	jp	fmt0
;
prt_x1:	push	hl
	push	iy
	call	getnum
	ld	a,8
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

	ENDMODULE

	MODULE XFPUTC
@fputc::
	call	fputc_##
	inc	a
	ld	hl,-1
	ret	z
	dec	hl
	ret
	ENDMODULE


	MODULE	PRINTF

;int	printf(char *fmt, ...)

printf_::
	ld	bc,_iob_##+14
	ld	de,@fputc##
	ld	hl,00002h
	add	hl,sp
	jp	@spr@##
	ENDMODULE


	MODULE FPRINTF

;int	fprintf(FILE *stream, char *fmt, ...)

fprintf_::
	pop	hl
	pop	bc
	push	bc
	push	hl
	ld	de,@fputc##
	ld	hl,00004h
	add	hl,sp
	jp	@spr@##
	ENDMODULE


	MODULE CPRINTF

;int	cprintf(char *fmt, ...)

putch@:	call	putch_##
	xor	a
	ret

cprintf_::
	ld	de,putch@
	ld	hl,00002h
	add	hl,sp
	jp	@spr@##
	ENDMODULE


	MODULE SPRINTF

;int	sprintf(char *buff, char *fmt, ...)

@sspr@:	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	(de),a
	inc	de
	ld	(hl),d
	dec	hl
	ld	(hl),e
	ret

sprintf_::
	ld	hl,2
	add	hl,sp
	ld	c,l
	ld	b,h
	ld	de,@sspr@
	ld	hl,4
	add	hl,sp
	call	@spr@##
	pop	bc
	pop	hl
	ld	(hl),0
	push	hl
	push	bc
	ret
	ENDMODULE


	MODULE XXSCN

@igs@:	ex	de,hl
@41:	ld	l,e
	ld	h,d
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	a,(hl)
	cp	020h
	jr	z,@40
	cp	009h
	jr	z,@40
	cp	00Ah
	ret	nz
@40:
	ld	l,e
	ld	h,d
	push	de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	de
	ld	(hl),d
	dec	hl
	ld	(hl),e
	pop	de
	jr	@41
	DSEG
?90:	DS	1
	CSEG
@bc@:
	ld	hl,?90
	ld	(hl),e
	call	toupper_##
	cp	041h
	jr	c,@42
	cp	05Bh
	jr	c,@43
@42:
	cp	061h
	jr	c,@44
	cp	07Bh
	jr	c,@43
@44:
	cp	05Fh
	jr	nz,@45
@43:
	sub	037h
	jr	@46
@45:
	cp	030h
	jr	c,@47
	cp	03Ah
	jr	nc,@47
	sub	030h
	jr	@46
@47:
	ld	hl,0FFFFh
	ret
@46:
	ld	hl,(?90)
	cp	l
	jr	c,@48
	ld	a,0FFh
@48:
	ld	l,a
	ld	h,000h
	ret
	DSEG
?95:	DS	2
?99:	DS	2
?100:	DS	1
?101:	DS	1
?102:	DS	1
?103:	DS	2
?104:	DS	2
?105:	DS	2
	CSEG
_scn_::
	ld	(?95),hl
	ld	hl,(?95)
	ld	(?95),hl
	inc	de
	inc	de
	ld	hl,0FFFEh
	add	hl,de
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	(?99),hl
	ld	l,e
	ld	h,d
	ld	(?105),hl
	xor	a
	ld	(?102),a
@50:
	ld	hl,(?99)
	ld	a,(hl)
	inc	hl
	ld	(?99),hl
	or	a
	jp	z,@49
	cp	020h
	jr	z,@50
	cp	009h
	jr	z,@50
	cp	00Ah
	jr	z,@50
	cp	025h
	jp	nz,@51
	push	hl
	ld	hl,00001h
	ld	(?103),hl
	ld	a,00Ah
	ld	(?101),a
	ld	a,001h
	ld	(?100),a
	pop	hl
	ld	a,(hl)
	inc	hl
	ld	(?99),hl
	cp	02Ah
	jr	nz,@52
	xor	a
	ld	(?100),a
	ld	a,(hl)
	inc	hl
	ld	(?99),hl
@52:
	call	toupper_##
	cp	058h
	jr	z,@53
	cp	04Fh
	jr	z,@54
	cp	044h
	jr	z,@55
	cp	055h
	jr	z,@56
	cp	053h
	jp	z,@57
	cp	043h
	jp	z,@58
	jp	@59
@53:
	ld	a,010h
	ld	(?101),a
	jr	@56
@54:
	ld	a,008h
	ld	(?101),a
	jr	@56
@55:
	ld	hl,?95
	call	@igs@
	cp	02Dh
	jr	nz,@56
	ld	hl,0FFFFh
	ld	(?103),hl
	ld	hl,(?95)
	inc	hl
	ld	(?95),hl
@56:
	ld	hl,00000h
	ld	(?104),hl
	ld	hl,?95
	call	@igs@
	push	af
	ld	a,(?101)
	ld	e,a
	pop	af
	call	@bc@
	ld	a,l
	and	h
	inc	a
	jr	nz,@60
	ld	hl,(?102)
	ld	h,000h
	ret
@60:
	ld	a,(?101)
	ld	e,a
	push	af
	ld	hl,(?95)
	ld	a,(hl)
	inc	hl
	ld	(?95),hl
	call	@bc@
	ld	a,l
	pop	de
	ld	e,d
	cp	0FFh
	jr	z,@61
	push	af
	ld	d,000h
	ld	hl,(?104)
	call	?MULHD##
	pop	de
	ld	e,d
	ld	d,000h
	add	hl,de
	ld	(?104),hl
	jr	@60
@61:
	ld	hl,(?95)
	dec	hl
	ld	(?95),hl
	jp	@62
@57:
	ld	hl,?95
	call	@igs@
	ld	hl,(?105)
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
@65:
	ld	hl,(?95)
	ld	a,(hl)
	inc	hl
	ld	(?95),hl
	ld	e,a
	inc	e
	dec	e
	jr	z,@63
	ld	hl,(?99)
	ld	a,(hl)
	cp	e
	jr	nz,@64
	inc	hl
	ld	(?99),hl
	jr	@63
@64:
	ld	a,(?100)
	or	a
	jr	z,@65
	ld	a,e
	ld	(bc),A
	inc	bc
	jr	@65
@63:
	ld	hl,?100
	ld	e,(hl)
	inc	e
	dec	e
	jp	z,@50
	ld	hl,(?102)
	inc	l
	ld	a,l
	ld	(?102),a
	xor	a
	ld	(bc),A
	ld	hl,(?105)
	inc	hl
	inc	hl
	ld	(?105),hl
	jp	@50
@58:
	ld	hl,?100
	ld	e,(hl)
	inc	e
	dec	e
	jr	z,@66
	ld	hl,(?95)
	ld	a,(hl)
	ld	hl,(?105)
	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	(?105),hl
	ld	(bc),A
	ld	hl,(?102)
	inc	l
	ld	a,l
	ld	(?102),a
@66:
	ld	hl,(?95)
	inc	hl
	ld	(?95),hl
	jp	@50
@59:
	ld	hl,(?102)
	ld	h,000h
	ret
@62:
	ld	a,(?100)
	or	a
	jr	z,@51
	ld	hl,(?103)
	ex	de,hl
	ld	hl,(?104)
	call	?MULHD##
	ex	de,hl
	ld	hl,(?105)
	inc	hl
	inc	hl
	ld	(?105),hl
	dec	hl
	dec	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ld	hl,(?102)
	inc	l
	ld	a,l
	ld	(?102),a
@51:
	ld	hl,(?95)
	ld	a,(hl)
	or	a
	jp	nz,@50
	ld	hl,(?102)
	ld	h,000h
	ret
@49:
	ld	hl,(?102)
	ld	h,000h
	ret
	ENDMODULE



	MODULE SCANF

;int	scanf(char *fmt, ...)

scanf_::
	ld	(?133),hl
	ld	hl,0FF80h
	add	hl,sp
	ld	sp,hl
	ld	hl,(?133)
	ld	de,0007Fh
	ld	hl,00000h
	add	hl,sp
	call	gets_##
	ld	hl,00082h
	add	hl,sp
	ex	de,hl
	ld	hl,00000h
	add	hl,sp
	call	_scn_##
	ex	de,hl
	ld	hl,00080h
	add	hl,sp
	ld	sp,hl
	ex	de,hl
	ret

	dseg
?133:	DS	2
	ENDMODULE


	MODULE FSCANF

;int	fscanf(FILE *stream, char *fmt, ...)

fscanf_::
	ld	(?137),hl
	ld	hl,0FF80h
	add	hl,sp
	ld	sp,hl
	ld	hl,(?137)
	call	?LAUHL##
	DW	130+2
	ld	c,l
	ld	b,h
	ld	de,0007Fh
	ld	hl,00000h
	add	hl,sp
	call	fgets_##
	ld	a,l
	or	h
	jr	nz,@67
	ld	hl,-1
	jr	@68
;
@67:	ld	hl,00084h
	add	hl,sp
	ex	de,hl
	ld	hl,00000h
	add	hl,sp
	call	_scn_##
@68:	ex	de,hl
	ld	hl,128
	add	hl,sp
	ld	sp,hl
	ex	de,hl
	ret

	dseg
?137:	DS	2

	ENDMODULE


	MODULE SSCANF

;int	sscanf(char *str, char *fmt, ...)

sscanf_::
	ld	hl,2
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ex	de,hl
	JP	_scn_##

	ENDMODULE

