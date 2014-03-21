/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strpbrk ************************************/
#ifdef L_strpbrk
/* This uses strchr, strchr should be in assembler */
char *strpbrk(str, set)
	register char *str;
	register char *set;
{
	while (*str != '\0') {
		if (strchr(set, *str))
			return str;
		++str;
	}
	return 0;
}
#endif
