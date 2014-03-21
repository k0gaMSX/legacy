/********** MSX-UZIX version of syscalls ************/
/* UNIX unlink(char *path); */

#include "syscalls.h"

#ifdef L_unlink
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_unlink");
	asm("	signat	_unlink,4154");
	asm("_unlink:");
	asm("	ld hl,33");
	asm("	jp __sys__1");
#endif


