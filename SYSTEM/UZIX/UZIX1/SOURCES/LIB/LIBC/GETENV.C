/*********************** getenv.c ***************************
/* Copyright (C) 1995,1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

#include "environ.h"

#ifdef L_getenv
char *getenv(name)
	char *name;
{
	register char *p, **ep = environ;
	register int l = strlen(name);

	if (ep == 0 || l == 0)
		return 0;
	while ((p = *ep++) != NULL) {
		if (p[0] == name[0] &&
		    p[l] == '=' &&
		    memcmp(name, p, l) == 0)
			return p + l + 1;
	}
	return NULL;
}
#endif
