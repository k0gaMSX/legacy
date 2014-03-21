/* memcmp.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */
 
#include "mem-l.h"

/********************** Function memcmp ************************************/
#ifdef L_memcmp
int memcmp(s, d, l)
	void *s;
	void *d;
	size_t l;
{
#ifdef HI_TECH_C
#asm
        ; d = BC, s=DE, l=(ix+4, ix+5)
        ld	ix,0
        add	ix,sp
        push    iy
        ld      l,(ix+4)
        ld      h,(ix+5)
        ex      de,hl   ; HL=s, DE=l
        push    bc
        pop     iy      ; IY=d
        ld      bc,0    ; char1, char2
1:      ld      a,(hl)
        ld      b,a
        ld      a,(iy)  ; char1 != char 2 ?
        ld      c,a
        cp      b
        jr      nz,2f
        inc     hl	; s++
        inc     iy	; d++
        dec     de	; l--
        ld      a,d
        or      e
        jp      nz,1b	; l != 0, continue
2:      ld      a,c	; char1 - char2
        ld      e,a
	rla
	sbc	a,a
	ld	d,a
        ld      a,b
        ld      l,b
	rla
	sbc	a,a
	ld	h,a
	or	a
	sbc	hl,de
	pop	iy
#endasm
#else
	register char *s1 = d, *s2 = s;
	register char c1 = 0, c2 = 0;

	while (l-- != 0) {
		if ((c1 = *s1++) != (c2 = *s2++))
			break;
	}
	return c1 - c2;
#endif
}
#endif

