/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strncmp ************************************/
#ifdef L_strncmp
int strncmp(d, s, l)
	char *d, *s;
	size_t l;
{
	register char c1 = 0, c2 = 0;

	while (l-- != 0) {
		if ((c1 = *d++) != (c2 = *s++) || c1 == '\0')
			break;
	}
	return c1 - c2;
}
#endif
