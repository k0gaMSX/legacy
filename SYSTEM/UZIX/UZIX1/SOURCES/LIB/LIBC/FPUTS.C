/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_fputs
int fputs(str, fp)
	void *str;
	FILE *fp;
{
	register int n = 0;
	char *s = str;

	while (*s) {
		if (putc(*s++, fp) == EOF)
			return (EOF);
		++n;
	}
	return (n);
}
#endif

