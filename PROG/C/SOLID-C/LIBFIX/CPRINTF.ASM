;int	cprintf(char *fmt, ...)

	cseg

putch@:	call	putch_##
	xor	a
	ret

cprintf_::
	ld	de,putch@
	ld	hl,00002h
	add	hl,sp
	jp	@spr@##
