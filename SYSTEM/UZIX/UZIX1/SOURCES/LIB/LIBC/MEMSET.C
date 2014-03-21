/* memset.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "mem-l.h"

/********************** Function memset ************************************/
#ifdef L_memset
void *memset(str, c, l)
	void *str;
	int c;
	size_t l;
{
#ifndef HI_TECH_C
	register char *s1 = str;

	while (l-- != 0)
		*s1++ = c;
	return str;
#else
#asm
	ld	ix,0
	add	ix,sp
	ld	h,d
	ld	l,e	; HL=str
	ld	d,c	; D=c
	ld	c,(ix+4)
	ld	b,(ix+5); BC=l
	ld	a,b
	or	c	; l=0? so return
	jr	z,_retw
	ld	a,d
	ld	(hl),a	; fill first byte
	ld	d,h
	ld	e,l
	inc	de	; DE=str+1
	dec	bc
	ld	a,b	; l=1? so return
	or	c
	jr	z,_retw
	push	hl
	ldir
	pop	hl
_retw:
#endasm
#endif
}
#endif
