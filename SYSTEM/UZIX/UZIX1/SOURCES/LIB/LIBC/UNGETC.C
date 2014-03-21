/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_ungetc
int ungetc(c, fp)
	int c;
	FILE *fp;
{
	if (fp->mode & __MODE_WRITING)
		fflush(fp);
	/* Can't read or there's been an error then return EOF */
	if ((fp->mode & (__MODE_READ | __MODE_ERR)) != __MODE_READ)
		return EOF;
	/* Can't do fast fseeks */
	fp->mode |= __MODE_UNGOT;
	if (fp->bufpos > fp->bufstart)
		return *--fp->bufpos = (unsigned char) c;
	if (fp->bufread == fp->bufstart)
		return *fp->bufread++ = (unsigned char) c;
	return EOF;
}
#endif
