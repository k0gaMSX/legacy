/********** MSX-UZIX version of syscalls ************/
/* UNIX chown(char *path, int owner, int group); */

#include "syscalls.h"

#ifdef L_chown
	asm("	psect text,class=CODE");
        asm("   global __sys__3");
	asm("	global	_chown");
	asm("	signat	_chown,12346");
	asm("_chown:");
	asm("	pop hl");
	asm("	ex (sp),hl");
	asm("	push hl");
	asm("	ld hl,5");
	asm("	jp __sys__3");
#endif
