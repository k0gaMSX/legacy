/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strlen ************************************/
#ifdef L_strlen
size_t strlen(str)
	register char *str;
{
#ifndef HI_TECH_C
	register char *p = str;

	while (*p != 0)
		++p;
	return (size_t)(p-str);
#else
#asm
	ld	h,d
	ld	l,e
	ld	bc,0ffffh
	xor	a
	cpir
	sbc	hl,de
	dec	hl
#endasm
#endif	
}
#endif
