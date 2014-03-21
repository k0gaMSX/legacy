/* memcpy.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "mem-l.h"

/********************** Function memcpy ************************************/
#ifdef L_memcpy
void *memcpy(d, s, l)
	void *d;
	void *s;
	size_t l;
{
#ifndef HI_TECH_C
	register char *s1 = d, *s2 = (char *) s;

	while (l-- != 0)
		*((unsigned char *) s1++) = *((unsigned char *) s2++);
	return d;
#else
#asm
	; HTC puts a "push ix" here
	ld 	ix,0
	add	ix,sp
	ld	h,b
	ld	l,c
	ld	c,(ix+4)
	ld	b,(ix+5)
	push	de
	ld	a,b
	or	c
	jr	z,_skip
	ldir
_skip:
	pop	hl
	; HTC puts a "pop ix" here
#endasm
#endif	
}
#endif

