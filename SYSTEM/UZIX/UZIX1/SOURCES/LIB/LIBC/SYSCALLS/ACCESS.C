/********** MSX-UZIX version of syscalls ************/
/* UNIX access(char *path, int mode); */

#include "syscalls.h"

#ifdef L_access
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_access");
	asm("	signat	_access,8250");
	asm("_access:");
	asm("	ld hl,0");
	asm("	jp __sys__2");
#endif


