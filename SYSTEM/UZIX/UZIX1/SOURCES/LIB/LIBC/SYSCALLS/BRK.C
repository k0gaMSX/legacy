/********** MSX-UZIX version of syscalls ************/
/* UNIX brk(char *addr); */

#include "syscalls.h"

#ifdef L_brk
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_brk");
	asm("	signat	_brk,4154");
	asm("_brk:");
	asm("	ld hl,2");
	asm("	jp __sys__1");
#endif
