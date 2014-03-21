/* string.c
 * Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "string-l.h"

/********************** Function strstr ************************************/
#ifdef L_strstr
#if 1
/* We've now got a nice fast strchr and memcmp use them */
char *strstr(s1, s2)
	char *s1;
	char *s2;
{
	register int l = strlen(s2);
	register char *p = s1;

	if (l == 0)
		return p;
	while ((p = strchr(p, *s2)) != 0) {
		if (memcmp(p, s2, l) == 0)
			return p;
		++p;
	}
	return NULL;
}
#else
/* This is a nice simple self contained strstr,
   now go and work out why the GNU one is faster :-)
 */
char *strstr(str1, str2)
	char *str1, *str2;
{
	register char *Sptr, *Tptr;
	int len = strlen(str1) - strlen(str2) + 1;

	if (*str2) {
		while (len > 0) {
			if (*str1 != *str2)
				continue;
			for (Sptr = str1, Tptr = str2; *Tptr != '\0'; Sptr++, Tptr++) {
				if (*Sptr != *Tptr)
					break;
			}
			if (*Tptr == '\0')
				return str1;
			--len;
			++str1;
		}
	}
	return NULL;
}
#endif
#endif
