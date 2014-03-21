/********** MSX-UZIX version of syscalls ************/
/* UNIX setuid(int uid); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_setuid
	asm("	psect text,class=CODE");
        asm("   global __setset");
	asm("	global	_setuid");
	asm("	signat	_setuid,4154");
	asm("_setuid:");
	asm("	push de");
	asm("	ld de," __str1(SET_UID));
	asm("	jp __setset");
#endif


