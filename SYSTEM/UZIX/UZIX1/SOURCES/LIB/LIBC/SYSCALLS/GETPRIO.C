/********** MSX-UZIX version of syscalls ************/
/* UNIX getprio(void); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_getprio
	asm("	psect text,class=CODE");
        asm("   global __getset");
	asm("	global	_getprio");
	asm("	signat	_getprio,26");
	asm("_getprio:");
	asm("	ld de," __str1(GET_PRIO));
	asm("	jp __getset");
#endif


