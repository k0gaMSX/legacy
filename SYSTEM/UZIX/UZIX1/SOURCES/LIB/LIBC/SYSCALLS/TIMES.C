/********** MSX-UZIX version of syscalls ************/
/* UNIX times(struct tms *tvec); */

#include "syscalls.h"

#ifdef L_times
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_times");
	asm("	signat	_times,4154");
	asm("_times:");
	asm("	ld hl,31");
	asm("	jp __sys__1");
#endif


