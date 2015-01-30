;	MODULE	FREAD
;
;	Read a file
;

	cseg

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

;	ENDMODULE

