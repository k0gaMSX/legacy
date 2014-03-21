/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_fputc
int fputc(ch, fp)
	int ch;
	FILE *fp;
{
	register int v;

	Inline_init;
	v = fp->mode;
	/* If last op was a read ... */
	if ((v & __MODE_READING) && fflush(fp))
		return EOF;
	/* Can't write or there's been an EOF or error then return EOF */
	if ((v & (__MODE_WRITE | __MODE_EOF | __MODE_ERR)) != __MODE_WRITE)
		return EOF;
#if __MODE_IOTRAN
	/* In MSDOS translation mode */
	if (ch == '\n' && (v & __MODE_IOTRAN) && fputc('\r', fp) == EOF)
		return EOF;
#endif
	/* Buffer is full */
	if (fp->bufpos >= fp->bufend && fflush(fp))
		return EOF;
	/* Right! Do it! */
	*(fp->bufpos++) = ch;
	fp->mode |= __MODE_WRITING;

	/* Unbuffered or Line buffered and end of line */
	if (((ch == '\n' && (v & _IOLBF)) || (v & _IONBF)) && fflush(fp))
		return EOF;
	/* Can the macro handle this by itself ? */
	if (v & (__MODE_IOTRAN | _IOLBF | _IONBF))
		fp->bufwrite = fp->bufstart;	/* Nope */
	else	fp->bufwrite = fp->bufend;	/* Yup */
	/* Correct return val */
	return (unsigned char) ch;
}
#endif

