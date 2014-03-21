/********** MSX-UZIX version of syscalls ************/
/* UNIX link(char *oldname, char *newname); */

#include "syscalls.h"

#ifdef L_link
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_link");
	asm("	signat	_link,8250");
	asm("_link:");
	asm("	ld hl,17");
	asm("	jp __sys__2");
#endif
