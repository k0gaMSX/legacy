/* stdio.c
 * Copyright (C) 1996 Robert de Bath <rdebath@cix.compulink.co.uk>
 * This file is part of the Linux-8086 C library and is distributed
 * under the GNU Library General Public License.
 */

/* This is an implementation of the C standard IO package. */

#include "stdio-l.h"

#ifdef L_stdio

#define buferr (unsigned char *)(stderr->unbuf) /* Stderr is unbuffered */

FILE	*__IO_list = NULL;	/* For fflush at exit */

static unsigned char bufin[BUFSIZ];
static unsigned char bufout[BUFSIZ];
#ifndef buferr
static unsigned char buferr[BUFSIZ];
#endif

FILE stdin[1] = {
	{bufin, bufin, bufin, bufin, bufin + sizeof(bufin),
	0, _IOFBF | __MODE_READ | __MODE_IOTRAN}
};

FILE stdout[1] = {
	{bufout, bufout, bufout, bufout, bufout + sizeof(bufout),
	1, _IOFBF | __MODE_WRITE | __MODE_IOTRAN}
};

FILE stderr[1] = {
	{buferr, buferr, buferr, buferr, buferr + sizeof(buferr),
	2, _IONBF | __MODE_WRITE | __MODE_IOTRAN}
};

/* Call the stdio initialiser; it's main job it to call atexit */
STATIC void __stdio_close_all(VOID) {
	FILE *fp = __IO_list;

	fflush(stdout);
	fflush(stderr);
	while (fp) {
		fflush(fp);
		close(fp->fd);
		/* Note we're not de-allocating the memory */
		/* There doesn't seem to be much point :-) */
		fp->fd = -1;
		fp = fp->next;
	}
}

STATIC void __stdio_init_vars() {
	static int first_time = 1;

	if (!first_time)
		return;
	first_time = 0;
	if (isatty(1))
		stdout->mode |= _IOLBF;
	atexit((atexit_t)__stdio_close_all);
}
#endif

