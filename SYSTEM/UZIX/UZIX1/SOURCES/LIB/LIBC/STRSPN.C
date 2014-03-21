/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strspn ************************************/
#ifdef L_strspn
/* Return the length of the maximum initial segment
   of S which contains only characters in ACCEPT.
 */
size_t strspn(s, accept)
	char *s;
	char *accept;
{
	register char *p = s, *a;
	register size_t count = 0;

	while (*p != '\0') {
		a = accept; 
		while (*a != '\0' && *p != *a)
			++a;
		if (*a == '\0')
			break;
		++p;
		++count;
	}
	return count;
}
#endif
