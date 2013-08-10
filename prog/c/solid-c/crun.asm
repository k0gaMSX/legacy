	MODULE LAUHL
?lauhl::pop	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	push	hl
	ex	de,hl
?laut::	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	ret
	ENDMODULE



	MODULE	SAUHL
?sauhl::ex	(sp),hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ex	(sp),hl
?saut::	ex	de,hl
	add	hl,sp
	ld	(hl),e
	inc	hl
	ld	(hl),d
	ex	de,hl
	ret
	ENDMODULE


	MODULE	MULHD
?mulhd::
	ld	a,h
	ld	c,l
	ld	hl,0
	ld	b,16
?01:	add	hl,hl
	rl	c
	rla
	jr	nc,?02
	add	hl,de
?02:	djnz	?01
	ret
	ENDMODULE


	MODULE	MULAB
?mulab::
	ld	h,a
	xor	a
	ld	l,b
	ld	b,8
?11:	add	a,a
	rl	h
	jr	nc,?12
	add	a,l
?12:	djnz	?11
	ret
	ENDMODULE


	MODULE	DVNHD
?dvnhd::
	ld	b,d
	ld	c,e
	ld	de,0
	ld	a,16
?21:	ex	af,af'

	add	hl,hl
	rl	e
	rl	d
	jr	c,?22
	ld	a,e
	sub	c
	ld	a,d
	sbc	a,b
	jr	c,?23
?22:
	or	a
	ex	de,hl
	sbc	hl,bc
	ex	de,hl
	inc	l
?23:
	ex	af,af'
	dec	a
	jp	nz,?21
	ret
	ENDMODULE


	MODULE	ABSNEG
abs_::
?abshl::
	bit	7,h
	ret	z
?neghl::
	dec	hl
?nothl::ld	a,l
	cpl
	ld	l,a
	ld	a,h
	cpl
	ld	h,a
	ret
	ENDMODULE


	MODULE	DVIHD
?dvihd::
	ld	a,h
	or	a
	push	af	;reminder's sign
	xor	d
	push	af	;quotient's sign
	call	?abshl##
	ex	de,hl
	call	?abshl##
	ex	de,hl
	call	?dvnhd##
	pop	af
	call	m,?neghl##
	pop	af
	ret	p
	xor	a
	sub	e
	ld	e,a
	ld	a,0
	sbc	a,d
	ld	d,a
	ret
	ENDMODULE


	MODULE	DVBAB
?dvbab::
	ld	l,a
	ld	h,b
	xor	a
	ld	b,8
?41:	sla	l
	rla
	jr	c,?42
	cp	h
	jr	c,?43
?42:	sub	h
	inc	l
?43:	djnz	?41
	ld	b,a
	ld	a,l
	ret
	ENDMODULE


	MODULE	SLHB
?slhb::	inc	b
	dec	b
	ret	z
?51:	add	hl,hl
	djnz	?51
	ret
	ENDMODULE


	MODULE	SLAB
?slab::	inc	b
	dec	b
	ret	z
?61:	add	a,a
	djnz	?61
	ret
	ENDMODULE


	MODULE	SRNHB
?srnhb::inc	b
	dec	b
	ret	z
?71:	srl	h
	rr	l
	djnz	?71
	ret
	ENDMODULE


	MODULE	SRIHB
?srihb::inc	b
	dec	b
	ret	z
?81:	sra	h
	rr	l
	djnz	?81
	ret
	ENDMODULE


	MODULE SRAB
?srab::	inc	b
	dec	b
	ret	z
?91:	srl	a
	djnz	?91
	ret
	ENDMODULE


	MODULE CPSHD
?cpshd::
	ld	a,h
	xor	d
	jp	p,?101
	ld	a,d
	cp	h
	ret
?101:
	ld	a,h
	cp	d
	ret	nz
	ld	a,l
	cp	e
	ret
	ENDMODULE


	MODULE	XDOS
bdosh_::
bdos_::	ld	h,b
	ld	l,c
	ld	c,a
	push	ix
	call	5
	pop	ix
	ret
	ENDMODULE


	MODULE	PUTC
putc_::	push	ix
	ld	e,a
	cp	10
	jr	nz,.1
	ld	e,13
	ld	c,2
	call	5
	ld	e,10
.1:	ld	c,2
	call	5
	pop	ix
	ret
	ENDMODULE


	MODULE	PUTS
puts_::	ld	a,(hl)
	or	a
	ret	z
	push	hl
	call	putc_##
	pop	hl
	inc	hl
	jr	puts_
	ENDMODULE


	MODULE	BRK
sbrk_::	ld	de,($MEMRY)
	add	hl,de
	call	brk_
	ld	a,h
	and	l
	inc	a
	ret	z
	ex	de,hl
	ret
brk_::	push	hl
	inc	h
	inc	h
	or	a
	sbc	hl,sp
	pop	hl
	jr	nc,brkerr
	ld	($MEMRY),hl
	ret
;
brkerr:	ld	hl,0FFFFh
	ret

$MEMRY::ds	2
	ENDMODULE


	MODULE	setjmp
;
;	int	setjmp(jmp_buf jb)
;
setjmp_::
	push	ix
	pop	bc
	push	hl
	pop	iy
	ld	hl,2
	add	hl,sp
	ld	(iy+0),l	;SP value
	ld	(iy+1),h
	ld	(iy+2),c
	ld	(iy+3),b
	pop	hl
	ld	(iy+4),l
	ld	(iy+5),h
	push	hl
	ld	hl,0
	ret
;
;	void	longjmp(jmp_buf jb, int retval)
;
longjmp_::
	push	hl
	pop	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	ld	c,(iy+2)
	ld	b,(iy+3)
	ld	sp,hl
	ld	l,(iy+4)
	ld	h,(iy+5)
	push	hl
	push	bc
	pop	ix
	ex	de,hl
	ld	a,h
	or	l
	ret	nz
	inc	hl
	ret
	ENDMODULE
