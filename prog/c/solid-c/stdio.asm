	MODULE	FFLUSH

fflush_::
	xor	a
	ld	(?1),a
	push	hl
	pop	iy
	bit	1,(iy+1)
	ret	nz		;A == 0 !
	bit	7,(iy+0)	;_F_IN
	jr	z,.1
	ld	hl,0		;flushing input file: lseek file to curren position; invalidate buffer
	ld	e,(iy+2)
	ld	d,(iy+3)
	or	a
	sbc	hl,de
	ld	(?2),hl
	sbc	hl,hl
	ld	(?2+2),hl
	ld	de,?2
	ld	l,(iy+6)
	ld	h,0
	ld	bc,1
	push	iy
	call	_seek_##
	ld	(?1),a
	jr	.2
;
.1:	bit	0,(iy+1)	;flush output file
	jr	z,.2a		;file was changed?
	ld	l,(iy+6)	;FD
	ld	h,0
	ld	e,(iy+8)	;pointer to buffer start
	ld	d,(iy+9)
	ld	c,(iy+2)	;number of characters
	ld	b,(iy+3)
	push	iy
	push	bc
	call	write_##	;write buffered characters
	pop	bc
	or	a
	sbc	hl,bc		;Wrote all???
	jr	nc,.2
	ld	a,255
	ld	(?1),a
.2:	pop	iy
.2a:	xor	a
	ld	(iy+2),a	;no characters in buffer
	ld	(iy+3),a
	ld	a,(iy+8)	;set current ptr to buffer start
	ld	(iy+4),a
	ld	a,(iy+9)
	ld	(iy+5),a
	res	0,(iy+1)	;No pending characters for output
	res	7,(iy+0)	;No pending characters on input
	ld	a,(?1)		;Ok?
	or	a
	ret	z		;if not OK set error flag
	set	4,(iy+0)		;_F_ERR
	ret

	dseg
?1:	db	0
?2:	ds	4

	ENDMODULE


	MODULE	FGETPOS
fgetpos_::
	inc	hl
	bit	1,(hl)
	dec	hl
	jr	nz,@0
	push	de
	push	hl
	call	fflush_##
	pop	hl
	pop	de
	or	a
	jr	z,@1
@0:	ld	a,255
	ret
;
@1:	ld	bc,6
	add	hl,bc
	ld	l,(hl)
	ld	h,0
	jp	_tell_##
	ENDMODULE


	MODULE	FSETPOS

?12:	dw	0,0
rewind_::
	ld	de,?12
fsetpos_::
	inc	hl
	bit	1,(hl)
	dec	hl
	jr      nz,@2
	push	de
	push	hl
	call	fflush_##
	pop	hl
	pop	de
	or	a
	jr	z,@3
@2:	ld	a,255
	ret
;
@3:	res	5,(hl)
	ld	bc,6
	add	hl,bc
	ld	l,(hl)
	ld	h,0
	ld	bc,0
	jp	_seek_##
	ENDMODULE


	MODULE	CLEARERR

clearerr_::
	ld	a,(hl)
	and	207
	ld	(hl),a
	ret
	ENDMODULE


	MODULE	FHEAP
_fpheap_::
	ld	hl,_iob_
	ld	de,14
	ld	b,16
.1:	ld	a,(hl)
	inc	hl
	or	(hl)
	dec	hl
	ret	z
	add	hl,de
	djnz	.1
	ld	hl,0
	ret
	dseg
_iob_::	ds	16*14
	ENDMODULE


	MODULE	FOPEN2

fdopen_::
	push	hl
	push	de
	call	_fpheap_##
	pop	bc
	pop	de
	ld	a,h
	or	l		;Check if any FILE structs available
	ret	z
	push	hl
	pop	iy
	ex	de,hl
	ld	a,(bc)
	and	5Fh
	inc	bc
	push	bc
	cp	'R'
	jr	z,.10
	cp	'W'
	jr	z,.20
	cp	'A'
	jr	z,.30
	ld	hl,0
	ret
