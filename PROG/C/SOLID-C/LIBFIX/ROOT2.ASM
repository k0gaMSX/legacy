;
;	C root module - open stdio	-- DOS1, DOS2 & MISIX
;
	cseg

_main_::
	xor	a
	ld	(atxcnt),a
	push	de
	push	hl
	ld	hl,fclosall_
	call	atexit_
	ld	de,$_r
	ld	hl,0
	call	fdopen_##	;open stdin
	ld	de,$_w
	ld	hl,1
	call	fdopen_##	;open stdout
	ld	de,$_w
	ld	hl,2
	call	fdopen_##	;open stderr
	pop	hl
	pop	de
;
	call	main_##
;	ld	hl,0
;
exit_::
	push	hl
.2:	ld	a,(atxcnt)
	dec	a
	jp	m,.1
	ld	(atxcnt),a
	ld	l,a
	ld	h,0
	add	hl,hl
	ld	de,atxtab
	add	hl,de
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	de,.2
	push	de
	jp	(hl)
.1:	pop	hl
	jp	_exit_##	;Buf fix by Tatsu
;	ret	Stack level is unknoun
;
atexit_::
	ld	a,(atxcnt)
	inc	a
	cp	20
	ret	nc
	ld	(atxcnt),a
	ex	de,hl
	ld	l,a
	ld	h,0
	add	hl,hl
	ld	bc,atxtab-2
	add	hl,bc
	ld	(hl),e
	inc	hl
	ld	(hl),d
	xor	a
	ret
;
fclosall_::
	ld	hl,_iob_##
	ld	b,16
.fca:	push	hl
	push	bc
	call	fclose_##
	pop	bc
	pop	hl
	ld	de,14
	add	hl,de
	djnz	.fca
	ret
;
$_r:	db	'R',0
$_w:	db	'W',0
;
	DSEG
;
atxcnt:	db	0
atxtab:	ds	40
