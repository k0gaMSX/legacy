/********** MSX-UZIX version of syscalls ************/
/* UNIX fork(void); */

#include "syscalls.h"

#ifdef L_fork
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_fork");
	asm("	signat	_fork,26");
	asm("_fork:");
	asm("	ld hl,12");
	asm("	jp __sys__");
#endif
