/********** MSX-UZIX version of syscalls ************/
/* UNIX dup2(int oldd, int newd); */

#include "syscalls.h"

#ifdef L_dup2
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_dup2");
	asm("	signat	_dup2,8250");
	asm("_dup2:");
	asm("	ld hl,9");
	asm("	jp __sys__2");
#endif
