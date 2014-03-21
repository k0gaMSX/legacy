/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_setbuff
void setbuffer(fp, buf, size)
	FILE *fp;
	char *buf;
	size_t size;
{
	fflush(fp);
	if (fp->mode & __MODE_FREEBUF)
		free(fp->bufstart);
	fp->mode &= ~(__MODE_FREEBUF | __MODE_BUF);
	if (buf == NULL) {
		fp->bufstart = (uchar *)fp->unbuf;
		fp->bufend = (uchar *)fp->unbuf + sizeof(fp->unbuf);
		fp->mode |= _IONBF;
	}
	else {
		fp->bufstart = (uchar *)buf;
		fp->bufend = (uchar *)buf + size;
#if _IOFBF
		fp->mode |= _IOFBF;
#endif
	}
	fp->bufpos = fp->bufread = fp->bufwrite = fp->bufstart;
}
#endif

