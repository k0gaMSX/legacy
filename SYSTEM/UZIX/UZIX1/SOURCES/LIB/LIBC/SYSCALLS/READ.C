/********** MSX-UZIX version of syscalls ************/
/* UNIX read(int d, void *buf, uint nbytes); */

#include "syscalls.h"

#ifdef L_read
	asm("	psect text,class=CODE");
        asm("   global __sys__3");
	asm("	global	_read");
	asm("	signat	_read,12346");
	asm("_read:");
	asm("	pop hl");
	asm("	ex (sp),hl");
	asm("	push hl");
	asm("	ld hl,23");
	asm("	jp __sys__3");
#endif


