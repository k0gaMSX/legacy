/********** MSX-UZIX version of syscalls ************/
/* UNIX dup(int oldd); */

#include "syscalls.h"

#ifdef L_dup
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_dup");
	asm("	signat	_dup,4154");
	asm("_dup:");
	asm("	ld hl,8");
	asm("	jp __sys__1");
#endif
