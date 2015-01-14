; int _glob(char * wild, char * fib)
; wild points to ambiguous file spec.
; fibbuf points to a buffer to store the file info block
;               the fib will start with the filename terminated by \0
; fibbuf[0] must not be 0ffh on the first call
 
	psect text
global __glob, csv, cret, bDos
__glob:
	call	csv
	ld	e,(ix+6)
	ld	d,(ix+7) ; wild
	ld	c,(ix+8)
	ld	b,(ix+9) ; fib
	ld	a,(bc)
	push	bc
	ex	(sp),ix
	ld	bc, 1040h ; 40 _FFIRST, 10 vind ook directories
	inc	a
	jr	nz, 3f
	inc	c ; if fib points to an initialised file info block, c=_FNEXT
3:
	call	bDos
	pop	ix
	ld	h,0
	ld	l,a
	jp	cret

