/********** MSX-UZIX version of syscalls ************/
/* UNIX setgid(int gid); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_setgid
	asm("	psect text,class=CODE");
        asm("   global __setset");
	asm("	global	_setgid");
	asm("	signat	_setgid,4154");
	asm("_setgid:");
	asm("	push de");
	asm("	ld de," __str1(SET_GID));
	asm("	jp __setset");
#endif


