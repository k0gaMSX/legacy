/********** MSX-UZIX version of syscalls ************/
/* UNIX alarm(uint secs); */

#include "syscalls.h"

#ifdef L_alarm
	asm("	psect text,class=CODE");
	asm("	global __sys__, __sys__1, __sys__2, __ret__");
	asm("	global	_alarm");
	asm("	signat	_alarm,4154");
	asm("_alarm:");
	asm("	ld hl,1");
	asm("	jp __sys__1");
#endif


