;	MODULE	FGETC1

;char _fgetc(FILE *p)

	cseg

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
@45:
	bit	0,(iy+0)
	jp	z,@46
	bit	1,(iy+1)
	jp	z,@47
	push	ix
	ld	c,1		;tty
	call	5
	pop	ix
	cp	13		;Bug fix by Tatsu
	ret	nz
	ld	a,10
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

;	ENDMODULE
