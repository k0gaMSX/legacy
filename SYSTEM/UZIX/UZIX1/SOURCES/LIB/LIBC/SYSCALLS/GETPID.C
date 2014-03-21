/********** MSX-UZIX version of syscalls ************/
/* UNIX getpid(void); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_getpid
	asm("	psect text,class=CODE");
        asm("   global __getset");
	asm("	global	_getpid");
	asm("	signat	_getpid,26");
	asm("_getpid:");
	asm("	ld de," __str1(GET_PID));
	asm("	jp __getset");
#endif


