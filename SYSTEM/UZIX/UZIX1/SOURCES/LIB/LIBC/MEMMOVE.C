/* memmove.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */
 
#include "mem-l.h"

/********************** Function memmove ************************************/
#ifdef L_memmove
void *memmove(d, s, l)
	void *d, *s;
	size_t l;
{
#ifdef HI_TECH_C
#asm
	global  _memcpy
;_s stored from bc
;_d stored from de
	ld	ix,0
	add	ix,sp
	push	de	; saves d
	push	bc
	push	de
	push	de
	pop	hl	; HL = d
	or	a
	sbc	hl,bc	; d = d - s
	ld	e,(ix+4)
	ld	d,(ix+5)
	or	a
	sbc	hl,de	; d = d -l
	jr	c, 2f
	; d-s >=l -> memcpy
	pop	de	; d
	pop	bc	; s
	ld	l,(ix+4)	; l
	ld	h,(ix+5)
	push	hl
	call	_memcpy
	jr	1f
2:	; s=s+l, d=d+l, lddr
	xor	a
	pop	hl
	dec	hl
	add	hl,de	; d=d+l
	pop	bc
	push	hl
	ld	h,b	; HL=s
	ld	l,c
	dec	hl
	add	hl,de	; s=s+l
	ld	b,d
	ld	c,e	; BC=l
	pop	de	; DE=d
	lddr
1:	pop	hl	; d
#endasm
#else
	register char *s1 = d, *s2 = s;

	/* This bit of sneakyness c/o Glibc,
	 * it assumes the test is unsigned
	 */
	if (s1 - s2 >= l)
		return memcpy(d, s, l);
	/* This reverse copy only used if we absolutly have to */
	s1 += l;
	s2 += l; 
	while (l-- != 0)
		*(--s1) = *(--s2);
	return d;
#endif
}
#endif