;
_fopen_::
	push	hl
	pop	iy	;FP
	xor	a
	ld	(iy+2),a
	ld	(iy+3),a
	ld	(iy+8),a
	ld	(iy+9),a
	ld	(iy+7),255
	ld	a,(bc)
	and	5Fh
	inc	bc
	cp	'R'
	jr	z,.1
	cp	'W'
	jr	z,.2
	cp	'A'
	jr	z,.3
	ld	hl,0
	ret
;
.1:	push	bc
	push	iy
	ex	de,hl
	ld	de,1
	call	open_##
	pop	iy
.10:	ld	(iy+6),l
	ld	(iy+7),h
	pop	bc
	set	0,(iy+0)
	jp	.4
;
.2:	push	bc
	push	iy
.21:	ex	de,hl
	ld	de,0
	call	creat_##
	pop	iy
.20:	ld	(iy+6),l
	ld	(iy+7),h
	pop	bc
	set	1,(iy+0)
	jp	.4
;
.3:	push	bc
	push	iy
	ex	de,hl
	ld	de,1
	push	hl
	call	open_##
	pop	de
	bit	7,h
	jr	z,.21
	pop	iy
.30:	ld	(iy+6),l
	ld	(iy+7),h
	pop	bc
	set	1,(iy+0)
	push	bc
	push	iy
	ld	l,(iy+6)
	ld	h,0
	ld	de,_0
	ld	bc,2
	call	_seek_##
	pop	iy
	pop	bc
	ld	a,(bc)
	cp	'b'
	jr	z,.4
	inc	bc
	ld	a,(bc)
	dec	bc
	cp	'b'
	jr	z,.4
	ld	de,_1
	push	bc
	push	iy
	ld	l,(iy+6)
	ld	h,0
	ld	bc,2
	push	hl
	call	_seek_##
	pop	hl
	ld	de,(0F34Dh)
	ld	bc,128
	call	read_##
	ld	a,l
	or	a
	jr	z,.310
	ld	c,a
	ld	b,0
	ld	a,1Ah
	ld	hl,(0F34Dh)
	cpir
	jr	nz,.310
	ld	hl,0
	or	a
	sbc	hl,bc
	ld	(_3),hl
	sbc	hl,hl
	ld	(_3+2),hl
	pop	iy
	push	iy
	ld	l,(iy+6)
	ld	h,0
	ld	de,_3
	ld	bc,2
	call	_seek_##
.310:	pop	iy
	pop	bc
.4:	ld	a,(bc)
	cp	'+'
	jr	nz,.5
	set	0,(iy+0)
	set	1,(iy+0)
	inc	bc
.5:	res	6,(iy+0)
	ld	a,(bc)
	cp	'b'
	jr	nz,.6
	set	6,(iy+0)
.6:	bit	7,(iy+7)
	jr	z,.7
	ld	hl,0
	ld	(iy+0),l
	ld	(iy+1),h
	ret
;
.7:	push	iy
	ld	l,(iy+6)
	ld	h,0
	call	isatty_##
	pop	hl
	or	a
	ret	z
	inc	hl
	set	1,(hl)	;TERM
	dec	hl
	ret

_0:	dw	0,0
_1:	dw	0FF80h,0FFFFh
	dseg
_3:	dw	0,0
	ret
	ENDMODULE


	MODULE	REOPEN

freopen_::
	ld	(?22),hl
	ld	l,c
	ld	h,b
	push	hl
	push	de
	call	fclose_##
	pop	bc
	ld	de,(?22)
	pop	hl
	jp	_fopen_##

	dseg
?22:	ds	2
	ENDMODULE



	MODULE	FOPEN
;
;
;
fopen_::
	push	hl
	push	de
	call	_fpheap_##
	pop	bc
	pop	de
	ld	a,l
	or	h
	ret	z
	jp	_fopen_##

	ENDMODULE


	MODULE	FCLOSE
