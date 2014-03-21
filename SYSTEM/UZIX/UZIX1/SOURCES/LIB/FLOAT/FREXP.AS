;	These functions allow the mantissa and exponent of floating
;	numbers to be manipulate separately.


	psect	text
	global	_frexp, _ldexp

;	double frexp(value, eptr)
;	double value;
;	int *  eptr;

_frexp:
	push	ix
	push	bc			;BC=eptr
	ld	ix,0
	add	ix,sp
	ld	a,(ix+9)		;get old exponent
	ld	b,a			;save sign bit
	and	80h			;mask it out
	add	a,64			;add in bias
	ld	d,a			;store new exponent back
	ld	a,b			;now get exponent
	and	7Fh			;clea sign bit
	sub	64			;remove bias
	pop	hl			;get pointer
	ld	(hl),a
	inc	hl
	rla
	sbc	a,a
	ld	(hl),a			;store upper byte
	ld	l,(ix+6)		;now get value to return
	ld	h,(ix+7)
	ld	e,(ix+8)
	ex	de,hl			;already have sign in d
	pop	ix
	ret

_ldexp:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	a,c			;A=C=new exponent
	and	7Fh			;only exponent bits
	ld	c,a
	ld	a,(ix+7)		;H=A=old exponent
	ld	h,a
	and	80h
	ld	b,a			;B=old signal
	ld	a,h
	add	a,c			;A=old exponent+new exponent
	and	7Fh			;only exponent bits
	or	b			;put back signal
	ld	h,a			;get mantissa
	ld	l,(ix+6)
	ld	d,(ix+5)
	ld	e,(ix+4)
	pop	ix
	ret
