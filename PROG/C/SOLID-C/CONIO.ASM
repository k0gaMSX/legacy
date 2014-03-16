	MODULE	PUTCH
;
;	void putch(char *c)
;
putch_::push	ix
	cp	10
	jr	 nz,ptch1
	ld	a,13
	db	0F7h,80h,0A2h,0
	ld	a,10
ptch1:	db	0F7h,80h,0A2h,0
	pop	ix
	ret

	ENDMODULE


	MODULE	GETCH
;
;	char	getch()
;
getch_::push	ix
	db	0F7h,80h,9Fh,0
	pop	ix
	ret

	ENDMODULE


	MODULE	GETCHE
;
;	char	getche()
;
getche_::
	call	getch_##
	jp	putch_##

	ENDMODULE


	MODULE	CPUTS
;
;	void	cputs(char *str)
;
cputs_::ld	a,(hl)
	or	a
	ret	z
	call	putch_##
	inc	hl
	jr	cputs_

	ENDMODULE


	MODULE	CLRSCR
;
;	void clrscr()
;
clrscr_::
	ld	a,12
	jp	putch_##

	ENDMODULE


	MODULE	HOME
;
;	void home()
;
home_::	ld	a,11
	jp	putch_##

	ENDMODULE


	MODULE	GOTOXY
;
;	void gotoxy(int x, int y)
;
gotoxy_::
	push	hl
	push	de
	ld	a,27
	call	putch_##
	ld	a,'Y'
	call	putch_
	pop	de
	ld	a,' '
	add	a,e
	call	putch_
	pop	de
	ld	a,' '
	add	a,e
	jp	putch_

	ENDMODULE


	MODULE	KBHIT
;
;	char	kbhit()
;
kbhit_::push	ix
	db	0F7h,80h,9Ch,0
	pop	ix
	ld	a,0
	ret	z
	inc	a
	ret

	ENDMODULE


	MODULE	PUTDEC
;
;	void	putdec(int num)
;
putdec_::
	bit	7,h
	jr	z,.1
	call	?NEGHL##
	ld	a,'-'
	call	putch_##
.1:	ld	de,0
	ld	c,e
	ld	b,16
.2:	add	hl,hl
	ld	a,e
	adc	a,a
	daa
	ld	e,a
	ld	a,d
	adc	a,a
	daa
	ld	d,a
	rl	c
	djnz	.2
	ld	hl,mystr
	call	@fhexw
	ld	e,c
	call	@fhexb
	ld	(hl),0
	ld	hl,mystr
	ld	bc,4
	ld	a,' '
	cpir
	jp	cputs_##
@fhexw:	push	de
	ld	e,d
	call	@fhexb
	pop	de
@fhexb:	ld	a,e
	push	af
	rrca
	rrca
	rrca
	rrca
	call	.3
	pop	af
.3:	and	0Fh
	add	a,'0'
	cp	3Ah
	jr	c,.4
	add	a,7
.4:	ld	(hl),a
	inc	hl
	ret
;
	DSEG
mystr:	ds	6

	ENDMODULE


	MODULE	GETSCON
	DSEG
?18:	DS	2
?23:	DS	2
	CSEG
_getscon_::
	push	ix
	ld	(?18),hl
	ld	hl,0FF7Eh
	add	hl,sp
	ld	sp,hl
	ld	hl,(?18)
	push	hl
	ld	(?23),hl
	ld	a,e
	dec	a
	dec	a
	ld	hl,00002h
	add	hl,sp
	ld	(hl),a
	ld	hl,00002h
	add	hl,sp
	ex	de,hl
	ld	c,10
	call	5
	ld	e,10
	ld	c,2
	call	5
	ld	hl,00004h
	add	hl,sp
	ld	a,(hl)
	pop	hl
	cp	01Ah
	jr	nz,@5
	ld	hl,00000h
	jr	@6
;
@5:	push	hl
	ld	hl,00003h
	add	hl,sp
	ld	c,(hl)
	ld	hl,00004h
	add	hl,sp
	ex	de,hl
	pop	hl
@8:
	dec	c
	ld	a,c
	inc	a
	jr	z,@7
	ld	a,(de)
	inc	de
	ld	(hl),a
	inc	hl
	jr	@8
@7:
	ld	a,00Ah
	ld	(hl),a
	inc	hl
	xor	a
	ld	(hl),a
	ld	hl,(?23)
@6:
	ex	de,hl
	ld	hl,00082h
	add	hl,sp
	ld	sp,hl
	ex	de,hl
	pop	ix
	ret
	ENDMODULE

	MODULE	GETCON
	CSEG
_getcon_::
	push	ix
	ld	c,1
	call	5
	cp	13
	ret	nz
	ld	a,10
	push	af
	ld	c,2
	ld	e,a
	call	5
	pop	af
	pop	ix
	ret
	ENDMODULE
