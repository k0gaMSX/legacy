/********** MSX-UZIX version of syscalls ************/
/* UNIX chmod(char *path, mode_t mode); */

#include "syscalls.h"

#ifdef L_chmod
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_chmod");
	asm("	signat	_chmod,8250");
	asm("_chmod:");
	asm("	ld hl,4");
	asm("	jp __sys__2");
#endif
