;int	printf(char *fmt, ...)

	cseg

printf_::
	ld	bc,_iob_##+14
	ld	de,@fputc##
	ld	hl,00002h
	add	hl,sp
	jp	@spr@##
