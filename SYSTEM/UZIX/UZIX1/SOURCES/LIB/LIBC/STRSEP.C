/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strsep ************************************/
#ifdef L_strsep
char *strsep(pp, delim)
	char **pp;
	char *delim;
{
	char *p, *q;

	if (0 == (p = *pp))
		return 0;
	if ((q = strpbrk(p, delim)) != 0) {
		*pp = q + 1;
		*q = '\0';
	}
	else	*pp = 0;
	return p;
}
#endif
