/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_gets
char *gets(str) 	/* BAD function; DON'T use it! */
	char *str;
{
	/* Auwlright it will work but of course _your_ program will crash */
	/* if it's given a too long line */
	register int c;
	register char *p = str;

	while (((c = getc(stdin)) != EOF) && (c != '\n'))
		*p++ = c;
	*p = '\0';
	return (((c == EOF) && (p == str)) ? NULL : str); /* NULL == EOF */
}
#endif

#ifdef L_puts
int puts(str)
	void *str;
{
	register int n;

	if (((n = fputs(str, stdout)) == EOF)
	    || (putc('\n', stdout) == EOF))
		return (EOF);
	return (++n);
}
#endif