;
;char	fclose(FILE *stream)
;
fclose_::
	ld	a,(hl)
	inc	hl
	or	(hl)
	dec	hl
	ret	z
	push	hl
	call	fflush_##
	ld	(?70),a
	pop	iy
	bit	1,(iy+1)
	push	iy
	jp	nz,@22
	ld	l,(iy+6)
	ld	h,(iy+7)
	call	close_##
	ld	hl,?70
	or	(hl)
	ld	(hl),a
@22:	pop	iy
	bit	2,(iy+0)
	ld	(iy+0),0
	ld	(iy+1),0
	jr	z,@23
	ld	l,(iy+8)
	ld	h,(iy+9)
	call	free_##
@23:	ld	a,(?70)
	ret

	dseg
?70:	ds	1

	ENDMODULE


	MODULE	GETS0

;char	*gets(char buf[255])

gets_::	push	ix
	push	hl
	ld	hl,(0F34Dh)
	ld	(hl),254
	inc	hl
	ld	(hl),0
	ld	de,(0F34Dh)
	ld	c,10
	call	5
	ld	e,13
	ld	c,2
	call	5
	ld	e,10
	ld	c,2
	call	5
	ld	hl,(0F34Dh)
	inc	hl
	ld	c,(hl)
	ld	b,0
	inc	hl
	push	hl
	add	hl,bc
	ld	(hl),0
	pop	de
	ld	a,(de)
	pop	hl
	pop	ix
	cp	26
	jp	nz,strcpy_##
	ld	hl,0
	ret

	ENDMODULE



	MODULE	FGETC1

;char _fgetc(FILE *p)

_fgetc_::
	push	hl
	pop	iy
	ld	a,(iy+0)
	and	48
	ld	c,a
	ld	a,(iy+1)
	and	1
	or	c
	jp	z,@45
@46:	ld	a,255
	ret
;
@45:	bit	0,(iy+0)
	jp	z,@46
	bit	1,(iy+1)
	jp	z,@47
	push	ix
	ld	c,1
	call	5
	pop	ix
	ret
;
@47:	ld	a,(iy+2)
	or	(iy+3)
	jp	nz,@48
	ld	a,(iy+8)
	or	(iy+9)
	jp	nz,@49
	push	iy
	ld	hl,512
	call	malloc_##
	pop	iy
	ld	(iy+8),l
	ld	(iy+9),h
	ld	a,l
	or	h
	jp	nz,@50
	set	4,(iy+0)
	jr	@46
;
@50:	set	2,(iy+0)
@49:	ld	e,(iy+8)
	ld	d,(iy+9)
	ld	(iy+4),e
	ld	(iy+5),d
	ld	l,(iy+6)
	ld	h,(iy+7)
	push	iy
	ld	bc,512
	call	read_##
	pop	iy
	ld	(iy+2),l
	ld	(iy+3),h
	ld	a,h
	or	l
	jp	nz,@48
	set	5,(iy+0)
	ld	(iy+2),0
	ld	(iy+3),0
	ld	a,255
	ret
;
@48:	set	7,(iy+0)
	ld	e,(iy+2)
	ld	d,(iy+3)
	dec	de
	ld	(iy+3),d
	ld	(iy+2),e
	ld	e,(iy+4)
	ld	d,(iy+5)
	ld	a,(de)
	inc	de
	ld	(iy+5),d
	ld	(iy+4),e
	ret

	ENDMODULE


	MODULE	UNGETC

;char	ungetc(char c, FILE *fp)

ungetc_::
	push	de
	pop	iy
	ld	(?132),a
	ld	a,255
	cp	l
	jp	z,@51
	ld	e,(iy+2)
	ld	d,(iy+3)
	inc	de
	ld	(iy+3),d
	ld	(iy+2),e
	ld	hl,1
	call	?cpshd##
	jp	nc,@52
	ld	a,(?132)
	ld	e,(iy+4)
	ld	d,(iy+5)
	dec	de
	ld	(iy+5),d
	ld	(iy+4),e
	ld	(de),a
	ret
