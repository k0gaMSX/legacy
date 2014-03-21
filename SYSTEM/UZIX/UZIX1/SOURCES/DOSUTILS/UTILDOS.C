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

#include "utildos.h"

#ifdef _MSX_DOS 	/* MSXDOS initialization procedures */
#ifdef Z80MU
#define BDOSADDR	0FEFEh
#else
#define BDOSADDR	00005h
#endif

/* CALROM and BDOS routines for DOS utils */
#asm
	psect	text
_calromd:
	ld	iy,(0FCC1h)
	jp	1Ch
_calbdos:
	ld	iy,(MAINDRV-1)
	jp	1Ch
#endasm

uchar xxbdos(uint de,uchar c) {
#asm
	push	bc
	call	BDOSADDR
	ld	l,a
	pop	bc
	ret
#endasm
}

/* Set UZIX CALROM and BDOS calls to DOS routines */
void initenv(void) {
#asm
	ld	a,0C3h		; JP
	ld	(CALROM),a
	ld	(BDOS),a
	ld	hl,_calromd
	ld	(CALROM+1),hl
	ld	hl,_calbdos
	ld	(BDOS+1),hl
#endasm
}

extern void exit(int);

/* Quit program and also batch file if called under one */
void xexit(int errcode) {
	uint i;
	
	if (DOSVER == 0) {		/* DOS1: */
		i = *(uint *)0x6;
		i += 19;
		*(uchar *)i = 0;	/* clear BATFLG (abort batchfile) */
		exit(errcode);
	}
	i = 0;		/* a C statement must be put here or the "else" statement
			   of the above if will not jump to the ASM code below */
	/* DOS2: */
#asm
	ld bc,08062h	; exit with error code 0x80 (abort batchfile)
	jp BDOSADDR
#endasm
}

#endif

