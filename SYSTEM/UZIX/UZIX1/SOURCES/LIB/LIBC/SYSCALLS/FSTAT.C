/********** MSX-UZIX version of syscalls ************/
/* UNIX fstat(int fd, void *buf); */

#include "syscalls.h"

#ifdef L_fstat
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_fstat");
	asm("	signat	_fstat,8250");
	asm("_fstat:");
	asm("	ld hl,13");
	asm("	jp __sys__2");
#endif
