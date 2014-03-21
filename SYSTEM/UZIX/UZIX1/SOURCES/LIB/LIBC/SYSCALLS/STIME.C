/********** MSX-UZIX version of syscalls ************/
/* UNIX stime(time_t *tvec); */

#include "syscalls.h"

#ifdef L_stime
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_stime");
	asm("	signat	_stime,4154");
	asm("_stime:");
	asm("	ld hl,28");
	asm("	jp __sys__1");
#endif


