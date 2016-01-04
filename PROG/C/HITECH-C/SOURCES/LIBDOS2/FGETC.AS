;	/*
;	 *	fgetc for Zios stdio
;	 */
;	
;	#include	<stdio.h>
;	
;	#define	CPMEOF	032		/* ctrl-Z */
;	
;	fgetc(f)
;	register FILE *	f;
;	{
;		int	c;
;	
;		if(f->_flag & _IOEOF || !(f->_flag & _IOREAD)) {
;	reteof:
;			f->_flag |= _IOEOF;
;			return EOF;
;		}
;	loop:
;		if(f->_cnt > 0) {
;			c = (unsigned)*f->_ptr++;
;			f->_cnt--;
;		} else if(f->_flag & _IOSTRG)
;			goto reteof;
;		else
;			c = _filbuf(f);
;		if(f->_flag & _IOBINARY)
;			return c;
;		if(c == '\r')
;			goto loop;
;		if(c == CPMEOF) {
;			f->_cnt++;
;			f->_ptr--;
;			goto reteof;
;		}
;		return c;
;	}

;	The assembler version of the above routine

*Include	stdio.i
	global	_fgetc, __filbuf
	psect	text

_fgetc:
	pop	de			;get return address off stack
	ex	(sp),iy			;save iy and get arguement into iy
	ld	a,(iy+flag)		;get flag bits
	bit	_IOREAD_BIT,a
	jr	z,reteof		;return EOF if not open for read
	bit	_IOEOF_BIT,a		;Already seen EOF?
	jr	nz,reteof		;yes, repeat ourselves

loop:
	ld	l,(iy+cnt)
	ld	h,(iy+cnt+1)
	ld	a,l
	or	h			;any bytes left?
	jr	z,1f			;no, go get some more
	dec	h