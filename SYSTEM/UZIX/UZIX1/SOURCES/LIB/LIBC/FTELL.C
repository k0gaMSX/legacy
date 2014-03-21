/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_ftell
long ftell(fp)
	FILE *fp;
{
	if (fflush(fp) == EOF)
		return EOF;
	return lseek(fp->fd, 0L, SEEK_CUR);
}
#endif

