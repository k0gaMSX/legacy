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
 MSX machine dependent routines for UZIX utilities
**********************************************************/

#include "uzix.h"
#ifdef SEPH
#include "types.h"
#include "signal.h"
#include "errno.h"
#endif
#include "unix.h"
#include "extern.h"	/* need for CALLROM/BDOS*/

#define	PF	printf
#define FF	fflush(stdout)

#ifdef _MSX_DOS
#define GETDEVNUM(p)	(dev_t)atol(p);
extern void initenv __P((void));
extern uchar xxbdos __P((uint, uchar));
extern void xexit __P((int));
#define DOSVER (*(char *)0xf313)	/* MSX: 0=DOS1 */
#else
#define GETDEVNUM(p)	(dev_t)strtol(p,NULL,0);
#endif
