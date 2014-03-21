/********** MSX-UZIX version of syscalls ************/
/* UNIX chdir(char *dir); */

#include "syscalls.h"

#ifdef L_chdir
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_chdir");
	asm("	signat	_chdir,4154");
	asm("_chdir:");
	asm("	ld hl,3");
	asm("	jp __sys__1");
#endif
