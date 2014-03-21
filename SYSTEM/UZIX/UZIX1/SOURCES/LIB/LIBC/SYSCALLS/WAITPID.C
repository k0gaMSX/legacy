/********** MSX-UZIX version of syscalls ************/
/* UNIX waitpid(int pid, int *statloc, int options); */

#include "syscalls.h"

#ifdef L_waitpid
	asm("	psect text,class=CODE");
        asm("   global __sys__3");
	asm("	global	_waitpid");
	asm("	signat	_waitpid,12346");
	asm("_waitpid:");
	asm("	pop hl");
	asm("	ex (sp),hl");
	asm("	push hl");
	asm("	ld hl,35");
	asm("	jp __sys__3");
#endif
