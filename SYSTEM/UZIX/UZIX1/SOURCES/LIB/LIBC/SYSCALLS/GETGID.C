/********** MSX-UZIX version of syscalls ************/
/* UNIX getgid(void); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_getgid
	asm("	psect text,class=CODE");
        asm("   global __getset");
	asm("	global	_getgid");
	asm("	signat	_getgid,26");
	asm("_getgid:");
	asm("	ld de," __str1(GET_GID));
	asm("	jp __getset");
#endif


