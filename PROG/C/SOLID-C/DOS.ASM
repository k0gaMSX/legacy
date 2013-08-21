	MODULE	CALLSLT
;
;	void callslt(char slot,unsigned addr, union REGS *ri, union REGS *ro)
;
callslt_::
	push	ix
	push	af
	push	de
	push	bc
	pop	ix
	ld	a,(ix+1)
	ld	c,(ix+2)	
	ld	b,(ix+3)	
	ld	e,(ix+4)	
	ld	d,(ix+5)	
	ld	l,(ix+6)	
	ld	h,(ix+7)	
	pop	ix
	pop	iy
	call	1Ch
	exx
	pop	hl	;ix saved
	pop	de	;return address
	pop	bc	;param4
	push	bc
	push	de
	push	hl
	push	bc
	exx
	ex	(sp),ix
	ld	(ix+2),c
	ld	(ix+3),b	
	ld	(ix+4),e
	ld	(ix+5),d
	ld	(ix+6),l
	ld	(ix+7),h
	push	af
	pop	bc
	ld	(ix+0),c
	ld	(ix+1),b
	pop	bc
	ld	(ix+8),c
	ld	(ix+9),b
	push	iy
	pop	bc
	ld	(ix+10),c
	ld	(ix+11),b
	pop	ix
	ret
	ENDMODULE

	MODULE	diei
;
;	enable and disable interrupts
;
enable_::
	ei
	ret
disable_::
	di
	ret
	ENDMODULE

	MODULE	SETVFY
;
;	void	setverify(char mode)
;
setverify_::
	push	ix
	ld	e,a
	ld	c,2Eh
	call	5
	pop	ix
	ret
	ENDMODULE


	MODULE	setarg
;
;	internal: set arguments of the main() function
;
setargv_::
	ld	a,(80h)
	add	a,81h
	ld	l,a
	ld	h,0
	ld	(hl),h
	ld	hl,_argv_+2
	ld	de,81h
	ld	b,1		;argc!
.1:	ld	a,(de)
	inc	de
	cp	' '
	jr	z,.1
	cp	9
	jr	z,.1
	or	a
	jr	z,.2
	dec	de
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	inc	b
.3:	ld	a,(de)
	cp	' '
	jr	z,.4
	cp	9
	jr	z,.4
	or	a
	jr	z,.2
	inc	de
	cp	22h
	jr	z,.5
	jr	.3
;
.4:	xor	a
	ld	(de),a
	inc	de
	jr	.1
;
.5:	ld	a,(de)
	cp	22h
	jr	z,.3
	or	a
	jr	z,.2
	inc	de
	jr	.5
;
.2:	ld	(hl),0
	inc	hl
	ld	(hl),0
	ld	a,b
	ld	(_argc_),a
	ld	a,(_os_ver_##)
	dec	a
	jr	nz,.6
	ld	hl,65
	call	sbrk_##
	ld	(_argv_),hl
	ex	de,hl
	ld	bc,416Bh
	ld	hl,$pn
	call	5
.6:	ld	hl,(_argc_)
	ret
;
$pn:	db	'PROGRAM',0

	DSEG
_argc_::dw	0
_argv_::dw	0F69Ch
	ds	64
	ENDMODULE


	MODULE	setdta
;
;	void	setdta(void *ptr)
;
setdta_::
	ld	(0F23Dh),hl
	ret

	ENDMODULE

	MODULE	setdisk
;
;	void	setdisk(char diskno)
;
setdisk_::
	push	ix
	ld	e,a
	ld	c,0Eh
	call	5
	pop	ix
	ret
	ENDMODULE


	MODULE	absread
;
;	char    absread(char disk, int sector, int seccnt, void *dma)
;
absread_::
	pop	iy
	pop	hl
	ld	(0F23Dh),hl
	push	hl
	push	iy
	push	ix
	ld	l,a		;disk
	ld	h,c		;sectors count
	ld	c,2Fh
	call	5
	pop	ix
	ret
	ENDMODULE

	MODULE	abswrit
;
;	char    abswrite(char disk, int sector, int seccnt, void *dma)
;
abswrite_::
	pop	iy
	pop	hl
	ld	(0F23Dh),hl
	push	hl
	push	iy
	push	ix
	ld	l,a		;disk
	ld	h,c		;sectors count
	ld	c,30h
	call	5
	pop	ix
	ret
	ENDMODULE

	MODULE	getdisk
;
;	char	getdisk();
;
getdisk_::
	push	ix
	ld	c,19h
	call	5
	pop	ix
	ret
	ENDMODULE


	MODULE	date
;
;	void	getdate(struct date *date);
;
getdate_::
	push	ix
	push	hl
	ld	c,2Ah
	call	5
	pop	ix
	ld	(ix+0),l
	ld	(ix+1),h
	ld	(ix+2),e
	ld	(ix+3),d
	pop	ix
	ret
;
;	void	setdate(struct date *date)
;
setdate_::
	push	ix
	push	hl
	pop	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	ld	e,(iy+2)
	ld	d,(iy+3)
	ld	c,2Bh
	call	5
	pop	ix
	ret
	ENDMODULE

	MODULE	time
;
;	void	gettime(struct time *time);
;
gettime_::
	push	ix
	push	hl
	ld	c,2Ch
	call	5
	pop	ix
	ld	(ix+0),l
	ld	(ix+1),h
	ld	(ix+2),e
	ld	(ix+3),d
	pop	ix
	ret
;
;	void	settime(struct time *time)
;
settime_::
	push	ix
	push	hl
	pop	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	ld	e,(iy+2)
	ld	d,(iy+3)
	ld	c,2Dh
	call	5
	pop	ix
	ret
	ENDMODULE

	MODULE	INTDOS
;
;	void intdos(union REGS *ri, union REGS *ro)
;
intdos_::
	push	ix
	push	de
	push	hl
	pop	ix
	ld	a,(ix+1)
	ld	c,(ix+10)
	ld	b,(ix+11)
	push	bc
	ld	c,(ix+8)
	ld	b,(ix+9)
	push	bc
	ld	c,(ix+2)	
	ld	b,(ix+3)	
	ld	e,(ix+4)	
	ld	d,(ix+5)	
	ld	l,(ix+6)	
	ld	h,(ix+7)	
	pop	ix
	pop	iy
	call	5
	ex	(sp),ix
	ld	(ix+2),c
	ld	(ix+3),b	
	ld	(ix+4),e
	ld	(ix+5),d
	ld	(ix+6),l
	ld	(ix+7),h
	push	af
	pop	bc
	ld	(ix+0),c
	ld	(ix+1),b
	pop	bc
	ld	(ix+8),c
	ld	(ix+9),b
	push	iy
	pop	bc
	ld	(ix+10),c
	ld	(ix+11),b
	pop	ix
	ret
	ENDMODULE

