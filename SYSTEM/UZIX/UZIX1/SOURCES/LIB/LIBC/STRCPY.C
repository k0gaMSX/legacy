/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strcpy ************************************/
#ifdef L_strcpy
char *strcpy(d, s)
	char *d;
	char *s;
{
	return memcpy(d, s, strlen(s) + 1);
}
#endif
