/********** MSX-UZIX version of syscalls ************/
/* UNIX kill(int pid, int sig); */

#include "syscalls.h"

#ifdef L_kill
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_kill");
	asm("	signat	_kill,8250");
	asm("_kill:");
	asm("	ld hl,16");
	asm("	jp __sys__2");
#endif
