/********** MSX-UZIX version of syscalls ************/
/* UNIX getppid(void); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_getppid
	asm("	psect text,class=CODE");
        asm("   global __getset");
	asm("	global	_getppid");
	asm("	signat	_getppid,26");
	asm("_getppid:");
	asm("	ld de," __str1(GET_PPID));
	asm("	jp __getset");
#endif


