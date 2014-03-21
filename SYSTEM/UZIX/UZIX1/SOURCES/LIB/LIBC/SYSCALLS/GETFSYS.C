/********** MSX-UZIX version of syscalls ************/
/* UNIX getfsys(int dev, void *buf); */

#include "syscalls.h"

#ifdef L_getfsys
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_getfsys");
	asm("	signat	_getfsys,8250");
	asm("_getfsys:");
	asm("	ld hl,14");
	asm("	jp __sys__2");
#endif
