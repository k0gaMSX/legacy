/********** MSX-UZIX version of syscalls ************/
/* UNIX getuid(void); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_getuid
	asm("	psect text,class=CODE");
        asm("   global __getset");
	asm("	global	_getuid");
	asm("	signat	_getuid,26");
	asm("_getuid:");
	asm("	ld de," __str1(GET_UID));
	asm("	jp __getset");
#endif


