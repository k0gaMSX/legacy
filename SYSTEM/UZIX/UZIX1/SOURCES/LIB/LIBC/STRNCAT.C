/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strncat ************************************/
#ifdef L_strncat
char *strncat(d, s, l)
	char *d, *s;
	size_t l;
{
	register char *s1 = d + strlen(d), *s2 = memchr(s, 0, l);

	if (s2)
		memcpy(s1, s, s2 - s + 1);
	else {
		memcpy(s1, s, l);
		s1[l] = '\0';
	}
	return d;
}
#endif
