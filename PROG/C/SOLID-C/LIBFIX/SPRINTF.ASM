;int	sprintf(char *buff, char *fmt, ...)

	cseg

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
