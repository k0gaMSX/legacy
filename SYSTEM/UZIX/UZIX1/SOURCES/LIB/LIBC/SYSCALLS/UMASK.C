/********** MSX-UZIX version of syscalls ************/
/* UNIX umask(int mask); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_umask
	asm("	psect text,class=CODE");
        asm("   global __setset");
	asm("	global	_umask");
	asm("	signat	_umask,4154");
	asm("_umask:");
	asm("	push de");
	asm("	ld de," __str1(SET_UMASK));
	asm("	jp __setset");
#endif


