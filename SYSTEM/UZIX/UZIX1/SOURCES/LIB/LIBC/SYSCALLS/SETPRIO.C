/********** MSX-UZIX version of syscalls ************/
/* UNIX setprio(int pid, char prio); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_setprio
	asm("	psect text,class=CODE");
        asm("   global __sys__3");
	asm("	global	_setprio");
	asm("	signat	_setprio,8250");
	asm("_setprio:");
	asm("	ld b,0");
	asm("	push bc");
	asm("	ld b,d");
	asm("	ld c,e");
	asm("	ld de," __str1(SET_PRIO));
	asm("	ld hl,7");
	asm("	jp __sys__3");
#endif


