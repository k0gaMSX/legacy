/********** MSX-UZIX version of syscalls ************/
/* UNIX write(int d, void *buf, uint nbytes); */

#include "syscalls.h"

#ifdef L_write
	asm("	psect text,class=CODE");
        asm("   global __sys__3");
	asm("	global	_write");
	asm("	signat	_write,12346");
	asm("_write:");
	asm("	pop hl");
	asm("	ex (sp),hl");
	asm("	push hl");
	asm("	ld hl,36");
	asm("	jp __sys__3");
#endif


