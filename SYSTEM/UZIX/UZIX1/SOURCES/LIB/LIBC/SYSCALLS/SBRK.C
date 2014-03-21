/********** MSX-UZIX version of syscalls ************/
/* UNIX sbrk(uint incr); */

#include "syscalls.h"

#ifdef L_sbrk
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_sbrk");
	asm("	signat	_sbrk,4154");
	asm("_sbrk:");
	asm("	ld hl,24");
	asm("	jp __sys__1");
#endif


