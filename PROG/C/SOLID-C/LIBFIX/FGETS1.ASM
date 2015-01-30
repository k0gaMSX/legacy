;	MODULE	FGETS1
;
;char *fgets(char *s, int maxlen, FILE *stream)
;
fgets_::
	ld	(?105),bc
	ld	(?103),hl
	ld	(?104),de
	ld	(?107),hl
@39:	ld	hl,(?104)
	dec	hl
	ld	(?104),hl
	ex	de,hl
	ld	hl,0
	call	?cpshd##
	jp	nc,@38
	ld	hl,(?105)
	call	fgetc_##
	ld	(?106),a
	inc	a
	jp	z,@38
;	ld	a,l
	dec	a		;Patched by Tatsu
	ld	hl,(?107)
	ld	(hl),a
	inc	hl
	ld	(?107),hl
	cp	10
	jp	nz,@39
@38:	xor	a
	ld	de,(?107)
	ld	(de),a
	ld	a,(?106)
	inc	a
	jp	nz,@40
	ld	hl,(?103)
	ld	a,e
	cp	l
	jr	nz,@40
	ld	a,d
	cp	h
	jr	nz,@40
	ld	hl,0
	ret
;
@40:	ld	hl,(?103)
	ret

	dseg
?103:	ds	2
?104:	ds	2
?105:	ds	2
?106:	ds	1
?107:	ds	2

;	ENDMODULE