;
@52:	ld	a,(iy+2)
	dec	a
	or	(iy+3)
	jp	nz,@53
	push	iy
	ld	hl,10
	pop	bc
	add	hl,bc
	ld	(iy+4),l
	ld	(iy+5),h
	ld	a,(?132)
	ld	(hl),a
	ret
;
@53:	ld	a,(iy+2)
	sub	1
	ld	(iy+2),a
	jr	nc,@51
	dec	(iy+3)
@51:	ld	a,-1
	ret

	dseg
?132:	ds	1

	ENDMODULE


	MODULE	FPUTC1
;
;char	fputc(char c, FILE *stream)
;
_fputc_::
	ld	(?139),a
	push	de
	pop	iy
	bit	1,(iy)
	jr	nz,@54
@55:	ld	a,255
	ret
;
@54:	bit	7,(iy)
	jr	nz,@55
	res	5,(iy)
	bit	1,(iy+1)	;TERM
	jp	z,@56
	ld	e,a
	ld	c,2
	push	ix
	push	af
	call	5
	pop	af
	pop	ix
	ret
;
@56:	ld	a,(iy+2)
	or	(iy+3)
	jp	nz,@57
	ld	a,(iy+8)
	or	(iy+9)
	jp	nz,@57
	ld	hl,512
	push	iy
	call	malloc_##
	pop	iy
	ld	(iy+8),l
	ld	(iy+9),h
	ld	a,l
	or	h
	jp	nz,@58
	set	4,(iy+0)
	jr	@55
;
@58:	set	2,(iy+0)
	ld	c,(iy+8)
	ld	b,(iy+9)
	ld	(iy+4),c
	ld	(iy+5),b
@57:	ld	e,(iy+4)
	ld	d,(iy+5)
	ld	a,(?139)
	ld	(de),a
	inc	de
	ld	(iy+5),d
	ld	(iy+4),e
	set	0,(iy+1)
	ld	l,(iy+2)
	ld	h,(iy+3)
	inc	hl
	ld	(iy+3),h
	ld	(iy+2),l
	bit	2,h
	jp	z,@59
	push	iy
	pop	hl
	call	fflush_##
	or	a
	jp	nz,@55
@59:	ld	a,(?139)
	ret

	dseg
?139:	ds	1

	ENDMODULE


	MODULE	FPUTC2

;char	fputc(char c, FILE *stream)

fputc_::ld	h,d
	ld	l,e
	bit	6,(hl)
	jp	nz,_fputc_##
	cp	10
	jp	nz,_fputc_##
	push	de
	ld	a,13
	call	_fputc_##
	pop	de
	cp	255
	ret	z
	ld	a,10
	jp	_fputc_##

	ENDMODULE


	MODULE	FGETC2
;
;char	fgetc(FILE *stream)
;
fgetc_::
	bit	6,(hl)
	jp	nz,_fgetc_##
@41:	push	hl
	call	_fgetc_##
	pop	hl
	cp	13
	jr	z,@41
	cp	1Ah
	ret	nz
@42:	set	5,(hl)
	push	hl
	inc	hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	de
	ld	(hl),d
	dec	hl
	ld	(hl),e
	inc	hl
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	dec	de
	ld	(hl),d
	dec	hl
	ld	(hl),e
	pop	hl
	jp	@41

	ENDMODULE


	MODULE	FGETS1
;
;char *fgets(char *s, int maxlen, FILE *stream)
;
fgets_::
	ld	(?105),bc
	ld	(?103),hl
	ld	(?104),de
	ld	(?107),hl
