/********** MSX-UZIX version of syscalls ************/
/* UNIX close(int uindex); */

#include "syscalls.h"

#ifdef L_close
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_close");
	asm("	signat	_close,4154");
	asm("_close:");
	asm("	ld hl,6");
	asm("	jp __sys__1");
#endif
