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
 UZIX target machine definition
**********************************************************/

#ifndef __UZIX_H
#define __UZIX_H

#define	__P(x)	x

/* Available targets:		and compilers:
 *	PC MS-DOS UZIX		Turbo-C
 *	PC MS-DOS UTILS		Turbo-C
 *	MSX MSX-DOS UTILS	HTC
 *	MSX UZIX		HTC
 *
 * Other directives for MSX:
 * 	MEGARAM_DDX		uses DDX-like MegaRAM as swapper (no mirror effect)
 * 	MEGARAM_ACVS		uses ACVS-like MegaRAM as swapper (has mirror effect)
 *	NO_RTC			simulates RTC (virtual RTC must be initialized by /bin/init)
 */

#ifndef PC_UZIX_TARGET
#ifndef PC_UTILS_TARGET
#ifndef MSX_UTILS_TARGET
#ifndef MSX_UZIX_TARGET
#error Target not specified!
#endif
#endif
#endif
#endif

#ifdef	PC_UZIX_TARGET
#define PC_HOSTED
#define x86
#define __KERNEL__
#undef	SEPH
#define	_LOC_UDATA	/* udata NOT at process local memory */
#undef	_MSX_DOS
#define	NOTUSED(v)	(void)(v)
#define HOST_MACHINE	"PC"
#endif

#ifdef	PC_UTILS_TARGET
#define PC_HOSTED
#define x86
#undef	__KERNEL__
#undef	SEPH
#undef	LOC_UDATA	/* udata NOT at process local memory */
#undef	_MSX_DOS
#define	NOTUSED(v)	(void)(v)
#endif

#ifdef	MSX_UZIX_TARGET
#define MSX_HOSTED
#define z80 1
#define __KERNEL__
#undef	SEPH
#define	LOC_UDATA	/* udata at process local memory */
#undef	_MSX_DOS
#define	NOTUSED(v)
#define HOST_MACHINE	"MSX"
#endif

#ifdef	MSX_UTILS_TARGET
#define MSX_HOSTED
#define z80 1
#undef	__KERNEL__
#undef	SEPH
#undef	LOC_UDATA	/* udata NOT at process local memory */
#ifndef _MSX_DOS
#define _MSX_DOS	1
#endif
#define	NOTUSED(v)
#endif

#ifndef SEPH
#define NEED__DEVFLOP
#define NEED__DEVSWAP
#define NEED__DEVTTY
#define NEED__DEVMISC
#define NEED__DEVIO
#define NEED__FILESYS
#define NEED__MACHDEP
#define NEED__PROCESS
#define NEED__DISPATCH
#define NEED__SCALL
#endif

#ifdef MSX_UTILS_TARGET
#ifndef XFS
#undef NEED__SCALL
#endif
#endif

#endif
