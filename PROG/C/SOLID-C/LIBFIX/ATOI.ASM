;	MODULE	atoi

	CSEG
atoi_::
	ex	de,hl
	xor	a
	ld	(?2),a
	ld	h,a
	ld	l,a
	ld	a,(de)
	cp	02Dh	;(de) is '-' ?
	jr	z,@0
	cp	02Bh	;(de) us '+' ?
	jr	z,@1
	jr	@2
@0:
	ld	a,001h
	ld	(?2),a
@1:
	inc	de
@2:
	ld	a,(de)		;'0' - '9'?
	cp	030h
	jr	c,@3
	ld	a,(de)
	cp	03Ah
	jr	nc,@3
	add	hl,hl
	ld	c,l
	ld	b,h
	add	hl,hl
	add	hl,hl
	add	hl,bc
	inc	de
	sub	30H			;Bug fix by Tatsu
	ld	c,a
	ld	b,000h
	add	hl,bc
	jr	@2
@3:
	ld	a,(?2)
	or	a
	ret	z
	xor	a
	sub	l
	ld	l,a
	ld	a,0
	sbc	a,h
	ld	h,a
	ret
	DSEG
?2:	DS	1
;	ENDMODULE
