/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strdup ************************************/
#ifdef L_strdup
#include <malloc.h>
char *strdup(s)
	char *s;
{
	register size_t len = strlen(s) + 1;
	register char *p = (char *) malloc(len);

	if (p)
		memcpy(p, s, len);	/* Faster than strcpy */
	return p;
}
#endif