@39:	ld	hl,(?104)
	dec	hl
	ld	(?104),hl
	ex	de,hl
	ld	hl,0
	call	?cpshd##
	jp	nc,@38
	ld	hl,(?105)
	call	fgetc_##
	ld	(?106),a
	inc	a
	jp	z,@38
	ld	a,l
	ld	hl,(?107)
	ld	(hl),a
	inc	hl
	ld	(?107),hl
	cp	10
	jp	nz,@39
@38:	xor	a
	ld	de,(?107)
	ld	(de),a
	ld	a,(?106)
	inc	a
	jp	nz,@40
	ld	hl,(?103)
	ld	a,e
	cp	l
	jr	nz,@40
	ld	a,d
	cp	h
	jr	nz,@40
	ld	hl,0
	ret
;
@40:	ld	hl,(?103)
	ret

	dseg
?103:	ds	2
?104:	ds	2
?105:	ds	2
?106:	ds	1
?107:	ds	2

	ENDMODULE


	MODULE	PUTS
;
;	put string to <stdout>
;
puts_::	ld	a,(hl)
	or	a
	ret	z
	inc	hl
	push	hl
	call	putc_##
	pop	hl
	jp	puts_

	ENDMODULE


	MODULE	FWRITE
;
;	write a block to file
;
fwrite_::
	push	ix
	ld	ix,0
	add	ix,sp
	ld	(?87),de
	ld	(?88),bc
	ld	(?86),hl
	ld	hl,0
	ld	(?91),hl
@34:	ld	hl,(?88)
	dec	hl
	ld	(?88),hl
	inc	hl
	ld	a,l
	or	h
	jr	z,@30
	ld	hl,(?87)
	ld	(?90),hl
@32:	ld	hl,(?90)
	dec	hl
	ld	(?90),hl
	inc	hl
	ld	a,l
	or	h
	jr	z,@31
	ld	hl,(?86)
	ld	a,(hl)
	inc	hl
	ld	(?86),hl
	ld	e,(ix+4)
	ld	d,(ix+5)
	call	_fputc_##
	ld	a,l
	and	h
	inc	a
	jp	nz,@32
@30:	ld	hl,(?91)
@33:	ld	sp,ix
	pop	ix
	ret
;
@31:	ld	hl,(?91)
	inc	hl
	ld	(?91),hl
	jp	@34
;

	dseg
?90:	ds	2
?91:	ds	2
?86:	ds	2
?87:	ds	2
?88:	ds	2

	ENDMODULE


	MODULE	FREAD
;
;	Read a file
;

fread_::push	ix
	ld	ix,0
	add	ix,sp
	ld	(?75),de
	ld	(?76),bc
	ld	(?74),hl
	ld	hl,0
	ld	(?79),hl
@29:	ld	hl,(?76)
	dec	hl
	ld	(?76),hl
	inc	hl
	ld	a,l
	or	h
	jr	z,@24
	ld	hl,(?75)
	ld	(?78),hl
@28:	ld	hl,(?78)
	dec	hl
	ld	(?78),hl
	inc	hl
	ld	a,l
	or	h
	jr	z,@25
	ld	l,(ix+4)
	ld	h,(ix+5)
	call	_fgetc_##
	ld	(?80),a
	inc	a
	jp	nz,@26
@24:	ld	hl,(?79)
@27:	ld	sp,ix
	pop	ix
	ret
;
@26:	ld	a,(?80)
	ld	hl,(?74)
	ld	(hl),a
	inc	hl
	ld	(?74),hl
	jp	@28
;
@25:	ld	hl,(?79)
	inc	hl
	ld	(?79),hl
	jp	@29


	dseg
?78:	ds	2
?79:	ds	2
?80:	ds	1
?74:	ds	2
?75:	ds	2
?76:	ds	2
	cseg

	ENDMODULE



	MODULE	ROOT2
;
;	C root module - open stdio	-- DOS1, DOS2 & MISIX
;
_main_::xor	a
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
	ld	hl,0
;
exit_::	push	hl
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
	ret
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
	ENDMODULE
