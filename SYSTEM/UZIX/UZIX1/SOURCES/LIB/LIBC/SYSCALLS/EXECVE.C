/********** MSX-UZIX version of syscalls ************/
/* UNIX execve(char *name, char *argv[], char *envp[]); */

#include "syscalls.h"

#ifdef L_execve
	asm("	psect text,class=CODE");
        asm("   global __sys__3");
	asm("	global	_execve");
	asm("	signat	_execve,12346");
	asm("_execve:");
	asm("	pop hl");
	asm("	ex (sp),hl");
	asm("	push hl");
	asm("	ld hl,10");
	asm("	jp __sys__3");
#endif
