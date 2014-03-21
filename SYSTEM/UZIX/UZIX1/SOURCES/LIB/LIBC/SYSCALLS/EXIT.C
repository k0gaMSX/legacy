/********** MSX-UZIX version of syscalls ************/
/* UNIXV _exit(int val); */

#include "syscalls.h"

#ifdef L_exit
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	__exit");
	asm("	signat	__exit,4152");
	asm("__exit:");
	asm("	ld hl,11");
	asm("	jp __sys__1");
#endif
