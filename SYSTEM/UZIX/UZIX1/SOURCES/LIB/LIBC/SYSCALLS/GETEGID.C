/********** MSX-UZIX version of syscalls ************/
/* UNIX getegid(void); */

#include "syscalls.h"

#define __str3(x)	__STRING(x)
#define __str2(x)	__str3(x)
#define __str1(x)	__str2(x)

#ifdef L_getegid
	asm("	psect text,class=CODE");
	asm("	global __getset");
	asm("	global	_getegid");
	asm("	signat	_getegid,26");
	asm("_getegid:");
	asm("	ld de," __str1(GET_EGID));
	asm("	jp __getset");
#endif


