; push long word relative to frame ptr IX (offset in HL)

	psect	text
	global	push_long
	
push_long:
	pop	de	; retaddr
	push	ix
	pop	bc
	add	hl,bc
	inc	hl
	inc	hl
	inc	hl
	ld	b,(hl)	; hi byte
	dec	hl
	ld	c,(hl)
	dec	hl
	push	bc
	ld	b,(hl)
	dec	hl
	ld	c,(hl)
	push	bc
	ex	de,hl
	jp	(hl)
