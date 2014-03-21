/* memchr.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */
 
#include "mem-l.h"

/********************** Function memchr ************************************/
#ifdef L_memchr
void *memchr(str, c, l)
	void *str;
	int c;
	size_t l;
{
	register char *p = (char *) str;

	while (l-- != 0) {
		if (*p == c)
			return p;
		p++;
	}
	return NULL;
}
#endif
