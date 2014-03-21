/********** MSX-UZIX version of syscalls ************/
/* UNIX mount(char *spec, char *dir, int rwflag); */

#include "syscalls.h"

#ifdef L_mount
	asm("	psect text,class=CODE");
	asm("	global __sys__3");
	asm("	global	_mount");
	asm("	signat	_mount,12346");
	asm("_mount:");
	asm("	pop hl");
	asm("	ex (sp),hl");
	asm("	push hl");
	asm("	ld hl,19");
	asm("	jp __sys__3");
#endif
