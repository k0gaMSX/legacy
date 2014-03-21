/********** MSX-UZIX version of syscalls ************/
/* UNIX geteuid(void); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_geteuid
	asm("	psect text,class=CODE");
	asm("	global __getset");
	asm("	global	_geteuid");
	asm("	signat	_geteuid,26");
	asm("_geteuid:");
	asm("	ld de," __str1(GET_EUID));
	asm("	jp __getset");
#endif


