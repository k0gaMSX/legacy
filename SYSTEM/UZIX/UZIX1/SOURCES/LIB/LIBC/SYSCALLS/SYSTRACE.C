/********** MSX-UZIX version of syscalls ************/
/* UNIX systrace(int onoff); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_systrace
	asm("	psect text,class=CODE");
        asm("   global __setset");
	asm("	global	_systrace");
	asm("	signat	_systrace,4154");
	asm("_systrace:");
	asm("	push de");
	asm("	ld de," __str1(SET_TRACE));
	asm("	jp __setset");
#endif


