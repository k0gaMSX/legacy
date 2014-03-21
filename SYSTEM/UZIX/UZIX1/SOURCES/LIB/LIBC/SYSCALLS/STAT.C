/********** MSX-UZIX version of syscalls ************/
/* UNIX stat(char *path, void *buf); */

#include "syscalls.h"

#ifdef L_stat
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_stat");
	asm("	signat	_stat,8250");
	asm("_stat:");
	asm("	ld hl,27");
	asm("	jp __sys__2");
#endif


