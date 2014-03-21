/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_setvbuf
int setvbuf(fp, buf, mode, size)
	FILE *fp;
	char *buf;
	int mode;
	size_t size;
{
	fflush(fp);
	if (fp->mode & __MODE_FREEBUF)
		free(fp->bufstart);
	fp->mode &= ~(__MODE_FREEBUF | __MODE_BUF);
	fp->bufstart = (uchar *)fp->unbuf;
	fp->bufend = (uchar *)fp->unbuf + sizeof(fp->unbuf);
	fp->mode |= _IONBF;
	if (mode == _IOFBF || mode == _IOLBF) {
		if (size == 0)
			size = BUFSIZ;
		if (buf == NULL && (buf = calloc(1,size)) == NULL)
			return EOF;
		fp->bufstart = (uchar *)buf;
		fp->bufend = (uchar *)buf + size;
		fp->mode |= mode;
	}
	fp->bufpos = fp->bufread = fp->bufwrite = fp->bufstart;
	return 0;
}
#endif

