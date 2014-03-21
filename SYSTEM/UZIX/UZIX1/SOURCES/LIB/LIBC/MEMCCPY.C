/* memccpy.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "mem-l.h"

/********************** Function memccpy ************************************/
#ifdef L_memccpy
void *memccpy(d, s, c, l)	/* Do we need a fast one ? */
	void *s, *d;
	int c;
	size_t l;
{
	register char *s1 = d, *s2 = s;

	while (l-- != 0) {
		if ((*s1++ = *s2++) == c)
			return s1;
	}
	return NULL;
}
#endif
