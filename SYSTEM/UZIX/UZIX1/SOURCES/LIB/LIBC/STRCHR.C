/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strchr ************************************/
#ifdef L_strchr
char *strchr(s, c)
	char *s;
	int c;
{
	register char ch;

	for (;;) {
		if ((ch = *s) == c)
			return s;
		if (ch == 0)
			return 0;
		s++;
	}
}
#endif
