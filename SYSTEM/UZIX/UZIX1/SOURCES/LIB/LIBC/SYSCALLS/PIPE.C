/********** MSX-UZIX version of syscalls ************/
/* UNIX pipe(int fildes[]); */

#include "syscalls.h"

#ifdef L_pipe
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_pipe");
	asm("	signat	_pipe,4154");
	asm("_pipe:");
	asm("	ld hl,22");
	asm("	jp __sys__1");
#endif


