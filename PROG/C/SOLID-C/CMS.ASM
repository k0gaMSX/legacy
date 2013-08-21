;›››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››
;
;			C LIBRARY FOR SOLID C compiler
;			Root module
;
;›››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››››

	.Z80

	cseg

	db	'SOLID C 1.00',0

xmain::	ld	sp,(6)
	ld	c,0Ch
	call	5
	cp	5
	jr	nz,.2
	ld	a,2
	ld	(_os_ver_),a
	ld	(_mx_ver_),de	;MISIX core version
	jr	.1
;
.2:	ld	bc,006Fh
	call	5
	ld	a,b
	cp	2
	jr	c,.3
	ld	a,1
	ld	(_os_ver_),a
	jr	.1
;
.3:	ld	hl,0F2B9h
	ld	de,5Ch
	ld	b,8
	ld	(_argv_),de
.91:	ld	a,(hl)
	cp	' '
	jr	z,.92
	ld	(de),a
	inc	hl
	inc	de
	djnz	.91
.92:	xor	a
	ld	(de),a
	ld	hl,38*16
	call	sbrk_##		;allocate 16 FCBs for DOS1
	ld	(?fio),hl
	ld	d,h
	ld	e,l
	inc	de
	ld	bc,38*16
	ld	(hl),0FFh
	push	hl
	ldir
	pop	hl
	call	opencon
	ld	de,38
	add	hl,de
	call	opencon
	ld	de,38
	add	hl,de
	call	opencon
.1:	call	setargv_##
	ld	de,_argv_##
	call	_main_##
abort_::
_exit_::ld	a,(_os_ver_)
	or	a
	jp	z,0		;DOS1 - no return code set
	dec	a
	jr	z,d2exit
	ld	e,l		;MISIX - set code and exit
	ld	d,1
	ld	c,34h
	call	5
	rst	0
;
d2exit:	ld	b,l		;DOS2 - terminate with error code
	ld	c,62h
	jp	5
;
opencon:push	hl
	ex	de,hl
	push	de
	ld	hl,$$con
	ld	bc,13
	ldir
	pop	de
	push	de
	ld	c,0Fh
	call	5
	pop	ix
	ld	(ix+14),1
	ld	(ix+15),0
	pop	hl
	ret
;
$$con:	db	0,'CON        ',0

	DSEG
_mx_ver_::
	dw	0
_os_ver_::
	dw	0		;0 -> MSXDOS 1.X, 1-> DOS2, 2->MISIX
?fio::	dw	0

	END
