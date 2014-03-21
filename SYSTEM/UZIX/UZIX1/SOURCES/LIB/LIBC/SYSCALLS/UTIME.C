/********** MSX-UZIX version of syscalls ************/
/* UNIX utime(char *path, struct utimbuf *buf); */

#include "syscalls.h"

#ifdef L_utime
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_utime");
	asm("	signat	_utime,8250");
	asm("_utime:");
	asm("	ld hl,34");
	asm("	jp __sys__2");
#endif


