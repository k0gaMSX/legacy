/*
 * UZIX - UNIX Implementation for MSX
 * (c) 1997-2001 Arcady Schekochikhin
 *		 Adriano C. R. da Cunha
 *
 * UZIX is based on UZI (UNIX Zilog Implementation)
 * UZI is a UNIX kernel clone written for Z-80 systems.
 * All code is public domain, not being based on any AT&T code.
 *
 * The author, Douglas Braun, can be reached at:
 *	7696 West Zayante Rd.
 *	Felton, CA 95018
 *	oliveb!intelca!mipos3!cadev4!dbraun
 *
 * This program is under GNU GPL, read COPYING for details
 *
 */

/**********************************************************
 Main procedure and UZIX data
**********************************************************/

#define __MAIN__COMPILATION
#define NEED__MACHDEP
#define NEED__SCALL

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#endif
#include "unix.h"
#include "extern.h"

char *UZIX="UZIX";

void main(VOID) {
#ifdef TEST_CONSOLE_IO			/* Console basic test */
	uchar a;

	inint=1;
	initsys();
	__ei();
	kprintf("\nTesting console I/O.\nHit any key. ESCAPE ends. CTRL+Z for debug.\n\n");
	for (;;) {
		while ((a = _getc()) == 0)
			;
		if (a == 27)
			break;
		_putc(a);
	}
	inint=0;
#endif
	kprintf("Welcome to %s %s.%s\n", UZIX, VERSION, RELEASE);
	arch_init();		/* NORETURN */
}

