;int	fprintf(FILE *stream, char *fmt, ...)

	cseg

fprintf_::
	pop	hl
	pop	bc
	push	bc
	push	hl
	ld	de,@fputc##
	ld	hl,00004h
	add	hl,sp
	jp	@spr@##
