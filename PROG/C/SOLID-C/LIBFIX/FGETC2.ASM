;	MODULE	FGETC2
;
;char	fgetc(FILE *stream)
;

	cseg

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

;	ENDMODULE
